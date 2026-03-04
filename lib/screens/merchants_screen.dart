import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';
import '../models/merchant_model.dart';
import '../utils/font_size_listener.dart';
import '../l10n/app_translations.dart';
import '../providers/language_provider.dart';

class MerchantsScreen extends StatefulWidget {
  const MerchantsScreen({super.key});

  @override
  State<MerchantsScreen> createState() => _MerchantsScreenState();
}

class _MerchantsScreenState extends State<MerchantsScreen> {
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedState = 'All States';

  List<Merchant> _allMerchants = [];
  List<Merchant> _filteredMerchants = [];

  final TextEditingController _searchController = TextEditingController();
  Location _location = Location();

  List<String> get categories {
    final cats = _allMerchants.map((m) => m.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  List<String> get states {
    final sts = _allMerchants.map((m) => m.state).toSet().toList();
    sts.sort();
    return ['All States', ...sts];
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          _loadMerchants(3.1390, 101.6869);
          return;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          _loadMerchants(3.1390, 101.6869);
          return;
        }
      }

      final locationData = await _location.getLocation();
      print('📍 当前位置: ${locationData.latitude}, ${locationData.longitude}');

      _loadMerchants(locationData.latitude!, locationData.longitude!);
    } catch (e) {
      print('❌ 位置错误: $e');
      _loadMerchants(3.1390, 101.6869);
    }
  }

  Future<void> _loadMerchants(double lat, double lng) async {
    try {
      print('📍 加载商家，位置: $lat, $lng');

      final merchantsData = await SupabaseService().getMerchants(lat, lng);

      print('📦 API 返回数据长度: ${merchantsData.length}');

      List<Merchant> merchants = merchantsData.map((data) {
        return Merchant(
          name: data['name'] ?? '',
          address: data['address'] ?? '',
          state: data['state'] ?? 'Malaysia',
          distance: data['distance']?.toString() ?? '0 km',
          openingHours: data['opening_hours'] ?? 'Hours not available',
          contact: data['phone'] ?? 'No phone',
          latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
          longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
          isOpen: data['is_open'] ?? false,
          rating: (data['rating'] as num?)?.toDouble() ?? 0,
          totalRatings: data['total_ratings'] ?? 0,
          category: data['category'] ?? 'Store',
          photos: data['photos'],
        );
      }).toList();

      setState(() {
        _allMerchants = merchants;
        _filteredMerchants = merchants;
        _isLoading = false;
      });

      print('✅ 最终商家数量: ${merchants.length}');
    } catch (e) {
      print('❌ 加载商家错误: $e');
      setState(() => _isLoading = false);
      _showError('Failed to load merchants: $e');
    }
  }

  void _filterMerchants() {
    setState(() {
      _filteredMerchants = _allMerchants.where((merchant) {
        final matchesSearch = _searchQuery.isEmpty ||
            merchant.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            merchant.address.toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesCategory = _selectedCategory == 'All' ||
            merchant.category == _selectedCategory;

        final matchesState = _selectedState == 'All States' ||
            merchant.state == _selectedState;

        return matchesSearch && matchesCategory && matchesState;
      }).toList();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _callMerchant(String phoneNumber, double fontSize) async {
    final telUrl = 'tel:$phoneNumber';
    final uri = Uri.parse(telUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not make a call',
            style: TextStyle(fontSize: fontSize),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openGoogleMaps(Merchant merchant, double fontSize) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${merchant.latitude},${merchant.longitude}';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open Google Maps',
            style: TextStyle(fontSize: fontSize),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showMerchantDetails(Merchant merchant, double fontSize) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Name and Category
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        merchant.name,
                        style: TextStyle(
                          fontSize: fontSize + 4,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: merchant.isOpenNow
                            ? Colors.green[50]
                            : Colors.red[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            merchant.isOpenNow ? Icons.check_circle : Icons.cancel,
                            size: fontSize - 2,
                            color: merchant.isOpenNow ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            merchant.isOpenNow ? 'Open' : 'Closed',
                            style: TextStyle(
                              fontSize: fontSize - 2,
                              color: merchant.isOpenNow ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Category
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    merchant.category,
                    style: TextStyle(
                      fontSize: fontSize - 2,
                      color: Colors.green[700],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Rating
                if (merchant.rating > 0) ...[
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < merchant.rating.floor()
                              ? Icons.star
                              : (index < merchant.rating ? Icons.star_half : Icons.star_border),
                          color: Colors.amber,
                          size: fontSize,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        '${merchant.rating} (${merchant.totalRatings} reviews)',
                        style: TextStyle(
                          fontSize: fontSize - 2,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Details
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      children: [
                        _buildDetailRow(
                          Icons.location_on,
                          AppTranslations.translate(context, 'address'),
                          merchant.address,
                          fontSize,
                        ),
                        _buildDetailRow(
                          Icons.phone,
                          AppTranslations.translate(context, 'phone'),
                          merchant.contact,
                          fontSize,
                        ),
                        _buildDetailRow(
                          Icons.access_time,
                          AppTranslations.translate(context, 'opening_hours'),
                          merchant.openingHours,
                          fontSize,
                        ),
                        _buildDetailRow(
                          Icons.directions_walk,
                          AppTranslations.translate(context, 'distance'),
                          merchant.distance,
                          fontSize,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: Text(
                          AppTranslations.translate(context, 'close'),
                          style: TextStyle(fontSize: fontSize),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _openGoogleMaps(merchant, fontSize);
                        },
                        icon: const Icon(Icons.directions),
                        label: Text(
                          AppTranslations.translate(context, 'directions'),
                          style: TextStyle(fontSize: fontSize),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.green[700],
              size: fontSize,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize - 2,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
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
    );
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
                  AppTranslations.translate(context, 'find_merchants'),
                  style: TextStyle(fontSize: fontSize + 4),
                ),
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _getCurrentLocation,
                    tooltip: AppTranslations.translate(context, 'refresh'),
                  ),
                ],
              ),
              body: Column(
                children: [
                  // Search and Filter Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      children: [
                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              _searchQuery = value;
                              _filterMerchants();
                            },
                            decoration: InputDecoration(
                              hintText: AppTranslations.translate(context, 'search_merchants'),
                              hintStyle: TextStyle(fontSize: fontSize - 2),
                              border: InputBorder.none,
                              prefixIcon: const Icon(Icons.search, color: Colors.grey),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchQuery = '';
                                  _filterMerchants();
                                },
                              )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Filter Chips Row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip(
                                '${AppTranslations.translate(context, 'category')}: $_selectedCategory',
                                fontSize,
                                    () {
                                  _showCategoryFilter(fontSize);
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                '${AppTranslations.translate(context, 'state')}: $_selectedState',
                                fontSize,
                                    () {
                                  _showStateFilter(fontSize);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Results Count
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_filteredMerchants.length} ${AppTranslations.translate(context, 'merchants_found')}',
                          style: TextStyle(
                            fontSize: fontSize - 2,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          AppTranslations.translate(context, 'accept_mykad'),
                          style: TextStyle(
                            fontSize: fontSize - 2,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Merchant List
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredMerchants.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.store,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppTranslations.translate(context, 'no_merchants'),
                            style: TextStyle(
                              fontSize: fontSize + 2,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppTranslations.translate(context, 'adjust_filters'),
                            style: TextStyle(
                              fontSize: fontSize - 2,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredMerchants.length,
                      itemBuilder: (context, index) {
                        return _buildMerchantCard(
                          _filteredMerchants[index],
                          fontSize,
                        );
                      },
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

  Widget _buildFilterChip(String label, double fontSize, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize - 2,
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: fontSize,
              color: Colors.green[700],
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryFilter(double fontSize) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslations.translate(context, 'select_category'),
              style: TextStyle(
                fontSize: fontSize + 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...categories.map((category) {
              return ListTile(
                title: Text(
                  category,
                  style: TextStyle(fontSize: fontSize),
                ),
                trailing: _selectedCategory == category
                    ? Icon(Icons.check, color: Colors.green[700])
                    : null,
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                    _filterMerchants();
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showStateFilter(double fontSize) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslations.translate(context, 'select_state'),
              style: TextStyle(
                fontSize: fontSize + 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...states.map((state) {
              return ListTile(
                title: Text(
                  state,
                  style: TextStyle(fontSize: fontSize),
                ),
                trailing: _selectedState == state
                    ? Icon(Icons.check, color: Colors.green[700])
                    : null,
                onTap: () {
                  setState(() {
                    _selectedState = state;
                    _filterMerchants();
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMerchantCard(Merchant merchant, double fontSize) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showMerchantDetails(merchant, fontSize),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name and Category
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          merchant.name,
                          style: TextStyle(
                            fontSize: fontSize + 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (merchant.rating > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              ...List.generate(5, (index) {
                                return Icon(
                                  index < merchant.rating.floor()
                                      ? Icons.star
                                      : (index < merchant.rating ? Icons.star_half : Icons.star_border),
                                  color: Colors.amber,
                                  size: fontSize - 2,
                                );
                              }),
                              const SizedBox(width: 4),
                              Text(
                                '(${merchant.totalRatings})',
                                style: TextStyle(
                                  fontSize: fontSize - 4,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: merchant.isOpenNow
                          ? Colors.green[50]
                          : Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          merchant.isOpenNow ? Icons.check_circle : Icons.cancel,
                          size: fontSize - 4,
                          color: merchant.isOpenNow ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          merchant.isOpenNow ? 'Open' : 'Closed',
                          style: TextStyle(
                            fontSize: fontSize - 4,
                            color: merchant.isOpenNow ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on,
                    size: fontSize,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      merchant.address,
                      style: TextStyle(
                        fontSize: fontSize - 2,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Distance and Hours
              Row(
                children: [
                  Icon(
                    Icons.directions_walk,
                    size: fontSize - 2,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    merchant.distance,
                    style: TextStyle(
                      fontSize: fontSize - 2,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: fontSize - 2,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      merchant.shortHours,
                      style: TextStyle(
                        fontSize: fontSize - 2,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Category Chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  merchant.category,
                  style: TextStyle(
                    fontSize: fontSize - 4,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}