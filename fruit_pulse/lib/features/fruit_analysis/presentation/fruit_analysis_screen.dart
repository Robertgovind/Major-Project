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

  @override
  void initState() {
    super.initState();
    // Start sensor stream when entering analysis
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _sensorProvider?.startSensorStream();
    });
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/fruit-selection');
            }
          },
        ),
        title: const Text(AppStrings.analysisTitle),
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
      ),
      body: Consumer<SensorProvider>(
        builder: (context, provider, child) {
          if (!provider.isStreaming) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVocChart(SensorProvider provider) {
    final history = provider.sensorHistory;
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
    final history = provider.sensorHistory;
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
    final data = provider.currentSensorData;
    if (data == null) return const SizedBox();

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
    final prediction = provider.currentPrediction;
    if (prediction == null) return const SizedBox();

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
    final prediction = provider.currentPrediction;
    if (prediction == null) return const SizedBox();

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
}
