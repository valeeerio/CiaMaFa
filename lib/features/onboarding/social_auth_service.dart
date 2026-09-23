import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart' as google;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants.dart';

/// Accesso con Apple o Google: nessuna email da digitare, nessun invio da
/// gestire (il fornitore fa tutto).
enum SocialProvider {
  apple,
  google;

  /// "Accedi con Apple" / "Accedi con Google".
  String get label => switch (this) {
    SocialProvider.apple => 'Apple',
    SocialProvider.google => 'Google',
  };
}

/// L'utente ha annullato il login: non è un errore da mostrare.
class SocialSignInCancelled implements Exception {
  const SocialSignInCancelled();
}

/// Questo account Apple/Google è già collegato a un altro profilo del gruppo.
class IdentityAlreadyLinkedException implements Exception {
  const IdentityAlreadyLinkedException();
}

abstract interface class SocialAuthService {
  /// Accede con [provider]: crea o riusa l'utente per questa identità.
  Future<void> signIn(SocialProvider provider);

  /// Collega [provider] all'utente anonimo corrente, mantenendo lo stesso
  /// profilo (nickname, piani, voti). Lancia [IdentityAlreadyLinkedException]
  /// se quell'identità appartiene già a un altro utente.
  Future<void> link(SocialProvider provider);
}

/// Token identità ottenuto da Apple/Google, pronto per Supabase.
class _IdToken {
  const _IdToken({required this.provider, required this.idToken, this.nonce});

  final OAuthProvider provider;
  final String idToken;
  final String? nonce;
}

/// Vero se [e] segnala che l'identità è già collegata a un altro utente
/// (non lo si può ricollegare al profilo corrente).
bool isIdentityAlreadyLinkedError(AuthException e) =>
    e.code == 'identity_already_exists' ||
    e.message.toLowerCase().contains('already linked');

class SupabaseSocialAuthService implements SocialAuthService {
  SupabaseSocialAuthService(this._client);

  final SupabaseClient _client;
  bool _googleReady = false;

  Future<void> _ensureGoogleReady() async {
    if (_googleReady) return;
    await google.GoogleSignIn.instance.initialize(
      serverClientId: Env.googleWebClientId,
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? Env.googleIosClientId
          : null,
    );
    _googleReady = true;
  }

  Future<_IdToken> _appleToken() async {
    final rawNonce = _client.auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [AppleIDAuthorizationScopes.email],
        nonce: hashedNonce,
      );
      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AuthException('Apple non ha restituito un token id.');
      }
      return _IdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const SocialSignInCancelled();
      }
      rethrow;
    }
  }

  Future<_IdToken> _googleToken() async {
    await _ensureGoogleReady();
    try {
      final account = await google.GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthException('Google non ha restituito un token id.');
      }
      return _IdToken(provider: OAuthProvider.google, idToken: idToken);
    } on google.GoogleSignInException catch (e) {
      if (e.code == google.GoogleSignInExceptionCode.canceled) {
        throw const SocialSignInCancelled();
      }
      rethrow;
    }
  }

  Future<_IdToken> _tokenFor(SocialProvider provider) => switch (provider) {
    SocialProvider.apple => _appleToken(),
    SocialProvider.google => _googleToken(),
  };

  @override
  Future<void> signIn(SocialProvider provider) async {
    final t = await _tokenFor(provider);
    await _client.auth.signInWithIdToken(
      provider: t.provider,
      idToken: t.idToken,
      nonce: t.nonce,
    );
  }

  @override
  Future<void> link(SocialProvider provider) async {
    final t = await _tokenFor(provider);
    try {
      await _client.auth.linkIdentityWithIdToken(
        provider: t.provider,
        idToken: t.idToken,
        nonce: t.nonce,
      );
    } on AuthException catch (e) {
      if (isIdentityAlreadyLinkedError(e)) {
        throw const IdentityAlreadyLinkedException();
      }
      rethrow;
    }
  }
}
