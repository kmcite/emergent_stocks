// import 'package:emergent_stocks/main.dart';
import 'package:emergent_stocks/objectbox.g.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals/signals.dart';

final db = Database()..ensureInitialized();

class Database {
  final objectsSignal = signal<Store?>(null);
  final preferencesSignal = signal<SharedPreferences?>(null);
  late final loading = computed(
    () => objectsSignal() == null || preferencesSignal() == null,
  );

  Future<Database> ensureInitialized() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    final storePath = join(appDocumentDir.path, 'emergent_stocks');
    await Future.delayed(Duration(milliseconds: 300));
    objectsSignal.set(await openStore(directory: storePath));
    preferencesSignal.set(await SharedPreferences.getInstance());
    return this;
  }

  /// PREFS API
  void save(String key, String value) async {
    await ensureInitialized();
    await preferencesSignal()!.setString(key, value);
  }

  String? read(String key) {
    String? value;
    ensureInitialized().then((_) {
      value = preferencesSignal()!.getString(key);
    });
    return value;
  }

  /// OBJECTBOX API
  int put<T>(T any) => objectsSignal()!.box<T>().put(any);
  List<T> getAll<T>() => objectsSignal()!.box<T>().getAll();
  T? get<T>(int id) => objectsSignal()!.box<T>().get(id);
  Stream<List<T>> watch<T>() => objectsSignal()!
      .box<T>()
      .query()
      .watch(triggerImmediately: true)
      .map((q) => q.find());
  bool remove<T>(int id) => objectsSignal()!.box<T>().remove(id);

  int removeAll<T>() => objectsSignal()!.box<T>().removeAll();
}
