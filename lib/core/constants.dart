/// Chiavi di configurazione, passate con `--dart-define` (mai committate).
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const mapboxToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
}
