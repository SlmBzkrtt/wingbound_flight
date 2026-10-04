import 'dart:math' as math;
import 'package:flutter/material.dart';

enum CosmicPowerType {
  plasmaShield, // Plazma Kalkanı: Çarpışmaya karşı enerji zırhı
  starCrystal, // Yıldız Kristali: +3 Kozmik puan
  timeDilation, // Zaman Bükülmesi: Kütleçekimsel zaman yavaşlatma
}

class SpaceOrbitDifficulty {
  final int stage;
  final String stageTitle;
  final double angularSpeed; // Radians per second
  final double gapSize; // Radial opening size in pixels
  final double gateSpacingAngle; // Radians between consecutive gates
  final double maxGapDelta; // Max radial shift between consecutive gates

  const SpaceOrbitDifficulty({
    required this.stage,
    required this.stageTitle,
    required this.angularSpeed,
    required this.gapSize,
    required this.gateSpacingAngle,
    required this.maxGapDelta,
  });

  static SpaceOrbitDifficulty fromScore(int score) {
    if (score < 6) {
      // Stage 1: Calm outer orbit, wide portals
      return const SpaceOrbitDifficulty(
        stage: 1,
        stageTitle: 'DIŞ YÖRÜNGE (KOLAY)',
        angularSpeed: 0.70,
        gapSize: 88.0,
        gateSpacingAngle: math.pi * 0.90, // 162° apart
        maxGapDelta: 50.0,
      );
    } else if (score < 16) {
      // Stage 2: Accretion gravitational pull
      final progress = (score - 6) / 10.0;
      return SpaceOrbitDifficulty(
        stage: 2,
        stageTitle: 'ÇEKİM ALANI',
        angularSpeed: 0.72 + progress * 0.12, // 0.72 -> 0.84
        gapSize: 86.0 - progress * 8.0, // 86 -> 78
        gateSpacingAngle: math.pi * (0.88 - progress * 0.10),
        maxGapDelta: 58.0,
      );
    } else if (score < 32) {
      // Stage 3: Event Horizon Edge
      final progress = (score - 16) / 16.0;
      return SpaceOrbitDifficulty(
        stage: 3,
        stageTitle: 'OLAY UFKU SINIRI',
        angularSpeed: 0.84 + progress * 0.12, // 0.84 -> 0.96
        gapSize: 78.0 - progress * 8.0, // 78 -> 70
        gateSpacingAngle: math.pi * (0.78 - progress * 0.08),
        maxGapDelta: 65.0,
      );
    } else {
      // Stage 4: Singularity Vortex
      final extra = ((score - 32) / 25.0).clamp(0.0, 1.0);
      return SpaceOrbitDifficulty(
        stage: 4,
        stageTitle: 'TEKİLLİK GİRDABI',
        angularSpeed: 0.96 + extra * 0.10, // Caps at 1.06 rad/s
        gapSize: 70.0 - extra * 4.0, // Never smaller than 66px
        gateSpacingAngle: math.pi * 0.68, // ~122° apart
        maxGapDelta: 72.0,
      );
    }
  }
}

class SpaceExplorer {
  static const double minRadius = 82.0;
  static const double maxRadius = 242.0;
  static const double defaultRadius = 156.0;
  // Starting angle at Warp Portal line (bottom-right: ~pi/4)
  static const double startAngle = math.pi * 0.25;

  double angle; // Radians, decreases for counter-clockwise orbit around Black Hole
  double radius; // Distance from Black Hole Singularity center
  double radialVelocity;
  int thrusterFrame;
  double _thrusterTimer = 0.0;
  double totalAngleTraversed = 0.0;
  int orbitsCompleted = 0; // 1 Orbit = 1 full 360° circle around the Black Hole

  SpaceExplorer({
    this.angle = startAngle,
    this.radius = defaultRadius,
    this.radialVelocity = 0.0,
    this.thrusterFrame = 0,
  });

  void reset() {
    angle = startAngle;
    radius = defaultRadius;
    radialVelocity = 0.0;
    thrusterFrame = 0;
    _thrusterTimer = 0.0;
    totalAngleTraversed = 0.0;
    orbitsCompleted = 0;
  }

  void thrustOutward() {
    // Firing jetpack thrusters pushes the explorer outward against black hole gravity
    radialVelocity = 205.0;
  }

  void update(double dt, double angularSpeed) {
    // Counter-clockwise orbit around the Black Hole
    final dAngle = angularSpeed * dt;
    angle -= dAngle;
    totalAngleTraversed += dAngle;

    // Gravitational pull inward toward the Event Horizon
    radialVelocity -= 275.0 * dt;
    if (radialVelocity < -155.0) {
      radialVelocity = -155.0;
    }

    radius += radialVelocity * dt;

    // Keep explorer within the safe orbital accretion rings
    if (radius < minRadius) {
      radius = minRadius;
      radialVelocity = 0.0;
    } else if (radius > maxRadius) {
      radius = maxRadius;
      radialVelocity = -15.0;
    }

    // Jetpack thruster pulse animation
    _thrusterTimer += dt;
    if (_thrusterTimer >= 0.10) {
      _thrusterTimer = 0.0;
      thrusterFrame = (thrusterFrame + 1) % 4;
    }
  }

  Offset getPosition(Offset center) {
    return Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
  }
}

class OrbitGate {
  double angle; // Radial angle on the accretion orbit ring
  final double gapInnerRadius;
  final double gapOuterRadius;
  bool passed;
  bool shattered;

  OrbitGate({
    required this.angle,
    required this.gapInnerRadius,
    required this.gapOuterRadius,
    this.passed = false,
    this.shattered = false,
  });

  bool isRadiusAligned(double explorerRadius) {
    const margin = 5.5;
    return (explorerRadius - margin) >= gapInnerRadius &&
        (explorerRadius + margin) <= gapOuterRadius;
  }

  // Checks if the space explorer collides with the inner or outer asteroid/laser pylons
  bool collidesWith(double explorerAngle, double explorerRadius) {
    if (shattered) return false;

    // Normalize angular difference to [-pi, pi]
    double diff = (explorerAngle - angle) % (2 * math.pi);
    if (diff > math.pi) diff -= 2 * math.pi;
    if (diff < -math.pi) diff += 2 * math.pi;

    // Forgiving angular thickness of the barrier (~0.082 radians)
    if (diff.abs() < 0.082) {
      const explorerMargin = 5.5;
      final hitsInnerPylon = (explorerRadius - explorerMargin) < gapInnerRadius;
      final hitsOuterPylon = (explorerRadius + explorerMargin) > gapOuterRadius;
      return hitsInnerPylon || hitsOuterPylon;
    }
    return false;
  }

  // Checks if explorer has just crossed this gate counter-clockwise
  bool isCrossedBy(double explorerAngle) {
    double diff = (angle - explorerAngle) % (2 * math.pi);
    if (diff > math.pi) diff -= 2 * math.pi;
    if (diff < -math.pi) diff += 2 * math.pi;
    return diff > 0.10 && diff < 0.65;
  }
}

class CosmicPowerUp {
  double angle;
  double radius;
  final CosmicPowerType type;
  bool collected;
  double _pulseTimer = 0.0;

  CosmicPowerUp({
    required this.angle,
    required this.radius,
    required this.type,
    this.collected = false,
  });

  double get pulseScale => 1.0 + math.sin(_pulseTimer * 5.0) * 0.14;

  void update(double dt) {
    _pulseTimer += dt;
  }

  Offset getPosition(Offset center) {
    return Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
  }
}
