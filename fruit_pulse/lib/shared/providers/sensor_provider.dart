import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/utils/live_sensor_service.dart';
import '../../shared/models/sensor_data.dart';
import '../../shared/models/prediction_result.dart';
import '../../core/constants/api_config.dart';

enum SensorStatus { offline, waiting, live }

class SensorProvider with ChangeNotifier {
  final LiveSensorService _sensorService = LiveSensorService();
  final Dio _dio = Dio();
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

  SensorStatus _sensorStatus = SensorStatus.offline;
  SensorStatus get sensorStatus => _sensorStatus;

  DateTime? _lastDataReceived;
  Timer? _statusCheckTimer;

  // Calibration timer
  bool _isCalibrating = false;
  bool get isCalibrating => _isCalibrating;

  int _calibrationTimeRemaining = 420; // 7 minutes in seconds
  int get calibrationTimeRemaining => _calibrationTimeRemaining;

  Timer? _calibrationTimer;

  // Default sensor data for offline display
  final SensorData _defaultSensorData = SensorData(
    r: 0,
    g: 0,
    b: 0,
    temperature: 0.0,
    humidity: 0.0,
    voc: 0.0,
    chemicalRipening: 0.0,
    timestamp: DateTime.now(),
  );

  // Default prediction for offline display
  final PredictionResult _defaultPrediction = PredictionResult(
    isNaturalRipening: false,
    confidence: 0.0,
    status: 'No data available',
    recommendation: 'Please ensure the sensor device is connected and active.',
  );

  SensorProvider() {
    _startStatusCheckTimer();
  }

  void startSensorStream() {
    if (_isStreaming || _isDisposed) return;

    _isStreaming = true;
    _sensorStatus = SensorStatus.waiting;
    _sensorService.connect();
    _readingSubscription = _sensorService.readingStream.listen((reading) {
      if (_isDisposed) return;

      _currentSensorData = reading.sensorData;
      _sensorHistory.add(reading.sensorData);

      if (_sensorHistory.length > 60) {
        _sensorHistory.removeAt(0);
      }

      _currentPrediction = reading.prediction;
      _lastDataReceived = DateTime.now();
      _updateSensorStatus();
      _notifyIfActive();
    });

    _notifyIfActive();
  }

  void stopSensorStream({bool notify = true}) {
    if (!_isStreaming && _readingSubscription == null) return;

    _isStreaming = false;
    _sensorStatus = SensorStatus.offline;
    unawaited(_readingSubscription?.cancel());
    _readingSubscription = null;
    _sensorService.disconnect();

    if (notify) {
      _notifyIfActive();
    }
  }

  void _startStatusCheckTimer() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      await _checkBackendSensorStatus();
      _updateSensorStatus();
    });
  }

  Future<void> _checkBackendSensorStatus() async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/api/v1/sensor-data/status',
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final status = data['data']['status'] as String;

        // Update status based on backend response
        switch (status) {
          case 'live':
            _sensorStatus = SensorStatus.live;
            break;
          case 'waiting':
            _sensorStatus = SensorStatus.waiting;
            break;
          case 'offline':
            _sensorStatus = SensorStatus.offline;
            break;
        }

        // If backend says live, update last received time
        if (status == 'live' && data['data']['lastSeen'] != null) {
          _lastDataReceived = DateTime.parse(
            data['data']['lastSeen'] as String,
          );
        }
      }
    } catch (e) {
      // If backend check fails, rely on local websocket status
      // Status will be updated by _updateSensorStatus based on _lastDataReceived
    }
  }

  void _updateSensorStatus() {
    if (!_isStreaming) {
      _sensorStatus = SensorStatus.offline;
      return;
    }

    if (_lastDataReceived == null) {
      _sensorStatus = SensorStatus.waiting;
      return;
    }

    final timeSinceLastData = DateTime.now().difference(_lastDataReceived!);
    if (timeSinceLastData.inSeconds > 10) {
      _sensorStatus = SensorStatus.offline;
    } else {
      _sensorStatus = SensorStatus.live;
    }
  }

  // Get current sensor data, returning default if offline
  SensorData getCurrentSensorData() {
    return _currentSensorData ?? _defaultSensorData;
  }

  // Get current prediction, returning default if offline
  PredictionResult getCurrentPrediction() {
    return _currentPrediction ?? _defaultPrediction;
  }

  // Get sensor history, returning empty list with default data if offline
  List<SensorData> getSensorHistory() {
    if (_sensorHistory.isNotEmpty) return _sensorHistory;
    // Return some default history points for charts
    return List.generate(10, (_) => _defaultSensorData);
  }

  // Calibration timer methods
  void startCalibration() {
    if (_isCalibrating) return;

    _isCalibrating = true;
    _calibrationTimeRemaining = 420; // Reset to 10 minutes
    _notifyIfActive();

    _calibrationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_calibrationTimeRemaining > 0) {
        _calibrationTimeRemaining--;
        _notifyIfActive();
      } else {
        // Timer finished - start sensor stream
        completeCalibration();
      }
    });
  }

  void pauseCalibration() {
    if (!_isCalibrating) return;
    _isCalibrating = false;
    _calibrationTimer?.cancel();
    _calibrationTimer = null;
    _notifyIfActive();
  }

  void resumeCalibration() {
    _isCalibrating = true;
    if (!_isCalibrating || _calibrationTimer != null) return;

    _calibrationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_calibrationTimeRemaining > 0) {
        _calibrationTimeRemaining--;
        _notifyIfActive();
      } else {
        // Timer finished - start sensor stream
        completeCalibration();
      }
    });
    _notifyIfActive();
  }

  void completeCalibration() {
    _calibrationTimer?.cancel();
    _calibrationTimer = null;
    _isCalibrating = false;
    _calibrationTimeRemaining = 0;

    // Start sensor stream after calibration
    if (!_isStreaming) {
      startSensorStream();
    }

    _notifyIfActive();
  }

  void cancelCalibration() {
    _calibrationTimer?.cancel();
    _calibrationTimer = null;
    _isCalibrating = false;
    _calibrationTimeRemaining = 420;
    _notifyIfActive();
  }

  void _notifyIfActive() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _statusCheckTimer?.cancel();
    _calibrationTimer?.cancel();
    unawaited(_readingSubscription?.cancel());
    _readingSubscription = null;
    _sensorService.dispose();
    super.dispose();
  }
}
