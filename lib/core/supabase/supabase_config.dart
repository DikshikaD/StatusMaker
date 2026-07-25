/// Supabase connection settings.
///
/// Paste your project's values here (Supabase dashboard → Settings → API):
///   • Project URL   → [url]
///   • anon public key → [anonKey]
///
/// The `anon` key is safe to ship in a client app (Row Level Security protects
/// your data). NEVER put the `service_role` key here.
///
/// Until these are filled in, the app runs normally with Supabase disabled
/// (see [SupabaseService.isConfigured]).
class SupabaseConfig {
  static const String url = 'https://soqpzkgribiumftburwy.supabase.co';
  // New-style publishable key (client-safe, replaces the legacy anon JWT).
  static const String anonKey = 'sb_publishable_uyv1HKeXnu669Zpww5Q4sQ__kiuxJgD';
}
