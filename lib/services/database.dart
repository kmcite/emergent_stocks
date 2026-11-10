import 'dart:async';
import 'dart:developer' show log;

import 'package:emergent_stocks/models/emergent_stock.dart';
import 'package:emergent_stocks/models/sync_outbox_entry.dart';
import 'package:emergent_stocks/utils/provider.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;
import 'package:shared_preferences/shared_preferences.dart';

import '../objectbox.g.dart';

final databaseServiceProvider = provider((f) => DatabaseService());

/// Local source of truth for app data. Optional remote sync reads/writes only
/// through the APIs here (`putEmergentStockFromSync`, outbox, etc.).
class DatabaseService {
  Store? _store;
  SharedPreferences? _prefs;
  final _keyStreams = <String, StreamController<String?>>{};

  late final Future<void> _initFuture;

  DatabaseService() {
    _initFuture = _init();
  }

  Future<void> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    _store = await openStore(directory: join(dir.path, 'emergent_stocks'));
    _prefs = await SharedPreferences.getInstance();
    log('INITIALIZED', name: 'DatabaseService');
  }

  Future<void> ensureReady() => _initFuture;

  Store get _requireStore {
    final store = _store;
    if (store == null) {
      throw StateError(
        'DatabaseService not ready yet — call this after a stream '
        'has been watched, or after app bootstrap.',
      );
    }
    return store;
  }

  SharedPreferences get _requirePrefs {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError(
        'DatabaseService not ready yet — call this after a stream '
        'has been watched, or after app bootstrap.',
      );
    }
    return prefs;
  }

  Future<Box<T>> box<T>() async {
    await _initFuture;
    return _requireStore.box<T>();
  }

  /// PREFS API
  void save(String key, String value) {
    unawaited(_requirePrefs.setString(key, value));
    _keyStreams[key]?.add(value);
  }

  String? read(String key) => _requirePrefs.getString(key);

  void removePref(String key) {
    unawaited(_requirePrefs.remove(key));
    _keyStreams[key]?.add(null);
  }

  /// OBJECTBOX API
  int put<T>(T any) {
    if (any is EmergentStock) {
      return putEmergentStock(any);
    }
    return _requireStore.box<T>().put(any);
  }

  List<T> getAll<T>() => _requireStore.box<T>().getAll();
  T? get<T>(int id) => _requireStore.box<T>().get(id);

  int removeAll<T>() => _requireStore.box<T>().removeAll();

  bool remove<T>(int id) => _requireStore.box<T>().remove(id);

  /// Emergent stock — all app mutations should go through these paths.
  int putEmergentStock(EmergentStock stock) {
    stock.updatedAtMs = DateTime.now().millisecondsSinceEpoch;
    final id = _requireStore.box<EmergentStock>().put(stock);
    stock.id = id;
    _enqueueUpsert(id);
    return id;
  }

  /// Used by the sync layer after pull or successful push (no outbox entry).
  Future<int> putEmergentStockFromSync(EmergentStock stock) async {
    await _initFuture;
    return _requireStore.box<EmergentStock>().put(stock);
  }

  EmergentStock? getEmergentStock(int id) {
    return _requireStore.box<EmergentStock>().get(id);
  }

  bool removeEmergentStock(int id) {
    final stock = _requireStore.box<EmergentStock>().get(id);
    if (stock != null) {
      _enqueueDelete(stock);
    }
    return _requireStore.box<EmergentStock>().remove(id);
  }

  bool hasPendingUpsert(int localStockId) {
    final box = _requireStore.box<SyncOutboxEntry>();
    final query = box
        .query(
          SyncOutboxEntry_.localStockId
              .equals(localStockId)
              .and(SyncOutboxEntry_.operation.equals('upsert')),
        )
        .build();
    try {
      return query.findFirst() != null;
    } finally {
      query.close();
    }
  }

  void _enqueueUpsert(int localStockId) {
    final box = _requireStore.box<SyncOutboxEntry>();
    _clearOutboxForStock(localStockId, keepDelete: false);
    box.put(
      SyncOutboxEntry()
        ..localStockId = localStockId
        ..operation = 'upsert'
        ..enqueuedAtMs = DateTime.now().millisecondsSinceEpoch,
    );
  }

  void _enqueueDelete(EmergentStock stock) {
    final box = _requireStore.box<SyncOutboxEntry>();
    _clearOutboxForStock(stock.id, keepDelete: false);
    if (stock.remoteId.isEmpty) return;
    box.put(
      SyncOutboxEntry()
        ..localStockId = stock.id
        ..remoteId = stock.remoteId
        ..operation = 'delete'
        ..enqueuedAtMs = DateTime.now().millisecondsSinceEpoch,
    );
  }

  void _clearOutboxForStock(int localStockId, {required bool keepDelete}) {
    final box = _requireStore.box<SyncOutboxEntry>();
    final query = box
        .query(SyncOutboxEntry_.localStockId.equals(localStockId))
        .build();
    try {
      final entries = query.find();
      for (final entry in entries) {
        if (!keepDelete || entry.operation != 'delete') {
          box.remove(entry.id);
        }
      }
    } finally {
      query.close();
    }
  }

  /// STREAMS
  Stream<List<T>> watch<T>() async* {
    if (_store == null) yield <T>[];
    await _initFuture;
    yield* _requireStore
        .box<T>()
        .query()
        .watch(triggerImmediately: true)
        .map((q) => q.find());
  }

  Stream<String?> watchKey(String key) async* {
    await _initFuture;
    yield _requirePrefs.getString(key);
    yield* _keyStreams
        .putIfAbsent(key, () => StreamController<String?>.broadcast())
        .stream;
  }

  void disposeKey(String key) => _keyStreams.remove(key)?.close();

  void dispose() {
    for (final c in _keyStreams.values) {
      c.close();
    }
    _keyStreams.clear();
    _store?.close();
    log('DISPOSED', name: 'DatabaseService');
  }
}
