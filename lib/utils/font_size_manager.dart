import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontSizeManager {
  static const String _keyFontSize = 'font_size';

  // 默认字体大小
  static const double small = 12.0;
  static const double normal = 14.0;
  static const double large = 16.0;
  static const double extraLarge = 18.0;

  // 保存字体大小
  static Future<void> saveFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontSize, size);
  }

  // 获取字体大小
  static Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyFontSize) ?? normal;
  }

  // 获取字体大小的标签
  static String getFontSizeLabel(double size) {
    if (size == small) return 'Small';
    if (size == normal) return 'Normal';
    if (size == large) return 'Large';
    if (size == extraLarge) return 'Extra Large';
    return 'Normal';
  }
}