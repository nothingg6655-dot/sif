import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../funds/fund_controller.dart';
import '../funds/presentation/widgets/home_cta_banner.dart';
import 'widgets/performance_header.dart';
import 'widgets/performance_category_winners.dart';
import 'widgets/performance_trailing_matrix.dart';
import 'widgets/performance_months_glance.dart';
import 'widgets/performance_category_deep_dives.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateToFund(int id) {
    Navigator.pushNamed(context, '/fund/$id');
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
            // 1. Live Market Data Header & Performance Highlights
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: PerformanceHeader(
                funds: state.funds,
                onSelectFund: _navigateToFund,
              ),
            ),

            // 2. Category Winners Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: PerformanceCategoryWinners(
                funds: state.funds,
                onSelectFund: _navigateToFund,
              ),
            ),

            // 3. SIF Trailing Returns Matrix
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: PerformanceTrailingMatrix(
                funds: state.funds,
                onSelectFund: _navigateToFund,
              ),
            ),

            // 4. Months at a Glance (2026 YTD)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: PerformanceMonthsGlance(),
            ),

            // 5. Category Deep Dives
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: PerformanceCategoryDeepDives(
                funds: state.funds,
                onSelectFund: _navigateToFund,
              ),
            ),

            // 6. Institutional Disclaimers Footer
            const SizedBox(height: 24),
            const HomeFooter(),
          ],
        ),
      ),
    );
  }
}
