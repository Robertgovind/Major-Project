import 'package:flutter/material.dart';

import 'package:fruit_pulse/core/constants/app_colors.dart';
import 'package:fruit_pulse/shared/providers/sensor_provider.dart';
import 'package:provider/provider.dart';

class TimercalibrationDialog extends StatelessWidget {
  const TimercalibrationDialog({super.key, required this.mounted});

  final bool mounted;

  @override
  Widget build(BuildContext context) {
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
}
