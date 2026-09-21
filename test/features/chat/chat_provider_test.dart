import 'dart:async';
import 'dart:typed_data';

import 'package:ciamafa/features/chat/chat_message.dart';
import 'package:ciamafa/features/chat/chat_provider.dart';
import 'package:ciamafa/features/chat/chat_repository.dart';
import 'package:ciamafa/features/onboarding/onboarding_provider.dart';
import 'package:ciamafa/features/onboarding/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockChat extends Mock implements ChatRepository {}

class MockProfiles extends Mock implements ProfileRepository {}

ChatMessage _msg({
  String id = 'm1',
  bool mine = true,
  String? imagePath,
  List<Reaction> reactions = const [],
}) => ChatMessage(
  id: id,
  senderId: mine ? 'u1' : 'u2',
  senderNickname: mine ? 'Valerio' : 'Marta',
  text: 'ciao',
  imagePath: imagePath,
  createdAt: DateTime.utc(2026, 9, 21, 10),
  isMine: mine,
  reactions: reactions,
);

void main() {
  late MockChat repo;
  late MockProfiles profiles;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(_msg());
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    repo = MockChat();
    profiles = MockProfiles();
    when(() => profiles.fetchCurrentProfile()).thenAnswer(
      (_) async => const Profile(
        id: 'u1',
        nickname: 'Valerio',
        notificationsEnabled: true,
      ),
    );
    when(
      () => repo.send(
        id: any(named: 'id'),
        text: any<String?>(named: 'text'),
        imagePath: any<String?>(named: 'imagePath'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => repo.uploadImage(
        messageId: any(named: 'messageId'),
        bytes: any(named: 'bytes'),
      ),
    ).thenAnswer((i) async => 'g/${i.namedArguments[#messageId]}.jpg');
    when(() => repo.delete(any())).thenAnswer((_) async {});
    when(
      () => repo.toggleReaction(
        messageId: any(named: 'messageId'),
        emoji: any(named: 'emoji'),
        mine: any(named: 'mine'),
      ),
    ).thenAnswer((_) async {});
    container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(repo),
        profileRepositoryProvider.overrideWithValue(profiles),
      ],
    );
    addTearDown(container.dispose);
  });

  ChatComposer composer() => container.read(chatComposerProvider.notifier);

  group('sending a message', () {
    test('sends the trimmed text with a fresh id', () async {
      expect(await composer().sendText('  ciao a tutti  '), isTrue);
      final captured = verify(
        () => repo.send(
          id: captureAny(named: 'id'),
          text: 'ciao a tutti',
          imagePath: null,
        ),
      ).captured;
      expect((captured.single as String).length, 36); // uuid v4
    });

    test('empty or blank text sends nothing', () async {
      expect(await composer().sendText(''), isFalse);
      expect(await composer().sendText('   \n '), isFalse);
      verifyNever(
        () => repo.send(
          id: any(named: 'id'),
          text: any<String?>(named: 'text'),
          imagePath: any<String?>(named: 'imagePath'),
        ),
      );
    });

    test('a failure is reported, not thrown', () async {
      when(
        () => repo.send(
          id: any(named: 'id'),
          text: any<String?>(named: 'text'),
          imagePath: any<String?>(named: 'imagePath'),
        ),
      ).thenThrow(Exception('rete'));
      expect(await composer().sendText('ciao'), isFalse);
    });

    test('an image is uploaded first, then sent with the same id', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      expect(await composer().sendImage(bytes, caption: ' guarda '), isTrue);
      final upload = verify(
        () => repo.uploadImage(
          messageId: captureAny(named: 'messageId'),
          bytes: bytes,
        ),
      );
      final send = verify(
        () => repo.send(
          id: captureAny(named: 'id'),
          text: 'guarda',
          imagePath: captureAny(named: 'imagePath'),
        ),
      );
      final id = upload.captured.single as String;
      expect(send.captured, [id, 'g/$id.jpg']);
    });

    test('the upload happens before the message is created', () async {
      final calls = <String>[];
      when(
        () => repo.uploadImage(
          messageId: any(named: 'messageId'),
          bytes: any(named: 'bytes'),
        ),
      ).thenAnswer((i) async {
        calls.add('upload');
        return 'g/x.jpg';
      });
      when(
        () => repo.send(
          id: any(named: 'id'),
          text: any<String?>(named: 'text'),
          imagePath: any<String?>(named: 'imagePath'),
        ),
      ).thenAnswer((_) async => calls.add('send'));
      await composer().sendImage(Uint8List(1));
      expect(calls, ['upload', 'send']);
    });

    test('an image without caption has no text', () async {
      await composer().sendImage(Uint8List(1), caption: '  ');
      verify(
        () => repo.send(
          id: any(named: 'id'),
          text: null,
          imagePath: any<String?>(named: 'imagePath'),
        ),
      ).called(1);
    });

    test('if the upload fails no message is created', () async {
      when(
        () => repo.uploadImage(
          messageId: any(named: 'messageId'),
          bytes: any(named: 'bytes'),
        ),
      ).thenThrow(Exception('rete'));
      expect(await composer().sendImage(Uint8List(1)), isFalse);
      verifyNever(
        () => repo.send(
          id: any(named: 'id'),
          text: any<String?>(named: 'text'),
          imagePath: any<String?>(named: 'imagePath'),
        ),
      );
    });
  });

  group('reactions', () {
    test('adds mine when I have not reacted with that emoji', () async {
      await composer().toggleReaction(
        _msg(reactions: const [Reaction(emoji: '👍', count: 1, mine: false)]),
        '👍',
      );
      verify(
        () => repo.toggleReaction(messageId: 'm1', emoji: '👍', mine: false),
      ).called(1);
    });

    test('removes mine when I already reacted', () async {
      await composer().toggleReaction(
        _msg(reactions: const [Reaction(emoji: '👍', count: 2, mine: true)]),
        '👍',
      );
      verify(
        () => repo.toggleReaction(messageId: 'm1', emoji: '👍', mine: true),
      ).called(1);
    });

    test('a new emoji on a message without reactions is an add', () async {
      await composer().toggleReaction(_msg(), '😂');
      verify(
        () => repo.toggleReaction(messageId: 'm1', emoji: '😂', mine: false),
      ).called(1);
    });

    test('mine on one emoji does not affect another', () async {
      await composer().toggleReaction(
        _msg(reactions: const [Reaction(emoji: '👍', count: 1, mine: true)]),
        '❤️',
      );
      verify(
        () => repo.toggleReaction(messageId: 'm1', emoji: '❤️', mine: false),
      ).called(1);
    });
  });

  group('deleting', () {
    test('deletes my own message', () async {
      final m = _msg(mine: true);
      expect(await composer().delete(m), isTrue);
      verify(() => repo.delete(m)).called(1);
    });

    test("never deletes someone else's message", () async {
      expect(await composer().delete(_msg(mine: false)), isFalse);
      verifyNever(() => repo.delete(any()));
    });

    test('a failed delete is reported', () async {
      when(() => repo.delete(any())).thenThrow(StateError('no'));
      expect(await composer().delete(_msg()), isFalse);
    });
  });

  group('liveMessages', () {
    test('loads, then reloads on every realtime change', () async {
      final changes = StreamController<void>();
      addTearDown(changes.close);
      var version = 0;
      when(() => repo.changes()).thenAnswer((_) => changes.stream);
      when(
        () => repo.todaysMessages(selfId: 'u1'),
      ).thenAnswer((_) async => [_msg(id: 'v${version++}')]);
      await container.read(currentProfileProvider.future);

      final seen = <String>[];
      container.listen(liveMessagesProvider, (_, next) {
        next.whenData((l) => seen.add(l.single.id));
      }, fireImmediately: true);
      await pumpEventQueue();
      changes.add(null);
      await pumpEventQueue();
      expect(seen, ['v0', 'v1']);
    });
  });
}
