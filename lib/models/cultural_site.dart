import 'package:cloud_firestore/cloud_firestore.dart';

class CulturalSite {
  final String id;
  final String name;
  final String description;
  final List<String>? images;
  final List<String>? videos;
  final GeoPoint? location;
  final int? visitCount;

  CulturalSite({
    required this.id,
    required this.name,
    required this.description,
    this.images,
    this.videos,
    this.location,
    this.visitCount,
  });

  factory CulturalSite.fromMap(Map<String, dynamic> data, String id) {
    return CulturalSite(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      videos: List<String>.from(data['videos'] ?? []),
      location: data['location'] as GeoPoint?,
      visitCount: data['visitCount'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'images': images,
      'videos': videos,
      'location': location,
      'visitCount': visitCount,
    };
  }
}
