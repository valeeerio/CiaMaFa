import 'package:ciamafa/features/places/camera_animator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

const _a = LatLng(41.0414, 16.7487);
const _near = LatLng(41.0420, 16.7490); // ~70 m
const _far = LatLng(41.1200, 16.8600); // ~13 km

class _Harness extends StatefulWidget {
  const _Harness({required this.onReady});

  final void Function(CameraAnimator animator, MapController map) onReady;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness>
    with SingleTickerProviderStateMixin {
  final map = MapController();
  late final animator = CameraAnimator(vsync: this, controller: map);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.onReady(animator, map),
    );
  }

  @override
  void dispose() {
    animator.dispose();
    map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: FlutterMap(
      mapController: map,
      options: const MapOptions(initialCenter: _a, initialZoom: 14),
      children: const [],
    ),
  );
}

void main() {
  group('cameraFrame', () {
    test('starts at "from" and ends exactly at "to"', () {
      final start = cameraFrame(
        from: _a,
        to: _far,
        fromZoom: 14,
        toZoom: 16,
        dip: 1,
        t: 0,
      );
      final end = cameraFrame(
        from: _a,
        to: _far,
        fromZoom: 14,
        toZoom: 16,
        dip: 1,
        t: 1,
      );
      expect((start.center, start.zoom), (_a, 14.0));
      expect(end.center.latitude, closeTo(_far.latitude, 1e-9));
      expect(end.center.longitude, closeTo(_far.longitude, 1e-9));
      expect(end.zoom, closeTo(16, 1e-9));
    });

    test('zooms out mid-flight when dip > 0, not when dip == 0', () {
      final withDip = cameraFrame(
        from: _a,
        to: _far,
        fromZoom: 16,
        toZoom: 16,
        dip: 1.2,
        t: 0.5,
      );
      final flat = cameraFrame(
        from: _a,
        to: _far,
        fromZoom: 16,
        toZoom: 16,
        dip: 0,
        t: 0.5,
      );
      expect(withDip.zoom, closeTo(16 - 1.2, 1e-9));
      expect(flat.zoom, 16);
    });

    test('dip is zero for short moves and grows (capped) with distance', () {
      expect(cameraDip(_a, _near), 0);
      expect(cameraDip(_a, _far), inInclusiveRange(0.5, 1.5));
    });
  });

  group('CameraAnimator', () {
    testWidgets('animates to the target and ends exactly there', (
      tester,
    ) async {
      late CameraAnimator animator;
      late MapController map;
      await tester.pumpWidget(
        _Harness(
          onReady: (a, m) {
            animator = a;
            map = m;
          },
        ),
      );
      await tester.pump();

      animator.flyTo(_far, minZoom: 16, reduced: false);
      await tester.pump(); // avvia il ticker
      await tester.pump(const Duration(milliseconds: 300));
      expect(map.camera.center, isNot(_a)); // in movimento
      expect(map.camera.center, isNot(_far)); // non ancora arrivata

      await tester.pumpAndSettle();
      expect(map.camera.center.latitude, closeTo(_far.latitude, 1e-6));
      expect(map.camera.center.longitude, closeTo(_far.longitude, 1e-6));
      expect(map.camera.zoom, closeTo(16, 1e-6));
    });

    testWidgets(
      'an explicit zoom is used exactly (even lower than the current)',
      (tester) async {
        late CameraAnimator animator;
        late MapController map;
        await tester.pumpWidget(
          _Harness(
            onReady: (a, m) {
              animator = a;
              map = m;
            },
          ),
        );
        await tester.pump();

        animator.flyTo(_far, zoom: 12, reduced: false);
        await tester.pump();
        await tester.pumpAndSettle();
        expect(map.camera.zoom, closeTo(12, 1e-6));
        expect(map.camera.center.latitude, closeTo(_far.latitude, 1e-6));
      },
    );

    testWidgets('reduced motion jumps immediately', (tester) async {
      late CameraAnimator animator;
      late MapController map;
      await tester.pumpWidget(
        _Harness(
          onReady: (a, m) {
            animator = a;
            map = m;
          },
        ),
      );
      await tester.pump();

      animator.flyTo(_far, minZoom: 16, reduced: true);
      await tester.pump();
      expect(map.camera.center.latitude, closeTo(_far.latitude, 1e-6));
      expect(map.camera.zoom, closeTo(16, 1e-6));
    });
  });
}
