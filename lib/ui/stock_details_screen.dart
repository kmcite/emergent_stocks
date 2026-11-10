import 'package:emergent_stocks/business/stocks_manager.dart';
import 'package:emergent_stocks/models/emergent_stock.dart';
import 'package:emergent_stocks/ui/delete_stock_dialog.dart';
import 'package:emergent_stocks/ui/stock_edit_dialog.dart';
import 'package:emergent_stocks/ui/theme/liquid_glass.dart';
import 'package:emergent_stocks/utils/core.dart';
import 'package:emergent_stocks/utils/medicine_expiry.dart';
import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';

class StockDetailsScreen extends SignalConsumer {
  final int stockId;

  const StockDetailsScreen({super.key, required this.stockId});

  @override
  Widget build(BuildContext context) {
    final stocksManager = stocksProvider(context);
    final colors = Theme.of(context).colorScheme;

    EmergentStock? medicine;
    for (final s in stocksManager.stocks) {
      if (s.id == stockId) {
        medicine = s;
        break;
      }
    }

    if (medicine == null) {
      return GlassScaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: context.pop,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: const Center(child: Text('This medicine is no longer in your bag.')),
      );
    }

    final expiry = expiryStatus(medicine);
    final expiryTint = expiryColor(expiry, colors);

    return GlassScaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: context.pop,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(medicine.name),
        actions: [
          GlassPill(
            label: expiryLabel(medicine),
            color: expiryTint,
            icon: Icons.calendar_today_outlined,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassPanel(
              padding: const EdgeInsets.all(20),
              tint: colors.primary.withValues(alpha: 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  if (medicine.forEmergency)
                    const GlassPill(
                      label: 'Emergency',
                      color: Color(0xFFFF453A),
                      icon: Icons.emergency,
                    ),
                  Text(
                    medicine.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (medicine.genericName.isNotEmpty)
                    Text(
                      medicine.genericName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Units in bag',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          Text(
                            '${medicine.count}',
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _RoundGlassButton(
                            icon: Icons.remove,
                            onPressed: medicine.count > 0
                                ? () {
                                    stocksManager.updateStock(
                                      medicine!..count = medicine.count - 1,
                                    );
                                  }
                                : null,
                          ),
                          const SizedBox(width: 12),
                          _RoundGlassButton(
                            icon: Icons.add,
                            onPressed: () {
                              stocksManager.updateStock(
                                medicine!..count = medicine.count + 1,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _InfoTile(
              label: 'Strength',
              value: medicine.strength.isEmpty ? '—' : medicine.strength,
              icon: Icons.speed_outlined,
            ),
            _InfoTile(
              label: 'Expiry',
              value: expiryLabel(medicine),
              icon: Icons.event_outlined,
            ),
            if (medicine.notes.isNotEmpty)
              _InfoTile(
                label: 'Notes',
                value: medicine.notes,
                icon: Icons.notes_outlined,
              ),
            FilledButton.icon(
              onPressed: () =>
                  context.pushDialog(StockEditDialog(stockId: medicine!.id)),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit medicine'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.pushDialog(
                DeleteStockDialog(stock: medicine!),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.error,
                side: BorderSide(color: colors.error.withValues(alpha: 0.6)),
              ),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove from bag'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelLarge),
                Text(value, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundGlassButton extends StatelessWidget {
  const _RoundGlassButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.55);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: border),
            color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.35),
          ),
          child: Icon(
            icon,
            color: disabled
                ? Theme.of(context).colorScheme.outline
                : null,
          ),
        ),
      ),
    );
  }
}
