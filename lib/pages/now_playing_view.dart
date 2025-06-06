// File: now_playing_view.dart
// ------------------------------------------------
// Displays a detailed view of the currently playing song:
// - Shows artwork, title, artist, album
// - Fetches and displays the user's rating
// - Allows updating the rating with NavidromeService

import 'package:flutter/cupertino.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter/material.dart';
import '../services/navidrome_service.dart';
import 'package:audio_service/audio_service.dart';
import '../utils/app_colors.dart';
import '../services/playback_manager.dart';
import 'playlist_panel.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:palette_generator/palette_generator.dart';

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
  Color _dominantColor = AppColors.secondary;

  final PanelController _playlistController = PanelController();

  late final PlaybackManager _playbackManager;

  @override
  void initState() {
    super.initState();
    _playbackManager = PlaybackManager(
      player: widget.player,
      service: widget.service,
    );
    // Listen for sequence changes to update displayed media item
    widget.player.sequenceStateStream.listen((seqState) {
      // seqState is non-null, so directly access currentSource
      final item = seqState.currentSource?.tag as MediaItem?;
      if (item != null && item != _mediaItem) {
        setState(() {
          _mediaItem = item;
          _fetchRating(); // Load stored rating
        });
        // update dominant color from album art
        if (item.artUri != null) _updateDominantColor(item.artUri!);
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

  Future<void> _updateDominantColor(Uri artUri) async {
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        NetworkImage(artUri.toString()),
      );
      Color color = palette.dominantColor?.color ?? AppColors.secondary;
      final hsl = HSLColor.fromColor(color);
      if (hsl.saturation < 0.3) {
        color = Colors.white;
      } else {
        final hue = hsl.hue;
        if (hue < 30 || hue > 330)
          color = Colors.red;
        else if (hue < 90)
          color = Colors.yellow;
        else if (hue < 150)
          color = Colors.green;
        else if (hue < 210)
          color = Colors.cyan;
        else if (hue < 270)
          color = Colors.blue;
        else
          color = Colors.purple;
      }
      setState(() => _dominantColor = color);
    } catch (_) {}
  }

  // fix duration formatter to use variables
  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final item = _mediaItem;
    if (item != null) {
      // render current playing with dynamic background & colors
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: Stack(
          key: ValueKey(item.id),
          children: [
            // blurred full-background album art
            Positioned.fill(
              child: Image.network(item.artUri.toString(), fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(color: Colors.black.withOpacity(0.4)),
              ),
            ),
            // gradient overlay from semi-transparent to solid black
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.3), Colors.black],
                  ),
                ),
              ),
            ),
            // main panel
            SlidingUpPanel(
              controller: _playlistController,
              panel: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey3,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(child: PlaylistPanel(manager: _playbackManager)),
                ],
              ),
              minHeight: 32,
              maxHeight: MediaQuery.of(context).size.height * 0.6,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              body: GestureDetector(
                onVerticalDragEnd: (details) {
                  if (details.velocity.pixelsPerSecond.dy < 0) {
                    _playlistController.open();
                  } else if (details.velocity.pixelsPerSecond.dy > 0) {
                    widget.onClose();
                  }
                },
                child: CupertinoPageScaffold(
                  backgroundColor: Colors.transparent,
                  navigationBar: CupertinoNavigationBar(
                    middle: Text(item.title),
                    leading: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(
                        CupertinoIcons.chevron_down,
                        color: Colors.white,
                      ),
                      onPressed: widget.onClose,
                    ),
                  ),
                  child: SafeArea(child: _buildNowPlayingContent(item)),
                ),
              ),
            ),
          ],
        ),
      );
    }
    // Load and display last played song when no current item
    return FutureBuilder<MediaItem?>(
      future: () async {
        final prefs = await SharedPreferences.getInstance();
        final jsonStr = prefs.getString('last_media_item');
        if (jsonStr == null) return null;
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return MediaItem(
          id: map['id'] as String,
          title: map['title'] as String,
          artist: map['artist'] as String?,
          album: map['album'] as String?,
          artUri:
              map['artUri'] != null ? Uri.parse(map['artUri'] as String) : null,
        );
      }(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const CupertinoPageScaffold(
            child: Center(child: CupertinoActivityIndicator()),
          );
        }
        final lastItem = snap.data;
        if (lastItem == null) {
          return const CupertinoPageScaffold(
            child: Center(child: Text('No song playing')),
          );
        }
        // Display last played item details
        return SlidingUpPanel(
          controller: _playlistController,
          panel: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(child: PlaylistPanel(manager: _playbackManager)),
            ],
          ),
          minHeight: 32,
          maxHeight: MediaQuery.of(context).size.height * 0.6,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          body: CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: Text(lastItem.title),
              leading: CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.chevron_down),
                onPressed: widget.onClose,
              ),
            ),
            child: SafeArea(child: _buildNowPlayingContent(lastItem)),
          ),
        );
      },
    );
  }

  Widget _buildNowPlayingContent(MediaItem item) {
    return DefaultTextStyle.merge(
      style: const TextStyle(decoration: TextDecoration.none),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Centered swipeable cover art
            if (item.artUri != null)
              Center(
                child: GestureDetector(
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
              ),
            const SizedBox(height: 16),
            // Metadata
            Text(
              item.title,
              style: TextStyle(
                color: AppColors.floatingBarText,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 4),
            Text(
              item.artist ?? '',
              style: TextStyle(
                color: AppColors.floatingBarPlaceholder,
                fontSize: 18,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 4),
            Text(
              item.album ?? '',
              style: TextStyle(
                color: AppColors.progressBackground,
                fontSize: 16,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 16),
            // Seek bar
            StreamBuilder<Duration?>(
              stream: widget.player.durationStream,
              builder: (context, durSnap) {
                final duration = durSnap.data ?? Duration.zero;
                return StreamBuilder<Duration>(
                  stream: widget.player.positionStream,
                  builder: (context, posSnap) {
                    final position = posSnap.data ?? Duration.zero;
                    // Replace the slider UI and add time labels below the slider
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 20,
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              thumbShape: RoundSliderThumbShape(
                                enabledThumbRadius: 4,
                              ),
                              trackHeight: 2,
                              activeTrackColor: _dominantColor,
                              inactiveTrackColor: AppColors.progressBackground,
                              thumbColor: _dominantColor,
                            ),
                            child: Material(
                              type: MaterialType.transparency,
                              child: Slider(
                                min: 0,
                                max: duration.inMilliseconds.toDouble(),
                                value:
                                    position.inMilliseconds
                                        .clamp(0, duration.inMilliseconds)
                                        .toDouble(),
                                onChanged:
                                    (value) => widget.player.seek(
                                      Duration(milliseconds: value.round()),
                                    ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: TextStyle(
                                  color: AppColors.floatingBarPlaceholder,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: TextStyle(
                                  color: AppColors.floatingBarPlaceholder,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            // Centered rating stars
            Center(
              child: RatingBar.builder(
                initialRating: _currentRating.toDouble(),
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemSize: 32,
                unratedColor: AppColors.floatingBarPlaceholder,
                itemBuilder:
                    (context, _) =>
                        Icon(CupertinoIcons.star_fill, color: _dominantColor),
                onRatingUpdate: (rating) => _updateRating(rating.toInt()),
              ),
            ),
            const SizedBox(height: 24),
            // Playback controls: previous, play/pause, next
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CupertinoButton(
                  child: Icon(
                    CupertinoIcons.backward_end_fill,
                    color: _dominantColor,
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
                        color: AppColors.secondary,
                      ),
                      onPressed: () {
                        if (playing) {
                          widget.player.pause();
                        } else {
                          _playbackManager.playMedia(item.id);
                        }
                      },
                    );
                  },
                ),
                const SizedBox(width: 32),
                CupertinoButton(
                  child: Icon(
                    CupertinoIcons.forward_end_fill,
                    color: _dominantColor,
                  ),
                  onPressed: () => widget.player.seekToNext(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
