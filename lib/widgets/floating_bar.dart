import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';

class MyHomePage extends StatelessWidget {
  final AudioPlayer player;
  const MyHomePage({required this.player, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Service Demo')),
      body: Center(child: Text('Audio player is ready.')),
      bottomNavigationBar: FloatingBar(player: player),
    );
  }
}

class FloatingBar extends StatelessWidget {
  final AudioPlayer player;
  const FloatingBar({required this.player, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SequenceState?>(
      stream: player.sequenceStateStream,
      builder: (context, snapshot) {
        final sequenceState = snapshot.data;
        debugPrint(
          "FloatingBar: sequenceState updated - ${sequenceState?.currentIndex}",
        );

        final currentSource = sequenceState?.currentSource;

        if (currentSource == null || currentSource.tag == null) {
          debugPrint("FloatingBar: No song playing");
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.black87,
            ),
            margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.music_note, color: Colors.grey, size: 40),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "No song playing",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }

        final mediaItem = currentSource.tag as MediaItem;
        final title = mediaItem.title;
        final artist = mediaItem.artist;
        final album = mediaItem.album ?? "Unknown Album";
        final artUri = mediaItem.artUri?.toString();

        debugPrint(
          "FloatingBar: Now playing - Title: $title, Artist: $artist, Album: $album",
        );

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.black87,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              if (artUri != null)
                Image.network(
                  artUri,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          Container(width: 40, height: 40, color: Colors.grey),
                ),
              const SizedBox(width: 8),
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
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  player.playing ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (player.playing) {
                    player.pause();
                  } else {
                    player.play();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
