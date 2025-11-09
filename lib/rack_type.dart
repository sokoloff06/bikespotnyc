enum RackType {
  largeHoop('Large Hoop', 'assets/images/racks/large-hoop.avif'),
  smallHoop('Small Hoop', 'assets/images/racks/small-hoop.avif'),
  uRack('U-Rack', 'assets/images/racks/u-rack.webp'),
  wave('Wave Rack', 'assets/images/racks/wave-rack.webp'),
  bikeCorral('Bike Corral', 'assets/images/racks/bike-corral.avif'),
  sled('Sled', 'assets/images/racks/sled.jpg'),
  opal('Opal', 'assets/images/racks/opal.webp'),
  byrne('Byrne', 'assets/images/racks/byrne.jpg'),
  staple('Staple', 'assets/images/racks/staple.png'),
  other('Other', 'assets/images/racks/other.png');

  const RackType(this.displayName, this.imagePath);

  final String displayName;
  final String imagePath;

  factory RackType.fromString(String rackTypeString) {
    final normalizedRackType = rackTypeString
        .toUpperCase()
        .replaceAll('-', ' ')
        .trim();
    switch (normalizedRackType) {
      case final s when s.contains('LARGE HOOP') || s.contains('LARGEHOOP'):
        return RackType.largeHoop;
      case final s when s.contains('SMALL HOOP') || s.contains('SMALLHOOP'):
        return RackType.smallHoop;
      case final s when s.contains('U RACK') || s.contains('URACK'):
        return RackType.uRack;
      case final s when s.contains('WAVE'):
        return RackType.wave;
      case final s when s.contains('CORRAL'):
        return RackType.bikeCorral;
      case final s when s.contains('SLED'):
        return RackType.sled;
      case final s when s.contains('OPAL'):
        return RackType.opal;
      case final s when s.contains('BYRNE'):
        return RackType.byrne;
      case final s when s.contains('STAPLE'):
        return RackType.staple;
      default:
        return RackType.other;
    }
  }
}
