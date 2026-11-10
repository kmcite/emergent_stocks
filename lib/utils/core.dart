import 'package:flutter/widgets.dart';

// The reactive core: every value is a Source, everything that reacts is a
// ConsumerMixin.
//
// Versions: one global clock stamps every change. A source's version only
// moves when its value actually changed (a Signal skips equal writes, a
// Computed skips equal results), and a consumer remembers the version of each
// source it read. That is how a consumer answers "did anything I care about
// move?" — and why an effect, or a widget, is not woken when a derivation
// above it recomputed to an equal value.
//
// Equality: `==` by default. Pass `equals` when a derivation builds a new
// collection on every run (`setEquals`, `listEquals`, `mapEquals` from
// foundation), and an equal result keeps the old version.
//
// Name: Source.name is optional and only used for debugging, which is why it
// shows up in toString and in error messages.

/// Monotonic clock shared by every [Source].
int globalVersion = 0;

/// Consumers currently collecting dependencies, innermost last.
final globalConsumers = <ConsumerMixin>[];

/// A consumer driven by a plain callback, for listeners that do not read
/// through the graph (the router subscribes to its page stack this way).
class Consumer(
  @override final void Function() onNotify,
) with ConsumerMixin;

/// Runs [untracking] with nothing tracking, so the reads inside it create no
/// dependencies.
T untrack<T>(T Function() untracking) {
  final copy = globalConsumers.toList();
  globalConsumers.clear();
  try {
    return untracking();
  } finally {
    globalConsumers
      ..clear()
      ..addAll(copy);
  }
}

/// Runs [track] as [consumer], recording every [Source] it reads.
///
/// The dependency set is rebuilt on each run: sources that are no longer read
/// lose their edge and their recorded version.
T track<T>(ConsumerMixin consumer, T Function() track) {
  final previous = consumer.sources.toSet();
  consumer.sources.clear();
  globalConsumers.add(consumer);
  try {
    return track();
  } finally {
    globalConsumers.removeLast();
    for (final source in previous) {
      if (!consumer.sources.contains(source)) {
        source.consumers.remove(consumer);
        consumer.versions.remove(source);
      }
    }
  }
}

/// Something that reads [Source]s and is told when they change.
mixin ConsumerMixin {
  /// Sources read during the last run.
  final sources = <Source>{};

  /// Version each source had when it was last read.
  final versions = <Source, int>{};

  /// Called when a source changed.
  VoidCallback get onNotify;

  /// Drops every dependency, so nothing keeps notifying this consumer.
  void dispose() {
    for (final source in sources) {
      source.consumers.remove(this);
    }
    sources.clear();
    versions.clear();
  }

  /// Reports whether any observed source moved past the recorded version.
  ///
  /// Stale computeds are pulled up to date first, so the comparison sees the
  /// fresh version rather than the one they are about to replace.
  bool get hasChanged {
    if (versions.isEmpty) return true;
    for (final entry in versions.entries) {
      final source = entry.key;
      source.refresh();
      if (source.version != entry.value) return true;
    }
    return false;
  }
}

/// A readable node of the graph.
class Source {
  Source({this.name});

  /// Optional label used by [toString] and in error messages.
  final String? name;

  final consumers = <ConsumerMixin>{};

  /// Version of the last change. Equal versions mean nothing moved.
  int version = ++globalVersion;

  /// Records the read, then hands [payload] back untouched.
  ///
  /// This is the only place an edge is created, so reactive collection
  /// accessors read by wrapping their result: `link(items[i])`.
  T link<T>(T payload) {
    final active = globalConsumers.lastOrNull;
    if (active != null) {
      active.sources.add(this);
      consumers.add(active);
      active.versions[this] = version;
    }
    return payload;
  }

  /// Brings this source up to date before a version comparison. Pushed sources
  /// are always current; [Computed] recomputes while it is stale.
  void refresh() {}

  /// Publishes a change: stamps a new version and notifies every consumer.
  void notifyListeners() {
    version = ++globalVersion;
    for (final consumer in consumers.toList()) {
      consumer.onNotify();
    }
  }

  /// Subscribes [consumer] without reading anything, so it hears every change.
  VoidCallback subscribe(ConsumerMixin consumer) {
    consumers.add(consumer);
    return () => consumers.remove(consumer);
  }

  @override
  String toString() => name == null ? '$runtimeType' : '$runtimeType($name)';
}

// ─── Primitives ─────────────────────────────────────────────────────────

/// Compares the previous and the next value of a [Signal] or [Computed].
///
/// The default is `==`; pass something looser when the value is rebuilt every
/// time, e.g. `equals: setEquals` for a computed that returns a fresh set.
typedef Equality<T> = bool Function(T previous, T next);

bool _same<T>(T previous, T next) => previous == next;

/// A writable cell.
class Signal<T> extends Source {
  Signal(this._value, {super.name, Equality<T>? equals})
    : _equals = equals ?? _same;

  final Equality<T> _equals;

  T _value;

