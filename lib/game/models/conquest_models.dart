import 'dart:math' as math;
import 'package:flutter/material.dart';

enum ConquestSupplyType {
  kizakShield, // Yağlı Kızak & Zırh: Çarpışmadan koruyan Fatih Kalkanı
  sahiPowder, // Şahi Barutu: 3'lü dev Şahi topu yaylım ateşi (duvarları bile yıkar!)
  fetihBanner, // Fetih Sancağı: +3 Fetih puanı
}

class ConquestDifficulty {
  final int stage;
  final String stageTitle;
  final double scrollSpeed;
  final double gapWidth;
  final double barrierSpacing;
  final double maxGapDelta;

  const ConquestDifficulty({
    required this.stage,
    required this.stageTitle,
    required this.scrollSpeed,
    required this.gapWidth,
    required this.barrierSpacing,
    required this.maxGapDelta,
  });

  static ConquestDifficulty fromScore(int score) {
    if (score < 7) {
      return const ConquestDifficulty(
        stage: 1,
        stageTitle: 'KARADAN HALİÇ\'E İNİŞ',
        scrollSpeed: 138.0,
        gapWidth: 150.0,
        barrierSpacing: 325.0,
        maxGapDelta: 95.0,
      );
    } else if (score < 18) {
      final p = (score - 7) / 11.0;
      return ConquestDifficulty(
        stage: 2,
        stageTitle: 'HALİÇ SULARINDA HÜCUM',
        scrollSpeed: 142.0 + p * 24.0,
        gapWidth: 146.0 - p * 14.0,
        barrierSpacing: 320.0 - p * 20.0,
        maxGapDelta: 110.0,
      );
    } else if (score < 34) {
      final p = (score - 18) / 16.0;
      return ConquestDifficulty(
        stage: 3,
        stageTitle: 'ZİNCİR KIRMA HAREKATI',
        scrollSpeed: 166.0 + p * 22.0,
        gapWidth: 132.0 - p * 12.0,
        barrierSpacing: 300.0 - p * 15.0,
        maxGapDelta: 125.0,
      );
    } else {
      final extra = ((score - 34) / 25.0).clamp(0.0, 1.0);
      return ConquestDifficulty(
        stage: 4,
        stageTitle: 'ALTIN BOYNUZ FETHİ (1453)',
        scrollSpeed: 188.0 + extra * 18.0,
        gapWidth: 120.0 - extra * 6.0, // Never narrower than 114px
        barrierSpacing: 285.0,
        maxGapDelta: 135.0,
      );
    }
  }
}

class OttomanGalley {
  static const double shoreWidth = 36.0;
  static const double hullWidth = 36.0;
  static const double hullHeight = 64.0;

  double x;
  double y;
  double vx;
  int steerDir; // 1 = Sancak (Right), -1 = İskele (Left)
  double bankAngle;
  double oarPhase;
  int chainsBroken;

  OttomanGalley({
    this.x = 220.0,
    this.y = 560.0,
    this.vx = 0.0,
    this.steerDir = 1,
    this.bankAngle = 0.0,
    this.oarPhase = 0.0,
    this.chainsBroken = 0,
  });

  void reset(double gameWidth, double gameHeight) {
    x = gameWidth * 0.5;
    y = gameHeight * 0.74;
    vx = 135.0;
    steerDir = 1;
    bankAngle = 0.0;
    oarPhase = 0.0;
    chainsBroken = 0;
  }

  /// Flips rudder direction (Sancak <-> İskele) or steers toward a forced side
  void tack([int? forcedDir]) {
    if (forcedDir != null) {
      steerDir = forcedDir;
    } else {
      steerDir = -steerDir;
    }
    vx = steerDir * 185.0;
  }

