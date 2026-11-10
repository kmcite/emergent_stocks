import 'package:emergent_stocks/business/new_stock_manager.dart';
import 'package:emergent_stocks/ui/medicine_form_fields.dart';
import 'package:emergent_stocks/ui/theme/liquid_glass.dart';
import 'package:emergent_stocks/utils/core.dart';
import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';

class NewStockDialog extends SignalConsumer {
  const NewStockDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final form = newStockProvider(context);

    return GlassDialogShell(
      title: 'Add medicine',
      leading: const Icon(Icons.medication_outlined, size: 28),
      onClose: () => form.clearForm(onFormCleared: context.pop),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          TextFormField(
            initialValue: form.name(),
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Brand / label name *',
              hintText: 'e.g. EpiPen, Tylenol',
              prefixIcon: Icon(Icons.local_pharmacy_outlined),
            ),
            onChanged: form.name.set,
          ),
          TextFormField(
            initialValue: form.genericName(),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Generic name',
              hintText: 'e.g. acetaminophen',
              prefixIcon: Icon(Icons.science_outlined),
            ),
            onChanged: form.genericName.set,
          ),
          TextFormField(
            initialValue: form.strength(),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Strength *',
              hintText: 'e.g. 500 mg tablet',
              prefixIcon: Icon(Icons.speed_outlined),
            ),
            onChanged: form.strength.set,
          ),
          TextFormField(
            initialValue: form.count(),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Units in bag *',
              hintText: 'Tablets, pens, vials…',
              prefixIcon: const Icon(Icons.numbers),
              errorText: form.countError,
            ),
            onChanged: form.count.set,
          ),
          MedicineExpiryPickerTile(
            expiryDate: form.expiryDate,
            onPick: form.setExpiryDate,
            onClear: () => form.setExpiryDate(null),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Emergency medicine'),
            subtitle: const Text(
              'Pin for quick access — allergies, chest pain, etc.',
            ),
            value: form.forEmergency(),
            onChanged: (v) => form.forEmergency.set(v),
          ),
          TextFormField(
            initialValue: form.notes(),
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'When to use, prescriber, batch…',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
            onChanged: form.notes.set,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => form.clearForm(onFormCleared: context.pop),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: form.isNewStockValid
                    ? () => form.put(onStockSaved: context.pop)
                    : null,
                child: const Text('Save to bag'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
