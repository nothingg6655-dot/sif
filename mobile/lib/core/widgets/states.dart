import 'package:flutter/material.dart';
import '../network/api_client.dart';

class StatusView extends StatelessWidget {
  const StatusView(this.message, {super.key, this.onRetry, this.icon = Icons.info_outline});
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
      const SizedBox(height: 16), Text(message, textAlign: TextAlign.center),
      if (onRetry != null) Padding(padding: const EdgeInsets.only(top: 16),
        child: FilledButton.tonal(onPressed: onRetry, child: const Text('Retry'))),
    ])));
}

String errorMessage(Object? error) => error is ApiException ? error.message : 'Unable to load this data. Please try again.';
String amount(double? value, {int decimals = 2}) => value?.toStringAsFixed(decimals) ?? 'Unavailable';
String percent(double? value) => value == null ? 'Unavailable' : '${(value * 100).toStringAsFixed(2)}%';

class Fact extends StatelessWidget {
  const Fact(this.label, this.value, {super.key});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
      const SizedBox(width: 12), Expanded(child: SelectableText(value, textAlign: TextAlign.end)),
    ]));
}

class Section extends StatelessWidget {
  const Section(this.title, this.children, {super.key});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 12), ...children,
    ])));
}
