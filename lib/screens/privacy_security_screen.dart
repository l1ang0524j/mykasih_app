import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/font_size_listener.dart';
import '../l10n/app_translations.dart';
import '../providers/language_provider.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return FontSizeListener(
          child: const SizedBox(),
          builder: (context, fontSize) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  AppTranslations.translate(context, 'privacy_security'),
                  style: TextStyle(fontSize: fontSize + 4),
                ),
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSection(
                    AppTranslations.translate(context, 'data_collection'),
                    [
                      AppTranslations.translate(context, 'data_collection_desc'),
                      AppTranslations.translate(context, 'data_collection_item1'),
                      AppTranslations.translate(context, 'data_collection_item2'),
                      AppTranslations.translate(context, 'data_collection_item3'),
                      AppTranslations.translate(context, 'data_collection_item4'),
                    ],
                    fontSize,
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    AppTranslations.translate(context, 'data_usage'),
                    [
                      AppTranslations.translate(context, 'data_usage_item1'),
                      AppTranslations.translate(context, 'data_usage_item2'),
                      AppTranslations.translate(context, 'data_usage_item3'),
                      AppTranslations.translate(context, 'data_usage_item4'),
                      AppTranslations.translate(context, 'data_usage_item5'),
                    ],
                    fontSize,
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    AppTranslations.translate(context, 'data_protection'),
                    [
                      AppTranslations.translate(context, 'data_protection_item1'),
                      AppTranslations.translate(context, 'data_protection_item2'),
                      AppTranslations.translate(context, 'data_protection_item3'),
                      AppTranslations.translate(context, 'data_protection_item4'),
                    ],
                    fontSize,
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    AppTranslations.translate(context, 'your_rights'),
                    [
                      AppTranslations.translate(context, 'rights_item1'),
                      AppTranslations.translate(context, 'rights_item2'),
                      AppTranslations.translate(context, 'rights_item3'),
                      AppTranslations.translate(context, 'rights_item4'),
                    ],
                    fontSize,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.update, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              AppTranslations.translate(context, 'last_updated'),
                              style: TextStyle(
                                fontSize: fontSize - 2,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '1 March 2026',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.verified_user, color: Colors.green[700], size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.translate(context, 'data_safe'),
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppTranslations.translate(context, 'data_safe_desc'),
                                style: TextStyle(
                                  fontSize: fontSize - 2,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSection(String title, List<String> items, double fontSize) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: fontSize + 2,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    fontSize: fontSize - 2,
                    color: Colors.grey[700],
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: fontSize - 2,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}