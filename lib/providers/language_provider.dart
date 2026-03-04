import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('ms', ''); // 默认马来文

  Locale get locale => _locale;

  // 支持的语言列表
  static const List<Locale> supportedLocales = [
    Locale('ms', ''), // 马来文
    Locale('en', ''), // 英文
    Locale('zh', ''), // 中文
    Locale('ta', ''), // 淡米尔文
  ];

  // 语言名称映射
  static const Map<String, String> languageNames = {
    'ms': 'Bahasa Melayu',
    'en': 'English',
    'zh': '中文',
    'ta': 'தமிழ்',
  };

  void setLanguage(String languageCode) {
    _locale = Locale(languageCode, '');
    notifyListeners();
  }

  String getCurrentLanguageName() {
    return languageNames[_locale.languageCode] ?? 'Bahasa Melayu';
  }
}