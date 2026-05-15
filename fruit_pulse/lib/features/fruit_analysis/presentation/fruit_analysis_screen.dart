import 'package:flutter/material.dart';
import 'package:fruit_pulse/features/fruit_analysis/widgets/build_chemical_ripening_chart.dart';
import 'package:fruit_pulse/features/fruit_analysis/widgets/build_voc_chart.dart';
import 'package:fruit_pulse/features/fruit_analysis/widgets/timer_calibration_dialog.dart';
import 'package:provider/provider.dart';
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
    // I want to start the timer when clicked on resume button so removed this function call
    //_sensorProvider?.startCalibration();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TimercalibrationDialog(mounted: mounted),
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

    _sensorProvider?.cancelCalibration();
    _sensorProvider?.stopSensorStream(notify: false);
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
                    VocChartWidget(context: context, provider: provider),
                    const SizedBox(height: 24),
                    BuildChemicalRipeningChart(
                      context: context,
                      provider: provider,
                    ),

                    const SizedBox(height: 24),

                    // Sensor Panel
                    _buildSensorPanel(provider),

                    const SizedBox(height: 24),

                    // AI Prediction Card
                    if (provider.currentPrediction != null)
                      _buildPredictionCard(provider)
                    else
                      _buildNoPredictionCard(),

                    const SizedBox(height: 24),

                    // Analysis Summary
                    if (provider.currentPrediction != null)
                      _buildAnalysisSummary(provider)
                    else
                      _buildNoAnalysisSummary(),
                  ]),
                ),
              ),
            ],
          );
        },
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

  Color _getVocColor(double voc) {
    if (voc > 60) return AppColors.primaryGreen;
    if (voc > 30) return AppColors.primaryOrange;
    return AppColors.primaryRed;
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

  Widget _buildNoPredictionCard() {
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
              Icon(
                Icons.hourglass_empty,
                color: AppColors.primaryBlue,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'AI Prediction',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Waiting for sensor data...',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI analysis will begin once live sensor readings are received from the backend.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.primaryBlue.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAnalysisSummary() {
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
            'No analysis available yet. Please ensure the sensor device is connected and actively sending data. The AI will provide insights on fruit ripening status once sufficient sensor readings are collected.',
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
