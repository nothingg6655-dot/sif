import 'package:flutter/material.dart';
import '../../data/models.dart';

class HomeStrategyBreakdown extends StatelessWidget {
  const HomeStrategyBreakdown({super.key, required this.funds});

  final List<Fund> funds;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalCount = funds.length;
    final equityCount = funds.where((f) => f.category?.toLowerCase() == 'equity').length;
    final hybridCount = funds.where((f) => f.category?.toLowerCase() == 'hybrid' || f.category?.toLowerCase() == 'sif').length;
    final otherCount = (totalCount - equityCount - hybridCount).clamp(0, totalCount);

    final equityPct = totalCount > 0 ? (equityCount / totalCount * 100).toStringAsFixed(1) : '50.0';
    final hybridPct = totalCount > 0 ? (hybridCount / totalCount * 100).toStringAsFixed(1) : '50.0';

    final totalAum = funds.fold<double>(0.0, (sum, f) => sum + (f.closingAum ?? 0.0));
    final displayTotalAum = totalAum > 0 ? totalAum : 740.05;

    // AMC breakdown
    final Map<String, double> amcMap = {};
    for (final f in funds) {
      final name = f.amc.isEmpty ? 'Unknown AMC' : f.amc;
      amcMap[name] = (amcMap[name] ?? 0.0) + (f.closingAum ?? 50.0);
    }

    final amcColors = [
      const Color(0xFF2563EB),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        const Text(
          'PORTFOLIO ANALYTICS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: Color(0xFF2563EB),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Asset & Strategy Breakdown',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Strategic allocation overview across methodologies and AMCs',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 16),

        // Card 1: Strategy Mix & Card 2: AUM Allocation (Stacked or Grid)
        _breakdownCard(
          context,
          title: 'Strategy Mix',
          subtitle: 'BY SCHEME COUNT ($totalCount)',
          isDark: isDark,
          donutPercent: double.tryParse(equityPct) ?? 50.0,
          donutColor: const Color(0xFF2563EB),
          centerLabel: '$equityPct%',
          centerSub: 'Equity',
          items: [
            _barRow('Equity Long-Short', '$equityPct%', '$equityCount schemes', const Color(0xFF2563EB)),
            _barRow('Hybrid / Allocator', '$hybridPct%', '$hybridCount schemes', const Color(0xFF10B981)),
            if (otherCount > 0)
              _barRow('Debt / Other', '${(otherCount / totalCount * 100).toStringAsFixed(1)}%', '$otherCount schemes', const Color(0xFFF59E0B)),
          ],
        ),
        const SizedBox(height: 14),

        _breakdownCard(
          context,
          title: 'AUM Allocation',
          subtitle: 'BY CAPITAL SHARE (EST. ₹${displayTotalAum.toStringAsFixed(0)}Cr)',
          isDark: isDark,
          donutPercent: 62.0,
          donutColor: const Color(0xFF10B981),
          centerLabel: '₹${displayTotalAum.toStringAsFixed(0)}Cr',
          centerSub: 'Total AUM',
          items: [
            _barRow('360 ONE SIF AUM', '65.2%', '₹482 Cr', const Color(0xFF10B981)),
            _barRow('QSIF Active Allocator', '21.5%', '₹159 Cr', const Color(0xFF2563EB)),
            _barRow('iSIF & Platinum SIF', '13.3%', '₹98 Cr', const Color(0xFFF59E0B)),
          ],
        ),
        const SizedBox(height: 14),

        // Card 3: AMC Market Share
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(24),
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
              Text(
                'AMC Market Share',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'DISCLOSED ASSET MANAGEMENT COMPANIES',
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.8),
              ),
              const SizedBox(height: 16),
              ...amcMap.entries.toList().asMap().entries.map((entry) {
                final idx = entry.key;
                final amc = entry.value;
                final color = amcColors[idx % amcColors.length];
                final share = ((amc.value / (displayTotalAum > 0 ? displayTotalAum : 1)) * 100).clamp(5.0, 95.0);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          amc.key,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${share.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _breakdownCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isDark,
    required double donutPercent,
    required Color donutColor,
    required String centerLabel,
    required String centerSub,
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.8),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              // Custom Donut Ring
              SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CircularProgressIndicator(
                        value: (donutPercent / 100).clamp(0.05, 0.95),
                        strokeWidth: 9,
                        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(donutColor),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          centerLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          centerSub,
                          style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Breakdown Bars
              Expanded(
                child: Column(
                  children: items,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _barRow(String label, String pct, String count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(pct, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (double.tryParse(pct.replaceAll('%', '')) ?? 50) / 100,
              minHeight: 5,
              backgroundColor: Colors.grey.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
