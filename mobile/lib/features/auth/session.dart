import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/api_client.dart';

abstract class CredentialStore {
  Future<String?> read();
  Future<void> save(String key);
  Future<void> clear();
}

class SecureCredentialStore implements CredentialStore {
  SecureCredentialStore(String server) : _key = 'admin:$server';
  final String _key;
  final _storage = const FlutterSecureStorage();
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> save(String key) => _storage.write(key: _key, value: key);
  @override
  Future<void> clear() => _storage.delete(key: _key);
}

class AdminSession extends ChangeNotifier {
  AdminSession(this.api, this.store) {
    api.onUnauthorized = () { logout(); };
  }
  final ApiClient api;
  final CredentialStore store;
  bool ready = false, busy = false, authenticated = false;
  String? error;

  Future<void> restore() async {
    try {
      final key = await store.read();
      if (key != null) await login(key, remember: false);
    } catch (_) {
      error = 'Stored administrator access could not be restored. Sign in again.';
    } finally {
      ready = true;
      notifyListeners();
    }
  }

  Future<void> login(String key, {bool remember = true}) async {
    if (busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      api.adminKey = key.trim();
      await api.get('/api/admin/ingestion-runs', admin: true);
      if (remember) await store.save(key.trim());
      authenticated = true;
    } catch (e) {
      api.adminKey = null;
      authenticated = false;
      error = e is ApiException ? e.message : 'Could not save administrator access securely.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    authenticated = false;
    api.adminKey = null;
    notifyListeners();
    try { await store.clear(); } catch (_) { error = 'Could not clear saved access. Please retry signing out.'; }
    notifyListeners();
  }
}
