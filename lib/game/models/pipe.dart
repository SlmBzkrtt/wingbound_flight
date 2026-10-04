import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game_constants.dart';

class PipePair {
  double x;
  double topHeight;
  double bottomHeight;
  final double gap;
  bool passed;
  bool shattered;
  bool isPortal; // If true, renders as a Cyber Warp Ring!

  final double baseTopHeight;
  final double moveSpeed;
  final double moveAmplitude;
  
  bool hasLaser;
  double laserTimer;
  bool laserActive;

  PipePair({
    required this.x,
    required this.topHeight,
    required this.bottomHeight,
    this.gap = GameConstants.pipeGap,
    this.passed = false,
    this.shattered = false,
    this.isPortal = false,
    double? baseTopHeight,
    this.moveSpeed = 0.0,
    this.moveAmplitude = 0.0,
    this.hasLaser = false,
  }) : baseTopHeight = baseTopHeight ?? topHeight,
       laserTimer = 0.0,
       laserActive = true;

  void updateMovement(double time, double playableHeight, double dt) {
    if (hasLaser) {
      laserTimer += dt;
      // 1.8s active, 1.2s warning/recharge cycle, or player can shoot it any time!
      if (laserActive && laserTimer > 1.8) {
        laserTimer = 0.0;
        laserActive = false;
      } else if (!laserActive && laserTimer > 1.2) {
        laserTimer = 0.0;
        laserActive = true;
      }
    }

    if (moveAmplitude <= 0) return;
    final delta = math.sin(time * moveSpeed + x * 0.015) * moveAmplitude;
    final minTop = GameConstants.minPipeHeight;
    final maxTop = playableHeight - gap - GameConstants.minPipeHeight;
    topHeight = (baseTopHeight + delta).clamp(minTop, maxTop);
    bottomHeight = playableHeight - topHeight - gap;
  }

  // Generous hitbox for player shots to destroy the laser gate in the gap
  Rect getLaserTargetRect() {
    return Rect.fromLTWH(
      x,
      topHeight,
      GameConstants.pipeWidth,
      gap,
    );
  }

  // Portal center
  Offset getPortalCenter() {
    return Offset(x + GameConstants.pipeWidth / 2, topHeight + gap / 2);
  }

  // Top pipe body rect
  Rect getTopBodyRect() {
    return Rect.fromLTWH(
      x,
      0,
      GameConstants.pipeWidth,
      math.max(0.0, topHeight - GameConstants.pipeCapHeight),
    );
  }

  // Top pipe cap rect (mouth of top pipe)
  Rect getTopCapRect() {
    return Rect.fromLTWH(
      x - GameConstants.pipeCapExtraWidth / 2,
      topHeight - GameConstants.pipeCapHeight,
      GameConstants.pipeWidth + GameConstants.pipeCapExtraWidth,
      GameConstants.pipeCapHeight,
    );
  }

  // Bottom pipe cap rect (mouth of bottom pipe)
  Rect getBottomCapRect(double gameHeight) {
    final bottomPipeTop = topHeight + gap;
    return Rect.fromLTWH(
      x - GameConstants.pipeCapExtraWidth / 2,
      bottomPipeTop,
      GameConstants.pipeWidth + GameConstants.pipeCapExtraWidth,
      GameConstants.pipeCapHeight,
    );
  }

  // Bottom pipe body rect
  Rect getBottomBodyRect(double gameHeight) {
    final bottomPipeTop = topHeight + gap + GameConstants.pipeCapHeight;
    final usableBottom = gameHeight - GameConstants.groundHeight;
    return Rect.fromLTWH(
      x,
      bottomPipeTop,
      GameConstants.pipeWidth,
      math.max(0.0, usableBottom - bottomPipeTop),
    );
  }

  // Check collision with bird bounding box
  bool collidesWithBody(Rect rect, double gameHeight) {
    if (shattered || isPortal) return false;

    final topBody = getTopBodyRect();
    final topCap = getTopCapRect();
    final bottomCap = getBottomCapRect(gameHeight);
    final bottomBody = getBottomBodyRect(gameHeight);

    return rect.overlaps(topBody) ||
        rect.overlaps(topCap) ||
        rect.overlaps(bottomCap) ||
        rect.overlaps(bottomBody);
  }

  bool collidesWithLaser(Rect rect) {
    if (shattered || isPortal || !hasLaser || !laserActive) return false;
    final laserRect = Rect.fromLTWH(
      x + GameConstants.pipeWidth / 2 - 4,
      topHeight + 4,
      8,
      gap - 8,
    );
    return rect.overlaps(laserRect);
  }

  // Check collision with bird bounding box or circle
  bool collidesWith(Rect birdRect, double gameHeight) {
    if (collidesWithBody(birdRect, gameHeight)) return true;
    if (collidesWithLaser(birdRect)) return true;
    return false;
  }
}

class LaserBolt {
  double x;
  double y;
  final bool isHeavy; // true = Blaster Overdrive (breaks pipes), false = Standard Plasma (breaks lasers & drones)

  LaserBolt({
    required this.x,
    required this.y,
    this.isHeavy = false,
  });

  Rect getHitBox() {
    return Rect.fromCenter(
      center: Offset(x, y),
      width: isHeavy ? 24.0 : 18.0,
      height: isHeavy ? 14.0 : 12.0,
    );
  }
}

class EnemyDrone {
  double x;
  double baseY;
  double y;
  double phase;
  bool destroyed;

  EnemyDrone({
    required this.x,
    required this.baseY,
    this.phase = 0.0,
    this.destroyed = false,
  }) : y = baseY;

  void update(double dt, double speed) {
    x -= (speed * 1.18) * dt;
    phase += dt * 4.2;
    y = baseY + math.sin(phase) * 32.0;
  }

  Rect getHitBox() {
    return Rect.fromCenter(
      center: Offset(x, y),
      width: 34.0,
      height: 28.0,
    );
  }
}
