import 'dart:math' as math;
import 'dart:typed_data';
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
  final Map<GameMode, int> _selectedSkins = {
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

    _selectedSkins[GameMode.classic] =
        _prefs?.getInt('wingbound_skin_classic') ?? 0;
    _selectedSkins[GameMode.cyberNeon] =
        _prefs?.getInt('wingbound_skin_cyber') ?? 0;
    _selectedSkins[GameMode.spaceOrbit] =
        _prefs?.getInt('wingbound_skin_space') ?? 0;
    _selectedSkins[GameMode.conquest1453] =
        _prefs?.getInt('wingbound_skin_conquest') ?? 0;

    _isMuted = _prefs?.getBool('wingbound_audio_muted') ?? false;
  }

  int getHighScore(GameMode mode) => _highScores[mode] ?? 0;

  int getSelectedSkin(GameMode mode) => _selectedSkins[mode] ?? 0;

  Future<void> saveSelectedSkin(GameMode mode, int skinIndex) async {
    _selectedSkins[mode] = skinIndex;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    switch (mode) {
      case GameMode.classic:
        await prefs.setInt('wingbound_skin_classic', skinIndex);
        break;
      case GameMode.cyberNeon:
        await prefs.setInt('wingbound_skin_cyber', skinIndex);
        break;
      case GameMode.spaceOrbit:
        await prefs.setInt('wingbound_skin_space', skinIndex);
        break;
      case GameMode.conquest1453:
        await prefs.setInt('wingbound_skin_conquest', skinIndex);
        break;
    }
  }

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

/// Saf Dart 16-bit PCM WAV ses sentezleyicisi + Çok kanallı (Polyphonic) AVAudioPlayer motoru.
/// Harici MP3/WAV dosyası gerektirmeden bellekte gerçek zamanlı arcade ses dalgaları üretir.
class GameAudioService {
  GameAudioService._();
  static final GameAudioService instance = GameAudioService._();

  static const MethodChannel _channel =
      MethodChannel('com.selimbozkurt.wingbound/audio');

  bool _initialized = false;
  bool _nativeChannelAvailable = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final jumpWav = _synthesizeSweep(
        startFreq: 310.0,
        endFreq: 690.0,
        durationSec: 0.11,
        volume: 0.38,
      );
      final scoreWav = _synthesizeArpeggio(
        notes: const [523.25, 659.25, 783.99, 1046.50], // C5 - E5 - G5 - C6
        noteDurationSec: 0.055,
        volume: 0.42,
      );
      final abilityWav = _synthesizeSweep(
        startFreq: 180.0,
        endFreq: 920.0,
        durationSec: 0.24,
        volume: 0.48,
        harmonicMix: 0.45,
      );
      final hitWav = _synthesizeImpact(
        durationSec: 0.26,
        volume: 0.52,
      );

