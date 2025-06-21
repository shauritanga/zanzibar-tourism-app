import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ZanzibarUser {
  final String id;
  final String email;
  final String name;
  final String role;
  final int? age;
  final DateTime? createdAt;
  final DateTime? lastSignInTime;

  ZanzibarUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.age,
    this.createdAt,
    this.lastSignInTime,
  });

  factory ZanzibarUser.fromFirebase(
    User firebaseUser, [
    Map<String, dynamic>? data,
  ]) {
    return ZanzibarUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName ?? '',
      role: data?['role'] ?? 'user',
      age: data?['age']?.toInt(),
      createdAt:
          data?['createdAt'] != null
              ? (data?['createdAt'] as Timestamp).toDate()
              : null,
      lastSignInTime: firebaseUser.metadata.lastSignInTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'age': age,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'lastSignInTime':
          lastSignInTime != null ? Timestamp.fromDate(lastSignInTime!) : null,
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isUser => role == 'user';

  @override
  String toString() {
    return 'ZanzibarUser(id: $id, email: $email, name: $name, role: $role)';
  }
}
