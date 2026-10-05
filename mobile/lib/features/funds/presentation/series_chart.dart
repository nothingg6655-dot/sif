import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/models.dart';
import '../../../core/widgets/states.dart';

class SeriesChart extends StatelessWidget {
  const SeriesChart(this.points, {super.key, this.percentage = false});
  final List<SeriesPoint> points;
  final bool percentage;
  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const StatusView('No history is available for this period.');
    final color = Theme.of(context).colorScheme.primary;
    final start = points.first.date.millisecondsSinceEpoch;
    final spots = points.map((p) => FlSpot((p.date.millisecondsSinceEpoch - start) / 86400000, p.value * (percentage ? 100 : 1))).toList();
    String date(double x) => DateTime.fromMillisecondsSinceEpoch(start + (x * 86400000).round()).toIso8601String().substring(0, 10);
    return Column(children: [
      Semantics(label: 'Chart from ${date(spots.first.x)} to ${date(spots.last.x)}. ${points.length} observations.',
        child: SizedBox(height: 200, child: Padding(padding: const EdgeInsets.only(right: 12, top: 12), child: LineChart(LineChartData(
          gridData: const FlGridData(show: true, drawVerticalLine: false), borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 48,
              getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 10))))),
          lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(getTooltipItems: (touched) => touched.map((s) =>
            LineTooltipItem('${date(s.x)}\n${s.y.toStringAsFixed(3)}${percentage ? '%' : ''}', const TextStyle(color: Colors.white))).toList())),
          lineBarsData: [LineChartBarData(spots: spots, color: color, barWidth: 2.5,
            dotData: FlDotData(show: points.length == 1), belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.08)))],
        ))))),
      const SizedBox(height: 8), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(date(spots.first.x), style: Theme.of(context).textTheme.bodySmall),
        Text(date(spots.last.x), style: Theme.of(context).textTheme.bodySmall),
      ]),
    ]);
  }
}