  void update(double dt, double gameWidth, double gameHeight) {
    y = gameHeight * 0.74;
    final minX = shoreWidth + hullWidth * 0.55;
    final maxX = gameWidth - shoreWidth - hullWidth * 0.55;

    final targetVx = steerDir * 190.0;
    vx += (targetVx - vx) * (8.0 * dt).clamp(0.0, 1.0);
    x += vx * dt;

    // Safe shoreline slipway bumpers: bounce gently instead of dying!
    if (x < minX) {
      x = minX;
      steerDir = 1;
      vx = 155.0;
    } else if (x > maxX) {
      x = maxX;
      steerDir = -1;
      vx = -155.0;
    }

    // Smooth visual banking angle proportional to horizontal speed
    final targetBank = (vx / 190.0) * 0.22;
    bankAngle += (targetBank - bankAngle) * (10.0 * dt).clamp(0.0, 1.0);

    // Oar rowing animation
    oarPhase = (oarPhase + dt * 9.5) % (2 * math.pi);
  }

  Rect getHitBox() {
    // Forgiving central hull hitbox
    return Rect.fromCenter(
      center: Offset(x, y),
      width: 24.0,
      height: 44.0,
    );
  }
}

class Cannonball {
  double x;
  double y;
  final double vx;
  final double vy;
  final bool isSahi;

  Cannonball({
    required this.x,
    required this.y,
    this.vx = 0.0,
    this.vy = -560.0,
    this.isSahi = false,
  });

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
  }

  Rect getHitBox() {
    final size = isSahi ? 22.0 : 14.0;
    return Rect.fromCenter(center: Offset(x, y), width: size, height: size);
  }
}

class SeaBarrier {
  double y;
  final double gapLeft;
  final double gapRight;
  bool hasChain; // Destructible Haliç Iron Chain stretched across the gap
  bool passed;
  bool shattered;

  SeaBarrier({
    required this.y,
    required this.gapLeft,
    required this.gapRight,
    this.hasChain = false,
    this.passed = false,
    this.shattered = false,
  });

  static const double wallThickness = 32.0;

  bool isShipAligned(double shipX) {
    const margin = 12.0;
    return (shipX - margin) >= gapLeft && (shipX + margin) <= gapRight;
  }

  Rect getLeftWallRect() {
    return Rect.fromLTWH(0, y - wallThickness / 2, gapLeft, wallThickness);
  }

  Rect getRightWallRect(double gameWidth) {
    return Rect.fromLTWH(
      gapRight,
      y - wallThickness / 2,
      math.max(0.0, gameWidth - gapRight),
      wallThickness,
    );
  }

  Rect getChainTargetRect() {
    return Rect.fromLTRB(
      gapLeft - 8,
      y - 22,
      gapRight + 8,
      y + 22,
    );
  }

  bool collidesWithWall(Rect hitbox, double gameWidth) {
    if (shattered) return false;
    return hitbox.overlaps(getLeftWallRect()) ||
        hitbox.overlaps(getRightWallRect(gameWidth));
  }

  bool collidesWithShip(Rect shipHitbox, double gameWidth) {
    if (shattered) return false;
    if (collidesWithWall(shipHitbox, gameWidth)) return true;
    if (hasChain) {
      final chainRect = Rect.fromLTRB(gapLeft, y - 8, gapRight, y + 8);
      if (shipHitbox.overlaps(chainRect)) return true;
    }
    return false;
  }
}

class EnemyFireShip {
  double x;
  double y;
  final double baseX;
  final double phase;
  bool destroyed = false;
  double _animTime = 0.0;

  EnemyFireShip({
    required this.x,
    required this.y,
    required this.phase,
  }) : baseX = x;

  void update(double dt, double scrollSpeed, double minX, double maxX) {
    _animTime += dt;
    y += scrollSpeed * 1.05 * dt;
    x = (baseX + math.sin(_animTime * 2.6 + phase) * 28.0).clamp(minX, maxX);
  }

  Rect getHitBox() {
    return Rect.fromCenter(center: Offset(x, y), width: 28, height: 36);
  }
}

class ConquestSupply {
  double x;
  double y;
  final ConquestSupplyType type;
  bool collected = false;
  double _pulse = 0.0;

  ConquestSupply({
    required this.x,
    required this.y,
    required this.type,
  });

  double get pulseScale => 1.0 + math.sin(_pulse * 5.0) * 0.12;

  void update(double dt, double scrollSpeed) {
    _pulse += dt;
    y += scrollSpeed * dt;
  }

  Rect getHitBox() {
    return Rect.fromCenter(center: Offset(x, y), width: 34, height: 34);
  }
}
