import 'package:flutter/material.dart';

void navigateBack<T extends Object?>([T? result]) {
  navigatorKey.currentState?.pop<T>(result);
}

Future<T?> navigateTo<T extends Object?>(Widget page) async {
  return navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (_) => page,
    ),
  );
}

Future<T?> navigateToDialog<T extends Object?>(Widget dialog) async {
  return showDialog<T>(
    context: navigatorKey.currentContext!,
    builder: (_) => dialog,
  );
}

Future<T?> navigateUntill<T extends Object?>(Widget page) async {
  return navigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => page,
    ),
    (route) => false,
  );
}

final navigatorKey = GlobalKey<NavigatorState>();
