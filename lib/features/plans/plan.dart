import 'package:latlong2/latlong.dart';

import 'activity.dart';

/// Risposta a un piano.
enum VoteChoice {
  yes,
  no;

  static VoteChoice parse(String value) =>
      value == 'yes' ? VoteChoice.yes : VoteChoice.no;
}

class PlanVote {
  const PlanVote({
    required this.profileId,
    required this.nickname,
    required this.choice,
  });

  final String profileId;
  final String nickname;
  final VoteChoice choice;
}

class PlanPlace {
  const PlanPlace({
    required this.name,
    required this.lat,
    required this.lng,
    this.address,
  });

  final String name;
  final String? address;
  final double lat;
  final double lng;

  LatLng get point => LatLng(lat, lng);
}

/// Un piano di oggi con i suoi voti.
class Plan {
  const Plan({
    required this.id,
    required this.activityId,
    required this.emoji,
    required this.label,
    required this.creatorId,
    required this.creatorNickname,
    required this.createdAt,
    required this.place,
    required this.votes,
  });

  /// Da una riga `plans` con `profiles!plans_creator_id_fkey(nickname)`,
  /// `places(...)` e `votes(profile_id, vote, profiles(nickname))` incorporati.
  factory Plan.fromRow(Map<String, dynamic> row) {
    final place = row['places'] as Map<String, dynamic>?;
    return Plan(
      id: row['id'] as String,
      activityId: row['activity_id'] as String,
      emoji: row['emoji'] as String,
      label: row['label'] as String,
      creatorId: row['creator_id'] as String,
      creatorNickname:
          (row['profiles'] as Map<String, dynamic>)['nickname'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      place: place == null
          ? null
          : PlanPlace(
              name: place['name'] as String,
              address: place['address'] as String?,
              lat: (place['lat'] as num).toDouble(),
              lng: (place['lng'] as num).toDouble(),
            ),
      votes: [
        for (final v in (row['votes'] as List? ?? const []))
          PlanVote(
            profileId: v['profile_id'] as String,
            nickname:
                (v['profiles'] as Map<String, dynamic>)['nickname'] as String,
            choice: VoteChoice.parse(v['vote'] as String),
          ),
      ],
    );
  }

  final String id;
  final String activityId;
  final String emoji;
  final String label;
  final String creatorId;
  final String creatorNickname;
  final DateTime createdAt;
  final PlanPlace? place;
  final List<PlanVote> votes;

  Activity get activity => activityById(activityId);

  List<PlanVote> voters(VoteChoice choice) => [
    for (final v in votes)
      if (v.choice == choice) v,
  ];

  int count(VoteChoice choice) => voters(choice).length;

  /// Il voto di [profileId], se ce l'ha.
  VoteChoice? voteOf(String profileId) {
    for (final v in votes) {
      if (v.profileId == profileId) return v.choice;
    }
    return null;
  }
}

/// Più "Ci sono" prima; a parità, il più recente.
List<Plan> sortPlans(Iterable<Plan> plans) => [...plans]
  ..sort((a, b) {
    final byYes = b.count(VoteChoice.yes).compareTo(a.count(VoteChoice.yes));
    return byYes != 0 ? byYes : b.createdAt.compareTo(a.createdAt);
  });

/// "18:32" (ora locale del telefono).
String formatTime(DateTime when) {
  final t = when.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.hour)}:${two(t.minute)}';
}
