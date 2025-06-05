// filepath: lib/pages/playlist_panel.dart
// View: PlaylistPanel
// Displays the current play queue and allows reordering via long-press drag

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // for Material proxyDecorator
import '../services/playback_manager.dart';

class PlaylistPanel extends StatefulWidget {
  final PlaybackManager manager;
  const PlaylistPanel({Key? key, required this.manager}) : super(key: key);

  @override
  State<PlaylistPanel> createState() => _PlaylistPanelState();
}

class _PlaylistPanelState extends State<PlaylistPanel> {
  @override
  Widget build(BuildContext context) {
    final items = widget.manager.currentQueue;
    final currentIndex = widget.manager.currentIndex;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Playlist')),
      child: SafeArea(
        child: ReorderableListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: items.length,
          onReorder: (oldIndex, newIndex) async {
            if (newIndex > oldIndex) newIndex--;
            await widget.manager.moveInQueue(oldIndex, newIndex);
            setState(() {});
          },
          itemBuilder: (context, index) {
            final item = items[index];
            final isCurrent = index == currentIndex;
            return Container(
              key: ValueKey(item.id),
              color:
                  isCurrent
                      ? CupertinoColors.systemGrey4
                      : CupertinoColors.systemBackground,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            isCurrent
                                ? CupertinoColors.activeBlue
                                : CupertinoColors.label,
                      ),
                    ),
                  ),
                  if (isCurrent)
                    const Icon(
                      CupertinoIcons.music_note,
                      color: CupertinoColors.activeBlue,
                    ),
                ],
              ),
            );
          },
          proxyDecorator: (child, index, animation) {
            return Material(elevation: 6, child: child);
          },
        ),
      ),
    );
  }
}
