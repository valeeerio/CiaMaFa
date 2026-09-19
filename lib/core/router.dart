import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_provider.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/plans/activity.dart';
import '../shared/placeholder_screen.dart';

part 'router.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(currentProfileProvider, (_, _) => refresh.value++);

  return GoRouter(
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
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      // Segnaposto: scelta del posto (Fase 3), piani di oggi (Fase 5), profilo (Fase 7).
      GoRoute(
        path: '/places/:activityId',
        builder: (context, state) => PlaceholderScreen(
          title: activityById(state.pathParameters['activityId']!).label,
          subtitle: 'Scelta del posto: Fase 3',
        ),
      ),
      GoRoute(
        path: '/plans',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Piani di oggi', subtitle: 'Fase 5'),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Profilo', subtitle: 'Fase 7'),
      ),
    ],
  );
}
