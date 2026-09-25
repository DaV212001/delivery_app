import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/storage_config.dart';

class ThemeController extends GetxController {
  final _isDarkMode = false.obs;
  bool get isDarkMode => _isDarkMode.value;
  ThemeMode get themeMode => _isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  @override
  void onInit() {
    super.onInit();
    _isDarkMode.value = ConfigPreference.isDarkMode();
  }

  void toggleTheme() {
    _isDarkMode.value = !_isDarkMode.value;
    ConfigPreference.setDarkMode(_isDarkMode.value);
    Get.changeThemeMode(themeMode);
  }
}
