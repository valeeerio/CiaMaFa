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
  /// Vero se c'è già una sessione (Apple/Google, o ancora anonima).
  bool get isSignedIn;

  /// Vero se la sessione corrente è ancora anonima (nessun account
  /// Apple/Google collegato: su un telefono nuovo si perderebbe il profilo).
  bool get isAnonymous;

  /// Profilo dell'utente corrente, `null` se senza sessione o senza profilo.
  Future<Profile?> fetchCurrentProfile();

  /// Cambia il nickname. Lancia [NicknameTakenException] se è già usato
  /// (maiuscole e spazi ai bordi non contano).
  Future<Profile> updateNickname(String nickname);

  /// Attiva/disattiva le notifiche.
  Future<Profile> setNotificationsEnabled(bool enabled);

  /// Cancella il proprio profilo (e i piani ancora attivi) ed esce.
  Future<void> deleteProfile();

  /// Crea il profilo nel gruppo unico per l'utente già autenticato (Apple o
  /// Google, Fase 10). Lancia [NicknameTakenException] se il nickname è già
  /// usato.
  Future<Profile> joinGroup({
    required String nickname,
    required bool notificationsEnabled,
  });
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  bool get isSignedIn => _client.auth.currentUser != null;

  @override
  bool get isAnonymous => _client.auth.currentUser?.isAnonymous ?? false;

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
  Future<Profile> updateNickname(String nickname) async {
    try {
      final row = await _client
          .from('profiles')
          .update({'nickname': nickname.trim()})
          .eq('id', _client.auth.currentUser!.id)
          .select()
          .single();
      return Profile.fromRow(row);
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw const NicknameTakenException();
      rethrow;
    }
  }

  @override
  Future<Profile> setNotificationsEnabled(bool enabled) async {
    final row = await _client
        .from('profiles')
        .update({'notifications_enabled': enabled})
        .eq('id', _client.auth.currentUser!.id)
        .select()
        .single();
    return Profile.fromRow(row);
  }

  @override
  Future<void> deleteProfile() async {
    await _client.rpc<void>('delete_my_profile');
    try {
      // L'utente non esiste più sul server: basta chiudere la sessione locale.
      await _client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {}
  }

  @override
  Future<Profile> joinGroup({
    required String nickname,
    required bool notificationsEnabled,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      // Non dovrebbe succedere: la schermata fa accedere con Apple/Google
      // prima di arrivare qui.
      throw StateError('Devi accedere con Apple o Google prima di continuare.');
    }
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
