import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/font_size_listener.dart';
import '../utils/font_size_manager.dart';
import '../providers/font_size_provider.dart';
import '../providers/language_provider.dart';
import '../l10n/app_translations.dart';
import 'privacy_security_screen.dart';
import '../services/notification_service.dart';
import 'test_notification_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _currentFontSize = FontSizeManager.normal;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentFontSize = prefs.getDouble('font_size') ?? FontSizeManager.normal;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontSize: _currentFontSize),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FontSizeListener(
      child: const SizedBox(),
      builder: (context, fontSize) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              AppTranslations.translate(context, 'settings'),
              style: TextStyle(fontSize: fontSize + 4),
            ),
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
          ),
          body: ListView(
            children: [
              // App Settings Section
              _buildSettingsSection(
                AppTranslations.translate(context, 'app_settings'),
                fontSize,
                [
                  _buildLanguageItem(fontSize),
                  _buildSwitchItem(
                    Icons.notifications,
                    AppTranslations.translate(context, 'notifications'),
                    AppTranslations.translate(context, 'notifications_subtitle'),
                    _notificationsEnabled,
                    fontSize,
                        (value) {
                      setState(() {
                        _notificationsEnabled = value;
                        _saveSetting('notifications_enabled', value);
                      });
                      _showSnackBar('${AppTranslations.translate(context, 'notifications')} ${value ?
                      AppTranslations.translate(context, 'enabled') :
                      AppTranslations.translate(context, 'disabled')}');
                    },
                  ),
                ],
              ),

              // Display Settings Section
              _buildSettingsSection(
                AppTranslations.translate(context, 'display_settings'),
                fontSize,
                [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.text_fields, color: Colors.blue),
                    ),
                    title: Text(
                      AppTranslations.translate(context, 'font_size'),
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      AppTranslations.translate(context, 'font_size_subtitle'),
                      style: TextStyle(
                        fontSize: fontSize - 2,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: DropdownButton<double>(
                        value: _currentFontSize,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down),
                        items: [
                          DropdownMenuItem(
                            value: FontSizeManager.small,
                            child: Text(
                              AppTranslations.translate(context, 'small'),
                              style: TextStyle(fontSize: fontSize),
                            ),
                          ),
                          DropdownMenuItem(
                            value: FontSizeManager.normal,
                            child: Text(
                              AppTranslations.translate(context, 'normal'),
                              style: TextStyle(fontSize: fontSize),
                            ),
                          ),
                          DropdownMenuItem(
                            value: FontSizeManager.large,
                            child: Text(
                              AppTranslations.translate(context, 'large'),
                              style: TextStyle(fontSize: fontSize),
                            ),
                          ),
                          DropdownMenuItem(
                            value: FontSizeManager.extraLarge,
                            child: Text(
                              AppTranslations.translate(context, 'extra_large'),
                              style: TextStyle(fontSize: fontSize),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            Provider.of<FontSizeProvider>(context, listen: false).updateFontSize(value);
                            setState(() {
                              _currentFontSize = value;
                            });
                            _showSnackBar('${AppTranslations.translate(context, 'font_size_updated')} ${_getFontSizeLabel(value)}');
                          }
                        },
                      ),
                    ),
                  ),
                  // Preview of font size
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTranslations.translate(context, 'preview'),
                            style: TextStyle(
                              fontSize: _currentFontSize - 2,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppTranslations.translate(context, 'preview_text'),
                            style: TextStyle(fontSize: _currentFontSize),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Notifications Test Section
              _buildSettingsSection(
                AppTranslations.translate(context, 'notifications_section'),
                fontSize,
                [
                  _buildSettingsItem(
                    Icons.notifications_active,
                    AppTranslations.translate(context, 'test_notifications'),
                    AppTranslations.translate(context, 'test_notifications_subtitle'),
                    fontSize,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TestNotificationScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    Icons.notifications_off,
                    AppTranslations.translate(context, 'clear_all'),
                    AppTranslations.translate(context, 'clear_all_subtitle'),
                    fontSize,
                        () async {
                      await NotificationService().cancelAll();
                      _showSnackBar(AppTranslations.translate(context, 'all_cleared'));
                    },
                  ),
                ],
              ),

              // Account Settings
              _buildSettingsSection(
                AppTranslations.translate(context, 'account'),
                fontSize,
                [
                  _buildSettingsItem(
                    Icons.person,
                    AppTranslations.translate(context, 'profile_info'),
                    AppTranslations.translate(context, 'profile_info_subtitle'),
                    fontSize,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    Icons.security,
                    AppTranslations.translate(context, 'privacy_security'),
                    AppTranslations.translate(context, 'privacy_security_subtitle'),
                    fontSize,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacySecurityScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              // About & Legal
              _buildSettingsSection(
                AppTranslations.translate(context, 'about_legal'),
                fontSize,
                [
                  _buildSettingsItem(
                    Icons.info,
                    AppTranslations.translate(context, 'about_us'),
                    AppTranslations.translate(context, 'about_us_subtitle'),
                    fontSize,
                        () {
                      _showAboutDialog(context, fontSize);
                    },
                  ),
                  _buildSettingsItem(
                    Icons.privacy_tip,
                    AppTranslations.translate(context, 'privacy_notice'),
                    AppTranslations.translate(context, 'privacy_notice_subtitle'),
                    fontSize,
                        () {
                      _showPrivacyDialog(fontSize);
                    },
                  ),
                  _buildSettingsItem(
                    Icons.description,
                    AppTranslations.translate(context, 'terms_access'),
                    AppTranslations.translate(context, 'terms_access_subtitle'),
                    fontSize,
                        () {
                      _showTermsDialog(fontSize);
                    },
                  ),
                  _buildSettingsItem(
                    Icons.contact_page,
                    AppTranslations.translate(context, 'contact_us'),
                    AppTranslations.translate(context, 'contact_us_subtitle'),
                    fontSize,
                        () {
                      _showContactDialog(fontSize);
                    },
                  ),
                  _buildSettingsItem(
                    Icons.warning,
                    AppTranslations.translate(context, 'disclaimer'),
                    AppTranslations.translate(context, 'disclaimer_subtitle'),
                    fontSize,
                        () {
                      _showDisclaimerDialog(fontSize);
                    },
                  ),
                ],
              ),

              // Exit Button
              Container(
                margin: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {
                    _showExitConfirmation(context, fontSize);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    foregroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    AppTranslations.translate(context, 'exit'),
                    style: TextStyle(fontSize: fontSize),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageItem(double fontSize) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.language, color: Colors.blue),
      ),
      title: Text(
        AppTranslations.translate(context, 'language'),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        languageProvider.getCurrentLanguageName(),
        style: TextStyle(
          fontSize: fontSize - 2,
          color: Colors.grey[600],
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () => _showLanguageDialog(context, fontSize),
    );
  }

  String _getFontSizeLabel(double size) {
    if (size == FontSizeManager.small) return AppTranslations.translate(context, 'small');
    if (size == FontSizeManager.normal) return AppTranslations.translate(context, 'normal');
    if (size == FontSizeManager.large) return AppTranslations.translate(context, 'large');
    if (size == FontSizeManager.extraLarge) return AppTranslations.translate(context, 'extra_large');
    return AppTranslations.translate(context, 'normal');
  }

  Widget _buildSettingsSection(String title, double fontSize, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: fontSize - 2,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 1,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
      IconData icon,
      String title,
      String subtitle,
      double fontSize,
      VoidCallback onTap,
      ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.grey[700], size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: fontSize - 2,
          color: Colors.grey[600],
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSwitchItem(
      IconData icon,
      String title,
      String subtitle,
      bool value,
      double fontSize,
      Function(bool) onChanged,
      ) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.grey[700], size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: fontSize - 2,
          color: Colors.grey[600],
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF2E7D32),
    );
  }

  void _showLanguageDialog(BuildContext context, double fontSize) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    // 使用 StatefulBuilder 来让弹窗内的状态可以更新
    showDialog(
      context: context,
      builder: (context) {
        String selectedLanguage = languageProvider.locale.languageCode;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                AppTranslations.translate(context, 'language'),
                style: TextStyle(fontSize: fontSize + 2, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<String>(
                      title: Text('Bahasa Melayu', style: TextStyle(fontSize: fontSize)),
                      value: 'ms',
                      groupValue: selectedLanguage,
                      onChanged: (value) {
                        setState(() {
                          selectedLanguage = value!;
                        });
                      },
                      activeColor: const Color(0xFF2E7D32),
                    ),
                    RadioListTile<String>(
                      title: Text('English', style: TextStyle(fontSize: fontSize)),
                      value: 'en',
                      groupValue: selectedLanguage,
                      onChanged: (value) {
                        setState(() {
                          selectedLanguage = value!;
                        });
                      },
                      activeColor: const Color(0xFF2E7D32),
                    ),
                    RadioListTile<String>(
                      title: Text('中文', style: TextStyle(fontSize: fontSize)),
                      value: 'zh',
                      groupValue: selectedLanguage,
                      onChanged: (value) {
                        setState(() {
                          selectedLanguage = value!;
                        });
                      },
                      activeColor: const Color(0xFF2E7D32),
                    ),
                    RadioListTile<String>(
                      title: Text('தமிழ்', style: TextStyle(fontSize: fontSize)),
                      value: 'ta',
                      groupValue: selectedLanguage,
                      onChanged: (value) {
                        setState(() {
                          selectedLanguage = value!;
                        });
                      },
                      activeColor: const Color(0xFF2E7D32),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    AppTranslations.translate(context, 'cancel'),
                    style: TextStyle(fontSize: fontSize),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    languageProvider.setLanguage(selectedLanguage);
                    Navigator.pop(context);
                    _showSnackBar(AppTranslations.translate(context, 'language_changed'));
                  },
                  child: Text(
                    AppTranslations.translate(context, 'save'),
                    style: TextStyle(fontSize: fontSize),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPrivacyDialog(double fontSize) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppTranslations.translate(context, 'privacy_notice'),
          style: TextStyle(fontSize: fontSize + 2, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppTranslations.translate(context, 'data_collection'),
                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                AppTranslations.translate(context, 'data_collection_content'),
                style: TextStyle(fontSize: fontSize - 2),
              ),
              const SizedBox(height: 12),
              Text(
                AppTranslations.translate(context, 'data_usage'),
                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                AppTranslations.translate(context, 'data_usage_content'),
                style: TextStyle(fontSize: fontSize - 2),
              ),
              const SizedBox(height: 12),
              Text(
                AppTranslations.translate(context, 'data_protection'),
                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                AppTranslations.translate(context, 'data_protection_content'),
                style: TextStyle(fontSize: fontSize - 2),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppTranslations.translate(context, 'close'),
              style: TextStyle(fontSize: fontSize),
            ),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(double fontSize) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppTranslations.translate(context, 'terms_access'),
          style: TextStyle(fontSize: fontSize + 2, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. ${AppTranslations.translate(context, 'eligibility')}',
                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
              ),
              Text(
                AppTranslations.translate(context, 'eligibility_content_short'),
                style: TextStyle(fontSize: fontSize - 2),
              ),
              const SizedBox(height: 8),
              Text(
                '2. ${AppTranslations.translate(context, 'usage')}',
                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
              ),
              Text(
                AppTranslations.translate(context, 'usage_content'),
                style: TextStyle(fontSize: fontSize - 2),
              ),
              const SizedBox(height: 8),
              Text(
                '3. ${AppTranslations.translate(context, 'accuracy')}',
                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
              ),
              Text(
                AppTranslations.translate(context, 'accuracy_content'),
                style: TextStyle(fontSize: fontSize - 2),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppTranslations.translate(context, 'close'),
              style: TextStyle(fontSize: fontSize),
            ),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(double fontSize) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppTranslations.translate(context, 'contact_us'),
          style: TextStyle(fontSize: fontSize + 2, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: Text(
                AppTranslations.translate(context, 'hotline'),
                style: TextStyle(fontSize: fontSize - 2),
              ),
              subtitle: Text('1-800-88-1234', style: TextStyle(fontSize: fontSize)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.green),
              title: Text(
                AppTranslations.translate(context, 'email'),
                style: TextStyle(fontSize: fontSize - 2),
              ),
              subtitle: Text('support@mykasih.gov.my', style: TextStyle(fontSize: fontSize)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.green),
              title: Text(
                AppTranslations.translate(context, 'address'),
                style: TextStyle(fontSize: fontSize - 2),
              ),
              subtitle: Text(
                AppTranslations.translate(context, 'address_value'),
                style: TextStyle(fontSize: fontSize),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppTranslations.translate(context, 'close'),
              style: TextStyle(fontSize: fontSize),
            ),
          ),
        ],
      ),
    );
  }

  void _showDisclaimerDialog(double fontSize) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppTranslations.translate(context, 'disclaimer'),
          style: TextStyle(fontSize: fontSize + 2, fontWeight: FontWeight.bold),
        ),
        content: Text(
          AppTranslations.translate(context, 'disclaimer_content'),
          style: TextStyle(fontSize: fontSize),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppTranslations.translate(context, 'close'),
              style: TextStyle(fontSize: fontSize),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context, double fontSize) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppTranslations.translate(context, 'about_us'),
          style: TextStyle(fontSize: fontSize + 2, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SUMBANGAN ASAS RAHMAH',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${AppTranslations.translate(context, 'version')}: 2.0.0',
                style: TextStyle(
                  fontSize: fontSize - 2,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppTranslations.translate(context, 'about_content'),
                style: TextStyle(fontSize: fontSize - 2),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppTranslations.translate(context, 'close'),
              style: TextStyle(fontSize: fontSize),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation(BuildContext context, double fontSize) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppTranslations.translate(context, 'exit'),
          style: TextStyle(fontSize: fontSize + 2, fontWeight: FontWeight.bold),
        ),
        content: Text(
          AppTranslations.translate(context, 'exit_confirmation'),
          style: TextStyle(fontSize: fontSize),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppTranslations.translate(context, 'cancel'),
              style: TextStyle(fontSize: fontSize),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              SystemNavigator.pop();
            },
            child: Text(
              AppTranslations.translate(context, 'exit'),
              style: TextStyle(fontSize: fontSize),
            ),
          ),
        ],
      ),
    );
  }
}