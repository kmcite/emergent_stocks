import 'package:emergent_stocks/models/emergent_stock.dart';
import 'package:flutter/material.dart';

enum ExpiryStatus { unknown, good, soon, expired }

const expiringSoonDays = 30;

ExpiryStatus expiryStatus(EmergentStock medicine, [DateTime? clock]) {
  final ms = medicine.expiryDateMs;
  if (ms <= 0) return ExpiryStatus.unknown;

  final now = clock ?? DateTime.now();
  final expiry = DateTime.fromMillisecondsSinceEpoch(ms);
  final days = expiry.difference(DateTime(now.year, now.month, now.day)).inDays;

  if (days < 0) return ExpiryStatus.expired;
  if (days <= expiringSoonDays) return ExpiryStatus.soon;
  return ExpiryStatus.good;
}

int? daysUntilExpiry(EmergentStock medicine, [DateTime? clock]) {
  final ms = medicine.expiryDateMs;
  if (ms <= 0) return null;
  final now = clock ?? DateTime.now();
  final expiry = DateTime.fromMillisecondsSinceEpoch(ms);
  return expiry.difference(DateTime(now.year, now.month, now.day)).inDays;
}

String formatExpiryDate(int expiryDateMs) {
  if (expiryDateMs <= 0) return 'Not set';
  final d = DateTime.fromMillisecondsSinceEpoch(expiryDateMs);
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

int dateOnlyMs(DateTime date) =>
    DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;

String expiryLabel(EmergentStock medicine, [DateTime? clock]) {
  final status = expiryStatus(medicine, clock);
  final days = daysUntilExpiry(medicine, clock);
  return switch (status) {
    ExpiryStatus.unknown => 'No expiry',
    ExpiryStatus.expired => 'Expired',
    ExpiryStatus.soon => days == 0 ? 'Expires today' : 'Expires in $days days',
    ExpiryStatus.good => 'Expires ${formatExpiryDate(medicine.expiryDateMs)}',
  };
}

Color expiryColor(ExpiryStatus status, ColorScheme colors) {
  return switch (status) {
    ExpiryStatus.unknown => colors.outline,
    ExpiryStatus.good => const Color(0xFF34C759),
    ExpiryStatus.soon => const Color(0xFFFF9F0A),
    ExpiryStatus.expired => colors.error,
  };
}
