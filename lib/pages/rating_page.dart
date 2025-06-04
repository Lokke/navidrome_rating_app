import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import '../services/navidrome_service.dart';
import '../models/song.dart';
import '../services/playback_manager.dart';

// Purpose: Allows users to rate songs from a playlist.
// Fetches unrated songs and manages playback.
// References:
// - `NavidromeService`: Fetches playlists and songs.
// - `PlaybackManager`: Handles playback logic.

class RatingPage extends StatefulWidget {
  const RatingPage({
    super.key,
    required this.username,
    required this.password,
    required this.player,
  });
  final String username;
  final String password;
  final AudioPlayer player;
  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  late final service = NavidromeService(
    baseUrl: 'https://musik.radio-endstation.de',
    username: widget.username,
    password: widget.password,
  );
  late final playbackManager = PlaybackManager(
    player: widget.player,
    service: service,
  );

  final PageController _pageController = PageController();
  List<Song> songs = [];
  int currentIndex = 0;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    widget.player.sequenceStateStream.listen((seqState) {
      if (!mounted) return;
      final idx = seqState?.currentIndex ?? 0;
      if (idx != currentIndex) {
        setState(() => currentIndex = idx);
        _pageController.animateToPage(
          idx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
        );
      }
    });
    _loadSongs();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
      final unrated = allSongs.where((s) => s.rating == 0).toList();
      songs = unrated.cast<Song>();
      setState(() {
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Fehler: ${e.toString()}';
        loading = false;
      });
    }
  }

  void _playSong(String mediaId) {
    playbackManager.playMedia(mediaId);
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (error != null) return Scaffold(body: Center(child: Text(error!)));
    if (songs.isEmpty)
      return const Scaffold(
        body: Center(child: Text('Keine unbewerteten Lieder gefunden.')),
      );
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        itemCount: songs.length,
        onPageChanged: (index) {
          setState(() => currentIndex = index);
          // Seek to the song but do not play it automatically
          widget.player.seek(Duration.zero, index: index);
        },
        itemBuilder: (context, idx) {
          final song = songs[idx];
          return Center(
            child: Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        if (widget.player.playing) {
                          widget.player.pause();
                        } else {
                          final url = service.uri('/rest/stream', {
                            'id': song.id,
                          });
                          debugPrint('Generated URL for playback: $url');
                          try {
                            final response = await http.head(url);
                            if (response.statusCode != 200) {
                              throw Exception(
                                'Invalid stream URL: ${response.statusCode}',
                              );
                            }
                            final audioSource = AudioSource.uri(
                              url,
                              tag: MediaItem(
                                id: song.id,
                                title: song.title,
                                artist: song.artist,
                                artUri: Uri.parse(song.coverUrl),
                              ),
                            );
                            await widget.player.setAudioSource(audioSource);
                            widget.player.play();
                          } catch (e) {
                            debugPrint('Error setting audio source: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to play song: ${e.toString()}',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: Image.network(
                        song.coverUrl,
                        width: 300,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
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
                      onPressed: () => _playSong(song.mediaId),
                      child: const Text('Play'),
                    ),
                    // Playback progress bar
                    StreamBuilder<Duration?>(
                      stream: widget.player.durationStream,
                      builder: (context, durSnap) {
                        final duration = durSnap.data ?? Duration.zero;
                        return StreamBuilder<Duration>(
                          stream: widget.player.positionStream,
                          builder: (context, posSnap) {
                            final position = posSnap.data ?? Duration.zero;
                            return Column(
                              children: [
                                // Interactive progress slider
                                Slider(
                                  min: 0,
                                  max:
                                      duration.inMilliseconds > 0
                                          ? duration.inMilliseconds.toDouble()
                                          : 1.0,
                                  value:
                                      position.inMilliseconds
                                          .clamp(0, duration.inMilliseconds)
                                          .toDouble(),
                                  activeColor:
                                      Theme.of(context).colorScheme.secondary,
                                  inactiveColor: Colors.grey.shade800,
                                  onChanged:
                                      (value) => widget.player.seek(
                                        Duration(milliseconds: value.toInt()),
                                      ),
                                ),
                                // Time labels
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      position.toString().split('.')[0],
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    Text(
                                      duration.toString().split('.')[0],
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    // Added buffering and playback progress indicator
                    StreamBuilder<Duration?>(
                      stream: widget.player.bufferedPositionStream,
                      builder: (context, bufferedSnap) {
                        final bufferedPosition =
                            bufferedSnap.data ?? Duration.zero;
                        return StreamBuilder<Duration>(
                          stream: widget.player.positionStream,
                          builder: (context, posSnap) {
                            final position = posSnap.data ?? Duration.zero;
                            final duration =
                                widget.player.duration ?? Duration.zero;
                            return Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.orange.shade800,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Stack(
                                children: [
                                  FractionallySizedBox(
                                    widthFactor:
                                        bufferedPosition.inMilliseconds /
                                        duration.inMilliseconds,
                                    child: Container(
                                      color: Colors.orange.shade400,
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor:
                                        position.inMilliseconds /
                                        duration.inMilliseconds,
                                    child: Container(color: Colors.white),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
