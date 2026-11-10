import 'package:objectbox/objectbox.dart';

@Entity()
class EmergentStock {
  @Id()
  int id = 0;
  String name = '';
  int count = 0;
  String genericName = '';
  String strength = '';

  /// Local calendar date at midnight (`DateTime` ms); 0 = unknown expiry.
  int expiryDateMs = 0;

  /// Kept in the bag for emergencies (e.g. epinephrine, nitroglycerin).
  bool forEmergency = false;

  String notes = '';

  /// Remote record id after a successful push (empty until synced).
  String remoteId = '';

  /// Milliseconds since epoch; used for last-write-wins merge on pull.
  int updatedAtMs = 0;
}

