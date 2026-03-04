class Merchant {
  final String name;
  final String address;
  final String state;
  final String distance;
  final String openingHours;
  final String contact;
  final double latitude;
  final double longitude;
  final bool isOpen;
  final double rating;
  final int totalRatings;
  final String? photos;
  final String category;

  Merchant({
    required this.name,
    required this.address,
    required this.state,
    required this.distance,
    required this.openingHours,
    required this.contact,
    required this.latitude,
    required this.longitude,
    required this.isOpen,
    required this.rating,
    required this.totalRatings,
    required this.category,
    this.photos,
  });

  bool get isOpenNow => isOpen;

  String get ratingDisplay {
    if (rating == 0) return 'No ratings';
    return '★ $rating ($totalRatings)';
  }

  String get shortHours {
    if (openingHours.contains('Closed')) {
      final lines = openingHours.split('\n');
      if (lines.isNotEmpty) {
        return lines[0];
      }
    }
    return openingHours.length > 30
        ? openingHours.substring(0, 30) + '...'
        : openingHours;
  }
}