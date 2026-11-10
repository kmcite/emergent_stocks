import 'package:emergent_stocks/business/stock_edit_manager.dart';
import 'package:emergent_stocks/business/stocks_manager.dart';
import 'package:emergent_stocks/models/emergent_stock.dart';
import 'package:emergent_stocks/ui/medicine_form_fields.dart';
import 'package:emergent_stocks/ui/theme/liquid_glass.dart';
import 'package:emergent_stocks/utils/core.dart';
import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';

class StockEditDialog extends SignalConsumer {
  final int stockId;

  const StockEditDialog({super.key, required this.stockId});

  @override
  Widget build(BuildContext context) {
    final stocks = stocksProvider(context);
    final edit = stockEditProvider(context);

    EmergentStock? medicine;
    for (final s in stocks.stocks) {
      if (s.id == stockId) {
        medicine = s;
        break;
      }
    }

    if (medicine == null) {
      return GlassDialogShell(
        title: 'Not found',
        onClose: context.pop,
        child: Column(
          spacing: 12,
          children: [
            const Text('This medicine was removed from your bag.'),
            FilledButton(onPressed: context.pop, child: const Text('Close')),
          ],
        ),
      );
    }

    edit.loadFrom(medicine);

    return GlassDialogShell(
      title: 'Edit medicine',
      leading: const Icon(Icons.edit_outlined, size: 28),
      onClose: () => edit.discard(onDiscarded: context.pop),
      child: Column(
        key: ValueKey(stockId),
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          TextFormField(
            initialValue: edit.name(),
            decoration: const InputDecoration(
              labelText: 'Brand / label name *',
              prefixIcon: Icon(Icons.local_pharmacy_outlined),
            ),
            onChanged: edit.name.set,
          ),
          TextFormField(
            initialValue: edit.genericName(),
            decoration: const InputDecoration(
              labelText: 'Generic name',
              prefixIcon: Icon(Icons.science_outlined),
            ),
            onChanged: edit.genericName.set,
          ),
          TextFormField(
            initialValue: edit.strength(),
            decoration: const InputDecoration(
              labelText: 'Strength *',
              prefixIcon: Icon(Icons.speed_outlined),
            ),
            onChanged: edit.strength.set,
          ),
          TextFormField(
            initialValue: edit.count(),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Units in bag *',
              prefixIcon: const Icon(Icons.numbers),
              errorText: edit.countError,
            ),
            onChanged: edit.count.set,
          ),
          MedicineExpiryPickerTile(
            expiryDate: edit.expiryDate,
            onPick: edit.setExpiryDate,
            onClear: () => edit.setExpiryDate(null),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Emergency medicine'),
            value: edit.forEmergency(),
            onChanged: edit.forEmergency.set,
          ),
          TextFormField(
            initialValue: edit.notes(),
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notes',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
            onChanged: edit.notes.set,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => edit.discard(onDiscarded: context.pop),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: edit.isValid
                    ? () => edit.save(
                        allStocks: stocks.stocks.toList(),
                        onSaved: context.pop,
                      )
                    : null,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
