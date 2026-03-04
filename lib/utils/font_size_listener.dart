import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/font_size_provider.dart';

class FontSizeListener extends StatelessWidget {
  final Widget child;
  final Widget Function(BuildContext context, double fontSize) builder;

  const FontSizeListener({
    super.key,
    required this.child,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    // 使用 Consumer 来监听字体大小变化
    return Consumer<FontSizeProvider>(
      builder: (context, provider, _) {
        return builder(context, provider.fontSize);
      },
    );
  }
}