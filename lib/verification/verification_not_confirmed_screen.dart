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
  static const _whoOptions = ['Owner of property', 'Tenant', 'Any other'];
  static const _residenceOptions = [
    'Not residing at given address',
    'Shifted from given address',
    'Any other',
  ];
  static const _floorOptions = [
    'Only ground floor',
    'Ground to 1st floor',
    'Ground to 2nd floor',
    'Ground to 3rd floor',
    'Ground to 4th floor',
    'Any other',
  ];
  static const _addressFloorOptions = [
    'Ground Floor',
    '1st Floor',
    '2nd Floor',
    '3rd Floor',
    '4th Floor',
    'Any other',
  ];
  static const _localityOptions = [
    'Middle class',
    'Lower middle class',
    'Upper middle class',
    'Posh area',
    'Village Area',
    'Slum locality',
    'Any other',
  ];

  final _metPersonCtrl = TextEditingController();
  String? _whoIsThat;
  final _whoOtherCtrl = TextEditingController();
  String? _residenceConfirmation;
  final _residenceOtherCtrl = TextEditingController();
  String? _totalFloors;
  final _floorsOtherCtrl = TextEditingController();
  String? _addressFloor;
  final _addressFloorOtherCtrl = TextEditingController();
  final _landAreaCtrl = TextEditingController();
  String? _locality;
  final _localityOtherCtrl = TextEditingController();
  final _commentsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final c = widget.verificationCase;
    _metPersonCtrl.text = c.metPersonName;
    _whoIsThat = _matchOrOther(c.whoIsThat, _whoOptions, _whoOtherCtrl);
    _residenceConfirmation = _matchOrOther(
      c.residenceConfirmationB2,
      _residenceOptions,
      _residenceOtherCtrl,
    );
    _totalFloors = _matchOrOther(
      c.totalFloorsB2,
      _floorOptions,
      _floorsOtherCtrl,
    );
    _addressFloor = _matchOrOther(
      c.addressFloorB2,
      _addressFloorOptions,
      _addressFloorOtherCtrl,
    );
    _landAreaCtrl.text = c.landAreaB2;
    _locality = _matchOrOther(c.localityB2, _localityOptions, _localityOtherCtrl);
    _commentsCtrl.text = c.commentsB2;
  }

  String? _matchOrOther(
    String value,
    List<String> options,
    TextEditingController otherCtrl,
  ) {
    if (value.isEmpty) return null;
    if (options.contains(value)) return value;
    otherCtrl.text = value;
    return 'Any other';
  }

  bool _isOther(String? value) =>
      (value ?? '').toLowerCase() == 'any other';

  String _resolved(String? value, TextEditingController otherCtrl) {
    if (_isOther(value)) {
      final extra = otherCtrl.text.trim();
      return extra.isEmpty ? 'Any other' : extra;
    }
    return value ?? '';
  }

  void _next() {
    final c = widget.verificationCase;
    c.metPersonName = _metPersonCtrl.text;
    c.whoIsThat = _resolved(_whoIsThat, _whoOtherCtrl);
    c.residenceConfirmationB2 =
        _resolved(_residenceConfirmation, _residenceOtherCtrl);
    c.totalFloorsB2 = _resolved(_totalFloors, _floorsOtherCtrl);
    c.addressFloorB2 = _resolved(_addressFloor, _addressFloorOtherCtrl);
    c.landAreaB2 = _landAreaCtrl.text;
    c.localityB2 = _resolved(_locality, _localityOtherCtrl);
    c.commentsB2 = _commentsCtrl.text;
    c.applicantResidingThere = false;
    c.generatedRemarks = c.buildNotConfirmedRemarks();
    c.finalStatus = 'Traced — Not Confirmed — Not Residing';

    VerificationStore.instance.saveDraft(c, 6);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VerificationFinalScreen(verificationCase: c)),
    );
  }

  @override
  void dispose() {
    _metPersonCtrl.dispose();
    _whoOtherCtrl.dispose();
    _residenceOtherCtrl.dispose();
    _floorsOtherCtrl.dispose();
    _addressFloorOtherCtrl.dispose();
    _landAreaCtrl.dispose();
    _localityOtherCtrl.dispose();
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
          VDropdown(
            label: 'Who is That',
            options: _whoOptions,
            value: _whoIsThat,
            onChanged: (v) => setState(() => _whoIsThat = v),
          ),
          if (_isOther(_whoIsThat))
            VLabeledField(label: 'Please specify', controller: _whoOtherCtrl),
          VDropdown(
            label: 'Applicant Residence Confirmation',
            options: _residenceOptions,
            value: _residenceConfirmation,
            onChanged: (v) => setState(() => _residenceConfirmation = v),
          ),
          if (_isOther(_residenceConfirmation))
            VLabeledField(
              label: 'Please specify',
              controller: _residenceOtherCtrl,
            ),
          VDropdown(
            label: 'Total Floors',
            options: _floorOptions,
            value: _totalFloors,
            onChanged: (v) => setState(() => _totalFloors = v),
          ),
          if (_isOther(_totalFloors))
            VLabeledField(label: 'Please specify', controller: _floorsOtherCtrl),
          VDropdown(
            label: 'Address Exists on Which Floor',
            options: _addressFloorOptions,
            value: _addressFloor,
            onChanged: (v) => setState(() => _addressFloor = v),
          ),
          if (_isOther(_addressFloor))
            VLabeledField(
              label: 'Please specify',
              controller: _addressFloorOtherCtrl,
            ),
          VLabeledField(label: 'Land Area', controller: _landAreaCtrl),
          VDropdown(
            label: 'Locality of Address',
            options: _localityOptions,
            value: _locality,
            onChanged: (v) => setState(() => _locality = v),
          ),
          if (_isOther(_locality))
            VLabeledField(
              label: 'Please specify',
              controller: _localityOtherCtrl,
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
