// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:fruit_pulse/core/constants/app_colors.dart';
// import 'package:fruit_pulse/shared/providers/sensor_provider.dart';
// import 'package:fruit_pulse/shared/widgets/app_card.dart';

// class BuildChemicalRipeningChart extends StatelessWidget {
//   const BuildChemicalRipeningChart({
//     super.key,
//     required this.context,
//     required this.provider,
//   });

//   final BuildContext context;
//   final SensorProvider provider;

//   @override
//   Widget build(BuildContext context) {
//     final predictionHistory = provider.getPredictionHistory();
//     if (predictionHistory.isEmpty) {
//       return AppCard(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.trending_up, color: AppColors.primaryOrange),
//                 const SizedBox(width: 8),
//                 Text(
//                   'Chemical Ripening Prediction',
//                   style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                     color: AppColors.primaryOrange,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             const SizedBox(
//               height: 150,
//               child: Center(child: Text('Waiting for prediction results...')),
//             ),
//           ],
//         ),
//       );
//     }

//     final spots = predictionHistory.asMap().entries.map((entry) {
//       final seconds = entry.key * 2.0;
//       final prediction = entry.value;
//       final chemicalScore = prediction.isNaturalRipening
//           ? (1 - prediction.confidence) * 100
//           : prediction.confidence * 100;

//       return FlSpot(seconds, chemicalScore.clamp(0, 100).toDouble());
//     }).toList();
//     if (spots.length == 1) {
//       spots.add(FlSpot(1, spots.first.y));
//     }

//     final latestPrediction = predictionHistory.last;
//     final chartColor = latestPrediction.isNaturalRipening
//         ? AppColors.primaryGreen
//         : AppColors.primaryRed;

//     return AppCard(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.trending_up, color: AppColors.primaryOrange),
//               const SizedBox(width: 8),
//               Text(
//                 'Chemical Ripening Trend',
//                 style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                   color: AppColors.primaryOrange,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           SizedBox(
//             height: 150,
//             child: LineChart(
//               LineChartData(
//                 minY: 0,
//                 maxY: 100,
//                 gridData: const FlGridData(show: true),
//                 titlesData: FlTitlesData(
//                   leftTitles: AxisTitles(
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       reservedSize: 40,
//                       getTitlesWidget: (value, meta) => Text(
//                         '${value.toInt()}%',
//                         style: const TextStyle(fontSize: 12),
//                       ),
//                     ),
//                   ),
//                   bottomTitles: AxisTitles(
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       getTitlesWidget: (value, meta) => Text(
//                         '${value.toInt()}s',
//                         style: const TextStyle(fontSize: 12),
//                       ),
//                     ),
//                   ),
//                   rightTitles: const AxisTitles(
//                     sideTitles: SideTitles(showTitles: false),
//                   ),
//                   topTitles: const AxisTitles(
//                     sideTitles: SideTitles(showTitles: false),
//                   ),
//                 ),
//                 borderData: FlBorderData(show: true),
//                 lineBarsData: [
//                   LineChartBarData(
//                     spots: spots,
//                     isCurved: true,
//                     color: chartColor,
//                     barWidth: 3,
//                     dotData: FlDotData(show: predictionHistory.length < 2),
//                     belowBarData: BarAreaData(
//                       show: true,
//                       color: chartColor.withValues(alpha: 0.1),
//                     ),
//                   ),
//                   LineChartBarData(
//                     spots: spots.map((spot) => FlSpot(spot.x, 50)).toList(),
//                     isCurved: false,
//                     color: Colors.grey,
//                     barWidth: 1,
//                     dotData: const FlDotData(show: false),
//                     dashArray: [5, 5],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               _buildLegendItem('Natural', AppColors.primaryGreen),
//               const SizedBox(width: 16),
//               _buildLegendItem('Chemical', AppColors.primaryRed),
//               const SizedBox(width: 16),
//               _buildLegendItem('Threshold', Colors.grey),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLegendItem(String label, Color color) {
//     return Row(
//       children: [
//         Container(
//           width: 20,
//           height: 4,
//           decoration: BoxDecoration(
//             color: color,
//             borderRadius: BorderRadius.circular(2),
//           ),
//         ),
//         const SizedBox(width: 8),
//         Text(label, style: const TextStyle(fontSize: 12)),
//       ],
//     );
//   }
// }
