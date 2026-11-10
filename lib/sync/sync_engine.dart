import 'dart:developer' show log;

import 'package:emergent_stocks/models/emergent_stock.dart';
import 'package:emergent_stocks/models/sync_outbox_entry.dart';
import 'package:emergent_stocks/services/database.dart';
import 'package:emergent_stocks/objectbox.g.dart';

import 'remote/pocketbase_stock_gateway.dart';
import 'remote/remote_stock_gateway.dart';
import 'remote/remote_stock_record.dart';
import 'pocketbase_auth.dart';
import 'sync_config.dart';

/// Push/pull orchestration against local ObjectBox. Remote backend is optional.
class SyncEngine {
  SyncEngine(this._db, {this._gateway});

  final DatabaseService _db;
  final RemoteStockGateway? _gateway;

  RemoteStockGateway? gatewayFor(SyncConfig config) {
    if (_gateway != null) return _gateway;
    if (!config.isActive) return null;
    return PocketBaseStockGateway(config);
  }

  /// Push local outbox, then pull remote changes (hybrid).
  Future<void> runCycle(SyncConfig config) async {
    if (!config.isActive) return;

    final auth = PocketBaseAuth(_db);
    final authed = await auth.ensureAuthenticated(config);
    final gateway = gatewayFor(authed);
    if (gateway == null) return;

    await push(gateway);
    await pull(authed, gateway);
  }

  Future<void> push(RemoteStockGateway gateway) async {
    final box = await _db.box<SyncOutboxEntry>();
    final entries = box.getAll()
      ..sort((a, b) => a.enqueuedAtMs.compareTo(b.enqueuedAtMs));

    for (final entry in entries) {
      try {
        if (entry.operation == 'delete') {
          if (entry.remoteId.isNotEmpty) {
            await gateway.deleteByRemoteId(entry.remoteId);
          }
          box.remove(entry.id);
          continue;
        }

        final stock = _db.getEmergentStock(entry.localStockId);
        if (stock == null) {
          box.remove(entry.id);
          continue;
        }

        final remoteId = await gateway.upsert(
          RemoteStockRecord.fromEmergentStock(stock),
        );
        stock.remoteId = remoteId;
        await _db.putEmergentStockFromSync(stock);
        box.remove(entry.id);
      } on RemoteSyncException catch (e, st) {
        log('Sync push paused: $e', name: 'SyncEngine', stackTrace: st);
        break;
      }
    }
  }

  Future<void> pull(SyncConfig config, RemoteStockGateway gateway) async {
    final sinceMs = config.lastPullMs(_db);
    final remoteRows = await gateway.fetchUpdatedSince(sinceMs);
    if (remoteRows.isEmpty) {
      config.saveLastPullMs(_db, DateTime.now().millisecondsSinceEpoch);
      return;
    }

    var maxSeenMs = sinceMs;
    final stockBox = await _db.box<EmergentStock>();

    for (final remote in remoteRows) {
      maxSeenMs = maxSeenMs < remote.updatedAtMs ? remote.updatedAtMs : maxSeenMs;

      EmergentStock? local;
      if (remote.remoteId != null && remote.remoteId!.isNotEmpty) {
        local = stockBox
            .query(EmergentStock_.remoteId.equals(remote.remoteId!))
            .build()
            .findFirst();
      }
      local ??= remote.localId > 0 ? stockBox.get(remote.localId) : null;

      if (local != null && local.updatedAtMs > remote.updatedAtMs) {
        continue;
      }

      if (local != null && _db.hasPendingUpsert(local.id)) {
        continue;
      }

      final merged = remote.applyTo(local);
      await _db.putEmergentStockFromSync(merged);
    }

    config.saveLastPullMs(_db, maxSeenMs);
  }
}
