import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../models/verification_case.dart';
import 'database_service.dart';
import 'imgbb_service.dart';
import 'local_storage_service.dart';

/// Offline-first sync engine.
///
/// Finished verifications are written to Hive first (see [LocalStorageService]).
/// [enqueue] then tries to push them to Firebase. If the device is offline (or
/// a photo upload fails) the record stays queued and is retried automatically
/// as soon as connectivity comes back.
class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();

  final DatabaseService _db = DatabaseService();
  final LocalStorageService _local = LocalStorageService.instance;
  final ImgbbService _imgbb = ImgbbService.instance;

  /// Number of verifications still waiting to reach Firebase.
  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);

  /// Whether the device currently has a network connection.
  final ValueNotifier<bool> online = ValueNotifier<bool>(true);

  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _initialized = false;
  bool _syncing = false;

  bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _local.init();
    pendingCount.value = _local.pendingCount;

    try {
      final results = await Connectivity().checkConnectivity();
      online.value = _hasConnection(results);
    } catch (_) {}

    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = _hasConnection(results);
      online.value = isOnline;
      if (isOnline) syncNow();
    });

    if (online.value) syncNow();
  }

  /// Save a finished verification to the local queue and attempt an immediate
  /// upload. The local copy is written before any network call, so nothing is
  /// lost when the device is offline.
  Future<void> enqueue(VerificationCase value, {required String uid}) async {
    await _local.init();

    final key = value.localKey;
    final existing = _local.getPending(key);

    await _local.putPending(key, <String, dynamic>{
      'key': key,
      'id': value.id,
      'uid': uid,
      'case': value.toMap(),
      'uploadedCount': existing?['uploadedCount'] ?? 0,
      'attempts': existing?['attempts'] ?? 0,
      'lastError': '',
      'updatedAt': DateTime.now().toIso8601String(),
    });
    pendingCount.value = _local.pendingCount;

    await syncNow();
  }

  /// Flush every queued verification to Firebase. Safe to call repeatedly;
  /// concurrent calls are ignored.
  Future<void> syncNow() async {
    if (_syncing) return;
    if (!_local.isReady) await _local.init();

    // Everything stays queued in Hive until the device is actually online.
    if (!online.value) {
      pendingCount.value = _local.pendingCount;
      return;
    }

    _syncing = true;
    try {
      for (final record in _local.allPending()) {
        await _syncRecord(record);
      }
    } finally {
      _syncing = false;
      pendingCount.value = _local.pendingCount;
    }
  }

  Future<void> _syncRecord(Map<String, dynamic> record) async {
    final key = (record['key'] ?? '').toString();
    final uid = (record['uid'] ?? '').toString();
    final rawCase = record['case'];

    if (key.isEmpty || uid.isEmpty || rawCase is! Map) {
      if (key.isNotEmpty) await _local.deletePending(key);
      return;
    }

    final caseMap = Map<String, dynamic>.from(rawCase);
    final value = VerificationCase.fromMap(
      (record['id'] ?? caseMap['id'] ?? '').toString(),
      caseMap,
    );

    // 1) Upload any photos that are not hosted yet.
    if (_imgbb.isConfigured && value.photoPaths.isNotEmpty) {
      var already = (record['uploadedCount'] as num?)?.toInt() ?? 0;
      // A previously synced edit already carries hosted URLs.
      if (value.photoUrls.length > already) already = value.photoUrls.length;
      if (already < value.photoPaths.length) {
        final urls = List<String>.from(value.photoUrls);
        var uploaded = already;
        var failed = false;

        for (var i = already; i < value.photoPaths.length; i++) {
          final url = await _imgbb.upload(value.photoPaths[i]);
          if (url == null) {
            failed = true;
            break;
          }
          urls.add(url);
          uploaded = i + 1;
        }

        value.photoUrls
          ..clear()
          ..addAll(urls);
        record['case'] = value.toMap();
        record['uploadedCount'] = uploaded;
        record['attempts'] = ((record['attempts'] as num?)?.toInt() ?? 0) + 1;
        record['updatedAt'] = DateTime.now().toIso8601String();

        if (failed) {
          record['lastError'] = 'Photo upload failed';
          await _local.putPending(key, record);
          return; // retry when connectivity is available again
        }
        await _local.putPending(key, record);
      }
    }

    // 2) Push the record to Firebase Realtime Database.
    try {
      await _db.saveCompletedCase(uid, value);
      if (value.firebaseKey.isNotEmpty) {
        await _db.updateAddressStatus(value.firebaseKey, 'Completed');
      }
      await _local.deletePending(key);
    } catch (e) {
      record['attempts'] = ((record['attempts'] as num?)?.toInt() ?? 0) + 1;
      record['lastError'] = e.toString();
      record['updatedAt'] = DateTime.now().toIso8601String();
      await _local.putPending(key, record);
    }
  }

  /// True when a finished verification for [key] is still waiting to sync.
  bool isPending(String key) => _local.getPending(key) != null;

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
