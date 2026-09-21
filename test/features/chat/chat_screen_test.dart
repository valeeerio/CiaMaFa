import 'dart:async';
import 'dart:typed_data';

import 'package:ciamafa/core/theme.dart';
import 'package:ciamafa/features/chat/chat_message.dart';
import 'package:ciamafa/features/chat/chat_provider.dart';
import 'package:ciamafa/features/chat/chat_repository.dart';
import 'package:ciamafa/features/chat/chat_screen.dart';
import 'package:ciamafa/features/chat/image_picker_service.dart';
import 'package:ciamafa/features/onboarding/onboarding_provider.dart';
import 'package:ciamafa/features/onboarding/profile_repository.dart';
import 'package:ciamafa/shared/staggered_entrance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockChat extends Mock implements ChatRepository {}

class MockProfiles extends Mock implements ProfileRepository {}

class MockPicker extends Mock implements ImagePickerService {}

ChatMessage _msg(
  String id, {
  bool mine = false,
  String? text = 'ciao',
  String? imagePath,
  List<Reaction> reactions = const [],
}) => ChatMessage(
  id: id,
  senderId: mine ? 'u1' : 'u2',
  senderNickname: mine ? 'Valerio' : 'Marta',
  text: text,
  imagePath: imagePath,
  createdAt: DateTime.utc(2026, 9, 21, 10),
  isMine: mine,
  reactions: reactions,
);

