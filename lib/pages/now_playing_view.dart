// File: now_playing_view.dart
// ------------------------------------------------
// Displays a detailed view of the currently playing song:
// - Shows artwork, title, artist, album
// - Fetches and displays the user's rating
// - Allows updating the rating with NavidromeService

import 'package:flutter/cupertino.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../services/navidrome_service.dart';
import 'package:audio_service/audio_service.dart';

/// NowPlayingPage shows full song details and rating controls.
class NowPlayingPage extends StatefulWidget {
  /// AudioPlayer instance to get current sequenceState
  final AudioPlayer player;

  /// NavidromeService for rating API calls
  final NavidromeService service;

  /// Callback to close the now playing panel
  final VoidCallback onClose;

  const NowPlayingPage({
    Key? key,
    required this.player,
    required this.service,
    required this.onClose,
  }) : super(key: key);

  @override
  _NowPlayingPageState createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage> {
  /// Currently playing media item metadata
  MediaItem? _mediaItem;

  /// User's current rating (0-5)
  int _currentRating = 0;

  @override
  void initState() {
    super.initState();
    // Listen for sequence changes to update displayed media item
    widget.player.sequenceStateStream.listen((seqState) {
      // seqState is non-null, so directly access currentSource
      final item = seqState.currentSource?.tag as MediaItem?;
      if (item != null && item != _mediaItem) {
        setState(() {
          _mediaItem = item;
          _fetchRating(); // Load stored rating
        });
      }
    });
  }

  /// Fetch rating from server for the current media item
  Future<void> _fetchRating() async {
    if (_mediaItem == null) return;
    final rating = await widget.service.getRating(_mediaItem!.id);
    setState(() => _currentRating = rating);
  }

  /// Update rating on server and local state
  Future<void> _updateRating(int rating) async {
    if (_mediaItem == null) return;
    await widget.service.setRating(_mediaItem!.id, rating);
    setState(() => _currentRating = rating);
  }

  @override
  Widget build(BuildContext context) {
    final item = _mediaItem;
    if (item == null) {
      return const CupertinoPageScaffold(
        child: Center(child: Text('No song playing')),
      );
    }
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(item.title),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.chevron_down),
          onPressed: widget.onClose,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Swipeable cover art
              if (item.artUri != null)
                GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity! < 0) {
                      widget.player.seekToNext();
                    } else if (details.primaryVelocity! > 0) {
                      widget.player.seekToPrevious();
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.artUri.toString(),
                      width: 300,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // Metadata
              Text(
                item.title,
                style: TextStyle(
                  color: CupertinoColors.label,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                item.artist ?? '',
                style: const TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                item.album ?? '',
                style: const TextStyle(
                  color: CupertinoColors.systemGrey2,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Rating
              RatingBar.builder(
                initialRating: _currentRating.toDouble(),
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemSize: 32,
                unratedColor: CupertinoColors.systemGrey2,
                itemBuilder:
                    (context, _) => const Icon(
                      CupertinoIcons.star_fill,
                      color: CupertinoColors.systemRed,
                    ),
                onRatingUpdate: (rating) => _updateRating(rating.toInt()),
              ),
              const SizedBox(height: 24),
              // Playback controls: previous, play/pause, next
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoButton(
                    child: const Icon(
                      CupertinoIcons.backward_end_fill,
                      size: 28,
                    ),
                    onPressed: () => widget.player.seekToPrevious(),
                  ),
                  const SizedBox(width: 32),
                  StreamBuilder<bool>(
                    stream: widget.player.playingStream,
                    builder: (context, snapshot) {
                      final playing = snapshot.data ?? false;
                      return CupertinoButton(
                        child: Icon(
                          playing
                              ? CupertinoIcons.pause_fill
                              : CupertinoIcons.play_fill,
                          size: 36,
                        ),
                        onPressed:
                            () =>
                                playing
                                    ? widget.player.pause()
                                    : widget.player.play(),
                      );
                    },
                  ),
                  const SizedBox(width: 32),
                  CupertinoButton(
                    child: const Icon(
                      CupertinoIcons.forward_end_fill,
                      size: 28,
                    ),
                    onPressed: () => widget.player.seekToNext(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
