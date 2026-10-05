import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/states.dart';
import '../data/fund_repository.dart';
import '../data/models.dart';
import 'series_chart.dart';

const periods = ['1M', '3M', '6M', '1Y', 'SINCE_INCEPTION'];
String periodLabel(String p) => p == 'SINCE_INCEPTION' ? 'Since inception' : p;

class AnalyticsPanel extends StatefulWidget {
  const AnalyticsPanel({super.key, required this.plan});
  final Plan plan;
  @override
  State<AnalyticsPanel> createState() => _AnalyticsPanelState();
}
class _AnalyticsPanelState extends State<AnalyticsPanel> {
  String period = 'SINCE_INCEPTION';
  late Future<PlanAnalytics> request;
  @override
  void initState() { super.initState(); load(); }
  void load() { request = context.read<FundRepository>().analytics(widget.plan.id, period); }
  @override
  void didUpdateWidget(AnalyticsPanel oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.plan.id != widget.plan.id) load(); }
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: DropdownButtonFormField<String>(
      initialValue: period, decoration: const InputDecoration(labelText: 'Analysis period'),
      items: periods.map((p) => DropdownMenuItem(value: p, child: Text(periodLabel(p)))).toList(),
      onChanged: (p) { if (p != null) setState(() { period = p; load(); }); })),
    FutureBuilder<PlanAnalytics>(future: request, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
      if (snapshot.hasError) return StatusView(errorMessage(snapshot.error), onRetry: () => setState(load));
      final data = snapshot.data!;
      final months = switch (period) { '1M' => 1, '3M' => 3, '6M' => 6, '1Y' => 12, _ => 0 };
      final last = data.history.isEmpty ? null : data.history.last.date;
      final cutoff = last == null || months == 0 ? null : DateTime(last.year, last.month - months, last.day);
      final history = data.history.where((p) => cutoff == null || !p.date.isBefore(cutoff)).toList();
      return Column(children: [
        Section('NAV history', [Fact('Latest NAV', amount(data.nav, decimals: 4)), Fact('As of', data.navDate ?? 'Unavailable'), SeriesChart(history)]),
        Section('Returns · ${periodLabel(period)}', [Fact('Absolute return', percent(data.returns.absolute)),
          Fact('Annualized return', percent(data.returns.annualized)), Fact('Benchmark return', percent(data.returns.benchmark))]),
        Section('Risk · ${periodLabel(period)}', [Fact('Volatility', percent(data.risk.volatility)), Fact('Alpha', percent(data.risk.alpha)),
          Fact('Beta', amount(data.risk.beta)), Fact('Sharpe ratio', amount(data.risk.sharpe)), Fact('Sortino ratio', amount(data.risk.sortino)),
          Fact('Maximum drawdown', percent(data.risk.drawdown))]),
        Section('Monthly returns', [if (data.monthly.isEmpty) const Text('No monthly history available.'),
          ...data.monthly.entries.map((year) => ExpansionTile(title: Text(year.key), children: [
            Wrap(spacing: 8, runSpacing: 8, children: List.generate(year.value.length, (i) => Container(
              width: 84, padding: const EdgeInsets.all(10), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                color: year.value[i] == null ? Theme.of(context).colorScheme.surfaceContainerHighest :
                  year.value[i]! >= 0 ? Colors.green.withValues(alpha: .12) : Colors.red.withValues(alpha: .12)),
              child: Column(children: [Text(const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][i]),
                Text(year.value[i] == null ? '—' : '${amount(year.value[i])}%', style: const TextStyle(fontSize: 11))])))),
            const SizedBox(height: 12),
          ])),
        ]),
        Section('Rolling return · 3 months', [SeriesChart(data.rolling, percentage: true)]),
        Section('Drawdown history', [SeriesChart(data.drawdown, percentage: true)]),
      ]);
    }),
  ]);
}
