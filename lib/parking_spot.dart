class ParkingSpot {
  final String borough;
  final String siteId;
  final double latitude;
  final double longitude;

  ParkingSpot({
    required this.borough,
    required this.siteId,
    required this.latitude,
    required this.longitude,
  });

  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    return ParkingSpot(
      borough: json['borough'] ?? '',
      siteId: json['site_id'] ?? '',
      latitude: double.tryParse(json['latitude'] ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude'] ?? '0') ?? 0.0,
    );
  }
}
