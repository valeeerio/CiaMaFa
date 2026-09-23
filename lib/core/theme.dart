import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette dal prototipo approvato. NON modificare.
abstract final class AppColors {
  static const cream = Color(0xFFFDF6E9);
  static const orange = Color(0xFFFF8C42);
  static const orangeShadow = Color(0xFFE06B25);
  static const coral = Color(0xFFFF6F61);
  static const coralShadow = Color(0xFFD9524A);
  static const coralText = Color(0xFFB33B30);
  static const nightBlue = Color(0xFF1B2A4A);
  static const acidGreen = Color(0xFFC6F135);
  static const acidGreenShadow = Color(0xFFA9D01D);
  static const muted = Color(0xFF5C6670);
  static const white = Color(0xFFFFFFFF);
}

/// Font inclusi negli asset (`assets/google_fonts/`): nessun download a
/// runtime, quindi nessun IP dell'utente inviato a Google. Registra anche la
/// licenza OFL dei font nella pagina "Licenze open source".
void configureBundledFonts() {
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    for (final (family, file) in const [
      ('Baloo 2', 'OFL-Baloo2.txt'),
      ('Poppins', 'OFL-Poppins.txt'),
    ]) {
      final text = await rootBundle.loadString('assets/google_fonts/$file');
      yield LicenseEntryWithLineBreaks([family], text);
    }
  });
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.orange,
      primary: AppColors.orange,
      secondary: AppColors.coral,
      tertiary: AppColors.acidGreen,
      surface: AppColors.cream,
      onSurface: AppColors.nightBlue,
    ),
    scaffoldBackgroundColor: AppColors.cream,
  );

  final body = GoogleFonts.poppinsTextTheme(base.textTheme)
      .apply(bodyColor: AppColors.nightBlue, displayColor: AppColors.nightBlue);
  TextStyle? display(TextStyle? s) =>
      GoogleFonts.baloo2(textStyle: s, fontWeight: FontWeight.w800);

  return base.copyWith(
    textTheme: body.copyWith(
      displayLarge: display(body.displayLarge),
      displayMedium: display(body.displayMedium),
      displaySmall: display(body.displaySmall),
      headlineLarge: display(body.headlineLarge),
      headlineMedium: display(body.headlineMedium),
      headlineSmall: display(body.headlineSmall),
      titleLarge: display(body.titleLarge),
    ),
  );
}
