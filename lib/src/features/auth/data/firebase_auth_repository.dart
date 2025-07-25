import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'auth_error_mapper.dart';
import 'auth_repository.dart';
import 'models/app_user.dart';

/// Firebase implementation of AuthRepository
///
/// This class provides concrete implementation of authentication operations
/// using Firebase Auth SDK. It handles Firebase-specific operations and
/// maps Firebase exceptions to domain exceptions.
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthRepository(this._firebaseAuth);

  @override
  Stream<AppUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      return firebaseUser != null ? AppUser.fromFirebaseUser(firebaseUser) : null;
    });
  }

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthErrorMapper.mapFirebaseException(e);
    } catch (e) {
      throw AuthErrorMapper.mapException(e);
    }
  }

  @override
  Future<void> createUserWithEmailAndPassword(String email, String password) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthErrorMapper.mapFirebaseException(e);
    } catch (e) {
      throw AuthErrorMapper.mapException(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw AuthErrorMapper.mapException(e);
    }
  }


}