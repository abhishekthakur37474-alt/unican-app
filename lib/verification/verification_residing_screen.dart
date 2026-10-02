import 'package:flutter/material.dart';
import '../models/verification_case.dart';
import '../services/verification_store.dart';
import 'verification_widgets.dart';
import 'verification_confirmed_screen.dart';
import 'verification_not_confirmed_screen.dart';

class VerificationResidingScreen extends StatefulWidget {
  final VerificationCase verificationCase;

  const VerificationResidingScreen({super.key, required this.verificationCase});

  @override
  State<VerificationResidingScreen> createState() =>
      _VerificationResidingScreenState();
}

class _VerificationResidingScreenState
    extends State<VerificationResidingScreen> {
  String? _choice;

  @override
  void initState() {
    super.initState();
    final residing = widget.verificationCase.applicantResidingThere;
    _choice = residing == null ? null : (residing ? 'Yes' : 'No');
  }

  void _next() {
    if (_choice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select Yes or No')),
      );
      return;
    }

    final c = widget.verificationCase;
    c.applicantResidingThere = _choice == 'Yes';

    if (c.applicantResidingThere!) {
      VerificationStore.instance.saveDraft(c, 4);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerificationConfirmedScreen(verificationCase: c),
        ),
      );
      return;
    }

    VerificationStore.instance.saveDraft(c, 6);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerificationNotConfirmedScreen(verificationCase: c),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return VStepScaffold(
      title: 'Applicant Residing',
      onNext: _next,
      child: VOptionGroup(
        label: 'Applicant Residing There?',
        options: const ['Yes', 'No'],
        value: _choice,
        onChanged: (v) => setState(() => _choice = v),
      ),
    );
  }
}