import 'package:emergent_stocks/effects/dark.dart';
import 'package:emergent_stocks/effects/navigation.dart';
import 'package:emergent_stocks/effects/database.dart';
import 'package:emergent_stocks/features/stocks_dashboard/emergency_stocks.dart';
import 'package:flutter/material.dart';

import 'main.dart';

export 'package:emergent_stocks/ui.dart';
export 'package:signals/signals.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SignalsObserver.instance = null;
  runApp(Application());
}

class Application extends UI {
  const Application({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: darkSignal() ? ThemeMode.dark : ThemeMode.light,
      home: db.loading()
          ? Center(child: CircularProgressIndicator())
          : EmergencyStocks(),
    );
  }
}
