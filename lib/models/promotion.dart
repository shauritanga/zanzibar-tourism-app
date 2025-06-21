// File: lib/models/promotion.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Promotion {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final double discountPercentage;
  final String discountCode;
  final DateTime validFrom;
  final DateTime validUntil;
  final String image;
  final String category;
  final bool isActive;
  final int maxUses;
  final int currentUses;
  final DateTime createdAt;

  Promotion({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.discountPercentage,
    required this.discountCode,
    required this.validFrom,
    required this.validUntil,
    required this.image,
    required this.category,
    required this.isActive,
    required this.maxUses,
    required this.currentUses,
    required this.createdAt,
  });

  factory Promotion.fromMap(Map<String, dynamic> map, String id) {
    return Promotion(
      id: id,
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      description: map['description'] ?? '',
      discountPercentage: (map['discountPercentage'] ?? 0.0).toDouble(),
      discountCode: map['discountCode'] ?? '',
      validFrom: (map['validFrom'] as Timestamp?)?.toDate() ?? DateTime.now(),
      validUntil: (map['validUntil'] as Timestamp?)?.toDate() ?? DateTime.now(),
      image: map['image'] ?? '',
      category: map['category'] ?? '',
      isActive: map['isActive'] ?? true,
      maxUses: map['maxUses'] ?? 0,
      currentUses: map['currentUses'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'discountPercentage': discountPercentage,
      'discountCode': discountCode,
      'validFrom': Timestamp.fromDate(validFrom),
      'validUntil': Timestamp.fromDate(validUntil),
      'image': image,
      'category': category,
      'isActive': isActive,
      'maxUses': maxUses,
      'currentUses': currentUses,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isValid {
    final now = DateTime.now();
    return isActive && 
           now.isAfter(validFrom) && 
           now.isBefore(validUntil) &&
           currentUses < maxUses;
  }

  bool get isExpired {
    return DateTime.now().isAfter(validUntil);
  }

  bool get isMaxedOut {
    return currentUses >= maxUses;
  }

  Promotion copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    double? discountPercentage,
    String? discountCode,
    DateTime? validFrom,
    DateTime? validUntil,
    String? image,
    String? category,
    bool? isActive,
    int? maxUses,
    int? currentUses,
    DateTime? createdAt,
  }) {
    return Promotion(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountCode: discountCode ?? this.discountCode,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      image: image ?? this.image,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      maxUses: maxUses ?? this.maxUses,
      currentUses: currentUses ?? this.currentUses,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Promotion(id: $id, title: $title, discountPercentage: $discountPercentage%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Promotion && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
