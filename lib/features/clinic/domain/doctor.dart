class Doctor {
  const Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    this.experienceYears = 0,
    this.bio = '',
    this.photo,
    this.active = true,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String specialty;
  final int experienceYears;
  final String bio;
  final String? photo;
  final bool active;
  final int sortOrder;

  factory Doctor.fromMap(Map<String, dynamic> m, String id) {
    return Doctor(
      id: id,
      name: m['name'] as String? ?? '',
      specialty: m['specialty'] as String? ?? '',
      experienceYears: (m['experienceYears'] as num?)?.toInt() ?? 0,
      bio: m['bio'] as String? ?? '',
      photo: m['photo'] as String?,
      active: m['active'] as bool? ?? true,
      sortOrder: (m['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'specialty': specialty,
    'experienceYears': experienceYears,
    'bio': bio,
    'photo': photo,
    'active': active,
    'sortOrder': sortOrder,
  };
}