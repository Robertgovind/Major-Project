import 'package:freezed_annotation/freezed_annotation.dart';

part 'sensor_data.freezed.dart';
part 'sensor_data.g.dart';

@freezed
class SensorData with _$SensorData {
  const factory SensorData({
    required int r,
    required int g,
    required int b,
    required double humidity,
    required double temperature,
    required double gasResistance,
    required double voc,
    required double chemicalRipening,
    required DateTime timestamp,
  }) = _SensorData;

  factory SensorData.fromJson(Map<String, dynamic> json) =>
      _$SensorDataFromJson(json);
}
