import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/states.dart';
import '../auth/session.dart';
import 'import_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}
class _AdminScreenState extends State<AdminScreen> {
  final keyController = TextEditingController();
  final form = GlobalKey<FormState>();
  @override
  void dispose() { keyController.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final session = context.watch<AdminSession>();
    return Column(children: [
      AppBar(title: const Text('Administrator'), actions: [if (session.authenticated)
        TextButton(onPressed: session.logout, child: const Text('Sign out'))]),
      Expanded(child: !session.ready ? const Center(child: CircularProgressIndicator()) : session.authenticated
        ? const ImportScreen() : Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24),
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: Form(key: form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Icon(Icons.admin_panel_settings_outlined, size: 56), const SizedBox(height: 24),
            Text('Import fund data', style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 12),
            const Text('Enter your administrator key to manage data imports.'), const SizedBox(height: 24),
            TextFormField(controller: keyController, obscureText: true, enableSuggestions: false, autocorrect: false,
              decoration: const InputDecoration(labelText: 'Administrator key'), textInputAction: TextInputAction.done,
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter your administrator key.' : null,
              onFieldSubmitted: (_) => login(session)),
            if (session.error != null) StatusView(session.error!), const SizedBox(height: 16),
            FilledButton(onPressed: session.busy ? null : () => login(session), child: Text(session.busy ? 'Verifying…' : 'Continue')),
          ])))))),
    ]);
  }
  Future<void> login(AdminSession session) async {
    if (!form.currentState!.validate()) return;
    await session.login(keyController.text);
    if (session.authenticated) keyController.clear();
  }
}
