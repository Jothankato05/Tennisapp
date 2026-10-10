const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String fmtDate(DateTime d) => '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]} ${d.year}';

String fmtShortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

String fmtTime(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// "Today", "Yesterday", "3 days ago" or a date.
String fmtRelativeDay(DateTime d, [DateTime? now]) {
  final today = _day(now ?? DateTime.now());
  final diff = today.difference(_day(d)).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff > 1 && diff < 7) return '$diff days ago';
  return fmtShortDate(d) + (d.year == today.year ? '' : ' ${d.year}');
}

String fmtMinutes(int minutes) {
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60, m = minutes % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

String fmtPercent(double v) => '${(v * 100).round()}%';

String greeting([DateTime? now]) {
  final h = (now ?? DateTime.now()).hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
