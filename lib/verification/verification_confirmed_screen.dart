import 'package:flutter/material.dart';
import '../models/verification_case.dart';
import '../services/verification_store.dart';
import 'verification_widgets.dart';
import 'verification_final_screen.dart';

class VerificationConfirmedScreen extends StatefulWidget {
  final VerificationCase verificationCase;

  const VerificationConfirmedScreen({super.key, required this.verificationCase});

  @override
  State<VerificationConfirmedScreen> createState() =>
      _VerificationConfirmedScreenState();
}

class _VerificationConfirmedScreenState
    extends State<VerificationConfirmedScreen> {
  final _metPersonCtrl = TextEditingController();
  String? _relation;
  String? _residenceConfirmation;
  final _tenureCtrl = TextEditingController();
  String? _ownership;
  final _rentCtrl = TextEditingController();
  final _landlordCtrl = TextEditingController();
  String? _building;
  String? _totalFloors;
  String? _applicantFloor;
  final _landAreaCtrl = TextEditingController();
  String? _locality;
  String? _document;
  String? _familyMembers;
  String? _earners;
  final _commentsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final c = widget.verificationCase;
    _metPersonCtrl.text = c.metPersonName;
    _relation = _opt(c.relationWithApplicant);
    _residenceConfirmation = _opt(c.residenceConfirmation);
    _tenureCtrl.text = c.tenureOfResidence;
    _ownership = _opt(c.ownershipOfResidence);
    _rentCtrl.text = c.rentAmount;
    _landlordCtrl.text = c.landlordName;
    _building = _opt(c.buildingDescription);
    _totalFloors = _opt(c.totalFloors);
    _applicantFloor = _opt(c.applicantFloor);
    _landAreaCtrl.text = c.landArea;
    _locality = _opt(c.localityOfAddress);
    _document = _opt(c.documentShown);
    _familyMembers = _opt(c.totalFamilyMembers);
    _earners = _opt(c.numberOfEarners);
    _commentsCtrl.text = c.verifierComments;
  }

  String? _opt(String value) => value.isEmpty ? null : value;

  void _next() {
    final c = widget.verificationCase;
    c.metPersonName = _metPersonCtrl.text;
    c.relationWithApplicant = _relation ?? '';
    c.residenceConfirmation = _residenceConfirmation ?? '';
    c.tenureOfResidence = _tenureCtrl.text;
    c.ownershipOfResidence = _ownership ?? '';
    c.rentAmount = _rentCtrl.text;
    c.landlordName = _landlordCtrl.text;
    c.buildingDescription = _building ?? '';
    c.totalFloors = _totalFloors ?? '';
    c.applicantFloor = _applicantFloor ?? '';
    c.landArea = _landAreaCtrl.text;
    c.localityOfAddress = _locality ?? '';
    c.documentShown = _document ?? '';
    c.totalFamilyMembers = _familyMembers ?? '';
    c.numberOfEarners = _earners ?? '';
    c.verifierComments = _commentsCtrl.text;
    c.applicantResidingThere ??=
        !(_residenceConfirmation ?? '').toLowerCase().contains('not residing');
    c.generatedRemarks = c.buildConfirmedRemarks();
    c.finalStatus = c.applicantResidingThere!
        ? 'Traced — Confirmed — Residing'
        : 'Traced — Confirmed — Not Residing';

    VerificationStore.instance.saveDraft(c, 4);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerificationFinalScreen(verificationCase: c),
      ),
    );
  }

  @override
  void dispose() {
    _metPersonCtrl.dispose();
    _tenureCtrl.dispose();
    _rentCtrl.dispose();
    _landlordCtrl.dispose();
    _landAreaCtrl.dispose();
    _commentsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VStepScaffold(
      title: 'Residence Details',
      onNext: _next,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VLabeledField(label: 'Met Person Name', controller: _metPersonCtrl),
          VDropdown(
            label: 'Relation with the Applicant',
            options: const [
              'Self',
              'Spouse',
              'Brother',
              'Sister',
              'Father',
              'Mother',
              'Son',
              'Any other',
            ],
            value: _relation,
            onChanged: (v) => setState(() => _relation = v),
          ),
          VDropdown(
            label: 'Applicant Residence Confirmation',
            options: const ['Residing here', 'Not residing here', 'Any other'],
            value: _residenceConfirmation,
            onChanged: (v) => setState(() => _residenceConfirmation = v),
          ),
          VLabeledField(label: 'Tenure of Residence', controller: _tenureCtrl),
          VDropdown(
            label: 'Ownership of Residence',
            options: const [
              'Owned',
              'Rented',
              'Parental owned',
              'Company provided',
              'Relative owned',
              'Govt. provided',
              'Any other',
            ],
            value: _ownership,
            onChanged: (v) => setState(() => _ownership = v),
          ),
          if (_ownership == 'Rented') ...[
            VLabeledField(label: 'Rent Amount', controller: _rentCtrl),
            VLabeledField(label: 'Landlord Name', controller: _landlordCtrl),
          ],
          VDropdown(
            label: 'Building Description',
            options: const [
              'Flat',
              'Independent house',
              'Kothi',
              'Apartment',
              'T-Huts',
              'Any other',
            ],
            value: _building,
            onChanged: (v) => setState(() => _building = v),
          ),
          VDropdown(
            label: 'Total Floors',
            options: const [
              'Only ground floor',
              'Ground to 1st',
              'Ground to 2nd',
              'Ground to 3rd',
              'Ground to 4th',
              'Any other',
            ],
            value: _totalFloors,
            onChanged: (v) => setState(() => _totalFloors = v),
          ),
          VDropdown(
            label: 'Applicant Residing on Which Floor',
            options: const ['Ground', '1st', '2nd', '3rd', '4th', 'Any other'],
            value: _applicantFloor,
            onChanged: (v) => setState(() => _applicantFloor = v),
          ),
          VLabeledField(label: 'Land Area', controller: _landAreaCtrl),
          VDropdown(
            label: 'Locality of Address',
            options: const [
              'Middle class',
              'Lower middle class',
              'Upper middle class',
              'Posh area',
              'Village area',
              'Slum locality',
              'Any other',
            ],
            value: _locality,
            onChanged: (v) => setState(() => _locality = v),
          ),
          VDropdown(
            label: 'Document Shown by Met Person',
            options: const ['PAN card', 'Aadhar card', 'E-bill', 'Any other'],
            value: _document,
            onChanged: (v) => setState(() => _document = v),
          ),
          VDropdown(
            label: 'Total Family Members',
            options: const ['1', '2', '3', '4', 'Joint family', 'Any other'],
            value: _familyMembers,
            onChanged: (v) => setState(() => _familyMembers = v),
          ),
          VDropdown(
            label: 'Number of Earners',
            options: const ['1', '2', '3', '4', 'Any other'],
            value: _earners,
            onChanged: (v) => setState(() => _earners = v),
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