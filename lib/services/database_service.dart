import 'package:firebase_database/firebase_database.dart';

/// RTDB node structure (staff created from admin panel):
/// root
///  └── staff
///       └── {uid}
///            ├── uid: String
///            ├── name: String
///            ├── email: String
///            ├── role: String   ("staff")
///            ├── deviceId: String (bound on first login)
///            └── createdAt: String (ISO)
class DatabaseService {
  final DatabaseReference _root = FirebaseDatabase.instance.ref();

  /// Returns staff record for uid, or null if not a staff member.
  Future<Map<String, dynamic>?> getStaff(String uid) async {
    final snap = await _root.child('staff').child(uid).get();
    if (!snap.exists || snap.value is! Map) return null;
    return Map<String, dynamic>.from(snap.value as Map);
  }

  Future<void> setStaffDeviceId(String uid, String deviceId) async {
    await _root.child('staff').child(uid).update({'deviceId': deviceId});
  }

  Future<void> updateStaffName(String uid, String name) async {
    await _root.child('staff').child(uid).update({'name': name});
  }
}