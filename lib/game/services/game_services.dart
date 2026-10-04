import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_mode.dart';

/// Hafif, önbellekli (in-memory cached) yerel veri saklama servisi.
class GameStorageService {
  GameStorageService._();
  static final GameStorageService instance = GameStorageService._();

  SharedPreferences? _prefs;
  final Map<GameMode, int> _highScores = {
    GameMode.classic: 0,
    GameMode.cyberNeon: 0,
    GameMode.spaceOrbit: 0,
    GameMode.conquest1453: 0,
  };
  bool _isMuted = false;

  bool get isMuted => _isMuted;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _highScores[GameMode.classic] =
        _prefs?.getInt('wingbound_high_score_classic') ?? 0;
    _highScores[GameMode.cyberNeon] =
        _prefs?.getInt('wingbound_high_score_cyber') ?? 0;
    _highScores[GameMode.spaceOrbit] =
        _prefs?.getInt('wingbound_high_score_space') ?? 0;
    _highScores[GameMode.conquest1453] =
        _prefs?.getInt('wingbound_high_score_conquest') ?? 0;
    _isMuted = _prefs?.getBool('wingbound_audio_muted') ?? false;
  }

  int getHighScore(GameMode mode) => _highScores[mode] ?? 0;

  Future<void> saveHighScore(GameMode mode, int score) async {
    _highScores[mode] = score;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    switch (mode) {
      case GameMode.classic:
        await prefs.setInt('wingbound_high_score_classic', score);
        break;
      case GameMode.cyberNeon:
        await prefs.setInt('wingbound_high_score_cyber', score);
        break;
      case GameMode.spaceOrbit:
        await prefs.setInt('wingbound_high_score_space', score);
        break;
      case GameMode.conquest1453:
        await prefs.setInt('wingbound_high_score_conquest', score);
        break;
    }
  }

  Future<void> setMuted(bool muted) async {
    _isMuted = muted;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool('wingbound_audio_muted', muted);
  }
}

/// `audioplayers` + `HapticFeedback` tabanlı düşük gecikmeli ses ve titreşim servisi.
class GameAudioService {
  GameAudioService._();
  static final GameAudioService instance = GameAudioService._();

  AudioPlayer? _sfxPlayer;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      _sfxPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      _initialized = true;
    } catch (_) {}
  }

  void playJump() {
    if (GameStorageService.instance.isMuted) return;
    HapticFeedback.selectionClick();
  }

  void playScore() {
    if (GameStorageService.instance.isMuted) return;
    HapticFeedback.lightImpact();
  }

  void playSpecialAbility() {
    if (GameStorageService.instance.isMuted) return;
    HapticFeedback.mediumImpact();
  }

  void playHit() {
    if (GameStorageService.instance.isMuted) return;
    HapticFeedback.heavyImpact();
  }

  Future<void> pauseAll() async {
    try {
      await _sfxPlayer?.pause();
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _sfxPlayer?.dispose();
      _sfxPlayer = null;
      _initialized = false;
    } catch (_) {}
  }
}
