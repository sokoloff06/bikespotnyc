import 'package:bikespotnyc/rack_type.dart';

class ParkingSpot {
  final String borough;
  final String siteId;
  final RackType rackType;
  final double latitude;
  final double longitude;

  ParkingSpot({
    required this.borough,
    required this.siteId,
    required this.rackType,
    required this.latitude,
    required this.longitude,
  });

  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    return ParkingSpot(
      borough: json['borough'] ?? '',
      siteId: json['site_id'] ?? '',
      rackType: RackType.fromString(json['racktype'] ?? ''),
      latitude: double.tryParse(json['latitude'] ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude'] ?? '0') ?? 0.0,
    );
  }
}
