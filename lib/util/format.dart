import 'package:intl/intl.dart';

import '../l10n/l10n.dart';

String capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// "hace 5 min", "ayer", "12 sept"… (o "5 min ago", "yesterday", "Sep 12").
String timeAgo(DateTime date, AppLocalizations l, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final diff = n.difference(date);
  if (diff.inSeconds < 45) return l.timeNow;
  if (diff.inMinutes < 60) return l.timeMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l.timeHoursAgo(diff.inHours);
  if (diff.inDays == 1) return l.timeYesterday;
  if (diff.inDays < 7) return l.timeDaysAgo(diff.inDays);
  final pattern = date.year == n.year ? 'd MMM' : 'd MMM y';
  return DateFormat(pattern, l.localeName).format(date);
}

/// "Septiembre 2026" / "September 2026" (encabezados del diario).
String monthYear(DateTime date, AppLocalizations l) =>
    capitalize(DateFormat('MMMM y', l.localeName).format(date));

/// "SEPT" / "SEP": el mes abreviado de una fecha.
String monthShort(DateTime date, AppLocalizations l) =>
    DateFormat('MMM', l.localeName).format(date).replaceAll('.', '');

/// Grupo de las notificaciones: "Hoy", "Ayer", "Esta semana" (lo de los
/// últimos 7 días) y, antes, el mes y el año ("Septiembre 2026"). Se cuenta
/// por días del calendario, no por horas.
String dayGroup(DateTime date, AppLocalizations l, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(date.year, date.month, date.day);
  final days = today.difference(day).inHours ~/ 24;
  if (days <= 0) return l.groupToday;
  if (days == 1) return l.groupYesterday;
  if (days < 7) return l.groupThisWeek;
  return monthYear(date, l);
}
