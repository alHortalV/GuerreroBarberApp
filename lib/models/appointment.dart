class Appointment {
  final String id;
  final String userId;
  final DateTime dateTime;
  final String service;
  final String? notes;

  Appointment({
    required this.id,
    required this.userId,
    required this.dateTime,
    required this.service,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'dateTime': dateTime.toIso8601String(),
      'service': service,
      'notes': notes,
    };
  }

  static Appointment fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'],
      userId: map['userId'],
      dateTime: DateTime.parse(map['dateTime']),
      service: map['service'] ?? '',
      notes: map['notes'],
    );
  }
}
