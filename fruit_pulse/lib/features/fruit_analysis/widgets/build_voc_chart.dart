import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fruit_pulse/core/constants/app_colors.dart';
import 'package:fruit_pulse/shared/providers/sensor_provider.dart';
import 'package:fruit_pulse/shared/widgets/app_card.dart';

class VocChartWidget extends StatelessWidget {
  const VocChartWidget({
    super.key,
    required this.context,
    required this.provider,
  });
  final BuildContext context;
  final SensorProvider provider;

  @override
  Widget build(BuildContext context) {
    final history = provider.getSensorHistory();

    if (history.isEmpty) {
      return const SizedBox();
    }

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
}
