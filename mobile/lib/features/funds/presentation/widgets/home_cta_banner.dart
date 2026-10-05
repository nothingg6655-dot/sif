import 'package:flutter/material.dart';

class HomeCtaBanner extends StatelessWidget {
  const HomeCtaBanner({
    super.key,
    required this.onExplore,
    required this.onCompare,
  });

  final VoidCallback onExplore;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explore DynaSIF Investment Schemes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Access real-time DynaSIF scheme analytics, performance metrics, and portfolio insights powered directly by the DynaSIF API.',
            style: TextStyle(fontSize: 12, color: Color(0xFFDBEAFE), height: 1.4),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(
                onPressed: onExplore,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1D4ED8),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Explore Schemes', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
              ),
              OutlinedButton(
                onPressed: onCompare,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Compare Schemes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield, size: 18, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 8),
              Text(
                'Mutual Fund Guru',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Mr. Vinayak Bhosale · Premier Financial Consultant\nARN: 115193 · AMFI Registered Mutual Fund Distributor',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Specialized Investment Funds (SIFs) are subject to SEBI regulatory framework 2026. Mutual fund investments are subject to market risks, read all scheme related documents carefully before investing.',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '© 2026 Mutual Fund Guru · All rights reserved.',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
