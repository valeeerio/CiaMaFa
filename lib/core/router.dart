import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/chat/chat_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_provider.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/places/places_screen.dart';
import '../features/plans/launched_screen.dart';
import '../features/plans/plan_detail_screen.dart';
import '../features/plans/plans_screen.dart';
import '../features/profile/credits_screen.dart';
import '../features/profile/profile_screen.dart';
import '../shared/main_shell.dart';
import '../shared/route_transitions.dart';

part 'router.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(currentProfileProvider, (_, _) => refresh.value++);

  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  return GoRouter(
    navigatorKey: rootKey,
    refreshListenable: refresh,
    redirect: (context, state) {
      final profile = ref.read(currentProfileProvider);
      if (profile.isLoading) return null; // resta sulla splash
      final hasProfile = profile.value != null;
      final loc = state.matchedLocation;
      if (!hasProfile) return loc == '/onboarding' ? null : '/onboarding';
      // Con profilo, onboarding e splash portano alla Home.
      return (loc == '/' || loc == '/onboarding') ? '/home' : null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      // Le 4 tab con la bottom nav; le schermate a stack stanno sul root.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/plans',
                builder: (context, state) => const PlansScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) => const ChatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/places/:activityId',
        parentNavigatorKey: rootKey,
        pageBuilder: (context, state) => expandingPage(
          key: state.pageKey,
          origin: state.extra as TransitionOrigin?,
          child: PlacesScreen(activityId: state.pathParameters['activityId']!),
        ),
      ),
      GoRoute(
        path: '/launched',
        parentNavigatorKey: rootKey,
        // Senza i dati del lancio (es. riapertura) non c'è nulla da mostrare.
        redirect: (context, state) =>
            state.extra is LaunchedInfo ? null : '/home',
        builder: (context, state) =>
            LaunchedScreen(info: state.extra! as LaunchedInfo),
      ),
      GoRoute(
        path: '/plans/:id',
        parentNavigatorKey: rootKey,
        builder: (context, state) =>
            PlanDetailScreen(planId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/credits',
        parentNavigatorKey: rootKey,
        builder: (context, state) => const CreditsScreen(),
      ),
    ],
  );
}
