// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plans_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(plansRepository)
final plansRepositoryProvider = PlansRepositoryProvider._();

final class PlansRepositoryProvider
    extends
        $FunctionalProvider<PlansRepository, PlansRepository, PlansRepository>
    with $Provider<PlansRepository> {
  PlansRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'plansRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plansRepositoryHash();

  @$internal
  @override
  $ProviderElement<PlansRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlansRepository create(Ref ref) {
    return plansRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlansRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlansRepository>(value),
    );
  }
}

String _$plansRepositoryHash() => r'6888874b6dc60fee7b520fcc6092b2fc43eab9f1';

@ProviderFor(mapLauncher)
final mapLauncherProvider = MapLauncherProvider._();

final class MapLauncherProvider
    extends $FunctionalProvider<MapLauncher, MapLauncher, MapLauncher>
    with $Provider<MapLauncher> {
  MapLauncherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapLauncherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapLauncherHash();

  @$internal
  @override
  $ProviderElement<MapLauncher> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MapLauncher create(Ref ref) {
    return mapLauncher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MapLauncher value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MapLauncher>(value),
    );
  }
}

String _$mapLauncherHash() => r'29c7ef8e385068d63abb492f69f2d2643e2c6268';

/// Piani di oggi, sempre aggiornati: si ricarica a ogni cambiamento di piani o
/// voti (Realtime). Ordinati: più "Ci sono" prima, poi i più recenti.

@ProviderFor(livePlans)
final livePlansProvider = LivePlansProvider._();

/// Piani di oggi, sempre aggiornati: si ricarica a ogni cambiamento di piani o
/// voti (Realtime). Ordinati: più "Ci sono" prima, poi i più recenti.

final class LivePlansProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Plan>>,
          List<Plan>,
          Stream<List<Plan>>
        >
    with $FutureModifier<List<Plan>>, $StreamProvider<List<Plan>> {
  /// Piani di oggi, sempre aggiornati: si ricarica a ogni cambiamento di piani o
  /// voti (Realtime). Ordinati: più "Ci sono" prima, poi i più recenti.
  LivePlansProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'livePlansProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$livePlansHash();

  @$internal
  @override
  $StreamProviderElement<List<Plan>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Plan>> create(Ref ref) {
    return livePlans(ref);
  }
}

String _$livePlansHash() => r'a91634008628b70b405ae2e2aa7f4ac667bba346';

/// Notifiche degli altri (nuovi piani e voti sui tuoi) (solo se hai un profilo e le notifiche attive).

@ProviderFor(planAnnouncements)
final planAnnouncementsProvider = PlanAnnouncementsProvider._();

/// Notifiche degli altri (nuovi piani e voti sui tuoi) (solo se hai un profilo e le notifiche attive).

final class PlanAnnouncementsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlanAnnouncement>,
          PlanAnnouncement,
          Stream<PlanAnnouncement>
        >
    with $FutureModifier<PlanAnnouncement>, $StreamProvider<PlanAnnouncement> {
  /// Notifiche degli altri (nuovi piani e voti sui tuoi) (solo se hai un profilo e le notifiche attive).
  PlanAnnouncementsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planAnnouncementsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planAnnouncementsHash();

  @$internal
  @override
  $StreamProviderElement<PlanAnnouncement> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<PlanAnnouncement> create(Ref ref) {
    return planAnnouncements(ref);
  }
}

String _$planAnnouncementsHash() => r'0900ce202a7ffe2df269112174ba90a1c1bea858';

/// Il banner in alto: l'ultimo annuncio, finché non lo chiudi o scade.

@ProviderFor(PlanBanner)
final planBannerProvider = PlanBannerProvider._();

/// Il banner in alto: l'ultimo annuncio, finché non lo chiudi o scade.
final class PlanBannerProvider
    extends $NotifierProvider<PlanBanner, PlanAnnouncement?> {
  /// Il banner in alto: l'ultimo annuncio, finché non lo chiudi o scade.
  PlanBannerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planBannerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planBannerHash();

  @$internal
  @override
  PlanBanner create() => PlanBanner();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlanAnnouncement? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlanAnnouncement?>(value),
    );
  }
}

String _$planBannerHash() => r'355e05d665d89fb2d06d52b0fdfc74c37e7e747e';

/// Il banner in alto: l'ultimo annuncio, finché non lo chiudi o scade.

abstract class _$PlanBanner extends $Notifier<PlanAnnouncement?> {
  PlanAnnouncement? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PlanAnnouncement?, PlanAnnouncement?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlanAnnouncement?, PlanAnnouncement?>,
              PlanAnnouncement?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
