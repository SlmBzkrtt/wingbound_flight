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

/// Her evrene (Classic, Cyber Neon, Space Orbit, 1453 Conquest) özel
/// 16-bit 44.1kHz PCM WAV ses sentezleyicisi + Çok kanallı AVAudioPlayer motoru.
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
      // 1. CLASSIC SKY: Yumuşak kanat çırpışı (rüzgar hışırtısı + kuş ıslığı)
      final jumpClassicWav = _synthesizeClassicWingFlap();
      // 2. CYBER NEON: Yüksek teknoloji plazma lazer ateşlemesi + siber itici
      final jumpCyberWav = _synthesizeCyberLaserPulse();
      // 3. SPACE ORBIT: Basınçlı iyon jetpack püskürtmesi (derin uzay RCS gaz sesi)
      final jumpSpaceWav = _synthesizeSpaceIonThruster();
      // 4. 1453 CONQUEST: Kadırga top atışı gürlemesi + kürek/deniz dalgası şapırtısı!
      final jumpConquestWav = _synthesizeConquestCannonAndOar();

      // Skor sesleri
      final scoreWav = _synthesizeArpeggio(
        notes: const [523.25, 659.25, 783.99, 1046.50], // C5 - E5 - G5 - C6
        noteDurationSec: 0.055,
        volume: 0.42,
      );

      // Özel yetenek sesleri (EMP, Süpernova, Şahi Topu)
      final abilityCyberWav = _synthesizeSweep(
        startFreq: 880.0,
        endFreq: 110.0,
        durationSec: 0.28,
        volume: 0.50,
        harmonicMix: 0.55,
      );
      final abilitySpaceWav = _synthesizeSweep(
        startFreq: 190.0,
        endFreq: 960.0,
        durationSec: 0.30,
        volume: 0.48,
        harmonicMix: 0.40,
      );
      final abilityConquestWav = _synthesizeSahiSalvo();

      // Çarpışma sesi
      final hitWav = _synthesizeImpact(
        durationSec: 0.28,
        volume: 0.54,
      );

      final ok = await _channel.invokeMethod<bool>('preload', {
        'id': 'jump_classic',
        'wav': jumpClassicWav,
      });
      if (ok == true) {
        _nativeChannelAvailable = true;
        await _channel.invokeMethod<bool>('preload', {
          'id': 'jump_cyber',
          'wav': jumpCyberWav,
        });
        await _channel.invokeMethod<bool>('preload', {
          'id': 'jump_space',
          'wav': jumpSpaceWav,
        });
        await _channel.invokeMethod<bool>('preload', {
          'id': 'jump_conquest',
          'wav': jumpConquestWav,
        });
        await _channel.invokeMethod<bool>('preload', {
          'id': 'score',
          'wav': scoreWav,
        });
        await _channel.invokeMethod<bool>('preload', {
          'id': 'ability_cyber',
          'wav': abilityCyberWav,
        });
        await _channel.invokeMethod<bool>('preload', {
          'id': 'ability_space',
          'wav': abilitySpaceWav,
        });
        await _channel.invokeMethod<bool>('preload', {
          'id': 'ability_conquest',
          'wav': abilityConquestWav,
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

  /// Her oyun modunun kendi atmosferine uygun SPACE / Dokunma aksiyon sesi çalar.
  void playJump([GameMode mode = GameMode.classic]) {
    if (GameStorageService.instance.isMuted) return;
    HapticFeedback.selectionClick();
    if (_nativeChannelAvailable) {
      final String soundId;
      switch (mode) {
        case GameMode.classic:
          soundId = 'jump_classic';
          break;
        case GameMode.cyberNeon:
          soundId = 'jump_cyber';
          break;
        case GameMode.spaceOrbit:
          soundId = 'jump_space';
          break;
        case GameMode.conquest1453:
          soundId = 'jump_conquest';
          break;
      }
      _channel.invokeMethod('play', {'id': soundId, 'volume': 0.62});
    } else {
      SystemSound.play(SystemSoundType.click);
    }
  }

  void playScore([GameMode mode = GameMode.classic]) {
    if (GameStorageService.instance.isMuted) return;
    HapticFeedback.lightImpact();
    if (_nativeChannelAvailable) {
      _channel.invokeMethod('play', {'id': 'score', 'volume': 0.65});
    }
  }

  void playSpecialAbility([GameMode mode = GameMode.cyberNeon]) {
    if (GameStorageService.instance.isMuted) return;
    HapticFeedback.mediumImpact();
    if (_nativeChannelAvailable) {
      final String soundId;
      switch (mode) {
        case GameMode.conquest1453:
          soundId = 'ability_conquest';
          break;
        case GameMode.spaceOrbit:
          soundId = 'ability_space';
          break;
        case GameMode.cyberNeon:
        case GameMode.classic:
          soundId = 'ability_cyber';
          break;
      }
      _channel.invokeMethod('play', {'id': soundId, 'volume': 0.80});
    }
  }

  void playHit() {
    if (GameStorageService.instance.isMuted) return;
    HapticFeedback.heavyImpact();
    if (_nativeChannelAvailable) {
      _channel.invokeMethod('play', {'id': 'hit', 'volume': 0.82});
    } else {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  Future<void> pauseAll() async {}

  Future<void> dispose() async {
    _initialized = false;
  }

  /// 1. CLASSIC SKY: Yumuşak kanat çırpışı (rüzgar hışırtısı + melodik kuş ıslığı)
  static Uint8List _synthesizeClassicWingFlap() {
    const sampleRate = 44100;
    const durationSec = 0.12;
    final numSamples = (sampleRate * durationSec).round();
    final samples = Int16List(numSamples);
    final rng = math.Random(42);
    double phase = 0.0;
    double filteredNoise = 0.0;

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final env = math.sin(t * math.pi);
      // Yumuşak kanat rüzgarı (Low-pass filtered air whoosh)
      final rawNoise = rng.nextDouble() * 2.0 - 1.0;
      filteredNoise = filteredNoise * 0.86 + rawNoise * 0.14;
      // Tatlı yukarı doğru ıslık (360Hz -> 620Hz)
      final freq = 360.0 + 260.0 * (t * t);
      phase += (2.0 * math.pi * freq) / sampleRate;
      final whistle = math.sin(phase) * 0.55;
      final val = (whistle + filteredNoise * 0.65) * env * 0.42;
      samples[i] = (val.clamp(-1.0, 1.0) * 32767).round();
    }
    return _encodeWav(samples, sampleRate);
  }

  /// 2. CYBER NEON: Synthwave Lazer Ateşi (Pew) + Siber İtici Frekansı
  static Uint8List _synthesizeCyberLaserPulse() {
    const sampleRate = 44100;
    const durationSec = 0.14;
    final numSamples = (sampleRate * durationSec).round();
    final samples = Int16List(numSamples);
    double laserPhase = 0.0;
    double thrusterPhase = 0.0;

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final env = math.pow(1.0 - t, 1.3).toDouble();
      // Hızlı lazer frekans düşüşü (1350Hz -> 240Hz)
      final laserFreq = 1350.0 * math.pow(0.18, t).toDouble();
      laserPhase += (2.0 * math.pi * laserFreq) / sampleRate;
      // Siber itici yükselişi (180Hz -> 520Hz)
      final thrusterFreq = 180.0 + 340.0 * t;
      thrusterPhase += (2.0 * math.pi * thrusterFreq) / sampleRate;

      final laserWave = math.sin(laserPhase) + 0.35 * math.sin(laserPhase * 2.0);
      final thrusterWave = math.sin(thrusterPhase * 2.0) * 0.45;
      final val = ((laserWave * 0.65 + thrusterWave * 0.35) / 1.35) * env * 0.44;
      samples[i] = (val.clamp(-1.0, 1.0) * 32767).round();
    }
    return _encodeWav(samples, sampleRate);
  }

  /// 3. SPACE ORBIT: Basınçlı İyon Jetpack Püskürtmesi (RCS Gaz & Kozmik Rezonans)
  static Uint8List _synthesizeSpaceIonThruster() {
    const sampleRate = 44100;
    const durationSec = 0.17;
    final numSamples = (sampleRate * durationSec).round();
    final samples = Int16List(numSamples);
    final rng = math.Random(108);
    double subPhase = 0.0;
    double bandNoise = 0.0;

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final attack = math.min(1.0, t * 7.0);
      final decay = math.pow(1.0 - t, 1.2).toDouble();
      final env = attack * decay;

      // İyon gaz püskürtme hışırtısı
      final white = rng.nextDouble() * 2.0 - 1.0;
      bandNoise = bandNoise * 0.78 + white * 0.22;

      // Kozmik manyetik alt-frekans (130Hz -> 260Hz)
      final freq = 130.0 + 130.0 * math.sin(t * math.pi * 0.8);
      subPhase += (2.0 * math.pi * freq) / sampleRate;
      final ionHum = math.sin(subPhase) * 0.55 + math.sin(subPhase * 1.5) * 0.25;

      final val = (bandNoise * 0.65 + ionHum * 0.55) * env * 0.46;
      samples[i] = (val.clamp(-1.0, 1.0) * 32767).round();
    }
    return _encodeWav(samples, sampleRate);
  }

  /// 4. 1453 CONQUEST: Kadırga Top Atışı Gürlemesi + Kürek ve Haliç Dalgası Sesi!
  static Uint8List _synthesizeConquestCannonAndOar() {
    const sampleRate = 44100;
    const durationSec = 0.22;
    final numSamples = (sampleRate * durationSec).round();
    final samples = Int16List(numSamples);
    final rng = math.Random(1453);
    double cannonPhase = 0.0;
    double waterState = 0.0;

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      // 1) Barut & Top Güllesi Patlaması (İlk 90ms güçlü sub-bass vuruşu: 125Hz -> 42Hz)
      final cannonEnv = math.pow(math.max(0.0, 1.0 - t * 1.6), 2.0).toDouble();
      final cannonFreq = 125.0 * math.pow(0.32, t).toDouble();
      cannonPhase += (2.0 * math.pi * cannonFreq) / sampleRate;
      final cannonBoom = math.sin(cannonPhase) * cannonEnv * 0.85;

      // 2) Kürek Çekişi ve Köpüklü Deniz Dalgası Şapırtısı (Low-pass su sesi)
      final splashEnv = math.sin(t * math.pi) * (1.0 - t * 0.35);
      final rawNoise = rng.nextDouble() * 2.0 - 1.0;
      waterState = waterState * 0.88 + rawNoise * 0.12;
      final waterSplash = waterState * splashEnv * 0.90;

      final val = (cannonBoom + waterSplash) * 0.56;
      samples[i] = (val.clamp(-1.0, 1.0) * 32767).round();
    }
    return _encodeWav(samples, sampleRate);
  }

  /// 1453 Şahi Topu Salvosu + Mehter Kös Davulu Gürlemesi
  static Uint8List _synthesizeSahiSalvo() {
    const sampleRate = 44100;
    const durationSec = 0.36;
    final numSamples = (sampleRate * durationSec).round();
    final samples = Int16List(numSamples);
    final rng = math.Random(14530529);
    double phase = 0.0;
    double lowNoise = 0.0;

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final env = math.pow(1.0 - t, 1.4).toDouble();
      final freq = 95.0 * math.pow(0.28, t).toDouble();
      phase += (2.0 * math.pi * freq) / sampleRate;
      final raw = rng.nextDouble() * 2.0 - 1.0;
      lowNoise = lowNoise * 0.84 + raw * 0.16;
      final val = (math.sin(phase) * 0.75 + lowNoise * 0.65) * env * 0.62;
      samples[i] = (val.clamp(-1.0, 1.0) * 32767).round();
    }
    return _encodeWav(samples, sampleRate);
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
      final env = math.sin(t * math.pi);
      final freq = startFreq + (endFreq - startFreq) * (t * t);
      phase += (2.0 * math.pi * freq) / sampleRate;
      final fundamental = math.sin(phase);
      final overtone = math.sin(phase * 2.0) * harmonicMix;
      final val =
          ((fundamental + overtone) / (1.0 + harmonicMix)) * env * volume;
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
        final env = (1.0 - localT * 0.75) *
            math.sin(math.min(1.0, localT * 8.0) * math.pi * 0.5);
        phase += (2.0 * math.pi * freq) / sampleRate;
        final sampleVal =
            (math.sin(phase) * 0.75 + math.sin(phase * 2.0) * 0.25) *
                env *
                volume;
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
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little);
    buffer.setUint16(22, 1, Endian.little);
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little);
    buffer.setUint16(32, 2, Endian.little);
    buffer.setUint16(34, 16, Endian.little);
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
