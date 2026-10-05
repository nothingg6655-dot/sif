import 'package:flutter/material.dart';

class HomeInvestmentOptions extends StatelessWidget {
  const HomeInvestmentOptions({super.key});

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
          Text(
            'Investment Options Comparison',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Understand differences between Direct Growth, Regular Growth, and IDCW plans',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // Cards for each plan type
          _planComparisonCard(
            title: 'Direct Growth',
            badge: 'RECOMMENDED',
            badgeColor: const Color(0xFF10B981),
            expense: 'Lower (0.5% - 1.2% less expense ratio)',
            intermediary: 'No intermediary (Direct with AMC)',
            suitability: 'High (Maximum wealth compounding)',
            tax: 'Capital gains on redemption (12.5% LTCG / 20% STCG)',
            isDark: isDark,
            isHighlighted: true,
          ),
          const SizedBox(height: 10),
          _planComparisonCard(
            title: 'Regular Growth',
            badge: 'BROKER-ASSISTED',
            badgeColor: const Color(0xFF64748B),
            expense: 'Higher (Includes recurring distributor commissions)',
            intermediary: 'Yes (Bank broker or agent ARN)',
            suitability: 'Medium compounding efficiency',
            tax: 'Capital gains on redemption',
            isDark: isDark,
            isHighlighted: false,
          ),
          const SizedBox(height: 10),
          _planComparisonCard(
            title: 'IDCW (Dividend Payout)',
            badge: 'REGULAR INCOME',
            badgeColor: const Color(0xFFF59E0B),
            expense: 'Varies based on plan class',
            intermediary: 'Direct or Distributor',
            suitability: 'Medium (Suited for cash flow needs)',
            tax: 'Dividend taxed at investor slab rate + TDS',
            isDark: isDark,
            isHighlighted: false,
          ),
        ],
      ),
    );
  }

  static Widget _planComparisonCard({
    required String title,
    required String badge,
    required Color badgeColor,
    required String expense,
    required String intermediary,
    required String suitability,
    required String tax,
    required bool isDark,
    required bool isHighlighted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isHighlighted
            ? (isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.25) : const Color(0xFFEFF6FF))
            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHighlighted
              ? const Color(0xFF3B82F6)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isHighlighted ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: badgeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _detailRow('Expense Ratio:', expense, isGood: isHighlighted),
          _detailRow('Intermediary:', intermediary),
          _detailRow('Suitability:', suitability),
          _detailRow('Taxation:', tax),
        ],
      ),
    );
  }

  static Widget _detailRow(String label, String value, {bool isGood = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isGood ? const Color(0xFF16A34A) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
