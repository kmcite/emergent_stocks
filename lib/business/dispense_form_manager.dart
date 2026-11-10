import 'package:emergent_stocks/business/dispense_manager.dart';
import 'package:emergent_stocks/business/stocks_manager.dart';
import 'package:emergent_stocks/models/emergent_stock.dart';
import 'package:emergent_stocks/utils/core.dart';
import 'package:emergent_stocks/utils/provider.dart';

final dispenseFormProvider = provider(
  (f) => DispenseFormManager(
    stocksProvider(f),
    dispenseProvider(f),
  ),
);

class DispenseFormManager(
  final StocksManager stocks,
  final DispenseManager dispense,
) {
  final selectedStockId = signal<int?>(null);
  final patientName = signal('');
  final quantity = signal('1');
  final notes = signal('');

  EmergentStock? get selectedStock {
    final id = selectedStockId();
    if (id == null) return null;
    for (final s in stocks.stocks) {
      if (s.id == id) return s;
    }
    return null;
  }

  int? get parsedQuantity {
    final n = int.tryParse(quantity().trim());
    if (n == null || n <= 0) return null;
    return n;
  }

  String? get quantityError {
    if (quantity().trim().isEmpty) return null;
    if (parsedQuantity == null) return 'Enter a whole number greater than 0';
    final stock = selectedStock;
    if (stock != null && parsedQuantity! > stock.count) {
      return 'Only ${stock.count} available';
    }
    return null;
  }

  bool get isValid =>
      selectedStockId() != null &&
      patientName().trim().isNotEmpty &&
      parsedQuantity != null &&
      quantityError == null;

  String? submit({void Function()? onDone}) {
    final stock = selectedStock;
    if (stock == null || !isValid) return 'Complete all required fields.';

    final error = dispense.dispense(
      stock: stock,
      patientName: patientName(),
      quantity: parsedQuantity!,
      notes: notes(),
    );
    if (error != null) return error;

    clear(onCleared: onDone);
    return null;
  }

  void clear({void Function()? onCleared, int? preselectStockId}) {
    patientName.state = '';
    quantity.state = '1';
    notes.state = '';
    selectedStockId.set(preselectStockId);
    onCleared?.call();
  }

  void ensurePreselect(int stockId) {
    if (selectedStockId() == stockId) return;
    selectedStockId.set(stockId);
  }
}
