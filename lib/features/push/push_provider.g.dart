// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Firebase Messaging. In `main` si sostituisce con la versione reale quando
/// Firebase è configurato; di default (e nei test) non fa nulla.

@ProviderFor(pushMessaging)
final pushMessagingProvider = PushMessagingProvider._();

/// Firebase Messaging. In `main` si sostituisce con la versione reale quando
/// Firebase è configurato; di default (e nei test) non fa nulla.

final class PushMessagingProvider
    extends $FunctionalProvider<PushMessaging, PushMessaging, PushMessaging>
    with $Provider<PushMessaging> {
  /// Firebase Messaging. In `main` si sostituisce con la versione reale quando
  /// Firebase è configurato; di default (e nei test) non fa nulla.
  PushMessagingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushMessagingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushMessagingHash();

  @$internal
  @override
  $ProviderElement<PushMessaging> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PushMessaging create(Ref ref) {
    return pushMessaging(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PushMessaging value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PushMessaging>(value),
    );
  }
}

String _$pushMessagingHash() => r'6b23dc75eefdd211f71c20728c5c0bfe12077fdb';

@ProviderFor(deviceTokenRepository)
final deviceTokenRepositoryProvider = DeviceTokenRepositoryProvider._();

final class DeviceTokenRepositoryProvider
    extends
        $FunctionalProvider<
          DeviceTokenRepository,
          DeviceTokenRepository,
          DeviceTokenRepository
        >
    with $Provider<DeviceTokenRepository> {
  DeviceTokenRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceTokenRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceTokenRepositoryHash();

  @$internal
  @override
  $ProviderElement<DeviceTokenRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeviceTokenRepository create(Ref ref) {
    return deviceTokenRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceTokenRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceTokenRepository>(value),
    );
  }
}

String _$deviceTokenRepositoryHash() =>
    r'f8c5f4eaa305ffebe86eb5bd88b8db02647faa4e';

/// Tiene allineato il token del telefono con il profilo: se le notifiche sono
/// accese chiede il permesso e registra il token (e i suoi rinnovi); se le spegni
/// lo toglie. Tutto "best effort": un errore non deve mai disturbare l'app.

@ProviderFor(PushController)
final pushControllerProvider = PushControllerProvider._();

/// Tiene allineato il token del telefono con il profilo: se le notifiche sono
/// accese chiede il permesso e registra il token (e i suoi rinnovi); se le spegni
/// lo toglie. Tutto "best effort": un errore non deve mai disturbare l'app.
final class PushControllerProvider
    extends $NotifierProvider<PushController, void> {
  /// Tiene allineato il token del telefono con il profilo: se le notifiche sono
  /// accese chiede il permesso e registra il token (e i suoi rinnovi); se le spegni
  /// lo toglie. Tutto "best effort": un errore non deve mai disturbare l'app.
  PushControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushControllerHash();

  @$internal
  @override
  PushController create() => PushController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$pushControllerHash() => r'944e817e88caa6b8e256710ba733a5ea4d2c7356';

/// Tiene allineato il token del telefono con il profilo: se le notifiche sono
/// accese chiede il permesso e registra il token (e i suoi rinnovi); se le spegni
/// lo toglie. Tutto "best effort": un errore non deve mai disturbare l'app.

abstract class _$PushController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Tocco su una notifica: apre il piano (o la lista). Se l'app era chiusa,
/// aspetta il profilo e mette la Home sotto.

@ProviderFor(PushRouting)
final pushRoutingProvider = PushRoutingProvider._();

/// Tocco su una notifica: apre il piano (o la lista). Se l'app era chiusa,
/// aspetta il profilo e mette la Home sotto.
final class PushRoutingProvider extends $NotifierProvider<PushRouting, void> {
  /// Tocco su una notifica: apre il piano (o la lista). Se l'app era chiusa,
  /// aspetta il profilo e mette la Home sotto.
  PushRoutingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushRoutingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushRoutingHash();

  @$internal
  @override
  PushRouting create() => PushRouting();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$pushRoutingHash() => r'67fb3e9401b62e40bafca7976f22f6f5fe213dd3';

/// Tocco su una notifica: apre il piano (o la lista). Se l'app era chiusa,
/// aspetta il profilo e mette la Home sotto.

abstract class _$PushRouting extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
