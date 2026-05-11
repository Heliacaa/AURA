import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/daily_log_model.dart';

class WeeklyChart extends StatelessWidget {
  final List<DailyLogModel> logs;

  const WeeklyChart({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        ),
        child: Text(
          'No data yet',
          style: GoogleFonts.poppins(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _legendDot(AppTheme.primaryAccent),
              const SizedBox(width: 4),
              Text(
                'Score',
                style: GoogleFonts.poppins(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 12),
              _legendDot(AppTheme.secondaryAccent),
              const SizedBox(width: 4),
              Text(
                'Steps (k)',
                style: GoogleFonts.poppins(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 12),
              _legendDot(AppTheme.statBlue),
              const SizedBox(width: 4),
              Text(
                'Sleep (h)',
                style: GoogleFonts.poppins(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.white.withAlpha(10), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= logs.length) {
                          return const SizedBox.shrink();
                        }
                        final date = logs[idx].date;
                        final day = date.length >= 10
                            ? date.substring(8, 10)
                            : '';
                        return Text(
                          day,
                          style: GoogleFonts.poppins(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  // Daily score line
                  LineChartBarData(
                    spots: _scoreSpots(),
                    isCurved: true,
                    color: AppTheme.primaryAccent,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryAccent.withAlpha(30),
                    ),
                  ),
                  // Steps line (normalized to 0-100 scale, 10k = 100)
                  LineChartBarData(
                    spots: _stepSpots(),
                    isCurved: true,
                    color: AppTheme.secondaryAccent,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                  // Sleep line (normalized: 10h = 100)
                  LineChartBarData(
                    spots: _sleepSpots(),
                    isCurved: true,
                    color: AppTheme.statBlue,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _scoreSpots() {
    return List.generate(
      logs.length,
      (i) => FlSpot(i.toDouble(), logs[i].dailyScore.toDouble()),
    );
  }

  List<FlSpot> _stepSpots() {
    return List.generate(
      logs.length,
      (i) => FlSpot(i.toDouble(), (logs[i].stepCount / 100).clamp(0, 100)),
    );
  }

  List<FlSpot> _sleepSpots() {
    return List.generate(
      logs.length,
      (i) => FlSpot(i.toDouble(), (logs[i].sleepHours * 10).clamp(0, 100)),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
