// File: now_playing_view.dart
// ------------------------------------------------
// Displays a detailed view of the currently playing song:
// - Shows artwork, title, artist, album
// - Fetches and displays the user's rating
// - Allows updating the rating with NavidromeService

import 'package:flutter/material.dart';
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
    // If no media item loaded, show placeholder text
    if (item == null) {
      return const Center(child: Text('No song playing'));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_downward),
          onPressed: widget.onClose, // Close sliding panel via callback
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Display cover art
            if (item.artUri != null)
              Image.network(
                item.artUri.toString(),
                width: 300,
                height: 300,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 16),
            // Song title
            Text(
              item.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Artist name
            Text(
              item.artist ?? '',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Album name
            Text(
              item.album ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Rating bar for setting song rating
            RatingBar.builder(
              initialRating: _currentRating.toDouble(),
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemSize: 40,
              unratedColor: Colors.grey.shade600,
              itemBuilder:
                  (context, _) => Icon(
                    Icons.star,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
              onRatingUpdate: (rating) => _updateRating(rating.toInt()),
            ),
          ],
        ),
      ),
    );
  }
}
