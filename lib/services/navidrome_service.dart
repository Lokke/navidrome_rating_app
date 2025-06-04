// Purpose: Provides methods to interact with the Navidrome API, including fetching playlists,
// songs, and metadata, as well as setting ratings.

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/playlist.dart';
import '../models/song.dart';

class NavidromeService {
  // Base URL of the Navidrome server.
  final String baseUrl;

  // Username for authentication.
  final String username;

  // Password for authentication.
  final String password;

  // Client name for API requests.
  final String client = 'NavidromeRatingApp';

  // API version for compatibility.
  final String apiVersion = '1.16.1';

  // Constructor to initialize the service with server details and credentials.
  NavidromeService({
    required this.baseUrl,
    required this.username,
    required this.password,
  });

  // Generates a URI for API requests.
  Uri uri(String endpoint, [Map<String, String>? extra]) {
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

  // Pings the server to check connectivity.
  Future<bool> ping() async {
    final response = await http.get(uri('/rest/ping'));
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final status = data['subsonic-response']['status'] as String?;
    return status == 'ok';
  }

  // Searches for songs based on a query.
  Future<List<Song>> searchSongs(String query) async {
    final response = await http.get(
      uri('/rest/search2', {'query': query, 'type': 'music'}),
    );
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final songsJson =
        data['subsonic-response']['searchResult2']['song'] as List<dynamic>;
    return songsJson.map((e) {
      final id = e['id'] as String;
      final title = e['title'] as String;
      final artist = e['artist'] as String;
      final coverArtId = e['coverArt']?.toString();
      final coverUrl =
          coverArtId != null
              ? uri('/rest/getCoverArt', {
                'id': coverArtId,
                'size': '500',
              }).toString()
              : '';
      return Song(
        id: id,
        title: title,
        artist: artist,
        coverUrl: coverUrl,
        mediaId: id,
        album: e['album'] as String?, // Populate album field
      );
    }).toList();
  }

  // Sets the rating for a song.
  Future<void> setRating(String id, int rating) async {
    await http.get(
      uri('/rest/setRating', {'id': id, 'rating': rating.toString()}),
    );
  }

  // Fetches all playlists.
  Future<List<Playlist>> getPlaylists() async {
    final response = await http.get(uri('/rest/getPlaylists'));
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final list =
        data['subsonic-response']['playlists']['playlist'] as List<dynamic>;
    return list
        .map(
          (e) => Playlist(
            id: e['id'] as String,
            name: e['name'] as String,
            isPublic: e['public'] as bool,
            owner: e['owner'] as String,
          ),
        )
        .toList();
  }

  // Fetches songs from a specific playlist.
  Future<List<Song>> getPlaylistSongs(String playlistId) async {
    final response = await http.get(
      uri('/rest/getPlaylist', {'id': playlistId}),
    );
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final sr = data['subsonic-response'] as Map<String, dynamic>?;
    if (sr == null)
      throw Exception('Invalid API response: no subsonic-response');
    dynamic plData =
        sr['playlist'] ??
        (sr['playlists'] as Map<String, dynamic>?)?['playlist'];
    if (plData == null)
      throw Exception('Invalid API response: no playlist object');
    if (plData is List) {
      plData = plData.firstWhere(
        (p) => p['id'] == playlistId,
        orElse: () => throw Exception('Playlist not found'),
      );
    }
    final plNode = plData as Map<String, dynamic>;
    dynamic entryNode =
        plNode['entry'] ??
        (plNode['entries'] as Map<String, dynamic>?)?['entry'];
    if (entryNode == null)
      throw Exception('Invalid API response: no entry field');
    List<dynamic> entries = entryNode is List ? entryNode : [entryNode];
    return entries.map((e) {
      final id = e['id'] as String;
      final title = e['title'] as String;
      final artist = e['artist'] as String;
      final coverArtId = e['coverArt']?.toString();
      final coverUrl =
          coverArtId != null
              ? uri('/rest/getCoverArt', {
                'id': coverArtId,
                'size': '500',
              }).toString()
              : '';
      final rating = (e['rating'] as int?) ?? 0;
      return Song(
        id: id,
        title: title,
        artist: artist,
        coverUrl: coverUrl,
        rating: rating,
        mediaId: id,
        album: e['album'] as String?, // Populate album field
      );
    }).toList();
  }

  // Fetches the rating for a specific song.
  Future<int> getRating(String id) async {
    try {
      final response = await http.get(uri('/rest/getSong', {'id': id}));
      if (response.statusCode != 200) {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data['subsonic-response'] == null ||
          data['subsonic-response']['song'] == null ||
          data['subsonic-response']['song']['userRating'] == null) {
        throw Exception('Invalid API response: ${response.body}');
      }
      return data['subsonic-response']['song']['userRating'] as int? ?? 0;
    } catch (e) {
      print('Error fetching rating: $e');
      return 0;
    }
  }

  // Fetches detailed metadata for a specific song.
  Future<Map<String, dynamic>> getSong(String songId) async {
    final response = await http.get(uri('/rest/getSong', {'id': songId}));
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data['subsonic-response'] == null ||
        data['subsonic-response']['song'] == null) {
      throw Exception('Invalid API response: ${response.body}');
    }
    return data['subsonic-response']['song'] as Map<String, dynamic>;
  }
}
