const List<String> monthNames = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

String monthShort(int month) => monthNames[month - 1].substring(0, 3);

String capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// "hace 5 min", "ayer", "12 sep"…
String timeAgo(DateTime date, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final diff = n.difference(date);
  if (diff.inSeconds < 45) return 'ahora';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  if (diff.inDays == 1) return 'ayer';
  if (diff.inDays < 7) return 'hace ${diff.inDays} días';
  if (date.year == n.year) return '${date.day} ${monthShort(date.month)}';
  return '${date.day} ${monthShort(date.month)} ${date.year}';
}

String monthYear(DateTime date) =>
    '${capitalize(monthNames[date.month - 1])} ${date.year}';

String shortDate(DateTime date) =>
    '${date.day} ${monthShort(date.month)} ${date.year}';

String greeting([DateTime? now]) {
  final h = (now ?? DateTime.now()).hour;
  if (h < 6) return 'Buenas noches';
  if (h < 12) return 'Buenos días';
  if (h < 19) return 'Buenas tardes';
  return 'Buenas noches';
}

String plural(int n, String singular, String pluralForm) =>
    '$n ${n == 1 ? singular : pluralForm}';
