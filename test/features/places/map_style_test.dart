import 'dart:ui';

import 'package:ciamafa/features/places/map_style.dart';
import 'package:flutter_test/flutter_test.dart';

/// Applica una matrice 4x5 (formato ColorFilter.matrix) a un colore RGB 0-255.
List<int> apply(List<double> m, int r, int g, int b) => [
  for (var row = 0; row < 3; row++)
    (m[row * 5] * r + m[row * 5 + 1] * g + m[row * 5 + 2] * b + m[row * 5 + 4])
        .round()
        .clamp(0, 255),
];

void main() {
  test('light mode uses Positron tinted with the app cream', () {
    final s = mapStyleFor(Brightness.light);
    expect(s.cartoStyle, 'light_all');
    expect(apply(s.matrix, 255, 255, 255), [253, 246, 233]); // bianco → crema
    expect(apply(s.matrix, 0, 0, 0), [0, 0, 0]);
  });

  test('dark mode uses Dark Matter recoloured to night blue', () {
    final s = mapStyleFor(Brightness.dark);
    expect(s.cartoStyle, 'dark_all');

    final black = apply(s.matrix, 0, 0, 0); // sfondo: blu notte scuro
    expect(black[2], greaterThan(black[0])); // blu prevale
    expect(black[0] + black[1] + black[2], lessThan(300));

    final white = apply(s.matrix, 255, 255, 255); // etichette: molto chiare
    expect(white.every((c) => c >= 225), isTrue);

    // Le strade (grigio scuro) diventano più chiare dello sfondo.
    final road = apply(s.matrix, 60, 60, 60);
    expect(road[2], greaterThan(black[2]));
  });

  test('dark map keeps a readable contrast between roads and background', () {
    final s = mapStyleFor(Brightness.dark);
    final bg = apply(s.matrix, 12, 12, 12);
    final road = apply(s.matrix, 60, 60, 60);
    final diff = (road[2] - bg[2]).abs() + (road[1] - bg[1]).abs();
    expect(diff, greaterThan(60));
  });
}
