import 'package:hive_flutter/hive_flutter.dart';

import '../models/verification_case.dart';

/// Local, on-device persistence for the verification flow.
///
/// Two boxes are used:
///  - drafts: an in-progress verification, updated after every step so data
///    survives an app kill while offline.
///  - pending: completed verifications waiting to be pushed to Firebase.
class LocalStorageService {
  LocalStorageService._();

  static final LocalStorageService instance = LocalStorageService._();

  static const String _draftsBoxName = 'unican_verification_drafts';
  static const String _pendingBoxName = 'unican_pending_sync';

  bool _ready = false;
  Box? _drafts;
  Box? _pending;

  bool get isReady => _ready;

  Future<void> init() async {
    if (_ready) return;
    await Hive.initFlutter();
    _drafts = await Hive.openBox(_draftsBoxName);
    _pending = await Hive.openBox(_pendingBoxName);
    _ready = true;
  }

  // ---- In-progress drafts -------------------------------------------------

  Future<void> saveDraft({
    required String key,
    required String uid,
    required VerificationCase value,
    required int step,
  }) async {
    await _ensure();
    await _drafts!.put(key, <String, dynamic>{
      'uid': uid,
      'step': step,
      'case': value.toMap(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Map<String, dynamic>? getDraft(String key) {
    final raw = _drafts?.get(key);
    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw);
  }

  Future<void> deleteDraft(String key) async {
    await _drafts?.delete(key);
  }

  // ---- Pending cloud sync -------------------------------------------------

  /// [record] holds at least: key, id, uid, case (map), attempts, lastError.
  Future<void> putPending(String key, Map<String, dynamic> record) async {
    await _ensure();
    await _pending!.put(key, record);
  }

  Map<String, dynamic>? getPending(String key) {
    final raw = _pending?.get(key);
    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw);
  }

  List<Map<String, dynamic>> allPending() {
    final box = _pending;
    if (box == null) return const <Map<String, dynamic>>[];
    final items = <Map<String, dynamic>>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is Map) items.add(Map<String, dynamic>.from(raw));
    }
    return items;
  }

  int get pendingCount => _pending?.length ?? 0;

  Future<void> deletePending(String key) async {
    await _pending?.delete(key);
  }

  Future<void> _ensure() async {
    if (!_ready) await init();
  }
}
