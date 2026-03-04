import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/font_size_listener.dart';
import '../l10n/app_translations.dart';
import '../providers/language_provider.dart';

class GuidesScreen extends StatelessWidget {
  const GuidesScreen({super.key});

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
                  AppTranslations.translate(context, 'guides'),
                  style: TextStyle(fontSize: fontSize + 4),
                ),
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SARA 2026 Information
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.translate(context, 'sara_info'),
                              style: TextStyle(
                                fontSize: fontSize + 4,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildInfoItem(
                              context,
                              AppTranslations.translate(context, 'eligibility_criteria'),
                              AppTranslations.translate(context, 'eligibility_subtitle'),
                              fontSize,
                                  () {
                                _showInfoDialog(context,
                                  AppTranslations.translate(context, 'eligibility_criteria'),
                                  AppTranslations.translate(context, 'eligibility_content'),
                                  fontSize,
                                );
                              },
                            ),
                            _buildInfoItem(
                              context,
                              AppTranslations.translate(context, 'application_process'),
                              AppTranslations.translate(context, 'application_subtitle'),
                              fontSize,
                                  () {
                                _showInfoDialog(context,
                                  AppTranslations.translate(context, 'application_process'),
                                  AppTranslations.translate(context, 'application_content'),
                                  fontSize,
                                );
                              },
                            ),
                            _buildInfoItem(
                              context,
                              AppTranslations.translate(context, 'payment_schedule'),
                              AppTranslations.translate(context, 'payment_subtitle'),
                              fontSize,
                                  () {
                                _showInfoDialog(context,
                                  AppTranslations.translate(context, 'payment_schedule'),
                                  AppTranslations.translate(context, 'payment_content'),
                                  fontSize,
                                );
                              },
                            ),
                            _buildInfoItem(
                              context,
                              AppTranslations.translate(context, 'participating_merchants'),
                              AppTranslations.translate(context, 'merchants_subtitle'),
                              fontSize,
                                  () {
                                _showInfoDialog(context,
                                  AppTranslations.translate(context, 'participating_merchants'),
                                  AppTranslations.translate(context, 'merchants_content'),
                                  fontSize,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Contact Information
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.translate(context, 'contact_info'),
                              style: TextStyle(
                                fontSize: fontSize + 4,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildContactItem(
                              context,
                              Icons.phone,
                              AppTranslations.translate(context, 'hotline'),
                              '1-800-88-1234',
                              fontSize,
                            ),
                            _buildContactItem(
                              context,
                              Icons.email,
                              AppTranslations.translate(context, 'email'),
                              'support@mykasih.gov.my',
                              fontSize,
                            ),
                            _buildContactItem(
                              context,
                              Icons.location_on,
                              AppTranslations.translate(context, 'address'),
                              AppTranslations.translate(context, 'address_value'),
                              fontSize,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time, color: Colors.blue[700]),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppTranslations.translate(context, 'operating_hours'),
                                          style: TextStyle(
                                            fontSize: fontSize,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          AppTranslations.translate(context, 'hours_value'),
                                          style: TextStyle(
                                            fontSize: fontSize - 2,
                                            color: Colors.grey[600],
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

  Widget _buildInfoItem(
      BuildContext context,
      String title,
      String subtitle,
      double fontSize,
      VoidCallback onTap
      ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.info, color: Colors.green[700]),
            const SizedBox(width: 12),
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
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: fontSize - 2,
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

  Widget _buildContactItem(
      BuildContext context,
      IconData icon,
      String title,
      String value,
      double fontSize
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue[700], size: 24),
          ),
          const SizedBox(width: 12),
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
                Text(
                  value,
                  style: TextStyle(
                    fontSize: fontSize - 2,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '$title ${AppTranslations.translate(context, 'copied')}',
                    style: TextStyle(fontSize: fontSize),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(
      BuildContext context,
      String title,
      String content,
      double fontSize
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: TextStyle(fontSize: fontSize + 2, fontWeight: FontWeight.bold),
        ),
        content: Text(
          content,
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
}