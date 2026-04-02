import 'package:emergent_stocks/effects/database.dart';
import 'package:emergent_stocks/effects/navigation.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import 'stock_details_screen.dart';

class StockEditDialog extends UI {
  const StockEditDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              spacing: 8,
              children: [
                const Icon(Icons.edit, size: 28),
                Expanded(
                  child: Text(
                    'Edit Stock',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  onPressed: () => navigateBack(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                _LabeledField(
                  label: 'Name',
                  initialValue: stock().name,
                  onChanged: (value) => db.put(stock()..name = value.trim()),
                ),
                _LabeledField(
                  label: 'Generic Name',
                  initialValue: stock().genericName,
                  onChanged: (value) {
                    db.put(stock()..genericName = value.trim());
                  },
                ),
                _LabeledField(
                  label: 'Strength',
                  initialValue: stock().strength,
                  onChanged: (value) {
                    db.put(stock()..strength = value.trim());
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

class _LabeledField extends StatelessWidget {
  final String label;
  final String initialValue;
  final Function(String) onChanged;

  const _LabeledField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        TextFormField(
          initialValue: initialValue,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
