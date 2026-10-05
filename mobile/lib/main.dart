import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'core/config/api_config.dart';
import 'core/network/api_client.dart';
import 'features/auth/session.dart';
import 'features/funds/data/fund_repository.dart';
import 'features/funds/fund_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final api = ApiClient(ApiConfig.baseUrl);
    runApp(MultiProvider(providers: [
      Provider.value(value: api),
      Provider(create: (_) => FundRepository(api)),
      ChangeNotifierProvider(create: (_) => AdminSession(api, SecureCredentialStore(api.baseUrl))..restore()),
      ChangeNotifierProvider(create: (c) => FundController(c.read<FundRepository>())..load()),
    ], child: const SifApp()));
  } on FormatException catch (e) {
    runApp(MaterialApp(home: Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(e.message))))));
  }
}
