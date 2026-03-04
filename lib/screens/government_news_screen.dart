import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';
import '../services/gemini_service.dart';
import '../utils/font_size_listener.dart';
import '../l10n/app_translations.dart';
import '../providers/language_provider.dart';
import 'package:provider/provider.dart';

class GovernmentNewsScreen extends StatefulWidget {
  const GovernmentNewsScreen({super.key});

  @override
  State<GovernmentNewsScreen> createState() => _GovernmentNewsScreenState();
}

class _GovernmentNewsScreenState extends State<GovernmentNewsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _news = [];
  List<Map<String, dynamic>> _filteredNews = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';  // 确保默认是 'All'
  final TextEditingController _searchController = TextEditingController();

  Timer? _refreshTimer;

  Set<int> _loadingSummary = {};
  Map<int, String> _summaries = {};
  Map<int, Map<String, String>> _translations = {};

  List<String> get categories {
    final cats = _news.map((n) => n['category']?.toString() ?? 'General').toSet().toList();
    cats.sort();
    return ['All', ...cats];  // 'All' 总是在第一个
  }

  @override
  void initState() {
    super.initState();
    _selectedCategory = 'All';
    _loadNews();

    // 添加调试
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('📋 初始 categories: ${categories}');
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNews() async {
    setState(() => _isLoading = true);

    try {
      print('📰 加载新闻...');
      final news = await SupabaseService().getNews();
      print('📰 获取到 ${news.length} 条新闻');

      setState(() {
        _news = news;
        _filterNews();  // 使用当前过滤条件重新过滤
        _isLoading = false;
      });

      // 打印各分类数量供调试
      _printCategoryCounts();
    } catch (e) {
      print('❌ 错误: $e');
      setState(() => _isLoading = false);
      _showError('Failed to load news: $e');
    }
  }

  void _printCategoryCounts() {
    print('📊 新闻分类统计:');
    for (var category in categories) {
      if (category == 'All') continue;
      final count = _news.where((n) => n['category'] == category).length;
      print('   $category: $count 条');
    }
  }

  Future<void> _refreshNews() async {
    await _loadNews();
  }

  Future<void> _generateSummary(int index, Map<String, dynamic> article) async {
    setState(() => _loadingSummary.add(index));

    try {
      final summary = await GeminiService.generateSummary(
        article['title'] ?? '',
        article['description'] ?? '',
      );

      setState(() {
        _summaries[index] = summary;
        _loadingSummary.remove(index);
      });
    } catch (e) {
      setState(() => _loadingSummary.remove(index));
      _showError('Failed to generate summary');
    }
  }

  Future<void> _translateNews(int index, Map<String, dynamic> article, String language) async {
    try {
      final translated = await GeminiService.translateText(
        '${article['title']}\n\n${article['description']}',
        language,
      );

      setState(() {
        _translations[index] ??= {};
        _translations[index]![language] = translated;
      });
    } catch (e) {
      _showError('Translation failed');
    }
  }

  void _removeTranslation(int index, String language) {
    setState(() {
      _translations[index]?.remove(language);
      if (_translations[index]?.isEmpty ?? false) {
        _translations.remove(index);
      }
    });
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'ms': return 'Bahasa Melayu';
      case 'en': return 'English';
      case 'zh': return 'Chinese';
      case 'ta': return 'Tamil';
      default: return code;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _filterNews() {
    setState(() {
      _filteredNews = _news.where((article) {
        final matchesSearch = _searchQuery.isEmpty ||
            (article['title']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (article['description']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

        final matchesCategory = _selectedCategory == 'All' ||
            (article['category']?.toString() == _selectedCategory);

        return matchesSearch && matchesCategory;
      }).toList();
    });

    // 添加调试代码
    print('🔍 过滤后 _filteredNews 有 ${_filteredNews.length} 条新闻');
    final categoriesInFiltered = _filteredNews.map((n) => n['category']?.toString() ?? 'General').toSet().toList();
    for (var cat in categoriesInFiltered) {
      final count = _filteredNews.where((n) => n['category'] == cat).length;
      print('   $cat: $count 条');
    }
  }

  Future<void> _openArticle(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showError('Could not open article');
      }
    } catch (e) {
      print('❌ 打开链接错误: $e');
      _showError('Failed to open article');
    }
  }

  String _getFormattedDate(Map<String, dynamic> article) {
    if (article['published_at'] != null) {
      try {
        final date = DateTime.parse(article['published_at']);
        final now = DateTime.now();
        final difference = now.difference(date);

        if (difference.inDays > 30) {
          return '${date.day}/${date.month}/${date.year}';
        } else if (difference.inDays > 0) {
          return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
        } else if (difference.inHours > 0) {
          return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
        } else if (difference.inMinutes > 0) {
          return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
        } else {
          return 'Just now';
        }
      } catch (e) {
        return 'Just now';
      }
    }
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return FontSizeListener(
          child: const SizedBox(),
          builder: (context, fontSize) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  AppTranslations.translate(context, 'government_news'),
                  style: TextStyle(fontSize: fontSize + 4),
                ),
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refreshNews,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              body: RefreshIndicator(
                onRefresh: _refreshNews,
                color: const Color(0xFF2E7D32),
                child: Column(
                  children: [
                    // Search Bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              _searchQuery = value;
                              _filterNews();
                            },
                            decoration: InputDecoration(
                              hintText: AppTranslations.translate(context, 'search_news'),
                              hintStyle: TextStyle(fontSize: fontSize - 2),
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchQuery = '';
                                  _filterNews();
                                },
                              )
                                  : null,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            style: TextStyle(fontSize: fontSize),
                          ),
                          const SizedBox(height: 12),

                          // Category Filter
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: categories.map((category) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(
                                      category,
                                      style: TextStyle(
                                        fontSize: fontSize - 2,
                                        color: _selectedCategory == category
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    selected: _selectedCategory == category,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedCategory = category;
                                        _filterNews();
                                      });
                                    },
                                    backgroundColor: Colors.grey[100],
                                    selectedColor: const Color(0xFF2E7D32),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // News Count
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_filteredNews.length} ${AppTranslations.translate(context, 'articles_found')}',
                            style: TextStyle(fontSize: fontSize - 2, color: Colors.grey[600]),
                          ),
                          if (_isLoading)
                            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        ],
                      ),
                    ),

                    // News List
                    Expanded(
                      child: _isLoading && _news.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredNews.isEmpty
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.newspaper, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              AppTranslations.translate(context, 'no_news'),
                              style: TextStyle(fontSize: fontSize + 2),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppTranslations.translate(context, 'adjust_search'),
                              style: TextStyle(fontSize: fontSize - 2),
                            ),
                          ],
                        ),
                      )
                          : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredNews.length,
                        itemBuilder: (context, index) {
                          final news = _filteredNews[index];
                          return _buildNewsCard(news, index, fontSize, screenWidth);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> news, int index, double fontSize, double screenWidth) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category and Source Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(news['category']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    news['category'] ?? 'General',
                    style: TextStyle(
                      fontSize: fontSize - 4,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    news['source'] ?? '',
                    style: TextStyle(
                      fontSize: fontSize - 4,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _getFormattedDate(news),
                  style: TextStyle(fontSize: fontSize - 4, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            InkWell(
              onTap: () => _openArticle(news['url'] ?? ''),
              child: Container(
                width: screenWidth - 64,
                child: Text(
                  news['title'] ?? '',
                  style: TextStyle(
                    fontSize: fontSize + 2,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Container(
              width: screenWidth - 64,
              child: Text(
                news['description'] ?? '',
                style: TextStyle(fontSize: fontSize - 2, color: Colors.grey[700]),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),

            // AI Summary (if available)
            if (_summaries.containsKey(index)) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.blue[700], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'AI Summary',
                          style: TextStyle(fontSize: fontSize - 2, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () => setState(() => _summaries.remove(index)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _summaries[index]!,
                      style: TextStyle(fontSize: fontSize - 2, color: Colors.blue[900]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Translations
            if (_translations.containsKey(index))
              ..._translations[index]!.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.translate, color: Colors.purple[700], size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${_getLanguageName(entry.key)} Translation',
                              style: TextStyle(fontSize: fontSize - 4, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () => _removeTranslation(index, entry.key),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.value,
                          style: TextStyle(fontSize: fontSize - 2, color: Colors.purple[900]),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // AI Summary Button
                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    onPressed: _loadingSummary.contains(index) ? null : () => _generateSummary(index, news),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _loadingSummary.contains(index)
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white))
                        : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, size: 14),
                        const SizedBox(width: 4),
                        Text('Summary', style: TextStyle(fontSize: fontSize - 4)),
                      ],
                    ),
                  ),
                ),

                // Translate Button
                PopupMenuButton<String>(
                  onSelected: (language) => _translateNews(index, news, language),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.translate, color: Colors.purple[700], size: 14),
                        const SizedBox(width: 4),
                        Text('Translate', style: TextStyle(fontSize: fontSize - 4, color: Colors.purple[700])),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'ms', child: Text('Bahasa Melayu')),
                    const PopupMenuItem(value: 'en', child: Text('English')),
                    const PopupMenuItem(value: 'zh', child: Text('中文')),
                    const PopupMenuItem(value: 'ta', child: Text('தமிழ்')),
                  ],
                ),

                // Read More Button
                TextButton(
                  onPressed: () => _openArticle(news['url'] ?? ''),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppTranslations.translate(context, 'read_more'),
                        style: TextStyle(fontSize: fontSize - 4, color: Colors.green[700]),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_forward, size: fontSize - 4, color: Colors.green[700]),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'MyKasih':
        return Colors.green;
      case 'SARA':
        return Colors.orange;
      case 'Food Bank':
        return Colors.blue;
      case 'General':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}