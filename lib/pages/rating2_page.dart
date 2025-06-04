/*
 * File: rating2_page.dart
 * ----------------------
 * Alternative rating page (Rating2Page) for songs in the "Hausaufgaben" playlist.
 * - Fetches all songs from the user's private homework playlist.
 * - Allows playing each track and setting ratings via RatingBar.
 * - Uses NavidromeService for API calls and PlaybackManager for playback control.
 */

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/song.dart';
import '../services/navidrome_service.dart';
import '../services/playback_manager.dart';

class Rating2Page extends StatefulWidget {
  const Rating2Page({
    super.key,
    required this.username,
    required this.password,
    required this.player,
  });

  final String username;
  final String password;
  final dynamic player;

  @override
  State<Rating2Page> createState() => _Rating2PageState();
}

class _Rating2PageState extends State<Rating2Page> {
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
        songs = allSongs;
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
      await playbackManager.playMedia(song.id);
    } catch (e) {
      setState(() {
        error = 'Fehler beim Abspielen: ${e.toString()}';
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
      appBar: AppBar(title: const Text('Hausaufgaben Playlist - Bewertung')),
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
