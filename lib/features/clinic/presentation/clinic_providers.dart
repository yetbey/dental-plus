import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/clinic_repository.dart';
import '../domain/clinic_info.dart';
import '../domain/doctor.dart';
import '../domain/treatment.dart';

final clinicRepositoryProvider = Provider<ClinicRepository>((ref) {
  return ClinicRepository(FirebaseFirestore.instance);
});

final treatmentsProvider = StreamProvider.autoDispose<List<Treatment>>((ref) {
  return ref.watch(clinicRepositoryProvider).watchActiveTreatments();
});

final doctorsProvider = StreamProvider.autoDispose<List<Doctor>>((ref) {
  return ref.watch(clinicRepositoryProvider).watchActiveDoctors();
});

final allTreatmentsProvider = StreamProvider.autoDispose<List<Treatment>>((ref) {
  return ref.watch(clinicRepositoryProvider).watchAllTreatments();
});

final allDoctorsProvider = StreamProvider.autoDispose<List<Doctor>>((ref) {
  return ref.watch(clinicRepositoryProvider).watchAllDoctors();
});

final clinicInfoProvider = StreamProvider.autoDispose<ClinicInfo>((ref) {
  return ref.watch(clinicRepositoryProvider).watchInfo();
});