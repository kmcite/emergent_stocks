import 'dart:async';

import 'package:emergent_stocks/utils/core.dart';
import 'package:flutter/material.dart';

import 'collections.dart';

typedef RouteGuard = List<SignalConsumer> Function(
  List<SignalConsumer> current,
  List<SignalConsumer> proposed,
);

class AppRouter extends RouterConfig<List<SignalConsumer>> {
  AppRouter._({
    required AppDelegate delegate,
    required BackButtonDispatcher backButtonDispatcher,
  }) : _delegate = delegate,
       super(
         routerDelegate: delegate,
         backButtonDispatcher: backButtonDispatcher,
       );

  factory AppRouter({
    required SignalConsumer home,
    GlobalKey<NavigatorState>? navigatorKey,
    List<RouteGuard> guards = const [],
    Future<bool> Function()? onExitAttempt,
  }) {
    final key = navigatorKey ?? GlobalKey<NavigatorState>();
    final delegate = AppDelegate(
      navigatorKey: key,
      initialPages: [home],
      guards: guards,
      onExitAttempt: onExitAttempt,
    );
    return AppRouter._(
      delegate: delegate,
      // A Router only listens for system back gestures when it is given a
      // dispatcher. `MaterialApp.router` builds the Router from this config, and
      // without a dispatcher the back event never reaches `popRoute`, so the
      // framework falls back to closing the app.
      backButtonDispatcher: RootBackButtonDispatcher(),
    );
  }

  final AppDelegate _delegate;

  GlobalKey<NavigatorState> get navigatorKey => _delegate.navigatorKey!;

  Future<T?> push<T>(SignalConsumer page) => _delegate.push<T>(page);
  void pop<T>([T? result]) => _delegate.pop<T>(result);
  void replace(SignalConsumer page) => _delegate.replace(page);
  void clearAndNavigate(SignalConsumer page) =>
      _delegate.clearAndNavigate(page);
}

class AppDelegate extends RouterDelegate<List<SignalConsumer>>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<List<SignalConsumer>> {
  AppDelegate({
    required this.navigatorKey,
    required List<SignalConsumer> initialPages,
    this.guards = const [],
    this.onExitAttempt,
  }) : pages = listSignal(initialPages) {
    pages.subscribe(Consumer(notifyListeners));
  }

  @override
  final GlobalKey<NavigatorState>? navigatorKey;

  final ListSignal<SignalConsumer> pages;
  final List<RouteGuard> guards;
  final Future<bool> Function()? onExitAttempt;

  // Tracks return values (futures) for each pushed page instance
  final Map<SignalConsumer, Completer<dynamic>> _completers = {};

  @override
  List<SignalConsumer> get currentConfiguration => pages.toList();

  void _applyTransition(
    List<SignalConsumer> Function(List<SignalConsumer> current) builder,
  ) {
    final current = List<SignalConsumer>.from(pages);
    var proposed = builder(current);

    for (final guard in guards) {
      proposed = guard(current, proposed);
    }

    if (proposed.isEmpty) return;

    // Complete futures for any pages removed during this transition (e.g. swipe-to-back or clear)
    for (final page in current) {
      if (!proposed.contains(page)) {
        _completers.remove(page)?.complete(null);
      }
    }

    pages.clear();
    pages.addAll(proposed);
  }

  Future<T?> push<T>(SignalConsumer page) {
    final completer = Completer<T?>();
    _completers[page] = completer;
    _applyTransition((current) => [...current, page]);
    return completer.future;
  }

  void pop<T>([T? result]) {
    if (pages.length > 1) {
      final topPage = pages.last;
      _completers.remove(topPage)?.complete(result);
      _applyTransition(
        (current) => current.length > 1
            ? current.sublist(0, current.length - 1)
            : current,
      );
    }
  }

  void replace(SignalConsumer page) {
    _applyTransition(
      (current) => [
        ...current.take(current.isNotEmpty ? current.length - 1 : 0),
        page,
      ],
    );
  }

  void clearAndNavigate(SignalConsumer page) {
    _applyTransition((current) => [page]);
  }

  @override
  Future<bool> popRoute() async {
    if (pages.length > 1) {
      pop();
      return true; // Handled internally
    }

    // Dialogs and other imperatively pushed routes sit above the pages, so a
    // back gesture should close those first instead of closing the app.
    final navigator = navigatorKey?.currentState;
    if (navigator != null && navigator.canPop()) {
      return navigator.maybePop();
    }

    if (onExitAttempt != null) {
      // `onExitAttempt` returns true when the user confirmed the exit. A
      // `popRoute` result of false lets the framework close the app, while true
      // consumes the back gesture.
      return !await onExitAttempt!();
    }
    return true; // Swallow back event by default on single screen
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<NavigationNotification>(
      // A navigator holding a single page reports that it cannot pop, which
      // makes the platform close the activity before Flutter ever sees the
      // gesture. This app always handles back itself (see [popRoute]), so the
      // framework must stay in charge of the back event.
      onNotification: (notification) {
        if (notification.canHandlePop) return false;
        context.dispatchNotification(
          NavigationNotification(canHandlePop: true),
        );
        return true;
      },
      child: Navigator(
        key: navigatorKey,
        pages: [
          for (final page in pages)
            MaterialPage(
              key: ValueKey(page),
              child: page,
            ),
        ],
        onDidRemovePage: (_) {
          if (pages.length > 1) {
            // Swipe-to-back gesture intercepted here
            final topPage = pages.last;
            _completers.remove(topPage)?.complete(null);
            _applyTransition(
              (current) => current.sublist(0, current.length - 1),
            );
          }
        },
      ),
    );
  }

  @override
  Future<void> setNewRoutePath(List<SignalConsumer> configuration) async {
    _applyTransition((current) => configuration);
  }
}
