import 'package:firebase_database/firebase_database.dart';

/// RTDB node structure:
/// root
///  └── users
///       └── {uid}
///            ├── name: String
///            ├── email: String
///            ├── deviceId: String
///            └── createdAt: int (millisSinceEpoch)
class DatabaseService {
  final DatabaseReference _root = FirebaseDatabase.instance.ref();

  Future<void> createUserNode({
    required String uid,
    required String name,
    required String email,
    required String deviceId,
  }) async {
    await _root.child('users').child(uid).set({
      'name': name,
      'email': email,
      'deviceId': deviceId,
      'createdAt': ServerValue.timestamp,
    });
  }

  Future<Map<dynamic, dynamic>?> getUser(String uid) async {
    final snap = await _root.child('users').child(uid).get();
    if (snap.exists) {
      return snap.value as Map<dynamic, dynamic>;
    }
    return null;
  }

  Future<void> updateUserName(String uid, String name) async {
    await _root.child('users').child(uid).update({'name': name});
  }
}