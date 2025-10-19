import 'package:emergent_stocks/domain/api/stocks_repository.dart';
import 'package:emergent_stocks/domain/model/brand.dart';
import 'package:spark/spark.dart';

class BrandsRepository extends Repository with Objectbox<Brand> {
  @override
  int getId(Brand item) => item.id;
}
