import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/assigned_address.dart';
import '../models/verification_case.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'verification_address_screen.dart';

/// Shown right after a verification is completed. Offers "Start Next" when
/// another address is still assigned, otherwise sends the staff member home.
class VerificationDoneScreen extends StatefulWidget {
  final VerificationCase verificationCase;

  const VerificationDoneScreen({super.key, required this.verificationCase});

  @override
  State<VerificationDoneScreen> createState() => _VerificationDoneScreenState();
}

class _VerificationDoneScreenState extends State<VerificationDoneScreen> {
  final DatabaseService _db = DatabaseService();

  bool _loading = true;
  AssignedAddress? _next;

  @override
  void initState() {
    super.initState();
    _loadNext();
  }

  Future<void> _loadNext() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final list = await _db.getAssignedAddresses(uid);
      // Only online/assigned cases reach here. Skip the one just completed in
      // case its status has not synced back yet.
      final current = widget.verificationCase.firebaseKey;
      final next = list.where((a) => a.id != current).toList();
      if (!mounted) return;
      setState(() {
        _next = next.isEmpty ? null : next.first;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startNext() {
    final next = _next;
    if (next == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => VerificationAddressScreen(assignedAddress: next),
      ),
    );
  }

  void _goHome() {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = widget.verificationCase;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goHome();
      },
      child: Scaffold(
        body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 52,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Verification Completed',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                c.applicantName.isEmpty ? c.address : c.applicantName,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                c.finalStatus,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_next != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _startNext,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start Next Verification'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _goHome,
                  child: const Text('Back to Home'),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _goHome,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Back to Home'),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