Color? _textColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  late MockChat repo;
  late MockProfiles profiles;
  late MockPicker picker;
  late StreamController<void> changes;
  var messages = <ChatMessage>[];

  setUpAll(() {
    registerFallbackValue(_msg('x'));
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(PickSource.gallery);
  });

  setUp(() {
    repo = MockChat();
    profiles = MockProfiles();
    picker = MockPicker();
    changes = StreamController<void>.broadcast();
    addTearDown(changes.close);
    messages = [];
    when(() => profiles.fetchCurrentProfile()).thenAnswer(
      (_) async => const Profile(
        id: 'u1',
        nickname: 'Valerio',
        notificationsEnabled: true,
      ),
    );
    when(() => repo.todaysMessages(selfId: any(named: 'selfId')))
        .thenAnswer((_) async => messages);
    when(() => repo.changes()).thenAnswer((_) => changes.stream);
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
    when(() => repo.signedImageUrl(any()))
        .thenAnswer((_) async => 'https://example.test/x.jpg');
  });

  Future<void> pump(WidgetTester tester, {bool reduced = false}) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatRepositoryProvider.overrideWithValue(repo),
          profileRepositoryProvider.overrideWithValue(profiles),
          imagePickerServiceProvider.overrideWithValue(picker),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: child!,
          ),
          home: const ChatScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('layout', () {
    testWidgets('header, subtitle and input bar', (tester) async {
      await pump(tester);
      expect(find.text('Chat'), findsOneWidget);
      expect(
        find.text('Messaggi di oggi · spariscono a mezzanotte 🕛'),
        findsOneWidget,
      );
      expect(find.text('📷'), findsOneWidget); // solo il pulsante allega
      expect(find.byKey(const ValueKey('message-field')), findsOneWidget);
      expect(find.text('Scrivi al gruppo…'), findsOneWidget);
      expect(find.byKey(const ValueKey('send')), findsOneWidget);
      // Tab: nessuna freccia indietro.
      expect(find.bySemanticsLabel('Indietro'), findsNothing);
    });

    testWidgets('empty state', (tester) async {
      await pump(tester);
      expect(find.text('Ancora nessun messaggio oggi.'), findsOneWidget);
    });
  });

  group('bubbles', () {
    testWidgets(
      'mine on the right in cream on night blue, theirs on the left',
      (tester) async {
        messages = [
          _msg('a', text: 'della Marta'),
          _msg('b', mine: true, text: 'mio'),
        ];
        await pump(tester);

        final mine = tester.getTopRight(find.byKey(const ValueKey('bubble:b')));
        final theirs = tester.getTopLeft(
          find.byKey(const ValueKey('bubble:a')),
        );
        expect(mine.dx, greaterThan(700));
        expect(theirs.dx, lessThan(100));
        expect(_textColor(tester, 'mio'), AppColors.cream);
        expect(_textColor(tester, 'della Marta'), AppColors.nightBlue);
      },
    );

    testWidgets("only other people's bubbles show the sender in coral", (
      tester,
    ) async {
      messages = [_msg('a'), _msg('b', mine: true)];
      await pump(tester);
      expect(find.text('Marta'), findsOneWidget);
      expect(_textColor(tester, 'Marta'), AppColors.coralText);
      expect(find.text('Valerio'), findsNothing);
    });

    testWidgets('newest message sits at the bottom', (tester) async {
      messages = [_msg('a', text: 'primo'), _msg('b', text: 'ultimo')];
      await pump(tester);
      expect(
        tester.getTopLeft(find.text('ultimo')).dy,
        greaterThan(tester.getTopLeft(find.text('primo')).dy),
      );
    });
  });

  group('image bubble', () {
    testWidgets('shows the 📷 block while the link loads, then the photo', (
      tester,
    ) async {
      final url = Completer<String>();
      when(() => repo.signedImageUrl(any())).thenAnswer((_) => url.future);
      messages = [_msg('a', text: 'guarda', imagePath: 'g/a.jpg')];
      await pump(tester);

      expect(find.byKey(const ValueKey('image-placeholder')), findsOneWidget);
      expect(find.byKey(const ValueKey('chat-image')), findsNothing);
      expect(find.text('guarda'), findsOneWidget); // didascalia sotto

      url.complete('https://example.test/a.jpg');
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('chat-image')), findsOneWidget);
    });

    testWidgets('falls back to the placeholder if the link fails', (
      tester,
    ) async {
      when(() => repo.signedImageUrl(any())).thenThrow(Exception('rete'));
      messages = [_msg('a', text: null, imagePath: 'g/a.jpg')];
      await pump(tester);
      expect(find.byKey(const ValueKey('image-placeholder')), findsOneWidget);
      expect(find.byKey(const ValueKey('chat-image')), findsNothing);
    });

    testWidgets('an image without caption has no text under it', (
      tester,
    ) async {
      messages = [_msg('a', text: null, imagePath: 'g/a.jpg')];
      await pump(tester);
      expect(find.byKey(const ValueKey('bubble:a')), findsOneWidget);
      expect(find.text('ciao'), findsNothing);
    });
  });

  group('delete', () {
    testWidgets('🗑️ only on my messages', (tester) async {
      messages = [_msg('a'), _msg('b', mine: true)];
      await pump(tester);
      expect(find.byKey(const ValueKey('delete:b')), findsOneWidget);
      expect(find.byKey(const ValueKey('delete:a')), findsNothing);
      expect(find.text('🗑️'), findsOneWidget);
    });

    testWidgets('one tap deletes, no confirmation', (tester) async {
      messages = [_msg('b', mine: true)];
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('delete:b')));
      await tester.pumpAndSettle();
      verify(() => repo.delete(any(that: isA<ChatMessage>()))).called(1);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('a failed delete says so', (tester) async {
      when(() => repo.delete(any())).thenThrow(StateError('no'));
      messages = [_msg('b', mine: true)];
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('delete:b')));
      await tester.pumpAndSettle();
      expect(find.text('Non sono riuscito a eliminare 😬'), findsOneWidget);
    });
  });

  group('reactions', () {
    testWidgets('chips show emoji and count, mine is acid green', (
      tester,
    ) async {
      messages = [
        _msg(
          'a',
          reactions: const [
            Reaction(emoji: '👍', count: 2, mine: true),
            Reaction(emoji: '😂', count: 1, mine: false),
          ],
        ),
      ];
      await pump(tester);
      expect(find.text('👍 2'), findsOneWidget);
      expect(find.text('😂 1'), findsOneWidget);

      Color? fill(String emoji) =>
          (tester
                      .widget<AnimatedContainer>(
                        find.descendant(
                          of: find.byKey(ValueKey('reaction:a:$emoji')),
                          matching: find.byType(AnimatedContainer),
                        ),
                      )
                      .decoration!
                  as BoxDecoration)
              .color;
      expect(fill('👍'), AppColors.acidGreen);
      expect(fill('😂'), AppColors.white);
    });

    testWidgets('tapping a chip toggles my reaction', (tester) async {
      messages = [
        _msg(
          'a',
          reactions: const [
            Reaction(emoji: '👍', count: 2, mine: true),
            Reaction(emoji: '😂', count: 1, mine: false),
          ],
        ),
      ];
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('reaction:a:😂')));
      await tester.pumpAndSettle();
      verify(
        () => repo.toggleReaction(messageId: 'a', emoji: '😂', mine: false),
      ).called(1);
      await tester.tap(find.byKey(const ValueKey('reaction:a:👍')));
      await tester.pumpAndSettle();
      verify(() => repo.toggleReaction(messageId: 'a', emoji: '👍', mine: true))
          .called(1);
    });

    testWidgets('🙂+ opens the six quick emoji and picking one reacts', (
      tester,
    ) async {
      messages = [_msg('a')];
      await pump(tester);
      for (final e in quickReactions) {
        expect(find.byKey(ValueKey('pick:$e')), findsNothing);
      }
      await tester.tap(find.byKey(const ValueKey('add-reaction:a')));
      await tester.pumpAndSettle();
      for (final e in quickReactions) {
        expect(find.byKey(ValueKey('pick:$e')), findsOneWidget);
      }
      await tester.tap(find.byKey(const ValueKey('pick:🙏')));
      await tester.pumpAndSettle();
      verify(
        () => repo.toggleReaction(messageId: 'a', emoji: '🙏', mine: false),
      ).called(1);
      expect(find.byKey(const ValueKey('pick:🙏')), findsNothing); // si chiude
    });

    testWidgets('reactions work on my own messages too', (tester) async {
      messages = [_msg('b', mine: true)];
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('add-reaction:b')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pick:❤️')));
      await tester.pumpAndSettle();
      verify(
        () => repo.toggleReaction(messageId: 'b', emoji: '❤️', mine: false),
      ).called(1);
    });
  });

  group('sending', () {
    testWidgets('send is disabled while the field is empty', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('send')));
      await tester.pumpAndSettle();
      verifyNever(
        () => repo.send(
          id: any(named: 'id'),
          text: any<String?>(named: 'text'),
          imagePath: any<String?>(named: 'imagePath'),
        ),
      );
    });

    testWidgets('sends the text and clears the field', (tester) async {
      await pump(tester);
      await tester.enterText(
        find.byKey(const ValueKey('message-field')),
        'ciao a tutti',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('send')));
      await tester.pumpAndSettle();
      verify(
        () => repo.send(
          id: any(named: 'id'),
          text: 'ciao a tutti',
          imagePath: null,
        ),
      ).called(1);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('message-field')))
            .controller!
            .text,
        isEmpty,
      );
    });

    testWidgets('a failure restores the text and says so', (tester) async {
      when(
        () => repo.send(
          id: any(named: 'id'),
          text: any<String?>(named: 'text'),
          imagePath: any<String?>(named: 'imagePath'),
        ),
      ).thenThrow(Exception('rete'));
      await pump(tester);
      await tester.enterText(
        find.byKey(const ValueKey('message-field')),
        'ciao',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('send')));
      await tester.pumpAndSettle();
      expect(find.text('Non sono riuscito a inviare 😬'), findsOneWidget);
      expect(find.text('ciao'), findsOneWidget); // di nuovo nel campo
    });

    testWidgets('📷 → Galleria → preview → send uploads then sends', (
      tester,
    ) async {
      when(() => picker.pick(any())).thenAnswer((_) async => Uint8List(4));
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('attach')));
      await tester.pumpAndSettle();
      expect(find.text('📸  Scatta'), findsOneWidget);
      await tester.tap(find.text('🖼️  Galleria'));
      await tester.pumpAndSettle();
      verify(() => picker.pick(PickSource.gallery)).called(1);
      expect(find.byKey(const ValueKey('pending-image')), findsOneWidget);
      expect(find.text('Aggiungi una didascalia…'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('message-field')),
        'guarda',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('send')));
      await tester.pumpAndSettle();
      verifyInOrder([
        () => repo.uploadImage(
          messageId: any(named: 'messageId'),
          bytes: any(named: 'bytes'),
        ),
        () => repo.send(
          id: any(named: 'id'),
          text: 'guarda',
          imagePath: any<String?>(named: 'imagePath', that: isNotNull),
        ),
      ]);
      expect(find.byKey(const ValueKey('pending-image')), findsNothing);
    });

    testWidgets('a photo can be sent without caption and can be removed', (
      tester,
    ) async {
      when(() => picker.pick(any())).thenAnswer((_) async => Uint8List(4));
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('attach')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('📸  Scatta'));
      await tester.pumpAndSettle();
      verify(() => picker.pick(PickSource.camera)).called(1);
      await tester.tap(find.byKey(const ValueKey('remove-pending')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pending-image')), findsNothing);
    });

    testWidgets('cancelling the picker leaves nothing pending', (tester) async {
      when(() => picker.pick(any())).thenAnswer((_) async => null);
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('attach')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('🖼️  Galleria'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pending-image')), findsNothing);
    });
  });

  group('live updates and motion', () {
    testWidgets('history appears without entrance, new messages animate', (
      tester,
    ) async {
      messages = [_msg('a', text: 'vecchio')];
      await pump(tester);
      expect(find.byType(StaggeredEntrance), findsNothing);

      messages = [...messages, _msg('b', text: 'nuovo')];
      changes.add(null);
      await tester.pump();
      await tester.pump();
      expect(find.text('nuovo'), findsOneWidget);
      expect(find.byType(StaggeredEntrance), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('reduced motion: a new message is there at once', (
      tester,
    ) async {
      messages = [_msg('a')];
      await pump(tester, reduced: true);
      messages = [...messages, _msg('b', text: 'nuovo')];
      changes.add(null);
      await tester.pump();
      await tester.pump();
      final opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(StaggeredEntrance),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 1);
    });

    testWidgets('a reaction arriving live updates the chip', (tester) async {
      messages = [_msg('a')];
      await pump(tester);
      expect(find.text('👍 1'), findsNothing);
      messages = [
        _msg(
          'a',
          reactions: const [Reaction(emoji: '👍', count: 1, mine: false)],
        ),
      ];
      changes.add(null);
      await tester.pumpAndSettle();
      expect(find.text('👍 1'), findsOneWidget);
    });
  });
}
