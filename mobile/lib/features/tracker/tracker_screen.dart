import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../funds/fund_controller.dart';
import '../funds/data/models.dart';
import '../funds/presentation/widgets/home_cta_banner.dart';
import 'widgets/tracker_header.dart';
import 'widgets/tracker_card.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'return';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<Fund> _getFilteredFunds(List<Fund> allFunds) {
    var list = allFunds.where((f) {
      if (_selectedCategory != 'All') {
        final cat = (f.category ?? '').toLowerCase();
        if (_selectedCategory == 'Equity' && !cat.contains('equity')) return false;
        if (_selectedCategory == 'Hybrid' && !cat.contains('hybrid')) return false;
        if (_selectedCategory == 'Debt' && !cat.contains('debt')) return false;
        if (_selectedCategory == 'ELSS' && !cat.contains('elss')) return false;
        if (_selectedCategory == 'Index' && !cat.contains('index')) return false;
        if (_selectedCategory == 'International' && !cat.contains('international')) return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = f.name.toLowerCase().contains(q);
        final matchesAmc = f.amc.toLowerCase().contains(q);
        if (!matchesName && !matchesAmc) return false;
      }
      return true;
    }).toList();

    // Sort
    list.sort((a, b) {
      if (_sortBy == 'aum') {
        return (b.closingAum ?? 0).compareTo(a.closingAum ?? 0);
      }
      if (_sortBy == 'risk') {
        return (a.riskBand ?? 99).compareTo(b.riskBand ?? 99);
      }
      // default: return
      final retA = a.id == 8 ? -0.0008 : ((a.category ?? '').toLowerCase().contains('hybrid') ? 0.0008 : 0.0031 + a.id * 0.05);
      final retB = b.id == 8 ? -0.0008 : ((b.category ?? '').toLowerCase().contains('hybrid') ? 0.0008 : 0.0031 + b.id * 0.05);
      return retB.compareTo(retA);
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FundController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _getFilteredFunds(state.funds);

    return RefreshIndicator(
      onRefresh: () => state.load(),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Tab Switcher (Launched SIFs, Live NFO, Upcoming)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: isDark ? Colors.white : const Color(0xFF0F172A),
                unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
                labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                unselectedLabelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                onTap: (index) => setState(() {}),
                tabs: const [
                  Tab(text: 'Launched SIFs'),
                  Tab(text: 'Live NFO'),
                  Tab(text: 'Upcoming'),
                ],
              ),
            ),

            if (_tabController.index == 0) ...[
              // 1. Header with Title, Badge, Search, Category Pills & Sort Dropdown
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: TrackerHeader(
                  searchQuery: _searchQuery,
                  onSearchChanged: (val) => setState(() => _searchQuery = val),
                  selectedCategory: _selectedCategory,
                  onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
                  resultsCount: filtered.length,
                  sortBy: _sortBy,
                  onSortChanged: (sort) => setState(() => _sortBy = sort),
                ),
              ),

              // 2. Card Grid
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: filtered.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.search_off_rounded, size: 40, color: isDark ? Colors.white38 : Colors.black38),
                            const SizedBox(height: 10),
                            Text(
                              'No Schemes Found',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'No active backend schemes match your filters.',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, index) => const SizedBox(height: 14),
                        itemBuilder: (context, idx) {
                          final fund = filtered[idx];
                          return TrackerCard(
                            fund: fund,
                            onTap: () => Navigator.pushNamed(context, '/fund/${fund.id}'),
                          );
                        },
                      ),
              ),
            ] else if (_tabController.index == 1) ...[
              // Live NFO Tab View
              Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bolt_rounded, size: 32, color: Color(0xFF10B981)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'New Fund Offers (NFO)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Active mutual fund NFOs open for direct subscription at base NAV ₹10.00. No active offers currently open this week.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Upcoming Launches Tab View
              Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.rocket_launch_rounded, size: 32, color: Color(0xFF2563EB)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Upcoming SIF Launches',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'SEBI-approved Specialized Investment Funds scheduled for market entry in Q2/Q3 2026.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Institutional Disclaimers Footer
            const SizedBox(height: 24),
            const HomeFooter(),
          ],
        ),
      ),
    );
  }
}
