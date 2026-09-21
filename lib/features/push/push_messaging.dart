import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants.dart';

/// La destinazione dentro l'app a cui porta una notifica (`/plans/<id>`), solo
/// se è una nostra rotta sui piani; altrimenti `null`.
String? validPushRoute(Object? route) {
  if (route is! String) return null;
  return route == '/plans' || route.startsWith('/plans/') ? route : null;
}

/// Il minimo di Firebase Cloud Messaging che serve all'app. Dietro
/// un'interfaccia per poterlo sostituire nei test e per far partire l'app anche
/// senza Firebase configurato.
abstract interface class PushMessaging {
  /// Firebase è configurato e inizializzato.
  bool get isAvailable;

  /// "ios" o "android".
  String get platform;

  /// Chiede il permesso di mostrare notifiche. `true` se concesso.
  Future<bool> requestPermission();

  /// Token FCM di questo telefono, se disponibile (su iPhone serve APNs).
  Future<String?> token();

  Stream<String> get tokenRefreshes;

  /// Rotte aperte toccando una notifica con l'app in secondo piano.
  Stream<String> get openedRoutes;

  /// Rotta della notifica che ha avviato l'app da chiusa, se c'è.
  Future<String?> initialRoute();
}

/// Senza Firebase (config mancante, piattaforma non supportata, test).
class NoPushMessaging implements PushMessaging {
  const NoPushMessaging();

  @override
  bool get isAvailable => false;

  @override
  String get platform => 'none';

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();

  @override
  Stream<String> get openedRoutes => const Stream.empty();

  @override
  Future<String?> initialRoute() async => null;
}

class FirebasePushMessaging implements PushMessaging {
  FirebasePushMessaging._(this.platform);

  @override
  final String platform;

  /// Opzioni Firebase dai valori di `env.json`; `null` se mancano o se la
  /// piattaforma non è iOS/Android.
  static FirebaseOptions? optionsFromEnv(TargetPlatform platform) {
    final ios = platform == TargetPlatform.iOS;
    if (!ios && platform != TargetPlatform.android) return null;
    final apiKey = ios ? Env.firebaseIosApiKey : Env.firebaseAndroidApiKey;
    final appId = ios ? Env.firebaseIosAppId : Env.firebaseAndroidAppId;
    if (apiKey.isEmpty ||
        appId.isEmpty ||
        Env.firebaseSenderId.isEmpty ||
        Env.firebaseProjectId.isEmpty) {
      return null;
    }
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: Env.firebaseSenderId,
      projectId: Env.firebaseProjectId,
      iosBundleId: ios ? 'com.valeriomortella.ciamafa.ciamafa' : null,
    );
  }

  /// Inizializza Firebase; `null` se non configurato o se l'avvio fallisce
  /// (l'app parte comunque, senza push).
  static Future<FirebasePushMessaging?> create({
    TargetPlatform? platform,
  }) async {
    final target = platform ?? defaultTargetPlatform;
    final options = optionsFromEnv(target);
    if (options == null) return null;
    try {
      await Firebase.initializeApp(options: options);
      // Con l'app aperta vale il banner in-app (Realtime): niente notifica di
      // sistema in più.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: false,
            badge: false,
            sound: false,
          );
      return FirebasePushMessaging._(
        target == TargetPlatform.iOS ? 'ios' : 'android',
      );
    } catch (e) {
      debugPrint('Push disattivate: $e');
      return null;
    }
  }

  FirebaseMessaging get _fm => FirebaseMessaging.instance;

  @override
  bool get isAvailable => true;

  @override
  Future<bool> requestPermission() async {
    try {
      final settings = await _fm.requestPermission();
      debugPrint('Push: permesso ${settings.authorizationStatus.name}');
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('Push: permesso non ottenuto: $e');
      return false;
    }
  }

  @override
  Future<String?> token() async {
    try {
      if (platform == 'ios') {
        // Il token APNs arriva qualche secondo dopo il permesso: senza, FCM non
        // può generare il suo.
        String? apns;
        for (var i = 0; i < 15 && apns == null; i++) {
          apns = await _fm.getAPNSToken();
          if (apns == null)
            await Future<void>.delayed(const Duration(seconds: 1));
        }
        debugPrint('Push: token APNs ${apns == null ? 'ASSENTE' : 'ok'}');
        if (apns == null) return null;
      }
      final token = await _fm.getToken();
      debugPrint('Push: token FCM ${token == null ? 'ASSENTE' : 'ok'}');
      return token;
    } catch (e) {
      // Es. iPhone senza APNs (account Apple non ancora attivo).
      debugPrint('Push: token non disponibile: $e');
      return null;
    }
  }

  @override
  Stream<String> get tokenRefreshes => _fm.onTokenRefresh;

  @override
  Stream<String> get openedRoutes => FirebaseMessaging.onMessageOpenedApp
      .map((m) => validPushRoute(m.data['route']))
      .where((r) => r != null)
      .cast<String>();

  @override
  Future<String?> initialRoute() async {
    final message = await _fm.getInitialMessage();
    return validPushRoute(message?.data['route']);
  }
}
