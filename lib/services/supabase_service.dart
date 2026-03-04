import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  static const String _googleApiKey = 'AIzaSyDc0OC9BIMxU_HznavlK2I-1F3JFEF_8fo';

  // 内存缓存相关
  bool _isFetchingNews = false;
  List<Map<String, dynamic>>? _cachedNews;
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  // ==================== 用户认证 ====================

  Future<User?> registerUser({
    required String email,
    required String icNumber,
    required String password,
    required String name,
    String? phoneNumber,
  }) async {

    try {

      // ⭐ 用 IC 生成假的 auth email（只给 Supabase Auth 用）
      final generatedEmail = '$icNumber@mykasih.local';

      print('📧 Registering with auth email: $generatedEmail');

      final response = await _client.auth.signUp(
        email: generatedEmail,
        password: password,
      );

      final user = response.user;

      if (user != null) {

        // ⭐ users table 保存真实 Gmail
        await _client.from('users').insert({
          'id': user.id,
          'email': email, // ⭐ 这里保存 Gmail
          'ic_number': icNumber,
          'name': name,
          'phone_number': phoneNumber,
          'balance': 0,
          'created_at': DateTime.now().toIso8601String(),
        });

        print('✅ User profile created with Gmail');

      }

      return user;

    } catch (e) {

      print('❌ Registration error: $e');
      throw Exception('注册失败: $e');

    }

  }

  Future<User?> loginUser(String icNumber, String password) async {
    try {
      final email = '$icNumber@mykasih.local';
      print('📧 Logging in with email: $email');

      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user;
    } catch (e) {
      print('❌ Login error: $e');
      throw Exception('登录失败: $e');
    }
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  // ==================== 用户资料 ====================

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .single();
    return response;
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _client
        .from('users')
        .update(data)
        .eq('id', userId);
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      final email = user.email!;
      await _client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );

      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw Exception('Password update failed: $e');
    }
  }

  Future<void> updateUserBalance(String userId, double newBalance) async {
    await _client
        .from('users')
        .update({'balance': newBalance})
        .eq('id', userId);
  }

  // ==================== Food Bank ====================

  Future<List<Map<String, dynamic>>> getFoodBanks(double lat, double lng, {String? state}) async {
    print('📍 搜索 Food Bank 位置: $lat, $lng');

    final url = 'https://maps.googleapis.com/maps/api/place/textsearch/json'
        '?query=food+bank|foodbank|bank+makanan|food+aid|bantuan+makanan|charity|food+donation|sumbangan+makanan|pusat+kebajikan|rumah+kebajikan'
        '&location=$lat,$lng'
        '&radius=100000'
        '&key=$_googleApiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;

      print('📊 API 返回 ${results.length} 个结果');

      List<Map<String, dynamic>> foodBanks = [];

      for (var place in results) {
        final name = place['name'] ?? '';
        final address = place['formatted_address'] ?? '';

        final types = place['types'] as List? ?? [];
        if (types.contains('restaurant') ||
            types.contains('cafe') ||
            types.contains('fast_food_restaurant')) {
          continue;
        }

        final placeLat = place['geometry']['location']['lat'];
        final placeLng = place['geometry']['location']['lng'];
        final distance = _calculateDistance(lat, lng, placeLat, placeLng);

        final details = await _getPlaceDetails(place['place_id']);

        final foodBankData = {
          'name': name,
          'address': address,
          'state': _extractState(address),
          'latitude': placeLat,
          'longitude': placeLng,
          'distance': distance,
          'phone': details['phone'] ?? place['formatted_phone_number'] ?? 'No phone',
          'opening_hours': details['hours'] ?? 'Hours not available',
          'is_open': details['isOpen'] ?? false,
          'rating': place['rating'] ?? 0,
          'total_ratings': place['user_ratings_total'] ?? 0,
          'created_at': DateTime.now().toIso8601String(),
        };
        foodBanks.add(foodBankData);

        /// ⭐ 插入 database
        try {
          await _client.from('food_banks').insert(foodBankData);
        } catch (e) {
          print('⚠️ Food bank insert failed or duplicate');
        }
      }

      foodBanks.sort((a, b) {
        final distA = double.parse(a['distance'].toString());
        final distB = double.parse(b['distance'].toString());
        return distA.compareTo(distB);
      });

      return foodBanks;
    } else {
      print('❌ API 请求失败: ${response.statusCode}');
      return [];
    }
  }

  // ==================== Merchants ====================

  Future<List<Map<String, dynamic>>> getMerchants(double lat, double lng, {String? state}) async {

    print('📍 搜索商家位置: $lat, $lng');

    final types = ['supermarket', 'convenience_store', 'pharmacy', 'hypermarket'];

    List<Map<String, dynamic>> allMerchants = [];

    for (var type in types) {

      final url = 'https://maps.googleapis.com/maps/api/place/textsearch/json'
          '?query=$type+in+Malaysia'
          '&location=$lat,$lng'
          '&radius=50000'
          '&key=$_googleApiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {

        final data = json.decode(response.body);
        final results = data['results'] as List;

        for (var place in results) {

          final details = await _getPlaceDetails(place['place_id']);

          final placeLat = place['geometry']['location']['lat'];
          final placeLng = place['geometry']['location']['lng'];

          final distance = _calculateDistance(lat, lng, placeLat, placeLng);

          final merchantData = {
            'name': place['name'] ?? '',
            'address': place['formatted_address'] ?? '',
            'state': _extractState(place['formatted_address'] ?? ''),
            'latitude': placeLat,
            'longitude': placeLng,
            'distance': distance,
            'phone': details['phone'] ?? '',
            'opening_hours': details['hours'] ?? 'Hours not available',
            'is_open': details['isOpen'] ?? false,
            'category': _getCategory(type),
            'rating': place['rating'] ?? 0,
            'total_ratings': place['user_ratings_total'] ?? 0,
            'photos': place['photos'] != null
                ? _getPhotoUrl(place['photos'][0]['photo_reference'])
                : null,
            'created_at': DateTime.now().toIso8601String(),
          };

          allMerchants.add(merchantData);

          /// ⭐ 存入 database
          try {
            await _client.from('merchants').insert(merchantData);
          } catch (e) {
            print('⚠️ merchant already exists or insert failed');
          }

        }
      }
    }

    allMerchants.sort((a, b) {
      final distA = a['distance'] as num;
      final distB = b['distance'] as num;
      return distA.compareTo(distB);
    });

    print('✅ 共找到 ${allMerchants.length} 个商家');

    return allMerchants;
  }

  // ==================== 商品目录 ====================

  Future<List<Map<String, dynamic>>> getAllItems() async {
    try {
      final response = await _client
          .from('items')
          .select()
          .eq('is_available', true);
      return response;
    } catch (e) {
      print('❌ 获取商品失败: $e');
      return [];
    }
  }

  // ==================== AI 对话历史 ====================

  Future<void> saveChatMessage({
    required String userId,
    required String message,
    required String response,
  }) async {
    try {
      await _client.from('chat_history').insert({
        'user_id': userId,
        'message': message,
        'response': response,
        'created_at': DateTime.now().toIso8601String(),
      });
      print('✅ 聊天记录已保存');
    } catch (e) {
      print('❌ 保存聊天记录失败: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getChatHistory(String userId) async {
    try {
      final response = await _client
          .from('chat_history')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      print('❌ 获取聊天记录失败: $e');
      return [];
    }
  }

  Future<void> clearChatHistory(String userId) async {
    try {
      await _client.from('chat_history').delete().eq('user_id', userId);
      print('✅ 已清空聊天记录');
    } catch (e) {
      print('❌ 清空聊天记录失败: $e');
    }
  }

  Future<void> deleteChatMessage(String messageId) async {
    try {
      await _client.from('chat_history').delete().eq('id', messageId);
      print('✅ 聊天记录已删除');
    } catch (e) {
      print('❌ 删除聊天记录失败: $e');
    }
  }

  // ==================== 新闻 - 带数据库缓存 ====================

  // 保存新闻到数据库
  Future<void> saveNewsToDatabase(List<Map<String, dynamic>> newsList) async {
    try {
      // 先清空旧新闻 - 使用正确的 UUID 比较
      await _client.from('news_cache').delete().neq('id', '00000000-0000-0000-0000-000000000000');

      // 批量插入新新闻
      for (var news in newsList) {
        await _client.from('news_cache').insert({
          'title': news['title'],
          'description': news['description'],
          'source': news['source'],
          'url': news['url'],
          'category': news['category'],
          'published_at': news['published_at'],
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      print('✅ 已保存 ${newsList.length} 条新闻到数据库');
    } catch (e) {
      print('❌ 保存新闻到数据库失败: $e');
    }
  }

  // 从数据库获取新闻
  Future<List<Map<String, dynamic>>> getNewsFromDatabase() async {
    try {
      final response = await _client
          .from('news_cache')
          .select()
          .order('published_at', ascending: false)
          .limit(30);

      print('📰 从数据库获取到 ${response.length} 条新闻');
      return response;
    } catch (e) {
      print('❌ 从数据库获取新闻失败: $e');
      return [];
    }
  }

  // 主方法：获取新闻（先查数据库，没有再抓取）
  Future<List<Map<String, dynamic>>> getNews({bool forceRefresh = false}) async {
    // 1. 先检查内存缓存（如果不需要强制刷新）
    if (!forceRefresh &&
        _cachedNews != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      print('📰 使用内存缓存新闻，共 ${_cachedNews!.length} 条');
      return _cachedNews!;
    }

    // 2. 如果不是强制刷新，尝试从数据库获取
    if (!forceRefresh) {
      try {
        final dbNews = await getNewsFromDatabase();
        if (dbNews.isNotEmpty) {
          print('📰 使用数据库缓存新闻，共 ${dbNews.length} 条');
          // 更新内存缓存
          _cachedNews = dbNews;
          _lastFetchTime = DateTime.now();
          return dbNews;
        }
      } catch (e) {
        print('❌ 数据库获取失败，将抓取新新闻: $e');
      }
    }

    // 3. 如果已经在抓取中，等待并返回缓存
    if (_isFetchingNews) {
      print('⏳ 新闻正在抓取中，等待...');
      int waitCount = 0;
      while (_isFetchingNews && waitCount < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
        if (_cachedNews != null) {
          print('📰 等待完成，返回缓存 (${_cachedNews!.length} 条)');
          return _cachedNews!;
        }
      }
    }

    _isFetchingNews = true;

    try {
      print('🌐 从指定的5个来源抓取新闻');
      final newsList = await _fetchFromSpecifiedSources();

      if (newsList.isNotEmpty) {
        // 按日期排序
        newsList.sort((a, b) {
          try {
            final dateA = DateTime.parse(a['published_at']);
            final dateB = DateTime.parse(b['published_at']);
            return dateB.compareTo(dateA);
          } catch (e) {
            return 0;
          }
        });

        // 打印各分类统计
        print('📊 最终新闻分类统计:');
        int mykasihCount = newsList.where((n) => n['category'] == 'MyKasih').length;
        int saraCount = newsList.where((n) => n['category'] == 'SARA').length;
        int generalCount = newsList.where((n) => n['category'] == 'General').length;
        int foodBankCount = newsList.where((n) => n['category'] == 'Food Bank').length;
        print('   MyKasih: $mykasihCount 条');
        print('   SARA: $saraCount 条');
        print('   General: $generalCount 条');
        print('   Food Bank: $foodBankCount 条');

        final latestNews = newsList.take(30).toList();

        // 保存到数据库
        await saveNewsToDatabase(latestNews);

        // 更新内存缓存
        _cachedNews = latestNews;
        _lastFetchTime = DateTime.now();

        print('✅ 获取到 ${latestNews.length} 条最新新闻并已缓存到数据库');
        return latestNews;
      }

      return newsList;
    } catch (e) {
      print('❌ 获取新闻失败: $e');
      // 如果抓取失败，尝试从数据库获取
      try {
        final dbNews = await getNewsFromDatabase();
        if (dbNews.isNotEmpty) {
          print('📰 抓取失败，使用数据库缓存');
          return dbNews;
        }
      } catch (dbError) {
        print('❌ 数据库也失败: $dbError');
      }

      if (_cachedNews != null) {
        return _cachedNews!;
      }
      return _getMockNews();
    } finally {
      _isFetchingNews = false;
    }
  }

  // 解析 RSS 项目
  List<Map<String, String>> _parseRSSItems(String xml) {
    final items = <Map<String, String>>[];

    try {
      final itemRegex = RegExp(r'<item>(.*?)</item>', dotAll: true);
      final itemMatches = itemRegex.allMatches(xml);

      for (var match in itemMatches) {
        final itemXml = match.group(1) ?? '';

        String getTagContent(String tag) {
          final regex = RegExp('<$tag>(.*?)</$tag>', dotAll: true);
          final tagMatch = regex.firstMatch(itemXml);
          return tagMatch?.group(1)?.trim() ?? '';
        }

        items.add({
          'title': getTagContent('title'),
          'description': getTagContent('description'),
          'link': getTagContent('link'),
          'pubDate': getTagContent('pubDate'),
        });
      }
    } catch (e) {
      print('❌ 解析 RSS 失败: $e');
    }

    return items;
  }

  // 只从你指定的5个来源抓取
  Future<List<Map<String, dynamic>>> _fetchFromSpecifiedSources() async {
    print('🚀 开始从5个指定来源抓取新闻');
    List<Map<String, dynamic>> allNews = [];

    // 你指定的5个来源
    final List<Map<String, String>> newsSources = [
      {
        'name': 'MyKasih Official',
        'url': 'https://news.google.com/rss/search?q=site:mykasih.gov.my+sara&hl=ms-MY&gl=MY&ceid=MY:ms',
        'category': 'MyKasih',
      },
      {
        'name': 'MOF Official',
        'url': 'https://news.google.com/rss/search?q=site:mof.gov.my+sara&hl=ms-MY&gl=MY&ceid=MY:ms',
        'category': 'SARA',
      },
      {
        'name': 'Government Aid News',
        'url': 'https://news.google.com/rss/search?q=mykasih+OR+sara+OR+bantuan+kerajaan&hl=ms-MY&gl=MY&ceid=MY:ms',
        'category': 'General',
      },
      {
        'name': 'BERNAMA Aid News',
        'url': 'https://news.google.com/rss/search?q=bantuan+kerajaan+OR+sara+OR+mykasih&hl=ms-MY&gl=MY&ceid=MY:ms',
        'category': 'General',
      },
      {
        'name': 'Food Bank News',
        'url': 'https://news.google.com/rss/search?q=food+bank+malaysia+OR+bank+makanan&hl=ms-MY&gl=MY&ceid=MY:ms',
        'category': 'Food Bank',
      },
    ];

    for (var source in newsSources) {
      try {
        print('📡 抓取: ${source['name']}');
        print('🔗 URL: ${source['url']}');

        final response = await http.get(
          Uri.parse(source['url']!),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        );

        if (response.statusCode == 200) {
          final items = _parseRSSItems(response.body);
          int sourceCount = 0;

          for (var item in items) {
            final title = item['title'] ?? '';
            final description = item['description'] ?? '';
            final link = item['link'] ?? '';
            final pubDateStr = item['pubDate'] ?? '';

            if (title.isEmpty) continue;

            // 解析日期
            DateTime? pubDate = _parseRSSDate(pubDateStr);
            if (pubDate == null) pubDate = DateTime.now();

            // 确保新闻与 MyKasih/SARA 相关
            if (!_isRelevantNews(title, description)) {
              continue;
            }

            final cleanTitle = _cleanHtml(title);
            final cleanDesc = _cleanHtml(description.length > 200
                ? description.substring(0, 200) + '...'
                : description);

            allNews.add({
              'title': cleanTitle,
              'description': cleanDesc,
              'source': source['name']!,
              'url': link,
              'category': source['category']!,
              'published_at': pubDate.toIso8601String(),
            });
            sourceCount++;
          }
          print('✅ ${source['name']} 获取到 $sourceCount 条新闻');
        } else {
          print('❌ HTTP ${response.statusCode}: ${source['name']}');
        }
      } catch (e) {
        print('❌ 抓取失败: ${source['name']}, $e');
      }

      await Future.delayed(const Duration(milliseconds: 500));
    }

    print('📊 各来源原始新闻数量:');
    for (var source in newsSources) {
      final sourceNews = allNews.where((n) => n['source'] == source['name']).length;
      print('   ${source['name']}: $sourceNews 条');
    }

    print('📊 原始数据按分类统计:');
    int totalMyKasih = allNews.where((n) => n['category'] == 'MyKasih').length;
    int totalSARA = allNews.where((n) => n['category'] == 'SARA').length;
    int totalGeneral = allNews.where((n) => n['category'] == 'General').length;
    int totalFoodBank = allNews.where((n) => n['category'] == 'Food Bank').length;
    print('   MyKasih: $totalMyKasih 条');
    print('   SARA: $totalSARA 条');
    print('   General: $totalGeneral 条');
    print('   Food Bank: $totalFoodBank 条');

    return allNews;
  }

  // 检查新闻相关性 - 非常宽松的过滤
  bool _isRelevantNews(String title, String description) {
    final lowerTitle = title.toLowerCase();
    final lowerDesc = description.toLowerCase();

    // 非常宽松的关键词列表
    final keywords = [
      'mykasih', 'sara', 'sumbangan', 'bantuan', 'rahmah',
      'ekasih', 'food', 'bank', 'makanan', 'kerajaan',
      'kewangan', 'mof', 'kementerian', '2025', '2026', 'belanjawan',
      'tunai', 'aid', 'government', 'malaysia', 'bendahari',
      'perdana', 'menteri', 'pm', 'anwar', 'budget', 'subsidi',
      'kebajikan', 'zakat', 'bencana', 'banjir', 'miskin',
      'rakyat', 'prihatin', 'insentif', 'fasa', 'bantuan',
      'fasa 1', 'fasa 2', 'fasa 3', 'fasa 4', 'fasa 5',
      'bantuan', 'wang', 'duit', 'rm', 'ringgit', 'mykad',
      'kad', 'ic', 'penerima', 'manfaat', 'program'
    ];

    final isRelevant = keywords.any((keyword) =>
    lowerTitle.contains(keyword) || lowerDesc.contains(keyword));

    final isFoodBankRelated = (lowerTitle.contains('food') && lowerTitle.contains('bank')) ||
        (lowerDesc.contains('food') && lowerDesc.contains('bank')) ||
        lowerTitle.contains('bank makanan') ||
        lowerDesc.contains('bank makanan');

    final isSaraRelated = lowerTitle.contains('sara') ||
        lowerDesc.contains('sara') ||
        lowerTitle.contains('sumbangan asas') ||
        lowerDesc.contains('sumbangan asas');

    final isMyKasihRelated = lowerTitle.contains('mykasih') ||
        lowerDesc.contains('mykasih');

    final shouldKeep = isRelevant || isFoodBankRelated || isSaraRelated || isMyKasihRelated;

    if (!shouldKeep) {
      print('❌ 过滤掉: $lowerTitle');
    } else {
      print('✅ 保留: $lowerTitle');
    }

    return shouldKeep;
  }

  // 解析 RSS 日期格式 - 修复版本
  DateTime? _parseRSSDate(String dateStr) {
    try {
      // 尝试直接解析 ISO 格式
      return DateTime.parse(dateStr);
    } catch (e) {
      try {
        // 处理 RFC 822 格式 (例如: "Wed, 04 Mar 2026 08:00:00 GMT")
        // 移除逗号和时区信息
        String cleaned = dateStr.replaceAll(',', '');

        // 处理常见的时区缩写
        cleaned = cleaned
            .replaceAll(' GMT', '')
            .replaceAll(' UTC', '')
            .replaceAll(' PST', '')
            .replaceAll(' PDT', '')
            .replaceAll(' EST', '')
            .replaceAll(' EDT', '');

        // 尝试解析格式: "Wed 04 Mar 2026 08:00:00"
        final parts = cleaned.split(' ');
        if (parts.length >= 5) {
          // 跳过星期几
          int startIndex = 0;
          if (parts[0].length == 3) startIndex = 1; // 如果是星期几，跳过

          final day = int.parse(parts[startIndex]);
          final month = _getMonthNumber(parts[startIndex + 1]);
          final year = int.parse(parts[startIndex + 2]);
          final timeParts = parts[startIndex + 3].split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;

          return DateTime(year, month, day, hour, minute, second);
        }
      } catch (e) {
        print('❌ 日期解析失败: $dateStr, 错误: $e');
      }
    }
    // 如果都失败，返回一个过去的日期，这样旧新闻就不会排在前面
    return DateTime(2000, 1, 1);
  }

  // 辅助方法：将月份名称转换为数字
  int _getMonthNumber(String monthName) {
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
    };
    return months[monthName] ?? 1;
  }

  // 获取模拟新闻数据
  List<Map<String, dynamic>> _getMockNews() {
    final now = DateTime.now();
    return [
      {
        'title': 'SARA 2026: Permohonan Dibuka Mulai 1 Mac',
        'description': 'Kementerian Kewangan mengumumkan program Sumbangan Asas Rahmah (SARA) 2026 akan dibuka mulai 1 Mac ini. Penerima yang layak akan menerima bayaran RM300 sebulan.',
        'source': 'MyKasih Official',
        'url': 'https://mykasih.gov.my',
        'category': 'SARA',
        'published_at': now.toIso8601String(),
      },
      {
        'title': 'MyKasih: 2 Juta Penerima Manfaat SARA 2026',
        'description': 'Seramai 2 juta penerima akan mendapat manfaat daripada program SARA 2026 yang bernilai RM7.2 bilion.',
        'source': 'BERNAMA',
        'url': 'https://bernama.com',
        'category': 'MyKasih',
        'published_at': now.subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'title': 'Food Bank Malaysia: 50 Cawangan Baharu Dibuka',
        'description': 'Program Food Bank Malaysia akan membuka 50 cawangan baharu di seluruh negara bagi membantu golongan memerlukan.',
        'source': 'Food Bank News',
        'url': 'https://foodbankmalaysia.org',
        'category': 'Food Bank',
        'published_at': now.subtract(const Duration(days: 2)).toIso8601String(),
      },
    ];
  }

  // ==================== 辅助函数 ====================

  String _cleanHtml(String html) {
    String text = html.replaceAll(RegExp(r'<[^>]*>'), '');
    text = text.replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");
    return text.trim();
  }

  Future<Map<String, dynamic>> _getPlaceDetails(String placeId) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=$placeId'
          '&fields=name,formatted_phone_number,opening_hours,website'
          '&key=$_googleApiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['result'] ?? {};

        String hours = 'Hours not available';
        bool isOpen = false;

        if (result['opening_hours'] != null) {
          final weekdayText = result['opening_hours']['weekday_text'] as List?;
          if (weekdayText != null && weekdayText.isNotEmpty) {
            hours = weekdayText.join('\n');
          }
          isOpen = result['opening_hours']['open_now'] ?? false;
        }

        return {
          'phone': result['formatted_phone_number'] ?? '',
          'hours': hours,
          'isOpen': isOpen,
        };
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  String _formatOpeningHours(Map<String, dynamic> place) {
    if (place['opening_hours'] != null) {
      final hours = place['opening_hours'];
      if (hours['weekday_text'] != null) {
        return (hours['weekday_text'] as List).join('\n');
      }
    }
    return 'Hours not available';
  }

  String _getCategory(String type) {
    switch (type) {
      case 'supermarket': return 'Supermarket';
      case 'convenience_store': return 'Convenience Store';
      case 'pharmacy': return 'Pharmacy';
      case 'hypermarket': return 'Hypermarket';
      default: return 'Store';
    }
  }

  String _extractState(String address) {
    if (address.contains('Kuala Lumpur')) return 'Kuala Lumpur';
    if (address.contains('Selangor')) return 'Selangor';
    if (address.contains('Johor')) return 'Johor';
    if (address.contains('Penang')) return 'Penang';
    if (address.contains('Pulau Pinang')) return 'Penang';
    if (address.contains('Melaka')) return 'Melaka';
    if (address.contains('Malacca')) return 'Melaka';
    if (address.contains('Perak')) return 'Perak';
    if (address.contains('Pahang')) return 'Pahang';
    if (address.contains('Kelantan')) return 'Kelantan';
    if (address.contains('Terengganu')) return 'Terengganu';
    if (address.contains('Kedah')) return 'Kedah';
    if (address.contains('Perlis')) return 'Perlis';
    if (address.contains('Negeri Sembilan')) return 'Negeri Sembilan';
    if (address.contains('Sabah')) return 'Sabah';
    if (address.contains('Sarawak')) return 'Sarawak';
    return 'Malaysia';
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    double dLat = _deg2rad(lat2 - lat1);
    double dLon = _deg2rad(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = R * c;
    return double.parse(distance.toStringAsFixed(1));
  }

  double _deg2rad(double deg) {
    return deg * (pi / 180);
  }

  String _getPhotoUrl(String photoReference) {
    return 'https://maps.googleapis.com/maps/api/place/photo'
        '?maxwidth=400'
        '&photo_reference=$photoReference'
        '&key=$_googleApiKey';
  }
}