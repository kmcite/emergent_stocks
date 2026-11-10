import 'dart:convert';

import 'package:emergent_stocks/services/database.dart';
import 'package:http/http.dart' as http;

import 'remote/pocketbase_stock_gateway.dart';
import 'sync_config.dart';

/// Obtains and refreshes API tokens for the optional sync backend.
class PocketBaseAuth {
  PocketBaseAuth(this._db, {http.Client? client})
    : _client = client ?? http.Client();

  final DatabaseService _db;
  final http.Client _client;

  /// Ensures [SyncConfig.authToken] is present; persists a new token on success.
  Future<SyncConfig> ensureAuthenticated(SyncConfig config) async {
    if (!config.isActive) return config;

    final existing = config.authToken;
    if (existing != null && existing.isNotEmpty) {
      return config;
    }

    final token = await _login(config);
    if (token == null) {
      throw const RemoteSyncException(
        'Could not sign in to the sync server. Check URL and credentials in Settings.',
      );
    }

    _db.save(SyncConfig.tokenKey, token);
    return SyncConfig.fromDatabase(_db);
  }

  /// Force a new login (e.g. “Test connection” in Settings).
  Future<String?> loginAndStore(SyncConfig config) async {
    final token = await _login(config);
    if (token != null) {
      _db.save(SyncConfig.tokenKey, token);
    }
    return token;
  }

  void clearToken() => _db.removePref(SyncConfig.tokenKey);

  Future<String?> _login(SyncConfig config) async {
    final identity = _db.read(SyncConfig.superuserEmailKey)?.trim() ?? '';
    final password = _db.read(SyncConfig.superuserPasswordKey) ?? '';
    if (identity.isEmpty || password.isEmpty) return null;

    final base = config.baseUrl!;
    final root = base.replace(
      path: base.path.replaceAll(RegExp(r'/+$'), ''),
    );

    final attempts = [
      'api/collections/_superusers/auth-with-password',
      'api/admins/auth-with-password',
    ];

    final body = jsonEncode({'identity': identity, 'password': password});
    const headers = {'Content-Type': 'application/json'};

    for (final segment in attempts) {
      final uri = root.replace(path: '').resolve(segment);
      final response = await _client.post(uri, headers: headers, body: body);
      if (response.statusCode == 404) continue;
      if (response.statusCode >= 400) {
        throw RemoteSyncException(
          'Sign-in failed (${response.statusCode}): ${response.body}',
        );
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final token = decoded['token'] as String?;
      if (token != null && token.isNotEmpty) return token;
    }

    throw const RemoteSyncException(
      'Sign-in endpoint not found. Is PocketBase running on this URL?',
    );
  }
}