      final ok = await _channel.invokeMethod<bool>('preload', {
        'id': 'jump',
        'wav': jumpWav,
      });
      if (ok == true) {
        _nativeChannelAvailable = true;
        await _channel.invokeMethod<bool>('preload', {
          'id': 'score',
          'wav': scoreWav,
        });
        await _channel.invokeMethod<bool>('preload', {
          'id': 'ability',
          'wav': abilityWav,
        });
        await _channel.invokeMethod<bool>('preload', {
          'id': 'hit',
          'wav': hitWav,
        });
      }
    } catch (_) {
      _nativeChannelAvailable = false;
    }
  }

  void playJump() {
    if (GameStorageService.instance.isMuted) return;
    HapticFeedback.selectionClick();
    if (_nativeChannelAvailable) {
      _channel.invokeMethod('play', {'id': 'jump', 'volume': 0.55});
    } else {
      SystemSound.play(SystemSoundType.click);
    }
  }

  void playScore() {
    if (GameStorageService.instance.isMuted) return;
    HapticFeedback.lightImpact();
    if (_nativeChannelAvailable) {
      _channel.invokeMethod('play', {'id': 'score', 'volume': 0.65});
    }
  }

  void playSpecialAbility() {
    if (GameStorageService.instance.isMuted) return;
    HapticFeedback.mediumImpact();
    if (_nativeChannelAvailable) {
      _channel.invokeMethod('play', {'id': 'ability', 'volume': 0.75});
    }
  }

  void playHit() {
    if (GameStorageService.instance.isMuted) return;
    HapticFeedback.heavyImpact();
    if (_nativeChannelAvailable) {
      _channel.invokeMethod('play', {'id': 'hit', 'volume': 0.80});
    } else {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  Future<void> pauseAll() async {}

  Future<void> dispose() async {
    _initialized = false;
  }

  /// Frekans kaydırmalı (Pitch-sweep) 16-bit 44.1kHz PCM WAV sentezleyici
  static Uint8List _synthesizeSweep({
    required double startFreq,
    required double endFreq,
    required double durationSec,
    double volume = 0.4,
    double harmonicMix = 0.2,
  }) {
    const sampleRate = 44100;
    final numSamples = (sampleRate * durationSec).round();
    final samples = Int16List(numSamples);
    double phase = 0.0;

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final env = math.sin(t * math.pi); // Yumuşak attack/decay zarfı
      final freq = startFreq + (endFreq - startFreq) * (t * t);
      phase += (2.0 * math.pi * freq) / sampleRate;
      final fundamental = math.sin(phase);
      final overtone = math.sin(phase * 2.0) * harmonicMix;
      final val = ((fundamental + overtone) / (1.0 + harmonicMix)) * env * volume;
      samples[i] = (val.clamp(-1.0, 1.0) * 32767).round();
    }
    return _encodeWav(samples, sampleRate);
  }

  /// Akor / Arpej (Chime) 16-bit PCM WAV sentezleyici
  static Uint8List _synthesizeArpeggio({
    required List<double> notes,
    required double noteDurationSec,
    double volume = 0.4,
  }) {
    const sampleRate = 44100;
    final samplesPerNote = (sampleRate * noteDurationSec).round();
    final totalSamples = samplesPerNote * notes.length;
    final samples = Int16List(totalSamples);
    double phase = 0.0;

    for (int n = 0; n < notes.length; n++) {
      final freq = notes[n];
      for (int i = 0; i < samplesPerNote; i++) {
        final localT = i / samplesPerNote;
        final env = (1.0 - localT * 0.75) * math.sin(math.min(1.0, localT * 8.0) * math.pi * 0.5);
        phase += (2.0 * math.pi * freq) / sampleRate;
        final sampleVal = (math.sin(phase) * 0.75 + math.sin(phase * 2.0) * 0.25) * env * volume;
        samples[n * samplesPerNote + i] =
            (sampleVal.clamp(-1.0, 1.0) * 32767).round();
      }
    }
    return _encodeWav(samples, sampleRate);
  }

  /// Çarpışma / Patlama (Sub-bass + White noise burst) WAV sentezleyici
  static Uint8List _synthesizeImpact({
    required double durationSec,
    double volume = 0.5,
  }) {
    const sampleRate = 44100;
    final numSamples = (sampleRate * durationSec).round();
    final samples = Int16List(numSamples);
    final rng = math.Random(1453);
    double phase = 0.0;

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final env = math.pow(1.0 - t, 1.8).toDouble();
      final freq = 140.0 * (1.0 - t * 0.72);
      phase += (2.0 * math.pi * freq) / sampleRate;
      final subBass = math.sin(phase);
      final noise = (rng.nextDouble() * 2.0 - 1.0) * 0.45;
      final val = (subBass * 0.65 + noise) * env * volume;
      samples[i] = (val.clamp(-1.0, 1.0) * 32767).round();
    }
    return _encodeWav(samples, sampleRate);
  }

  static Uint8List _encodeWav(Int16List pcmSamples, int sampleRate) {
    final dataSize = pcmSamples.length * 2;
    final buffer = ByteData(44 + dataSize);

    // "RIFF"
    buffer.setUint8(0, 0x52);
    buffer.setUint8(1, 0x49);
    buffer.setUint8(2, 0x46);
    buffer.setUint8(3, 0x46);
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    // "WAVE"
    buffer.setUint8(8, 0x57);
    buffer.setUint8(9, 0x41);
    buffer.setUint8(10, 0x56);
    buffer.setUint8(11, 0x45);
    // "fmt "
    buffer.setUint8(12, 0x66);
    buffer.setUint8(13, 0x6D);
    buffer.setUint8(14, 0x74);
    buffer.setUint8(15, 0x20);
    buffer.setUint32(16, 16, Endian.little); // PCM chunk size
    buffer.setUint16(20, 1, Endian.little); // AudioFormat = 1 (PCM)
    buffer.setUint16(22, 1, Endian.little); // NumChannels = 1 (Mono)
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
    buffer.setUint16(32, 2, Endian.little); // BlockAlign
    buffer.setUint16(34, 16, Endian.little); // BitsPerSample
    // "data"
    buffer.setUint8(36, 0x64);
    buffer.setUint8(37, 0x61);
    buffer.setUint8(38, 0x74);
    buffer.setUint8(39, 0x61);
    buffer.setUint32(40, dataSize, Endian.little);

    for (int i = 0; i < pcmSamples.length; i++) {
      buffer.setInt16(44 + i * 2, pcmSamples[i], Endian.little);
    }
    return buffer.buffer.asUint8List();
  }
}
