import 'package:flutter/cupertino.dart';
import '../models/song.dart';
import '../services/navidrome_service.dart';
import '../services/playback_manager.dart';

class RatingPage extends StatefulWidget {
  const RatingPage({
    super.key,
    required this.username,
    required this.password,
    required this.player,
  });

  final String username;
  final String password;
  final dynamic player;

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  late final NavidromeService service;
  late final PlaybackManager playbackManager;

  List<Song> songs = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    service = NavidromeService(
      baseUrl: 'https://musik.radio-endstation.de',
      username: widget.username,
      password: widget.password,
    );
    playbackManager = PlaybackManager(player: widget.player, service: service);
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    try {
      final playlists = await service.getPlaylists();
      final myPlaylist = playlists.firstWhere(
        (p) =>
            p.owner == widget.username &&
            !p.isPublic &&
            p.name.contains('Hausaufgaben'),
      );
      final allSongs = await service.getPlaylistSongs(myPlaylist.id);
      // Only include unrated songs
      final unrated = allSongs.where((s) => s.rating == 0).toList();
      setState(() {
        songs = unrated;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Fehler: ${e.toString()}';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    if (error != null) {
      return CupertinoPageScaffold(
        child: Center(
          child: Text(
            error!,
            style: const TextStyle(color: CupertinoColors.destructiveRed),
          ),
        ),
      );
    }
    if (songs.isEmpty) {
      return const CupertinoPageScaffold(
        child: Center(child: Text('Keine Lieder gefunden.')),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: const CupertinoNavigationBar(middle: Text('Bewertungen')),
      child: SafeArea(
        child: ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return GestureDetector(
              onTap:
                  () => playbackManager.playPlaylist(songs, startIndex: index),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CupertinoColors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        song.coverUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist,
                            style: const TextStyle(
                              color: CupertinoColors.systemRed,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // No rating stars displayed
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
