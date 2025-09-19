class ParkingSpot {
  final String borough;
  final String assetId;
  final String location;
  final int yrInstalled;
  final double latitude;
  final double longitude;

  ParkingSpot({
    required this.borough,
    required this.assetId,
    required this.location,
    required this.yrInstalled,
    required this.latitude,
    required this.longitude,
  });

  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    return ParkingSpot(
      borough: json['borough'] ?? '',
      assetId: json['asset_id'] ?? '',
      location: json['location'] ?? '',
      yrInstalled: int.tryParse(json['yr_install'] ?? '0') ?? 0,
      latitude: double.tryParse(json['latitude'] ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude'] ?? '0') ?? 0.0,
    );
  }
}
