import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/theme_store.dart';

class ThemeController extends GetxController {
  ThemeController(this._store);

  final ThemeStore _store;

  final Rx<ThemeMode> mode = ThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    final stored = await _store.readThemeMode();
    mode.value = stored;
    Get.changeThemeMode(stored);
  }

  Future<void> setMode(ThemeMode newMode) async {
    mode.value = newMode;
    Get.changeThemeMode(newMode);
    await _store.saveThemeMode(newMode);
  }
}
