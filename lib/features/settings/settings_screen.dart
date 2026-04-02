import 'package:emergent_stocks/domain/emergent_stock.dart';
import 'package:emergent_stocks/effects/dark.dart';
import 'package:emergent_stocks/effects/database.dart';
import 'package:emergent_stocks/effects/navigation.dart';
import 'package:emergent_stocks/effects/stocks.dart';
import 'package:emergent_stocks/features/settings/settings_section.dart';
import 'package:emergent_stocks/features/settings/settings_tile.dart';
import 'package:flutter/material.dart';

import '../../main.dart';

class SettingsScreen extends UI {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          onPressed: () => navigateBack(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appearance Section
            SettingsSection(
              title: 'Appearance',
              children: [
                SettingsTile(
                  title: 'Dark Mode',
                  subtitle: darkSignal() ? 'Enabled' : 'Disabled',
                  leading: Icon(
                    darkSignal() ? Icons.dark_mode : Icons.light_mode,
                  ),
                  trailing: Switch(
                    value: darkSignal(),
                    onChanged: (_) => toggleDarkMode(),
                  ),
                  onTap: () => toggleDarkMode(),
                ),
              ],
            ),

            // Data Management Section
            SettingsSection(
              title: 'Data Management',
              children: [
                SettingsTile(
                  title: 'Total Stocks',
                  subtitle: '${stocks().length} items',
                  leading: const Icon(Icons.inventory_2_outlined),
                  onTap: () {},
                ),
                SettingsTile(
                  title: 'Clear All Data',
                  subtitle: 'Delete all stock data',
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  onTap: stocks.isEmpty
                      ? null
                      : () {
                          navigateToDialog(
                            AlertDialog(
                              title: const Text('Clear All Data'),
                              content: const Text(
                                'Are you sure you want to delete all stock data? This action cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => navigateBack(),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    db.removeAll<EmergentStock>();
                                    navigateBack();
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Clear All'),
                                ),
                              ],
                            ),
                          );
                        },
                  trailing: const Icon(Icons.chevron_right, color: Colors.red),
                ),
              ],
            ),

            // About Section
            SettingsSection(
              title: 'About',
              children: [
                SettingsTile(
                  leading: const Icon(Icons.help_outline),
                  title: 'Help & Support',
                  subtitle: 'Get help with the app',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    navigateToDialog(
                      AlertDialog(
                        title: const Text('Help & Support'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => navigateBack(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SettingsTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: 'Privacy Policy',
                  subtitle: 'View our privacy policy',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    navigateToDialog(
                      AlertDialog(
                        title: Text('Privacy Policy - Coming Soon'),
                        content: Text(
                          'The Privacy Policy feature will be available in a future update.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => navigateBack(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
