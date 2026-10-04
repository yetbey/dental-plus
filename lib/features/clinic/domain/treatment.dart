import 'package:flutter/material.dart';

IconData treatmentIcon(String key) => switch (key) {
  'checkup' => Icons.fact_check_outlined,
  'emergency' => Icons.emergency,
  'whitening' => Icons.auto_awesome_outlined,
  'implant' => Icons.hardware_rounded,
  'ortho' => Icons.cruelty_free_outlined,
  'smile' => Icons.sentiment_satisfied_alt_outlined,
  'crown' => Icons.diamond_outlined,
  'invisible' => Icons.visibility_off_outlined,
  'child' => Icons.child_care_rounded,
  _ => Icons.medical_services_outlined,
};

class Treatment {
  const Treatment({
    required this.id,
    required this.title,
    required this.category,
    required this.subtitle,
    this.description = '',
    this.badge,
    this.perks = const [],
    this.iconKey = 'default',
    this.urgent = false,
    this.active = true,
    this.sortOrder = 0,
});

  final String id;
  final String title;
  final String category;
  final String subtitle;
  final String description;
  final String? badge;
  final List<String> perks;
  final String iconKey;
  final bool urgent;
  final bool active;
  final int sortOrder;

  IconData get icon => treatmentIcon(iconKey);

  factory Treatment.fromMap(Map<String, dynamic> m, String id) {
    return Treatment(
      id: id,
      title: m['title'] as String? ?? '',
      category: m['category'] as String? ?? '',
      subtitle: m['subtitle'] as String? ?? '',
      description: m['description'] as String? ?? '',
      badge: m['badge'] as String?,
      perks: ((m['perks'] as List?) ?? const []).map((e) => e.toString()).toList(),
      iconKey: m['iconKey'] as String? ?? 'default',
      urgent: m['urgent'] as bool? ?? false,
      active: m['active'] as bool? ?? true,
      sortOrder: (m['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'category': category,
    'subtitle': subtitle,
    'description': description,
    'badge': badge,
    'perks': perks,
    'iconKey': iconKey,
    'urgent': urgent,
    'active': active,
    'sortOrder': sortOrder,
  };
}