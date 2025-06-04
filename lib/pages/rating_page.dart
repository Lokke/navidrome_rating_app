import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
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
      setState(() {
        songs = allSongs; // Only fetch metadata, no downloading
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Fehler: ${e.toString()}';
        loading = false;
      });
    }
  }

  void _playSong(Song song) async {
    try {
      setState(() => loading = true); // Show loading indicator during download
      await playbackManager.playMedia(song.id); // Download and play the song
      setState(
        () => loading = false,
      ); // Hide loading indicator after playback starts
    } catch (e) {
      setState(() {
        error = 'Fehler beim Abspielen: ${e.toString()}';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return Scaffold(body: Center(child: Text(error!)));
    }
    if (songs.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Keine Lieder gefunden.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        // Heading removed per user request
      ),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.network(
                    song.coverUrl,
                    width: 300,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    song.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(song.artist, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  RatingBar.builder(
                    initialRating: song.rating.toDouble(),
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: false,
                    itemCount: 5,
                    itemSize: 32,
                    unratedColor: Colors.grey.shade600,
                    itemBuilder:
                        (context, _) => Icon(
                          Icons.star,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                    onRatingUpdate: (rating) async {
                      await service.setRating(song.id, rating.toInt());
                      setState(() {
                        song.rating = rating.toInt();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _playSong(song),
                    child: const Text('Play'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
