import 'dart:async';
import 'dart:math' as math;

import 'package:ciamafa/core/theme.dart';
import 'package:ciamafa/features/places/location_service.dart';
import 'package:ciamafa/features/places/place_candidate.dart';
import 'package:ciamafa/features/places/place_search_repository.dart';
import 'package:ciamafa/features/places/place_suggestions_repository.dart';
import 'package:ciamafa/features/places/places_provider.dart';
import 'package:ciamafa/features/places/places_screen.dart';
import 'package:ciamafa/features/plans/activity.dart';
import 'package:ciamafa/shared/dashed_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';

class MockSearch extends Mock implements PlaceSearchRepository {}

class MockSuggestions extends Mock implements PlaceSuggestionsRepository {}

class MockLocation extends Mock implements LocationService {}

const _timeout = LocationFailure(LocationFailureReason.timeout);

const _piazza = PlaceCandidate(
  name: 'Piazza Aldo Moro',
  address: 'Bitetto',
  lat: 41.0389,
  lng: 16.7264,
);
const _bar = PlaceCandidate(
  name: 'Bar Centrale',
  address: 'Via Roma 12',
  lat: 41.04,
  lng: 16.73,
);

// I 5 bar reali (coordinate del seed).
const _arco = PlaceCandidate(
  name: 'Arco del Tempo',
  lat: 41.03954,
  lng: 16.74883,
);
const _pineta = PlaceCandidate(
  name: 'Pineta Comunale',
  lat: 41.03797,
  lng: 16.73744,
);
const _gatti = PlaceCandidate(name: 'GATTI Area', lat: 41.02676, lng: 16.76480);
const _momento = PlaceCandidate(
  name: 'Momento Bar',
  lat: 40.99224,
  lng: 16.80070,
);
const _frida = PlaceCandidate(
  name: "Frida a'mare",
  lat: 41.16871,
  lng: 16.74029,
);

