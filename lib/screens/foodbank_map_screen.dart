import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';
import '../models/foodbank_model.dart';
import '../utils/font_size_listener.dart';
import '../l10n/app_translations.dart';
import '../providers/language_provider.dart';

class FoodBankMapScreen extends StatefulWidget {
  const FoodBankMapScreen({super.key});

  @override
  State<FoodBankMapScreen> createState() => _FoodBankMapScreenState();
}

class _FoodBankMapScreenState extends State<FoodBankMapScreen> {
  bool _showList = false;
  String _selectedState = 'All States';
  String _searchQuery = '';
  GoogleMapController? _mapController;
  Location _location = Location();
  LatLng _currentLocation = const LatLng(3.1390, 101.6869);
  bool _isLoading = true;
  Set<Marker> _markers = {};
  List<FoodBank> _foodBanks = [];
  List<FoodBank> _filteredBanks = [];

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
          _loadFoodBanks(_currentLocation.latitude, _currentLocation.longitude);
          return;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          _loadFoodBanks(_currentLocation.latitude, _currentLocation.longitude);
          return;
        }
      }

      final locationData = await _location.getLocation();
      _currentLocation = LatLng(locationData.latitude!, locationData.longitude!);

      _loadFoodBanks(_currentLocation.latitude, _currentLocation.longitude);

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLocation, zoom: 12),
        ),
      );
    } catch (e) {
      _loadFoodBanks(_currentLocation.latitude, _currentLocation.longitude);
    }
  }

  Future<void> _loadFoodBanks(double lat, double lng) async {
    try {
      final foodBanksData = await SupabaseService().getFoodBanks(lat, lng);

      List<FoodBank> foodBanks = foodBanksData.map((data) => FoodBank(
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
        photos: data['photos'],
      )).toList();

      setState(() {
        _foodBanks = foodBanks;
        _filteredBanks = foodBanks;
        _isLoading = false;
        _createMarkers();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load food banks: $e');
    }
  }

  void _createMarkers() {
    Set<Marker> markers = {};
    for (var bank in _filteredBanks) {
      markers.add(
        Marker(
          markerId: MarkerId(bank.name + bank.latitude.toString()),
          position: LatLng(bank.latitude, bank.longitude),
          infoWindow: InfoWindow(
            title: bank.name,
            snippet: '${bank.distance} • ${bank.isOpenNow ? "Open" : "Closed"}',
          ),
          onTap: () => _showFoodBankDetails(bank),
        ),
      );
    }
    setState(() => _markers = markers);
  }

  void _filterBanks() {
    setState(() {
      _filteredBanks = _foodBanks.where((bank) {
        final matchesState = _selectedState == 'All States' ||
            bank.state.contains(_selectedState);

        final matchesSearch = _searchQuery.isEmpty ||
            bank.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            bank.address.toLowerCase().contains(_searchQuery.toLowerCase());

        return matchesState && matchesSearch;
      }).toList();

      _createMarkers();

      if (_filteredBanks.isNotEmpty && !_showList) {
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(_filteredBanks.first.latitude, _filteredBanks.first.longitude),
              zoom: 14,
            ),
          ),
        );
      }
    });
  }

  void _filterNearby() {
    setState(() {
      _filteredBanks.sort((a, b) {
        double distanceA = double.parse(a.distance.replaceAll(' km', ''));
        double distanceB = double.parse(b.distance.replaceAll(' km', ''));
        return distanceA.compareTo(distanceB);
      });
      _selectedState = 'Nearby';
      _createMarkers();
    });
  }

  void _showFoodBankDetails(FoodBank bank) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.8,
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

                // Name and Status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        bank.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: bank.isOpenNow ? Colors.green[50] : Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            bank.isOpenNow ? Icons.check_circle : Icons.cancel,
                            size: 14,
                            color: bank.isOpenNow ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            bank.isOpenNow ? 'Open Now' : 'Closed',
                            style: TextStyle(
                              fontSize: 12,
                              color: bank.isOpenNow ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (bank.rating > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < bank.rating.floor()
                              ? Icons.star
                              : (index < bank.rating ? Icons.star_half : Icons.star_border),
                          color: Colors.amber,
                          size: 16,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        '${bank.rating} (${bank.totalRatings} reviews)',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Details
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      children: [
                        _buildDetailRow(Icons.location_on, 'Address', bank.address),
                        _buildDetailRow(Icons.phone, 'Phone', bank.contact),
                        _buildDetailRow(Icons.access_time, 'Opening Hours', bank.openingHours),
                        _buildDetailRow(Icons.directions_walk, 'Distance', bank.distance),
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
                        label: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openGoogleMaps(bank),
                        icon: const Icon(Icons.directions),
                        label: const Text('Directions'),
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
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
            child: Icon(icon, color: Colors.green[700], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openGoogleMaps(FoodBank bank) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${bank.latitude},${bank.longitude}';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError('Could not open Google Maps');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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
                  AppTranslations.translate(context, 'food_bank_map'),
                  style: TextStyle(fontSize: fontSize + 4),
                ),
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                actions: [
                  IconButton(
                    icon: Icon(_showList ? Icons.map : Icons.list),
                    onPressed: () => setState(() => _showList = !_showList),
                    tooltip: _showList ? 'Show Map' : 'Show List',
                  ),
                ],
              ),
              body: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                children: [
                  // Search and Filter Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: TextField(
                                  onChanged: (value) {
                                    _searchQuery = value;
                                    _filterBanks();
                                  },
                                  decoration: InputDecoration(
                                    hintText: AppTranslations.translate(context, 'search_food_banks'),
                                    hintStyle: TextStyle(fontSize: fontSize),
                                    border: InputBorder.none,
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchQuery = '';
                                        _filterBanks();
                                      },
                                    )
                                        : null,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                  style: TextStyle(fontSize: fontSize),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[100],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.my_location),
                                onPressed: _getCurrentLocation,
                                tooltip: 'My Location',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('All States', 'All States', fontSize),
                              _buildFilterChip('Nearby', 'Nearby', fontSize),
                              _buildFilterChip('Kuala Lumpur', 'Kuala Lumpur', fontSize),
                              _buildFilterChip('Selangor', 'Selangor', fontSize),
                              _buildFilterChip('Johor', 'Johor', fontSize),
                              _buildFilterChip('Penang', 'Penang', fontSize),
                              _buildFilterChip('Melaka', 'Melaka', fontSize),
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
                          '${_filteredBanks.length} ${AppTranslations.translate(context, 'food_banks_found')}',
                          style: TextStyle(fontSize: fontSize - 2, color: Colors.grey[600]),
                        ),
                        if (_filteredBanks.isNotEmpty)
                          TextButton(
                            onPressed: _selectedState == 'Nearby' ? null : _filterNearby,
                            child: Text(
                              AppTranslations.translate(context, 'sort_by_distance'),
                              style: TextStyle(
                                fontSize: fontSize - 2,
                                color: _selectedState == 'Nearby' ? Colors.green[700] : Colors.blue,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Map/List View
                  Expanded(
                    child: _showList
                        ? _buildListView(fontSize)
                        : _buildMapView(fontSize),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value, double fontSize) {
    final isSelected = _selectedState == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: fontSize - 2)),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedState = selected ? value : 'All States');
          if (value == 'Nearby' && selected) {
            _filterNearby();
          } else {
            _filterBanks();
          }
        },
        backgroundColor: Colors.grey[100],
        selectedColor: const Color(0xFF2E7D32),
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontSize: fontSize - 2),
        checkmarkColor: Colors.white,
      ),
    );
  }

  Widget _buildMapView(double fontSize) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _currentLocation, zoom: 10),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      compassEnabled: true,
      onMapCreated: (GoogleMapController controller) => _mapController = controller,
    );
  }

  Widget _buildListView(double fontSize) {
    if (_filteredBanks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              AppTranslations.translate(context, 'no_food_banks'),
              style: TextStyle(fontSize: fontSize + 2),
            ),
            const SizedBox(height: 8),
            Text(
              AppTranslations.translate(context, 'adjust_search'),
              style: TextStyle(fontSize: fontSize - 2),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredBanks.length,
      itemBuilder: (context, index) {
        final foodBank = _filteredBanks[index];
        return _buildFoodBankCard(foodBank, fontSize);
      },
    );
  }

  Widget _buildFoodBankCard(FoodBank foodBank, double fontSize) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showFoodBankDetails(foodBank),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          foodBank.name,
                          style: TextStyle(fontSize: fontSize + 2, fontWeight: FontWeight.bold),
                        ),
                        if (foodBank.rating > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              ...List.generate(5, (index) {
                                return Icon(
                                  index < foodBank.rating.floor()
                                      ? Icons.star
                                      : (index < foodBank.rating ? Icons.star_half : Icons.star_border),
                                  color: Colors.amber,
                                  size: fontSize - 2,
                                );
                              }),
                              const SizedBox(width: 4),
                              Text(
                                '(${foodBank.totalRatings})',
                                style: TextStyle(fontSize: fontSize - 4, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: foodBank.isOpenNow ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          foodBank.isOpenNow ? Icons.check_circle : Icons.cancel,
                          size: fontSize - 4,
                          color: foodBank.isOpenNow ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          foodBank.isOpenNow ? 'Open' : 'Closed',
                          style: TextStyle(
                            fontSize: fontSize - 4,
                            color: foodBank.isOpenNow ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: fontSize, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      foodBank.address,
                      style: TextStyle(fontSize: fontSize - 2, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: fontSize, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      foodBank.shortHours,
                      style: TextStyle(fontSize: fontSize - 2, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone, size: fontSize, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      foodBank.contact,
                      style: TextStyle(fontSize: fontSize - 2, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(
                    label: Text(foodBank.distance, style: TextStyle(fontSize: fontSize - 4)),
                    backgroundColor: Colors.green[50],
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward, color: Colors.green[700], size: fontSize),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}