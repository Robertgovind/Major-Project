import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/utils/live_sensor_service.dart';
import '../../shared/models/sensor_data.dart';
import '../../shared/models/prediction_result.dart';

class SensorProvider with ChangeNotifier {
  final LiveSensorService _sensorService = LiveSensorService();
  StreamSubscription<LiveSensorReading>? _readingSubscription;
  bool _isDisposed = false;

  SensorData? _currentSensorData;
  PredictionResult? _currentPrediction;
  final List<SensorData> _sensorHistory = [];

  SensorData? get currentSensorData => _currentSensorData;
  PredictionResult? get currentPrediction => _currentPrediction;
  List<SensorData> get sensorHistory => _sensorHistory;

  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;

  void startSensorStream() {
    if (_isStreaming || _isDisposed) return;

    _isStreaming = true;
    _sensorService.connect();
    _readingSubscription = _sensorService.readingStream.listen((reading) {
      if (_isDisposed) return;

      _currentSensorData = reading.sensorData;
      _sensorHistory.add(reading.sensorData);

      if (_sensorHistory.length > 60) {
        _sensorHistory.removeAt(0);
      }

      _currentPrediction = reading.prediction;
      _notifyIfActive();
    });

    _notifyIfActive();
  }

  void stopSensorStream({bool notify = true}) {
    if (!_isStreaming && _readingSubscription == null) return;

    _isStreaming = false;
    unawaited(_readingSubscription?.cancel());
    _readingSubscription = null;
    _sensorService.disconnect();

    if (notify) {
      _notifyIfActive();
    }
  }

  void _notifyIfActive() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_readingSubscription?.cancel());
    _readingSubscription = null;
    _sensorService.dispose();
    super.dispose();
  }
}
