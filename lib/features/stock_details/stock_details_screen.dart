import 'package:emergent_stocks/effects/database.dart';
import 'package:emergent_stocks/effects/navigation.dart';
import 'package:emergent_stocks/domain/emergent_stock.dart';
import 'package:emergent_stocks/effects/stocks.dart';
import 'package:emergent_stocks/features/stocks_dashboard/emergency_stocks.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import 'stock_edit_dialog.dart';

// Computed signal to demonstrate reactivity - shows stock status
final stockStatus = computed(() {
  final currentStock = stock();
  if (currentStock.count == 0) return 'Out of Stock';
  if (currentStock.count < 10) return 'Low Stock';
  return 'In Stock';
});

final stockId = signal<int>(-1);
final stock = computed(() {
  return stocks().firstWhere((stock) => stock.id == stockId());
});

class StockDetailsScreen extends UI {
  const StockDetailsScreen({super.key});
  Color _getStatusColor() {
    switch (stockStatus()) {
      case 'Out of Stock':
        return Colors.red;
      case 'Low Stock':
        return Colors.orange;
      case 'In Stock':
        return Colors.green;
    }
    return Colors.grey; // fallback
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => navigateBack(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(stock().name),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              stockStatus(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StockDetailsContent(
        stock: stock(),
        onIncrement: () {
          db.put(stock()..count = stock().count + 1);
        },
        onDecrement: () {
          db.put(stock()..count = stock().count - 1);
        },
        onEdit: () {
          navigateToDialog(const StockEditDialog());
        },
        onDelete: () {
          navigateToDialog(
            AlertDialog(
              title: const Text('Delete Stock'),
              content: const Text(
                'Are you sure you want to delete this stock?',
              ),
              actions: [
                TextButton(
                  onPressed: () => navigateBack(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    db.remove<EmergentStock>(stock().id);
                    navigateUntill(EmergencyStocks());
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class StockDetailsContent extends UI {
  final EmergentStock stock;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const StockDetailsContent({
    super.key,
    required this.stock,
    required this.onIncrement,
    required this.onDecrement,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StockSummaryCard(
            stock: stock,
            onIncrement: onIncrement,
            onDecrement: onDecrement,
          ),
          _StockInfoGrid(stock: stock),
          ElevatedButton(
            onPressed: () => onEdit(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Edit Stock'),
          ),
          ElevatedButton(
            onPressed: () => onDelete(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Stock'),
          ),
        ],
      ),
    );
  }
}

class _StockSummaryCard extends UI {
  final EmergentStock stock;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _StockSummaryCard({
    required this.stock,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stock.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Stock',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    stock.count.toString(),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: color.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _RoundIconButton(
                    icon: Icons.remove,
                    onPressed: onDecrement,
                    semanticLabel: 'Decrease stock',
                  ),
                  const SizedBox(width: 12),
                  _RoundIconButton(
                    icon: Icons.add,
                    onPressed: onIncrement,
                    semanticLabel: 'Increase stock',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StockInfoGrid extends UI {
  final EmergentStock stock;

  const _StockInfoGrid({required this.stock});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _InfoTile(label: 'Stock ID', value: stock.id.toString(), icon: Icons.tag),
      _InfoTile(
        label: 'Name',
        value: stock.name.isNotEmpty ? stock.name : '—',
        icon: Icons.business,
      ),
      _InfoTile(
        label: 'Generic Name',
        value: stock.genericName.isNotEmpty ? stock.genericName : '—',
        icon: Icons.science,
      ),
      _InfoTile(
        label: 'Strength',
        value: stock.strength.isNotEmpty ? stock.strength : '—',
        icon: Icons.speed,
      ),
    ];

    return Wrap(spacing: 12, runSpacing: 12, children: tiles);
  }
}

class _InfoTile extends UI {
  final String label;
  final String value;
  final IconData icon;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(label, style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              Text(value, style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends UI {
  final IconData icon;
  final VoidCallback onPressed;
  final String semanticLabel;

  const _RoundIconButton({
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                // color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon),
        ),
      ),
    );
  }
}
