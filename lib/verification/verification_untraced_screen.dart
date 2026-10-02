import 'package:flutter/material.dart';
import '../models/verification_case.dart';
import '../services/verification_store.dart';
import 'verification_widgets.dart';
import 'verification_final_screen.dart';

class VerificationUntracedScreen extends StatefulWidget {
  final VerificationCase verificationCase;

  const VerificationUntracedScreen({super.key, required this.verificationCase});

  @override
  State<VerificationUntracedScreen> createState() =>
      _VerificationUntracedScreenState();
}

class _VerificationUntracedScreenState
    extends State<VerificationUntracedScreen> {
  String? _reason;
  String? _requireToTrace;
  String? _callingResponse;
  final _lastLocationCtrl = TextEditingController();
  final _commentsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final c = widget.verificationCase;
    _reason = _opt(c.reasonOfUntraced);
    _requireToTrace = _opt(c.requireToTrace);
    _callingResponse = _opt(c.callingResponse);
    _lastLocationCtrl.text = c.lastLocation;
    _commentsCtrl.text = c.untracedComments;
  }

  String? _opt(String value) => value.isEmpty ? null : value;

  void _next() {
    final c = widget.verificationCase;
    c.reasonOfUntraced = _reason ?? '';
    c.requireToTrace = _requireToTrace ?? '';
    c.callingResponse = _callingResponse ?? '';
    c.lastLocation = _lastLocationCtrl.text;
    c.untracedComments = _commentsCtrl.text;
    c.generatedRemarks = c.buildUntracedRemarks();
    c.finalStatus = 'Untraced';

    VerificationStore.instance.saveDraft(c, 7);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VerificationFinalScreen(verificationCase: c)),
    );
  }

  @override
  void dispose() {
    _lastLocationCtrl.dispose();
    _commentsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VStepScaffold(
      title: 'Untraced Details',
      nextLabel: 'Finish',
      onNext: _next,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VOptionGroup(
            label: 'Reason of Untraced',
            options: const [
              'Address is incomplete',
              'Address exists in slum location',
              'Address is not in sequence',
              'Any other',
            ],
            value: _reason,
            onChanged: (v) => setState(() => _reason = v),
          ),
          VOptionGroup(
            label: 'Require to Trace',
            options: const [
              'Required street number',
              'Required landmark',
              'Any other',
            ],
            value: _requireToTrace,
            onChanged: (v) => setState(() => _requireToTrace = v),
          ),
          VOptionGroup(
            label: 'Calling Response',
            options: const [
              'Did not pick the call',
              'Number was not reachable',
              'Number was switched off',
              'Any other',
            ],
            value: _callingResponse,
            onChanged: (v) => setState(() => _callingResponse = v),
          ),
          VLabeledField(label: 'Last Location', controller: _lastLocationCtrl),
          VLabeledField(
            label: 'Other Observation / Verifier Comments',
            controller: _commentsCtrl,
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}