import 'package:ciamafa/core/theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('palette is the approved one', () {
    expect(AppColors.cream.toARGB32(), 0xFFFDF6E9);
    expect(AppColors.nightBlue.toARGB32(), 0xFF1B2A4A);
    expect(AppColors.acidGreen.toARGB32(), 0xFFC6F135);
  });
}
