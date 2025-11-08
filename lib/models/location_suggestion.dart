class LocationSuggestion {
  final String displayName;
  final double lat;
  final double lon;
  final String? address;
  final String? city;
  final String? state;
  final String? country;

  LocationSuggestion({
    required this.displayName,
    required this.lat,
    required this.lon,
    this.address,
    this.city,
    this.state,
    this.country,
  });

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    try {
      final address = json['address'] as Map<String, dynamic>?;

      return LocationSuggestion(
        displayName: json['display_name'] as String,
        lat: double.parse(json['lat'].toString()),
        lon: double.parse(json['lon'].toString()),
        address: address?['road'] ?? address?['suburb'],
        city: address?['city'] ??
            address?['town'] ??
            address?['village'] ??
            address?['municipality'],
        state: address?['state'],
        country: address?['country'],
      );
    } catch (e) {
      rethrow;
    }
  }

  String get shortAddress {
    final parts = <String>[];

    if (address != null && address!.isNotEmpty) {
      parts.add(address!);
    }
    if (city != null && city!.isNotEmpty) {
      parts.add(city!);
    }
    if (state != null && state!.isNotEmpty) {
      parts.add(state!);
    }

    return parts.isNotEmpty ? parts.join(', ') : displayName;
  }

  @override
  String toString() {
    return 'LocationSuggestion(displayName: $displayName, lat: $lat, lon: $lon, shortAddress: $shortAddress)';
  }
}