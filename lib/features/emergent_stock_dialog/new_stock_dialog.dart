import 'package:flutter/material.dart';

import 'package:emergent_stocks/domain/emergent_stock.dart';
import 'package:emergent_stocks/effects/database.dart';
import 'package:emergent_stocks/effects/navigation.dart';

import '../../main.dart';

final nameSignal = signal('');
final genericNameSignal = signal('');
final strengthSignal = signal('');
final countSignal = signal('');

///
final isNewStockValid = computed(() {
  return strengthSignal().isNotEmpty && countSignal().isNotEmpty;
});

class NewStockDialog extends UI {
  const NewStockDialog({super.key});

  @override
  void init(BuildContext context) {}

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'New Stock',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  onPressed: () => navigateBack(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            TextFormField(
              initialValue: nameSignal(),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'Enter name',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.inventory),
              ),
              onChanged: nameSignal.set,
            ),
            TextFormField(
              initialValue: genericNameSignal(),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Generic Name',
                hintText: 'Enter generic name',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.label),
              ),
              onChanged: genericNameSignal.set,
            ),
            TextFormField(
              initialValue: strengthSignal(),
              // keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Strength *',
                hintText: 'Enter strength',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.browse_gallery),
              ),
              onChanged: strengthSignal.set,
            ),
            TextFormField(
              initialValue: countSignal(),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Quantity *',
                hintText: 'Enter quantity',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.kayaking),
              ),
              onChanged: countSignal.set,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => navigateBack(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: isNewStockValid()
                      ? () {
                          final stock = EmergentStock()
                            ..name = nameSignal()
                            ..genericName = genericNameSignal()
                            ..strength = strengthSignal()
                            ..count = int.tryParse(countSignal()) ?? 0;
                          db.put(stock);
                          navigateBack();
                        }
                      : null,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
