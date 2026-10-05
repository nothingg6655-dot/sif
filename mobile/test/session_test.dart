import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sif_mobile/core/network/api_client.dart';
import 'package:sif_mobile/features/auth/session.dart';

class MemoryCredentials implements CredentialStore {
  String? key;
  @override
  Future<String?> read() async => key;
  @override
  Future<void> save(String value) async => key = value;
  @override
  Future<void> clear() async => key = null;
}
void main() {
  test('Session verifies, persists, restores, and clears admin credentials', () async {
    final storage = MemoryCredentials();
    final api = ApiClient('http://localhost', client: MockClient((r) async => http.Response('{}', r.headers['x-admin-key'] == 'valid' ? 200 : 401)));
    final session = AdminSession(api, storage);
    await session.restore();
    expect(session.ready, isTrue);
    expect(session.authenticated, isFalse);
    await session.login('invalid');
    expect(session.authenticated, isFalse);
    expect(storage.key, isNull);
    await session.login('valid');
    expect(session.authenticated, isTrue);
    expect(storage.key, 'valid');
    final restored = AdminSession(api, storage);
    await restored.restore();
    expect(restored.authenticated, isTrue);
    await restored.logout();
    expect(restored.authenticated, isFalse);
    expect(api.adminKey, isNull);
    expect(storage.key, isNull);
    session.dispose(); restored.dispose(); api.close();
  });
}
