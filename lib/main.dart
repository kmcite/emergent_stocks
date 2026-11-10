import 'package:emergent_stocks/business/settings.dart';
import 'package:emergent_stocks/sync/sync_coordinator.dart';
import 'package:emergent_stocks/ui/theme/liquid_glass.dart';
import 'package:emergent_stocks/utils/core.dart';
import 'package:emergent_stocks/utils/navigation.dart';
import 'package:emergent_stocks/utils/provider.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      child: const Application(),
    ),
  );
}

class Application extends SignalConsumer {
  const Application({super.key});

  @override
  Widget build(BuildContext context) {
    context(syncCoordinatorProvider);
    final settings = context(settingsProvider);

    return MaterialApp.router(
      routerConfig: router(context),
      debugShowCheckedModeBanner: false,
      theme: LiquidGlassTheme.theme(Brightness.light),
      darkTheme: LiquidGlassTheme.theme(Brightness.dark),
      themeMode: settings.themeMode(),
    );
  }
}
