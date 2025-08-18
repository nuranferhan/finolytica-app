import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme.dart';
import '../models/transaction.dart';

class ExpenseChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String chartType; // 'pie', 'bar', 'line'

  const ExpenseChart({
    Key? key,
    required this.transactions,
    this.chartType = 'pie',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (chartType) {
      case 'bar':
        return _buildBarChart();
      case 'line':
        return _buildLineChart();
      case 'pie':
      default:
        return _buildPieChart();
    }
  }

  Widget _buildPieChart() {
    final categoryData = _getCategoryData();
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.accentColor,
      AppTheme.errorColor,
      AppTheme.successColor,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];

    return Container(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: categoryData.entries.map((entry) {
            final index = categoryData.keys.toList().indexOf(entry.key);
            return PieChartSectionData(
              color: colors[index % colors.length],
              value: entry.value,
              title: '${entry.value.toStringAsFixed(0)}%',
              titleStyle: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              radius: 80,
            );
          }).toList(),
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final weeklyData = _getWeeklyData();
    
    return Container(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: weeklyData.values.isEmpty ? 100 : weeklyData.values.reduce((a, b) => a > b ? a : b) * 1.2,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                  return Text(
                    days[value.toInt() % days.length],
                    style: TextStyle(fontSize: 12),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: weeklyData.entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value,
                  color: AppTheme.primaryColor,
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    final monthlyData = _getMonthlyData();
    
    return Container(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz'];
                  return Text(
                    months[value.toInt() % months.length],
                    style: TextStyle(fontSize: 12),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: monthlyData.entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value);
              }).toList(),
              isCurved: true,
              color: AppTheme.primaryColor,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primaryColor.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, double> _getCategoryData() {
    final Map<String, double> categoryTotals = {};
    double totalAmount = 0;

    for (var transaction in transactions) {
      if (transaction.type == 'expense') {
        final category = transaction.categoryId ?? 'Diğer';
        categoryTotals[category] = (categoryTotals[category] ?? 0) + transaction.amount;
        totalAmount += transaction.amount;
      }
    }

    final Map<String, double> categoryPercentages = {};
    categoryTotals.forEach((category, amount) {
      categoryPercentages[category] = totalAmount > 0 ? (amount / totalAmount) * 100 : 0;
    });

    return categoryPercentages;
  }

  Map<int, double> _getWeeklyData() {
    final Map<int, double> weeklyTotals = {};
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    for (int i = 0; i < 7; i++) {
      weeklyTotals[i] = 0;
    }

    for (var transaction in transactions) {
      if (transaction.type == 'expense' && transaction.date.isAfter(startOfWeek)) {
        final dayIndex = transaction.date.weekday - 1;
        weeklyTotals[dayIndex] = (weeklyTotals[dayIndex] ?? 0) + transaction.amount;
      }
    }

    return weeklyTotals;
  }

  Map<int, double> _getMonthlyData() {
    final Map<int, double> monthlyTotals = {};
    
    for (int i = 0; i < 6; i++) {
      monthlyTotals[i] = 0;
    }

    for (var transaction in transactions) {
      if (transaction.type == 'expense') {
        final monthIndex = transaction.date.month - 1;
        if (monthIndex >= 0 && monthIndex < 6) {
          monthlyTotals[monthIndex] = (monthlyTotals[monthIndex] ?? 0) + transaction.amount;
        }
      }
    }

    return monthlyTotals;
  }
}

class ChartLegend extends StatelessWidget {
  final Map<String, Color> items;

  const ChartLegend({Key? key, required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: items.entries.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: entry.value,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 4),
            Text(
              entry.key,
              style: TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }
}