import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/plans/plans_provider.dart';
import 'bottom_nav_bar.dart';

/// Contenitore delle 4 tab (Home, Piani, Chat, Profilo) con la nav bar fissa.
/// Le schermate a stack stanno sul navigator root, quindi la coprono.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansToday = ref.watch(livePlansProvider).value?.length ?? 0;
    return Scaffold(
      body: navigationShell,
      // Con la tastiera aperta (es. in Chat) la barra si toglie di mezzo invece
      // di salire sopra la tastiera.
      bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
          ? null
          : BottomNavBar(
              currentIndex: navigationShell.currentIndex,
              plansCount: plansToday,
              // Ritoccare la tab attiva torna alla sua radice.
              onTap: (i) => navigationShell.goBranch(
                i,
                initialLocation: i == navigationShell.currentIndex,
              ),
            ),
    );
  }
}
