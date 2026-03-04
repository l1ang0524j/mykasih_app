import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_assistant_screen.dart';
import 'government_news_screen.dart';
import 'foodbank_map_screen.dart';
import 'guides_screen.dart';
import 'settings_screen.dart';
import 'merchants_screen.dart';
import 'barcode_scanner_screen.dart';
import 'items_catalogue_screen.dart';
import 'profile_screen.dart';
import '../widgets/header_widget.dart';
import '../widgets/feature_card.dart';
import '../utils/font_size_listener.dart';
import '../utils/font_size_manager.dart';
import '../services/supabase_service.dart';
import '../l10n/app_translations.dart';
import '../providers/language_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeContentScreen(),
    const GuidesScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
            child: _screens[_currentIndex],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            selectedItemColor: const Color(0xFF2E7D32),
            unselectedItemColor: Colors.grey[600],
            showUnselectedLabels: true,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home),
                label: AppTranslations.translate(context, 'home'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.menu_book),
                label: AppTranslations.translate(context, 'guides'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.settings),
                label: AppTranslations.translate(context, 'settings'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HomeContentScreen extends StatefulWidget {
  const HomeContentScreen({super.key});

  @override
  State<HomeContentScreen> createState() => _HomeContentScreenState();
}

class _HomeContentScreenState extends State<HomeContentScreen> {
  double _fontSize = FontSizeManager.normal;
  double _userBalance = 0.0;
  String _userName = '';
  Map<String, dynamic>? _latestNews;
  bool _loadingNews = true;

  @override
  void initState() {
    super.initState();
    _loadFontSize();
    _loadUserData();
    _loadLatestNews();
  }

  Future<void> _loadFontSize() async {
    final size = await FontSizeManager.getFontSize();
    if (mounted) {
      setState(() {
        _fontSize = size;
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId != null) {
        final userData = await SupabaseService().getUserProfile(userId);
        if (userData != null && mounted) {
          setState(() {
            _userBalance = (userData['balance'] as num?)?.toDouble() ?? 0.0;
            _userName = userData['name'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadLatestNews() async {
    try {
      final news = await SupabaseService().getNews();
      if (news.isNotEmpty && mounted) {
        setState(() {
          _latestNews = news.first;
          _loadingNews = false;
        });
      } else {
        setState(() {
          _loadingNews = false;
        });
      }
    } catch (e) {
      print('Error loading news: $e');
      setState(() {
        _loadingNews = false;
      });
    }
  }

  void _openGovernmentNews() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GovernmentNewsScreen()),
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final weekdays = ['Isnin', 'Selasa', 'Rabu', 'Khamis', 'Jumaat', 'Sabtu', 'Ahad'];
    final months = ['Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun', 'Jul', 'Ogos', 'Sep', 'Okt', 'Nov', 'Dis'];

    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return FontSizeListener(
          child: const SizedBox(),
          builder: (context, fontSize) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  // Custom Header with Balance
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[700]!, Colors.green[900]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getCurrentTime(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _getCurrentDate(),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet,
                                        color: Colors.white,
                                        size: fontSize,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'RM ${_userBalance.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: fontSize,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _navigateToProfile,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Center(
                          child: Column(
                            children: [
                              Text(
                                'SUMBANGAN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              Text(
                                'ASAS RAHMAH',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'MyKasih',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'PENERAJU',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'RAKAN KERJASAMA',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Welcome Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          _userName.isEmpty
                              ? AppTranslations.translate(context, 'welcome')
                              : '${AppTranslations.translate(context, 'welcome')}, $_userName!',
                          style: TextStyle(
                            fontSize: fontSize + 4,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Latest News Card
                  if (_loadingNews)
                    const Center(child: CircularProgressIndicator())
                  else if (_latestNews != null)
                    InkWell(
                      onTap: _openGovernmentNews,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green[700]!, Colors.green[900]!],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    AppTranslations.translate(context, 'latest_news').toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: fontSize - 4,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _latestNews!['source'] ?? '',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: fontSize - 4,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _latestNews!['title'] ?? '',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: fontSize + 2,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _latestNews!['description'] ?? '',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: fontSize - 2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        AppTranslations.translate(context, 'read_more'),
                                        style: TextStyle(
                                          color: Colors.green[800],
                                          fontSize: fontSize - 2,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward,
                                        color: Colors.green[800],
                                        size: fontSize - 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // AI Features Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      AppTranslations.translate(context, 'ai_features'),
                      style: TextStyle(
                        fontSize: fontSize + 6,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),

                  // AI Features Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.0,
                    padding: const EdgeInsets.all(16),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      FeatureCard(
                        icon: Icons.smart_toy,
                        title: AppTranslations.translate(context, 'ai_assistant'),
                        subtitle: AppTranslations.translate(context, 'ai_assistant_subtitle'),
                        color: Colors.blue[50]!,
                        iconColor: Colors.blue,
                        fontSize: fontSize,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AIAssistantScreen(),
                            ),
                          );
                        },
                      ),
                      FeatureCard(
                        icon: Icons.newspaper,
                        title: AppTranslations.translate(context, 'government_news'),
                        subtitle: AppTranslations.translate(context, 'government_news_subtitle'),
                        color: Colors.purple[50]!,
                        iconColor: Colors.purple,
                        fontSize: fontSize,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GovernmentNewsScreen(),
                            ),
                          );
                        },
                      ),
                      FeatureCard(
                        icon: Icons.map,
                        title: AppTranslations.translate(context, 'food_bank_map'),
                        subtitle: AppTranslations.translate(context, 'food_bank_map_subtitle'),
                        color: Colors.orange[50]!,
                        iconColor: Colors.orange,
                        fontSize: fontSize,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FoodBankMapScreen(),
                            ),
                          );
                        },
                      ),
                      FeatureCard(
                        icon: Icons.store,
                        title: AppTranslations.translate(context, 'merchants'),
                        subtitle: AppTranslations.translate(context, 'merchants_subtitle'),
                        color: Colors.green[50]!,
                        iconColor: Colors.green,
                        fontSize: fontSize,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MerchantsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // Quick Actions Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      AppTranslations.translate(context, 'quick_actions'),
                      style: TextStyle(
                        fontSize: fontSize + 6,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),

                  // Quick Actions List
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildActionRow(
                          context,
                          Icons.qr_code_scanner,
                          AppTranslations.translate(context, 'scan_barcode'),
                          AppTranslations.translate(context, 'scan_barcode_subtitle'),
                          Colors.green,
                          fontSize,
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BarcodeScannerScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 24),
                        _buildActionRow(
                          context,
                          Icons.store_mall_directory,
                          AppTranslations.translate(context, 'find_merchants'),
                          AppTranslations.translate(context, 'find_merchants_subtitle'),
                          Colors.blue,
                          fontSize,
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MerchantsScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 24),
                        _buildActionRow(
                          context,
                          Icons.shopping_cart,
                          AppTranslations.translate(context, 'check_items'),
                          AppTranslations.translate(context, 'check_items_subtitle'),
                          Colors.orange,
                          fontSize,
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ItemsCatalogueScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 24),
                        _buildActionRow(
                          context,
                          Icons.menu_book,
                          AppTranslations.translate(context, 'purchasing_guide'),
                          AppTranslations.translate(context, 'purchasing_guide_subtitle'),
                          Colors.purple,
                          fontSize,
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const GuidesScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Chat with us button
                  Container(
                    margin: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AIAssistantScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat),
                      label: Text(
                        AppTranslations.translate(context, 'chat_with_us'),
                        style: TextStyle(fontSize: fontSize),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionRow(
      BuildContext context,
      IconData icon,
      String title,
      String subtitle,
      Color color,
      double fontSize,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: fontSize - 4,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}