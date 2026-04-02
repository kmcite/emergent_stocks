import 'package:emergent_stocks/main.dart';

final darkSignal = signal(false);

void toggleDarkMode() => darkSignal.value = !darkSignal.value;
