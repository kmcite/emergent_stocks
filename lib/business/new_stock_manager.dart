import 'package:emergent_stocks/models/emergent_stock.dart';
import 'package:emergent_stocks/services/database.dart';
import 'package:emergent_stocks/utils/core.dart';
import 'package:emergent_stocks/utils/medicine_expiry.dart';
import 'package:emergent_stocks/utils/provider.dart';

final newStockProvider = provider(
  (f) => NewStockManager(databaseServiceProvider(f)),
);

class NewStockManager(final DatabaseService db) {
  final name = signal('');
  final genericName = signal('');
  final strength = signal('');
  final count = signal('');
  final forEmergency = signal(false);
  final notes = signal('');

  /// 0 = no expiry selected.
  final expiryDateMs = signal(0);

  int? get parsedCount {
    final value = int.tryParse(count().trim());
    if (value == null || value <= 0) return null;
    return value;
  }

  String? get countError {
    if (count().trim().isEmpty) return null;
    return parsedCount == null ? 'Enter a whole number greater than 0' : null;
  }

  bool get isNewStockValid =>
      name().trim().isNotEmpty &&
      strength().trim().isNotEmpty &&
      parsedCount != null;

  void setExpiryDate(DateTime? date) {
    expiryDateMs.set(date == null ? 0 : dateOnlyMs(date));
  }

  DateTime? get expiryDate {
    final ms = expiryDateMs();
    if (ms <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  void put({void Function()? onStockSaved}) {
    if (!isNewStockValid) return;

    final stock = EmergentStock()
      ..name = name().trim()
      ..genericName = genericName().trim()
      ..strength = strength().trim()
      ..count = parsedCount!
      ..forEmergency = forEmergency()
      ..notes = notes().trim()
      ..expiryDateMs = expiryDateMs();

    db.put(stock);
    onStockSaved?.call();
    clearForm();
  }

  void clearForm({void Function()? onFormCleared}) {
    name.state = '';
    genericName.state = '';
    strength.state = '';
    count.state = '';
    forEmergency.state = false;
    notes.state = '';
    expiryDateMs.state = 0;
    onFormCleared?.call();
  }
}
