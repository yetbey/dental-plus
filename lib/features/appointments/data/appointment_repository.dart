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

  /// Admin: telefonla ya da yüz yüze gelen, uygulamada kaydı olmayan hasta için randevu.
  Future<String> bookByAdmin({
    required String patientName,
    required String patientPhone,
    required String treatment,
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
    if (!start.isAfter(DateTime.now())) {
      throw const AppointmentException('Geçmiş bir saate randevu eklenemez.');
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
        'patientId': '',
        'patientName': patientName.trim(),
        'patientPhone': patientPhone.trim(),
        'treatment': treatment,
        'start': Timestamp.fromDate(start),
        'status': AppointmentStatus.confirmed.name,
        'note': (cleanNote == null || cleanNote.isEmpty) ? null : cleanNote,
        'source': 'admin',
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

  /// Admin: seçilen saatleri kapatır. Zaten dolu olanlar korunur.
  Future<({int closed, int skipped})> closeSlots(
      DateTime day,
      Set<int> hours,
      String reason,
      ) async {
    final from = DateTime(day.year, day.month, day.day);
    final existing = await _slots
        .where('start', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('start', isLessThan: Timestamp.fromDate(from.add(const Duration(days: 1))))
        .get();
    final taken = existing.docs.map((d) => d.id).toSet();

    final batch = _db.batch();
    var closed = 0;
    var skipped = 0;
    for (final h in hours) {
      final s = DateTime(day.year, day.month, day.day, h);
      if (!s.isAfter(DateTime.now())) continue;
      final id = ClinicSchedule.slotId(s);
      if (taken.contains(id)) {
        skipped++;
        continue;
      }
      batch.set(_slots.doc(id), {
        'appointmentId': '',
        'start': Timestamp.fromDate(s),
        'blocked': true,
        'reason': reason.trim(),
      });
      closed++;
    }
    if (closed > 0) await batch.commit();
    return (closed: closed, skipped: skipped);
  }

  Future<void> reopenSlots(List<String> slotIds) async {
    final batch = _db.batch();
    for (final id in slotIds) {
      batch.delete(_slots.doc(id));
    }
    await batch.commit();
  }

  Stream<List<BlockedSlot>> watchBlockedSlots() {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    return _slots.where('blocked', isEqualTo: true).snapshots().map((snap) {
      final list = snap.docs
          .map((d) => BlockedSlot(
        id: d.id,
        start: (d.data()['start'] as Timestamp).toDate(),
        reason: d.data()['reason'] as String? ?? '',
      ))
          .where((s) => !s.start.isBefore(startOfToday))
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start));
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

class BlockedSlot {
  const BlockedSlot({required this.id, required this.start, required this.reason});

  final String id;
  final DateTime start;
  final String reason;
}