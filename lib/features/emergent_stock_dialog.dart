import 'package:emergent_stocks/domain/api/generic_names_repository.dart';
import 'package:emergent_stocks/domain/model/brand.dart';
import 'package:emergent_stocks/domain/model/generic_name.dart';
import 'package:emergent_stocks/domain/api/brands_repository.dart';
import 'package:emergent_stocks/domain/api/stocks_repository.dart';
import 'package:emergent_stocks/domain/model/emergent_stock.dart';

import 'package:emergent_stocks/main.dart';
import 'package:spark/spark.dart';

class EmergentStockDialogCubit extends Spark {
  late StocksRepository stocksRepository = of();
  late BrandsRepository brandsRepository = of();
  late GenericNamesRepository genericNamesRepository = of();

  bool brandExistsByName(Brand brand) =>
      brands.any((eachBrand) => eachBrand.name == brand.name);
  bool genericNameExistsByName(GenericName genericName) => genericNames
      .any((eachGenericName) => eachGenericName.name == genericName.name);

  Iterable<Brand> brandSuggestions(String query) {
    return brands.where((brand) => brand.name.contains(query));
  }

  Iterable<GenericName> genericNameSuggestions(String query) {
    return genericNames
        .where((genericName) => genericName.name.contains(query));
  }

  List<EmergentStock> get stocks => stocksRepository.getAll();
  List<Brand> get brands => brandsRepository.getAll();
  List<GenericName> get genericNames => genericNamesRepository.getAll();

  String name = '';
  String count = '';

  void onNameChanged(String name) {
    this.name = name;
    notifyListeners();
  }

  void onCountChanged(String count) {
    this.count = count;
    notifyListeners();
  }

  void onBrandSelected(Brand selection) {
    brandsRepository.put(selection);
    notifyListeners();
  }

  void onStockAdded(String name, int count) {
    stocksRepository.put(
      EmergentStock()
        ..name = name
        ..count = count,
    );
    notifyListeners();
    navigator.back();
  }
}

class EmergentStockDialog extends Feature<EmergentStockDialogCubit> {
  const EmergentStockDialog({super.key});

  @override
  EmergentStockDialogCubit create() => EmergentStockDialogCubit();

  @override
  Widget build(BuildContext context, spark) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Text(
              'Add Stock',
              style: TextStyle(fontSize: 32),
            ),
            TextFormField(
              initialValue: spark.name,
              onChanged: spark.onNameChanged,
              decoration: InputDecoration(
                hintText: 'Stock Name',
              ),
            ),
            TextFormField(
              initialValue: spark.count,
              onChanged: spark.onCountChanged,
              decoration: InputDecoration(
                hintText: 'Stock Count',
              ),
              keyboardType: TextInputType.number,
            ),
            Autocomplete<Brand>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<Brand>.empty();
                }
                return spark.brandSuggestions(textEditingValue.text);
              },
              onSelected: (selection) {
                if (spark.brandExistsByName(selection)) {
                } else {
                  spark.onBrandSelected(selection);
                }
                debugPrint('You selected $selection');
              },
            ),
            Autocomplete<GenericName>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable.empty();
                }
                return spark.genericNameSuggestions(textEditingValue.text);
              },
              onSelected: (GenericName selection) {
                debugPrint('You selected $selection');
              },
            ),
            FilledButton(
              onPressed: () {
                final name = spark.name;
                final count = int.tryParse(spark.count) ?? 0;
                if (name.isNotEmpty) {
                  spark.onStockAdded(name, count);
                }
              },
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
