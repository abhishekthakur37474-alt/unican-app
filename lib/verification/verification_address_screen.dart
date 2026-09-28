import 'package:flutter/material.dart';
import '../models/assigned_address.dart';
import '../models/verification_case.dart';
import 'verification_widgets.dart';
import 'verification_media_screen.dart';

class VerificationAddressScreen extends StatefulWidget {
  final AssignedAddress assignedAddress;

  const VerificationAddressScreen({
    super.key,
    required this.assignedAddress,
  });

  @override
  State<VerificationAddressScreen> createState() =>
      _VerificationAddressScreenState();
}

class _VerificationAddressScreenState
    extends State<VerificationAddressScreen> {
  late final VerificationCase _case;
  String? _tracedChoice;

  @override
  void initState() {
    super.initState();
    final assigned = widget.assignedAddress;
    _case = VerificationCase(
      address: assigned.fullAddress,
      applicantName: assigned.applicantName,
      caseId: assigned.caseId,
      clientName: assigned.clientName,
      phone: assigned.phone,
      firebaseKey: assigned.id,
    );
  }

  void _next() {
    if (_tracedChoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select Traced or Untraced first')),
      );
      return;
    }

    _case.traced = _tracedChoice == 'Traced';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerificationMediaScreen(verificationCase: _case),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assigned = widget.assignedAddress;

    return VStepScaffold(
      title: 'Residence Verification',
      onNext: _next,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (assigned.applicantName.isNotEmpty || assigned.caseId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (assigned.applicantName.isNotEmpty)
                    Text(
                      assigned.applicantName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (assigned.caseId.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      assigned.caseId,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (assigned.clientName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      assigned.clientName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          Text(
            'Given Address',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(_case.address, style: theme.textTheme.bodyLarge),
          ),
          if (assigned.phone.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              assigned.phone,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 24),
          VOptionGroup(
            label: 'Was the address traced?',
            options: const ['Traced', 'Untraced'],
            value: _tracedChoice,
            onChanged: (v) => setState(() => _tracedChoice = v),
          ),
        ],
      ),
    );
  }
}
