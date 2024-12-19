// lib/models/publisher.dart

class Publisher {
  final int id;
  final String name;
  final Location location;

  Publisher({
    required this.id,
    required this.name,
    required this.location,
  });

  factory Publisher.fromJson(Map<String, dynamic> json) {
    return Publisher(
      id: json['id'],
      name: json['name'],
      location: Location.fromJson(json['location']),
    );
  }
}

class Location {
  final double latitude;
  final double longitude;
  final String? country;
  final String? city;

  Location({
    required this.latitude,
    required this.longitude,
    this.country,
    this.city,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: json['latitude'],
      longitude: json['longitude'],
      country: json['country'],
      city: json['city'],
    );
  }
}
