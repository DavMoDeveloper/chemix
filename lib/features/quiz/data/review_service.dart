import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewService {
  ReviewService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  static const _key = 'review_wrong_ids';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<Set<String>> getWrongIds() async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_key) ?? const []).toSet();
    final document = _userDocument;
    if (document == null) return current;

    try {
      final snapshot =
          await document.get().timeout(const Duration(seconds: 5));
      final remote = snapshot.data()?['wrongElementIds'];
      if (remote is Iterable) {
        current.addAll(remote.whereType<String>());
        await _saveLocal(prefs, current);
      }
    } on Object {
      // Keep the locally available review list.
    }

    return current;
  }

  Future<void> addWrong(String elementId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_key) ?? const []).toSet();
    current.add(elementId);
    await _saveLocal(prefs, current);
    await _updateCloud(FieldValue.arrayUnion([elementId]));
  }

  Future<void> removeMany(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_key) ?? const []).toSet();
    current.removeAll(ids);
    await _saveLocal(prefs, current);
    await _updateCloud(FieldValue.arrayRemove(ids.toList()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    final document = _userDocument;
    if (document == null) return;

    try {
      await document.set({
        'wrongElementIds': <String>[],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on Object {
      // The local list is still cleared when Firestore is unavailable.
    }
  }

  DocumentReference<Map<String, dynamic>>? get _userDocument {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore.collection('users').doc(user.uid);
  }

  Future<void> _saveLocal(
    SharedPreferences prefs,
    Set<String> ids,
  ) {
    return prefs.setStringList(_key, ids.toList()..sort());
  }

  Future<void> _updateCloud(FieldValue operation) async {
    final document = _userDocument;
    if (document == null) return;

    try {
      await document.set({
        'wrongElementIds': operation,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on Object {
      // A later read merges the local and remote review lists.
    }
  }
}
