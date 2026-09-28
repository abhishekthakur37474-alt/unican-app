import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/verification_case.dart';
import 'database_service.dart';

class VerificationStore {
  VerificationStore._();

  static final VerificationStore instance = VerificationStore._();

  final DatabaseService _db = DatabaseService();
  final ValueNotifier<List<VerificationCase>> cases =
      ValueNotifier<List<VerificationCase>>(<VerificationCase>[]);

  StreamSubscription<List<VerificationCase>>? _sub;

  void start() {
    stop();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      cases.value = <VerificationCase>[];
      return;
    }
    _sub = _db.watchCompletedCases(uid).listen(
      (items) => cases.value = items,
      onError: (_) {},
    );
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    cases.value = <VerificationCase>[];
  }

  Future<void> save(VerificationCase value) async {
    final list = List<VerificationCase>.from(cases.value);
    final index = list.indexWhere((e) => e.id == value.id);
    if (index >= 0) {
      list[index] = value;
    } else {
      list.insert(0, value);
    }
    cases.value = list;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.saveCompletedCase(uid, value);
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
  }

  void clear() {
    stop();
  }

  List<VerificationCase> get favorites =>
      cases.value.where((e) => e.isFavorite).toList();
}
