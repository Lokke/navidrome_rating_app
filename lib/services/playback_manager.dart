// Purpose: Manages playback logic, including fetching song metadata, generating stream URLs,
// and controlling playback actions like play, pause, and stop.

import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'navidrome_service.dart';
import '../models/song.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

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

  // Plays a media file using its ID.
  // Fetches metadata, generates the stream URL, and starts playback.
  Future<void> playMedia(String mediaId) async {
    try {
      // Fetch song metadata (title, artist, cover art, etc.).
      final song = await _fetchSongMetadata(mediaId);

      // Generate the stream URL for the media.
      final streamUrl = _service.uri('/rest/stream', {
        'id': mediaId,
        'maxBitRate': '320', // Fetch the highest quality available
      });
      print('Stream URL: $streamUrl');

      // Debugging: Print response headers and body to verify the stream.
      final response = await http.get(streamUrl);
      print('Response Headers: ${response.headers}');
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // Check if the response is valid.
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch audio stream: ${response.reasonPhrase}',
        );
      }

      // Create an AudioSource using the stream URL and metadata.
      final audioSource = AudioSource.uri(
        streamUrl,
        tag: MediaItem(
          id: song.id,
          title: song.title,
          artist: song.artist,
          artUri: Uri.parse(song.coverUrl),
        ),
      );

      // Set the audio source and start playback.
      await _player.setAudioSource(audioSource);
      _player.play();
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

  // Provides a stream of the buffered position of the current media.
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  // Provides a stream of the playback position of the current media.
  Stream<Duration> get positionStream => _player.positionStream;

  // Provides a stream of the total duration of the current media.
  Stream<Duration?> get durationStream => _player.durationStream;

  // Provides a stream indicating whether the player is currently playing.
  Stream<bool> get playingStream => _player.playingStream;
}
