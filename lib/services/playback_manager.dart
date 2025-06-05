// Purpose: Manages playback logic, including fetching song metadata, generating stream URLs,
// and controlling playback actions like play, pause, and stop.

import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'navidrome_service.dart';
import '../models/song.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PlaybackManager {
  // The AudioPlayer instance used for playback.
  final AudioPlayer _player;

  // The NavidromeService instance used to fetch song metadata and URLs.
  final NavidromeService _service;

  // Constructor to initialize the PlaybackManager with an AudioPlayer and NavidromeService.
  PlaybackManager({
    required AudioPlayer player,
    required NavidromeService service,
  }) : _player = player,
       _service = service;

  // Builds a MediaItem object for a given song.
  MediaItem buildMediaItem(Song song) {
    return MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album ?? "Unknown Album",
      artUri: Uri.parse(song.coverUrl),
    );
  }

  // Add helper to persist last media item
  Future<void> _persistLastMediaItem(MediaItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'id': item.id,
      'title': item.title,
      'artist': item.artist,
      'album': item.album,
      'artUri': item.artUri?.toString(),
    };
    await prefs.setString('last_media_item', jsonEncode(map));
  }

  // Plays a media file using its ID.
  // Fetches metadata, generates the stream URL, and starts playback.
  Future<void> playMedia(String mediaId) async {
    try {
      // Fetch song metadata and build MediaItem.
      final song = await _fetchSongMetadata(mediaId);
      final mediaItem = buildMediaItem(song);

      // Generate the stream URL for the media.
      final streamUrl = _service.uri('/rest/stream', {
        'id': mediaId,
        'maxBitRate': '320', // Fetch the highest quality available
      });
      print('Stream URL: $streamUrl');

      // Download the song file
      final response = await http.get(streamUrl);
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch audio stream: ${response.reasonPhrase}',
        );
      }

      // Save the file locally
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$mediaId.mp3';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Verify the file size
      if (await file.length() == 0) {
        throw Exception('Downloaded file is empty');
      }

      // Use the local file for playback and tag with the MediaItem.
      // Stop any existing playback before setting new source
      await _player.stop();
      final audioSource = AudioSource.file(filePath, tag: mediaItem);

      // Set the audio source and start playback.
      await _player.setAudioSource(audioSource);
      await _player.seek(Duration.zero);
      _player.play();
      // Persist this as the last played item
      await _persistLastMediaItem(mediaItem);
    } catch (e) {
      // Print any errors that occur during playback.
      print('Error playing media: $e');
    }
  }

  // Fetches metadata for a song using its ID.
  // Combines metadata from the Navidrome API with the user rating.
  Future<Song> _fetchSongMetadata(String mediaId) async {
    // Fetch detailed metadata for the song.
    final response = await _service.getSong(mediaId);

    // Fetch the user rating for the song.
    final rating = await _service.getRating(mediaId);

    // Return a Song object with all metadata and the rating.
    return Song(
      id: mediaId,
      title: response['title'] ?? 'Unknown Title',
      artist: response['artist'] ?? 'Unknown Artist',
      coverUrl:
          response['coverArt'] != null
              ? _service.uri('/rest/getCoverArt', {
                'id': response['coverArt'],
                'size': '500',
              }).toString()
              : '',
      mediaId: mediaId,
      rating: rating,
    );
  }

  // Pauses playback.
  void pause() => _player.pause();

  // Resumes playback.
  void resume() => _player.play();

  // Stops playback.
  void stop() => _player.stop();

  // Plays a list of songs as a playlist, starting at the given index.
  Future<void> playPlaylist(List<Song> songs, {int startIndex = 0}) async {
    // Build audio sources with tags for each song
    final sources =
        songs.map((song) {
          final mediaItem = buildMediaItem(song);
          final uri = _service.uri('/rest/stream', {
            'id': song.id,
            'maxBitRate': '320',
          });
          return AudioSource.uri(uri, tag: mediaItem);
        }).toList();
    // Create a concatenated playlist and start playback
    final playlist = ConcatenatingAudioSource(children: sources);
    // Ensure we fully reset any current playback and load the new playlist
    await _player.stop();
    await _player.setAudioSource(playlist, initialIndex: startIndex);
    await _player.seek(Duration.zero);
    _player.play();
    // Persist the first item in the queue as last played
    final firstItem = sources[startIndex].tag as MediaItem;
    await _persistLastMediaItem(firstItem);
  }

  // Provides a stream of the buffered position of the current media.
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  // Provides a stream of the playback position of the current media.
  Stream<Duration> get positionStream => _player.positionStream;

  // Provides a stream of the total duration of the current media.
  Stream<Duration?> get durationStream => _player.durationStream;

  // Provides a stream indicating whether the player is currently playing.
  Stream<bool> get playingStream => _player.playingStream;
}
