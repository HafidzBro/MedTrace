import 'package:equatable/equatable.dart';

import 'model_utils.dart';

class TherapyStatusHistoryModel extends Equatable {
  final String therapyHistoryId;
  final String therapyId;
  final String? oldStatus;
  final String newStatus;
  final String? notes;
  final String changedBy;
  final DateTime changedAt;

  const TherapyStatusHistoryModel({
    required this.therapyHistoryId,
    required this.therapyId,
    this.oldStatus,
    required this.newStatus,
    this.notes,
    required this.changedBy,
    required this.changedAt,
  });

  factory TherapyStatusHistoryModel.fromJson(Map<String, dynamic> json) {
    return TherapyStatusHistoryModel(
      therapyHistoryId: json['therapy_history_id'] ?? json['id'] ?? '',
      therapyId: json['therapy_id'] ?? '',
      oldStatus: json['old_status'],
      newStatus: json['new_status'] ?? '',
      notes: json['notes'],
      changedBy: json['changed_by'] ?? '',
      changedAt: parseDateTime(json['changed_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'therapy_history_id': therapyHistoryId,
        'therapy_id': therapyId,
        'old_status': oldStatus,
        'new_status': newStatus,
        'notes': notes,
        'changed_by': changedBy,
        'changed_at': changedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        therapyHistoryId,
        therapyId,
        oldStatus,
        newStatus,
        notes,
        changedBy,
        changedAt,
      ];
}
