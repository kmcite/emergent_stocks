import 'package:objectbox/objectbox.dart';

@Entity()
class EmergentStock {
  @Id()
  int id = 0;
  String name = '';
  int count = 0;
  String genericName = '';
  String strength = '';
}
