package screens;

import 'package:flutter/material.dart';
import '../utils/font_size_listener.dart';

class GuidesScreen extends StatelessWidget {
  const GuidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FontSizeListener(
      child: const SizedBox(),
      builder: (context, fontSize) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Guides',
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
                // Help & Support Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Help & Support',
                          style: TextStyle(
                            fontSize: fontSize + 4,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          leading: const Icon(Icons.help, color: Colors.blue),
                          title: Text(
                            'SARA FAQs',
                            style: TextStyle(fontSize: fontSize),
                          ),
                          subtitle: Text(
                            'Frequently Asked Questions (PDF)',
                            style: TextStyle(fontSize: fontSize - 2),
                          ),
                          trailing: const Icon(Icons.download),
                          onTap: () {
                            // Open PDF
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.video_library, color: Colors.red),
                          title: Text(
                            'Purchasing Guide Video',
                            style: TextStyle(fontSize: fontSize),
                          ),
                          subtitle: Text(
                            'Using MyKad for purchases',
                            style: TextStyle(fontSize: fontSize - 2),
                          ),
                          trailing: const Icon(Icons.play_circle),
                          onTap: () {
                            // Play video
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // SARA 2026 Information
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SARA 2026 Information',
                          style: TextStyle(
                            fontSize: fontSize + 4,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoItem(
                          'Eligibility Criteria',
                          'Who can apply for SARA 2026',
                          fontSize,
                        ),
                        _buildInfoItem(
                          'Application Process',
                          'Step-by-step guide to apply',
                          fontSize,
                        ),
                        _buildInfoItem(
                          'Payment Schedule',
                          'When and how payments are made',
                          fontSize,
                        ),
                        _buildInfoItem(
                          'Participating Merchants',
                          'List of stores accepting SARA',
                          fontSize,
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
                          'Contact Information',
                          style: TextStyle(
                            fontSize: fontSize + 4,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildContactItem(
                          Icons.phone,
                          'Hotline',
                          '1-800-88-1234',
                          fontSize,
                        ),
                        _buildContactItem(
                          Icons.email,
                          'Email',
                          'support@mykasih.gov.my',
                          fontSize,
                        ),
                        _buildContactItem(
                          Icons.location_on,
                          'Address',
                          'Ministry of Finance, Putrajaya',
                          fontSize,
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
  }

  Widget _buildInfoItem(String title, String subtitle, double fontSize) {
    return Padding(
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
    );
  }

  Widget _buildContactItem(IconData icon, String title, String value, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[700]),
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
              // Copy to clipboard
            },
          ),
        ],
      ),
    );
  }
}