import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/router.dart';
import '../../core/supabase_client.dart';
import '../onboarding/onboarding_provider.dart';
import 'device_token_repository.dart';
import 'push_messaging.dart';

part 'push_provider.g.dart';

/// Firebase Messaging. In `main` si sostituisce con la versione reale quando
/// Firebase è configurato; di default (e nei test) non fa nulla.
@Riverpod(keepAlive: true)
PushMessaging pushMessaging(Ref ref) => const NoPushMessaging();

@Riverpod(keepAlive: true)
DeviceTokenRepository deviceTokenRepository(Ref ref) =>
    SupabaseDeviceTokenRepository(supabase);

/// Tiene allineato il token del telefono con il profilo: se le notifiche sono
/// accese chiede il permesso e registra il token (e i suoi rinnovi); se le spegni
/// lo toglie. Tutto "best effort": un errore non deve mai disturbare l'app.
@Riverpod(keepAlive: true)
class PushController extends _$PushController {
  StreamSubscription<String>? _refreshes;
  String? _registered;
  (String, bool)? _last;

  @override
  void build() {
    final push = ref.watch(pushMessagingProvider);
    final profile = ref.watch(currentProfileProvider).value;
    ref.onDispose(() => _refreshes?.cancel());
    if (!push.isAvailable || profile == null) return;
    // Conta solo chi sei e l'interruttore: cambiare nickname non ripete tutto.
    final key = (profile.id, profile.notificationsEnabled);
    if (key == _last) return;
    _last = key;
    unawaited(profile.notificationsEnabled ? _enable(push) : _disable(push));
  }

  Future<void> _register(PushMessaging push, String token) async {
    await ref
        .read(deviceTokenRepositoryProvider)
        .register(token: token, platform: push.platform);
    _registered = token;
  }

  Future<void> _enable(PushMessaging push) async {
    try {
      if (!await push.requestPermission()) return;
      final token = await push.token();
      if (token != null) await _register(push, token);
      await _refreshes?.cancel();
      _refreshes = push.tokenRefreshes.listen((t) {
        unawaited(_register(push, t).catchError((Object _) {}));
      });
    } catch (_) {}
  }

  Future<void> _disable(PushMessaging push) async {
    try {
      await _refreshes?.cancel();
      _refreshes = null;
      final token = _registered ?? await push.token();
      if (token != null) {
        await ref.read(deviceTokenRepositoryProvider).unregister(token);
        _registered = null;
      }
    } catch (_) {}
  }
}

/// Tocco su una notifica: apre il piano (o la lista). Se l'app era chiusa,
/// aspetta il profilo e mette la Home sotto.
@Riverpod(keepAlive: true)
class PushRouting extends _$PushRouting {
  StreamSubscription<String>? _opened;

  @override
  void build() {
    final push = ref.watch(pushMessagingProvider);
    ref.onDispose(() => _opened?.cancel());
    if (!push.isAvailable) return;
    _opened = push.openedRoutes.listen(
      (route) => _open(ref.read(routerProvider), route),
    );
    unawaited(_openInitial(push));
  }

  /// La lista sta nella tab Piani; il dettaglio (a tutto schermo) ci si appoggia sopra.
  void _open(GoRouter router, String route) {
    router.go('/plans');
    if (route != '/plans') unawaited(router.push(route));
  }

  Future<void> _openInitial(PushMessaging push) async {
    try {
      final route = await push.initialRoute();
      if (route == null) return;
      if (await ref.read(currentProfileProvider.future) == null) return;
      final router = ref.read(routerProvider);
      _open(router, route);
    } catch (_) {}
  }
}
