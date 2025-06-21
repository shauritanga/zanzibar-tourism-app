import 'package:cloud_firestore/cloud_firestore.dart';

class Tour {
  final String id;
  final String title;
  final String description;
  final String duration;
  final double price;
  final int maxParticipants;
  final String difficulty;
  final String category;
  final List<String> images;
  final List<String> highlights;
  final List<String> included;
  final String meetingPoint;
  final double rating;
  final int reviews;
  final bool isActive;
  final DateTime createdAt;

  Tour({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.price,
    required this.maxParticipants,
    required this.difficulty,
    required this.category,
    required this.images,
    required this.highlights,
    required this.included,
    required this.meetingPoint,
    required this.rating,
    required this.reviews,
    required this.isActive,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'duration': duration,
      'price': price,
      'maxParticipants': maxParticipants,
      'difficulty': difficulty,
      'category': category,
      'images': images,
      'highlights': highlights,
      'included': included,
      'meetingPoint': meetingPoint,
      'rating': rating,
      'reviews': reviews,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Tour.fromMap(Map<String, dynamic> map, String id) {
    return Tour(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      duration: map['duration'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      maxParticipants: map['maxParticipants'] ?? 0,
      difficulty: map['difficulty'] ?? '',
      category: map['category'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      highlights: List<String>.from(map['highlights'] ?? []),
      included: List<String>.from(map['included'] ?? []),
      meetingPoint: map['meetingPoint'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviews: map['reviews'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class TourBooking {
  final String id;
  final String userId;
  final String tourId;
  final Tour tour;
  final int quantity;
  final String status;
  final DateTime date;
  final String paymentMethod;
  final double totalAmount;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  TourBooking({
    required this.id,
    required this.userId,
    required this.tourId,
    required this.tour,
    required this.quantity,
    required this.status,
    required this.date,
    required this.paymentMethod,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tourId': tourId,
      'tour': tour.toMap(),
      'quantity': quantity,
      'status': status,
      'date': Timestamp.fromDate(date),
      'paymentMethod': paymentMethod,
      'totalAmount': totalAmount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory TourBooking.fromMap(Map<String, dynamic> map) {
    return TourBooking(
      id: map['id'] as String,
      userId: map['userId'] as String,
      tourId: map['tourId'] as String,
      tour: Tour.fromMap(
        map['tour'] as Map<String, dynamic>,
        map['tourId'] as String,
      ),
      quantity: map['quantity'] as int,
      status: map['status'] as String,
      date: (map['date'] as Timestamp).toDate(),
      paymentMethod: map['paymentMethod'] as String,
      totalAmount: (map['totalAmount'] as num).toDouble(),
      createdAt: map['createdAt'] as Timestamp,
      updatedAt: map['updatedAt'] as Timestamp,
    );
  }
}
