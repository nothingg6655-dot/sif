import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/states.dart';
import '../data/models.dart';
import '../fund_controller.dart';

class FundTile extends StatelessWidget {
  const FundTile(this.fund, {super.key});
  final Fund fund;
  @override
  Widget build(BuildContext context) {
    final state = context.watch<FundController>();
    final selected = state.selected.any((f) => f.id == fund.id);
    return Card(child: InkWell(borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.pushNamed(context, '/fund/${fund.id}'), child: Padding(padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(fund.amc, style: Theme.of(context).textTheme.labelMedium), const SizedBox(height: 8),
        Text(fund.name, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 8),
        Text(fund.category ?? 'Category unavailable', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12), Wrap(spacing: 20, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text('NAV  ${amount(fund.nav, decimals: 4)}'),
          if (fund.riskBand != null) Text('Risk band ${fund.riskBand}'),
          TextButton.icon(onPressed: () {
            if (!state.toggle(fund)) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compare up to five funds.')));
          }, icon: Icon(selected ? Icons.check_circle : Icons.add_circle_outline), label: Text(selected ? 'Selected' : 'Compare')),
        ]),
      ]))));
  }
}
