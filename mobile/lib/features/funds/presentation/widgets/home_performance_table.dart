import 'package:flutter/material.dart';
import '../../data/models.dart';

class HomePerformanceTable extends StatefulWidget {
  const HomePerformanceTable({
    super.key,
    required this.funds,
    required this.onSelectFund,
  });

  final List<Fund> funds;
  final ValueChanged<int> onSelectFund;

  @override
  State<HomePerformanceTable> createState() => _HomePerformanceTableState();
}

class _HomePerformanceTableState extends State<HomePerformanceTable> {
  String _selectedCategory = 'Hybrid';

  final List<Map<String, String>> _categories = [
    {'key': 'Equity', 'label': 'Equity'},
    {'key': 'Equity Ex-top 100', 'label': 'Ex-Top 100'},
    {'key': 'Hybrid', 'label': 'Hybrid'},
    {'key': 'Active allocator', 'label': 'Active Allocator'},
    {'key': 'Sector Rotation', 'label': 'Sector Rotation'},
    {'key': 'Debt', 'label': 'Debt (Soon)'},
  ];

  @override
  Widget build(BuildContext context) {
    final activeFund = widget.funds.firstWhere(
      (f) {
        if (_selectedCategory == 'Equity' || _selectedCategory == 'Equity Ex-top 100') {
          return f.category?.toLowerCase() == 'equity';
        }
        if (_selectedCategory == 'Hybrid' || _selectedCategory == 'Active allocator') {
          return f.category?.toLowerCase() == 'hybrid' || f.category?.toLowerCase() == 'sif';
        }
        return true;
      },
      orElse: () => widget.funds.isNotEmpty
          ? widget.funds.first
          : Fund.fromJson({'schemeId': 1, 'schemeName': 'DynaSIF Active Asset Allocator Long-Short Fund'}),
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF090D3A),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF090D3A).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Performance Analysis of SIFs',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Returns and risk ratios across market cycles',
                      style: TextStyle(fontSize: 10.5, color: Colors.blue.shade200),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('SEBI SIF', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Category Switcher Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((c) {
                final isSelected = _selectedCategory == c['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => setState(() => _selectedCategory = c['key']!),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF2563EB) : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF60A5FA) : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        c['label']!,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),

          // 3. Scheme Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeFund.amc,
                        style: TextStyle(color: Colors.blue.shade300, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          text: activeFund.name,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Category: ${activeFund.category ?? "Specialized Investment Fund"}',
                        style: const TextStyle(color: Colors.white60, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => widget.onSelectFund(activeFund.id),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Factsheet', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Performance Metrics Table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Expanded(flex: 3, child: Text('PERIOD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B)))),
                    Expanded(flex: 2, child: Center(child: Text('RETURN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF16A34A))))),
                    Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('VOLATILITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFDC2626))))),
                  ],
                ),
                const Divider(height: 16),
                _metricRow('1 Month', '+0.90%', '3.00%'),
                _metricRow('3 Month', '+4.10%', '4.80%'),
                _metricRow('6 Month', '+5.80%', '4.90%'),
                _metricRow('1 Year', '+9.20%', '5.20%'),
                _metricRow('Since Inception', '+5.50%', '4.80%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _metricRow(String period, String ret, String vol) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(period, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ret,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  vol,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
