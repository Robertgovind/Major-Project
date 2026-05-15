import 'package:flutter/material.dart';
import 'package:fruit_pulse/core/constants/app_colors.dart';
import 'package:fruit_pulse/shared/providers/sensor_provider.dart';

class HistoryTab extends StatelessWidget {
  final SensorProvider provider;

  const HistoryTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final history = provider.sensorHistory.reversed.toList();

    return history.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No sensor history available yet. Start the live sensor stream to see readings here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final reading = history[index];

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatTimestamp(reading.timestamp),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          _buildBadge('R', reading.r, AppColors.primaryRed),

                          const SizedBox(width: 8),

                          _buildBadge('G', reading.g, AppColors.primaryGreen),

                          const SizedBox(width: 8),

                          _buildBadge('B', reading.b, AppColors.primaryBlue),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          _buildStat(
                            'Temp',
                            '${reading.temperature.toStringAsFixed(1)}°C',
                          ),

                          _buildStat(
                            'Humidity',
                            '${reading.humidity.toStringAsFixed(1)}%',
                          ),

                          _buildStat('VOC', reading.voc.toStringAsFixed(2)),

                          _buildStat(
                            'Ripening',
                            '${(reading.chemicalRipening * 100).toStringAsFixed(1)}%',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}

Widget _buildBadge(String label, int value, Color backgroundColor) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: backgroundColor.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      '$label: $value',
      style: TextStyle(color: backgroundColor, fontWeight: FontWeight.bold),
    ),
  );
}

Widget _buildStat(String label, String value) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 4),

      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),

      Text(
        value,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    ],
  );
}

String _formatTimestamp(DateTime timestamp) {
  final local = timestamp.toLocal();

  return '${local.year}-${_twoDigits(local.month)}-${_twoDigits(local.day)} '
      '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
}

String _twoDigits(int value) {
  return value.toString().padLeft(2, '0');
}
