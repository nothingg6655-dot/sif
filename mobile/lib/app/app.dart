import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/funds/presentation/discover_screen.dart';
import '../features/funds/presentation/detail_screen.dart';
import '../features/compare/compare_screen.dart';
import '../features/performance/performance_screen.dart';
import '../features/tracker/tracker_screen.dart';
import '../features/admin/admin_screen.dart';
import '../features/calculator/cost_calculator.dart';
import '../features/funds/fund_controller.dart';
import '../core/widgets/states.dart';
import 'theme.dart';

class SifApp extends StatefulWidget {
  const SifApp({super.key});
  @override
  State<SifApp> createState() => _SifAppState();
}
class _SifAppState extends State<SifApp> {
  ThemeMode mode = ThemeMode.system;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SIF360', debugShowCheckedModeBanner: false,
    theme: appTheme(Brightness.light), darkTheme: appTheme(Brightness.dark), themeMode: mode,
    onGenerateRoute: (settings) {
      final parts = Uri.tryParse(settings.name ?? '/')?.pathSegments ?? [];
      final id = parts.length == 2 && parts[0] == 'fund' ? int.tryParse(parts[1]) : null;
      final Widget screen;
      if (id != null && id > 0) { screen = DetailScreen(id: id); }
      else if (settings.name == '/admin') { screen = const Scaffold(body: SafeArea(child: AdminScreen())); }
      else if (settings.name == '/calculator') { screen = const CostCalculator(); }
      else if (settings.name == '/') { screen = _Shell(onTheme: (v) => setState(() => mode = v)); }
      else { screen = Scaffold(appBar: AppBar(title: const Text('SIF360')), body: const StatusView('Page not found.')); }
      return MaterialPageRoute<void>(settings: settings, builder: (_) => screen);
    },
  );
}
class _Shell extends StatefulWidget {
  const _Shell({required this.onTheme});
  final ValueChanged<ThemeMode> onTheme;
  @override
  State<_Shell> createState() => _ShellState();
}
class _ShellState extends State<_Shell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final count = context.watch<FundController>().selected.length;
    return PopScope(canPop: index == 0, onPopInvokedWithResult: (didPop, result) {
      if (!didPop) setState(() => index = 0);
    }, child: Scaffold(
      appBar: AppBar(title: const Text('SIF360', style: TextStyle(fontWeight: FontWeight.w800)), actions: [
        IconButton(tooltip: 'Cost calculator', icon: const Icon(Icons.calculate_outlined), onPressed: () => Navigator.pushNamed(context, '/calculator')),
        PopupMenuButton<ThemeMode>(tooltip: 'Appearance', icon: const Icon(Icons.brightness_6_outlined),
          onSelected: widget.onTheme, itemBuilder: (_) => ThemeMode.values.map((v) => PopupMenuItem(value: v, child: Text(v.name))).toList()),
        IconButton(tooltip: 'Administrator', icon: const Icon(Icons.admin_panel_settings_outlined), onPressed: () => Navigator.pushNamed(context, '/admin')),
      ]),
      body: SafeArea(child: IndexedStack(index: index, children: [
        TickerMode(enabled: index == 0, child: const DiscoverScreen()),
        TickerMode(enabled: index == 1, child: const PerformanceScreen()),
        TickerMode(enabled: index == 2, child: const TrackerScreen()),
        TickerMode(enabled: index == 3, child: CompareScreen(active: index == 3)),
      ])),
      bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (i) => setState(() => index = i), destinations: [
        const NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Discover'),
        const NavigationDestination(icon: Icon(Icons.insights), label: 'Performance'),
        const NavigationDestination(icon: Icon(Icons.event_note), label: 'Tracker'),
        NavigationDestination(icon: Badge(isLabelVisible: count > 0, label: Text('$count'), child: const Icon(Icons.compare_arrows)), label: 'Compare'),
      ]),
    ));
  }
}
