import 'package:emergent_stocks/main.dart';
import 'package:emergent_stocks/domain/api/stocks_repository.dart';
import 'package:emergent_stocks/domain/model/emergent_stock.dart';
import 'package:spark/spark.dart';

class StockSpark extends Spark {
  final EmergentStock stock;
  StockSpark({required this.stock});
  late StocksRepository stocksRepository = of();

  void onStockCountIncremented(EmergentStock stock) {
    stocksRepository.put(stock..count = stock.count + 1);
    notifyListeners();
  }

  void onStockCountDecrement(EmergentStock stock) {
    stocksRepository.put(stock..count = stock.count - 1);
    notifyListeners();
  }

  void onDeleted(EmergentStock stock) {
    stocksRepository.remove(stock);
    notifyListeners();
    navigator.back();
  }
}

class StockDetails extends Feature<StockSpark> {
  final EmergentStock stock;
  const StockDetails({super.key, required this.stock});

  @override
  StockSpark create() => StockSpark(stock: stock);

  @override
  Widget build(BuildContext context, spark) {
    return Scaffold(
      appBar: AppBar(
        title: Text(stock.name),
        actions: [
          IconButton(
            onPressed: () => spark.onDeleted(stock),
            icon: Icon(Icons.delete_forever_outlined),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              stock.count.toString(),
              style: TextStyle(fontSize: 48),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: 8,
        children: [
          FloatingActionButton(
            heroTag: stock.name,
            onPressed: () => spark.onStockCountIncremented(stock),
            child: Icon(Icons.add),
          ),
          FloatingActionButton(
            heroTag: stock.count,
            onPressed: () => spark.onStockCountDecrement(stock),
            child: Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
