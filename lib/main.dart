import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'core/router.dart';
import 'core/supabase_client.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Env.supabaseUrl.isNotEmpty) await initSupabase();
  runApp(const ProviderScope(child: CiaMaFaApp()));
}

class CiaMaFaApp extends StatelessWidget {
  const CiaMaFaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CiaMaFa',
      theme: buildAppTheme(),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
