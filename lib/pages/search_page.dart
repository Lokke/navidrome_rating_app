import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import '../services/navidrome_service.dart';
import '../widgets/song_list_tile.dart';
import '../models/song.dart';

class SearchPage extends StatefulWidget {
  final NavidromeService service;
  final AudioPlayer player;
  const SearchPage({required this.service, required this.player, super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _query = '';
  List<Song> _results = [];
  bool _loading = false;

  Future<void> _search() async {
    if (_query.isEmpty) return;
    setState(() => _loading = true);
    final results = await widget.service.searchSongs(_query);
    for (var song in results) {
      final rating = await widget.service.getRating(song.id);
      song.rating = rating;
    }
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Suchbegriff',
                prefixIcon: Icon(Icons.search),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (v) => _query = v,
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 8),
            _loading
                ? const CircularProgressIndicator()
                : Expanded(
                  child: ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (c, i) {
                      final song = _results[i];
                      return SongListTile(
                        song: song,
                        onTap: () async {
                          final audioSource = AudioSource.uri(
                            widget.service.uri('/rest/stream', {'id': song.id}),
                            tag: MediaItem(
                              id: song.id,
                              title: song.title,
                              artist: song.artist,
                              artUri: Uri.parse(song.coverUrl),
                            ),
                          );
                          await widget.player.setAudioSource(audioSource);
                          widget.player.play();

                          // Log the song being played
                          debugPrint(
                            "SearchPage: Now playing - Title: ${song.title}, Artist: ${song.artist}, Cover URL: ${song.coverUrl}",
                          );
                        },
                      );
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
