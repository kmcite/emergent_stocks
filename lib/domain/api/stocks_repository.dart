import 'package:emergent_stocks/domain/model/emergent_stock.dart';
import 'package:objectbox/objectbox.dart';
import 'package:spark/spark.dart';

class StocksRepository extends TypedRepository<List<EmergentStock>>
    with ObjectboxT<EmergentStock> {
  StocksRepository() : super([]);

  @override
  int getId(EmergentStock item) => item.id;
}

mixin Objectbox<T> on Repository {
  late final Store store = of();
  late final Box<T> box = store.box<T>();

  int getId(T item);

  List<T> getAll() => box.getAll();

  Future<List<T>> getAllAsync() async {
    return await box.getAllAsync();
  }

  Future<void> put(T entity) async {
    await box.putAsync(entity);
  }

  Future<void> remove(T entity) async {
    await box.removeAsync(getId(entity));
  }

  Future<void> removeAll() async {
    await box.removeAllAsync();
  }
}

mixin ObjectboxT<T> on TypedRepository<List<T>> {
  late final Store store = of();
  late final Box<T> box = store.box<T>();

  int getId(T item);

  List<T> getAll() => value;

  Future<List<T>> getAllAsync() async {
    emit(box.getAll());
    return await box.getAllAsync();
  }

  Future<void> put(T entity) async {
    await box.putAsync(entity);
    emit(box.getAll());
  }

  Future<void> remove(T entity) async {
    await box.removeAsync(getId(entity));
    emit(box.getAll());
  }

  Future<void> removeAll() async {
    await box.removeAllAsync();
    emit([]);
  }
}
