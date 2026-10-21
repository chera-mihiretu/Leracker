import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progress_tracker/core/presentation/widgets/progress_tracker_logo.dart';
import 'package:progress_tracker/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('lightTheme adheres to ProgressTrackerPalette.light brand colors', () {
      final theme = AppTheme.lightTheme;

      expect(theme.brightness, Brightness.light);
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, ProgressTrackerPalette.light.emerald);
      expect(theme.colorScheme.secondary, ProgressTrackerPalette.light.jade);
      expect(theme.colorScheme.tertiary, ProgressTrackerPalette.light.mint);
      expect(theme.scaffoldBackgroundColor, ProgressTrackerPalette.light.background);
      expect(theme.colorScheme.outline, ProgressTrackerPalette.light.inactive);
    });

    test('darkTheme adheres to ProgressTrackerPalette.dark brand colors', () {
      final theme = AppTheme.darkTheme;

      expect(theme.brightness, Brightness.dark);
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, ProgressTrackerPalette.dark.emerald);
      expect(theme.colorScheme.secondary, ProgressTrackerPalette.dark.jade);
      expect(theme.colorScheme.tertiary, ProgressTrackerPalette.dark.mint);
      expect(theme.scaffoldBackgroundColor, ProgressTrackerPalette.dark.background);
      expect(theme.colorScheme.outline, ProgressTrackerPalette.dark.inactive);
      expect(theme.colorScheme.surface, const Color(0xFF1E293B));
    });
  });
}

