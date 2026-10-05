import 'package:flutter/material.dart';

import '../domain/appointment.dart';

(Color, Color) appointmentStatusColors(AppointmentStatus s) => switch (s) {
  AppointmentStatus.pending => (const Color(0xFFFEF3C7), const Color(0xFFB45309)),
  AppointmentStatus.confirmed => (const Color(0xFFD1FAE5), const Color(0xFF047857)),
  AppointmentStatus.rejected => (const Color(0xFFFEE2E2), const Color(0xFFB91C1C)),
  AppointmentStatus.cancelled => (const Color(0xFFF1F5F9), const Color(0xFF64748B)),
  AppointmentStatus.completed => (const Color(0xFFE5EEFF), const Color(0xFF0F2B48)),
};