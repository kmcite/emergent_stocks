import 'package:objectbox/objectbox.dart';

/// Pending change waiting to be pushed to an optional remote backend.
/// Only [DatabaseService] reads and writes this entity.
@Entity()
class SyncOutboxEntry {
  @Id()
  int id = 0;

  /// ObjectBox id of [EmergentStock] for upserts (0 if unknown).
  int localStockId = 0;

  /// PocketBase record id for deletes when the local row is already gone.
  String remoteId = '';

  /// `upsert` | `delete`
  String operation = 'upsert';

  int enqueuedAtMs = 0;
}
