import 'package:emergent_stocks/business/settings.dart';
import 'package:emergent_stocks/sync/sync_coordinator.dart';
import 'package:emergent_stocks/sync/sync_config.dart';
import 'package:emergent_stocks/ui/theme/liquid_glass.dart';
import 'package:emergent_stocks/utils/core.dart';
import 'package:emergent_stocks/utils/navigation.dart';
import 'package:emergent_stocks/utils/provider.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends SignalConsumer {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context(settingsProvider);
    final sync = context(syncCoordinatorProvider);
    final colors = Theme.of(context).colorScheme;

    return GlassScaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: context.pop,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SectionHeader(title: 'Appearance', icon: Icons.palette_outlined),
          const SizedBox(height: 8),
          GlassPanel(
            child: _ThemeControls(settings: settings),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Cloud sync', icon: Icons.cloud_sync_outlined),
          const SizedBox(height: 8),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 14,
              children: [
                Text(
                  'Optional backup when a sync server runs on this device '
                  '(e.g. PocketBase in Termux). Your bag stays local-first.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.75),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable cloud sync'),
                  value: settings.syncEnabled(),
                  onChanged: (v) => settings.syncEnabled.set(v),
                ),
                TextFormField(
                  initialValue: settings.syncBaseUrl(),
                  decoration: const InputDecoration(
                    labelText: 'Server URL',
                    hintText: 'http://127.0.0.1:8090',
                    prefixIcon: Icon(Icons.link),
                  ),
                  onChanged: settings.syncBaseUrl.set,
                ),
                TextFormField(
                  initialValue: settings.syncSuperuserEmail(),
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Administrator email',
                    prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                  ),
                  onChanged: settings.syncSuperuserEmail.set,
                ),
                TextFormField(
                  initialValue: settings.syncSuperuserPassword(),
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Administrator password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  onChanged: settings.syncSuperuserPassword.set,
                ),
                Text(
                  'Collection: ${SyncConfig.defaultCollectionName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    settings.applyTermuxDefaults();
                    settings.syncBaseUrl.set(SyncConfig.defaultTermuxBaseUrl);
                  },
                  icon: const Icon(Icons.phone_android),
                  label: const Text('Use Termux / localhost defaults'),
                ),
                if (settings.syncStatusMessage() != null)
                  Text(
                    settings.syncStatusMessage()!,
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 13,
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: settings.persistSyncSettings,
                        child: const Text('Save sync settings'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          settings.persistSyncSettings();
                          try {
                            await sync.testConnectionAndSync();
                            if (context.mounted) {
                              settings.setSyncStatus(
                                'Connected and synced successfully.',
                              );
                            }
                          } catch (e) {
                            settings.setSyncStatus('$e');
                          }
                        },
                        child: const Text('Test & sync'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeControls extends StatelessWidget {
  const _ThemeControls({required this.settings});

  final SettingsSignals settings;

  @override
  Widget build(BuildContext context) {
    final followSystem = settings.followsSystem;
    final current = settings.themeMode();
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 14,
      children: [
        Row(
          children: [
            Text(
              'Theme',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            Text(
              'System',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.onSurface.withValues(
                  alpha: followSystem ? 1 : 0.55,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Switch(
              value: followSystem,
              onChanged: settings.setFollowSystem,
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _ThemeTile(
                label: 'Light',
                icon: Icons.light_mode_outlined,
                selected: !followSystem && current == ThemeMode.light,
                enabled: !followSystem,
                onTap: () => settings.setManualTheme(ThemeMode.light),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ThemeTile(
                label: 'Dark',
                icon: Icons.dark_mode_outlined,
                selected: !followSystem && current == ThemeMode.dark,
                enabled: !followSystem,
                onTap: () => settings.setManualTheme(ThemeMode.dark),
              ),
            ),
          ],
        ),
        if (followSystem)
          Text(
            'Following your device appearance. Turn off System to pick Light or Dark.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.65),
            ),
          ),
      ],
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark
        ? Colors.white.withValues(alpha: enabled ? 0.28 : 0.12)
        : Colors.white.withValues(alpha: enabled ? 0.62 : 0.28);

    final fill = enabled
        ? (selected
              ? colors.primary.withValues(alpha: isDark ? 0.28 : 0.22)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.45)))
        : (isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.white.withValues(alpha: 0.18));

    final contentColor = enabled
        ? (selected ? colors.primary : colors.onSurface)
        : colors.onSurface.withValues(alpha: 0.35);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected && enabled
                  ? colors.primary.withValues(alpha: 0.65)
                  : border,
              width: selected && enabled ? 1.6 : 1,
            ),
            color: fill,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: contentColor, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: contentColor,
                  fontWeight: selected && enabled
                      ? FontWeight.bold
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}
