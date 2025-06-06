// filepath: lib/pages/playlist_panel.dart
// View: PlaylistPanel
// Displays the current play queue and allows reordering via long-press drag

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/playback_manager.dart';

class PlaylistPanel extends StatelessWidget {
  final PlaybackManager manager;
  const PlaylistPanel({Key? key, required this.manager}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = manager.currentQueue;
    final currentIndex = manager.currentIndex;

    return Container(
      color: CupertinoColors.systemBackground,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              height: 56,
              alignment: Alignment.center,
              child: Text(
                'Playlist',
                style:
                    CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child:
                  items.isEmpty
                      ? const Center(child: CupertinoActivityIndicator())
                      : ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final song = items[index];
                          final isCurrent = index == currentIndex;
                          return GestureDetector(
                            onTap: () => manager.seekToIndex(index),
                            child: Container(
                              color:
                                  isCurrent
                                      ? CupertinoColors.systemGrey5
                                      : CupertinoColors.systemBackground,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  // Cover art
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child:
                                        song.coverUrl.isNotEmpty
                                            ? Image.network(
                                              song.coverUrl,
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                            )
                                            : const Icon(
                                              CupertinoIcons.music_note,
                                              size: 40,
                                            ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Title & artist
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          song.title,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                                isCurrent
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          song.artist,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: CupertinoColors.systemGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Playing indicator
                                  if (isCurrent)
                                    const Icon(
                                      CupertinoIcons.play_fill,
                                      color: CupertinoColors.activeBlue,
                                    ),
                                ],
                              ),
                            ),
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
