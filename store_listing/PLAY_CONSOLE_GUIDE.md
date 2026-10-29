# Status Maker — Play Console guide

Everything needed to publish `com.appbedev.statusmaker` (version 1.0.0, code 1).
Copy-paste text lives in `en-IN/` and `hi-IN/`; graphics in `graphics/`.

## 1. Store listing (Grow → Store presence → Main store listing)

| Field | Value | File |
|---|---|---|
| Default language | English (India) — en-IN | |
| App name (30) | Status Maker: Quotes & Wishes | `en-IN/title.txt` |
| Short description (80) | see file | `en-IN/short_description.txt` |
| Full description (4000) | see file | `en-IN/full_description.txt` |
| App icon | 512 × 512 PNG | `graphics/app_icon_512.png` |
| Feature graphic | 1024 × 500 PNG | `graphics/feature_graphic_1024x500.png` |
| Phone screenshots | 4–8 images, 1080 × 1920 | `graphics/screenshots/en/` (see §2) |

Add a translation: **Hindi — hi-IN**, using the files in `hi-IN/` and
`graphics/screenshots/hi/`. Icon and feature graphic are shared.

## 2. Screenshots

Raw phone screenshots (1080 × 2340) are taller than Play's 2:1 limit, so they
are framed first:

1. On the phone, take these screenshots in **English** (and again in **Hindi**
   for the Hindi listing), with no notifications in the status bar:

   | File name | Screen |
   |---|---|
   | `01_home.png` | Home feed with a nice post visible |
   | `02_templates.png` | Explore → Ready templates |
   | `03_editor.png` | A template open in the editor, with a photo and name added |
   | `04_themes.png` | Create tab (theme grid) |
   | `05_share.png` | The share sheet (WhatsApp / Instagram / … tiles) |
   | `06_dark.png` | Home or Settings in dark mode |
   | `07_detail.png` | A post's detail page (like / share / customise) — optional |
   | `08_report.png` | The ⋯ menu showing Report / Hide / Block — optional |

2. Copy them to `screenshots_raw/en/` and `screenshots_raw/hi/`.
3. Run `python3 store_listing/source/frame_screenshots.py` from the repo root.
4. Upload `graphics/screenshots/en/*.png` (and `/hi/`) in number order.

Use only real app screens and real, non-copyrighted photos.

## 3. App category and contact

| Field | Value |
|---|---|
| App or game | App |
| Category | Art & Design |
| Tags | Photo editing, Greeting cards, Quotes (pick the closest offered) |
| Email | appbedev@gmail.com |
| Website | https://dikshikad.github.io/StatusMaker/ |
| Privacy policy | https://dikshikad.github.io/StatusMaker/privacy.html |

## 4. App content (Policy → App content)

**Privacy policy:** URL above.

**Ads:** No, the app does not contain ads.

**App access:** All functionality is available without special access
(no login).

**Content rating (IARC questionnaire):**
- Category: *All other app types*
- Violence, sexuality, language, controlled substances, gambling: **No**
- *Does the app allow users to interact or exchange content?* **Yes**
  (users post public statuses others can see, like, share and customise)
- *Does the app share the user's location?* No
- *Digital purchases?* No
- Expected result: rated for general audiences, with a "Users Interact" notice.

**Target audience and content:** ages **13–15, 16–17, 18+** (do not select
under 13). Not designed to appeal to children.

**News app:** No. **COVID-19 tracing:** No. **Government app:** No.
**Financial features:** None. **Health:** No.

**Data safety:**

| Question | Answer |
|---|---|
| Does your app collect or share user data? | Yes |
| Is all collected data encrypted in transit? | Yes |
| Do you provide a way for users to request data deletion? | Yes |
| Data deletion URL (optional field) | https://dikshikad.github.io/StatusMaker/delete-data.html |
| Does your app allow users to create an account? | **No** (no sign-up or login) |

Data types collected (none are *shared* — Supabase and Firebase are service
providers processing on our behalf):

| Data type | Collected | Required? | Purposes |
|---|---|---|---|
| Personal info → User IDs | Yes | Required | App functionality, Account management |
| Photos and videos → Photos | Yes | Optional | App functionality |
| App activity → App interactions | Yes | Optional | App functionality |
| App activity → Other user-generated content | Yes | Optional | App functionality, Fraud prevention, security, and compliance |
| Device or other IDs | Yes | Required | App functionality (push notifications) |

Not collected: location, contacts, financial info, health, messages, audio,
files and docs, calendar, web browsing, app info and performance, name, email,
phone number.

## 5. Release (Test and release)

1. Build the bundle on the release machine:
   `flutter build appbundle --release`
   → `build/app/outputs/bundle/release/app-release.aab`
2. Enrol in **Play App Signing** (default). Keep `android/app/upload-keystore.jks`
   and `android/key.properties` backed up somewhere safe — they are not in git.
3. New personal developer accounts must run a **closed test with at least
   12 testers for 14 days** before production access. Start that first.
4. Release notes: `en-IN/release_notes.txt` and `hi-IN/release_notes.txt`.
5. Countries: India (add more later if wanted).

## 6. Before you press "Send for review"

- [ ] Supabase SQL run in order: `notifications.sql` → `0002` → `0003` → `0004`
- [ ] `notify-on-like` Edge Function redeployed; `NOTIFY_HOOK_SECRET` set and
      matching the Vault secret `notify_on_like_key`
- [ ] GitHub Pages enabled (`main` / `docs`); all three legal URLs open in a
      private browser window
- [ ] CAPTCHA / rate limit for anonymous sign-ins set in Supabase Auth
- [ ] Test on a real phone: first launch, Post (Terms dialog), Share, Report,
      Delete my data, dark mode
- [ ] Screenshots framed and uploaded for both languages

## Regenerating the graphics

`python3 store_listing/source/render.py` re-renders the icon, logo, feature
graphic, the Android launcher icons (`android/app/src/main/res/mipmap-*`) and
the notification icon. Needs Google Chrome and Pillow.
