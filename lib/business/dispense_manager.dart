import 'package:emergent_stocks/models/dispense_record.dart';
import 'package:emergent_stocks/models/emergent_stock.dart';
import 'package:emergent_stocks/services/database.dart';
import 'package:emergent_stocks/utils/collections.dart';
import 'package:emergent_stocks/utils/provider.dart';

final dispenseProvider = provider(
  (f) => DispenseManager(databaseServiceProvider(f)),
);

class DispenseManager(final DatabaseService db) {
  this {
    db.watch<DispenseRecord>().listen(records.set);
  }

  var records = listSignal<DispenseRecord>();

  String? dispense({
    required EmergentStock stock,
    required String patientName,
    required int quantity,
    String notes = '',
  }) {
    final patient = patientName.trim();
    if (patient.isEmpty) return 'Enter a patient name or identifier.';
    if (quantity <= 0) return 'Quantity must be at least 1.';
    if (stock.count < quantity) {
      return 'Not enough in stock (${stock.count} available).';
    }

    stock.count -= quantity;
    db.put(stock);

    db.put(
      DispenseRecord()
        ..stockId = stock.id
        ..medicineName = stock.name
        ..strength = stock.strength
        ..patientName = patient
        ..quantity = quantity
        ..notes = notes.trim()
        ..dispensedAtMs = DateTime.now().millisecondsSinceEpoch,
    );

    return null;
  }

  int totalDispensedSince(int sinceMs) {
    var total = 0;
    for (final r in records) {
      if (r.dispensedAtMs >= sinceMs) total += r.quantity;
    }
    return total;
  }

  List<DispenseRecord> recent({int limit = 12}) {
    final copy = records.toList()
      ..sort((a, b) => b.dispensedAtMs.compareTo(a.dispensedAtMs));
    if (copy.length <= limit) return copy;
    return copy.sublist(0, limit);
  }
}
