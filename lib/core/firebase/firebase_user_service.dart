import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';

class FirebaseUserService {
  FirebaseUserService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Future<User?> ensureSignedIn() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) return currentUser;

    try {
      final credential = await _auth
          .signInAnonymously()
          .timeout(const Duration(seconds: 8));
      return credential.user;
    } on Object catch (error, stackTrace) {
      developer.log(
        'Anonymous Firebase sign-in is unavailable.',
        name: 'FirebaseUserService',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
