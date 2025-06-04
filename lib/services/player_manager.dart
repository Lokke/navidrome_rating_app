// Purpose: Provides a singleton instance of AudioPlayer for shared use across the app.
// Handles the lifecycle of the AudioPlayer, including disposal.

import 'package:just_audio/just_audio.dart';

class PlayerManager {
  // Private constructor to ensure only one instance of PlayerManager exists.
  PlayerManager._privateConstructor();

  // The single instance of PlayerManager.
  static final PlayerManager _instance = PlayerManager._privateConstructor();

  // Factory constructor to return the single instance.
  factory PlayerManager() => _instance;

  // The AudioPlayer instance used for playback.
  final AudioPlayer player = AudioPlayer();

  // Disposes the AudioPlayer instance to free resources.
  Future<void> dispose() async {
    await player.dispose();
  }
}
