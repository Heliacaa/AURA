import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/meal_model.dart';

class MacroSummaryCard extends StatelessWidget {
  final List<MealModel> meals;
  final int calorieGoal;

  const MacroSummaryCard({
    super.key,
    required this.meals,
    required this.calorieGoal,
  });

  @override
  Widget build(BuildContext context) {
    int totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (final meal in meals) {
      totalCalories += meal.calories;
      totalProtein += meal.protein;
      totalCarbs += meal.carbs;
      totalFat += meal.fat;
    }

    final progress = calorieGoal > 0
        ? (totalCalories / calorieGoal).clamp(0.0, 1.5)
        : 0.0;
    final isOver = totalCalories > calorieGoal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(
          borderColor: isOver ? AppTheme.statRed : AppTheme.secondaryAccent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🍽️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                '$totalCalories / $calorieGoal kcal',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isOver ? AppTheme.statRed : AppTheme.textWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.toDouble(),
              backgroundColor: Colors.white.withAlpha(15),
              valueColor: AlwaysStoppedAnimation(
                  isOver ? AppTheme.statRed : AppTheme.secondaryAccent),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _macroChip('P', totalProtein, AppTheme.secondaryAccent),
              _macroChip('C', totalCarbs, AppTheme.warningOrange),
              _macroChip('F', totalFat, AppTheme.statPink),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroChip(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          '${value.toStringAsFixed(1)}g',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
