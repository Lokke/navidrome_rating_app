// File: floating_bar.dart
// -----------------------
// This widget displays a compact floating bar showing the current playing song.
// It subscribes to the AudioPlayer's sequenceStateStream to update song info and playback status.

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/navidrome_service.dart';
import '../utils/app_colors.dart';
import '../services/playback_manager.dart';

/// FloatingBar shows the currently playing track in a small bar,
/// including artwork, title, artist, playback controls, and progress.
class FloatingBar extends StatelessWidget {
  /// Reference to the JustAudio player instance (singleton via PlayerManager).
  final AudioPlayer player;

  /// Service to fetch metadata and set ratings (not used directly here,
  /// but available for potential rating interactions).
  final NavidromeService service;

  /// Constructor: requires an AudioPlayer and NavidromeService.
  const FloatingBar({required this.player, required this.service, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use StreamBuilder to rebuild the bar whenever the sequence state changes
    return StreamBuilder<SequenceState?>(
      stream: player.sequenceStateStream, // Stream of playlist sequence updates
      builder: (context, snapshot) {
        final sequenceState = snapshot.data;
        debugPrint(
          "FloatingBar: sequenceState updated - ${sequenceState?.currentIndex}",
        );

        // If no audio source or tag available, show a placeholder
        final currentSource = sequenceState?.currentSource;

        if (currentSource == null || currentSource.tag == null) {
          // Attempt to load last played media item from storage
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
                    map['artUri'] != null
                        ? Uri.parse(map['artUri'] as String)
                        : null,
              );
            }(),
            builder: (ctx, snap2) {
              // Determine displayed MediaItem or placeholder
              final hasData =
                  snap2.connectionState == ConnectionState.done &&
                  snap2.data != null;
              final displayedItem = hasData ? snap2.data! : null;
              final title = displayedItem?.title ?? 'No song playing';
              final artist = displayedItem?.artist;
              final artUri = displayedItem?.artUri;
              // Build consistent bar with play/pause and progress
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.floatingBarBackground,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Artwork or placeholder icon
                        if (artUri != null)
                          Image.network(
                            artUri.toString(),
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          )
                        else
                          const Icon(
                            Icons.music_note,
                            size: 40,
                            color: AppColors.floatingBarPlaceholder,
                          ),
                        const SizedBox(width: 8),
                        // Title & optional artist
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: AppColors.floatingBarText,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (artist != null)
                                Text(
                                  artist,
                                  style: const TextStyle(
                                    color: AppColors.floatingBarPlaceholder,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        // Play/Pause button (always present)
                        StreamBuilder<bool>(
                          stream: player.playingStream,
                          builder: (context, playSnap) {
                            final isPlaying = playSnap.data ?? false;
                            return IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                color: AppColors.floatingBarIcon,
                              ),
                              onPressed: () {
                                if (isPlaying) {
                                  player.pause();
                                } else if (displayedItem != null) {
                                  // Start playback of last saved track
                                  PlaybackManager(
                                    player: player,
                                    service: service,
                                  ).playMedia(displayedItem.id);
                                }
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Placeholder progress bar ready for playback
                    Container(
                      height: 4,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.progressBackground,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }

        // Extract MediaItem (tag attached to the AudioSource) for metadata
        final mediaItem = currentSource.tag as MediaItem;
        final title = mediaItem.title; // Song title
        final artist = mediaItem.artist; // Artist name
        final album = mediaItem.album ?? "Unknown Album"; // Album name
        final artUri = mediaItem.artUri?.toString(); // Artwork URL

        debugPrint(
          "FloatingBar: Now playing - Title: $title, Artist: $artist, Album: $album",
        );

        // Build the UI bar showing artwork, title/artist, and play/pause button
        final bar = Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.floatingBarBackground,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            children: [
              Row(
                children: [
                  // Display cover art if available
                  if (artUri != null)
                    Image.network(
                      artUri,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey,
                          ),
                    ),
                  const SizedBox(width: 8),
                  // Show title and artist stacked vertically
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          artist ?? "Unknown Artist",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Play/Pause button reflecting current playback state
                  StreamBuilder<bool>(
                    stream: player.playingStream,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data ?? false;
                      return IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: AppColors.floatingBarIcon,
                        ),
                        onPressed: () {
                          if (isPlaying) {
                            player.pause(); // Pause playback
                          } else {
                            player.play(); // Start playback
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Progress bar with buffered and played position
              StreamBuilder<Duration?>(
                stream: player.bufferedPositionStream,
                builder: (context, bufferedSnap) {
                  final buffered = bufferedSnap.data ?? Duration.zero;
                  return StreamBuilder<Duration>(
                    stream: player.positionStream,
                    builder: (context, posSnap) {
                      final position = posSnap.data ?? Duration.zero;
                      final duration = player.duration ?? Duration.zero;
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 4,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.progressBackground,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Stack(
                            children: [
                              // Buffered portion indicator
                              FractionallySizedBox(
                                widthFactor:
                                    duration.inMilliseconds == 0
                                        ? 0
                                        : (buffered.inMilliseconds /
                                                duration.inMilliseconds)
                                            .clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.progressBuffered,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              // Played portion indicator
                              FractionallySizedBox(
                                widthFactor:
                                    duration.inMilliseconds == 0
                                        ? 0
                                        : (position.inMilliseconds /
                                                duration.inMilliseconds)
                                            .clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );

        // Return the fully built floating bar widget
        return bar;
      },
    );
  }
}
