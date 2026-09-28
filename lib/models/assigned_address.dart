class AssignedAddress {
  final String id;
  final String addressLine;
  final String applicantName;
  final String assignedToStaffEmail;
  final String assignedToStaffId;
  final String assignedToStaffName;
  final String caseId;
  final String city;
  final String clientName;
  final String landmark;
  final String phone;
  final String pincode;
  final String priority;
  final String state;
  final String status;
  final String verificationType;
  final DateTime? assignedAt;
  final DateTime? createdAt;

  AssignedAddress({
    required this.id,
    required this.addressLine,
    required this.applicantName,
    required this.assignedToStaffEmail,
    required this.assignedToStaffId,
    required this.assignedToStaffName,
    required this.caseId,
    required this.city,
    required this.clientName,
    required this.landmark,
    required this.phone,
    required this.pincode,
    required this.priority,
    required this.state,
    required this.status,
    required this.verificationType,
    this.assignedAt,
    this.createdAt,
  });

  factory AssignedAddress.fromMap(String id, Map<String, dynamic> map) {
    return AssignedAddress(
      id: id,
      addressLine: _asString(map['addressLine']),
      applicantName: _asString(map['applicantName']),
      assignedToStaffEmail: _asString(map['assignedToStaffEmail']),
      assignedToStaffId: _asString(map['assignedToStaffId']),
      assignedToStaffName: _asString(map['assignedToStaffName']),
      caseId: _asString(map['caseId']),
      city: _asString(map['city']),
      clientName: _asString(map['clientName']),
      landmark: _asString(map['landmark']),
      phone: _asString(map['phone']),
      pincode: _asString(map['pincode']),
      priority: _asString(map['priority']),
      state: _asString(map['state']),
      status: _asString(map['status']),
      verificationType: _asString(map['verificationType']),
      assignedAt: _asDate(map['assignedAt']),
      createdAt: _asDate(map['createdAt']),
    );
  }

  String get fullAddress {
    final parts = <String>[
      if (addressLine.isNotEmpty) addressLine,
      if (landmark.isNotEmpty) landmark,
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
    ];
    var text = parts.join(', ');
    if (pincode.isNotEmpty) {
      text = text.isEmpty ? pincode : '$text - $pincode';
    }
    return text;
  }

  bool get isOpen {
    final value = status.toLowerCase();
    return value != 'completed' && value != 'done';
  }
}

String _asString(dynamic value) => value?.toString() ?? '';

DateTime? _asDate(dynamic value) {
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}
