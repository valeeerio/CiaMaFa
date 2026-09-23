import 'package:ciamafa/features/onboarding/social_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('SocialProvider.label', () {
    test('shows the provider name', () {
      expect(SocialProvider.apple.label, 'Apple');
      expect(SocialProvider.google.label, 'Google');
    });
  });

  group('isIdentityAlreadyLinkedError', () {
    test('true when the server reports the known error code', () {
      expect(
        isIdentityAlreadyLinkedError(
          const AuthException('boh', code: 'identity_already_exists'),
        ),
        isTrue,
      );
    });

    test('true when only the message says so (no code)', () {
      expect(
        isIdentityAlreadyLinkedError(
          const AuthException('Identity is already linked to another user'),
        ),
        isTrue,
      );
    });

    test('false for an unrelated auth error', () {
      expect(
        isIdentityAlreadyLinkedError(const AuthException('network error')),
        isFalse,
      );
    });
  });
}
