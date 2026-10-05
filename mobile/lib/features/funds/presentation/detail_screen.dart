import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/states.dart';
import '../data/fund_repository.dart';
import '../data/models.dart';
import '../fund_controller.dart';
import 'analytics_panel.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.id});
  final int id;
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}
class _DetailScreenState extends State<DetailScreen> {
  late Future<FundDetails> request;
  int? selected;
  int refreshVersion = 0;
  @override
  void initState() { super.initState(); request = context.read<FundRepository>().details(widget.id); }
  Future<void> refresh() async {
    setState(() { refreshVersion++; request = context.read<FundRepository>().details(widget.id); });
    try { await request; } catch (_) {}
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Fund factsheet')),
    body: SafeArea(child: FutureBuilder<FundDetails>(future: request, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return StatusView(errorMessage(snapshot.error), onRetry: refresh);
      final data = snapshot.data!;
      final o = data.overview;
      final plan = data.plans.isEmpty ? null : data.plans.firstWhere((p) => p.id == selected, orElse: () => data.preferred!);
      final state = context.watch<FundController>();
      final compared = state.selected.any((f) => f.id == widget.id);
      return RefreshIndicator(onRefresh: refresh, child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(20), children: [
        Text(o.fund.amc, style: Theme.of(context).textTheme.labelLarge), const SizedBox(height: 8),
        Text(o.fund.name, style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: () {
          if (!state.toggle(o.fund)) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compare up to five funds.')));
        }, icon: Icon(compared ? Icons.check : Icons.add), label: Text(compared ? 'Remove from comparison' : 'Add to comparison')),
        Section('Investment approach', [Text(o.objective ?? 'Investment objective unavailable.')]),
        Section('Key facts', [Fact('Scheme code', o.code ?? 'Unavailable'), Fact('Category', o.fund.category ?? 'Unavailable'),
          Fact('Risk band', o.fund.riskBand?.toString() ?? 'Unavailable'), Fact('Allotment date', o.allotment ?? 'Unavailable'),
          Fact('Closing AUM${data.aumUnit == null ? '' : ' (${data.aumUnit})'}', amount(data.aum)), Fact('AUM as of', data.aumDate ?? 'Unavailable'),
          Fact('Minimum investment (₹)', amount(o.minimum)), Fact('Additional investment (₹)', amount(o.additional)),
          Fact('Exit load', o.exitLoad ?? 'Unavailable'), Fact('Benchmark', o.benchmark ?? 'Unavailable'),
          Fact('Managers', data.managers.isEmpty ? 'Unavailable' : data.managers.join('\n')),
          Fact('Registrar', o.registrar ?? 'Unavailable'), Fact('Custodian', o.custodian ?? 'Unavailable'), Fact('Auditor', o.auditor ?? 'Unavailable')]),
        if (plan == null) const Section('Plans', [Text('No active plans available.')]) else ...[
          const SizedBox(height: 12), DropdownButtonFormField<int>(key: ValueKey(plan.id), initialValue: plan.id, isExpanded: true,
            decoration: const InputDecoration(labelText: 'Plan and option'),
            items: data.plans.map((p) => DropdownMenuItem(value: p.id, child: Text(p.label, maxLines: 2, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (id) => setState(() => selected = id)),
          Section('Plan identifiers', [Fact('SIF code', plan.sifCode ?? 'Unavailable'), Fact('ISIN', plan.isin ?? 'Unavailable'),
            Fact('Maximum expense ratio', plan.expense == null ? 'Unavailable' : '${amount(plan.expense)}%')]),
          AnalyticsPanel(key: ValueKey('${plan.id}:$refreshVersion'), plan: plan),
        ],
        Section('Top holdings · ${data.portfolioDate ?? 'date unavailable'}', allocations(data.holdings)),
        Section('Sector allocation', allocations(data.sectors)), Section('Asset allocation', allocations(data.allocation)),
      ]));
    })));
  List<Widget> allocations(List<Allocation> rows) => rows.isEmpty ? [const Text('No disclosure data available.')] :
    rows.map((r) => Fact(r.name, r.value == null ? 'Unavailable' : '${amount(r.value)}%')).toList();
}
