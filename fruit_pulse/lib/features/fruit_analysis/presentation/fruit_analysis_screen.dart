import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fruit_pulse/features/fruit_analysis/widgets/build_voc_chart.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/models/sensor_data.dart';
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

  @override
  void initState() {
    super.initState();
    _sensorProvider = context.read<SensorProvider>();
    _sensorProvider?.restartAnalysisStream();
  }

  @override
  void dispose() {
    _clearAnalysisSession(notify: false);
    super.dispose();
  }

  void _clearAnalysisSession({bool notify = true}) {
    _sensorProvider?.stopSensorStream(notify: false);
    _sensorProvider?.resetAnalysisData(notify: notify);
  }

  void _handleBackPressed(SensorProvider provider) {
    _clearAnalysisSession();

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/fruit-selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SensorProvider>(
        builder: (context, provider, child) {
          // Always show analysis UI; results will appear when sensor data is received

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                leading: BackButton(
                  onPressed: () => _handleBackPressed(provider),
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

                    // const SizedBox(height: 24),
                    // BuildChemicalRipeningChart(
                    //   context: context,
                    //   provider: provider,
                    // ),
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
    final history = provider.getSensorHistory();

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
              sparklineData: _sparklineSpots(history, (item) => item.humidity),
            ),
            SensorCard(
              title: AppStrings.temperature,
              value: data.temperature.toStringAsFixed(1),
              unit: '°C',
              icon: Icons.thermostat,
              color: AppColors.primaryOrange,
              sparklineData: _sparklineSpots(
                history,
                (item) => item.temperature,
              ),
            ),
            SensorCard(
              title: AppStrings.voc,
              value: data.gasResistance.toStringAsFixed(2),
              unit: 'Kohm',
              icon: Icons.air,
              color: _getVocColor(data.gasResistance),
              sparklineData: _sparklineSpots(
                history,
                (item) => item.gasResistance,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<FlSpot> _sparklineSpots(
    List<SensorData> history,
    double Function(SensorData item) valueForItem,
  ) {
    if (history.isEmpty) return const [FlSpot(0, 0), FlSpot(2, 0)];

    final spots = history.asMap().entries.map((entry) {
      return FlSpot(entry.key * 2.0, valueForItem(entry.value));
    }).toList();

    if (spots.length == 1) {
      spots.add(FlSpot(2, spots.first.y));
    }

    return spots;
  }

  Color _getVocColor(double voc) {
    if (voc > 45) return AppColors.primaryGreen;
    if (voc > 35) return AppColors.primaryOrange;
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
