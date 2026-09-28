class StaffNotification {
  final String id;
  final String address;
  final String applicantName;
  final String caseId;
  final String clientName;
  final String message;
  final String phone;
  final String priority;
  final bool read;
  final String verificationType;
  final DateTime? timestamp;

  StaffNotification({
    required this.id,
    required this.address,
    required this.applicantName,
    required this.caseId,
    required this.clientName,
    required this.message,
    required this.phone,
    required this.priority,
    required this.read,
    required this.verificationType,
    this.timestamp,
  });

  factory StaffNotification.fromMap(String id, Map<String, dynamic> map) {
    return StaffNotification(
      id: id,
      address: _asString(map['address']),
      applicantName: _asString(map['applicantName']),
      caseId: _asString(map['caseId']),
      clientName: _asString(map['clientName']),
      message: _asString(map['message']),
      phone: _asString(map['phone']),
      priority: _asString(map['priority']),
      read: map['read'] == true,
      verificationType: _asString(map['verificationType']),
      timestamp: _asDate(map['timestamp']),
    );
  }
}

String _asString(dynamic value) => value?.toString() ?? '';

DateTime? _asDate(dynamic value) {
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}
