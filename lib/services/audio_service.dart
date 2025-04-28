import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SoundType {
  rotate,
  clearLine,
  clearTetris, // 4 lines at once
  gameStart,
  gameOver,
  victory,
  applyGarbage,
  lobbySoundtrack
}

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _effectsPlayer = AudioPlayer();
  final AudioPlayer _backgroundPlayer = AudioPlayer();
  bool _isSoundEnabled = true;

  // Cache the sound files
  final Map<SoundType, String> _soundPaths = {
    SoundType.rotate: 'audio/rotate.mp3',
    SoundType.clearLine: 'audio/clear_line.mp3',
    SoundType.clearTetris: 'audio/tetris.mp3',
    SoundType.gameStart: 'audio/start.mp3',
    SoundType.gameOver: 'audio/lose.mp3',
    SoundType.victory: 'audio/victory.mp3',
    SoundType.applyGarbage: 'audio/garbage.mp3',
    SoundType.lobbySoundtrack: 'audio/lobby.mp3',
  };

  Future<void> initialize() async {
    // Load sound preferences
    final prefs = await SharedPreferences.getInstance();
    _isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _isSoundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', enabled);

    if (!enabled) {
      await stopAllSounds();
    }
  }

  bool get isSoundEnabled => _isSoundEnabled;

  Future<void> playSound(SoundType type) async {
    if (!_isSoundEnabled) return;

    try {
      final source = AssetSource(_soundPaths[type]!);

      if (type == SoundType.lobbySoundtrack) {
        await _backgroundPlayer.stop();
        await _backgroundPlayer.play(source);
        await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
      } else {
        await _effectsPlayer.play(source);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing sound: $e');
      }
    }
  }

  Future<void> stopBackgroundSound() async {
    await _backgroundPlayer.stop();
  }

  Future<void> stopAllSounds() async {
    await _effectsPlayer.stop();
    await _backgroundPlayer.stop();
  }

  void dispose() {
    _effectsPlayer.dispose();
    _backgroundPlayer.dispose();
  }
}
