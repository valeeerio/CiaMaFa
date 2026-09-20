import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Blu del puntino "sei qui": usato SOLO per la posizione dell'utente, per non
/// confonderla con i locali (verde acido) e il luogo scelto (corallo).
const userPositionBlue = Color(0xFF2F80ED);

/// Quanto tempo fa, in parole: "oggi", "ieri", "3 giorni fa", "2 sett. fa",
/// "1 mese fa". [now] è iniettabile per i test.
String formatLastUsed(DateTime when, {DateTime? now}) {
  final today = (now ?? DateTime.now());
  final days = DateTime(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime(when.year, when.month, when.day)).inDays;
  if (days <= 0) return 'oggi';
  if (days == 1) return 'ieri';
  if (days < 7) return '$days giorni fa';
  if (days < 30) return '${days ~/ 7} sett. fa';
  final months = days ~/ 30;
  return months == 1 ? '1 mese fa' : '$months mesi fa';
}

/// Diametro in pixel dell'alone della posizione: la precisione del GPS
/// ([accuracyMeters], raggio) in scala con lo zoom, mai più piccolo di 56 px
/// (si vede sempre) né più grande di 220.
double userHaloSize({
  required double? accuracyMeters,
  required double latitude,
  required double zoom,
}) {
  final metersPerPixel =
      156543.03392 * math.cos(latitude * math.pi / 180) / math.pow(2, zoom);
  return (2 * (accuracyMeters ?? 30) / metersPerPixel).clamp(56.0, 220.0);
}
