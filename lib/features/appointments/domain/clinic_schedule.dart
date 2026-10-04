class ClinicSchedule {
  static const firstHour = 9;
  static const lastHour = 18;
  static const minLeadMinutes = 60;

  static bool isOpenDay(DateTime d) => d.weekday != DateTime.sunday;

  static List<DateTime> slotsFor(DateTime day) => [
    for (var h = firstHour; h <= lastHour; h++)
      DateTime(day.year, day.month, day.day, h),
  ];

  static bool isBookableTime(DateTime slot) => slot.isAfter(
    DateTime.now().add(const Duration(minutes: minLeadMinutes)),
  );

  static List<DateTime> bookableDays({int count = 14}) {
    final now = DateTime.now();
    final days = <DateTime>[];
    for (var i = 0; days.length < count && i < 60; i++) {
      final d = DateTime(now.year, now.month, now.day).add(Duration(days: i));
      if (!isOpenDay(d)) continue;
      if (!slotsFor(d).any(isBookableTime)) continue;
      days.add(d);
    }
    return days;
  }

  static String slotId(DateTime s) {
    String p(int v) => v.toString().padLeft(2, '0');
    return '${s.year}${p(s.month)}${p(s.day)}_${p(s.hour)}';
  }

  static String timeLabel(DateTime s) =>
      '${s.hour.toString().padLeft(2, '0')}:00';
}