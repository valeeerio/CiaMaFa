import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../onboarding/onboarding_provider.dart';

/// Segnaposto: la vera Home arriva nella Fase 2.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nickname = ref.watch(currentProfileProvider).value?.nickname ?? '';
    return Scaffold(
      body: Center(child: Text('Ciao $nickname 👋')),
    );
  }
}
