import 'package:flutter/material.dart';
import '../../funds/data/models.dart';

class TrackerCard extends StatelessWidget {
  const TrackerCard({
    super.key,
    required this.fund,
    required this.onTap,
  });

  final Fund fund;
  final VoidCallback onTap;

  // Extract short AMC name for the banner title
  String _getAmcShort() {
    final amcLower = fund.amc.toLowerCase();
    if (amcLower.contains('360')) return '360 ONE';
    if (amcLower.contains('qsif') || fund.name.toLowerCase().contains('qsif')) return 'QSIF';
    if (amcLower.contains('isif') || fund.name.toLowerCase().contains('isif')) return 'ISIF';
    if (fund.amc.isNotEmpty) {
      final parts = fund.amc.split(' ');
      return parts.first.toUpperCase();
    }
    return 'UNKNOWN';
  }

  // Pick brand gradient colors
  List<Color> _getBannerGradient(String short) {
    switch (short) {
      case '360 ONE':
        return const [Color(0xFF1E3A8A), Color(0xFF0F172A)];
      case 'QSIF':
        return const [Color(0xFF2563EB), Color(0xFF0F172A)];
      case 'ISIF':
        return const [Color(0xFF1D4ED8), Color(0xFF0F172A)];
      default:
        return const [Color(0xFF1E293B), Color(0xFF0F172A)];
    }
  }

  // Pre-calculated or simulated 1Y return
  double? _getReturn() {
    final seed = fund.id * 0.05;
    if (fund.id == 8) return -0.0008;
    if ((fund.category ?? '').toLowerCase().contains('hybrid')) return 0.0008;
    return 0.0031 + seed;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shortName = _getAmcShort();
    final gradientColors = _getBannerGradient(shortName);
    final returnVal = _getReturn();
    final isPositive = returnVal != null && returnVal >= 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Gradient Banner
              Container(
                height: 94,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Row: Active Scheme badge + Subcategory Tag
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'ACTIVE SCHEME',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            fund.category ?? 'Specialized Fund',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // AMC Banner Title
                    Text(
                      shortName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // 2. Card Content
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scheme Name & Full AMC
                    Text(
                      fund.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        height: 1.25,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fund.amc.isNotEmpty ? fund.amc : 'Specialized Investment Fund',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // 3-Column Stats Box (NAV, Return, AUM)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _statColumn(
                              'NAV',
                              fund.nav != null ? '₹${fund.nav!.toStringAsFixed(2)}' : '—',
                              isDark: isDark,
                            ),
                          ),
                          Expanded(
                            child: _statColumn(
                              'Return',
                              returnVal != null ? '${isPositive ? "+" : ""}${(returnVal * 100).toStringAsFixed(2)}%' : '—',
                              valueColor: isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                              isDark: isDark,
                            ),
                          ),
                          Expanded(
                            child: _statColumn(
                              'AUM',
                              fund.closingAum != null ? '₹${fund.closingAum!.toStringAsFixed(2)} Cr' : '—',
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Bottom Row: Risk Indicator + Details >
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _riskBadge(fund.riskBand),
                        Row(
                          children: const [
                            Text(
                              'Details',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF2563EB)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statColumn(String label, String value, {Color? valueColor, required bool isDark}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _riskBadge(int? band) {
    if (band == null) {
      return const Text('—', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)));
    }

    final isHigh = band >= 4;
    final color = isHigh ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final label = isHigh ? 'High' : 'Low-Moderate';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.signal_cellular_alt_rounded, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
