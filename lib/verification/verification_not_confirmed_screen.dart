import 'package:flutter/material.dart';
import '../models/verification_case.dart';
import '../services/verification_store.dart';
import 'verification_widgets.dart';
import 'verification_final_screen.dart';

class VerificationNotConfirmedScreen extends StatefulWidget {
  final VerificationCase verificationCase;

  const VerificationNotConfirmedScreen({super.key, required this.verificationCase});

  @override
  State<VerificationNotConfirmedScreen> createState() =>
      _VerificationNotConfirmedScreenState();
}

class _VerificationNotConfirmedScreenState
    extends State<VerificationNotConfirmedScreen> {
  final _metPersonCtrl = TextEditingController();
  String? _whoIsThat;
  String? _residenceConfirmation;
  String? _totalFloors;
  String? _addressFloor;
  final _landAreaCtrl = TextEditingController();
  String? _locality;
  final _commentsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final c = widget.verificationCase;
    _metPersonCtrl.text = c.metPersonName;
    _whoIsThat = _opt(c.whoIsThat);
    _residenceConfirmation = _opt(c.residenceConfirmationB2);
    _totalFloors = _opt(c.totalFloorsB2);
    _addressFloor = _opt(c.addressFloorB2);
    _landAreaCtrl.text = c.landAreaB2;
    _locality = _opt(c.localityB2);
    _commentsCtrl.text = c.commentsB2;
  }

  String? _opt(String value) => value.isEmpty ? null : value;

  void _next() {
    final c = widget.verificationCase;
    c.metPersonName = _metPersonCtrl.text;
    c.whoIsThat = _whoIsThat ?? '';
    c.residenceConfirmationB2 = _residenceConfirmation ?? '';
    c.totalFloorsB2 = _totalFloors ?? '';
    c.addressFloorB2 = _addressFloor ?? '';
    c.landAreaB2 = _landAreaCtrl.text;
    c.localityB2 = _locality ?? '';
    c.commentsB2 = _commentsCtrl.text;
    c.generatedRemarks = c.buildNotConfirmedRemarks();
    c.finalStatus = 'Traced — Not Confirmed';

    VerificationStore.instance.saveDraft(c, 6);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VerificationFinalScreen(verificationCase: c)),
    );
  }

  @override
  void dispose() {
    _metPersonCtrl.dispose();
    _landAreaCtrl.dispose();
    _commentsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VStepScaffold(
      title: 'Additional Details',
      nextLabel: 'Finish',
      onNext: _next,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VLabeledField(label: 'Met Person Name', controller: _metPersonCtrl),
          VOptionGroup(
            label: 'Who is That',
            options: const ['Owner of property', 'Tenant', 'Any other'],
            value: _whoIsThat,
            onChanged: (v) => setState(() => _whoIsThat = v),
          ),
          VOptionGroup(
            label: 'Applicant Residence Confirmation',
            options: const [
              'Not residing at given address', 'Shifted from given address', 'Any other',
            ],
            value: _residenceConfirmation,
            onChanged: (v) => setState(() => _residenceConfirmation = v),
          ),
          VOptionGroup(
            label: 'Total Floors',
            options: const [
              'Only ground floor', 'Ground to 1st', 'Ground to 2nd',
              'Ground to 3rd', 'Ground to 4th', 'Any other',
            ],
            value: _totalFloors,
            onChanged: (v) => setState(() => _totalFloors = v),
          ),
          VOptionGroup(
            label: 'Address Exists on Which Floor',
            options: const ['Ground', '1st', '2nd', '3rd', '4th', 'Any other'],
            value: _addressFloor,
            onChanged: (v) => setState(() => _addressFloor = v),
          ),
          VLabeledField(label: 'Land Area', controller: _landAreaCtrl),
          VOptionGroup(
            label: 'Locality of Address',
            options: const [
              'Middle class', 'Lower middle class', 'Upper middle class',
              'Posh area', 'Village area', 'Slum locality', 'Any other',
            ],
            value: _locality,
            onChanged: (v) => setState(() => _locality = v),
          ),
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