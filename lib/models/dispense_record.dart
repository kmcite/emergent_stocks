import 'package:objectbox/objectbox.dart';

@Entity()
class DispenseRecord {
  @Id()
  int id = 0;

  int stockId = 0;

  /// Snapshot in case the stock row is removed later.
  String medicineName = '';
  String strength = '';

  String patientName = '';
  int quantity = 0;
  String notes = '';

  int dispensedAtMs = 0;
}
