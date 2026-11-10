import 'package:emergent_stocks/models/emergent_stock.dart';
import 'package:emergent_stocks/utils/core.dart';
import 'package:emergent_stocks/utils/medicine_expiry.dart';
import 'package:emergent_stocks/utils/provider.dart';

enum MedicineBagFilter { all, emergency, expiring }

final medicineBagFilterProvider = provider(
  (f) => signal(MedicineBagFilter.all, name: 'medicineBagFilter'),
);

List<EmergentStock> sortMedicinesForBag(List<EmergentStock> items) {
  final copy = List<EmergentStock>.from(items);
  copy.sort((a, b) {
    if (a.forEmergency != b.forEmergency) {
      return a.forEmergency ? -1 : 1;
    }
    final aExpiry = a.expiryDateMs <= 0 ? 1 << 62 : a.expiryDateMs;
    final bExpiry = b.expiryDateMs <= 0 ? 1 << 62 : b.expiryDateMs;
    if (aExpiry != bExpiry) return aExpiry.compareTo(bExpiry);
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return copy;
}

List<EmergentStock> filterMedicines(
  List<EmergentStock> items,
  MedicineBagFilter filter,
) {
  return switch (filter) {
    MedicineBagFilter.all => items,
    MedicineBagFilter.emergency =>
      items.where((m) => m.forEmergency).toList(),
    MedicineBagFilter.expiring => items.where((m) {
      final status = expiryStatus(m);
      return status == ExpiryStatus.soon || status == ExpiryStatus.expired;
    }).toList(),
  };
}

int countExpiringSoon(List<EmergentStock> items) {
  return items
      .where((m) {
        final s = expiryStatus(m);
        return s == ExpiryStatus.soon || s == ExpiryStatus.expired;
      })
      .length;
}
