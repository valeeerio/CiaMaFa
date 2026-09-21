import 'package:ciamafa/features/chat/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _row({
  String id = 'm1',
  String senderId = 'u2',
  String? text = 'ciao',
  String? imagePath,
  List<Map<String, dynamic>> reactions = const [],
}) => {
  'id': id,
  'sender_id': senderId,
  'text': text,
  'image_path': imagePath,
  'created_at': '2026-09-21T10:30:00+00:00',
  'profiles': {'nickname': 'Marta'},
  'message_reactions': reactions,
};

Map<String, dynamic> _reaction(String emoji, String by, String at) => {
  'emoji': emoji,
  'profile_id': by,
  'created_at': at,
};

void main() {
  test('parses a text message', () {
    final m = ChatMessage.fromJson(_row(), selfId: 'u1');
    expect(m.id, 'm1');
    expect(m.senderId, 'u2');
    expect(m.senderNickname, 'Marta');
    expect(m.text, 'ciao');
    expect(m.imagePath, isNull);
    expect(m.hasImage, isFalse);
    expect(m.createdAt, DateTime.utc(2026, 9, 21, 10, 30));
    expect(m.reactions, isEmpty);
  });

  test('parses an image message with caption', () {
    final m = ChatMessage.fromJson(
      _row(text: 'guarda', imagePath: 'g/m1.jpg'),
      selfId: 'u1',
    );
    expect(m.hasImage, isTrue);
    expect(m.imagePath, 'g/m1.jpg');
    expect(m.text, 'guarda');
  });

  test('isMine compares the sender with the current profile', () {
    expect(
      ChatMessage.fromJson(_row(senderId: 'u1'), selfId: 'u1').isMine,
      isTrue,
    );
    expect(
      ChatMessage.fromJson(_row(senderId: 'u2'), selfId: 'u1').isMine,
      isFalse,
    );
  });

  test('reactions are counted per emoji, in order of first use', () {
    final m = ChatMessage.fromJson(
      _row(
        reactions: [
          _reaction('😂', 'u3', '2026-09-21T10:32:00+00:00'),
          _reaction('👍', 'u2', '2026-09-21T10:31:00+00:00'),
          _reaction('😂', 'u2', '2026-09-21T10:33:00+00:00'),
        ],
      ),
      selfId: 'u1',
    );
    expect(m.reactions.map((r) => (r.emoji, r.count)), [('👍', 1), ('😂', 2)]);
  });

  test('a reaction is "mine" only if I gave it', () {
    final m = ChatMessage.fromJson(
      _row(
        reactions: [
          _reaction('👍', 'u1', '2026-09-21T10:31:00+00:00'),
          _reaction('👍', 'u2', '2026-09-21T10:32:00+00:00'),
          _reaction('❤️', 'u2', '2026-09-21T10:33:00+00:00'),
        ],
      ),
      selfId: 'u1',
    );
    expect(m.reactions.firstWhere((r) => r.emoji == '👍').mine, isTrue);
    expect(m.reactions.firstWhere((r) => r.emoji == '❤️').mine, isFalse);
  });

  test('a missing sender profile falls back to a placeholder name', () {
    final row = _row()..['profiles'] = null;
    expect(ChatMessage.fromJson(row, selfId: 'u1').senderNickname, '?');
  });
}
