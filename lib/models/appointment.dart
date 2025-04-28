class Appointment {
  final String id;
  final String userId;
  final DateTime dateTime;
  final String service;
  final String? notes;
  final String userEmail;
  final String? username;
  final String? status;
  
  Appointment({
    required this.id,
    required this.userId,
    required this.dateTime,
    required this.service,
    this.notes,
    required this.userEmail,
    this.username,
    this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'dateTime': dateTime.toIso8601String(),
      'service': service,
      'notes': notes,
      'userEmail': userEmail,
      'username': username,
      'status': status,
    };
  }

  static Appointment fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'],
      userId: map['userId'],
      dateTime: DateTime.parse(map['dateTime']),
      service: map['service'] ?? '',
      notes: map['notes'],
      userEmail: map['userEmail'] ?? '',
      username: map['username'],
      status: map['status'],
    );
  }
}
