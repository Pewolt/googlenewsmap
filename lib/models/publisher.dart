// lib/models/publisher.dart

import 'package:json_annotation/json_annotation.dart';

part 'publisher.g.dart';

@JsonSerializable()
class Publisher {
  final int id;
  final String name;
  final Location location;

  Publisher({
    required this.id,
    required this.name,
    required this.location,
  });

  /// Vom Generator erstellte Methode zum Deserialisieren
  factory Publisher.fromJson(Map<String, dynamic> json) =>
      _$PublisherFromJson(json);

  /// Zum Serialisieren
  Map<String, dynamic> toJson() => _$PublisherToJson(this);
}

@JsonSerializable()
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

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);

  Map<String, dynamic> toJson() => _$LocationToJson(this);
}
