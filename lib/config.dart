/// Build with: --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
/// Defaults fall back to the shared project so the app runs out of the box.
class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://jdgshudtqymneaaiabxm.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_b-K6jXxlW0iRiKckK1TUOw_RkmD129J',
  );
  static String get restUrl => '$supabaseUrl/rest/v1';
}
