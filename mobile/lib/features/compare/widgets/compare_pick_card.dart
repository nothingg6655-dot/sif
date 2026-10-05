import 'package:flutter/material.dart';
import '../../funds/data/models.dart';

class ComparePickCard extends StatelessWidget {
  const ComparePickCard({
    super.key,
    required this.fund,
    required this.selected,
    required this.onToggle,
  });

  final Fund fund;
  final bool selected;
  final VoidCallback onToggle;

  String _getAmcCode() {
    final lower = fund.amc.toLowerCase();
    if (lower.contains('360')) return '360';
    if (lower.contains('qsif') || fund.name.toLowerCase().contains('qsif')) return 'QSI';
    if (lower.contains('isif') || fund.name.toLowerCase().contains('isif')) return 'ISI';
    if (fund.amc.isNotEmpty) {
      final clean = fund.amc.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      return clean.length >= 3 ? clean.substring(0, 3).toUpperCase() : 'UNK';
    }
    return 'UNK';
  }

  Color _getAmcColor(String code) {
    switch (code) {
      case '360':
        return const Color(0xFF2563EB);
      case 'QSI':
        return const Color(0xFF2563EB);
      case 'ISI':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF2563EB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final code = _getAmcCode();
    final amcCircleColor = _getAmcColor(code);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selected
              ? const Color(0xFF2563EB)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
          width: selected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Top Strategy Tag
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                (fund.category ?? 'DYNASIF').toUpperCase(),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2563EB),
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // AMC Avatar Circle
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: amcCircleColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: amcCircleColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              code,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Subtitle
          const Text(
            'DynaSIF Registered Scheme',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),

          // Scheme Name
          Text(
            fund.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),

          // AMC Name
          Text(
            fund.amc.isNotEmpty ? fund.amc : 'DynaSIF Asset Management',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // Risk Meter
          _riskMeter(fund.riskBand),
          const SizedBox(height: 14),

          // + Compare Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onToggle,
              style: FilledButton.styleFrom(
                backgroundColor: selected
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected ? Icons.check_circle_rounded : Icons.add_rounded,
                    size: 15,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    selected ? 'Selected' : 'Compare',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _riskMeter(int? band) {
    if (band == null) {
      return const Text('—', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)));
    }

    final isHigh = band >= 4;
    final color = isHigh ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final label = isHigh ? 'High' : 'Low-Moderate';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.signal_cellular_alt_rounded, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
