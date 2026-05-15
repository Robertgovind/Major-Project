// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sensor_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SensorDataImpl _$$SensorDataImplFromJson(Map<String, dynamic> json) =>
    _$SensorDataImpl(
      r: (json['r'] as num).toInt(),
      g: (json['g'] as num).toInt(),
      b: (json['b'] as num).toInt(),
      humidity: (json['humidity'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
      gasResistance: (json['gasResistance'] as num).toDouble(),
      voc: (json['voc'] as num).toDouble(),
      chemicalRipening: (json['chemicalRipening'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$$SensorDataImplToJson(_$SensorDataImpl instance) =>
    <String, dynamic>{
      'r': instance.r,
      'g': instance.g,
      'b': instance.b,
      'humidity': instance.humidity,
      'temperature': instance.temperature,
      'gasResistance': instance.gasResistance,
      'voc': instance.voc,
      'chemicalRipening': instance.chemicalRipening,
      'timestamp': instance.timestamp.toIso8601String(),
    };
