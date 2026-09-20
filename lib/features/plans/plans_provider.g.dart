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

/// Nuovi piani degli altri (solo se hai un profilo e le notifiche attive).

@ProviderFor(planAnnouncements)
final planAnnouncementsProvider = PlanAnnouncementsProvider._();

/// Nuovi piani degli altri (solo se hai un profilo e le notifiche attive).

final class PlanAnnouncementsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlanAnnouncement>,
          PlanAnnouncement,
          Stream<PlanAnnouncement>
        >
    with $FutureModifier<PlanAnnouncement>, $StreamProvider<PlanAnnouncement> {
  /// Nuovi piani degli altri (solo se hai un profilo e le notifiche attive).
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
