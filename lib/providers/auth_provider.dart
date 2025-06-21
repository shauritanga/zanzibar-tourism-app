import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zanzibar_tourism/models/user.dart';

final authProvider = Provider((ref) => FirebaseAuth.instance);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authProvider).authStateChanges();
});

final currentUserProvider = StreamProvider<ZanzibarUser?>((ref) {
  final auth = ref.watch(authProvider);
  return auth.authStateChanges().asyncMap((user) async {
    if (user == null) return null;
    
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    
    if (!userDoc.exists) {
      // Create user document if it doesn't exist
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'email': user.email,
        'name': user.displayName,
        'role': user.email == 'admin@zanzibar.com' ? 'admin' : 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    
    return ZanzibarUser.fromFirebase(user, userDoc.data() ?? {});
  });
});

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._auth, this._firestore);

  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> createUserWithEmailAndPassword(
      {required String email,
      required String password,
      String? name}) async {
    if (email.toLowerCase() == 'admin@zanzibar.com') {
      throw Exception('Admin registration is not allowed');
    }
    
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (name != null) {
      await userCredential.user?.updateDisplayName(name);
    }

    // Create user document in Firestore
    await _firestore.collection('users').doc(userCredential.user!.uid).set({
      'email': email,
      'name': name ?? email.split('@')[0],
      'role': 'user',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return userCredential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateProfile({String? name}) async {
    final user = _auth.currentUser;
    if (user != null && name != null) {
      await user.updateDisplayName(name);
      await _firestore.collection('users').doc(user.uid).update({
        'name': name,
      });
    }
  }
}
