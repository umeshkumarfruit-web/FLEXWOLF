import 'package:flutter/services.dart';

abstract final class AppHaptics {
  static Future<void> selection() => HapticFeedback.selectionClick();

  static Future<void> confirmation() => HapticFeedback.lightImpact();
}
