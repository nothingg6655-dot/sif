import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

typedef Json = Map<String, Object?>;
Json object(Object? value) => Map<String, Object?>.from(value as Map);
List<Json> objects(Object? value) => (value as List? ?? []).map(object).toList();
double? number(Object? value) => value == null ? null : double.tryParse('$value');

class ApiException implements Exception {
  const ApiException(this.message, {this.status});
  final String message;
  final int? status;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this.baseUrl, {http.Client? client, this.timeout = const Duration(seconds: 20)})
      : _client = client ?? http.Client();
  final String baseUrl;
  final http.Client _client;
  final Duration timeout;
  String? adminKey;
  VoidCallback? onUnauthorized;

  Future<Json> get(String path, {Map<String, String>? query, bool admin = false}) =>
      request('GET', path, query: query, admin: admin);
  Future<Json> post(String path, {Object? body, bool admin = false}) =>
      request('POST', path, body: body, admin: admin);

  Future<Json> request(String method, String path, {Object? body,
      Map<String, String>? query, bool admin = false}) {
    final request = http.Request(method, Uri.parse('$baseUrl$path').replace(queryParameters: query));
    request.headers['Content-Type'] = 'application/json';
    if (body != null) request.body = jsonEncode(body);
    return _send(request, admin: admin);
  }

  Future<Json> upload(String path, List<int> bytes, String name) {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: name));
    return _send(request, admin: true);
  }

  Future<Json> _send(http.BaseRequest request, {required bool admin}) async {
    request.headers['Accept'] = 'application/json';
    if (admin && adminKey != null) request.headers['x-admin-key'] = adminKey!;
    try {
      final response = await (() async => http.Response.fromStream(await _client.send(request)))().timeout(timeout);
      if (kDebugMode) debugPrint('${request.method} ${request.url.path}: ${response.statusCode}');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (admin && response.statusCode == 401) onUnauthorized?.call();
        final message = switch (response.statusCode) {
          400 || 422 => 'Please check the submitted values and try again.',
          401 => 'Administrator access expired or the key is incorrect.',
          403 => 'You do not have permission for this action.',
          404 => 'The requested data could not be found.',
          409 => 'This conflicts with existing data. Refresh and try again.',
          413 => 'The upload is too large.',
          429 => 'Too many requests. Please try again shortly.',
          _ => 'The server could not complete this request. Please try again.',
        };
        throw ApiException(message, status: response.statusCode);
      }
      return response.body.isEmpty ? {} : object(jsonDecode(response.body));
    } on TimeoutException {
      throw const ApiException('The request timed out. Check your connection and retry.');
    } on http.ClientException {
      throw const ApiException('Cannot reach the server. Check Wi-Fi and the API address.');
    } on FormatException {
      throw const ApiException('The server returned an unreadable response.');
    } on TypeError {
      throw const ApiException('The server response has an unexpected format.');
    }
  }

  void close() => _client.close();
}
