import 'package:flutter/material.dart';

@immutable
class DifficultyConfig {
  final int level;
  final String levelTitle;
  final double pipeSpeed;
  final double pipeGap;
  final double pipeSpacing;
  final double maxGapDelta;

  const DifficultyConfig({
    required this.level,
    required this.levelTitle,
    required this.pipeSpeed,
    required this.pipeGap,
    required this.pipeSpacing,
    required this.maxGapDelta,
  });
}

class GameConstants {
  const GameConstants._();

  // Sanal (Mantıksal) Oyun Koordinat Sistemi (Responsive Ölçekleme Referansı)
  // Tüm fizik, engel aralıkları ve çarpışma kutuları bu sabit mantıksal çözünürlükte
  // çalışır; FittedBox + LayoutBuilder ile her ekran boyutuna kayıpsız ölçeklenir.
  static const double worldWidth = 400.0;
  static const double logicalStandardWidth = 430.0;
  static const double logicalWideWidth = 560.0;
  static const double logicalHeight = 820.0;

  static const double groundHeight = 112.0;
  static const double grassHeight = 16.0;

  // Fizik Sabitleri (Mantıksal birim / saniye)
  static const double gravity = 820.0;
  static const double jumpVelocity = -300.0;
  static const double maxFallSpeed = 480.0;

  // Önceden oluşturulmuş (Pre-allocated) const zorluk seviyeleri (GC baskısını önler)
  static const DifficultyConfig _tier1 = DifficultyConfig(
    level: 1,
    levelTitle: 'BAŞLANGIÇ',
    pipeSpeed: 142.0,
    pipeGap: 196.0,
    pipeSpacing: 250.0,
    maxGapDelta: 85.0,
  );

  static const DifficultyConfig _tier2 = DifficultyConfig(
    level: 2,
    levelTitle: 'SEVİYE 2 ⚡',
    pipeSpeed: 152.0,
    pipeGap: 184.0,
    pipeSpacing: 238.0,
    maxGapDelta: 100.0,
  );

  static const DifficultyConfig _tier3 = DifficultyConfig(
    level: 3,
    levelTitle: 'SEVİYE 3 🔥',
    pipeSpeed: 162.0,
    pipeGap: 172.0,
    pipeSpacing: 226.0,
    maxGapDelta: 115.0,
  );

  static const DifficultyConfig _tier4 = DifficultyConfig(
    level: 4,
    levelTitle: 'USTA 🏆',
    pipeSpeed: 172.0,
    pipeGap: 162.0,
    pipeSpacing: 215.0,
    maxGapDelta: 128.0,
  );

  static DifficultyConfig getDifficulty(int score) {
    if (score < 6) return _tier1;
    if (score < 13) return _tier2;
    if (score < 25) return _tier3;
    return _tier4;
  }

  // Test ve varsayılan referans sabitleri
  static const double pipeSpeed = 142.0;
  static const double pipeGap = 196.0;
  static const double pipeSpacing = 250.0;

  // Kuş Boyutları
  static const double birdWidth = 42.0;
  static const double birdHeight = 30.0;
  static const double birdRadius = 16.0;

  // Boru Boyutları
  static const double pipeWidth = 64.0;
  static const double pipeCapHeight = 26.0;
  static const double pipeCapExtraWidth = 8.0;
  static const double minPipeHeight = 55.0;

  // Renk Paleti
  static const Color skyColorTop = Color(0xFF4EC0CA);
  static const Color skyColorBottom = Color(0xFF90E0EF);

  static const Color pipeBodyColor = Color(0xFF73BF2E);
  static const Color pipeHighlightColor = Color(0xFFA6EE38);
  static const Color pipeShadowColor = Color(0xFF559C1A);
  static const Color pipeBorderColor = Color(0xFF2E4613);

  static const Color groundGrassColor1 = Color(0xFF73BF2E);
  static const Color groundGrassColor2 = Color(0xFF8DE146);
  static const Color groundDirtColor = Color(0xFFDED895);
  static const Color groundBorderColor = Color(0xFF53821C);

  static const Color birdBodyColor = Color(0xFFF7CF34);
  static const Color birdBodyShadowColor = Color(0xFFE5B01E);
  static const Color birdBellyColor = Color(0xFFF85820);
  static const Color birdWingColor = Color(0xFFFFFFFF);
  static const Color birdWingShadowColor = Color(0xFFE6E6E6);
  static const Color birdBeakColor = Color(0xFFF84820);
  static const Color birdBeakHighlightColor = Color(0xFFFA7044);
  static const Color birdOutlineColor = Color(0xFF2C2416);
}
