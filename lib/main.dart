import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'core/router.dart';
import 'core/supabase_client.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  if (!Env.isSupabaseConfigured) {
    runApp(const _MissingConfigApp());
    return;
  }
  await initSupabase();
  runApp(
    // Niente retry automatico: gli errori (es. rete) devono emergere subito.
    ProviderScope(retry: (_, _) => null, child: const CiaMaFaApp()),
  );
}

class CiaMaFaApp extends ConsumerWidget {
  const CiaMaFaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'CiaMaFa',
      theme: buildAppTheme(),
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Mostrata quando l'app parte senza SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY.
class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Configurazione mancante.\n\n'
              'Copia env.example.json in env.json,\n'
              'compila i valori e rilancia l\'app\n'
              '(restart completo, non hot reload).',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
