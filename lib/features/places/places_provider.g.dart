// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'places_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(placeSearchRepository)
final placeSearchRepositoryProvider = PlaceSearchRepositoryProvider._();

final class PlaceSearchRepositoryProvider
    extends
        $FunctionalProvider<
          PlaceSearchRepository,
          PlaceSearchRepository,
          PlaceSearchRepository
        >
    with $Provider<PlaceSearchRepository> {
  PlaceSearchRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'placeSearchRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$placeSearchRepositoryHash();

  @$internal
  @override
  $ProviderElement<PlaceSearchRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlaceSearchRepository create(Ref ref) {
    return placeSearchRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaceSearchRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaceSearchRepository>(value),
    );
  }
}

String _$placeSearchRepositoryHash() =>
    r'ae716d2a59e3663e0a712a362e78bce7ed673f5d';

@ProviderFor(placeSuggestionsRepository)
final placeSuggestionsRepositoryProvider =
    PlaceSuggestionsRepositoryProvider._();

final class PlaceSuggestionsRepositoryProvider
    extends
        $FunctionalProvider<
          PlaceSuggestionsRepository,
          PlaceSuggestionsRepository,
          PlaceSuggestionsRepository
        >
    with $Provider<PlaceSuggestionsRepository> {
  PlaceSuggestionsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'placeSuggestionsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$placeSuggestionsRepositoryHash();

  @$internal
  @override
  $ProviderElement<PlaceSuggestionsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlaceSuggestionsRepository create(Ref ref) {
    return placeSuggestionsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaceSuggestionsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaceSuggestionsRepository>(value),
    );
  }
}

String _$placeSuggestionsRepositoryHash() =>
    r'e8089155750ac1f0d9838220aedd751984897932';

@ProviderFor(locationService)
final locationServiceProvider = LocationServiceProvider._();

final class LocationServiceProvider
    extends
        $FunctionalProvider<LocationService, LocationService, LocationService>
    with $Provider<LocationService> {
  LocationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationServiceHash();

  @$internal
  @override
  $ProviderElement<LocationService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LocationService create(Ref ref) {
    return locationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocationService>(value),
    );
  }
}

String _$locationServiceHash() => r'f7fd0ffb4698d96772b6ac4b6d14a429632720b2';

/// Preset per l'attività: luoghi più usati dal gruppo.

@ProviderFor(suggestedPlaces)
final suggestedPlacesProvider = SuggestedPlacesFamily._();

/// Preset per l'attività: luoghi più usati dal gruppo.

final class SuggestedPlacesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlaceCandidate>>,
          List<PlaceCandidate>,
          FutureOr<List<PlaceCandidate>>
        >
    with
        $FutureModifier<List<PlaceCandidate>>,
        $FutureProvider<List<PlaceCandidate>> {
  /// Preset per l'attività: luoghi più usati dal gruppo.
  SuggestedPlacesProvider._({
    required SuggestedPlacesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'suggestedPlacesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$suggestedPlacesHash();

  @override
  String toString() {
    return r'suggestedPlacesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PlaceCandidate>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PlaceCandidate>> create(Ref ref) {
    final argument = this.argument as String;
    return suggestedPlaces(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SuggestedPlacesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$suggestedPlacesHash() => r'9c8ce6b148255289e86a44eac5275e963c713954';

/// Preset per l'attività: luoghi più usati dal gruppo.

final class SuggestedPlacesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PlaceCandidate>>, String> {
  SuggestedPlacesFamily._()
    : super(
        retry: null,
        name: r'suggestedPlacesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Preset per l'attività: luoghi più usati dal gruppo.

  SuggestedPlacesProvider call(String activityId) =>
      SuggestedPlacesProvider._(argument: activityId, from: this);

  @override
  String toString() => r'suggestedPlacesProvider';
}

/// Luogo scelto (in memoria fino al lancio, Fase 4).

@ProviderFor(PlaceSelection)
final placeSelectionProvider = PlaceSelectionProvider._();

/// Luogo scelto (in memoria fino al lancio, Fase 4).
final class PlaceSelectionProvider
    extends $NotifierProvider<PlaceSelection, PlaceCandidate?> {
  /// Luogo scelto (in memoria fino al lancio, Fase 4).
  PlaceSelectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'placeSelectionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$placeSelectionHash();

  @$internal
  @override
  PlaceSelection create() => PlaceSelection();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaceCandidate? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaceCandidate?>(value),
    );
  }
}

String _$placeSelectionHash() => r'd029d16f7736578a6c4fc62c703f7a8c711d480d';

/// Luogo scelto (in memoria fino al lancio, Fase 4).

abstract class _$PlaceSelection extends $Notifier<PlaceCandidate?> {
  PlaceCandidate? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PlaceCandidate?, PlaceCandidate?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlaceCandidate?, PlaceCandidate?>,
              PlaceCandidate?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Ricerca con debounce; ignora le risposte di query superate.

@ProviderFor(PlaceSearch)
final placeSearchProvider = PlaceSearchProvider._();

/// Ricerca con debounce; ignora le risposte di query superate.
final class PlaceSearchProvider
    extends $NotifierProvider<PlaceSearch, AsyncValue<List<PlaceCandidate>>> {
  /// Ricerca con debounce; ignora le risposte di query superate.
  PlaceSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'placeSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$placeSearchHash();

  @$internal
  @override
  PlaceSearch create() => PlaceSearch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<PlaceCandidate>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<PlaceCandidate>>>(
        value,
      ),
    );
  }
}

String _$placeSearchHash() => r'6998bcb48a86a6fa6569229d55349c75f66143c7';

/// Ricerca con debounce; ignora le risposte di query superate.

abstract class _$PlaceSearch
    extends $Notifier<AsyncValue<List<PlaceCandidate>>> {
  AsyncValue<List<PlaceCandidate>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<PlaceCandidate>>,
              AsyncValue<List<PlaceCandidate>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<PlaceCandidate>>,
                AsyncValue<List<PlaceCandidate>>
              >,
              AsyncValue<List<PlaceCandidate>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
