import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/verification_case.dart';
import 'database_service.dart';
import 'local_storage_service.dart';
import 'sync_service.dart';

class VerificationStore {
  VerificationStore._();

  static final VerificationStore instance = VerificationStore._();

  final DatabaseService _db = DatabaseService();
  final LocalStorageService _local = LocalStorageService.instance;

  final ValueNotifier<List<VerificationCase>> cases =
      ValueNotifier<List<VerificationCase>>(<VerificationCase>[]);

  StreamSubscription<List<VerificationCase>>? _sub;
  List<VerificationCase> _remote = <VerificationCase>[];

  void start() {
    stop();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      cases.value = <VerificationCase>[];
      return;
    }

    // Show locally queued (unsynced) cases immediately, even when offline.
    _emit();

    _sub = _db.watchCompletedCases(uid).listen(
      (items) {
        _remote = items;
        _emit();
      },
      onError: (_) {},
    );

    // Push anything left over from a previous offline session.
    SyncService.instance.syncNow();
  }

  /// Merge the cloud list with local unsynced records. Local records win
  /// because they represent the most recent edit made on this device.
  void _emit() {
    final merged = <String, VerificationCase>{};
    // Keep whatever is already on screen so a just-saved case does not
    // flicker out while the cloud stream catches up.
    for (final item in cases.value) {
      merged[item.id] = item;
    }
    for (final item in _remote) {
      merged[item.id] = item;
    }
    for (final record in _local.allPending()) {
      final raw = record['case'];
      if (raw is! Map) continue;
      final item = VerificationCase.fromMap(
        (record['id'] ?? '').toString(),
        Map<String, dynamic>.from(raw),
      );
      merged[item.id] = item;
    }
    final list = merged.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    cases.value = list;
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _remote = <VerificationCase>[];
    cases.value = <VerificationCase>[];
  }

  /// Local-first save: the case is queued in Hive before anything is sent to
  /// Firebase, so an offline device never loses a completed verification.
  Future<void> save(VerificationCase value) async {
    _upsertMemory(value);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Queue the finished record first so a crash can never lose it, then
    // drop the in-progress draft for this case.
    await SyncService.instance.enqueue(value, uid: uid);
    try {
      await _local.deleteDraft(value.localKey);
    } catch (_) {}
    _emit();
  }

  void _upsertMemory(VerificationCase value) {
    final list = List<VerificationCase>.from(cases.value);
    final index = list.indexWhere((e) => e.id == value.id);
    if (index >= 0) {
      list[index] = value;
    } else {
      list.insert(0, value);
    }
    cases.value = list;
  }

  // ---- In-progress drafts (saved after every step) ------------------------

  Future<void> saveDraft(VerificationCase value, int step) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    try {
      await _local.saveDraft(
        key: value.localKey,
        uid: uid,
        value: value,
        step: step,
      );
    } catch (_) {}
  }

  /// Returns the stored draft for [key] when it belongs to the signed-in user.
  Map<String, dynamic>? getDraft(String key) {
    final draft = _local.getDraft(key);
    if (draft == null) return null;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if ((draft['uid'] ?? '').toString() != uid) return null;
    return draft;
  }

  Future<void> deleteDraft(String key) async {
    try {
      await _local.deleteDraft(key);
    } catch (_) {}
  }

  Future<void> toggleFavorite(VerificationCase value) async {
    value.isFavorite = !value.isFavorite;
    cases.value = List<VerificationCase>.from(cases.value);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.updateCaseFavorite(uid, value.id, value.isFavorite);
    } catch (_) {}

    // Keep the queued local copy consistent if it has not synced yet.
    final pending = _local.getPending(value.localKey);
    if (pending != null && pending['case'] is Map) {
      final map = Map<String, dynamic>.from(pending['case'] as Map);
      map['isFavorite'] = value.isFavorite;
      pending['case'] = map;
      await _local.putPending(value.localKey, pending);
    }
  }

  void clear() {
    stop();
  }

  List<VerificationCase> get favorites =>
      cases.value.where((e) => e.isFavorite).toList();
}
