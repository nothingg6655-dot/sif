import 'package:flutter/material.dart';
import '../../funds/data/models.dart';

class CategoryDeepDiveItem {
  final String code;
  final String title;
  final String subCategory;
  final String avg1Y;
  final String avg3Y;
  final String aum;

  const CategoryDeepDiveItem({
    required this.code,
    required this.title,
    required this.subCategory,
    required this.avg1Y,
    required this.avg3Y,
    required this.aum,
  });
}

class PerformanceCategoryDeepDives extends StatefulWidget {
  const PerformanceCategoryDeepDives({
    super.key,
    required this.funds,
    required this.onSelectFund,
  });

  final List<Fund> funds;
  final ValueChanged<int> onSelectFund;

  @override
  State<PerformanceCategoryDeepDives> createState() => _PerformanceCategoryDeepDivesState();
}

class _PerformanceCategoryDeepDivesState extends State<PerformanceCategoryDeepDives> {
  String _expandedCode = 'EQU';

  final List<CategoryDeepDiveItem> _categories = const [
    CategoryDeepDiveItem(
      code: 'EQU',
      title: 'Equity Category',
      subCategory: 'Equity',
      avg1Y: '+0.18%',
      avg3Y: '+0.12%',
      aum: '₹14,250 Cr',
    ),
    CategoryDeepDiveItem(
      code: 'AAV',
      title: 'Active Asset Allocator Long-Short Fund Category',
      subCategory: 'Active Asset Allocator',
      avg1Y: '+0.10%',
      avg3Y: '+0.08%',
      aum: '₹8,675 Cr',
    ),
    CategoryDeepDiveItem(
      code: 'HYB',
      title: 'Hybrid Category',
      subCategory: 'Hybrid',
      avg1Y: '+0.10%',
      avg3Y: '+0.08%',
      aum: '₹7,820 Cr',
    ),
    CategoryDeepDiveItem(
      code: 'HEU',
      title: 'Equity Ex-Top 100 Long-Short Fund Category',
      subCategory: 'Equity Ex-Top 100',
      avg1Y: '+0.12%',
      avg3Y: '+0.09%',
      aum: '₹5,310 Cr',
    ),
    CategoryDeepDiveItem(
      code: 'DEU',
      title: 'Equity Long-Short Fund Category',
      subCategory: 'Equity Long-Short',
      avg1Y: '+0.06%',
      avg3Y: '+0.05%',
      aum: '₹3,122 Cr',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category Deep Dives',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Expand category for detailed analysis',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categories.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final cat = _categories[idx];
              final isExpanded = _expandedCode == cat.code;
              final matchingFunds = widget.funds.where((f) {
                final c = (f.category ?? '').toLowerCase();
                return c.contains(cat.subCategory.toLowerCase()) ||
                    (cat.subCategory == 'Equity' && c.contains('equity'));
              }).toList();

              return _accordionCard(context, cat, isExpanded, matchingFunds, isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _accordionCard(
    BuildContext context,
    CategoryDeepDiveItem cat,
    bool isExpanded,
    List<Fund> matchingFunds,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpanded
              ? const Color(0xFF2563EB).withValues(alpha: 0.5)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Column(
        children: [
          // Header Trigger Row
          InkWell(
            onTap: () {
              setState(() {
                _expandedCode = isExpanded ? '' : cat.code;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Code Avatar (EQU, AAV, HYB, etc.)
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cat.code,
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Category Title & Schemes Tracked
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.title,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${matchingFunds.isNotEmpty ? matchingFunds.length : 1} Schemes Tracked · Total AUM: ${cat.aum}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Return Badges
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Avg 1Y: ', style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                          Text(cat.avg1Y, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF15803D))),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Avg 3Y: ', style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                          Text(cat.avg3Y, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF15803D))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),

                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF2563EB),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OPERATIONAL SCHEMES IN THIS STRATEGY',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF2563EB), letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),

                  if (matchingFunds.isEmpty)
                    _schemeItem(
                      context,
                      name: widget.funds.isNotEmpty ? widget.funds.first.name : 'DynaSIF Active Asset Allocator Fund',
                      amc: widget.funds.isNotEmpty ? widget.funds.first.amc : '360 ONE Asset Management',
                      nav: '₹11.25',
                      ret1Y: cat.avg1Y,
                      fundId: widget.funds.isNotEmpty ? widget.funds.first.id : 1,
                      isDark: isDark,
                    )
                  else
                    ...matchingFunds.map((f) => _schemeItem(
                          context,
                          name: f.name,
                          amc: f.amc,
                          nav: f.nav != null ? '₹${f.nav!.toStringAsFixed(2)}' : '₹10.50',
                          ret1Y: cat.avg1Y,
                          fundId: f.id,
                          isDark: isDark,
                        )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _schemeItem(
    BuildContext context, {
    required String name,
    required String amc,
    required String nav,
    required String ret1Y,
    required int fundId,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$amc · NAV: $nav',
                  style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ret1Y,
                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF166534)),
                ),
              ),
              const SizedBox(width: 6),
              TextButton(
                onPressed: () => widget.onSelectFund(fundId),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Factsheet', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
