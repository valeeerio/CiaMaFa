import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Pin della mappa: verde = non selezionato, corallo = selezionato.
class MapPin extends StatelessWidget {
  const MapPin({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.location_on,
      size: selected ? 48 : 40,
      color: selected ? AppColors.coral : AppColors.acidGreenShadow,
      shadows: const [Shadow(color: Color(0x55000000), blurRadius: 4)],
    );
  }
}
