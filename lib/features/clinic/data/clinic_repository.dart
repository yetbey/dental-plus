import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/clinic_info.dart';
import '../domain/doctor.dart';
import '../domain/treatment.dart';

const _defaultTreatments = <Treatment>[
  Treatment(
    id: 'checkup',
    title: 'İlk Muayene & Kontrol',
    category: 'Genel',
    subtitle: 'Genel ağız ve diş muayenesi (Ücretsiz)',
    description: 'Ağız ve diş sağlığınızın genel değerlendirmesi yapılır, ihtiyaç duyulan tedaviler planlanır.',
    perks: ['Ücretsiz muayene', 'Tedavi planı'],
    iconKey: 'checkup',
    sortOrder: 0,
  ),
  Treatment(
    id: 'emergency',
    title: 'Diş Ağrısı / Acil Girişim',
    category: 'Acil',
    subtitle: 'Akut ağrı veya acil durum müdahalesi',
    description: 'Ani diş ağrısı ve acil durumlar için öncelikli randevu.',
    perks: ['Öncelikli randevu'],
    iconKey: 'emergency',
    urgent: true,
    sortOrder: 1,
  ),
  Treatment(
    id: 'smile-design',
    title: 'Estetik Gülüş Tasarımı',
    category: 'Estetik',
    subtitle: 'Kişiye özel dijital gülüş planlaması',
    description: 'Dijital prova ile nihai gülüşünüzü işleme başlamadan önce görün ve onaylayın.',
    perks: ['Dijital planlama', 'Kişiye özel'],
    iconKey: 'smile',
    sortOrder: 2,
  ),
  Treatment(
    id: 'whitening',
    title: 'Diş Beyazlatma (Bleaching)',
    category: 'Estetik',
    subtitle: 'Lazerli estetik klinik beyazlatma',
    description: 'Diş minesine zarar vermeden, hassasiyeti önleyen özel formülle beyazlatma.',
    perks: ['Anında görünür etki', 'Hassasiyet azaltıcı'],
    iconKey: 'whitening',
    sortOrder: 3,
  ),
  Treatment(
    id: 'crown',
    title: 'Zirkonyum & Porselen Kaplama',
    category: 'Restoratif',
    subtitle: 'Doğal görünümlü diş restorasyonu',
    description: 'Yüksek biyouyumlulukla, doğal diş dokusuna uyumlu kaplamalar.',
    perks: ['Doğal görünüm', 'Dijital üretim'],
    iconKey: 'crown',
    sortOrder: 4,
  ),
  Treatment(
    id: 'ortho',
    title: 'Ortodonti & Şeffaf Plak',
    category: 'Ortodonti',
    subtitle: 'Telsiz diş düzeltme ve kontrol',
    description: 'Çıkarılabilir, neredeyse görünmez plaklarla diş düzeltme tedavisi.',
    perks: ['Çıkarılabilir', 'Konforlu'],
    iconKey: 'invisible',
    sortOrder: 5,
  ),
  Treatment(
    id: 'implant',
    title: 'İmplant Danışmanlığı',
    category: 'Cerrahi',
    subtitle: '3D Tomografi & çene kemiği analizi',
    description: 'İmplant uygunluğunuz görüntüleme ile değerlendirilir ve tedavi planı çıkarılır.',
    perks: ['3D Tomografi', 'Tedavi planı'],
    iconKey: 'implant',
    sortOrder: 6,
  ),
];

const _defaultDoctors = <Doctor>[
  Doctor(
    id: 'mustafa-erkan',
    name: 'Mustafa Erkan',
    specialty: 'Diş Hekimi',
    sortOrder: 0,
  ),
];

class ClinicRepository {
  ClinicRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _treatments => _db.collection('treatments');
  CollectionReference<Map<String, dynamic>> get _doctors => _db.collection('doctors');

  Stream<List<Treatment>> watchActiveTreatments() {
    return _treatments.where('active', isEqualTo: true).snapshots().map((snap) {
      final list = snap.docs.map((d) => Treatment.fromMap(d.data(), d.id)).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return list;
    });
  }

  Stream<List<Doctor>> watchActiveDoctors() {
    return _doctors.where('active', isEqualTo: true).snapshots().map((snap) {
      final list = snap.docs.map((d) => Doctor.fromMap(d.data(), d.id)).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return list;
    });
  }

  Stream<List<Treatment>> watchAllTreatments() {
    return _treatments.snapshots().map((snap) {
      final list = snap.docs.map((d) => Treatment.fromMap(d.data(), d.id)).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return list;
    });
  }

  Stream<List<Doctor>> watchAllDoctors() {
    return _doctors.snapshots().map((snap) {
      final list = snap.docs.map((d) => Doctor.fromMap(d.data(), d.id)).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return list;
    });
  }

  DocumentReference<Map<String, dynamic>> get _info => _db.collection('settings').doc('clinic');

  Stream<ClinicInfo> watchInfo() => _info
      .snapshots()
      .map((s) => s.exists ? ClinicInfo.fromMap(s.data()!) : const ClinicInfo());

  Future<void> saveInfo(ClinicInfo info) => _info.set(info.toMap());

  Future<void> saveDoctor(Doctor d) {
    final ref = d.id.isEmpty ? _doctors.doc() : _doctors.doc(d.id);
    return ref.set(d.toMap());
  }

  Future<void> saveTreatment(Treatment t) {
    final ref = t.id.isEmpty ? _treatments.doc() : _treatments.doc(t.id);
    return ref.set(t.toMap());
  }

  Future<void> setTreatmentActive(String id, bool active) =>
      _treatments.doc(id).update({'active': active});

  Future<void> deleteTreatment(String id) => _treatments.doc(id).delete();

  Future<bool> seedDefaults() async {
    final t = await _treatments.limit(1).get();
    final d = await _doctors.limit(1).get();
    if (t.docs.isNotEmpty && d.docs.isNotEmpty) return false;

    final batch = _db.batch();
    if (t.docs.isEmpty) {
      for (final item in _defaultTreatments) {
        batch.set(_treatments.doc(item.id), item.toMap());
      }
    }
    if (d.docs.isEmpty) {
      for (final item in _defaultDoctors) {
        batch.set(_doctors.doc(item.id), item.toMap());
      }
    }
    await batch.commit();
    return true;
  }
}