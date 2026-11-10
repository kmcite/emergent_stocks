import 'package:emergent_stocks/utils/medicine_expiry.dart';
import 'package:flutter/material.dart';

class MedicineExpiryPickerTile extends StatelessWidget {
  const MedicineExpiryPickerTile({
    super.key,
    required this.expiryDate,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? expiryDate;
  final ValueChanged<DateTime> onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final label = expiryDate == null
        ? 'Expiry date (recommended)'
        : formatExpiryDate(dateOnlyMs(expiryDate!));

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event_outlined),
      title: Text(label),
      subtitle: const Text('Tap to choose — helps avoid carrying expired meds'),
      trailing: expiryDate == null
          ? null
          : IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.clear),
            ),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: expiryDate ?? now.add(const Duration(days: 365)),
          firstDate: now.subtract(const Duration(days: 365 * 3)),
          lastDate: now.add(const Duration(days: 365 * 15)),
        );
        if (picked != null) onPick(picked);
      },
    );
  }
}
