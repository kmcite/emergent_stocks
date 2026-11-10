import 'remote_stock_record.dart';

/// Backend-agnostic sync transport. Implementations live under `remote/`.
abstract class RemoteStockGateway {
  Future<List<RemoteStockRecord>> fetchUpdatedSince(int updatedAfterMs);

  /// Returns the canonical remote id for the saved record.
  Future<String> upsert(RemoteStockRecord record);

  Future<void> deleteByRemoteId(String remoteId);
}
