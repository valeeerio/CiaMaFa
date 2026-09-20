import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

/// Guardia sui dati dei preset: coordinate plausibili, id unici, stats coerenti.
/// Il limite è 20 km da Bitetto: "Frida a'mare" è sul lungomare di Bari (~14 km).
void main() {
  final dir = Directory('supabase/migrations');
  final seeds = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.contains('_seed_places_'))
      .toList();

  test('there is at least the "bar" seed', () {
    expect(seeds.any((f) => f.path.endsWith('_seed_places_bar.sql')), isTrue);
  });

  for (final file in seeds) {
    final name = file.uri.pathSegments.last;
    final sql = file.readAsStringSync();

    // ('osm', 'way/1', 'Nome', 'Indirizzo', 41.0, 16.7)
    final rows = RegExp(
      r"\('(\w+)',\s*'([^']+)',\s*'((?:[^']|'')+)',\s*'((?:[^']|'')+)',\s*(-?[\d.]+),\s*(-?[\d.]+)\)",
    ).allMatches(sql).toList();

    group(name, () {
      test('has places', () => expect(rows, isNotEmpty));

      test('external ids are unique', () {
        final ids = [for (final r in rows) '${r[1]}:${r[2]}'];
        expect(ids.toSet().length, ids.length);
      });

      test('coordinates are within 20 km of Bitetto (surroundings)', () {
        for (final r in rows) {
          final lat = double.parse(r[5]!), lng = double.parse(r[6]!);
          final km = math.sqrt(
            math.pow((lat - 41.0414) * 111.2, 2) +
                math.pow((lng - 16.7487) * 84.0, 2),
          );
          expect(km, lessThan(20), reason: r[3]);
        }
      });

      test('every place gets a stats row for the same activity', () {
        final stats = RegExp(r"select p\.id, '(\w+)'").firstMatch(sql);
        expect(
          stats,
          isNotNull,
          reason: 'manca l\'insert in place_activity_stats',
        );
        for (final r in rows) {
          expect(sql.contains("in ("), isTrue);
          expect(
            RegExp("'${RegExp.escape(r[2]!)}'").allMatches(sql).length,
            2,
            reason: '${r[3]}: deve comparire nei places e nelle stats',
          );
        }
      });

      test('seeds written after the scoring migration set curated = true', () {
        final version = int.parse(name.split('_').first);
        if (version >= 20260920000005) {
          expect(
            sql.contains('curated'),
            isTrue,
            reason:
                'senza curated = true il preset comparirebbe solo dopo 2 lanci',
          );
        }
      });

      test('is idempotent (on conflict clauses)', () {
        expect('on conflict'.allMatches(sql).length, greaterThanOrEqualTo(2));
      });
    });
  }
}
