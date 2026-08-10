import 'package:ddr001_diag_view_app/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('primary field buttons keep the high-contrast light foreground', () {
    final theme = buildAppTheme();
    final foreground = theme.filledButtonTheme.style?.foregroundColor?.resolve(
      const <WidgetState>{},
    );

    expect(foreground, AppColors.text);
  });
}
