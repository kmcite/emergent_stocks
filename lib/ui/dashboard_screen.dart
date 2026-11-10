import 'package:emergent_stocks/business/dispense_manager.dart';
import 'package:emergent_stocks/business/stocks_manager.dart';
import 'package:emergent_stocks/models/dispense_record.dart';
import 'package:emergent_stocks/ui/dispense_dialog.dart';
import 'package:emergent_stocks/ui/medicine_bag_screen.dart';
import 'package:emergent_stocks/ui/settings_screen.dart';
import 'package:emergent_stocks/ui/theme/liquid_glass.dart';
import 'package:emergent_stocks/utils/core.dart';
import 'package:emergent_stocks/business/medicine_bag.dart';
import 'package:emergent_stocks/utils/navigation.dart' show router;
import 'package:emergent_stocks/utils/provider.dart';
import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';

class DashboardScreen extends SignalConsumer {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stocks = context(stocksProvider);
    final dispense = context(dispenseProvider);
    final colors = Theme.of(context).colorScheme;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final startOfWeek = now
        .subtract(Duration(days: now.weekday - 1))
        .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0)
        .millisecondsSinceEpoch;

    final items = stocks.stocks.toList();
    final totalUnits = items.fold<int>(0, (sum, s) => sum + s.count);
    final lowStock = items.where((s) => s.count > 0 && s.count < 10).length;
    final outOfStock = items.where((s) => s.count == 0).length;
    final expiring = countExpiringSoon(items);
    final dispensedToday = dispense.totalDispensedSince(startOfDay);
    final dispensedWeek = dispense.totalDispensedSince(startOfWeek);
    final recent = dispense.recent();

    return GlassScaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dispensing dashboard'),
            Text(
              'Inventory & patient handouts',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => router(context).push(const SettingsScreen()),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushDialog(const DispenseDialog()),
        icon: const Icon(Icons.medication_liquid),
        label: const Text('Dispense'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _MetricGrid(
            cells: [
              _MetricCell(
                label: 'SKUs in bag',
                value: '${items.length}',
                icon: Icons.inventory_2_outlined,
                accent: colors.primary,
              ),
              _MetricCell(
                label: 'Units on hand',
                value: '$totalUnits',
                icon: Icons.numbers,
                accent: const Color(0xFF34C759),
              ),
              _MetricCell(
                label: 'Dispensed today',
                value: '$dispensedToday',
                icon: Icons.today_outlined,
                accent: const Color(0xFF5AC8FA),
              ),
              _MetricCell(
                label: 'This week',
                value: '$dispensedWeek',
                icon: Icons.date_range_outlined,
                accent: const Color(0xFF5E5CE6),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Text(
                  'Stock health',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    GlassPill(
                      label: '$lowStock low stock',
                      color: const Color(0xFFFF9F0A),
                      icon: Icons.trending_down,
                    ),
                    GlassPill(
                      label: '$outOfStock out of stock',
                      color: colors.error,
                      icon: Icons.remove_shopping_cart_outlined,
                    ),
                    GlassPill(
                      label: '$expiring expiring',
                      color: const Color(0xFFFF453A),
                      icon: Icons.event_busy_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => router(context).push(const MedicineBagScreen()),
            icon: const Icon(Icons.backpack_outlined),
            label: const Text('Open Medicine Bag'),
          ),
          const SizedBox(height: 20),
          Text(
            'Recent dispensations',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (recent.isEmpty)
            GlassPanel(
              child: Text(
                'No dispensations yet. Tap Dispense when you give medicine to a patient.',
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.75),
                ),
              ),
            )
          else
            ...recent.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _DispenseTile(record: r),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.cells});

  final List<_MetricCell> cells;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: cells
              .map((c) => SizedBox(width: width, child: c))
              .toList(),
        );
      },
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      tint: accent.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(
                alpha: 0.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DispenseTile extends StatelessWidget {
  const _DispenseTile({required this.record});

  final DispenseRecord record;

  @override
  Widget build(BuildContext context) {
    final when = DateTime.fromMillisecondsSinceEpoch(record.dispensedAtMs);
    final time =
        '${when.year}-${when.month.toString().padLeft(2, '0')}-${when.day.toString().padLeft(2, '0')} '
        '${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';

    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  record.medicineName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${record.quantity} → ${record.patientName}'
                  '${record.strength.isNotEmpty ? ' · ${record.strength}' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (record.notes.isNotEmpty)
                  Text(
                    record.notes,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ),
          Text(time, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
