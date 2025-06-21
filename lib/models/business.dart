import 'package:cloud_firestore/cloud_firestore.dart';

class Business {
  final String id;
  final String name;
  final String category;
  final String description;
  final String address;
  final String contact;
  final String email;
  final String website;
  final String imageUrl;
  final List<String> services;
  final String status;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Business({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.address,
    required this.contact,
    required this.email,
    required this.website,
    required this.imageUrl,
    required this.services,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'address': address,
      'contact': contact,
      'email': email,
      'website': website,
      'imageUrl': imageUrl,
      'services': services,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Business.fromMap(Map<String, dynamic> map) {
    return Business(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      description: map['description'] as String,
      address: map['address'] as String,
      contact: map['contact'] as String,
      email: map['email'] as String,
      website: map['website'] as String,
      imageUrl: map['imageUrl'] as String,
      services: List<String>.from(map['services'] as List<dynamic>),
      status: map['status'] as String,
      createdAt: map['createdAt'] as Timestamp,
      updatedAt: map['updatedAt'] as Timestamp,
    );
  }
}