void main() {
  late MockSearch search;
  late MockSuggestions suggestions;
  late MockLocation location;

  setUpAll(() => registerFallbackValue(LocationFailureReason.timeout));

  void presetsAre(List<PlaceCandidate> list) =>
      when(() => suggestions.presetsFor(any())).thenAnswer((_) async => list);

  setUp(() {
    search = MockSearch();
    suggestions = MockSuggestions();
    location = MockLocation();
    presetsAre([_piazza]);
    when(() => location.locate()).thenAnswer((_) async => _timeout);
    when(() => location.openSettings(any())).thenAnswer((_) async {});
  });

  Future<void> pump(
    WidgetTester tester,
    String activityId, {
    bool reduced = false,
    Size size = const Size(800, 2400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          placeSearchRepositoryProvider.overrideWithValue(search),
          placeSuggestionsRepositoryProvider.overrideWithValue(suggestions),
          locationServiceProvider.overrideWithValue(location),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: child!,
          ),
          home: PlacesScreen(activityId: activityId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  FilledButton cta(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton));

  MapCamera cameraOf(WidgetTester tester) =>
      tester.widget<FlutterMap>(find.byType(FlutterMap)).mapController!.camera;

  final locateChip = find.byKey(const ValueKey('chip:📍 La tua posizione'));

  group('testata e elementi rimossi', () {
    testWidgets('a centred "Dove?" and nothing else in the header', (
      tester,
    ) async {
      await pump(tester, 'bar', size: const Size(390, 844));
      expect(find.text('Dove?'), findsOneWidget);
      // Tolti: pillola con l'attività, scritta piccola, titolo lungo.
      expect(find.text('🍻 Bar'), findsNothing);
      expect(find.text('🍻 Bar · adesso'), findsNothing);
      expect(find.text('Dove andiamo al bar?'), findsNothing);
      // Simmetrica: il titolo è al centro dello schermo.
      expect(tester.getCenter(find.text('Dove?')).dx, closeTo(390 / 2, 0.5));
    });

    testWidgets('the title is the same "Dove?" for every activity', (
      tester,
    ) async {
      for (final a in activities) {
        await pump(tester, a.id, size: const Size(390, 844));
        expect(find.text('Dove?'), findsOneWidget, reason: a.id);
      }
    });

    testWidgets('no 🎯, no attribution/logo, no hint card', (tester) async {
      await pump(tester, 'bar', size: const Size(390, 844));
      expect(find.text('🎯'), findsNothing);
      expect(find.byType(RichAttributionWidget), findsNothing);
      expect(find.byType(SimpleAttributionWidget), findsNothing);
      expect(find.byIcon(Icons.info_outline), findsNothing);
      expect(find.textContaining('OpenStreetMap'), findsNothing);
      expect(find.textContaining('Tocca un punto sulla mappa'), findsNothing);
    });

    testWidgets('the freed space goes to the map', (tester) async {
      await pump(tester, 'bar', size: const Size(390, 844));
      final map = tester.getSize(find.byType(FlutterMap));
      // Su 844 pt ora la mappa supera la metà dello schermo.
      expect(map.height, greaterThan(844 / 2));
    });

    testWidgets('short screens never overflow', (tester) async {
      await pump(tester, 'bar', size: const Size(390, 640));
      expect(tester.takeException(), isNull);
      await pump(tester, 'bar', size: const Size(390, 900));
      expect(tester.takeException(), isNull);
    });
  });

  group('CTA', () {
    testWidgets('per-activity text, disabled without a place', (tester) async {
      await pump(tester, 'bar');
      expect(find.text('Lancia Bar qui'), findsOneWidget);
      expect(find.text('🚀'), findsOneWidget);
      expect(cta(tester).onPressed, isNull);
    });

    testWidgets('Bho uses its own text', (tester) async {
      await pump(tester, 'bho');
      expect(find.text('Lanciamo e decidiamo lì'), findsOneWidget);
      expect(find.text('🚀'), findsOneWidget);
    });

    testWidgets('is the orange Home-style block, muted when disabled', (
      tester,
    ) async {
      await pump(tester, 'bar');
      Color bg() => cta(tester).style!.backgroundColor!.resolve(
        cta(tester).onPressed == null ? {WidgetState.disabled} : {},
      )!;

      expect(bg(), AppColors.muted);
      await tester.tap(find.byKey(const ValueKey('chip:Piazza Aldo Moro')));
      await tester.pumpAndSettle();
      expect(bg(), AppColors.orange);
    });

    testWidgets('the rocket wiggles once when the CTA becomes active', (
      tester,
    ) async {
      double emojiAngle() {
        final t = tester.widget<Transform>(
          find
              .ancestor(of: find.text('🚀'), matching: find.byType(Transform))
              .first,
        );
        return math.asin(t.transform.entry(1, 0));
      }

      await pump(tester, 'bar');
      expect(emojiAngle(), 0);
      await tester.tap(find.byKey(const ValueKey('chip:Piazza Aldo Moro')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(emojiAngle().abs(), greaterThan(0.05));
      await tester.pumpAndSettle();
      expect(emojiAngle().abs(), lessThan(1e-6));
    });

    testWidgets('reduced motion: the rocket never wiggles', (tester) async {
      await pump(tester, 'bar', reduced: true);
      await tester.tap(find.byKey(const ValueKey('chip:Piazza Aldo Moro')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final t = tester.widget<Transform>(
        find
            .ancestor(of: find.text('🚀'), matching: find.byType(Transform))
            .first,
      );
      expect(math.asin(t.transform.entry(1, 0)), 0);
    });
  });

  group('scelta del luogo', () {
    testWidgets(
      'a preset chip selects it, shows its label on the pin, enables the CTA',
      (tester) async {
        await pump(tester, 'bar');
        await tester.tap(find.byKey(const ValueKey('chip:Piazza Aldo Moro')));
        await tester.pumpAndSettle();

        // Chip + etichetta sul pin: il nome ora sta solo lì (niente card).
        expect(find.text('Piazza Aldo Moro'), findsAtLeastNWidgets(2));
        expect(cta(tester).onPressed, isNotNull);
      },
    );

    testWidgets('search shows results; picking one selects it', (tester) async {
      when(() => search.search('bar', near: any(named: 'near')))
          .thenAnswer((_) async => [_bar]);
      await pump(tester, 'bar');

      await tester.enterText(find.byType(TextField), 'bar');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'Bar Centrale'), findsOneWidget);

      await tester.tap(find.widgetWithText(ListTile, 'Bar Centrale'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, 'Bar Centrale'), findsNothing);
      expect(find.text('Bar Centrale'), findsOneWidget); // etichetta del pin
      expect(cta(tester).onPressed, isNotNull);
    });

    testWidgets('choosing a place flies to it and zooms in (min zoom 16)', (
      tester,
    ) async {
      presetsAre([_arco, _pineta, _gatti, _momento, _frida]);
      await pump(tester, 'bar', size: const Size(390, 844));
      expect(cameraOf(tester).zoom, lessThan(12)); // vista d'insieme

      final arcoChip = find.byKey(const ValueKey('chip:Arco del Tempo'));
      await tester.ensureVisible(arcoChip); // la fila di chip è scorrevole
      await tester.pumpAndSettle();
      await tester.tap(arcoChip);
      await tester.pumpAndSettle();

      final cam = cameraOf(tester);
      expect(cam.zoom, greaterThanOrEqualTo(16));
      expect(cam.center.latitude, closeTo(_arco.lat, 1e-6));
      expect(cam.center.longitude, closeTo(_arco.lng, 1e-6));
    });
  });

  group('"La tua posizione" (chip, come prima)', () {
    testWidgets('with permission selects your position and enables the CTA', (
      tester,
    ) async {
      when(
        () => location.locate(),
      ).thenAnswer((_) async => const LocationFound(LatLng(41.0414, 16.7487)));
      await pump(tester, 'bar');

      await tester.tap(locateChip);
      await tester.pumpAndSettle();

      expect(find.text('La tua posizione'), findsWidgets); // etichetta del pin
      expect(cta(tester).onPressed, isNotNull);
    });
  });

  group('"La tua posizione": errori e attesa', () {
    Future<void> tapLocate(WidgetTester tester) async {
      await tester.tap(locateChip);
      await tester.pumpAndSettle();
    }

    for (final reason in LocationFailureReason.values) {
      testWidgets('${reason.name}: shows its own message, not a generic one', (
        tester,
      ) async {
        when(() => location.locate())
            .thenAnswer((_) async => LocationFailure(reason));
        await pump(tester, 'bar');
        await tapLocate(tester);

        expect(find.text(reason.message), findsOneWidget);
        expect(find.textContaining('controlla i permessi'), findsNothing);
        expect(cta(tester).onPressed, isNull); // nessun luogo scelto
      });
    }

    testWidgets('off / denied for good: the action opens the right settings', (
      tester,
    ) async {
      for (final reason in [
        LocationFailureReason.serviceDisabled,
        LocationFailureReason.deniedForever,
      ]) {
        when(() => location.locate())
            .thenAnswer((_) async => LocationFailure(reason));
        await pump(tester, 'bar');
        await tapLocate(tester);

        expect(find.text('Impostazioni'), findsOneWidget);
        expect(find.text('Riprova'), findsNothing);
        await tester.tap(find.text('Impostazioni'));
        await tester.pumpAndSettle();
        verify(() => location.openSettings(reason)).called(1);
      }
    });

    testWidgets(
      'timeout / unavailable / denied: the action is "Riprova" and locates again',
      (tester) async {
        var calls = 0;
        when(() => location.locate()).thenAnswer((_) async {
          calls++;
          return calls == 1
              ? _timeout
              : const LocationFound(LatLng(41.0414, 16.7487));
        });
        await pump(tester, 'bar');
        await tapLocate(tester);
        expect(find.text('Riprova'), findsOneWidget);
        expect(find.text('Impostazioni'), findsNothing);

        await tester.tap(find.text('Riprova'));
        await tester.pumpAndSettle();

        expect(calls, 2);
        expect(cta(tester).onPressed, isNotNull); // ora la posizione è scelta
      },
    );

    testWidgets('a new error replaces the previous message', (tester) async {
      when(() => location.locate()).thenAnswer((_) async => _timeout);
      await pump(tester, 'bar');
      await tapLocate(tester);
      when(() => location.locate()).thenAnswer(
        (_) async => const LocationFailure(LocationFailureReason.deniedForever),
      );
      await tapLocate(tester);

      expect(
        find.text(LocationFailureReason.deniedForever.message),
        findsOneWidget,
      );
      expect(find.text(LocationFailureReason.timeout.message), findsNothing);
    });

    testWidgets('shows a spinner on the chip while looking, then goes back', (
      tester,
    ) async {
      final pending = Completer<LocationResult>();
      when(() => location.locate()).thenAnswer((_) => pending.future);
      await pump(tester, 'bar');
      expect(
        find.descendant(
          of: locateChip,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsNothing,
      );

      await tester.tap(locateChip);
      await tester.pump();
      final spinner = find.descendant(
        of: locateChip,
        matching: find.byType(CircularProgressIndicator),
      );
      expect(spinner, findsOneWidget);
      expect(
        find.descendant(of: locateChip, matching: find.text('📍')),
        findsNothing,
      );
      expect(
        find.descendant(
          of: locateChip,
          matching: find.text('La tua posizione'),
        ),
        findsOneWidget,
      );

      pending.complete(const LocationFound(LatLng(41.0414, 16.7487)));
      await tester.pumpAndSettle();
      expect(spinner, findsNothing);
      expect(
        find.descendant(of: locateChip, matching: find.text('📍')),
        findsOneWidget,
      );
    });

    testWidgets('the spinner also goes away after a failure', (tester) async {
      final pending = Completer<LocationResult>();
      when(() => location.locate()).thenAnswer((_) => pending.future);
      await pump(tester, 'bar');
      await tester.tap(locateChip);
      await tester.pump();

      pending.complete(_timeout);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: locateChip,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsNothing,
      );
    });

    testWidgets(
      'taps while it is still looking are ignored (one lookup at a time)',
      (tester) async {
        final pending = Completer<LocationResult>();
        when(() => location.locate()).thenAnswer((_) => pending.future);
        await pump(tester, 'bar');

        await tester.tap(locateChip);
        await tester.pump();
        await tester.tap(locateChip);
        await tester.pump();
        await tester.tap(locateChip);
        await tester.pump();

        verify(() => location.locate()).called(1);
        pending.complete(_timeout);
        await tester.pumpAndSettle();
      },
    );

    testWidgets('leaving the screen while looking does not crash', (
      tester,
    ) async {
      final pending = Completer<LocationResult>();
      when(() => location.locate()).thenAnswer((_) => pending.future);
      await pump(tester, 'bar');
      await tester.tap(locateChip);
      await tester.pump();

      await tester.pumpWidget(const SizedBox()); // schermata chiusa
      pending.complete(const LocationFound(LatLng(41, 16)));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('inquadratura automatica', () {
    testWidgets('opening frames ALL the points, even the far ones', (
      tester,
    ) async {
      presetsAre([_arco, _pineta, _gatti, _momento, _frida]);
      await pump(tester, 'bar', size: const Size(390, 844));

      final cam = cameraOf(tester);
      for (final p in [_arco, _pineta, _gatti, _momento, _frida]) {
        expect(cam.visibleBounds.contains(p.point), isTrue, reason: p.name);
      }
    });

    testWidgets('a single preset is centred at zoom 16', (tester) async {
      await pump(tester, 'bar', size: const Size(390, 844));
      final cam = cameraOf(tester);
      expect(cam.zoom, closeTo(16, 1e-6));
      expect(cam.center.latitude, closeTo(_piazza.lat, 1e-6));
    });

    testWidgets('with no presets the map stays on Bitetto', (tester) async {
      presetsAre([]);
      await pump(tester, 'bar', size: const Size(390, 844));
      final cam = cameraOf(tester);
      expect(cam.center.latitude, closeTo(bitetto.latitude, 1e-6));
      expect(cam.zoom, closeTo(15, 1e-6));
    });

    testWidgets(
      'presets arriving after you chose a place do not move the camera',
      (tester) async {
        final presets = Completer<List<PlaceCandidate>>();
        when(() => suggestions.presetsFor(any()))
            .thenAnswer((_) => presets.future);
        const me = LatLng(41.0300, 16.7600);
        when(() => location.locate())
            .thenAnswer((_) async => const LocationFound(me));

        await pump(tester, 'bar', size: const Size(390, 844));
        await tester.tap(locateChip);
        await tester.pumpAndSettle();
        expect(cameraOf(tester).center.latitude, closeTo(me.latitude, 1e-6));

        presets.complete([_piazza]);
        await tester.pumpAndSettle();
        expect(cameraOf(tester).center.latitude, closeTo(me.latitude, 1e-6));
        expect(cameraOf(tester).center.longitude, closeTo(me.longitude, 1e-6));
      },
    );
  });

  group('tasti + e −', () {
    testWidgets('+ zooms in one level, − zooms out one level', (tester) async {
      await pump(tester, 'bar', size: const Size(390, 844)); // zoom 16
      expect(cameraOf(tester).zoom, closeTo(16, 1e-6));

      await tester.tap(find.byTooltip('Ingrandisci'));
      await tester.pumpAndSettle();
      expect(cameraOf(tester).zoom, closeTo(17, 1e-6));

      await tester.tap(find.byTooltip('Riduci'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Riduci'));
      await tester.pumpAndSettle();
      expect(cameraOf(tester).zoom, closeTo(15, 1e-6));
    });

    testWidgets('zoom never goes past the limits', (tester) async {
      await pump(tester, 'bar', size: const Size(390, 844));
      for (var i = 0; i < 8; i++) {
        await tester.tap(find.byTooltip('Ingrandisci'));
        await tester.pumpAndSettle();
      }
      expect(cameraOf(tester).zoom, closeTo(19, 1e-6));
      for (var i = 0; i < 20; i++) {
        await tester.tap(find.byTooltip('Riduci'));
        await tester.pumpAndSettle();
      }
      expect(cameraOf(tester).zoom, closeTo(3, 1e-6));
    });

    testWidgets('reduced motion: zoom is applied immediately', (tester) async {
      await pump(tester, 'bar', size: const Size(390, 844), reduced: true);
      await tester.tap(find.byTooltip('Ingrandisci'));
      await tester.pump();
      expect(cameraOf(tester).zoom, closeTo(17, 1e-6));
    });
  });

  group('cerchi col numero', () {
    // A 390x844 la mappa inquadra i 4 punti a ~zoom 11,7 (~36 m/px):
    // Arco–Pineta 1 km ≈ 27 px → un cerchio "2"; Gatti a ~58 px e Frida restano pin.
    testWidgets('nearby points collapse into a numbered circle at wide zoom', (
      tester,
    ) async {
      presetsAre([_arco, _pineta, _gatti, _frida]);
      await pump(tester, 'bar', size: const Size(390, 844));
      expect(find.text('2'), findsOneWidget);
      expect(find.text('🍻'), findsNWidgets(2)); // Gatti e Frida: pin singoli
    });

    testWidgets('a lone point is never a circle', (tester) async {
      presetsAre([_arco, _frida]);
      await pump(tester, 'bar', size: const Size(390, 844));
      expect(find.text('🍻'), findsNWidgets(2));
      expect(find.text('2'), findsNothing);
    });

    testWidgets('tapping a circle zooms in and splits it into pins', (
      tester,
    ) async {
      presetsAre([_arco, _pineta, _gatti, _frida]);
      await pump(tester, 'bar', size: const Size(390, 844));
      final before = cameraOf(tester).zoom;

      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();

      expect(cameraOf(tester).zoom, greaterThan(before + 1));
      expect(find.text('2'), findsNothing); // ora sono due pin separati
    });

    testWidgets('zooming out with − merges pins back into a circle', (
      tester,
    ) async {
      presetsAre([_arco, _pineta, _gatti, _frida]);
      await pump(tester, 'bar', size: const Size(390, 844));
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      expect(find.text('2'), findsNothing);

      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byTooltip('Riduci'));
        await tester.pumpAndSettle();
      }
      expect(
        find.textContaining(RegExp(r'^\d$')),
        findsWidgets,
      ); // ricompare un cerchio
    });

    testWidgets(
      'the place you chose is a pin of its own, not part of a circle',
      (tester) async {
        presetsAre([_arco, _pineta, _gatti, _frida]);
        await pump(tester, 'bar', size: const Size(390, 844));
        expect(find.text('2'), findsOneWidget);

        final arcoChip = find.byKey(const ValueKey('chip:Arco del Tempo'));
        await tester.ensureVisible(arcoChip); // la fila di chip è scorrevole
        await tester.pumpAndSettle();
        await tester.tap(arcoChip);
        await tester.pumpAndSettle();

        expect(find.text('2'), findsNothing); // Pineta resta da sola
        expect(
          find.text('Arco del Tempo'),
          findsAtLeastNWidgets(2),
        ); // chip + etichetta
        expect(cta(tester).onPressed, isNotNull);
      },
    );
  });

  group('classifica dei preset', () {
    Finder chip(String name) => find.byKey(ValueKey('chip:$name'));

    testWidgets(
      'chips follow the order given by the server, most chosen first',
      (tester) async {
        // Ordine del server: Pineta (×5) prima di Arco (×2) prima di Gatti (×0).
        presetsAre([
          const PlaceCandidate(
            name: 'Pineta Comunale',
            lat: 41.03797,
            lng: 16.73744,
            timesUsed: 5,
          ),
          const PlaceCandidate(
            name: 'Arco del Tempo',
            lat: 41.03954,
            lng: 16.74883,
            timesUsed: 2,
          ),
          _gatti,
        ]);
        await pump(tester, 'bar', size: const Size(2400, 900));

        final xs = [
          for (final n in ['Pineta Comunale', 'Arco del Tempo', 'GATTI Area'])
            tester.getTopLeft(chip(n)).dx,
        ];
        expect(xs, orderedEquals([...xs]..sort()));
        expect(xs.toSet().length, 3);
        // …e "La tua posizione" resta sempre il primo.
        expect(tester.getTopLeft(locateChip).dx, lessThan(xs.first));
      },
    );

    testWidgets('a small ×N shows how many times a place was chosen', (
      tester,
    ) async {
      presetsAre([
        const PlaceCandidate(
          name: 'Pineta Comunale',
          lat: 41.03797,
          lng: 16.73744,
          timesUsed: 5,
        ),
        const PlaceCandidate(
          name: 'Arco del Tempo',
          lat: 41.03954,
          lng: 16.74883,
          timesUsed: 1,
        ),
        _gatti, // mai scelto → nessun numero
      ]);
      await pump(tester, 'bar', size: const Size(2400, 900));

      expect(
        find.descendant(of: chip('Pineta Comunale'), matching: find.text('×5')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: chip('Arco del Tempo'), matching: find.text('×1')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: chip('GATTI Area'),
          matching: find.textContaining('×'),
        ),
        findsNothing,
      );
      // La posizione non è un preset: mai un contatore.
      expect(
        find.descendant(of: locateChip, matching: find.textContaining('×')),
        findsNothing,
      );
    });

    testWidgets('the counter also shows on the selected chip', (tester) async {
      presetsAre([
        const PlaceCandidate(
          name: 'Arco del Tempo',
          lat: 41.03954,
          lng: 16.74883,
          timesUsed: 3,
        ),
      ]);
      await pump(tester, 'bar', size: const Size(2400, 900));
      await tester.tap(chip('Arco del Tempo'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: chip('Arco del Tempo'), matching: find.text('×3')),
        findsOneWidget,
      );
    });

    testWidgets('no more limit of 8: every preset is shown', (tester) async {
      final many = [
        for (var i = 0; i < 14; i++)
          PlaceCandidate(name: 'Posto $i', lat: 41.03 + i * 0.001, lng: 16.74),
      ];
      presetsAre(many);
      await pump(
        tester,
        'bar',
        size: const Size(2400, 900),
      ); // largo: tutti i chip visibili
      for (final p in many) {
        expect(chip(p.name), findsOneWidget, reason: p.name);
      }
    });
  });

  group('stile (blocchi della Home)', () {
    // Cornice della mappa: blocco nel colore del pulsante della Home, con la sua
    // ombra piena.
    Finder frameOf(Activity a) => find.byWidgetPredicate((w) {
      if (w is! DecoratedBox) return false;
      final d = w.decoration;
      if (d is! BoxDecoration || d.color != a.background) return false;
      if (d.borderRadius != BorderRadius.circular(26)) return false;
      return a.dashed
          ? d.boxShadow == null
          : d.boxShadow?.single.color == a.shadow &&
                d.boxShadow?.single.offset == const Offset(0, 5);
    });

    for (final id in ['bar', 'bombolone', 'chill', 'mangiare', 'bho']) {
      testWidgets('$id: the map frame reuses the Home button colour', (
        tester,
      ) async {
        await pump(tester, id);
        expect(frameOf(activityById(id)), findsOneWidget);
      });
    }

    testWidgets('Bho frame is dashed, the others are not', (tester) async {
      Finder dashedFrame() => find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            w.foregroundPainter is DashedBorderPainter &&
            (w.foregroundPainter! as DashedBorderPainter).radius == 26,
      );

      await pump(tester, 'bho');
      expect(dashedFrame(), findsOneWidget);
      await pump(tester, 'bar');
      expect(dashedFrame(), findsNothing);
    });

    testWidgets('search bar and chips are flat Home-style pills', (
      tester,
    ) async {
      await pump(tester, 'bar');
      expect(find.text('Cerca un locale, indirizzo, piazza…'), findsOneWidget);
      expect(locateChip, findsOneWidget);
      expect(
        find.byKey(const ValueKey('chip:Piazza Aldo Moro')),
        findsOneWidget,
      );
    });
  });
}
