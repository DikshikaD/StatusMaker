// ============================================================================
// notify-on-like — turns a `notifications` row (like or remix) into an
// Android push via FCM.
//
// Invoked directly by the `notify_on_like` Postgres trigger via pg_net (see
// supabase/notifications.sql, sections 3.5–4) — no manual Dashboard wiring
// needed once its two Vault secrets are set. It also accepts the same payload
// shape from a Database Webhook, if you prefer that instead (see the note at
// the bottom of notifications.sql).
//
// Deploy:
//   supabase functions deploy notify-on-like
//   supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat service-account.json)"
//
// The service-account JSON is a credential: keep it out of git and out of chat —
// set it as a secret in the dashboard or with the CLI above.
//
// verify_jwt stays ON (the default) for this function, and the handler then
// also requires the service-role key (see isServiceRole): every app user holds
// a valid project JWT too, so verify_jwt on its own would let them through.
// The trigger presents the service-role key as its bearer token, so legitimate
// calls pass.
// ============================================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface WebhookPayload {
  type: 'INSERT' | 'UPDATE' | 'DELETE';
  table: string;
  record: {
    id: string;
    recipient_id: string;
    actor_id: string;
    status_id: string | null;
    type: string;
  } | null;
}

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

// ---- Google auth -----------------------------------------------------------
// FCM's HTTP v1 API wants an OAuth access token, which means signing a JWT with
// the service account's private key. Done with Web Crypto so the function has
// no dependency beyond the Supabase client.

function base64url(bytes: Uint8Array): string {
  return btoa(String.fromCharCode(...bytes))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

function encodeJson(value: unknown): string {
  return base64url(new TextEncoder().encode(JSON.stringify(value)));
}

/** Turns the PEM private key from the service account into a signing key. */
async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const body = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '');
  const der = Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey(
    'pkcs8',
    der,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
}

async function getAccessToken(account: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const claim = {
    iss: account.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };

  const unsigned = `${encodeJson({ alg: 'RS256', typ: 'JWT' })}.${encodeJson(claim)}`;
  const key = await importPrivateKey(account.private_key);
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(unsigned),
  );
  const jwt = `${unsigned}.${base64url(new Uint8Array(signature))}`;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });
  if (!res.ok) {
    throw new Error(`token exchange failed: ${res.status} ${await res.text()}`);
  }
  return (await res.json()).access_token;
}

// ---- FCM -------------------------------------------------------------------

/**
 * Sends one push. Returns 'gone' when Google says the token is dead, so the
 * caller can delete it — otherwise dead tokens accumulate forever and every
 * send wastes a request on them.
 */
async function sendPush(
  projectId: string,
  accessToken: string,
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<'sent' | 'gone' | 'failed'> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          // `notification` (not data-only) is what lets Android draw the tray
          // item itself while the app is closed — no Dart code needs to run.
          notification: { title, body },
          data,
          android: { priority: 'high', notification: { sound: 'default' } },
        },
      }),
    },
  );

  if (res.ok) return 'sent';

  const text = await res.text();
  // 404 UNREGISTERED / 400 INVALID_ARGUMENT on the token = uninstalled or stale.
  // SENDER_ID_MISMATCH = token was issued by a different Firebase project (e.g.
  // before the app was re-registered under a new app id) — it can never work.
  if (
    res.status === 404 ||
    text.includes('UNREGISTERED') ||
    text.includes('SENDER_ID_MISMATCH')
  ) {
    return 'gone';
  }
  console.error(`fcm send failed (${res.status}): ${text}`);
  return 'failed';
}

// ---- handler ---------------------------------------------------------------

/**
 * True only for the service-role caller (the pg_net trigger, or a Database
 * Webhook configured with that key).
 *
 * verify_jwt alone is NOT enough: it accepts any token signed by this project,
 * including the session every anonymous app user gets — so without this check
 * anyone could POST a hand-made record and push to any user id. The gateway
 * has already verified the signature, so reading the role claim is safe.
 */
function isServiceRole(req: Request): boolean {
  const auth = req.headers.get('Authorization') ?? '';
  const token = auth.replace(/^Bearer\s+/i, '');
  if (!token) return false;
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (serviceKey && token === serviceKey) return true;
  try {
    const part = token.split('.')[1];
    if (!part) return false;
    const json = atob(part.replace(/-/g, '+').replace(/_/g, '/'));
    return JSON.parse(json).role === 'service_role';
  } catch {
    return false;
  }
}