  T get value => link(_value);

  set value(T newValue) {
    // Equality gate: a write the cell already holds must not invalidate the
    // graph, so a no-op assignment wakes nobody.
    if (_equals(_value, newValue)) return;
    _value = newValue;
    notifyListeners();
  }

  /// Alias for [value], for call sites that read more naturally as state.
  T get state => value;
  set state(T newValue) => value = newValue;

  /// Reads the value and optionally transforms it: `count()` or
  /// `count((current) => current + 1)`.
  T call([T Function(T current)? update]) {
    if (update != null) {
      value = update(value);
    }
    return value;
  }

  void set(T newValue) => value = newValue;
}

mixin Callable<T> {
  T call();
}

/// A memoized derivation: marked by pushes, evaluated on read.
///
/// Pass [equals] when the computation produces a new collection on every run,
/// so an equal result keeps the old version instead of waking its consumers:
/// `computed(() => {...}, equals: setEquals)`.
class Computed<T> extends Source with ConsumerMixin, Callable<T> {
  Computed(this._compute, {super.name, Equality<T>? equals})
    : _equals = equals ?? _same;

  final T Function() _compute;
  final Equality<T> _equals;

  T? _cached;
  bool _hasValue = false;
  bool _dirty = true;
  bool _computing = false;

  @override
  VoidCallback get onNotify => _markDirty;

  /// Its value is unknown until it is read, so the change is passed on and
  /// each consumer decides on its next read whether this computed really
  /// produced something new.
  void _markDirty() {
    if (_dirty) return;
    _dirty = true;
    for (final consumer in consumers.toList()) {
      consumer.onNotify();
    }
  }

  @override
  void refresh() {
    if (_hasValue && !_dirty) return;
    // Mark clean before pulling: if a dependency leads back here, this
    // computed answers with its last value instead of recursing.
    _dirty = false;
    if (!_hasValue || hasChanged) _evaluate();
  }

  void _evaluate() {
    if (_computing) {
      throw StateError(
        '$this read itself while computing; a derivation must not depend on '
        'its own value.',
      );
    }
    _computing = true;
    try {
      final next = track(this, _compute);
      final changed = !_hasValue || !_equals(_cached as T, next);
      _cached = next;
      _hasValue = true;
      // Only a real change earns a new version, so a recompute that lands on
      // an equal value leaves every consumer where it was.
      if (changed) version = ++globalVersion;
    } finally {
      _computing = false;
    }
  }

  T get value {
    // Refresh before linking so a consumer snapshots the fresh version, not
    // the one this computed is about to replace.
    refresh();
    return link(_cached as T);
  }

  T get state => value;

  @override
  T call() => value;
}

/// Runs its body for side effects, once per change that reaches it.
class Effect with ConsumerMixin {
  Effect(this._callback, {this.name});

  final VoidCallback _callback;

  /// Optional label used by [toString].
  final String? name;

  @override
  VoidCallback get onNotify => () {
    if (hasChanged) track(this, _callback);
  };

  @override
  String toString() => name == null ? 'Effect' : 'Effect($name)';
}

// ─── Factories ──────────────────────────────────────────────────────────

Signal<T> signal<T>(T initialValue, {String? name, Equality<T>? equals}) =>
    Signal<T>(initialValue, name: name, equals: equals);

Signal<T?> nullSignal<T>({String? name, Equality<T?>? equals}) =>
    Signal<T?>(null, name: name, equals: equals);

Computed<T> computed<T>(
  T Function() compute, {
  String? name,
  Equality<T>? equals,
}) => Computed<T>(compute, name: name, equals: equals);

/// Creates an [Effect] and returns its [Effect.dispose], so the caller can
/// cancel it: `final cancel = effect(...); cancel();`.
VoidCallback effect(void Function() callback, {String? name}) =>
    Effect(callback, name: name).dispose;

// ─── Widget Consumer ────────────────────────────────────────────────────

/// A [StatelessWidget] whose [build] collects dependencies and rebuilds when
/// they move.
///
/// Only reads made while [build] runs are observed. Lazy children — a
/// `ListView`'s `itemBuilder`, a `FutureBuilder`'s callbacks — run after the
/// build returns, with nothing tracking, so a signal read there is never
/// attributed to an element and nothing would ever rebuild. Read the signal in
/// [build] instead and pass the value down.
abstract class SignalConsumer extends StatelessWidget {
  const SignalConsumer({super.key});

  @override
  Widget build(BuildContext context);

  @override
  StatelessElement createElement() => SignalElement(this);
}

class SignalElement extends StatelessElement with ConsumerMixin {
  SignalElement(super.widget);

  @override
  Widget build() => track(this, super.build);

  @override
  void unmount() {
    dispose();
    super.unmount();
  }

  /// Rebuilds only when a source this element read actually moved. A
  /// derivation that recomputed to an equal value keeps its version, so the
  /// element is left alone.
  @override
  VoidCallback get onNotify => () {
    if (hasChanged) markNeedsBuild();
  };
}
