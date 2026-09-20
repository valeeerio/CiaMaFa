import 'package:ciamafa/features/plans/plan.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> row({
  String id = 'p1',
  String createdAt = '2026-09-20T16:32:00+00:00',
  List<Map<String, dynamic>> votes = const [],
  Object? place = const {
    'name': 'Pineta',
    'address': 'Via X',
    'lat': 41.03797,
    'lng': 16.73744,
  },
}) => {
  'id': id,
  'activity_id': 'bar',
  'emoji': '🍻',
  'label': 'Bar',
  'creator_id': 'u1',
  'created_at': createdAt,
  'profiles': {'nickname': 'Marco'},
  'places': place,
  'votes': votes,
};

Map<String, dynamic> vote(String id, String nick, String v) => {
  'profile_id': id,
  'vote': v,
  'profiles': {'nickname': nick},
};

void main() {
  group('Plan.fromRow', () {
    test('reads plan, creator, place and votes', () {
      final p = Plan.fromRow(
        row(votes: [vote('u1', 'Marco', 'yes'), vote('u2', 'Anna', 'no')]),
      );
      expect((p.id, p.label, p.creatorNickname), ('p1', 'Bar', 'Marco'));
      expect(p.place?.name, 'Pineta');
      expect(p.place?.point.latitude, 41.03797);
      expect(p.activity.id, 'bar');
      expect(p.count(VoteChoice.yes), 1);
      expect(p.count(VoteChoice.no), 1);
      expect(p.voters(VoteChoice.no).single.nickname, 'Anna');
    });

    test('voteOf finds your vote, or null', () {
      final p = Plan.fromRow(row(votes: [vote('u2', 'Anna', 'no')]));
      expect(p.voteOf('u2'), VoteChoice.no);
      expect(p.voteOf('u3'), isNull);
    });

    test('no place, no votes', () {
      final p = Plan.fromRow(row(place: null));
      expect(p.place, isNull);
      expect(p.votes, isEmpty);
    });
  });

  group('sortPlans', () {
    Plan plan(String id, String at, int yes) => Plan.fromRow(
      row(
        id: id,
        createdAt: at,
        votes: [for (var i = 0; i < yes; i++) vote('v$i', 'N$i', 'yes')],
      ),
    );

    test('more "Ci sono" first, then the most recent', () {
      final sorted = sortPlans([
        plan('old-2', '2026-09-20T10:00:00+00:00', 2),
        plan('new-1', '2026-09-20T18:00:00+00:00', 1),
        plan('new-2', '2026-09-20T17:00:00+00:00', 2),
        plan('old-1', '2026-09-20T09:00:00+00:00', 1),
      ]);
      expect(
        [for (final p in sorted) p.id],
        ['new-2', 'old-2', 'new-1', 'old-1'],
      );
    });

    test('"Non ci sono" do not count for the order', () {
      final a = Plan.fromRow(
        row(id: 'a', votes: [vote('x', 'X', 'no'), vote('y', 'Y', 'no')]),
      );
      final b = Plan.fromRow(
        row(
          id: 'b',
          createdAt: '2026-09-20T10:00:00+00:00',
          votes: [vote('z', 'Z', 'yes')],
        ),
      );
      expect(
        [
          for (final p in sortPlans([a, b])) p.id,
        ],
        ['b', 'a'],
      );
    });
  });

  test('formatTime pads and uses the local time', () {
    expect(formatTime(DateTime(2026, 9, 20, 7, 5)), '07:05');
    expect(formatTime(DateTime(2026, 9, 20, 18, 32)), '18:32');
  });
}
