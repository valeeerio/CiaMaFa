import 'dart:convert';

import 'package:flutter/services.dart';

/// Configurazione (Supabase). Mai committata.
///
/// Priorità: `--dart-define` / `--dart-define-from-file`, poi l'asset
/// `env.json` (gitignored, copia di `env.example.json`).
abstract final class Env {
  static String supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
  static String supabasePublishableKey = const String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// Chiave gratuita CARTO (carto.com/basemaps/apikey). Opzionale: senza, la
  /// mappa usa i tile OpenStreetMap standard.
  static String cartoApiKey = const String.fromEnvironment('CARTO_API_KEY');

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  /// Completa i valori mancanti leggendo l'asset `env.json`.
  static Future<void> load() async {
    try {
      final map = jsonDecode(
        await rootBundle.loadString('env.json'),
      ) as Map<String, dynamic>;
      String pick(String key, String current) =>
          current.isNotEmpty ? current : (map[key] as String? ?? '');
      supabaseUrl = pick('SUPABASE_URL', supabaseUrl);
      supabasePublishableKey = pick(
        'SUPABASE_PUBLISHABLE_KEY',
        supabasePublishableKey,
      );
      cartoApiKey = pick('CARTO_API_KEY', cartoApiKey);
    } catch (_) {
      // Asset assente o non valido: resta "non configurato".
    }
  }
}

/// Gruppo unico dell'MVP (stesso UUID del seed in supabase/migrations).
const defaultGroupId = '00000000-0000-0000-0000-00000000c1a0';
