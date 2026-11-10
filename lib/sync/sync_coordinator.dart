import 'dart:async';
import 'dart:developer' show log;

import 'package:emergent_stocks/models/sync_outbox_entry.dart';
import 'package:emergent_stocks/services/database.dart';
import 'package:emergent_stocks/utils/provider.dart';

import 'pocketbase_auth.dart';
import 'sync_config.dart';
import 'sync_engine.dart';

final syncCoordinatorProvider = provider((f) {
  final coordinator = SyncCoordinator(databaseServiceProvider(f));
  coordinator.start();
  return coordinator;
});

/// Background hybrid sync. The rest of the app only talks to [DatabaseService].
class SyncCoordinator {
  SyncCoordinator(this._db) : _engine = SyncEngine(_db);

  final DatabaseService _db;
  final SyncEngine _engine;

  static const _period = Duration(seconds: 45);

  Timer? _timer;
  bool _cycleInFlight = false;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    _db.ensureReady().then((_) {
      _schedulePeriodic();
      _listenForLocalChanges();
      unawaited(_runCycle());
    });
  }

  void _schedulePeriodic() {
    _timer?.cancel();
    _timer = Timer.periodic(_period, (_) => unawaited(_runCycle()));
  }

  Timer? _pushDebounce;

  void _listenForLocalChanges() {
    _db.watch<SyncOutboxEntry>().listen((_) {
      _pushDebounce?.cancel();
      _pushDebounce = Timer(const Duration(seconds: 2), () {
        unawaited(_runCycle());
      });
    });
  }

  Future<void> _runCycle() async {
    if (_cycleInFlight) return;
    final config = SyncConfig.fromDatabase(_db);
    if (!config.isActive) return;

    _cycleInFlight = true;
    try {
      await _engine.runCycle(config);
    } catch (e, st) {
      log('Sync cycle error: $e', name: 'SyncCoordinator', stackTrace: st);
    } finally {
      _cycleInFlight = false;
    }
  }

  /// Manual sync trigger without exposing backend details.
  Future<void> syncNow() => _runCycle();

  Future<void> testConnectionAndSync() async {
    final config = SyncConfig.fromDatabase(_db);
    if (!config.isActive) {
      throw StateError('Turn on cloud sync and set a server URL first.');
    }
    final auth = PocketBaseAuth(_db);
    auth.clearToken();
    await auth.loginAndStore(config);
    await _runCycle();
  }

  void dispose() {
    _timer?.cancel();
    _pushDebounce?.cancel();
    _timer = null;
    _pushDebounce = null;
  }
}
