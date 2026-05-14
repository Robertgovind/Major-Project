import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fruit_pulse/core/constants/app_colors.dart';
import 'package:fruit_pulse/shared/providers/sensor_provider.dart';
import 'package:fruit_pulse/shared/widgets/app_card.dart';

class BuildChemicalRipeningChart extends StatelessWidget {
  const BuildChemicalRipeningChart({
    super.key,
    required this.context,
    required this.provider,
  });

  final BuildContext context;
  final SensorProvider provider;

  @override
  Widget build(BuildContext context) {
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
}
