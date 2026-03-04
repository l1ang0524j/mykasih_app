import 'package:flutter/material.dart';
import '../utils/font_size_manager.dart';

class FontSizeProvider extends ChangeNotifier {
  double _fontSize = FontSizeManager.normal;

  double get fontSize => _fontSize;

  FontSizeProvider() {
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    _fontSize = await FontSizeManager.getFontSize();
    notifyListeners();
  }

  Future<void> updateFontSize(double newSize) async {
    if (_fontSize != newSize) {
      _fontSize = newSize;
      await FontSizeManager.saveFontSize(newSize);
      notifyListeners();
    }
  }
}