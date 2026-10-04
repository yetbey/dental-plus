import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/appointment.dart';
import '../domain/clinic_schedule.dart';

class AppointmentException implements Exception {
  const AppointmentException(this.message);
  final String message;
  @override
  String toString() => message;
}

class SlotTakenException extends AppointmentException {
  const SlotTakenException() : super('Bu saat az önce doldu. Lütfen başka bir saat seçin.');
}

class AppointmentRepository {
  AppointmentRepository(this._db);

  final FirebaseFirestore _db;
  static const maxActivePerPatient = 3;

  CollectionReference<Map<String, dynamic>> get _appointments =>
      _db.collection('appointments');
  CollectionReference<Map<String, dynamic>> get _slots => _db.collection('slots');

  Future<String> book({
    required String patientId,
    required String patientName,
    String? patientPhone,
    required String treatment,
    String? doctorName,
    required DateTime start,
    String? note,
  }) async {
    final invalidTime = !ClinicSchedule.isOpenDay(start) ||
        start.minute != 0 ||
        start.hour < ClinicSchedule.firstHour ||
        start.hour > ClinicSchedule.lastHour;
    if (invalidTime) {
      throw const AppointmentException('Seçilen saat randevuya uygun değil.');
    }
    if (!ClinicSchedule.isBookableTime(start)) {
      throw const AppointmentException(
        'Bu saat için randevu alınamıyor. Lütfen daha ileri bir saat seçin.',
      );
    }

    final activeSnap = await _appointments
    .where('patientId', isEqualTo: patientId)
    .where('status', whereIn: [
      AppointmentStatus.pending.name,
      AppointmentStatus.confirmed.name,
    ]).get();

    final upcomingCount = activeSnap.docs
    .where((d) => (d.data()['start'] as
    Timestamp).toDate().isAfter(DateTime.now())).length;

    if (upcomingCount >= maxActivePerPatient) {
      throw const AppointmentException(
        'En fazla 3 aktif randevunuz olabilir. Yeni randevu için mevcut randevularınızdan birini iptal edebilirsiniz.',
      );
    }

    final slotRef = _slots.doc(ClinicSchedule.slotId(start));
    final apptRef = _appointments.doc();
    final cleanNote = note?.trim();

    await _db.runTransaction((tx) async {
      final slot = await tx.get(slotRef);
      if (slot.exists) throw const SlotTakenException();

      tx.set(slotRef, {
        'appointmentId': apptRef.id,
        'start': Timestamp.fromDate(start),
      });
      tx.set(apptRef, {
        'patientId': patientId,
        'patientName': patientName,
        'patientPhone': patientPhone,
        'treatment': treatment,
        'doctorName': doctorName,
        'start': Timestamp.fromDate(start),
        'status': AppointmentStatus.pending.name,
        'note': (cleanNote == null || cleanNote.isEmpty) ? null : cleanNote,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return apptRef.id;
  }

  /// Hasta kendi randevusunu iptal eder; saat tekrar boşa çıkar.
  Future<void> cancel(Appointment a) async {
    if (!a.isActive) {
      throw const AppointmentException('Bu randevu zaten sonlanmış.');
    }
    final batch = _db.batch();
    batch.update(_appointments.doc(a.id), {
      'status': AppointmentStatus.cancelled.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.delete(_slots.doc(ClinicSchedule.slotId(a.start)));
    await batch.commit();
  }

  /// Verilen günün dolu saatlerinin slot kimlikleri.
  Stream<Set<String>> watchBookedSlotIds(DateTime day) {
    final from = DateTime(day.year, day.month, day.day);
    final to = from.add(const Duration(days: 1));
    return _slots
        .where('start', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('start', isLessThan: Timestamp.fromDate(to))
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  Stream<List<Appointment>> watchPatientAppointments(String uid) {
    return _appointments.where('patientId', isEqualTo: uid).snapshots().map((snap) {
      final list = snap.docs
          .map((d) => Appointment.fromMap(d.data(), d.id))
          .toList()
        ..sort((a, b) => b.start.compareTo(a.start));
      return list;
    });
  }

  Future<void> setStatus(
      Appointment a,
      AppointmentStatus status, {
        String? adminNote,
      }) async {
    final allowed = switch (a.status) {
      AppointmentStatus.pending => [AppointmentStatus.confirmed, AppointmentStatus.rejected],
      AppointmentStatus.confirmed => [AppointmentStatus.completed, AppointmentStatus.cancelled],
      _ => <AppointmentStatus>[],
    };
    if (!allowed.contains(status)) {
      throw const AppointmentException('Bu işlem bu randevu için uygun değil.');
    }
    if (status == AppointmentStatus.completed && a.start.isAfter(DateTime.now())) {
      throw const AppointmentException(
        'Randevu saati gelmeden tamamlandı olarak işaretlenemez.',
      );
    }

    final note = adminNote?.trim();
    final batch = _db.batch();
    batch.update(_appointments.doc(a.id), {
      'status': status.name,
      'adminNote': (note == null || note.isEmpty) ? null : note,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (status == AppointmentStatus.rejected || status == AppointmentStatus.cancelled) {
      batch.delete(_slots.doc(ClinicSchedule.slotId(a.start)));
    }
    await batch.commit();
  }

  /// Admin için: son 90 gün ve sonrasındaki tüm randevular.
  Stream<List<Appointment>> watchAllAppointments() {
    final since = DateTime.now().subtract(const Duration(days: 90));
    return _appointments
        .where('start', isGreaterThan: Timestamp.fromDate(since))
        .snapshots()
        .map((snap) => snap.docs.map((d) => Appointment.fromMap(d.data(), d.id)).toList());
  }
}