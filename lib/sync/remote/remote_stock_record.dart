import 'package:emergent_stocks/models/emergent_stock.dart';

/// Transport DTO between local persistence and any HTTP backend implementation.
class RemoteStockRecord {
  const RemoteStockRecord({
    this.remoteId,
    required this.localId,
    required this.name,
    required this.count,
    required this.genericName,
    required this.strength,
    required this.expiryDateMs,
    required this.forEmergency,
    required this.notes,
    required this.updatedAtMs,
  });

  final String? remoteId;
  final int localId;
  final String name;
  final int count;
  final String genericName;
  final String strength;
  final int expiryDateMs;
  final bool forEmergency;
  final String notes;
  final int updatedAtMs;

  factory RemoteStockRecord.fromEmergentStock(EmergentStock stock) {
    return RemoteStockRecord(
      remoteId: stock.remoteId.isEmpty ? null : stock.remoteId,
      localId: stock.id,
      name: stock.name,
      count: stock.count,
      genericName: stock.genericName,
      strength: stock.strength,
      expiryDateMs: stock.expiryDateMs,
      forEmergency: stock.forEmergency,
      notes: stock.notes,
      updatedAtMs: stock.updatedAtMs,
    );
  }

  EmergentStock applyTo(EmergentStock? existing) {
    final target = existing ?? EmergentStock();
    if (remoteId != null) {
      target.remoteId = remoteId!;
    }
    target.name = name;
    target.count = count;
    target.genericName = genericName;
    target.strength = strength;
    target.expiryDateMs = expiryDateMs;
    target.forEmergency = forEmergency;
    target.notes = notes;
    target.updatedAtMs = updatedAtMs;
    return target;
  }

  Map<String, dynamic> toPayloadJson() => {
    'name': name,
    'count': count,
    'generic_name': genericName,
    'strength': strength,
    'expiry_date_ms': expiryDateMs,
    'for_emergency': forEmergency,
    'notes': notes,
    'local_id': localId,
    'updated_ms': updatedAtMs,
  };

  static RemoteStockRecord? fromJson(Map<String, dynamic> json) {
    final updatedMs = json['updated_ms'];
    if (updatedMs is! num) return null;

    return RemoteStockRecord(
      remoteId: json['id'] as String?,
      localId: (json['local_id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      genericName: json['generic_name'] as String? ?? '',
      strength: json['strength'] as String? ?? '',
      expiryDateMs: (json['expiry_date_ms'] as num?)?.toInt() ?? 0,
      forEmergency: json['for_emergency'] == true,
      notes: json['notes'] as String? ?? '',
      updatedAtMs: updatedMs.toInt(),
    );
  }
}
