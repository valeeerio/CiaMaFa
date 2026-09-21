import 'dart:async';
import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../core/supabase_client.dart';
import '../onboarding/onboarding_provider.dart';
import 'chat_message.dart';
import 'chat_repository.dart';
import 'image_picker_service.dart';

part 'chat_provider.g.dart';

@Riverpod(keepAlive: true)
ChatRepository chatRepository(Ref ref) => SupabaseChatRepository(supabase);

@Riverpod(keepAlive: true)
ImagePickerService imagePickerService(Ref ref) => DeviceImagePicker();

/// Messaggi di oggi, sempre aggiornati: si ricarica a ogni cambiamento di
/// messaggi o reazioni (Realtime).
@riverpod
Stream<List<ChatMessage>> liveMessages(Ref ref) async* {
  final selfId = ref.watch(currentProfileProvider).value?.id;
  if (selfId == null) return;
  final repo = ref.watch(chatRepositoryProvider);
  yield await repo.todaysMessages(selfId: selfId);
  await for (final _ in repo.changes()) {
    yield await repo.todaysMessages(selfId: selfId);
  }
}

/// Link temporaneo dell'immagine di un messaggio (in cache finché la schermata vive).
@riverpod
Future<String> chatImageUrl(Ref ref, String path) =>
    ref.watch(chatRepositoryProvider).signedImageUrl(path);

/// Azioni della chat. Ognuna dice se è andata a buon fine: la schermata ripristina
/// il testo e avvisa in caso contrario. keepAlive: terminano anche se la schermata
/// viene chiusa a metà.
@Riverpod(keepAlive: true)
class ChatComposer extends _$ChatComposer {
  static const _uuid = Uuid();

  @override
  void build() {}

  ChatRepository get _repo => ref.read(chatRepositoryProvider);

  /// Invia un messaggio di testo (vuoto o solo spazi: niente).
  Future<bool> sendText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    return _try(() => _repo.send(id: _uuid.v4(), text: trimmed));
  }

  /// Invia una foto, con una didascalia opzionale. Il file va su prima del messaggio.
  Future<bool> sendImage(Uint8List bytes, {String? caption}) {
    final trimmed = caption?.trim();
    return _try(() async {
      final id = _uuid.v4();
      final path = await _repo.uploadImage(messageId: id, bytes: bytes);
      await _repo.send(
        id: id,
        imagePath: path,
        text: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      );
    });
  }

  /// Elimina un messaggio. Solo i propri: su quelli altrui non fa nulla (la vera
  /// barriera è la RLS).
  Future<bool> delete(ChatMessage message) {
    if (!message.isMine) return Future.value(false);
    return _try(() => _repo.delete(message));
  }

  /// Aggiunge o toglie la propria reazione [emoji].
  Future<bool> toggleReaction(ChatMessage message, String emoji) {
    final mine = message.reactions.any((r) => r.emoji == emoji && r.mine);
    return _try(
      () => _repo.toggleReaction(
        messageId: message.id,
        emoji: emoji,
        mine: mine,
      ),
    );
  }

  Future<bool> _try(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (_) {
      return false;
    }
  }
}
