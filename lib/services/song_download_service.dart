import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/song.dart';
import 'navidrome_service.dart';

class SongDownloadService {
  final NavidromeService _service;

  SongDownloadService(this._service);

  Future<String> downloadSong(Song song) async {
    final url = _service.uri('/rest/stream', {'id': song.id});
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to download song: ${response.reasonPhrase}');
    }

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/${song.id}.mp3';
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    return filePath;
  }
}
