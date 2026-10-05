import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../data/fund_repository.dart';
import '../../data/models.dart';

class HomePerformanceComparison extends StatefulWidget {
  const HomePerformanceComparison({
    super.key,
    required this.funds,
    required this.onSelectFund,
  });

  final List<Fund> funds;
  final ValueChanged<int> onSelectFund;

  @override
  State<HomePerformanceComparison> createState() => _HomePerformanceComparisonState();
}

class _HomePerformanceComparisonState extends State<HomePerformanceComparison> {
  String _activeTab = 'Performance'; // 'Performance' | 'Rolling Returns'
  String _selectedCategory = 'All';
  String _timeframe = '1Y'; // 1D, 1M, 3M, 6M, 1Y, SI
  final Set<int> _selectedFundIds = {};

  final Map<int, List<SeriesPoint>> _navHistoryCache = {};
  bool _loadingChart = false;

  final List<Color> _palette = const [
    Color(0xFF581C87), // Deep Purple
    Color(0xFF8B5CF6), // Violet
    Color(0xFFD97706), // Amber
    Color(0xFFDC2626), // Crimson
    Color(0xFF047857), // Emerald
    Color(0xFF2563EB), // Brand Blue
    Color(0xFF0891B2), // Cyan
    Color(0xFFF97316), // Orange
  ];

  @override
  void initState() {
    super.initState();
    // Default select first 3-4 funds
    if (widget.funds.isNotEmpty) {
      _selectedFundIds.addAll(widget.funds.take(4).map((f) => f.id));
      _loadHistoryForSelected();
    }
  }

