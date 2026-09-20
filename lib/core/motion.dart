import 'package:flutter/material.dart';

/// Token di movimento dell'app: "fluido e morbido", solo in risposta ai tocchi.
/// Regola qui la vivacità: tutte le animazioni leggono questi valori.
abstract final class Motion {
  static const fast = Duration(milliseconds: 180);
  static const base = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 520);
  static const camera = Duration(milliseconds: 600);

  /// Ritardo tra un elemento e il successivo nelle entrate a cascata.
  static const stagger = Duration(milliseconds: 45);

  static const Curve soft = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  /// "Riduci movimento" attivo sul dispositivo.
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  /// [d], oppure zero se il movimento è ridotto.
  static Duration of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;
}