Deno.serve(async (req) => {
  if (!isServiceRole(req)) {
    return new Response(JSON.stringify({ error: 'forbidden' }), { status: 403 });
  }
  try {
    const payload: WebhookPayload = await req.json();
    const incoming = payload.record;

    // Only act on newly created notifications this function knows how to word.
    const KNOWN_TYPES = new Set(['like', 'remix']);
    if (payload.type !== 'INSERT' || !incoming?.id) {
      return new Response(JSON.stringify({ skipped: true }), { status: 200 });
    }

    const rawAccount = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
    if (!rawAccount) throw new Error('FIREBASE_SERVICE_ACCOUNT is not set');
    const account: ServiceAccount = JSON.parse(rawAccount);

    // Service-role client: it must read another user's device tokens, which no
    // user-scoped client is allowed to do under the RLS policies.
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // Word the push from the stored row, not the request body: the row is what
    // the trigger actually inserted, so a replayed or edited payload can't
    // change who gets pushed or what it says.
    const { data: record, error: recordError } = await supabase
      .from('notifications')
      .select('id, recipient_id, actor_id, status_id, type')
      .eq('id', incoming.id)
      .maybeSingle();
    if (recordError) throw recordError;
    if (!record || !KNOWN_TYPES.has(record.type)) {
      return new Response(JSON.stringify({ skipped: true }), { status: 200 });
    }

    const { data: tokens, error } = await supabase
      .from('device_tokens')
      .select('token, lang')
      .eq('user_id', record.recipient_id);
    if (error) throw error;

    // Nobody registered a device (or they only ever used the web) — the bell row
    // still exists, so nothing is lost.
    if (!tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ sent: 0, reason: 'no tokens' }), {
        status: 200,
      });
    }

    // The status title makes the notification concrete ("… liked 'Good
    // Morning'"). Best-effort: a missing title just falls back to generic copy.
    let statusTitle: string | null = null;
    if (record.status_id) {
      const { data: status } = await supabase
        .from('statuses')
        .select('title')
        .eq('id', record.status_id)
        .maybeSingle();
      statusTitle = status?.title ?? null;
    }

    // Deliberately anonymous: users are anonymous accounts today, so there is no
    // display name to use. Add a profiles table and this becomes "<name> liked…"
    // / "<name> remixed…".
    // Keep in sync with the `push_*` keys in lib/core/localization/strings.dart,
    // which word the in-app banner. Any language missing here falls back to
    // English rather than sending nothing.
    type Copy = { title: string; body: (t: string | null) => string };
    const copy: Record<string, Record<string, Copy>> = {
      en: {
        like: {
          title: 'Someone liked your status ❤️',
          body: (t) =>
            t ? `Your status "${t}" got a new like.` : 'Your status got a new like.',
        },
        remix: {
          title: 'Someone remixed your template 🔁',
          body: (t) =>
            t ? `Someone used your template "${t}".` : 'Someone used your template.',
        },
      },
      hi: {
        like: {
          title: 'किसी ने आपका स्टेटस पसंद किया ❤️',
          body: (t) =>
            t
              ? `आपके स्टेटस "${t}" को नया लाइक मिला।`
              : 'आपके स्टेटस को नया लाइक मिला।',
        },
        remix: {
          title: 'किसी ने आपका टेम्पलेट रीमिक्स किया 🔁',
          body: (t) =>
            t
              ? `किसी ने आपका टेम्पलेट "${t}" इस्तेमाल किया।`
              : 'किसी ने आपका टेम्पलेट इस्तेमाल किया।',
        },
      },
    };

    const copyFor = (lang: string | null) => {
      const table = copy[lang ?? 'en'] ?? copy.en;
      const entry = table[record.type] ?? copy.en[record.type];
      return { title: entry.title, body: entry.body(statusTitle) };
    };

    const accessToken = await getAccessToken(account);
    const results = await Promise.all(
      tokens.map((t) => {
        const { title, body } = copyFor(t.lang ?? null);
        return sendPush(account.project_id, accessToken, t.token, title, body, {
          type: record.type,
          status_id: record.status_id ?? '',
          notification_id: record.id,
          // Lets the in-app banner name the status when it re-words this in
          // the language the user has selected right now.
          status_title: statusTitle ?? '',
        }).then((outcome) => ({ token: t.token, outcome }));
      }),
    );

    const dead = results.filter((r) => r.outcome === 'gone').map((r) => r.token);
    if (dead.length > 0) {
      await supabase.from('device_tokens').delete().in('token', dead);
    }

    return new Response(
      JSON.stringify({
        sent: results.filter((r) => r.outcome === 'sent').length,
        pruned: dead.length,
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } },
    );
  } catch (e) {
    console.error('notify-on-like failed:', e);
    // 200 on purpose: a webhook retry storm would not fix a bad credential, and
    // a lost push is far less bad than a hot loop. The error is in the logs.
    // Supabase/PostgREST errors are plain objects, so String(e) gives
    // "[object Object]" — serialise them so the real cause is visible.
    const detail = e instanceof Error ? e.message : JSON.stringify(e);
    return new Response(JSON.stringify({ error: detail }), { status: 200 });
  }
});
