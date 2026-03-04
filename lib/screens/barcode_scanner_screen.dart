import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/font_size_listener.dart';
import '../l10n/app_translations.dart';
import '../providers/language_provider.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _isScanning = false;
  bool _isCameraInitialized = false;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  String? _lastScannedCode;
  List<ScanHistory> _scanHistory = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadScanHistory();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();

        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  Future<void> _loadScanHistory() async {
    // TODO: Load from database if needed
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      final randomCode = _generateRandomBarcode();

      setState(() {
        _lastScannedCode = randomCode;
        _isScanning = false;

        _scanHistory.insert(0, ScanHistory(
          barcode: randomCode,
          timestamp: DateTime.now(),
        ));
      });
    });
  }

  String _generateRandomBarcode() {
    String barcode = '';
    for (int i = 0; i < 13; i++) {
      barcode += (DateTime.now().millisecond % 10).toString();
    }
    return barcode;
  }

  void _stopScan() {
    setState(() {
      _isScanning = false;
    });
  }

  void _enterManually() {
    showDialog(
      context: context,
      builder: (context) => const BarcodeInputDialog(),
    ).then((barcode) {
      if (barcode != null && barcode.isNotEmpty) {
        setState(() {
          _lastScannedCode = barcode;
          _scanHistory.insert(0, ScanHistory(
            barcode: barcode,
            timestamp: DateTime.now(),
          ));
        });
      }
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

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
                  AppTranslations.translate(context, 'scan_barcode'),
                  style: TextStyle(fontSize: fontSize + 4),
                ),
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.history),
                    onPressed: () {
                      _showScanHistory(fontSize);
                    },
                    tooltip: AppTranslations.translate(context, 'history'),
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Camera Preview Container
                    Container(
                      height: 350,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green[700]!, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: _isCameraInitialized && _cameraController != null
                            ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _cameraController!.value.previewSize!.width,
                            height: _cameraController!.value.previewSize!.height,
                            child: CameraPreview(_cameraController!),
                          ),
                        )
                            : _buildCameraPlaceholder(fontSize),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Scan Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isScanning ? _stopScan : _startScan,
                        icon: Icon(_isScanning ? Icons.stop : Icons.qr_code_scanner),
                        label: Text(
                          _isScanning
                              ? AppTranslations.translate(context, 'stop_scanning')
                              : AppTranslations.translate(context, 'start_scan'),
                          style: TextStyle(fontSize: fontSize),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isScanning
                              ? Colors.red[700]
                              : const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Manual Entry
                    TextButton.icon(
                      onPressed: _enterManually,
                      icon: const Icon(Icons.edit),
                      label: Text(
                        AppTranslations.translate(context, 'enter_manually'),
                        style: TextStyle(fontSize: fontSize),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Scan Result
                    if (_lastScannedCode != null) ...[
                      _buildScanResult(fontSize),
                    ],

                    const SizedBox(height: 24),

                    // Quick Tips
                    _buildQuickTips(fontSize),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCameraPlaceholder(double fontSize) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _isCameraInitialized
                ? AppTranslations.translate(context, 'camera_ready')
                : AppTranslations.translate(context, 'camera_not_available'),
            style: TextStyle(
              color: Colors.white70,
              fontSize: fontSize,
            ),
          ),
          if (!_isCameraInitialized) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.orange[700],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                AppTranslations.translate(context, 'demo_mode'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize - 4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScanResult(double fontSize) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslations.translate(context, 'barcode_scanned'),
                      style: TextStyle(
                        fontSize: fontSize + 2,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    Text(
                      _lastScannedCode!,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange[700],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.translate(context, 'demo_mode'),
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppTranslations.translate(context, 'demo_warning'),
                        style: TextStyle(
                          fontSize: fontSize - 2,
                          color: Colors.orange[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _lastScannedCode = null;
                    });
                  },
                  icon: const Icon(Icons.close),
                  label: Text(
                    AppTranslations.translate(context, 'clear'),
                    style: TextStyle(fontSize: fontSize - 2),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppTranslations.translate(context, 'barcode_copied'),
                          style: TextStyle(fontSize: fontSize),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: Text(
                    AppTranslations.translate(context, 'copy'),
                    style: TextStyle(fontSize: fontSize - 2),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTips(double fontSize) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber[700]),
                const SizedBox(width: 8),
                Text(
                  AppTranslations.translate(context, 'quick_tips'),
                  style: TextStyle(
                    fontSize: fontSize + 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTipItem(
              Icons.camera_alt,
              AppTranslations.translate(context, 'tip_position'),
              Colors.blue,
              fontSize,
            ),
            _buildTipItem(
              Icons.history,
              AppTranslations.translate(context, 'tip_history'),
              Colors.green,
              fontSize,
            ),
            _buildTipItem(
              Icons.info,
              AppTranslations.translate(context, 'tip_official'),
              Colors.orange,
              fontSize,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String text, Color color, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: fontSize),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: fontSize - 2),
            ),
          ),
        ],
      ),
    );
  }

  void _showScanHistory(double fontSize) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslations.translate(context, 'scan_history'),
              style: TextStyle(
                fontSize: fontSize + 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _scanHistory.isEmpty
                  ? Center(
                child: Text(
                  AppTranslations.translate(context, 'no_history'),
                  style: TextStyle(
                    fontSize: fontSize,
                    color: Colors.grey[500],
                  ),
                ),
              )
                  : ListView.builder(
                itemCount: _scanHistory.length,
                itemBuilder: (context, index) {
                  final item = _scanHistory[index];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.qr_code,
                        color: Colors.blue,
                        size: fontSize - 2,
                      ),
                    ),
                    title: Text(
                      item.barcode,
                      style: TextStyle(
                        fontSize: fontSize - 2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '${AppTranslations.translate(context, 'scanned_at')} ${_formatTime(item.timestamp)}',
                      style: TextStyle(fontSize: fontSize - 4),
                    ),
                    trailing: TextButton(
                      onPressed: () {
                        setState(() {
                          _lastScannedCode = item.barcode;
                        });
                        Navigator.pop(context);
                      },
                      child: Text(
                        AppTranslations.translate(context, 'view'),
                        style: TextStyle(
                          fontSize: fontSize - 4,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class BarcodeInputDialog extends StatefulWidget {
  const BarcodeInputDialog({super.key});

  @override
  State<BarcodeInputDialog> createState() => _BarcodeInputDialogState();
}

class _BarcodeInputDialogState extends State<BarcodeInputDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppTranslations.translate(context, 'enter_barcode')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: AppTranslations.translate(context, 'barcode_hint'),
              border: const OutlineInputBorder(),
            ),
            maxLength: 13,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppTranslations.translate(context, 'demo_warning'),
                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppTranslations.translate(context, 'cancel')),
        ),
        TextButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              Navigator.pop(context, _controller.text);
            }
          },
          child: Text(AppTranslations.translate(context, 'check')),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class ScanHistory {
  final String barcode;
  final DateTime timestamp;

  ScanHistory({
    required this.barcode,
    required this.timestamp,
  });
}