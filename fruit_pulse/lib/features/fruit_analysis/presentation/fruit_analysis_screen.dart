import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/providers/sensor_provider.dart';
import '../../../shared/widgets/sensor_card.dart';
import '../../../shared/widgets/app_card.dart';

class FruitAnalysisScreen extends StatefulWidget {
  final String fruitId;

  const FruitAnalysisScreen({super.key, required this.fruitId});

  @override
  State<FruitAnalysisScreen> createState() => _FruitAnalysisScreenState();
}

class _FruitAnalysisScreenState extends State<FruitAnalysisScreen> {
  SensorProvider? _sensorProvider;
  bool _calibrationDialogShown = false;

  @override
  void initState() {
    super.initState();
    // Show calibration dialog when entering analysis
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showCalibrationDialog();
    });
  }

  void _showCalibrationDialog() {
    if (_calibrationDialogShown) return;
    _calibrationDialogShown = true;

    _sensorProvider?.startCalibration();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildCalibrationDialog(),
    );
  }

  Widget _buildCalibrationDialog() {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        content: Consumer<SensorProvider>(
          builder: (context, provider, _) {
            final minutes = provider.calibrationTimeRemaining ~/ 60;
            final seconds = provider.calibrationTimeRemaining % 60;
            final timeString =
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

            // Auto-close when timer reaches 0
            if (!provider.isCalibrating &&
                provider.calibrationTimeRemaining == 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              });
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.timelapse,
                        color: AppColors.primaryGreen,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sensor Calibration',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Initializing sensor readings',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Timer Display
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryBlue.withValues(alpha: 0.15),
                        AppColors.primaryOrange.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryBlue.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Time Remaining',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        timeString,
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                      ),
                      const SizedBox(height: 12),
                      // Progress bar
                      LinearProgressIndicator(
                        value: provider.calibrationTimeRemaining / 600,
                        minHeight: 6,
                        backgroundColor: Colors.black12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Info text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Please place the fruit in the sensor chamber',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.black87, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (provider.isCalibrating) {
                            provider.pauseCalibration();
                          } else {
                            provider.resumeCalibration();
                          }
                        },
                        icon: Icon(
                          provider.isCalibrating
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                        label: Text(
                          provider.isCalibrating ? 'Pause' : 'Resume',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          provider.cancelCalibration();
                          if (mounted && Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryRed,
                          side: BorderSide(
                            color: AppColors.primaryRed.withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sensorProvider = context.read<SensorProvider>();
  }

  @override
  void dispose() {
    // Stop sensor stream when leaving
    _sensorProvider?.stopSensorStream(notify: false);
    _sensorProvider?.cancelCalibration();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SensorProvider>(
        builder: (context, provider, child) {
          // Show loading state during calibration
          if (provider.isCalibrating) {
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  leading: BackButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/fruit-selection');
                      }
                    },
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(AppStrings.analysisTitle),
                      Text(
                        _getStatusText(
                          context.watch<SensorProvider>().sensorStatus,
                        ),
                        style: TextStyle(
                          color: _getStatusColor(
                            context.watch<SensorProvider>().sensorStatus,
                          ),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color.fromARGB(255, 45, 91, 47),
                  elevation: 0,
                  floating: true,
                  snap: true,
                ),
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color.fromARGB(255, 6, 219, 13),
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Calibrating sensor...',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                leading: BackButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/fruit-selection');
                    }
                  },
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(AppStrings.analysisTitle),
                    Text(
                      _getStatusText(
                        context.watch<SensorProvider>().sensorStatus,
                      ),
                      style: TextStyle(
                        color: _getStatusColor(
                          context.watch<SensorProvider>().sensorStatus,
                        ),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color.fromARGB(255, 45, 91, 47),
                elevation: 0,
                floating: true,
                snap: true,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // VOC Gas Chart
                    _buildVocChart(provider),

                    const SizedBox(height: 24),

                    // Chemical Ripening Chart
                    _buildChemicalRipeningChart(provider),

                    const SizedBox(height: 24),

                    // Sensor Panel
                    _buildSensorPanel(provider),

                    const SizedBox(height: 24),

                    // AI Prediction Card
                    _buildPredictionCard(provider),

                    const SizedBox(height: 24),

                    // Analysis Summary
                    _buildAnalysisSummary(provider),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVocChart(SensorProvider provider) {
    final history = provider.getSensorHistory();
    if (history.isEmpty) return const SizedBox();

    final spots = history.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final data = entry.value;
      return FlSpot(index, data.voc);
    }).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(
                'VOC Gas Resistance Trend',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}s',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: _getVocColor(history.last.voc),
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _getVocColor(
                        history.last.voc,
                      ).withValues(alpha: 0.1),
                    ),
                  ),
                  // Standard reference line
                  LineChartBarData(
                    spots: spots.map((spot) => FlSpot(spot.x, 45)).toList(),
                    isCurved: false,
                    color: Colors.grey,
                    barWidth: 1,
                    dotData: const FlDotData(show: false),
                    dashArray: [5, 5],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Unripe', AppColors.primaryGreen),
              const SizedBox(width: 16),
              _buildLegendItem('Ripe', AppColors.primaryOrange),
              const SizedBox(width: 16),
              _buildLegendItem('Overripe', AppColors.primaryRed),
              const SizedBox(width: 16),
              _buildLegendItem('Standard', Colors.grey, isDashed: true),
            ],
          ),
        ],
      ),
    );
  }

  Color _getVocColor(double voc) {
    if (voc > 60) return AppColors.primaryGreen;
    if (voc > 30) return AppColors.primaryOrange;
    return AppColors.primaryRed;
  }

  Widget _buildLegendItem(String label, Color color, {bool isDashed = false}) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: isDashed
                ? const Border(
                    bottom: BorderSide(
                      color: Colors.grey,
                      width: 1,
                      style: BorderStyle.solid,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildChemicalRipeningChart(SensorProvider provider) {
    final history = provider.getSensorHistory();
    if (history.isEmpty) return const SizedBox();

    final spots = history.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final data = entry.value;
      return FlSpot(index, data.chemicalRipening * 100);
    }).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: AppColors.primaryOrange),
              const SizedBox(width: 8),
              Text(
                'Chemical Ripening Trend',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}%',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}s',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primaryOrange,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primaryOrange.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorPanel(SensorProvider provider) {
    final data = provider.getCurrentSensorData();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live Sensor Data',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildRgbSensorCard(data.r, data.g, data.b),
            SensorCard(
              title: AppStrings.humidity,
              value: data.humidity.toStringAsFixed(1),
              unit: '%',
              icon: Icons.water_drop,
              color: AppColors.primaryBlue,
              sparklineData: [], // TODO: Add sparkline data
            ),
            SensorCard(
              title: AppStrings.temperature,
              value: data.temperature.toStringAsFixed(1),
              unit: '°C',
              icon: Icons.thermostat,
              color: AppColors.primaryOrange,
              sparklineData: [], // TODO: Add sparkline data
            ),
            SensorCard(
              title: AppStrings.voc,
              value: data.voc.toStringAsFixed(1),
              unit: '',
              icon: Icons.air,
              color: _getVocColor(data.voc),
              sparklineData: [], // TODO: Add sparkline data
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRgbSensorCard(int r, int g, int b) {
    final rgbColor = Color.fromARGB(
      255,
      r.clamp(0, 255),
      g.clamp(0, 255),
      b.clamp(0, 255),
    );

    return AppCard(
      gradient: LinearGradient(
        colors: [
          AppColors.primaryBlue.withValues(alpha: 0.1),
          AppColors.primaryBlue.withValues(alpha: 0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.color_lens, color: AppColors.primaryBlue, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.rgb,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$r, $g, $b',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: rgbColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(SensorProvider provider) {
    final prediction = provider.getCurrentPrediction();

    return AppCard(
      gradient: LinearGradient(
        colors: [
          prediction.isNaturalRipening
              ? AppColors.primaryGreen
              : AppColors.primaryRed,
          prediction.isNaturalRipening
              ? AppColors.primaryGreen.withValues(alpha: 0.7)
              : AppColors.primaryRed.withValues(alpha: 0.7),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                prediction.isNaturalRipening ? Icons.eco : Icons.warning,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'AI Prediction',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            prediction.isNaturalRipening
                ? AppStrings.naturalRipening
                : AppStrings.chemicalRipening,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Status: ${prediction.status}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Confidence: ${(prediction.confidence * 100).toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSummary(SensorProvider provider) {
    final prediction = provider.getCurrentPrediction();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analysis Summary',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            prediction.recommendation,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  String _getStatusText(SensorStatus status) {
    switch (status) {
      case SensorStatus.live:
        return 'Live';
      case SensorStatus.waiting:
        return 'Waiting';
      case SensorStatus.offline:
        return 'Offline';
    }
  }

  Color _getStatusColor(SensorStatus status) {
    switch (status) {
      case SensorStatus.live:
        return const Color.fromARGB(255, 6, 219, 13); // Green
      case SensorStatus.waiting:
        return Colors.orange;
      case SensorStatus.offline:
        return AppColors.primaryRed;
    }
  }
}
