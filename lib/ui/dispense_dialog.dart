import 'package:emergent_stocks/business/dispense_form_manager.dart';
import 'package:emergent_stocks/business/stocks_manager.dart';
import 'package:emergent_stocks/ui/theme/liquid_glass.dart';
import 'package:emergent_stocks/utils/core.dart';
import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';

class DispenseDialog extends SignalConsumer {
  const DispenseDialog({super.key, this.preselectStockId});

  final int? preselectStockId;

  @override
  Widget build(BuildContext context) {
    final form = dispenseFormProvider(context);
    final stocks = stocksProvider(context);
    final available = stocks.stocks.where((s) => s.count > 0).toList();

    if (preselectStockId != null) {
      form.ensurePreselect(preselectStockId!);
    }

    return GlassDialogShell(
      title: 'Dispense to patient',
      leading: const Icon(Icons.local_hospital_outlined, size: 28),
      onClose: () => form.clear(onCleared: context.pop),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          if (available.isEmpty)
            const Text('No medicines with stock on hand. Add inventory first.')
          else ...[
            DropdownMenu<int>(
              initialSelection: form.selectedStockId(),
              label: const Text('Medicine'),
              expandedInsets: EdgeInsets.zero,
              dropdownMenuEntries: [
                for (final s in available)
                  DropdownMenuEntry(
                    value: s.id,
                    label: '${s.name} (${s.count} left)',
                  ),
              ],
              onSelected: form.selectedStockId.set,
            ),
            TextFormField(
              initialValue: form.patientName(),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Patient name / ID *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              onChanged: form.patientName.set,
            ),
            TextFormField(
              initialValue: form.quantity(),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity to dispense *',
                prefixIcon: const Icon(Icons.exposure_outlined),
                errorText: form.quantityError,
                helperText: form.selectedStock == null
                    ? null
                    : '${form.selectedStock!.count} units available',
              ),
              onChanged: form.quantity.set,
            ),
            TextFormField(
              initialValue: form.notes(),
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Reason, batch, prescriber…',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              onChanged: form.notes.set,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => form.clear(onCleared: context.pop),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: form.isValid
                      ? () {
                          final err = form.submit(onDone: context.pop);
                          if (err != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(err)),
                            );
                          }
                        }
                      : null,
                  child: const Text('Confirm dispense'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
