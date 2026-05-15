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
            const SizedBox(
              height: 200,
              child: Center(child: Text('Waiting for live sensor readings...')),
            ),
          ],
        ),
      );
    }

    final spots = history.asMap().entries.map((entry) {
      final seconds = entry.key * 2.0;
      final data = entry.value;

      // Use gas resistance for the VOC Gas Resistance trend chart; backend
      // provides `gasResistance` as the live sensor reading.
      return FlSpot(seconds, data.gasResistance);
    }).toList();
    if (spots.length == 1) {
      spots.add(FlSpot(2, spots.first.y));
    }

    final yValues = spots.map((spot) => spot.y).toList();
    final minValue = yValues.reduce((a, b) => a < b ? a : b);
    final maxValue = yValues.reduce((a, b) => a > b ? a : b);
    final padding = (maxValue - minValue).abs() < 0.001
        ? 5.0
        : (maxValue - minValue) * 0.2;
    final minY = (minValue - padding).clamp(0.0, double.infinity).toDouble();
    final maxY = maxValue + padding;

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
                minY: minY,
                maxY: maxY <= minY ? minY + 10 : maxY,
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
                    color: _getVocColor(history.last.gasResistance),
                    barWidth: 3,
                    dotData: FlDotData(show: history.length < 2),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _getVocColor(
                        history.last.gasResistance,
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
    // Thresholds tuned for gas resistance readings (kohm-ish)
    if (voc > 45) return AppColors.primaryGreen;
    if (voc > 35) return AppColors.primaryOrange;
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
