import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/presentation/auth_providers.dart';
import 'data/appointment_repository.dart';
import 'domain/appointment.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository(FirebaseFirestore.instance);
});

/// Anahtar: günün başlangıcı (saat 00:00). Dolu slot kimliklerini verir.
final bookedSlotsProvider =
StreamProvider.autoDispose.family<Set<String>, DateTime>((ref, day) {
  return ref.watch(appointmentRepositoryProvider).watchBookedSlotIds(day);
});

final myAppointmentsProvider =
StreamProvider.autoDispose<List<Appointment>>((ref) {
  final uid = ref.watch(authStateProvider.select((s) => s.value?.uid));
  if (uid == null) return Stream.value(const <Appointment>[]);
  return ref.watch(appointmentRepositoryProvider).watchPatientAppointments(uid);
});

final allAppointmentsProvider = StreamProvider.autoDispose<List<Appointment>>((ref) {
  return ref.watch(appointmentRepositoryProvider).watchAllAppointments();
});

class PreselectedTreatment extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String id) => state = id;
  void clear() => state = null;
}

final preselectedTreatmentProvider =
NotifierProvider<PreselectedTreatment, String?>(PreselectedTreatment.new);

final blockedSlotsProvider = StreamProvider.autoDispose<List<BlockedSlot>>((ref) {
  return ref.watch(appointmentRepositoryProvider).watchBlockedSlots();
});