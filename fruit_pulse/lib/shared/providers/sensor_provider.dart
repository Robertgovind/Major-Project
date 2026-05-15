import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/live_sensor_service.dart';
import '../../shared/models/sensor_data.dart';
import '../../shared/models/prediction_result.dart';
import '../../core/constants/api_config.dart';

enum SensorStatus { offline, waiting, live }

class SensorProvider with ChangeNotifier {
  static const String _sensorHistoryStorageKey = 'sensor_iteration_history_v1';
  static const String _predictionHistoryStorageKey =
      'prediction_iteration_history_v1';
  static const int _maxSessionItems = 60;
  static const int _maxStoredItems = 300;

  final LiveSensorService _sensorService = LiveSensorService();
  final Dio _dio = Dio();
  StreamSubscription<LiveSensorReading>? _readingSubscription;
  bool _isDisposed = false;

  SensorData? _currentSensorData;
  PredictionResult? _currentPrediction;
  final List<SensorData> _sensorHistory = [];
  final List<PredictionResult> _predictionHistory = [];
  final List<SensorData> _analysisSensorHistory = [];
  final List<PredictionResult> _analysisPredictionHistory = [];

  SensorData? get currentSensorData => _currentSensorData;
  PredictionResult? get currentPrediction => _currentPrediction;
  List<SensorData> get sensorHistory => _sensorHistory;
  List<PredictionResult> get predictionHistory => _predictionHistory;

  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;

  SensorStatus _sensorStatus = SensorStatus.offline;
  SensorStatus get sensorStatus => _sensorStatus;

  DateTime? _lastDataReceived;
  Timer? _statusCheckTimer;
  int _streamSessionId = 0;
  int? _activeHistoryIndex;

  // Calibration timer
  bool _isCalibrating = false;
  bool get isCalibrating => _isCalibrating;

  int _calibrationTimeRemaining = 60; // 7 minutes in seconds
  int get calibrationTimeRemaining => _calibrationTimeRemaining;

  Timer? _calibrationTimer;

  // Default sensor data for offline display
  final SensorData _defaultSensorData = SensorData(
    r: 0,
    g: 0,
    b: 0,
    temperature: 0.0,
    humidity: 0.0,
    gasResistance: 0.0,
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
    unawaited(_loadStoredHistory());
    _startStatusCheckTimer();
  }

  void startSensorStream() {
    print('Attempting to start sensor stream...');
    if (_isDisposed) return;

    if (_isStreaming) {
      _sensorStatus = SensorStatus.waiting;
      _notifyIfActive();
      return;
    }

    _isStreaming = true;
    _sensorStatus = SensorStatus.waiting;
    _activeHistoryIndex = null;
    final sessionId = ++_streamSessionId;
    _sensorService.connect();
    _readingSubscription = _sensorService.readingStream.listen((reading) {
      if (_isDisposed || !_isStreaming || sessionId != _streamSessionId) {
        return;
      }

      _currentSensorData = reading.sensorData;
      _analysisSensorHistory.add(reading.sensorData);
      print('New sensor reading received: ${reading.sensorData}');

      if (_analysisSensorHistory.length > _maxSessionItems) {
        _analysisSensorHistory.removeAt(0);
      }

      _currentPrediction = reading.prediction;
      _analysisPredictionHistory.add(reading.prediction);
      if (_analysisPredictionHistory.length > _maxSessionItems) {
        _analysisPredictionHistory.removeAt(0);
      }

      _storeLatestSessionResult(reading);

      _lastDataReceived = DateTime.now();
      unawaited(_saveStoredHistory());
      _updateSensorStatus();
      _notifyIfActive();
    });

    // Defer notification until after build phase completes
    Future.microtask(_notifyIfActive);
  }

  void restartAnalysisStream() {
    stopSensorStream(notify: false);
    resetAnalysisData(notify: false);
    startSensorStream();
  }

  void stopSensorStream({bool notify = true}) {
    if (!_isStreaming && _readingSubscription == null) return;

    _streamSessionId++;
    _isStreaming = false;
    _sensorStatus = SensorStatus.offline;
    _activeHistoryIndex = null;
    unawaited(_readingSubscription?.cancel());
    _readingSubscription = null;
    _sensorService.disconnect();

    if (notify) {
      _notifyIfActive();
    }
  }

