import 'dart:async';

import 'package:ciamafa/features/places/location_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';

class MockGateway extends Mock implements GeolocatorGateway {}

const _here = LatLng(41.0414, 16.7487);

void main() {
  setUpAll(() => registerFallbackValue(Duration.zero));

  late MockGateway gw;
  late GeolocatorLocationService service;

  setUp(() {
    gw = MockGateway();
    service = GeolocatorLocationService(gw);
    // Di base: servizio acceso, permesso già concesso, posizione disponibile.
    when(() => gw.isServiceEnabled()).thenAnswer((_) async => true);
    when(() => gw.checkPermission())
        .thenAnswer((_) async => LocationPermission.whileInUse);
    when(() => gw.currentPosition(timeLimit: any(named: 'timeLimit')))
        .thenAnswer((_) async => const GeoFix(_here, accuracyMeters: 25));
  });

  LocationFailureReason? failure(LocationResult r) =>
      r is LocationFailure ? r.reason : null;

  group('locate()', () {
    test(
      'found: returns the position and never asks for permission again',
      () async {
        final r = await service.locate();
        expect(r, isA<LocationFound>());
        expect((r as LocationFound).point, _here);
        expect(r.accuracyMeters, 25);
        verifyNever(() => gw.requestPermission());
      },
    );

    test('waits at most 8 seconds for a position', () async {
      await service.locate();
      verify(() => gw.currentPosition(timeLimit: const Duration(seconds: 8)))
          .called(1);
    });

    test(
      'location turned off → serviceDisabled (and never asks permission)',
      () async {
        when(() => gw.isServiceEnabled()).thenAnswer((_) async => false);
        expect(
          failure(await service.locate()),
          LocationFailureReason.serviceDisabled,
        );
        verifyNever(() => gw.checkPermission());
      },
    );

    test(
      'permission not yet asked → asks once, then uses the position',
      () async {
        when(() => gw.checkPermission())
            .thenAnswer((_) async => LocationPermission.denied);
        when(() => gw.requestPermission())
            .thenAnswer((_) async => LocationPermission.whileInUse);
        expect(await service.locate(), isA<LocationFound>());
        verify(() => gw.requestPermission()).called(1);
      },
    );

    test('permission refused at the prompt → denied', () async {
      when(() => gw.checkPermission())
          .thenAnswer((_) async => LocationPermission.denied);
      when(() => gw.requestPermission())
          .thenAnswer((_) async => LocationPermission.denied);
      expect(failure(await service.locate()), LocationFailureReason.denied);
      verifyNever(() => gw.currentPosition(timeLimit: any(named: 'timeLimit')));
    });

    test(
      'permission refused for good → deniedForever, no prompt, no lookup',
      () async {
        when(() => gw.checkPermission())
            .thenAnswer((_) async => LocationPermission.deniedForever);
        expect(
          failure(await service.locate()),
          LocationFailureReason.deniedForever,
        );
        verifyNever(() => gw.requestPermission());
        verifyNever(
          () => gw.currentPosition(timeLimit: any(named: 'timeLimit')),
        );
      },
    );

    test('prompt answered "never" → deniedForever', () async {
      when(() => gw.checkPermission())
          .thenAnswer((_) async => LocationPermission.denied);
      when(() => gw.requestPermission())
          .thenAnswer((_) async => LocationPermission.deniedForever);
      expect(
        failure(await service.locate()),
        LocationFailureReason.deniedForever,
      );
    });

    test('"always" permission works like "while in use"', () async {
      when(() => gw.checkPermission())
          .thenAnswer((_) async => LocationPermission.always);
      expect(await service.locate(), isA<LocationFound>());
    });

    test(
      'no position in time (e.g. simulator without a location) → timeout',
      () async {
        when(() => gw.currentPosition(timeLimit: any(named: 'timeLimit')))
            .thenThrow(TimeoutException('nessuna posizione'));
        expect(failure(await service.locate()), LocationFailureReason.timeout);
      },
    );

    test('exceptions from the platform map to the right reason', () async {
      when(() => gw.currentPosition(timeLimit: any(named: 'timeLimit')))
          .thenThrow(const PermissionDeniedException('no'));
      expect(failure(await service.locate()), LocationFailureReason.denied);

      when(() => gw.currentPosition(timeLimit: any(named: 'timeLimit')))
          .thenThrow(const LocationServiceDisabledException());
      expect(
        failure(await service.locate()),
        LocationFailureReason.serviceDisabled,
      );
    });

    test('any other error → unavailable (never throws)', () async {
      when(() => gw.currentPosition(timeLimit: any(named: 'timeLimit')))
          .thenThrow(StateError('boom'));
      expect(
        failure(await service.locate()),
        LocationFailureReason.unavailable,
      );

      when(() => gw.isServiceEnabled()).thenThrow(Exception('platform error'));
      expect(
        failure(await service.locate()),
        LocationFailureReason.unavailable,
      );
    });
  });

  group('openSettings()', () {
    setUp(() {
      when(() => gw.openAppSettings()).thenAnswer((_) async => true);
      when(() => gw.openLocationSettings()).thenAnswer((_) async => true);
    });

    test('location turned off → the system location settings', () async {
      await service.openSettings(LocationFailureReason.serviceDisabled);
      verify(() => gw.openLocationSettings()).called(1);
      verifyNever(() => gw.openAppSettings());
    });

    test('permission refused for good → the app settings', () async {
      await service.openSettings(LocationFailureReason.deniedForever);
      verify(() => gw.openAppSettings()).called(1);
      verifyNever(() => gw.openLocationSettings());
    });

    test('never throws, even if the settings cannot be opened', () async {
      when(() => gw.openAppSettings()).thenThrow(Exception('no'));
      await service.openSettings(LocationFailureReason.deniedForever);
    });
  });

  group('LocationFailureReason', () {
    test('every reason has a distinct, non-generic message', () {
      final messages = LocationFailureReason.values
          .map((r) => r.message)
          .toList();
      expect(messages.toSet().length, messages.length);
      expect(
        messages,
        everyElement(isNot(contains('controlla i permessi di posizione'))),
      );
    });

    test('only "off" and "denied for good" need the system settings', () {
      final needs = LocationFailureReason.values.where((r) => r.needsSettings);
      expect(
        needs,
        unorderedEquals([
          LocationFailureReason.serviceDisabled,
          LocationFailureReason.deniedForever,
        ]),
      );
    });
  });
}
