import 'package:emergent_stocks/effects/database.dart';
import 'package:emergent_stocks/domain/emergent_stock.dart';
import 'package:emergent_stocks/main.dart';

final stocksSignal = streamSignal<List<EmergentStock>>(
  db.watch,
  initialValue: <EmergentStock>[],
  lazy: false,
);

final stocks = computed(
  () => stocksSignal().map(
    data: (data) => data,
    error: (error) => <EmergentStock>[],
    loading: () => <EmergentStock>[],
  ),
);
