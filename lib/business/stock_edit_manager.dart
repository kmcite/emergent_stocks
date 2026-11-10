import 'package:emergent_stocks/models/emergent_stock.dart';
import 'package:emergent_stocks/services/database.dart';
import 'package:emergent_stocks/utils/core.dart';
import 'package:emergent_stocks/utils/medicine_expiry.dart';
import 'package:emergent_stocks/utils/provider.dart';

final stockEditProvider = provider(
  (f) => StockEditManager(databaseServiceProvider(f)),
);

class StockEditManager(final DatabaseService db) {
  final name = signal('');
  final genericName = signal('');
  final strength = signal('');
  final count = signal('');
  final forEmergency = signal(false);
  final notes = signal('');
  final expiryDateMs = signal(0);
  final editingId = nullSignal<int>(name: 'stockEditId');

  void loadFrom(EmergentStock stock) {
    if (editingId() == stock.id) return;
    editingId.set(stock.id);
    name.set(stock.name);
    genericName.set(stock.genericName);
    strength.set(stock.strength);
    count.set(stock.count.toString());
    forEmergency.set(stock.forEmergency);
    notes.set(stock.notes);
    expiryDateMs.set(stock.expiryDateMs);
  }

  void setExpiryDate(DateTime? date) {
    expiryDateMs.set(date == null ? 0 : dateOnlyMs(date));
  }

  DateTime? get expiryDate {
    final ms = expiryDateMs();
    if (ms <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  int? get parsedCount {
    final value = int.tryParse(count().trim());
    if (value == null || value < 0) return null;
    return value;
  }

  String? get countError {
    if (count().trim().isEmpty) return null;
    return parsedCount == null ? 'Enter a whole number, 0 or greater' : null;
  }

  bool get isValid =>
      name().trim().isNotEmpty &&
      strength().trim().isNotEmpty &&
      parsedCount != null &&
      editingId() != null;

  void save({
    required List<EmergentStock> allStocks,
    void Function()? onSaved,
  }) {
    if (!isValid) return;

    final id = editingId()!;
    EmergentStock? original;
    for (final s in allStocks) {
      if (s.id == id) {
        original = s;
        break;
      }
    }
    if (original == null) return;

    db.put(
      original
        ..name = name().trim()
        ..genericName = genericName().trim()
        ..strength = strength().trim()
        ..count = parsedCount!
        ..forEmergency = forEmergency()
        ..notes = notes().trim()
        ..expiryDateMs = expiryDateMs(),
    );

    editingId.set(null);
    onSaved?.call();
  }

  void discard({void Function()? onDiscarded}) {
    editingId.set(null);
    onDiscarded?.call();
  }
}
