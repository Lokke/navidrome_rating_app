import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/song.dart';

class NavidromeService {
  final String baseUrl;
  final String username;
  final String password;
  final String client = 'NavidromeRatingApp';
  final String apiVersion = '1.16.1';

  NavidromeService({
    required this.baseUrl,
    required this.username,
    required this.password,
  });

  Uri uri(String endpoint, [Map<String, String>? extra]) {
    return _uri(endpoint, extra);
  }

  Uri _uri(String endpoint, [Map<String, String>? extra]) {
    final params = <String, String>{
      'u': username,
      'p': password,
      'v': apiVersion,
      'c': client,
      'f': 'json',
    };
    if (extra != null) params.addAll(extra);
    final path = endpoint.endsWith('.view') ? endpoint : endpoint + '.view';
    return Uri.parse('$baseUrl$path').replace(queryParameters: params);
  }

  Future<List<dynamic>> getPlaylists() async {
    try {
      final response = await http.get(uri('/rest/getPlaylists'));
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch playlists: ${response.statusCode}');
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data['subsonic-response']['status'] != 'ok') {
        throw Exception('API error: ${data['subsonic-response']['error']}');
      }
      return data['subsonic-response']['playlists']['playlist']
          as List<dynamic>;
    } catch (e) {
      print('Error in getPlaylists: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getPlaylistSongs(String playlistId) async {
    final response = await http.get(
      uri('/rest/getPlaylist', {'id': playlistId}),
    );
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return data['subsonic-response']['playlist']['entry'] as List<dynamic>;
  }

  Future<void> setRating(String songId, int rating) async {
    await http.get(uri('/rest/setRating', {'id': songId, 'rating': '$rating'}));
  }

  Future<int> getRating(String songId) async {
    final response = await http.get(uri('/rest/getSong', {'id': songId}));
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return data['subsonic-response']['song']['userRating'] as int? ?? 0;
  }

  Future<List<Song>> searchSongs(String query) async {
    final response = await http.get(uri('/rest/search3', {'query': query}));
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final songs =
        data['subsonic-response']['searchResult3']['song'] as List<dynamic>?;
    return songs?.map((json) => Song.fromJson(json)).toList() ?? [];
  }
}
