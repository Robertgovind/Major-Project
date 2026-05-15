// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sensor_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SensorData _$SensorDataFromJson(Map<String, dynamic> json) {
  return _SensorData.fromJson(json);
}

/// @nodoc
mixin _$SensorData {
  int get r => throw _privateConstructorUsedError;
  int get g => throw _privateConstructorUsedError;
  int get b => throw _privateConstructorUsedError;
  double get humidity => throw _privateConstructorUsedError;
  double get temperature => throw _privateConstructorUsedError;
  double get gasResistance => throw _privateConstructorUsedError;
  double get voc => throw _privateConstructorUsedError;
  double get chemicalRipening => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Serializes this SensorData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SensorData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SensorDataCopyWith<SensorData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SensorDataCopyWith<$Res> {
  factory $SensorDataCopyWith(
    SensorData value,
    $Res Function(SensorData) then,
  ) = _$SensorDataCopyWithImpl<$Res, SensorData>;
  @useResult
  $Res call({
    int r,
    int g,
    int b,
    double humidity,
    double temperature,
    double gasResistance,
    double voc,
    double chemicalRipening,
    DateTime timestamp,
  });
}

/// @nodoc
class _$SensorDataCopyWithImpl<$Res, $Val extends SensorData>
    implements $SensorDataCopyWith<$Res> {
  _$SensorDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SensorData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? r = null,
    Object? g = null,
    Object? b = null,
    Object? humidity = null,
    Object? temperature = null,
    Object? gasResistance = null,
    Object? voc = null,
    Object? chemicalRipening = null,
    Object? timestamp = null,
  }) {
    return _then(
      _value.copyWith(
            r: null == r
                ? _value.r
                : r // ignore: cast_nullable_to_non_nullable
                      as int,
            g: null == g
                ? _value.g
                : g // ignore: cast_nullable_to_non_nullable
                      as int,
            b: null == b
                ? _value.b
                : b // ignore: cast_nullable_to_non_nullable
                      as int,
            humidity: null == humidity
                ? _value.humidity
                : humidity // ignore: cast_nullable_to_non_nullable
                      as double,
            temperature: null == temperature
                ? _value.temperature
                : temperature // ignore: cast_nullable_to_non_nullable
                      as double,
            gasResistance: null == gasResistance
                ? _value.gasResistance
                : gasResistance // ignore: cast_nullable_to_non_nullable
                      as double,
            voc: null == voc
                ? _value.voc
                : voc // ignore: cast_nullable_to_non_nullable
                      as double,
            chemicalRipening: null == chemicalRipening
                ? _value.chemicalRipening
                : chemicalRipening // ignore: cast_nullable_to_non_nullable
                      as double,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SensorDataImplCopyWith<$Res>
    implements $SensorDataCopyWith<$Res> {
  factory _$$SensorDataImplCopyWith(
    _$SensorDataImpl value,
    $Res Function(_$SensorDataImpl) then,
  ) = __$$SensorDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int r,
    int g,
    int b,
    double humidity,
    double temperature,
    double gasResistance,
    double voc,
    double chemicalRipening,
    DateTime timestamp,
  });
}

/// @nodoc
class __$$SensorDataImplCopyWithImpl<$Res>
    extends _$SensorDataCopyWithImpl<$Res, _$SensorDataImpl>
    implements _$$SensorDataImplCopyWith<$Res> {
  __$$SensorDataImplCopyWithImpl(
    _$SensorDataImpl _value,
    $Res Function(_$SensorDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SensorData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? r = null,
    Object? g = null,
    Object? b = null,
    Object? humidity = null,
    Object? temperature = null,
    Object? gasResistance = null,
    Object? voc = null,
    Object? chemicalRipening = null,
    Object? timestamp = null,
  }) {
    return _then(
      _$SensorDataImpl(
        r: null == r
            ? _value.r
            : r // ignore: cast_nullable_to_non_nullable
                  as int,
        g: null == g
            ? _value.g
            : g // ignore: cast_nullable_to_non_nullable
                  as int,
        b: null == b
            ? _value.b
            : b // ignore: cast_nullable_to_non_nullable
                  as int,
        humidity: null == humidity
            ? _value.humidity
            : humidity // ignore: cast_nullable_to_non_nullable
                  as double,
        temperature: null == temperature
            ? _value.temperature
            : temperature // ignore: cast_nullable_to_non_nullable
                  as double,
        gasResistance: null == gasResistance
            ? _value.gasResistance
            : gasResistance // ignore: cast_nullable_to_non_nullable
                  as double,
        voc: null == voc
            ? _value.voc
            : voc // ignore: cast_nullable_to_non_nullable
                  as double,
        chemicalRipening: null == chemicalRipening
            ? _value.chemicalRipening
            : chemicalRipening // ignore: cast_nullable_to_non_nullable
                  as double,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SensorDataImpl implements _SensorData {
  const _$SensorDataImpl({
    required this.r,
    required this.g,
    required this.b,
    required this.humidity,
    required this.temperature,
    required this.gasResistance,
    required this.voc,
    required this.chemicalRipening,
    required this.timestamp,
  });

  factory _$SensorDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$SensorDataImplFromJson(json);

  @override
  final int r;
  @override
  final int g;
  @override
  final int b;
  @override
  final double humidity;
  @override
  final double temperature;
  @override
  final double gasResistance;
  @override
  final double voc;
  @override
  final double chemicalRipening;
  @override
  final DateTime timestamp;

  @override
  String toString() {
    return 'SensorData(r: $r, g: $g, b: $b, humidity: $humidity, temperature: $temperature, gasResistance: $gasResistance, voc: $voc, chemicalRipening: $chemicalRipening, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SensorDataImpl &&
            (identical(other.r, r) || other.r == r) &&
            (identical(other.g, g) || other.g == g) &&
            (identical(other.b, b) || other.b == b) &&
            (identical(other.humidity, humidity) ||
                other.humidity == humidity) &&
            (identical(other.temperature, temperature) ||
                other.temperature == temperature) &&
            (identical(other.gasResistance, gasResistance) ||
                other.gasResistance == gasResistance) &&
            (identical(other.voc, voc) || other.voc == voc) &&
            (identical(other.chemicalRipening, chemicalRipening) ||
                other.chemicalRipening == chemicalRipening) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    r,
    g,
    b,
    humidity,
    temperature,
    gasResistance,
    voc,
    chemicalRipening,
    timestamp,
  );

  /// Create a copy of SensorData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SensorDataImplCopyWith<_$SensorDataImpl> get copyWith =>
      __$$SensorDataImplCopyWithImpl<_$SensorDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SensorDataImplToJson(this);
  }
}

abstract class _SensorData implements SensorData {
  const factory _SensorData({
    required final int r,
    required final int g,
    required final int b,
    required final double humidity,
    required final double temperature,
    required final double gasResistance,
    required final double voc,
    required final double chemicalRipening,
    required final DateTime timestamp,
  }) = _$SensorDataImpl;

  factory _SensorData.fromJson(Map<String, dynamic> json) =
      _$SensorDataImpl.fromJson;

  @override
  int get r;
  @override
  int get g;
  @override
  int get b;
  @override
  double get humidity;
  @override
  double get temperature;
  @override
  double get gasResistance;
  @override
  double get voc;
  @override
  double get chemicalRipening;
  @override
  DateTime get timestamp;

  /// Create a copy of SensorData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SensorDataImplCopyWith<_$SensorDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
