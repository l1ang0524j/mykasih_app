import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyDbLrrLV8jl4Sm1j1JOC7Td2cKU6KaWYFM';

  static GenerativeModel? _model;

  // 初始化模型（只初始化一次）
  static void _initModel() {
    if (_model != null) return; // 如果已经初始化，直接返回

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.5,
        maxOutputTokens: 500,
      ),
    );
  }

  // 生成新闻摘要
  static Future<String> generateSummary(String title, String description) async {
    try {
      _initModel();
      if (_model == null) throw Exception('Model not initialized');

      final prompt = '''
Berikut adalah berita dari Malaysia:

Tajuk: $title
Kandungan: $description

Tugas anda:
1. Tulis ringkasan pendek dalam 2-3 ayat dalam Bahasa Melayu
2. Fokus kepada perkara penting sahaja
3. Gunakan bahasa yang mudah difahami
4. Pastikan ringkasan tepat dengan berita asal

Ringkasan:
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Maaf, tidak dapat menjana ringkasan.';
    } catch (e) {
      return 'Ralat semasa menjana ringkasan: $e';
    }
  }

  // 翻译文本
  static Future<String> translateText(String text, String targetLanguage) async {
    try {
      _initModel();
      if (_model == null) throw Exception('Model not initialized');

      String languageName;
      String instruction;

      switch (targetLanguage) {
        case 'ms':
          languageName = 'Bahasa Melayu';
          instruction = 'Terjemahkan teks berikut ke Bahasa Melayu dengan tepat dan natural. Pastikan terjemahan mudah difahami oleh penutur Melayu.';
          break;
        case 'en':
          languageName = 'English';
          instruction = 'Translate the following text to English accurately and naturally. Make sure the translation is easy to understand for English speakers.';
          break;
        case 'zh':
          languageName = 'Chinese';
          instruction = '将以下文本翻译成中文，要求准确自然。确保翻译易于中文使用者理解。';
          break;
        case 'ta':
          languageName = 'Tamil';
          instruction = 'பின்வரும் உரையை தமிழில் துல்லியமாகவும் இயற்கையாகவும் மொழிபெயர்க்கவும். மொழிபெயர்ப்பு தமிழ் பேசுபவர்களுக்கு எளிதில் புரியும்படி இருக்க வேண்டும்.';
          break;
        default:
          languageName = 'English';
          instruction = 'Translate the following text to English accurately and naturally.';
      }

      final prompt = '''
$instruction

Text to translate:
$text

Translation:
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Translation failed. Please try again.';
    } catch (e) {
      return 'Error during translation: $e';
    }
  }

  // 获取新闻摘要（英文版本）
  static Future<String> generateSummaryEnglish(String title, String description) async {
    try {
      _initModel();
      if (_model == null) throw Exception('Model not initialized');

      final prompt = '''
Here is a news article from Malaysia:

Title: $title
Content: $description

Your task:
1. Write a short summary in 2-3 sentences in English
2. Focus only on key points
3. Use simple and clear language
4. Keep the summary accurate to the original news

Summary:
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Sorry, unable to generate summary.';
    } catch (e) {
      return 'Error generating summary: $e';
    }
  }

  // 获取新闻关键词
  static Future<List<String>> extractKeywords(String title, String description) async {
    try {
      _initModel();
      if (_model == null) throw Exception('Model not initialized');

      final prompt = '''
Extract 3-5 main keywords from this news article:

Title: $title
Content: $description

Return only the keywords as a comma-separated list, nothing else.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      if (response.text != null) {
        return response.text!
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 回答问题关于新闻
  static Future<String> askQuestion(String title, String description, String question) async {
    try {
      _initModel();
      if (_model == null) throw Exception('Model not initialized');

      final prompt = '''
Based on this news article, answer the question:

Article Title: $title
Article Content: $description

Question: $question

Answer in a helpful and concise way. If the question cannot be answered from the article, say so.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Sorry, could not answer the question.';
    } catch (e) {
      return 'Error: $e';
    }
  }

  // 判断新闻是否与MyKasih相关
  static Future<bool> isMyKasihRelated(String title, String description) async {
    try {
      _initModel();
      if (_model == null) throw Exception('Model not initialized');

      final prompt = '''
Is this news article related to MyKasih, SARA, or Malaysian government aid?

Title: $title
Content: $description

Answer only "yes" or "no".
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text?.toLowerCase().contains('yes') ?? false;
    } catch (e) {
      return false;
    }
  }
}