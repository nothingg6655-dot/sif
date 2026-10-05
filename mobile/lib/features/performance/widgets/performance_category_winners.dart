import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../funds/data/models.dart';

class CategoryWinnerItem {
  final String category;
  final String returnText;
  final String schemeName;
  final String amc;
  final int fundId;
  final List<double> sparkline;
  final bool isPositive;

  const CategoryWinnerItem({
    required this.category,
    required this.returnText,
    required this.schemeName,
    required this.amc,
    required this.fundId,
    required this.sparkline,
    this.isPositive = true,
  });
}

class PerformanceCategoryWinners extends StatelessWidget {
  const PerformanceCategoryWinners({
    super.key,
    required this.funds,
    required this.onSelectFund,
  });

  final List<Fund> funds;
  final ValueChanged<int> onSelectFund;

  List<CategoryWinnerItem> _buildWinners() {
    final firstId = funds.isNotEmpty ? funds.first.id : 1;
    final firstName = funds.isNotEmpty ? funds.first.name : 'DynaSIF Active Asset Allocator Long-Short Fund';
    final firstAmc = funds.isNotEmpty ? funds.first.amc : '360 ONE Asset Management Limited';

    return [
      CategoryWinnerItem(
        category: 'Equity',
        returnText: '+0.31%',
        schemeName: funds.length > 2 ? funds[2].name : 'qsif Active Asset Allocator Long-Short Fund',
        amc: funds.length > 2 ? funds[2].amc : 'Quantum AMC',
        fundId: funds.length > 2 ? funds[2].id : firstId,
        sparkline: const [10.0, 10.15, 10.08, 10.22, 10.31],
      ),
      CategoryWinnerItem(
        category: 'Active Asset Allocator Long-Short Fund',
        returnText: '+0.08%',
        schemeName: firstName,
        amc: firstAmc,
        fundId: firstId,
        sparkline: const [11.2, 11.22, 11.21, 11.25, 11.29],
      ),
      CategoryWinnerItem(
        category: 'Hybrid',
        returnText: '+0.08%',
        schemeName: firstName,
        amc: firstAmc,
        fundId: firstId,
        sparkline: const [11.2, 11.21, 11.23, 11.26, 11.29],
      ),
      CategoryWinnerItem(
        category: 'Equity Ex-Top 100 Long-Short Fund',
        returnText: '+0.12%',
        schemeName: funds.length > 1 ? funds[1].name : 'DynaSIF Equity Ex-Top 100 Long - Short Fund',
        amc: firstAmc,
        fundId: funds.length > 1 ? funds[1].id : firstId,
        sparkline: const [9.9, 10.05, 10.02, 10.10, 10.12],
      ),
      CategoryWinnerItem(
        category: 'Equity Long-Short Fund',
        returnText: '+0.06%',
        schemeName: funds.length > 3 ? funds[3].name : 'DynaSIF Equity Long - Short Fund',
        amc: firstAmc,
        fundId: funds.length > 3 ? funds[3].id : firstId,
        sparkline: const [10.0, 10.02, 10.01, 10.04, 10.06],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final winners = _buildWinners();

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
          Text(
            'Category Winners',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Leading schemes across active DynaSIF strategies.',
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: winners.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final w = winners[idx];
              return _winnerCard(context, w, isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _winnerCard(BuildContext context, CategoryWinnerItem w, bool isDark) {
    return InkWell(
      onTap: () => onSelectFund(w.fundId),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Category Badge + Return Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : const Color(0xFFBFDBFE),
                      ),
                    ),
                    child: Text(
                      w.category,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    w.returnText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Scheme Name
            Text(
              w.schemeName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),

            // AMC
            Text(
              w.amc,
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Sparkline + Details >
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 100,
                  height: 22,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: w.sparkline.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                          isCurved: true,
                          color: const Color(0xFF10B981),
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: const [
                    Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF2563EB)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
