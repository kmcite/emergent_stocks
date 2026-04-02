import 'package:flutter/material.dart';

import 'package:emergent_stocks/domain/emergent_stock.dart';
import 'package:emergent_stocks/effects/navigation.dart';
import 'package:emergent_stocks/effects/stocks.dart';
import 'package:emergent_stocks/features/emergent_stock_dialog/new_stock_dialog.dart';
import 'package:emergent_stocks/features/settings/settings_screen.dart';
import 'package:emergent_stocks/features/stock_details/stock_details_screen.dart';

import 'package:emergent_stocks/main.dart';

class EmergencyStocks extends StatelessWidget {
  const EmergencyStocks({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Stocks'),
        actions: [
          IconButton(
            onPressed: () => navigateTo(SettingsScreen()),
            icon: const Icon(Icons.settings),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StocksList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => navigateToDialog(NewStockDialog()),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class StocksList extends UI {
  const StocksList({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: stocks.isEmpty
          ? Center(
              child: Text(
                'No stocks available. Add your first stock!',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: stocks().length,
              itemBuilder: (context, index) =>
                  StockTile(stock: stocks()[index]),
            ),
    );
  }
}

class StockTile extends StatelessWidget {
  final EmergentStock stock;

  const StockTile({super.key, required this.stock});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: .circular(16)),
      leading: CircleAvatar(
        child: Text(
          stock.count.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(stock.name),
      subtitle: Text(
        stock.genericName.isEmpty
            ? 'No generic name provided'
            : stock.genericName,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.arrow_forward_ios),
        onPressed: () {},
      ),
      onTap: () {
        stockId.set(stock.id);
        navigateTo(StockDetailsScreen());
      },
    );
  }
}
