import 'package:emergent_stocks/domain/api/generic_names_repository.dart';
import 'package:emergent_stocks/domain/api/brands_repository.dart';
import 'package:emergent_stocks/objectbox.g.dart';
import 'package:emergent_stocks/domain/api/settings_repository.dart';
import 'package:emergent_stocks/domain/api/stocks_repository.dart';
import 'package:emergent_stocks/features/stocks_dashboard.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spark/spark.dart';

import 'main.dart';
export 'package:flutter/material.dart' hide State;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}

class App extends Injector {
  const App({super.key});

  @override
  Future<void> init() async {
    final appInfo = await PackageInfo.fromPlatform();
    final path = await getApplicationDocumentsDirectory();
    final store = await openStore(
      directory: join(path.path, appInfo.appName),
    );

    putService<Store>(store);

    putRepository(StocksRepository());
    putRepository(SettingsRepository());
    putRepository(BrandsRepository());
    putRepository(GenericNamesRepository());
  }

  @override
  Widget build(BuildContext context) => const EmergentStocks();
}

class EmergentStocksBloc extends Spark {
  late SettingsRepository settingsRepository = of();
  bool get dark => settingsRepository.dark;
}

class EmergentStocks extends Feature<EmergentStocksBloc> {
  const EmergentStocks({super.key});

  @override
  EmergentStocksBloc create() => EmergentStocksBloc();

  @override
  Widget build(BuildContext context, spark) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigator.key,
      home: StocksDashboard(),
      theme: ThemeData.light().copyWith(
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      themeMode: spark.dark ? ThemeMode.dark : ThemeMode.light,
    );
  }
}
