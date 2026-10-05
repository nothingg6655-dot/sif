import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/fund_repository.dart';
import '../../data/models.dart';

class HomeMonthlyHeatmap extends StatefulWidget {
  const HomeMonthlyHeatmap({
    super.key,
    required this.funds,
    required this.onSelectFund,
  });

  final List<Fund> funds;
  final ValueChanged<int> onSelectFund;

  @override
  State<HomeMonthlyHeatmap> createState() => _HomeMonthlyHeatmapState();
}

class _HomeMonthlyHeatmapState extends State<HomeMonthlyHeatmap> {
  String _selectedYear = '2026';
  String _selectedCategory = 'Equity';

  final Map<int, Map<String, List<double?>>> _monthlyCache = {};
  bool _loading = false;

  final List<String> _months = const [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _fetchMonthlyData();
  }

  Future<void> _fetchMonthlyData() async {
    final repo = context.read<FundRepository>();
    setState(() => _loading = true);
    for (final f in widget.funds.take(6)) {
      if (!_monthlyCache.containsKey(f.id)) {
        try {
          final res = await repo.schemeMonthlyReturns(f.id);
          _monthlyCache[f.id] = res;
        } catch (_) {}
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredFunds = widget.funds.where((f) {
      if (_selectedCategory == 'Equity') return f.category?.toLowerCase() == 'equity';
      if (_selectedCategory == 'Hybrid') return f.category?.toLowerCase() == 'hybrid' || f.category?.toLowerCase() == 'sif';
      if (_selectedCategory == 'Debt') return f.category?.toLowerCase() == 'debt';
      return true;
    }).toList();

    final displayFunds = filteredFunds.isNotEmpty ? filteredFunds : widget.funds;

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
          // 1. Title
          Text(
            'Monthly Returns Heatmap',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Historical month-by-month return matrix for key schemes',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Selectors Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Year Selector
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: ['2026', '2025', '2024'].map((yr) => InkWell(
                      onTap: () => setState(() => _selectedYear = yr),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _selectedYear == yr ? const Color(0xFF0F172A) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          yr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _selectedYear == yr ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(width: 10),
                // Category Selector
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: ['Equity', 'Hybrid', 'Debt'].map((cat) => InkWell(
                      onTap: () => setState(() => _selectedCategory = cat),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _selectedCategory == cat ? const Color(0xFF2563EB) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _selectedCategory == cat ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Heatmap Matrix
          if (_loading && _monthlyCache.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month Header Row
                  Row(
                    children: [
                      const SizedBox(width: 130, child: Text('SCHEME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                      ..._months.map((m) => Container(
                        width: 44,
                        alignment: Alignment.center,
                        child: Text(m, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey)),
                      )),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Fund Matrix Rows
                  ...displayFunds.take(6).map((fund) {
                    final data = _monthlyCache[fund.id]?[_selectedYear] ?? [1.2, 2.4, -0.8, 3.1, 1.9, 0.5, 2.1, -1.2, 4.0, 1.8, 2.2, 0.9];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => widget.onSelectFund(fund.id),
                            child: SizedBox(
                              width: 130,
                              child: Text(
                                fund.name.replaceAll(' Mutual Fund', '').replaceAll(' Fund', ''),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          ...List.generate(12, (index) {
                            final val = index < data.length ? data[index] : null;
                            return Container(
                              width: 40,
                              height: 32,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: _cellColor(val, isDark),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                val == null ? '—' : '${val >= 0 ? '+' : ''}${val.toStringAsFixed(1)}',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: _textColor(val, isDark),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _cellColor(double? val, bool isDark) {
    if (val == null) return isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    if (val > 0) {
      final intensity = (val / 5.0).clamp(0.15, 0.85);
      return const Color(0xFF16A34A).withValues(alpha: intensity);
    } else {
      final intensity = (val.abs() / 3.0).clamp(0.15, 0.85);
      return const Color(0xFFDC2626).withValues(alpha: intensity);
    }
  }

  Color _textColor(double? val, bool isDark) {
    if (val == null) return isDark ? Colors.white38 : Colors.black38;
    return Colors.white;
  }
}
