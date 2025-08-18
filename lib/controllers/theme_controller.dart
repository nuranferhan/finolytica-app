import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  var themeMode = ThemeMode.system.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadThemeMode();
  }

  void toggleTheme() {
    if (themeMode.value == ThemeMode.light) {
      themeMode.value = ThemeMode.dark;
    } else {
      themeMode.value = ThemeMode.light;
    }
    Get.changeThemeMode(themeMode.value);
    saveThemeMode();
  }

  void loadThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? themeIndex = prefs.getInt('themeMode');
    if (themeIndex != null) {
      themeMode.value = ThemeMode.values[themeIndex];
      Get.changeThemeMode(themeMode.value);
    }
  }

  void saveThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('themeMode', themeMode.value.index);
  }
}