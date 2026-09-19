import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appThemeModeControllerProvider = Provider<ValueNotifier<ThemeMode>>((
  ref,
) {
  // FLEXWOLF starts in light mode on every device. Customers can still switch
  // to dark mode explicitly from the app shell.
  final controller = ValueNotifier<ThemeMode>(ThemeMode.light);
  ref.onDispose(controller.dispose);
  return controller;
});
