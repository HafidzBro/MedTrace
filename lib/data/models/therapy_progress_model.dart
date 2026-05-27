import 'package:equatable/equatable.dart';

import 'model_utils.dart';

class TherapyProgressModel extends Equatable {
  final String therapyProgressId;
  final String therapyId;
  final int daysOnTherapy;
  final DateTime lastCalculated;

  const TherapyProgressModel({
    required this.therapyProgressId,
    required this.therapyId,
    required this.daysOnTherapy,
    required this.lastCalculated,
  });

  factory TherapyProgressModel.fromJson(Map<String, dynamic> json) =>
      TherapyProgressModel(
        therapyProgressId: json['therapy_progress_id'] ?? json['id'] ?? '',
        therapyId: json['therapy_id'] ?? '',
        daysOnTherapy: parseInt(json['days_on_therapy']),
        lastCalculated: parseDateTime(json['last_calculated']),
      );

  Map<String, dynamic> toJson() => {
        'therapy_progress_id': therapyProgressId,
        'therapy_id': therapyId,
        'days_on_therapy': daysOnTherapy,
        'last_calculated': lastCalculated.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      [therapyProgressId, therapyId, daysOnTherapy, lastCalculated];
}
