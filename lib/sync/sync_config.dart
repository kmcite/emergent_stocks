import 'package:emergent_stocks/services/database.dart';

/// Optional backend sync settings stored in the same prefs layer as the app.
/// UI and business code never import PocketBase — only this module reads these keys.
class SyncConfig {
  SyncConfig({
    required this.enabled,
    this.baseUrl,
    this.authToken,
    this.collectionName = defaultCollectionName,
  });

  /// PocketBase collection slug — not user-configurable.
  static const defaultCollectionName = 'emergent_stocks';

  static const enabledKey = 'sync_enabled';
  static const baseUrlKey = 'sync_base_url';
  static const tokenKey = 'sync_auth_token';
  static const superuserEmailKey = 'sync_superuser_email';
  static const superuserPasswordKey = 'sync_superuser_password';
  static const lastPullMsKey = 'sync_last_pull_ms';

  /// Typical PocketBase on Termux (same device).
  static const defaultTermuxBaseUrl = 'http://127.0.0.1:8090';

  final bool enabled;
  final Uri? baseUrl;
  final String? authToken;
  final String collectionName;

  bool get isActive => enabled && baseUrl != null;

  factory SyncConfig.fromDatabase(DatabaseService db) {
    final enabled = db.read(enabledKey) == 'true';
    final urlRaw = db.read(baseUrlKey)?.trim();
    Uri? baseUrl;
    if (urlRaw != null && urlRaw.isNotEmpty) {
      baseUrl = Uri.tryParse(urlRaw);
    }
    final token = db.read(tokenKey)?.trim();
    return SyncConfig(
      enabled: enabled,
      baseUrl: baseUrl,
      authToken: token != null && token.isNotEmpty ? token : null,
      collectionName: defaultCollectionName,
    );
  }

  int lastPullMs(DatabaseService db) {
    final raw = db.read(lastPullMsKey);
    return int.tryParse(raw ?? '') ?? 0;
  }

  void saveLastPullMs(DatabaseService db, int ms) {
    db.save(lastPullMsKey, ms.toString());
  }
}
