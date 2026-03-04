import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'providers/font_size_provider.dart';
import 'providers/language_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://fsborkdngvgeuvxtdjhf.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZzYm9ya2RuZ3ZnZXV2eHRkamhmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI0MTMzOTUsImV4cCI6MjA4Nzk4OTM5NX0.O7yAvOZzbfEjOdyA-HKzbftqBZhWO6T-tYgSr063KPQ',
    );
    print('✅ Supabase initialized');
  } catch (e) {
    print('❌ Supabase error: $e');
  }

  runApp(const MyKasihApp());
}

class MyKasihApp extends StatelessWidget {
  const MyKasihApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FontSizeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'MyKasih',
            theme: ThemeData(
              primaryColor: const Color(0xFF2E7D32),
              primarySwatch: Colors.green,
            ),
            debugShowCheckedModeBanner: false,
            locale: languageProvider.locale,  // 从 Provider 获取语言
            supportedLocales: LanguageProvider.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const LoginScreen(),
          );
        },
      ),
    );
  }
}