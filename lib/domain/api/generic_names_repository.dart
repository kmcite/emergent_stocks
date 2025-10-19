import 'package:emergent_stocks/domain/api/stocks_repository.dart';
import 'package:emergent_stocks/domain/model/generic_name.dart';
import 'package:spark/spark.dart';

class GenericNamesRepository extends Repository with Objectbox<GenericName> {
  @override
  int getId(GenericName item) => item.id;
}
