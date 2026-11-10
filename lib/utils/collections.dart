import 'dart:collection';

import 'core.dart';

class ListSignal<E> extends Signal<List<E>> with ListMixin<E> {
  ListSignal([List<E>? initial]) : super(initial ?? <E>[]);

  @override
  int get length => link(value.length);

  @override
  set length(int newValue) {
    if (value.length != newValue) {
      value.length = newValue;
      notifyListeners();
    }
  }

  @override
  E operator [](int index) => link(value[index]);

  @override
  void operator []=(int index, E newValue) {
    if (value[index] != newValue) {
      value[index] = newValue;
      notifyListeners();
    }
  }

  @override
  void add(E element) {
    value.add(element);
    notifyListeners();
  }

  @override
  void addAll(Iterable<E> iterable) {
    if (iterable.isNotEmpty) {
      value.addAll(iterable);
      notifyListeners();
    }
  }

  @override
  bool remove(Object? element) {
    final removed = value.remove(element);
    if (removed) {
      notifyListeners();
    }
    return removed;
  }

  @override
  void clear() {
    if (value.isNotEmpty) {
      value.clear();
      notifyListeners();
    }
  }
}

class MapSignal<K, V> extends Signal<Map<K, V>> with MapMixin<K, V> {
  MapSignal([Map<K, V>? initial]) : super(initial ?? <K, V>{});

  @override
  V? operator [](Object? key) => link(value[key]);

  @override
  void operator []=(K key, V newValue) {
    if (value[key] != newValue) {
      value[key] = newValue;
      notifyListeners();
    }
  }

  @override
  void clear() {
    if (value.isNotEmpty) {
      value.clear();
      notifyListeners();
    }
  }

  @override
  Iterable<K> get keys => link(value.keys);

  @override
  Iterable<V> get values => link(value.values);

  @override
  int get length => link(value.length);

  @override
  bool get isEmpty => link(value.isEmpty);

  @override
  bool get isNotEmpty => link(value.isNotEmpty);

  @override
  bool containsKey(Object? key) => link(value.containsKey(key));

  @override
  // ignore: avoid_renaming_method_parameters
  bool containsValue(Object? val) => link(value.containsValue(val));

  @override
  V? remove(Object? key) {
    if (value.containsKey(key)) {
      final result = value.remove(key);
      notifyListeners();
      return result;
    }
    return null;
  }
}

class SetSignal<E> extends Signal<Set<E>> with SetMixin<E> {
  SetSignal([Set<E>? initial]) : super(initial ?? <E>{});

  @override
  bool add(E element) {
    final added = value.add(element);
    if (added) {
      notifyListeners();
    }
    return added;
  }

  @override
  bool contains(Object? element) => link(value.contains(element));

  @override
  Iterator<E> get iterator => link(value.iterator);

  @override
  int get length => link(value.length);

  @override
  bool get isEmpty => link(value.isEmpty);

  @override
  bool get isNotEmpty => link(value.isNotEmpty);

  @override
  E? lookup(Object? element) => link(value.lookup(element));

  @override
  bool remove(Object? element) {
    final removed = value.remove(element);
    if (removed) {
      notifyListeners();
    }
    return removed;
  }

  @override
  void clear() {
    if (value.isNotEmpty) {
      value.clear();
      notifyListeners();
    }
  }

  @override
  Set<E> toSet() => link(value.toSet());
}

final listSignal = ListSignal.new;
final mapSignal = MapSignal.new;
final setSignal = SetSignal.new;
