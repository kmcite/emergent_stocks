import 'package:flutter/widgets.dart';

// ─── Provider System ────────────────────────────────────────────────────

typedef ProviderCreate<T> = T Function(BuildContext context);

/// A token that identifies a piece of state managed by a [ProviderContainer].
///
/// Providers are read through the container attached to the nearest
/// [ProviderScope], which guarantees a single instance per container:
/// `myProvider(context)` or `context(myProvider)`.
class Provider<T> {
  const Provider.internal(this._create, {this.name});

  final ProviderCreate<T>? _create;

  /// Optional label used in error messages for easier debugging.
  final String? name;

  /// Reads this provider's (cached) value from the enclosing scope.
  T call(BuildContext context) => ProviderScope.of(context).read(this, context);

  @override
  String toString() => name ?? 'Provider<$T>';
}

/// A [Provider] whose value must be supplied via [override] in a
/// [ProviderScope] before it is first read (e.g. async-initialized
/// services created in `main`).
class LazyProvider<T> extends Provider<T> {
  const LazyProvider.internal({super.name}) : super.internal(null);

  Override<T> override(T value) => Override<T>(this, value);
}

/// A compile-time checked value replacement for a single [Provider].
class Override<T> {
  const Override(this.provider, this.value);

  final Provider<T> provider;
  final T value;
}

class ProviderContainer {
  ProviderContainer({List<Override<Object?>> overrides = const []}) {
    for (final override in overrides) {
      _cache[override.provider] = override.value;
    }
  }

  final Map<Provider<Object?>, Object?> _cache = {};

  /// Providers currently being created, used to detect circular dependencies.
  final Set<Provider<Object?>> _creating = {};

  /// Returns the instance for [provider], creating it once and caching it,
  /// unless an override or cached value already exists.
  T read<T>(Provider<T> provider, BuildContext context) {
    if (_cache.containsKey(provider)) {
      return _cache[provider] as T;
    }
    final create = provider._create;
    if (create == null) {
      throw StateError(
        'LazyProvider "${provider.name ?? provider}" was read before an '
        'override was provided in ProviderScope.',
      );
    }
    if (!_creating.add(provider)) {
      throw StateError(
        'Circular dependency detected while resolving "${provider.name}".',
      );
    }
    try {
      final instance = create(context);
      _cache[provider] = instance;
      return instance;
    } finally {
      _creating.remove(provider);
    }
  }

  bool isCreated(Provider<Object?> provider) => _cache.containsKey(provider);

  void dispose() {
    for (final instance in _cache.values) {
      if (instance is ChangeNotifier) {
        instance.dispose();
      }
    }
    _cache.clear();
  }
}

Provider<T> provider<T>(ProviderCreate<T> create, {String? name}) =>
    Provider<T>.internal(create, name: name ?? '$T');

LazyProvider<T> lazyProvider<T>({String? name}) =>
    LazyProvider<T>.internal(name: name ?? '$T');

class ProviderScope extends StatefulWidget {
  const ProviderScope({
    super.key,
    this.overrides = const [],
    required this.child,
  });

  final List<Override<Object?>> overrides;
  final Widget child;

  @override
  State<ProviderScope> createState() => _ProviderScopeState();

  static ProviderContainer of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_InheritedProviderScope>();
    assert(scope != null, 'No ProviderScope found in context');
    return scope!.container;
  }
}

class _ProviderScopeState extends State<ProviderScope> {
  /// Created once per scope so cached instances survive rebuilds.
  late final ProviderContainer _container = ProviderContainer(
    overrides: widget.overrides,
  );

  @override
  void dispose() {
    _container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedProviderScope(
      container: _container,
      child: widget.child,
    );
  }
}

class _InheritedProviderScope extends InheritedWidget {
  const _InheritedProviderScope({
    required this.container,
    required super.child,
  });

  final ProviderContainer container;

  @override
  bool updateShouldNotify(_InheritedProviderScope oldWidget) {
    return container != oldWidget.container;
  }
}

extension ProviderExtension on BuildContext {
  /// Reads [provider] through the nearest [ProviderScope].
  T read<T>(Provider<T> provider) =>
      ProviderScope.of(this).read(provider, this);

  /// Same as [read], kept for the `context(myProvider)` call syntax.
  T call<T>(Provider<T> provider) => read(provider);
}
