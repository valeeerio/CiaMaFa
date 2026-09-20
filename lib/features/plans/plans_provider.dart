import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/supabase_client.dart';
import '../onboarding/onboarding_provider.dart';
import 'map_launcher.dart';
import 'plan.dart';
import 'plans_repository.dart';

part 'plans_provider.g.dart';

/// Quanto resta visibile il banner se non lo tocchi.
const bannerDuration = Duration(seconds: 6);

@Riverpod(keepAlive: true)
PlansRepository plansRepository(Ref ref) => SupabasePlansRepository(supabase);

@Riverpod(keepAlive: true)
MapLauncher mapLauncher(Ref ref) => const UrlMapLauncher();

/// Piani di oggi, sempre aggiornati: si ricarica a ogni cambiamento di piani o
/// voti (Realtime). Ordinati: più "Ci sono" prima, poi i più recenti.
@riverpod
Stream<List<Plan>> livePlans(Ref ref) async* {
  final repo = ref.watch(plansRepositoryProvider);
  yield await repo.todaysPlans();
  await for (final _ in repo.changes()) {
    yield await repo.todaysPlans();
  }
}

/// Notifiche degli altri (nuovi piani e voti sui tuoi) (solo se hai un profilo e le notifiche attive).
@Riverpod(keepAlive: true)
Stream<PlanAnnouncement> planAnnouncements(Ref ref) {
  final profile = ref.watch(currentProfileProvider).value;
  if (profile == null || !profile.notificationsEnabled) {
    return const Stream.empty();
  }
  return ref.watch(plansRepositoryProvider).announcements(selfId: profile.id);
}

/// Il banner in alto: l'ultimo annuncio, finché non lo chiudi o scade.
@Riverpod(keepAlive: true)
class PlanBanner extends _$PlanBanner {
  Timer? _timer;

  @override
  PlanAnnouncement? build() {
    ref.onDispose(() => _timer?.cancel());
    ref.listen(planAnnouncementsProvider, (_, next) => next.whenData(show));
    return null;
  }

  void show(PlanAnnouncement announcement) {
    _timer?.cancel();
    state = announcement;
    _timer = Timer(bannerDuration, dismiss);
  }

  void dismiss() {
    _timer?.cancel();
    state = null;
  }
}
