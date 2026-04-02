import 'package:objectbox/objectbox.dart';

@Entity()
class GenericName {
  @Id()
  int id = 0;
  String name = '';
}
