import 'package:flutter/material.dart';
import '../../core/models/device_state.dart';
import '../theme/app_theme.dart';

/// 5 filled dots representing confidence.
/// Each dot = 20%. Colour follows the spec: green/yellow/orange/red.
class ConfidenceDots extends StatelessWidget {
  final Confidence confidence;

  const ConfidenceDots({super.key, required this.confidence});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.confidenceColor(confidence.value);
    final filled = confidence.dots;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: List.generate(5, (i) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < filled ? color : color.withOpacity(0.2),
          ),
        );
      }),
    );
  }
}