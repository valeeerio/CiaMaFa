import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/realtime.dart';
import 'chat_message.dart';

abstract interface class ChatRepository {
  /// Messaggi di oggi, dal più vecchio al più recente (la RLS nasconde gli scaduti).
  Future<List<ChatMessage>> todaysMessages({required String selfId});

  /// Invia un messaggio: [id] lo sceglie l'app (serve al path dell'immagine).
  Future<void> send({required String id, String? text, String? imagePath});

  /// Carica l'immagine (già compressa, JPEG) e restituisce il path nel bucket.
  Future<String> uploadImage({
    required String messageId,
    required Uint8List bytes,
  });

  /// Elimina un proprio messaggio: prima il file (se c'è), poi la riga.
  Future<void> delete(ChatMessage message);

  /// Aggiunge (o, se [mine], toglie) la propria reazione.
  Future<void> toggleReaction({
    required String messageId,
    required String emoji,
    required bool mine,
  });

  /// Link temporaneo (1 h) per mostrare un'immagine del bucket privato.
  Future<String> signedImageUrl(String path);

  /// Emette a ogni cambiamento di messaggi o reazioni (Realtime, app aperta).
  Stream<void> changes();
}

const chatImagesBucket = 'chat-images';

class SupabaseChatRepository implements ChatRepository {
  SupabaseChatRepository(this._client);

  final SupabaseClient _client;
  String? _groupId;

  static const _select =
      'id, sender_id, text, image_path, created_at, '
      'profiles!messages_sender_id_fkey(nickname), '
      'message_reactions(emoji, profile_id, created_at)';

  String get _selfId => _client.auth.currentUser!.id;

  Future<String> _group() async =>
      _groupId ??=
          (await _client
                  .from('profiles')
                  .select('group_id')
                  .eq('id', _selfId)
                  .single())['group_id']
              as String;

  @override
  Future<List<ChatMessage>> todaysMessages({required String selfId}) async {
    final rows = await _client
        .from('messages')
        .select(_select)
        .order('created_at', ascending: true);
    return [for (final r in rows) ChatMessage.fromJson(r, selfId: selfId)];
  }

  @override
  Future<void> send({
    required String id,
    String? text,
    String? imagePath,
  }) async {
    await _client.from('messages').insert({
      'id': id,
      'group_id': await _group(),
      'sender_id': _selfId,
      'text': text,
      'image_path': imagePath,
    });
  }

  @override
  Future<String> uploadImage({
    required String messageId,
    required Uint8List bytes,
  }) async {
    final path = '${await _group()}/$messageId.jpg';
    await _client.storage
        .from(chatImagesBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
    return path;
  }

  @override
  Future<void> delete(ChatMessage message) async {
    final path = message.imagePath;
    if (path != null) {
      await _client.storage.from(chatImagesBucket).remove([path]);
    }
    // La RLS lascia eliminare solo i propri messaggi: senza righe restituite
    // non è stato eliminato nulla.
    final deleted = await _client
        .from('messages')
        .delete()
        .eq('id', message.id)
        .select('id');
    if (deleted.isEmpty) throw StateError('Messaggio non eliminato');
  }

  @override
  Future<void> toggleReaction({
    required String messageId,
    required String emoji,
    required bool mine,
  }) async {
    if (mine) {
      await _client.from('message_reactions').delete().match({
        'message_id': messageId,
        'profile_id': _selfId,
        'emoji': emoji,
      });
      return;
    }
    try {
      await _client.from('message_reactions').insert({
        'message_id': messageId,
        'profile_id': _selfId,
        'emoji': emoji,
      });
    } on PostgrestException catch (e) {
      // Doppio tocco: la reazione c'è già, va bene così.
      if (e.code != '23505') rethrow;
    }
  }

  @override
  Future<String> signedImageUrl(String path) =>
      _client.storage.from(chatImagesBucket).createSignedUrl(path, 3600);

  @override
  Stream<void> changes() => realtimeStream<void>(_client, 'chat-live', const {
    'messages': PostgresChangeEvent.all,
    'message_reactions': PostgresChangeEvent.all,
  }, (table, row) async => true);
}
