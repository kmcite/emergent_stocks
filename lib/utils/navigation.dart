import 'package:emergent_stocks/ui/dashboard_screen.dart';
import 'package:emergent_stocks/utils/core.dart';
import 'package:emergent_stocks/utils/router.dart';
import 'package:flutter/material.dart';

import 'provider.dart';

final navigatorKeyProvider = provider((f) => GlobalKey<NavigatorState>());

final router = provider(
  (f) => AppRouter(
    navigatorKey: navigatorKeyProvider(f),
    home: const DashboardScreen(),
  ),
);

extension NavigationExtension on BuildContext {
  AppRouter get _router => router(this);

  Future<T?> push<T>(SignalConsumer page) => _router.push<T>(page);

  void pop<T>([T? result]) {
    final modalRoute = ModalRoute.of(this);
    if (modalRoute != null && !modalRoute.isFirst) {
      Navigator.of(this).pop(result);
    } else {
      _router.pop(result);
    }
  }

  void replace(SignalConsumer page) => _router.replace(page);

  void clearAndPush(SignalConsumer page) => _router.clearAndNavigate(page);
}
