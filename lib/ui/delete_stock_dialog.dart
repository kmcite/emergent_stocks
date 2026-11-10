import 'package:emergent_stocks/business/stocks_manager.dart';
import 'package:emergent_stocks/models/emergent_stock.dart';
import 'package:emergent_stocks/ui/theme/liquid_glass.dart';
import 'package:emergent_stocks/utils/core.dart';
import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';

class DeleteStockDialog extends SignalConsumer {
  const DeleteStockDialog({super.key, required this.stock});
  final EmergentStock stock;

  @override
  Widget build(BuildContext context) {
    final stocksManager = stocksProvider(context);
    final colors = Theme.of(context).colorScheme;

    return GlassDialogShell(
      title: 'Remove from bag?',
      leading: Icon(Icons.delete_outline, color: colors.error),
      onClose: context.pop,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Text(
            '“${stock.name}” will be deleted from this device. '
            'Emergency and expiry tracking for this item will stop.',
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: context.pop,
                child: const Text('Keep'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.error.withValues(alpha: 0.85),
                ),
                onPressed: () {
                  stocksManager.removeStock(stock);
                  if (context.mounted) {
                    context.popUntil((route) => route.isFirst);
                  }
                },
                child: const Text('Remove'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
