import 'package:ciamafa/shared/map_pin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('teardrop pin shows the activity emoji and has the right size', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: MapPin(selected: false, emoji: '🍻')),
      ),
    );
    expect(find.text('🍻'), findsOneWidget);
    expect(tester.getSize(find.byType(MapPin)), MapPin.presetSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: MapPin(selected: true, emoji: '🍻')),
      ),
    );
    expect(tester.getSize(find.byType(MapPin)), MapPin.selectedSize);
  });
}
