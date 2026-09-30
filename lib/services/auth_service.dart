import 'package:firebase_auth/firebase_auth.dart';
import 'app_settings.dart';
import 'database_service.dart';
import 'device_service.dart';
import 'notification_store.dart';
import 'push_service.dart';
import 'verification_store.dart';

/// Staff accounts are created from the admin panel (Auth + RTDB `staff/{uid}`).
/// App has NO register. Login only.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _db = DatabaseService();
  final DeviceService _deviceService = DeviceService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Sign in with admin-set email/password, then confirm the uid exists
  /// under `staff/` in RTDB with role == staff. Else sign out + throw.
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user;
    if (user == null) return null;

    Map<String, dynamic>? staff;
    try {
      staff = await _db.getStaff(user.uid);
    } catch (_) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'staff-check-failed',
        message: 'Could not verify staff account. Try again.',
      );
    }

    if (staff == null || staff['role'] != 'staff') {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'not-staff',
        message: 'This account is not registered as staff.',
      );
    }

    // Device lock: first login binds device to staff node,
    // later logins must match.
    try {
      final currentDeviceId = await _deviceService.getDeviceId();
      final savedDeviceId = staff['deviceId'] as String?;

      if (savedDeviceId == null || savedDeviceId.isEmpty) {
        await _db.setStaffDeviceId(user.uid, currentDeviceId);
      } else if (savedDeviceId != currentDeviceId) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'device-mismatch',
          message: 'This account is registered on a different device.',
        );
      }
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'device-check-failed',
        message: 'Could not verify device. Try again.',
      );
    }

    AppSettings.instance.displayName.value =
        (staff['name'] as String?) ?? user.displayName ?? '';
    await PushService.instance.registerCurrentUser();
    VerificationStore.instance.start();
    NotificationStore.instance.start();
    return user;
  }

  /// Call on app start when a session already exists.
  /// Returns null if ok. Returns error message (and signs out) if the
  /// account is no longer valid staff or device differs from saved one.
  /// Network error / timeout -> keep session (returns null).
  Future<String?> verifyDevice() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    Map<String, dynamic>? staff;
    try {
      staff = await _db.getStaff(user.uid).timeout(const Duration(seconds: 10));
    } catch (_) {
      return null; // offline: don't lock user out
    }

    if (staff == null || staff['role'] != 'staff') {
      await logout();
      return 'This account is not registered as staff.';
    }

    final savedDeviceId = staff['deviceId'] as String?;
    if (savedDeviceId != null && savedDeviceId.isNotEmpty) {
      String currentDeviceId;
      try {
        currentDeviceId = await _deviceService.getDeviceId();
      } catch (_) {
        return null;
      }
      if (savedDeviceId != currentDeviceId) {
        await logout();
        return 'This account is registered on a different device.';
      }
    }

    AppSettings.instance.displayName.value =
        (staff['name'] as String?) ?? user.displayName ?? '';
    await PushService.instance.registerCurrentUser();
    VerificationStore.instance.start();
    NotificationStore.instance.start();
    return null;
  }

  /// Load staff name into AppSettings for already-signed-in user (app start).
  Future<void> loadCurrentStaffName() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final staff = await _db.getStaff(user.uid);
      AppSettings.instance.displayName.value =
          (staff?['name'] as String?) ?? user.displayName ?? '';
    } catch (_) {
      AppSettings.instance.displayName.value = user.displayName ?? '';
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateName(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(name);
    await _db.updateStaffName(user.uid, name);
    AppSettings.instance.displayName.value = name;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'You need to be signed in to change your password.',
      );
    }
    final cred = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);
  }

  Future<void> logout() async {
    try {
      await PushService.instance.clearCurrentUser();
    } catch (_) {}
    VerificationStore.instance.stop();
    NotificationStore.instance.stop();
    await _auth.signOut();
    AppSettings.instance.displayName.value = '';
    AppSettings.instance.homeTabIndex.value = 0;
  }
}