import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../fund_controller.dart';
import 'widgets/home_ticker.dart';
import 'widgets/home_hero_banner.dart';
import 'widgets/home_performance_comparison.dart';
import 'widgets/home_performance_table.dart';
import 'widgets/home_monthly_heatmap.dart';
import 'widgets/home_strategy_breakdown.dart';
import 'widgets/home_marketplace.dart';
import 'widgets/home_investment_options.dart';
import 'widgets/home_ideal_fund.dart';
import 'widgets/home_cta_banner.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _marketplaceKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToMarketplace() {
    if (_marketplaceKey.currentContext != null) {
      Scrollable.ensureVisible(
        _marketplaceKey.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showInvestModal(BuildContext context, String fundName) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    bool submitted = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Container(
            margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('INVESTMENT PORTAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                          const SizedBox(height: 2),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 260),
                            child: Text(
                              'Invest in $fundName',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (submitted) ...[
                    const SizedBox(height: 16),
                    const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 54),
                    const SizedBox(height: 12),
                    const Text('Inquiry Received!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
                    const SizedBox(height: 6),
                    const Text('Our financial advisory team will contact you shortly.', style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
                  ] else ...[
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Mobile Number', prefixIcon: Icon(Icons.phone_outlined)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                          setModalState(() => submitted = true);
                        }
                      },
                      child: const Text('Submit Investment Inquiry', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FundController>();

    return RefreshIndicator(
      onRefresh: () => state.load(),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // 1. Moving Top Market Ticker Banner
          const HomeMarketTicker(),

          // 2. Hero Section matching SIF360 card layout
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: HomeHeroBanner(
              totalFunds: state.funds.length,
              onExplore: _scrollToMarketplace,
              onPerformance: () => Navigator.pushNamed(context, '/'),
            ),
          ),

          // 3. Performance Comparison & Rolling Returns Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: HomePerformanceComparison(
              funds: state.funds,
              onSelectFund: (id) => Navigator.pushNamed(context, '/fund/$id'),
            ),
          ),

          // 4. Performance Analysis of SIFs Table (Dark Midnight Navy Card)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: HomePerformanceTable(
              funds: state.funds,
              onSelectFund: (id) => Navigator.pushNamed(context, '/fund/$id'),
            ),
          ),

          // 5. Monthly Returns Heatmap
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: HomeMonthlyHeatmap(
              funds: state.funds,
              onSelectFund: (id) => Navigator.pushNamed(context, '/fund/$id'),
            ),
          ),

          // 6. Portfolio Analysis & Asset Strategy Breakdown
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: HomeStrategyBreakdown(funds: state.funds),
          ),

          // 7. Active Mutual Funds Marketplace (Table / Card Screener)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: KeyedSubtree(
              key: _marketplaceKey,
              child: HomeMarketplace(
                funds: state.funds,
                onSelectFund: (id) => Navigator.pushNamed(context, '/fund/$id'),
                onInvestNow: (name) => _showInvestModal(context, name),
              ),
            ),
          ),

          // 8. Investment Options Comparison (Direct Growth vs Regular Growth vs IDCW)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: HomeInvestmentOptions(),
          ),

          // 9. Find Your Ideal Fund Interactive Widget
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: HomeIdealFund(
              funds: state.funds,
              onSelectFund: (id) => Navigator.pushNamed(context, '/fund/$id'),
            ),
          ),

          // 10. Booking / CTA Card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: HomeCtaBanner(
              onExplore: _scrollToMarketplace,
              onCompare: () => Navigator.pushNamed(context, '/'),
            ),
          ),

          // 11. Institutional Disclaimers Footer
          const HomeFooter(),
        ],
        ),
      ),
    );
  }
}
