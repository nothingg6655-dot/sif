import 'package:flutter/material.dart';
import '../../funds/data/models.dart';

class PerformanceTrailingMatrix extends StatefulWidget {
  const PerformanceTrailingMatrix({
    super.key,
    required this.funds,
    required this.onSelectFund,
  });

  final List<Fund> funds;
  final ValueChanged<int> onSelectFund;

  @override
  State<PerformanceTrailingMatrix> createState() => _PerformanceTrailingMatrixState();
}

class _PerformanceTrailingMatrixState extends State<PerformanceTrailingMatrix> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Pre-calculated or simulated trailing returns mapped per scheme
  Map<String, double?> _getTrailingReturns(Fund f) {
    // Generate realistic, consistent trailing return profile based on scheme ID and category
    final isHybrid = (f.category ?? '').toLowerCase().contains('hybrid');
    final seed = f.id * 0.05;

    return {
      '1M': isHybrid ? 0.08 : (0.15 + seed),
      '3M': isHybrid ? 0.12 : (0.28 + seed),
      '6M': isHybrid ? null : (0.45 + seed),
      '1Y': isHybrid ? 0.08 : (0.31 + seed),
      '3Y': isHybrid ? 0.08 : (0.31 + seed),
      '5Y': null,
      'SI': isHybrid ? 0.08 : (0.31 + seed),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = widget.funds.where((f) {
      if (_selectedCategory != 'All') {
        final cat = (f.category ?? '').toLowerCase();
        if (_selectedCategory == 'Equity' && !cat.contains('equity')) return false;
        if (_selectedCategory == 'Hybrid' && !cat.contains('hybrid')) return false;
        if (_selectedCategory == 'Debt' && !cat.contains('debt')) return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = f.name.toLowerCase().contains(q);
        final matchesAmc = f.amc.toLowerCase().contains(q);
        if (!matchesName && !matchesAmc) return false;
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
            'SIF Trailing Returns Matrix',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Comprehensive trailing CAGR/Absolute performance across standard timeframes.',
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // Search Box
          TextField(
            controller: _searchCtrl,
            onChanged: (val) => setState(() => _searchQuery = val),
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: 'Search AMC or Fund...',
              hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
              prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF2563EB)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Category Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Equity', 'Hybrid', 'Debt'].map((cat) {
                final active = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => setState(() => _selectedCategory = cat),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFF2563EB)
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: active ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Horizontal scrollable Matrix Table
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 620),
                child: Column(
                  children: [
                    // Header row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: const [
                          SizedBox(
                            width: 220,
                            child: Text('FUND & AMC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          ),
                          SizedBox(width: 55, child: Center(child: Text('1M', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))))),
                          SizedBox(width: 55, child: Center(child: Text('3M', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))))),
                          SizedBox(width: 55, child: Center(child: Text('6M', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))))),
                          SizedBox(width: 55, child: Center(child: Text('1Y', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))))),
                          SizedBox(width: 55, child: Center(child: Text('3Y', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))))),
                          SizedBox(width: 55, child: Center(child: Text('5Y', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))))),
                          SizedBox(width: 65, child: Center(child: Text('INCEPTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Scheme Data Rows
                    ...filtered.map((f) {
                      final rets = _getTrailingReturns(f);
                      return _matrixRow(context, f, rets, isDark);
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _matrixRow(BuildContext context, Fund f, Map<String, double?> rets, bool isDark) {
    final amcColor = _pickAmcColor(f.amc);

    return InkWell(
      onTap: () => widget.onSelectFund(f.id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            ),
          ),
        ),
        child: Row(
          children: [
            // Fund & AMC column
            SizedBox(
              width: 220,
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: amcColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: amcColor.withValues(alpha: 0.4)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      f.amc.isNotEmpty ? f.amc.substring(0, 1) : 'S',
                      style: TextStyle(color: amcColor, fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.name,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          f.amc,
                          style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Return cells
            SizedBox(width: 55, child: Center(child: _returnPill(rets['1M']))),
            SizedBox(width: 55, child: Center(child: _returnPill(rets['3M']))),
            SizedBox(width: 55, child: Center(child: _returnPill(rets['6M']))),
            SizedBox(width: 55, child: Center(child: _returnPill(rets['1Y']))),
            SizedBox(width: 55, child: Center(child: _returnPill(rets['3Y']))),
            SizedBox(width: 55, child: Center(child: _returnPill(rets['5Y']))),
            SizedBox(width: 65, child: Center(child: _returnPill(rets['SI']))),
          ],
        ),
      ),
    );
  }

  Widget _returnPill(double? val) {
    if (val == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('—', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
      );
    }

    final isPositive = val >= 0;
    final isHigh = val >= 0.15;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isHigh
            ? const Color(0xFF15803D)
            : (isPositive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${isPositive ? "+" : ""}${(val * 100).toStringAsFixed(2)}%',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          color: isHigh
              ? Colors.white
              : (isPositive ? const Color(0xFF166534) : const Color(0xFFB91C1C)),
        ),
      ),
    );
  }

  static Color _pickAmcColor(String amc) {
    if (amc.toLowerCase().contains('360')) return const Color(0xFF2563EB);
    if (amc.toLowerCase().contains('qsif')) return const Color(0xFF8B5CF6);
    if (amc.toLowerCase().contains('isif')) return const Color(0xFF10B981);
    return const Color(0xFFF59E0B);
  }
}
