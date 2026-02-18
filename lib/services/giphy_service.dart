import 'dart:convert';

import 'package:http/http.dart' as http;

class GiphyGif {
  final String id;
  final String previewUrl;
  final String originalUrl;

  GiphyGif({
    required this.id,
    required this.previewUrl,
    required this.originalUrl,
  });
}

class GiphyService {
  GiphyService._();

  static final GiphyService instance = GiphyService._();

  // TODO: consider moving this to a safer config for production.
  static const String _apiKey = String.fromEnvironment('GIPHY_API_KEY');

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  static const String _baseUrl = 'https://api.giphy.com/v1/gifs';

  Future<List<GiphyGif>> trending({int limit = 24}) async {
    if (!isConfigured) {
      throw StateError('Missing GIPHY_API_KEY');
    }
    final uri = Uri.parse(
      '$_baseUrl/trending?api_key=$_apiKey&limit=$limit&rating=g',
    );
    return _fetch(uri);
  }

  Future<List<GiphyGif>> search(String query, {int limit = 24}) async {
    if (!isConfigured) {
      throw StateError('Missing GIPHY_API_KEY');
    }
    final q = query.trim();
    if (q.isEmpty) {
      return trending(limit: limit);
    }
    final uri = Uri.parse(
      '$_baseUrl/search?api_key=$_apiKey&q=${Uri.encodeQueryComponent(q)}&limit=$limit&rating=g',
    );
    return _fetch(uri);
  }

  Future<List<GiphyGif>> _fetch(Uri uri) async {
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      final body = resp.body;
      final snippet = body.length > 300 ? body.substring(0, 300) : body;
      throw Exception('Giphy request failed (${resp.statusCode}): $snippet');
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final list = json['data'] as List<dynamic>? ?? [];
    return list.map((item) {
      final m = item as Map<String, dynamic>;
      final images = m['images'] as Map<String, dynamic>? ?? {};
      final preview = (images['fixed_width_small'] ?? images['fixed_width']
          ?? images['downsized_medium'] ?? images['original']) as Map<String, dynamic>;
      final original = (images['original'] ?? images['downsized']) as Map<String, dynamic>;
      return GiphyGif(
        id: m['id'] as String? ?? '',
        previewUrl: preview['url'] as String? ?? '',
        originalUrl: original['url'] as String? ?? '',
      );
    }).where((g) => g.previewUrl.isNotEmpty && g.originalUrl.isNotEmpty).toList();
  }
}
