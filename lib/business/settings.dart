import 'dart:async';

import 'package:emergent_stocks/sync/sync_config.dart';
import 'package:emergent_stocks/utils/core.dart';
import 'package:emergent_stocks/utils/provider.dart';
import 'package:flutter/material.dart';

import 'package:emergent_stocks/services/database.dart';

final settingsProvider = provider(
  (f) => SettingsSignals(databaseServiceProvider(f)),
);

class SettingsSignals(final DatabaseService db) {
  static const themeModeKey = 'THEME_MODE';
  static const themeManualKey = 'theme_manual_last';

  StreamSubscription? _subscription;

  final themeMode = signal(ThemeMode.system);

  final syncEnabled = signal(false);
  final syncBaseUrl = signal('');
  final syncSuperuserEmail = signal('');
  final syncSuperuserPassword = signal('');

  /// Shown on the settings screen after save / sync test.
  final syncStatusMessage = signal<String?>(null);

  this {
    _subscription = db.watchKey(themeModeKey).listen((value) {
      themeMode.state = _themeFromPref(value);
    });
    unawaited(db.ensureReady().then((_) => _loadSyncFromPrefs()));
  }

  static ThemeMode _themeFromPref(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    'false' => ThemeMode.light,
    'true' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  static String _prefFromTheme(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };

  void _loadSyncFromPrefs() {
    syncEnabled.set(db.read(SyncConfig.enabledKey) == 'true');
    syncBaseUrl.set(
      db.read(SyncConfig.baseUrlKey) ?? SyncConfig.defaultTermuxBaseUrl,
    );
    syncSuperuserEmail.set(db.read(SyncConfig.superuserEmailKey) ?? '');
    syncSuperuserPassword.set(db.read(SyncConfig.superuserPasswordKey) ?? '');
  }

  void setThemeMode(ThemeMode mode) {
    if (mode != ThemeMode.system) {
      db.save(themeManualKey, _prefFromTheme(mode));
    }
    db.save(themeModeKey, _prefFromTheme(mode));
  }

  bool get followsSystem => themeMode() == ThemeMode.system;

  void setFollowSystem(bool follow) {
    if (follow) {
      setThemeMode(ThemeMode.system);
      return;
    }
    final manual = _themeFromPref(db.read(themeManualKey));
    setThemeMode(
      manual == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light,
    );
  }

  void setManualTheme(ThemeMode mode) {
    if (mode == ThemeMode.system || followsSystem) return;
    setThemeMode(mode);
  }

  void applyTermuxDefaults() {
    if (syncBaseUrl().trim().isEmpty) {
      syncBaseUrl.set(SyncConfig.defaultTermuxBaseUrl);
    }
  }

  void persistSyncSettings() {
    db.save(SyncConfig.enabledKey, syncEnabled() ? 'true' : 'false');
    db.save(SyncConfig.baseUrlKey, syncBaseUrl().trim());
    db.save(SyncConfig.superuserEmailKey, syncSuperuserEmail().trim());
    db.save(SyncConfig.superuserPasswordKey, syncSuperuserPassword());
    db.removePref(SyncConfig.tokenKey);
    syncStatusMessage.set('Saved. Sign-in will run on the next sync.');
  }

  void setSyncStatus(String? message) => syncStatusMessage.set(message);

  void dispose() {
    _subscription?.cancel();
  }
}
