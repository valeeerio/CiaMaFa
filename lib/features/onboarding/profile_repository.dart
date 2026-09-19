import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants.dart';

class Profile {
  const Profile({
    required this.id,
    required this.nickname,
    required this.notificationsEnabled,
  });

  factory Profile.fromRow(Map<String, dynamic> row) => Profile(
    id: row['id'] as String,
    nickname: row['nickname'] as String,
    notificationsEnabled: row['notifications_enabled'] as bool,
  );

  final String id;
  final String nickname;
  final bool notificationsEnabled;
}

class NicknameTakenException implements Exception {
  const NicknameTakenException();
}

abstract interface class ProfileRepository {
  /// Profilo dell'utente corrente, `null` se senza sessione o senza profilo.
  Future<Profile?> fetchCurrentProfile();

  /// Accede in modo anonimo (se serve) e crea il profilo nel gruppo unico.
  /// Lancia [NicknameTakenException] se il nickname è già usato.
  Future<Profile> joinGroup({
    required String nickname,
    required bool notificationsEnabled,
  });
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Profile?> fetchCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    return row == null ? null : Profile.fromRow(row);
  }

  @override
  Future<Profile> joinGroup({
    required String nickname,
    required bool notificationsEnabled,
  }) async {
    final user =
        _client.auth.currentUser ??
        (await _client.auth.signInAnonymously()).user!;
    try {
      final row = await _client
          .from('profiles')
          .insert({
            'id': user.id,
            'group_id': defaultGroupId,
            'nickname': nickname,
            'notifications_enabled': notificationsEnabled,
          })
          .select()
          .single();
      return Profile.fromRow(row);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Profilo già esistente per questo utente: lo riusiamo.
        if ((e.message).contains('profiles_pkey')) {
          final existing = await fetchCurrentProfile();
          if (existing != null) return existing;
        }
        throw const NicknameTakenException();
      }
      rethrow;
    }
  }
}
