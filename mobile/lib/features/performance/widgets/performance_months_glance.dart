import 'package:flutter/material.dart';

class PerformanceMonthsGlance extends StatelessWidget {
  const PerformanceMonthsGlance({super.key});

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
            'Months at a Glance (2026 YTD)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Aggregate monthly win/loss distribution across DynaSIF schemes.',
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // 2x2 Grid of Monthly Highlights
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.25,
            children: [
              _metricBox(
                label: 'BEST MONTH',
                value: '+13.41%',
                subtext: 'July 2026',
                valueColor: const Color(0xFF15803D),
                bg: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5),
                border: const Color(0xFFA7F3D0),
                isDark: isDark,
              ),
              _metricBox(
                label: 'WORST MONTH',
                value: '-4.26%',
                subtext: 'May 2026',
                valueColor: const Color(0xFFDC2626),
                bg: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : const Color(0xFFFEF2F2),
                border: const Color(0xFFFECACA),
                isDark: isDark,
              ),
              _metricBox(
                label: 'POSITIVE MONTHS %',
                value: '69.6%',
                subtext: '48 of 69 Months',
                valueColor: isDark ? Colors.white : const Color(0xFF0F172A),
                bg: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
                border: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                isDark: isDark,
              ),
              _metricBox(
                label: 'AVERAGE MONTHLY CAGR',
                value: '+1.14%',
                subtext: 'Consistent Trajectory',
                valueColor: const Color(0xFF2563EB),
                bg: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
                border: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricBox({
    required String label,
    required String value,
    required String subtext,
    required Color valueColor,
    required Color bg,
    required Color border,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 9.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
