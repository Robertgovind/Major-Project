import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../shared/models/prediction_result.dart';
import '../../shared/models/sensor_data.dart';
import '../constants/api_config.dart';

class LiveSensorReading {
  const LiveSensorReading({required this.sensorData, required this.prediction});

  final SensorData sensorData;
  final PredictionResult prediction;
}

class LiveSensorService {
  LiveSensorService({String? websocketUrl})
    : _websocketUrl = websocketUrl ?? ApiConfig.websocketUrl;

  final String _websocketUrl;
  final StreamController<LiveSensorReading> _readingStreamController =
      StreamController<LiveSensorReading>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;

  Stream<LiveSensorReading> get readingStream =>
      _readingStreamController.stream;

  void connect() {
    if (_channel != null) return;

    _channel = WebSocketChannel.connect(Uri.parse(_websocketUrl));
    _channelSubscription = _channel!.stream.listen(
      _handleMessage,
      onError: _readingStreamController.addError,
      onDone: () {
        _channel = null;
        _channelSubscription = null;
      },
    );
  }

  void disconnect() {
    _channelSubscription?.cancel();
    _channelSubscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  void _handleMessage(dynamic message) {
    final decoded = jsonDecode(message as String) as Map<String, dynamic>;
    print('WebSocket message received: $decoded');

    if (decoded['event'] != 'sensor:reading') return;

    final data = Map<String, dynamic>.from(decoded['data'] as Map);
    final sensorData = Map<String, dynamic>.from(data['sensorData'] as Map);
    final prediction = Map<String, dynamic>.from(data['prediction'] as Map);

    _readingStreamController.add(
      LiveSensorReading(
        sensorData: SensorData.fromJson(_normalizeSensorData(sensorData)),
        prediction: PredictionResult.fromJson(prediction),
      ),
    );
  }

  Map<String, dynamic> _normalizeSensorData(Map<String, dynamic> data) {
    final gasResistance =
        _numberValue(
          data,
          'gasResistance',
          'GasResistance',
          'Gas resistance in (Kohm)',
          'gas',
        ) ??
        0;
    final vocPercent =
        _numberValue(data, 'vocPercent', 'VOC%', 'VOC_percent') ?? 0;
    final voc = _numberValue(data, 'voc') ?? vocPercent * 100;

    return {
      'r': _numberValue(data, 'r', 'Red', 'red')?.round() ?? 0,
      'g': _numberValue(data, 'g', 'Green', 'green')?.round() ?? 0,
      'b': _numberValue(data, 'b', 'Blue', 'blue')?.round() ?? 0,
      'humidity': _numberValue(data, 'humidity', 'Humidity') ?? 0,
      'temperature': _numberValue(data, 'temperature', 'Temperature') ?? 0,
      'gasResistance': gasResistance,
      'voc': voc,
      'chemicalRipening':
          _numberValue(data, 'chemicalRipening') ?? vocPercent.clamp(0, 1),
      'timestamp':
          data['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
    };
  }

  double? _numberValue(
    Map<String, dynamic> data,
    String key, [
    String? key2,
    String? key3,
    String? key4,
  ]) {
    for (final candidate in [key, key2, key3, key4]) {
      if (candidate == null) continue;
      final value = data[candidate];
      if (value is num) return value.toDouble();
      if (value is String && value.trim().isNotEmpty) {
        return double.tryParse(value);
      }
    }

    return null;
  }

  void dispose() {
    disconnect();
    _readingStreamController.close();
  }
}
