import 'dart:convert';

import 'package:http/http.dart' as http;

import '../sync_config.dart';
import 'remote_stock_gateway.dart';
import 'remote_stock_record.dart';

/// PocketBase REST adapter — not referenced outside `lib/sync/`.
class PocketBaseStockGateway implements RemoteStockGateway {
  PocketBaseStockGateway(this._config, {http.Client? client})
    : _client = client ?? http.Client();

  final SyncConfig _config;
  final http.Client _client;

  Uri get _recordsBase => _config.baseUrl!.replace(
    path:
        '${_config.baseUrl!.path.replaceAll(RegExp(r'/+$'), '')}'
        '/api/collections/${_config.collectionName}/records',
  );

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_config.authToken != null)
      'Authorization': _config.authToken!,
  };

  @override
  Future<List<RemoteStockRecord>> fetchUpdatedSince(int updatedAfterMs) async {
    final filter = Uri.encodeQueryComponent('updated_ms>$updatedAfterMs');
    final url =
        '$_recordsBase?page=1&perPage=500&sort=updated_ms&filter=$filter';
    final response = await _client.get(Uri.parse(url), headers: _headers);
    if (response.statusCode >= 400) {
      throw RemoteSyncException(
        'Pull failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final items = decoded['items'] as List<dynamic>? ?? [];
    final records = <RemoteStockRecord>[];
    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;
      final record = RemoteStockRecord.fromJson(item);
      if (record != null) records.add(record);
    }
    return records;
  }

  @override
  Future<String> upsert(RemoteStockRecord record) async {
    final body = jsonEncode(record.toPayloadJson());
    final remoteId = record.remoteId;

    if (remoteId != null && remoteId.isNotEmpty) {
      final uri = Uri.parse('$_recordsBase/$remoteId');
      final response = await _client.patch(uri, headers: _headers, body: body);
      if (response.statusCode >= 400) {
        throw RemoteSyncException(
          'Push update failed (${response.statusCode}): ${response.body}',
        );
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return decoded['id'] as String? ?? remoteId;
    }

    final response = await _client.post(_recordsBase, headers: _headers, body: body);
    if (response.statusCode >= 400) {
      throw RemoteSyncException(
        'Push create failed (${response.statusCode}): ${response.body}',
      );
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final id = decoded['id'] as String?;
    if (id == null || id.isEmpty) {
      throw const RemoteSyncException('Push create returned no id');
    }
    return id;
  }

  @override
  Future<void> deleteByRemoteId(String remoteId) async {
    final uri = Uri.parse('$_recordsBase/$remoteId');
    final response = await _client.delete(uri, headers: _headers);
    if (response.statusCode == 404) return;
    if (response.statusCode >= 400) {
      throw RemoteSyncException(
        'Push delete failed (${response.statusCode}): ${response.body}',
      );
    }
  }
}

class RemoteSyncException implements Exception {
  const RemoteSyncException(this.message);
  final String message;

  @override
  String toString() => message;
}
