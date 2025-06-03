import 'package:just_audio/just_audio.dart';

class PlayerManager {
  PlayerManager._privateConstructor();
  static final PlayerManager _instance = PlayerManager._privateConstructor();
  factory PlayerManager() => _instance;

  final AudioPlayer player = AudioPlayer();

  Future<void> dispose() async {
    await player.dispose();
  }
}
