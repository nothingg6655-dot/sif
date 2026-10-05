import 'package:flutter/material.dart';

class HomeMarketTicker extends StatelessWidget {
  const HomeMarketTicker({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF4338CA)],
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.workspace_premium, color: Color(0xFFFDE68A), size: 14),
                  SizedBox(width: 5),
                  Text(
                    'Mr. Vinayak Bhosale · ARN: 115193',
                    style: TextStyle(color: Color(0xFFFEF3C7), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            _dot(),
            _pill('NIFTY 50', '24,850.40', '+0.35%', true),
            _dot(),
            _pill('SENSEX', '81,420.10', '+0.41%', true),
            _dot(),
            _sifPill('Groww SIF Equity', '₹10.58', '+0.42%'),
            _dot(),
            _sifPill('DSP SIF Hybrid', '₹10.65', '+0.78%'),
            _dot(),
            _sifPill('Franklin SIF Debt', '₹11.24', '+1.05%'),
            _dot(),
            const Row(
              children: [
                Icon(Icons.shield_outlined, color: Colors.white70, size: 13),
                SizedBox(width: 4),
                Text(
                  'Total SIF AUM: ₹740.05 Cr across 8 Schemes',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _dot() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 10),
    child: Text('•', style: TextStyle(color: Colors.white54, fontSize: 14)),
  );

  static Widget _pill(String label, String value, String delta, bool positive) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
        const SizedBox(width: 4),
        Text(
          delta,
          style: TextStyle(
            color: positive ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static Widget _sifPill(String name, String nav, String ret) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Text(nav, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(width: 4),
          Text(ret, style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
