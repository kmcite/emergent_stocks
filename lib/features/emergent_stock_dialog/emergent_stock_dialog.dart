import 'package:emergent_stocks/effects/navigation.dart';
import 'package:flutter/material.dart';

class EmergentStockDialog extends StatelessWidget {
  const EmergentStockDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Emergent Stock'),
      content: const Text('This is an emergent stock dialog.'),
      actions: [
        TextButton(
          onPressed: () => navigateBack(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
