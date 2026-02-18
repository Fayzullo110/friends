import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final bool enableLogging;

  ApiClient({required this.baseUrl, this.enableLogging = false});

  void _log(String message) {
    if (!enableLogging) return;
    debugPrint(message);
  }

  String absolutizeUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '$baseUrl$url';
    return '$baseUrl/$url';
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<T> patchJson<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    final response = await patch(path, body: body);
    return _handleResponse(response, fromJson);
  }

  Future<void> patchNoContent(String path, {Map<String, dynamic>? body}) async {
    final response = await patch(path, body: body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Server error';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final m = decoded['message'];
          if (m != null && m.toString().trim().isNotEmpty) {
            message = m.toString();
          }
        }
      } catch (_) {
        final bodyText = response.body.trim();
        if (bodyText.isNotEmpty) {
          message = 'HTTP ${response.statusCode}: '
              '${bodyText.length > 120 ? bodyText.substring(0, 120) : bodyText}';
        } else {
          message = 'HTTP ${response.statusCode}';
        }
      }
      throw Exception(message);
    }
  }

  Future<void> _setToken(String? token) async {
    if (token == null) {
      await _storage.delete(key: 'jwt_token');
    } else {
      await _storage.write(key: 'jwt_token', value: token);
    }
  }

  Future<http.Response> post(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final token = await _getToken();
    _log('[API] POST $uri body: $body');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await http.post(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    _log('[API] POST $uri status: ${response.statusCode}');
    return response;
  }

  Future<http.Response> patch(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final token = await _getToken();
    _log('[API] PATCH $uri body: $body');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await http.patch(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    _log('[API] PATCH $uri status: ${response.statusCode}');
    return response;
  }

  Future<Map<String, dynamic>> uploadFile({
    required String path,
    required Uint8List bytes,
    required String filename,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final token = await _getToken();

    final request = http.MultipartRequest('POST', uri);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    _log('[API] UPLOAD $uri file: $filename (${bytes.length} bytes)');
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    _log('[API] UPLOAD $uri status: ${response.statusCode}');

    throwForNon2xx(response);
    final decoded = decodeBody(response);
    if (decoded is Map<String, dynamic>) {
      if (decoded['url'] is String) {
        decoded['url'] = absolutizeUrl(decoded['url'] as String);
      }
      return decoded;
    }
    throw Exception('Invalid response');
  }

  dynamic decodeBody(http.Response response) {
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  void throwForNon2xx(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    }
    if (response.statusCode == 403) {
      throw Exception('Forbidden');
    }

    Object? decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }
    }
    final message = (decoded is Map<String, dynamic>)
        ? (decoded['message'] ?? 'Server error')
        : (response.body.isNotEmpty ? response.body : 'Server error');
    throw Exception(message);
  }

  Future<http.Response> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final token = await _getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    _log('[API] DELETE $uri');
    final response = await http.delete(uri, headers: headers);
    _log('[API] DELETE $uri status: ${response.statusCode}');
    return response;
  }

  Future<http.Response> get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final token = await _getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    _log('[API] GET $uri');
    final response = await http.get(uri, headers: headers);
    _log('[API] GET $uri status: ${response.statusCode}');
    return response;
  }

  Future<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        throw Exception('Invalid response');
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return fromJson(json);
    } else {
      throwForNon2xx(response);
      throw Exception('Server error');
    }
  }

  Future<T> postJson<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    final response = await post(path, body: body);
    return _handleResponse(response, fromJson);
  }

  Future<void> postNoContent(String path, {Map<String, dynamic>? body}) async {
    final response = await post(path, body: body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Server error';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final m = decoded['message'];
          if (m != null && m.toString().trim().isNotEmpty) {
            message = m.toString();
          }
        }
      } catch (_) {
        final bodyText = response.body.trim();
        if (bodyText.isNotEmpty) {
          message = 'HTTP ${response.statusCode}: '
              '${bodyText.length > 120 ? bodyText.substring(0, 120) : bodyText}';
        } else {
          message = 'HTTP ${response.statusCode}';
        }
      }
      throw Exception(message);
    }
  }

  Future<void> deleteNoContent(String path) async {
    final response = await delete(path);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Server error';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final m = decoded['message'];
          if (m != null && m.toString().trim().isNotEmpty) {
            message = m.toString();
          }
        }
      } catch (_) {
        final bodyText = response.body.trim();
        if (bodyText.isNotEmpty) {
          message = 'HTTP ${response.statusCode}: '
              '${bodyText.length > 120 ? bodyText.substring(0, 120) : bodyText}';
        } else {
          message = 'HTTP ${response.statusCode}';
        }
      }
      throw Exception(message);
    }
  }

  Future<T> getJson<T>(
    String path,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    final response = await get(path);
    return _handleResponse(response, fromJson);
  }

  Future<List<dynamic>> getList(String path) async {
    final resp = await get(path);
    throwForNon2xx(resp);
    final decoded = decodeBody(resp);
    if (decoded is List) {
      return decoded;
    }
    return const <dynamic>[];
  }

  Future<List<Map<String, dynamic>>> getListOfMaps(String path) async {
    final resp = await get(path);
    throwForNon2xx(resp);
    final decoded = decodeBody(resp);
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
  }

  Future<bool> getBool(String path) async {
    final response = await get(path);
    throwForNon2xx(response);
    final decoded = decodeBody(response);
    if (decoded is bool) return decoded;
    if (decoded is String) return decoded.toLowerCase() == 'true';
    throw Exception('Invalid response');
  }

  Future<void> storeToken(String token) => _setToken(token);
  Future<void> clearToken() => _setToken(null);
}