  @override
  void didUpdateWidget(HomePerformanceComparison oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedFundIds.isEmpty && widget.funds.isNotEmpty) {
      _selectedFundIds.addAll(widget.funds.take(4).map((f) => f.id));
      _loadHistoryForSelected();
    }
  }

  Future<void> _loadHistoryForSelected() async {
    final repo = context.read<FundRepository>();
    setState(() => _loadingChart = true);
    for (final id in _selectedFundIds) {
      if (!_navHistoryCache.containsKey(id)) {
        try {
          final plans = await repo.fundPlans(id);
          final preferredPlan = plans.firstWhere(
            (p) => p.type.toLowerCase().contains('direct') && p.option.toLowerCase().contains('growth'),
            orElse: () => plans.isNotEmpty ? plans.first : Plan.fromJson({'planId': id, 'planType': 'Direct', 'optionType': 'Growth'}),
          );
          final history = await repo.planNavHistory(preferredPlan.id);
          _navHistoryCache[id] = history;
        } catch (_) {
          _navHistoryCache[id] = [];
        }
      }
    }
    if (mounted) setState(() => _loadingChart = false);
  }

  void _toggleFund(int id) {
    setState(() {
      if (_selectedFundIds.contains(id)) {
        if (_selectedFundIds.length > 1) {
          _selectedFundIds.remove(id);
        }
      } else {
        if (_selectedFundIds.length < 5) {
          _selectedFundIds.add(id);
          _loadHistoryForSelected();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredFunds = widget.funds.where((f) {
      if (_selectedCategory == 'All') return true;
      if (_selectedCategory == 'Equity') return f.category?.toLowerCase() == 'equity';
      if (_selectedCategory == 'Hybrid') return f.category?.toLowerCase() == 'hybrid' || f.category?.toLowerCase() == 'sif';
      if (_selectedCategory == 'Debt') return f.category?.toLowerCase() == 'debt';
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
          // 1. Header & Main Tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Performance Comparison (NAV)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Real-time comparative NAV trajectories',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Tab Switcher
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    _tabPill('Performance', _activeTab == 'Performance', () => setState(() => _activeTab = 'Performance')),
                    _tabPill('Rolling', _activeTab == 'Rolling Returns', () => setState(() => _activeTab = 'Rolling Returns')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Category & Timeframe Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...['All', 'Equity', 'Hybrid', 'Debt'].map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(cat, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    selected: _selectedCategory == cat,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    showCheckmark: false,
                    selectedColor: const Color(0xFF2563EB),
                    labelStyle: TextStyle(
                      color: _selectedCategory == cat ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                    ),
                  ),
                )),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: ['1D', '1M', '3M', '6M', '1Y', 'SI'].map((tf) => InkWell(
                      onTap: () => setState(() => _timeframe = tf),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: _timeframe == tf ? const Color(0xFF0F172A) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tf,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _timeframe == tf ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Fund Selection Pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filteredFunds.take(6).map((f) {
              final isSelected = _selectedFundIds.contains(f.id);
              final colorIdx = widget.funds.indexOf(f) % _palette.length;
              final fundColor = _palette[colorIdx];

              return InkWell(
                onTap: () => _toggleFund(f.id),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? fundColor : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? fundColor : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.white : fundColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: Text(
                          f.amc.isNotEmpty ? '${f.amc.split(' ').first} · ${f.name}' : f.name,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.check, size: 12, color: Colors.white),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // 4. Interactive Chart Area
          SizedBox(
            height: 220,
            child: _loadingChart
                ? const Center(child: CircularProgressIndicator())
                : _buildChart(isDark),
          ),
          const SizedBox(height: 12),

          // Notice
          Center(
            child: Text(
              'Showing comparative Direct Growth NAV trajectory. Tap pills above to toggle schemes.',
              style: TextStyle(
                fontSize: 10,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(bool isDark) {
    final activeSeries = <LineChartBarData>[];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    int maxPoints = 0;

    for (final id in _selectedFundIds) {
      final points = _navHistoryCache[id] ?? [];
      if (points.isEmpty) continue;

      // Filter by timeframe
      final filteredPoints = _filterByTimeframe(points, _timeframe);
      if (filteredPoints.isEmpty) continue;

      final startNav = filteredPoints.first.value;
      if (startNav <= 0) continue;

      final spots = <FlSpot>[];
      for (int i = 0; i < filteredPoints.length; i++) {
        final pctReturn = ((filteredPoints[i].value - startNav) / startNav) * 100;
        spots.add(FlSpot(i.toDouble(), pctReturn));
        if (pctReturn < minY) minY = pctReturn;
        if (pctReturn > maxY) maxY = pctReturn;
      }

      if (spots.length > maxPoints) maxPoints = spots.length;

      final fund = widget.funds.firstWhere((f) => f.id == id, orElse: () => widget.funds.first);
      final colorIdx = widget.funds.indexOf(fund) % _palette.length;
      final color = _palette[colorIdx];

      activeSeries.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color,
          barWidth: 2.2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    if (activeSeries.isEmpty) {
      return Center(
        child: Text(
          'No chart history available for selected schemes.',
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 12),
        ),
      );
    }

    minY = (minY.isFinite ? minY : 0) - 1.0;
    maxY = (maxY.isFinite ? maxY : 10) + 1.0;

    return LineChart(
      LineChartBarDataDependency(
        activeSeries: activeSeries,
        minY: minY,
        maxY: maxY,
        isDark: isDark,
      ).chartData,
    );
  }

  List<SeriesPoint> _filterByTimeframe(List<SeriesPoint> points, String tf) {
    if (points.isEmpty) return [];
    if (tf == 'SI') return points;
    final lastDate = points.last.date;
    final months = switch (tf) {
      '1D' => 0,
      '1M' => 1,
      '3M' => 3,
      '6M' => 6,
      '1Y' => 12,
      _ => 12,
    };
    if (months == 0) return points.length > 2 ? points.sublist(points.length - 2) : points;
    final cutoff = DateTime(lastDate.year, lastDate.month - months, lastDate.day);
    return points.where((p) => !p.date.isBefore(cutoff)).toList();
  }

  Widget _tabPill(String title, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF4F46E5) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: active ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }
}

class LineChartBarDataDependency {
  LineChartBarDataDependency({
    required this.activeSeries,
    required this.minY,
    required this.maxY,
    required this.isDark,
  });

  final List<LineChartBarData> activeSeries;
  final double minY, maxY;
  final bool isDark;

  LineChartData get chartData => LineChartData(
    gridData: FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: ((maxY - minY) / 4).clamp(1.0, 50.0),
      getDrawingHorizontalLine: (value) => FlLine(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        strokeWidth: 1,
      ),
    ),
    titlesData: FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 42,
          getTitlesWidget: (value, meta) => Text(
            '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}%',
            style: TextStyle(
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ),
    borderData: FlBorderData(show: false),
    minY: minY,
    maxY: maxY,
    lineBarsData: activeSeries,
  );
}
