/// Le sei reazioni veloci del "🙂+".
const quickReactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

/// Una reazione emoji a un messaggio, già aggregata.
class Reaction {
  const Reaction({
    required this.emoji,
    required this.count,
    required this.mine,
  });

  final String emoji;
  final int count;

  /// Ho messo io questa reazione.
  final bool mine;
}

/// Un messaggio della chat di oggi.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderNickname,
    required this.createdAt,
    required this.isMine,
    this.text,
    this.imagePath,
    this.reactions = const [],
  });

  final String id;
  final String senderId;
  final String senderNickname;
  final String? text;

  /// Path nel bucket `chat-images` (`{group_id}/{id}.jpg`).
  final String? imagePath;
  final DateTime createdAt;
  final bool isMine;
  final List<Reaction> reactions;

  bool get hasImage => imagePath != null;

  /// Da una riga di `messages` con `profiles(nickname)` e `message_reactions`
  /// incorporati. [selfId] è il profilo corrente.
  factory ChatMessage.fromJson(
    Map<String, dynamic> json, {
    required String selfId,
  }) {
    final senderId = json['sender_id'] as String;
    final rows =
        [
          for (final r in (json['message_reactions'] as List? ?? const []))
            r as Map<String, dynamic>,
        ]..sort(
          (a, b) =>
              DateTime.parse(a['created_at'] as String)
                  .compareTo(DateTime.parse(b['created_at'] as String)),
        );
    // Conteggio per emoji, nell'ordine in cui è comparsa la prima volta.
    final counts = <String, int>{};
    final mine = <String>{};
    for (final r in rows) {
      final emoji = r['emoji'] as String;
      counts[emoji] = (counts[emoji] ?? 0) + 1;
      if (r['profile_id'] == selfId) mine.add(emoji);
    }
    return ChatMessage(
      id: json['id'] as String,
      senderId: senderId,
      senderNickname:
          (json['profiles'] as Map<String, dynamic>?)?['nickname'] as String? ??
          '?',
      text: json['text'] as String?,
      imagePath: json['image_path'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      isMine: senderId == selfId,
      reactions: [
        for (final e in counts.entries)
          Reaction(emoji: e.key, count: e.value, mine: mine.contains(e.key)),
      ],
    );
  }
}
