import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/navidrome_service.dart';
import '../widgets/song_card.dart';
import '../models/song.dart';

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
      await _initAudio();
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Fehler: ${e.toString()}';
        loading = false;
      });
    }
  }

  Future<void> _initAudio() async {
    final initialCount = songs.length >= 1 ? 1 : songs.length;
    // Update AudioSource initialization to include tags
    final initialSources =
        songs.take(initialCount).map((song) {
          final url = service.uri('/rest/stream', {'id': song.id});
          debugPrint(
            'RatingPage - Adding song to playlist: ${song.title}, ${song.artist}, ${song.coverUrl}',
          );
          return AudioSource.uri(
            url,
            tag: MediaItem(
              id: song.id,
              title: song.title,
              artist: song.artist,
              artUri: Uri.parse(song.coverUrl),
            ),
          );
        }).toList();
    final playlistSource = ConcatenatingAudioSource(children: initialSources);
    await widget.player.setAudioSource(playlistSource);
    widget.player.currentIndexStream.listen((idx) async {
      if (idx == null) return;
      final totalBuffered =
          (widget.player.audioSource as ConcatenatingAudioSource).length;
      if (idx + 1 >= totalBuffered && totalBuffered < songs.length) {
        final nextSong = songs[totalBuffered];
        final nextSource = AudioSource.uri(
          service.uri('/rest/stream', {'id': nextSong.id}),
          tag: MediaItem(
            id: nextSong.id,
            title: nextSong.title,
            artist: nextSong.artist,
            artUri: Uri.parse(nextSong.coverUrl),
          ),
        );
        await (widget.player.audioSource as ConcatenatingAudioSource).add(
          nextSource,
        );
      }

      // Log the currently playing song
      final currentSong = songs[idx];
      debugPrint(
        "RatingPage: Now playing - Title: ${currentSong.title}, Artist: ${currentSong.artist}, Cover URL: ${currentSong.coverUrl}",
      );

      // Save the currently playing song to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastPlayedTitle', currentSong.title);
      await prefs.setString('lastPlayedArtist', currentSong.artist);
      await prefs.setString('lastPlayedCoverUrl', currentSong.coverUrl);
    });
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
          widget.player.seek(Duration.zero, index: index);
          widget.player.play();
        },
        itemBuilder: (context, idx) {
          final song = songs[idx];
          return SongCard(
            song: song,
            onRatingUpdate: (rating) async {
              await service.setRating(song.id, rating.toInt());
              setState(() {
                song.rating = rating.toInt();
              });
            },
          );
        },
      ),
    );
  }
}
