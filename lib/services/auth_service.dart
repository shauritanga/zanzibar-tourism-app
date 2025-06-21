// File: lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last sign in time
      if (credential.user != null) {
        await _updateLastSignInTime(credential.user!.uid);
      }

      return credential;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email,
          'name': name,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
          'lastSignInTime': FieldValue.serverTimestamp(),
          'emailVerified': false,
          'profileComplete': false,
          'preferences': {
            'notifications': true,
            'language': 'en',
            'currency': 'USD',
          },
        });

        // Send email verification
        await credential.user!.sendEmailVerification();
      }

      return credential;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw Exception('Email verification failed: $e');
    }
  }

  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      throw Exception('Failed to reload user: $e');
    }
  }

  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }

        // Update Firestore document
        await _firestore.collection('users').doc(user.uid).update({
          'name': displayName ?? user.displayName,
          'photoURL': photoURL ?? user.photoURL,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Profile update failed: $e');
    }
  }

  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'preferences': preferences,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Preferences update failed: $e');
    }
  }

  Future<void> _updateLastSignInTime(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastSignInTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Don't throw error for this non-critical operation
      print('Failed to update last sign in time: $e');
    }
  }

  // Legacy methods for backward compatibility
  Future<void> signIn(String email, String password) async {
    await signInWithEmailAndPassword(email, password);
  }

  Future<void> signUp(String email, String password) async {
    await createUserWithEmailAndPassword(email, password, '');
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user document from Firestore
        await _firestore.collection('users').doc(user.uid).delete();

        // Delete user account
        await user.delete();
      }
    } catch (e) {
      throw Exception('Account deletion failed: $e');
    }
  }
}
