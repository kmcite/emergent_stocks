import 'package:emergent_stocks/business/medicine_bag.dart';
import 'package:emergent_stocks/business/stocks_manager.dart';
import 'package:emergent_stocks/models/emergent_stock.dart';
import 'package:emergent_stocks/ui/delete_stock_dialog.dart';
import 'package:emergent_stocks/ui/dispense_dialog.dart';
import 'package:emergent_stocks/ui/new_stock_dialog.dart';
import 'package:emergent_stocks/ui/stock_details_screen.dart';
import 'package:emergent_stocks/ui/theme/liquid_glass.dart';
import 'package:emergent_stocks/utils/core.dart';
import 'package:emergent_stocks/utils/medicine_expiry.dart';
import 'package:emergent_stocks/utils/navigation.dart' show router;
import 'package:emergent_stocks/utils/provider.dart';
import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';

class MedicineBagScreen extends SignalConsumer {
  const MedicineBagScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stocksManager = context(stocksProvider);
    final filter = context(medicineBagFilterProvider);
    final colors = Theme.of(context).colorScheme;

    final all = stocksManager.stocks.toList();
    final visible = sortMedicinesForBag(filterMedicines(all, filter()));
    final totalUnits = all.fold<int>(0, (s, m) => s + m.count);
    final emergencyCount = all.where((m) => m.forEmergency).length;
    final expiringCount = countExpiringSoon(all);

    return GlassScaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Medicine Bag'),
            Text(
              'Inventory, expiry & stock audit',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
        leading: IconButton(
          tooltip: 'Back to dashboard',
          onPressed: () => router(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            tooltip: 'Dispense',
            onPressed: () => context.pushDialog(const DispenseDialog()),
            icon: const Icon(Icons.local_hospital_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushDialog(const NewStockDialog()),
        icon: const Icon(Icons.add),
        label: const Text('Add medicine'),
      ),
      body: stocksManager.stocks.isEmpty
          ? const _EmptyBagState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                _BagSummaryStrip(
                  lineItems: all.length,
                  totalUnits: totalUnits,
                  emergencyCount: emergencyCount,
                  expiringCount: expiringCount,
                ),
                const SizedBox(height: 16),
                _FilterRow(filter: filter),
                const SizedBox(height: 12),
                ...visible.map(
                  (medicine) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MedicineBagRow(medicine: medicine),
                  ),
                ),
              ],
            ),
    );
  }
}

class _BagSummaryStrip extends StatelessWidget {
  const _BagSummaryStrip({
    required this.lineItems,
    required this.totalUnits,
    required this.emergencyCount,
    required this.expiringCount,
  });

  final int lineItems;
  final int totalUnits;
  final int emergencyCount;
  final int expiringCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        final tiles = [
          _SummaryTile(
            label: 'Line items',
            value: '$lineItems',
            icon: Icons.inventory_2_outlined,
            accent: Theme.of(context).colorScheme.primary,
          ),
          _SummaryTile(
            label: 'Total units',
            value: '$totalUnits',
            icon: Icons.numbers,
            accent: const Color(0xFF34C759),
          ),
          _SummaryTile(
            label: 'Emergency',
            value: '$emergencyCount',
            icon: Icons.emergency_outlined,
            accent: const Color(0xFFFF453A),
          ),
          _SummaryTile(
            label: 'Expiring',
            value: '$expiringCount',
            icon: Icons.event_busy_outlined,
            accent: const Color(0xFFFF9F0A),
          ),
        ];
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: tiles.map((t) => SizedBox(width: width, child: t)).toList(),
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      radius: 18,
      tint: accent.withValues(alpha: 0.07),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(
                alpha: 0.65,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.filter});

  final Signal<MedicineBagFilter> filter;

  @override
  Widget build(BuildContext context) {
    final current = filter();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MedicineBagFilter.values.map((value) {
        final selected = current == value;
        final label = switch (value) {
          MedicineBagFilter.all => 'All',
          MedicineBagFilter.emergency => 'Emergency',
          MedicineBagFilter.expiring => 'Expiring',
        };
        return FilterChip(
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          onSelected: (_) => filter.set(value),
        );
      }).toList(),
    );
  }
}

class _MedicineBagRow extends StatelessWidget {
  const _MedicineBagRow({required this.medicine});

  final EmergentStock medicine;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = expiryStatus(medicine);
    final statusColor = expiryColor(status, colors);
    return GlassPanel(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary.withValues(alpha: 0.12),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Icon(
                    medicine.forEmergency
                        ? Icons.emergency
                        : Icons.medication_outlined,
                    size: 22,
                    color: medicine.forEmergency
                        ? const Color(0xFFFF453A)
                        : colors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    medicine.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  'Qty ${medicine.count}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: medicine.count == 0 ? colors.error : null,
                  ),
                ),
              ],
            ),
            if (medicine.genericName.isNotEmpty || medicine.strength.isNotEmpty)
              Text(
                [
                  if (medicine.genericName.isNotEmpty) medicine.genericName,
                  if (medicine.strength.isNotEmpty) medicine.strength,
                ].join(' · '),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.75),
                ),
              ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                GlassPill(
                  label: expiryLabel(medicine),
                  color: statusColor,
                  icon: Icons.event_outlined,
                ),
                if (medicine.forEmergency)
                  const GlassPill(
                    label: 'Emergency',
                    color: Color(0xFFFF453A),
                    icon: Icons.emergency,
                  ),
                GlassPill(
                  label: 'ID ${medicine.id}',
                  color: colors.outline,
                ),
              ],
            ),
            if (medicine.notes.isNotEmpty)
              Text(
                medicine.notes,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Remove',
                  onPressed: () => context.pushDialog(
                    DeleteStockDialog(stock: medicine),
                  ),
                  icon: const Icon(Icons.delete_outline),
                ),
                TextButton.icon(
                  onPressed: () => context.pushDialog(
                    DispenseDialog(preselectStockId: medicine.id),
                  ),
                  icon: const Icon(Icons.output_outlined, size: 18),
                  label: const Text('Dispense'),
                ),
                TextButton.icon(
                  onPressed: () => router(context).push(
                    StockDetailsScreen(stockId: medicine.id),
                  ),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Details'),
                ),
              ],
            ),
          ],
        ),
    );
  }
}

class _EmptyBagState extends StatelessWidget {
  const _EmptyBagState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassPanel(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.medication_liquid_outlined,
                size: 52,
                color: colors.primary.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 16),
              Text(
                'Your Medicine Bag is empty',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Add medicines you carry — track expiry, emergency items, and full stock in one place.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
