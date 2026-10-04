import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus { pending, confirmed, rejected, cancelled, completed }

extension AppointmentStatusX on AppointmentStatus {
  String get label => switch (this) {
    AppointmentStatus.pending => 'Onay Bekliyor',
    AppointmentStatus.confirmed => 'Onaylandı',
    AppointmentStatus.rejected => 'Reddedildi.',
    AppointmentStatus.cancelled => 'İptal Edildi',
    AppointmentStatus.completed => 'Tamamlandı',
  };
}

class Appointment {
  const Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.treatment,
    required this.start,
    required this.status,
    required this.createdAt,
    this.patientPhone,
    this.doctorName,
    this.note,
    this.adminNote,
  });

  final String id;
  final String patientId;
  final String patientName;
  final String? patientPhone;
  final String treatment;
  final String? doctorName;
  final DateTime start;
  final AppointmentStatus status;
  final String? note;
  final String? adminNote;
  final DateTime createdAt;

  bool get isActive =>
      status == AppointmentStatus.pending ||
    status == AppointmentStatus.confirmed;

  bool get isUpcoming => isActive && start.isAfter(DateTime.now());

  factory Appointment.fromMap(Map<String, dynamic> m, String id) {
    return Appointment(
      id: id,
      patientId: m['patientId'] as String? ?? '',
      patientName: m['patientName'] as String? ?? '',
      patientPhone: m['patientPhone'] as String?,
      treatment: m['treatment'] as String? ?? '',
      doctorName: m['doctorName'] as String?,
      start: (m['start'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: AppointmentStatus.values.firstWhere(
            (s) => s.name == m['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      note: m['note'] as String?,
      adminNote: m['adminNote'] as String?,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

}