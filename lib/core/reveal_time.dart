import 'package:flutter/material.dart';

const _monthNames = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];

/// "Bugün 23:00", "Yarın 10:00" or "28 Eylül 10:00" — how a Banyo reveal time is shown everywhere.
String formatRevealTime(DateTime revealAt, {DateTime? now}) {
  final local = revealAt.toLocal();
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final day = DateUtils.dateOnly(local);
  final time = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  final daysAway = day.difference(today).inDays;
  if (daysAway == 0) return 'Bugün $time';
  if (daysAway == 1) return 'Yarın $time';
  return '${local.day} ${_monthNames[local.month - 1]} $time';
}

/// "3 sa 12 dk 05 sn" — the live countdown to a reveal.
String formatCountdown(Duration remaining) {
  if (remaining.isNegative) return '0 sn';
  final days = remaining.inDays;
  final hours = remaining.inHours % 24;
  final minutes = remaining.inMinutes % 60;
  final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
  if (days > 0) return '$days gün $hours sa $minutes dk';
  if (hours > 0) return '$hours sa $minutes dk $seconds sn';
  return '$minutes dk $seconds sn';
}

/// The morning after the event: 10:00 the day after [eventDate], or tomorrow 10:00 without one.
/// Falls back to tomorrow if that moment has already passed.
DateTime defaultRevealTime(DateTime? eventDate) {
  final now = DateTime.now();
  final base = eventDate ?? now;
  final candidate = DateTime(base.year, base.month, base.day + 1, 10);
  return candidate.isAfter(now) ? candidate : DateTime(now.year, now.month, now.day + 1, 10);
}

/// Picks a future reveal moment (date, then time). Returns null if cancelled or the moment isn't in the future.
Future<DateTime?> pickRevealTime(BuildContext context, DateTime initial) async {
  final now = DateTime.now();
  final date = await showDatePicker(
    context: context,
    helpText: 'Fotoğraflar ne zaman açılsın?',
    initialDate: initial.isBefore(now) ? now : initial,
    firstDate: DateUtils.dateOnly(now),
    lastDate: now.add(const Duration(days: 30)),
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(context: context, helpText: 'Açılış saati', initialTime: TimeOfDay.fromDateTime(initial));
  if (time == null) return null;
  final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
  if (!picked.isAfter(DateTime.now())) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Açılış zamanı ileride olmalı.')));
    }
    return null;
  }
  return picked;
}
