import 'package:objectbox/objectbox.dart';

@Entity()
class Brand {
  @Id()
  int id = 0;
  String name = '';
}
