import 'package:emergent_stocks/domain/model/emergent_stock.dart';
import 'package:emergent_stocks/features/emergent_stock_dialog.dart';
import 'package:emergent_stocks/main.dart';
import 'package:emergent_stocks/domain/api/settings_repository.dart';
import 'package:emergent_stocks/features/stock_details.dart';
import 'package:emergent_stocks/domain/api/stocks_repository.dart';
import 'package:spark/spark.dart';

class StocksDashboardCubit extends Spark {
  late SettingsRepository settingsRepository = of();
  late StocksRepository stocksRepository = of();

  List<EmergentStock> get stocks => stocksRepository.getAll();
  bool get dark => settingsRepository.dark;

  void onRemoveAllStocks() {
    stocksRepository.removeAll();
  }

  void onDarkModeToggled() {
    settingsRepository.toggleMode();
  }
}

class StocksDashboard extends Feature<StocksDashboardCubit> {
  const StocksDashboard({super.key});

  @override
  StocksDashboardCubit create() => StocksDashboardCubit();

  @override
  Widget build(BuildContext context, spark) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stocks Dashboard'),
        actions: [
          IconButton(
            onPressed: spark.stocks.isEmpty ? null : spark.onRemoveAllStocks,
            icon: Icon(Icons.clear),
          ),
          IconButton(
            onPressed: spark.onDarkModeToggled,
            icon: Icon(spark.dark ? Icons.light_mode : Icons.dark_mode),
          ),
          SizedBox(width: 8)
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemBuilder: (context, i) {
                final stock = spark.stocks.elementAt(i);
                return ListTile(
                  onTap: () => navigator.to(
                    StockDetails(stock: stock),
                  ),
                  title: Text(stock.name),
                  subtitle: Text(stock.count.toString()),
                );
              },
              itemCount: spark.stocks.length,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => navigator.toDialog(EmergentStockDialog()),
        child: Icon(Icons.medical_information),
      ),
    );
  }
}
