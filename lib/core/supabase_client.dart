import 'package:supabase_flutter/supabase_flutter.dart';

import 'constants.dart';

/// Inizializza Supabase. Da chiamare in main() prima di runApp.
Future<void> initSupabase() {
  return Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
  );
}

SupabaseClient get supabase => Supabase.instance.client;
