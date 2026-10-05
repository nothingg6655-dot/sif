import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../data/models.dart';
import '../../fund_controller.dart';

class HomeMarketplace extends StatefulWidget {
  const HomeMarketplace({
    super.key,
    required this.funds,
    required this.onSelectFund,
    required this.onInvestNow,
  });

  final List<Fund> funds;
  final ValueChanged<int> onSelectFund;
  final ValueChanged<String> onInvestNow;

  @override
  State<HomeMarketplace> createState() => _HomeMarketplaceState();
}

class _HomeMarketplaceState extends State<HomeMarketplace> {
  final TextEditingController _searchController = TextEditingController();
  String _riskFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.watch<FundController>();

    final filtered = widget.funds.where((f) {
      final q = _searchController.text.toLowerCase().trim();
      if (q.isNotEmpty) {
        final matchesName = f.name.toLowerCase().contains(q);
        final matchesAmc = f.amc.toLowerCase().contains(q);
        if (!matchesName && !matchesAmc) return false;
      }
      if (_riskFilter != 'All') {
        if (_riskFilter == 'Very High' && f.riskBand != 5) return false;
        if (_riskFilter == 'High' && f.riskBand != 4) return false;
        if (_riskFilter == 'Moderate' && (f.riskBand ?? 0) > 3) return false;
      }
      return true;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            'Active Mutual Funds Marketplace',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Active Mutual Funds Marketplace · Real-time quotes',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // Search & Filter Row
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search scheme name or AMC...',
              hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _searchController.clear()),
                    )
                  : null,
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Risk filter pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _riskPill('All', 'All Profiles'),
                _riskPill('Very High', 'Very High Risk (Band 5)'),
                _riskPill('High', 'High Risk (Band 4)'),
                _riskPill('Moderate', 'Moderate (Band 1-3)'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Scheme Cards
          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No funds match your current filter.',
                  style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
                ),
              ),
            )
          else
            ...filtered.map((f) {
              final isSelected = state.selected.any((s) => s.id == f.id);
              return _fundCard(context, f, isSelected, isDark);
            }),
        ],
      ),
    );
  }

  Widget _riskPill(String key, String label) {
    final active = _riskFilter == key;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => setState(() => _riskFilter = key),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF2563EB) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: active ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fundCard(BuildContext context, Fund f, bool isSelected, bool isDark) {
    final state = context.read<FundController>();
    final amcColor = _pickAmcColor(f.amc);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: AMC Avatar + Name + Compare Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: amcColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: amcColor.withValues(alpha: 0.3)),
                ),
                alignment: Alignment.center,
                child: Text(
                  f.amc.isNotEmpty ? f.amc.substring(0, 1) : 'S',
                  style: TextStyle(color: amcColor, fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => widget.onSelectFund(f.id),
                      child: Text(
                        f.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${f.amc} · ${f.category ?? "SIF"}',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  if (!state.toggle(f)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Compare up to five funds.')),
                    );
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
                  foregroundColor: isSelected ? Colors.white : null,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade400),
                  ),
                ),
                icon: Icon(isSelected ? Icons.check_circle : Icons.add_circle_outline, size: 13),
                label: Text(isSelected ? 'Selected' : 'Compare', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Key Stats Strip: NAV, 1Y Return, AUM, Risk Band
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(child: _statCell('NAV', f.nav != null ? '₹${f.nav!.toStringAsFixed(2)}' : '—')),
                Expanded(child: _statCell('1Y Return', '+9.52%', isPositive: true)),
                Expanded(child: _statCell('AUM', f.closingAum != null ? '₹${f.closingAum!.toStringAsFixed(0)}Cr' : '₹215Cr')),
                Expanded(child: _statCell('Risk', 'Band ${f.riskBand ?? 5}')),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Sparkline Chart
          SizedBox(
            height: 28,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 10.0),
                      FlSpot(1, 10.15),
                      FlSpot(2, 10.05),
                      FlSpot(3, 10.35),
                      FlSpot(4, 10.42),
                      FlSpot(5, 10.58),
                    ],
                    isCurved: true,
                    color: const Color(0xFF10B981),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Action Buttons: Details, Invest Now
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.end,
            children: [
              TextButton(
                onPressed: () => widget.onSelectFund(f.id),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Details', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              FilledButton(
                onPressed: () => widget.onInvestNow(f.name),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Invest Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _statCell(String label, String value, {bool isPositive = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: isPositive ? const Color(0xFF16A34A) : null,
          ),
        ),
      ],
    );
  }

  static Color _pickAmcColor(String amc) {
    if (amc.toLowerCase().contains('360')) return const Color(0xFF2563EB);
    if (amc.toLowerCase().contains('qsif')) return const Color(0xFF8B5CF6);
    if (amc.toLowerCase().contains('isif')) return const Color(0xFF10B981);
    return const Color(0xFFF59E0B);
  }
}
