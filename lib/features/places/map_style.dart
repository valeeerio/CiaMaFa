import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Stile della mappa CARTO in base alla modalità del dispositivo.
///
/// - chiara: Positron + tinta crema (A)
/// - scura: Dark Matter con più contrasto, ricolorata blu notte (C)
class MapStyle {
  const MapStyle({required this.cartoStyle, required this.matrix});

  /// Nome dello stile in `rastertiles/<stile>`.
  final String cartoStyle;

  /// Matrice colore 4x5 (formato `ColorFilter.matrix`).
  final List<double> matrix;

  ColorFilter get filter => ColorFilter.matrix(matrix);
}

MapStyle mapStyleFor(Brightness brightness) => brightness == Brightness.dark
    ? MapStyle(
        cartoStyle: 'dark_all',
        matrix: duotoneMatrix(
          start: const Color(0xFF14203C),
          end: const Color(0xFFE1E8FA),
          gain: 2.6,
          bias: 0.12,
        ),
      )
    : MapStyle(
        cartoStyle: 'light_all',
        matrix: multiplyMatrix(AppColors.cream),
      );

/// Moltiplica ogni canale per la tinta (0-255 → 0-1).
List<double> multiplyMatrix(Color tint) => [
  tint.r, 0, 0, 0, 0, //
  0, tint.g, 0, 0, 0,
  0, 0, tint.b, 0, 0,
  0, 0, 0, 1, 0,
];

/// Luminanza → gradiente da [start] a [end], con `gain`/`bias` sul contrasto.
///
/// out = start + (end - start) * (gain * L + bias), con L in 0..1.
///
/// Una matrice colore non può limitare `gain * L + bias` a 1 prima di
/// ricolorare: i chiari oltre `end` saturano verso il bianco.
List<double> duotoneMatrix({
  required Color start,
  required Color end,
  double gain = 1,
  double bias = 0,
}) {
  const wr = 0.299, wg = 0.587, wb = 0.114;
  List<double> row(double s, double e) {
    final delta = (e - s) * 255; // 0..1 → scala 0..255 dell'output
    final k = delta * gain / 255; // L è già in scala 0..255 in input
    return [k * wr, k * wg, k * wb, 0, delta * bias + s * 255];
  }

  return [
    ...row(start.r, end.r),
    ...row(start.g, end.g),
    ...row(start.b, end.b),
    0,
    0,
    0,
    1,
    0,
  ];
}
