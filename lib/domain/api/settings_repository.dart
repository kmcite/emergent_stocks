import 'package:spark/spark.dart';

class SettingsRepository extends Repository {
  bool dark = false;
  void toggleMode() {
    dark = !dark;
    notifyListeners();
  }
}