  void resetAnalysisData({bool notify = true}) {
    _currentSensorData = null;
    _currentPrediction = null;
    _analysisSensorHistory.clear();
    _analysisPredictionHistory.clear();
    _activeHistoryIndex = null;
    _lastDataReceived = null;
    _calibrationTimer?.cancel();
    _calibrationTimer = null;
    _isCalibrating = false;
    _calibrationTimeRemaining = 60;

    if (!_isStreaming) {
      _sensorStatus = SensorStatus.offline;
    } else {
      _sensorStatus = SensorStatus.waiting;
    }

    if (notify) {
      _notifyIfActive();
    }
  }

  void _storeLatestSessionResult(LiveSensorReading reading) {
    final index = _activeHistoryIndex;

    if (index != null &&
        index >= 0 &&
        index < _sensorHistory.length &&
        index < _predictionHistory.length) {
      _sensorHistory[index] = reading.sensorData;
      _predictionHistory[index] = reading.prediction;
      return;
    }

    _sensorHistory.add(reading.sensorData);
    _predictionHistory.add(reading.prediction);
    _activeHistoryIndex = _sensorHistory.length - 1;

    while (_sensorHistory.length > _maxStoredItems ||
        _predictionHistory.length > _maxStoredItems) {
      _sensorHistory.removeAt(0);
      _predictionHistory.removeAt(0);
      if (_activeHistoryIndex != null) {
        final nextIndex = _activeHistoryIndex! - 1;
        _activeHistoryIndex = nextIndex < 0 ? 0 : nextIndex;
      }
    }
  }

  void _startStatusCheckTimer() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      await _checkBackendSensorStatus();
      _updateSensorStatus();
    });
  }

  Future<void> _checkBackendSensorStatus() async {
    if (_isStreaming && _lastDataReceived == null) {
      return;
    }

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
    if (_analysisSensorHistory.isNotEmpty) return _analysisSensorHistory;
    return const [];
  }

  List<PredictionResult> getPredictionHistory() {
    if (_analysisPredictionHistory.isNotEmpty) {
      return _analysisPredictionHistory;
    }
    return const [];
  }

  Future<void> _loadStoredHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sensorJson = prefs.getString(_sensorHistoryStorageKey);
      final predictionJson = prefs.getString(_predictionHistoryStorageKey);

      if (sensorJson != null) {
        final decoded = jsonDecode(sensorJson) as List<dynamic>;
        _sensorHistory
          ..clear()
          ..addAll(
            decoded
                .whereType<Map>()
                .map((item) => SensorData.fromJson(_jsonMap(item)))
                .take(_maxStoredItems),
          );
      }

      if (predictionJson != null) {
        final decoded = jsonDecode(predictionJson) as List<dynamic>;
        _predictionHistory
          ..clear()
          ..addAll(
            decoded
                .whereType<Map>()
                .map((item) => PredictionResult.fromJson(_jsonMap(item)))
                .take(_maxStoredItems),
          );
      }

      _notifyIfActive();
    } catch (_) {
      // Ignore corrupt local history and continue with a fresh in-memory state.
    }
  }

  Future<void> _saveStoredHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _sensorHistoryStorageKey,
        jsonEncode(_sensorHistory.map((item) => item.toJson()).toList()),
      );
      await prefs.setString(
        _predictionHistoryStorageKey,
        jsonEncode(_predictionHistory.map((item) => item.toJson()).toList()),
      );
    } catch (_) {
      // Persistence should not interrupt live plotting.
    }
  }

  Map<String, dynamic> _jsonMap(Map item) {
    return item.map((key, value) => MapEntry(key.toString(), value));
  }

  // Calibration timer methods
  void startCalibration() {
    if (_isCalibrating) return;

    _isCalibrating = true;
    _calibrationTimeRemaining = 60; // Reset to 10 minutes
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
    _calibrationTimeRemaining = 60;
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
