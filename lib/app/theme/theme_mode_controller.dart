import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/core/storage/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppThemeModeController extends ValueNotifier<ThemeMode> {
  AppThemeModeController(this._storage) : super(ThemeMode.light) {
    _restore();
  }

  static const _storageKey = 'app_theme_mode';
  final LocalStorage _storage;
  bool _changedByUser = false;
  bool _disposed = false;

  Future<void> _restore() async {
    try {
      final saved = await _storage.readString(_storageKey);
      if (_disposed || _changedByUser) return;
      if (saved == ThemeMode.dark.name) super.value = ThemeMode.dark;
      if (saved == ThemeMode.light.name) super.value = ThemeMode.light;
    } catch (_) {
      // Storage failure must not stop shopping.
    }
  }

  @override
  set value(ThemeMode mode) {
    _changedByUser = true;
    super.value = mode;
    _storage.writeString(_storageKey, mode.name).ignore();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

final appThemeModeControllerProvider = Provider<ValueNotifier<ThemeMode>>((
  ref,
) {
  final controller = AppThemeModeController(ref.watch(localStorageProvider));
  ref.onDispose(controller.dispose);
  return controller;
});
