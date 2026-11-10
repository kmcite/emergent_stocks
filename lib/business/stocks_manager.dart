import 'package:emergent_stocks/models/emergent_stock.dart';
import 'package:emergent_stocks/services/database.dart';
import 'package:emergent_stocks/utils/collections.dart';
import 'package:emergent_stocks/utils/provider.dart';

final stocksProvider = provider(
  (f) => StocksManager(
    databaseServiceProvider(f),
  ),
);

class StocksManager(
  final DatabaseService db,
) {
  this {
    db.watch<EmergentStock>().listen(stocks.set);
  }

  var stocks = listSignal<EmergentStock>();

  void putStock(EmergentStock stock) {
    db.put(stock);
  }

  void removeStock(EmergentStock stock) {
    db.removeEmergentStock(stock.id);
  }

  void updateStock(EmergentStock stock) {
    db.put(stock);
  }
}
