import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'core/router.dart';
import 'core/supabase_client.dart';
import 'core/theme.dart';
import 'features/plans/plan_banner_host.dart';
import 'features/push/push_host.dart';
import 'features/push/push_messaging.dart';
import 'features/push/push_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureBundledFonts();
  await Env.load();
  if (!Env.isSupabaseConfigured) {
    runApp(const _MissingConfigApp());
    return;
  }
  await initSupabase();
  // Push: solo se Firebase è configurato in env.json; altrimenti l'app parte
  // comunque, senza notifiche di sistema.
  // Mai bloccare l'avvio per Firebase: se non risponde entro pochi secondi
  // l'app parte lo stesso, senza notifiche di sistema.
  final push = await FirebasePushMessaging.create().timeout(
    const Duration(seconds: 5),
    onTimeout: () => null,
  );
  runApp(
    // Niente retry automatico: gli errori (es. rete) devono emergere subito.
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        if (push != null) pushMessagingProvider.overrideWithValue(push),
      ],
      child: const CiaMaFaApp(),
    ),
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
      builder: (context, child) =>
          PushHost(child: PlanBannerHost(child: child!)),
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
