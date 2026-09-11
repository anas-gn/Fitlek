import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  AudioPlayer? _currentPlayer;
  String? _currentlyPlayingUrl;

  /// Register a new player and stop the previously playing one
  void playNew(AudioPlayer player, String url) async {
    if (_currentPlayer != null && _currentPlayer != player) {
      try {
        await _currentPlayer!.stop();
      } catch (e) {
        // ignore errors on stop
      }
    }
    _currentPlayer = player;
    _currentlyPlayingUrl = url;
  }

  void stopCurrent() async {
    if (_currentPlayer != null) {
      try {
        await _currentPlayer!.stop();
      } catch (e) {
        // ignore errors
      }
      _currentPlayer = null;
      _currentlyPlayingUrl = null;
    }
  }

  bool isCurrentlyPlaying(String url) {
    return _currentlyPlayingUrl == url;
  }
}
