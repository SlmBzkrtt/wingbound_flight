import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game_constants.dart';
import '../models/bird.dart';
import '../models/particle.dart';
import '../models/pipe.dart';
import '../models/power_up.dart';

// 1. Synthwave Cyberpunk Background
class CyberBackgroundPainter extends CustomPainter {
  final bool warpSpeedActive;

  static final Paint _skyPaint = Paint();
  static Size? _cachedSkySize;

  const CyberBackgroundPainter({
    this.warpSpeedActive = false,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final groundY = size.height - GameConstants.groundHeight;

    // Sky Gradient (Deep space purple to neon magenta horizon)
    final skyRect = Rect.fromLTWH(0, 0, size.width, groundY);
    if (_cachedSkySize != size) {
      _cachedSkySize = size;
      _skyPaint.shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF090618),
          Color(0xFF1E0A3C),
          Color(0xFF4A1054),
        ],
      ).createShader(skyRect);
    }
    canvas.drawRect(skyRect, _skyPaint);

    // Distant Stars / Light-Speed Streaks if Warp Active
    if (warpSpeedActive) {
      final warpPaint = Paint()
        ..color = const Color(0xFF00F3FF).withValues(alpha: 0.8)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < 40; i++) {
        final sx = ((i * 53) % size.width);
        final sy = ((i * 37) % (groundY * 0.9));
        canvas.drawLine(Offset(sx, sy), Offset(sx - 45, sy), warpPaint);
      }
    } else {
      final starPaint = Paint()..color = Colors.white70;
      for (int i = 0; i < 35; i++) {
        final sx = ((i * 47) % size.width);
        final sy = ((i * 31) % (groundY * 0.65));
        final radius = (i % 3 == 0) ? 1.8 : 1.0;
        canvas.drawCircle(Offset(sx, sy), radius, starPaint);
      }
    }

    // Giant Synthwave Retro Sun with Neon Corona Halo
    final sunCenter = Offset(size.width * 0.5, groundY - 52);
    const sunRadius = 62.0;
    final sunRect = Rect.fromCircle(center: sunCenter, radius: sunRadius);

    final sunGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFFEE55),
        Color(0xFFFF6D00),
        Color(0xFFFF007F),
      ],
    );

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, groundY));
    canvas.drawCircle(
      sunCenter,
      sunRadius + 22,
      Paint()
        ..color = const Color(0x55FF007F)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24.0),
    );
    canvas.drawCircle(sunCenter, sunRadius, Paint()..shader = sunGradient.createShader(sunRect));

    // Retro scanline stripes cutting through the bottom half of the sun
    final cutPaint = Paint()..color = const Color(0xFF1E0A3C);
    for (double y = sunCenter.dy - 5; y < sunCenter.dy + sunRadius; y += 9) {
      final stripeHeight = ((y - (sunCenter.dy - 10)) / 14).clamp(1.5, 4.5);
      canvas.drawRect(
        Rect.fromLTWH(sunCenter.dx - sunRadius - 5, y, (sunRadius + 5) * 2, stripeHeight),
        cutPaint,
      );
    }

    // Distant Synthwave Neon Wireframe Mountains
    const mSpan = 220.0;
    const mStart = -mSpan;
    final mFill = Paint()..color = const Color(0xFF160B30);
    final mStroke = Paint()
      ..color = const Color(0x99B388FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (double mx = mStart; mx < size.width + mSpan; mx += mSpan) {
      final mPath = Path()
        ..moveTo(mx, groundY)
        ..lineTo(mx + 80, groundY - 175)
        ..lineTo(mx + 145, groundY - 115)
        ..lineTo(mx + 195, groundY - 185)
        ..lineTo(mx + mSpan + 20, groundY)
        ..close();
      canvas.drawPath(mPath, mFill);
      canvas.drawPath(mPath, mStroke);
    }

    // Flying Cyber Traffic Light Streaks in the Sky (static positions)
    final trafficPaintCyan = Paint()
      ..color = const Color(0xCC00F3FF)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final trafficPaintPink = Paint()
      ..color = const Color(0xCCFF007F)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    for (int t = 0; t < 4; t++) {
      final tx = size.width * 0.15 + t * (size.width * 0.22);
      final ty = groundY - 155 - t * 34.0;
      canvas.drawLine(
        Offset(tx, ty),
        Offset(tx + 22, ty),
        t.isEven ? trafficPaintCyan : trafficPaintPink,
      );
    }
    canvas.restore();

    // Cyber Skyscrapers with glowing cyan/pink windows & rooftop spires
    _drawCyberCity(canvas, size, groundY);
  }

  void _drawCyberCity(Canvas canvas, Size size, double groundY) {
    final buildingPaint = Paint()..color = const Color(0xFF120E2E);
    final neonLinePaint = Paint()
      ..color = const Color(0xFF00F3FF).withValues(alpha: 0.75)
      ..strokeWidth = 1.8;
    final windowPaint = Paint()..color = const Color(0xFFFF007F).withValues(alpha: 0.75);
    final cyanWindowPaint = Paint()..color = const Color(0xFF00F3FF).withValues(alpha: 0.70);

    const buildings = [
      [42.0, 90.0],
      [56.0, 134.0],
      [36.0, 75.0],
      [64.0, 154.0],
      [48.0, 112.0],
      [52.0, 128.0],
      [38.0, 85.0],
    ];

    double patternWidth = 0;
    for (final b in buildings) {
      patternWidth += b[0] + 8;
    }

    final startX = -patternWidth;

    for (double shift = startX; shift < size.width + patternWidth; shift += patternWidth) {
      double currentX = shift;
      for (int i = 0; i < buildings.length; i++) {
        final b = buildings[i];
        final w = b[0];
        final h = b[1];
        final top = groundY - h;

        final rect = Rect.fromLTWH(currentX, top, w, h);
        canvas.drawRect(rect, buildingPaint);

        canvas.drawLine(
          Offset(currentX, top),
          Offset(currentX + w, top),
          neonLinePaint,
        );

        // Cyber antenna spire on tall towers
        if (i.isOdd) {
          final cx = currentX + w * 0.5;
          canvas.drawLine(Offset(cx, top), Offset(cx, top - 16), neonLinePaint);
          canvas.drawCircle(Offset(cx, top - 17), 2.5, windowPaint);
        }

        int wIdx = 0;
        for (double wy = top + 14; wy < groundY - 16; wy += 18) {
          for (double wx = currentX + 8; wx < currentX + w - 8; wx += 12) {
            wIdx++;
            canvas.drawRect(
              Rect.fromLTWH(wx, wy, 4, 7),
              (wIdx + i) % 3 == 0 ? cyanWindowPaint : windowPaint,
            );
          }
        }

        currentX += w + 8;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CyberBackgroundPainter oldDelegate) {
    return oldDelegate.warpSpeedActive != warpSpeedActive;
  }
}

// 2. Cyber Laser Grid Ground
class CyberGroundPainter extends CustomPainter {
  final double groundOffset;

  const CyberGroundPainter({required this.groundOffset, super.repaint});

  @override
  void paint(Canvas canvas, Size size) {
    final groundY = size.height - GameConstants.groundHeight;
    final totalWidth = size.width;

    // Dark cyber platform floor
    final floorRect = Rect.fromLTWH(0, groundY, totalWidth, GameConstants.groundHeight);
    final floorPaint = Paint()..color = const Color(0xFF0C091C);
    canvas.drawRect(floorRect, floorPaint);

    // Glowing Neon Cyan Horizon Line
    final glowPaint = Paint()
      ..color = const Color(0xFF00F3FF)
      ..strokeWidth = 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);
    canvas.drawLine(Offset(0, groundY), Offset(totalWidth, groundY), glowPaint);

    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, groundY), Offset(totalWidth, groundY), linePaint);

    // Moving Cyber Wireframe Grid Lines
    final gridLinePaint = Paint()
      ..color = const Color(0xFFFF007F).withValues(alpha: 0.6)
      ..strokeWidth = 2.0;

    const spacing = 36.0;
    final normalizedOffset = groundOffset % spacing;

    for (double x = -spacing - normalizedOffset; x < totalWidth + spacing; x += spacing) {
      canvas.drawLine(
        Offset(x, groundY),
        Offset(x - 20, size.height),
        gridLinePaint,
      );
    }

    // Horizontal cyber grid tiers
    final subLinePaint = Paint()
      ..color = const Color(0xFF00F3FF).withValues(alpha: 0.35)
      ..strokeWidth = 1.5;
    for (double y = groundY + 18; y < size.height; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(totalWidth, y), subLinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CyberGroundPainter oldDelegate) {
    return oldDelegate.groundOffset != groundOffset;
  }
}

// 3. Cyber Mecha Bird with Tron Tail Trail, Visor, Shield, Projectiles & Drones
class CyberBirdPainter extends CustomPainter {
  final Bird bird;
  final bool hasShield;
  final bool isInvulnerable;
  final List<Offset> trailPositions;
  final double empRadius;
  final List<LaserBolt> projectiles;
  final List<EnemyDrone> drones;
  final int skinIndex;

  const CyberBirdPainter({
    required this.bird,
    this.hasShield = false,
    this.isInvulnerable = false,
    this.trailPositions = const [],
    this.empRadius = 0.0,
    this.projectiles = const [],
    this.drones = const [],
    this.skinIndex = 0,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final primaryNeon = skinIndex == 1
        ? const Color(0xFF00E676)
        : skinIndex == 2
            ? const Color(0xFFFFD54F)
            : const Color(0xFF00F3FF);
    final secondaryNeon = skinIndex == 1
        ? const Color(0xFFB388FF)
        : skinIndex == 2
            ? const Color(0xFFFF3D00)
            : const Color(0xFFFF007F);

    // Draw Enemy Cyber Drones
    for (final drone in drones) {
      if (drone.destroyed) continue;
      _drawEnemyDrone(canvas, Offset(drone.x, drone.y), drone.phase);
    }

    // Draw Projectiles (Standard Cyan Plasma vs Heavy Pink Blaster)
    for (final bolt in projectiles) {
      final p = Offset(bolt.x, bolt.y);
      final color = bolt.isHeavy ? secondaryNeon : primaryNeon;
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 5.0);
      final corePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(p, bolt.isHeavy ? 6.0 : 4.5, glowPaint);
      canvas.drawCircle(p, bolt.isHeavy ? 4.0 : 3.0, corePaint);
      canvas.drawCircle(p, 1.5, Paint()..color = Colors.white);

      canvas.drawLine(
        Offset(p.dx - (bolt.isHeavy ? 18 : 13), p.dy),
        p,
        Paint()
          ..color = color
          ..strokeWidth = bolt.isHeavy ? 3.5 : 2.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // 0. Draw EMP Shockwave if expanding
    if (empRadius > 0.0) {
      final shockwavePaint = Paint()
        ..color = primaryNeon.withValues(alpha: (1.0 - (empRadius / 380.0)).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 8.0);
      canvas.drawCircle(Offset(bird.x, bird.y), empRadius, shockwavePaint);
    }

    // 1. Draw Tron Neon Light Trail behind bird
    if (trailPositions.length > 2) {
      for (int i = 0; i < trailPositions.length - 1; i++) {
        final progress = i / trailPositions.length; // 0 to 1
        final trailPaint = Paint()
          ..color = primaryNeon.withValues(alpha: progress * 0.65)
          ..strokeWidth = progress * 4.0 + 1.2
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(trailPositions[i], trailPositions[i + 1], trailPaint);
      }
    }

    canvas.save();
    canvas.translate(bird.x, bird.y);
    canvas.rotate(bird.rotation);

    // Invulnerability flashing aura
    if (isInvulnerable) {
      final invulnPaint = Paint()
        ..color = primaryNeon.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);
      canvas.drawCircle(Offset.zero, 28, invulnPaint);
    }

    // Active Hex Shield if present
    if (hasShield) {
      final shieldGlowPaint = Paint()
        ..color = primaryNeon.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 5.0);

      final shieldFillPaint = Paint()
        ..color = primaryNeon.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset.zero, 25, shieldFillPaint);
      canvas.drawCircle(Offset.zero, 25, shieldGlowPaint);

      final hexPaint = Paint()
        ..color = Colors.white70
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset.zero, 24, hexPaint);
    }

    // Thruster Flame at back (-16, 0)
    final thrusterPath = Path()
      ..moveTo(-16, -4)
      ..lineTo(-26, 0)
      ..lineTo(-16, 4)
      ..close();
    final thrusterPaint = Paint()..color = secondaryNeon;
    canvas.drawPath(thrusterPath, thrusterPaint);

    final innerFlamePaint = Paint()..color = primaryNeon;
    final innerFlame = Path()
      ..moveTo(-16, -2)
      ..lineTo(-22, 0)
      ..lineTo(-16, 2)
      ..close();
    canvas.drawPath(innerFlame, innerFlamePaint);

    // Titanium Metallic Body
    final bodyPaint = Paint()..color = const Color(0xFF1E2430);
    final borderPaint = Paint()
      ..color = primaryNeon
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final bodyRect = Rect.fromCenter(center: const Offset(-1, 0), width: 34, height: 26);
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, const Radius.circular(12));
    canvas.drawRRect(bodyRRect, bodyPaint);
    canvas.drawRRect(bodyRRect, borderPaint);

    // Cybernetic Wing
    final wingPaint = Paint()..color = secondaryNeon;
    final wingPath = Path();
    if (bird.wingFrame == 1) {
      wingPath
        ..moveTo(-8, -2)
        ..lineTo(-18, -15)
        ..lineTo(-5, -3)
        ..close();
    } else if (bird.wingFrame == 2) {
      wingPath
        ..moveTo(-8, 2)
        ..lineTo(-18, 15)
        ..lineTo(-5, 3)
        ..close();
    } else {
      wingPath
        ..moveTo(-4, 0)
        ..lineTo(-18, -4)
        ..lineTo(-16, 4)
        ..close();
    }
    canvas.drawPath(wingPath, wingPaint);

    // Glowing Neon Visor Eye
    final visorPaint = Paint()..color = const Color(0xFF00F3FF);
    final visorRect = Rect.fromLTWH(5, -7, 10, 6);
    canvas.drawRRect(RRect.fromRectAndRadius(visorRect, const Radius.circular(3)), visorPaint);

    final visorLine = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5;
    canvas.drawLine(const Offset(6, -4), const Offset(13, -4), visorLine);

    // Cyber Beak
    final beakPaint = Paint()..color = const Color(0xFFFFB300);
    final beakPath = Path()
      ..moveTo(8, -1)
      ..lineTo(19, 2)
      ..lineTo(7, 6)
      ..close();
    canvas.drawPath(beakPath, beakPaint);

    final laserTip = Paint()..color = const Color(0xFFFF007F);
    canvas.drawCircle(const Offset(19, 2), 2.2, laserTip);

    canvas.restore();
  }

  void _drawEnemyDrone(Canvas canvas, Offset center, double phase) {
    // Red aura glow
    final auraPaint = Paint()
      ..color = const Color(0xFFFF1744).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 8.0);
    canvas.drawCircle(center, 18, auraPaint);

    // Outer metallic shell
    final hullPaint = Paint()..color = const Color(0xFF1A1426);
    final hullBorder = Paint()
      ..color = const Color(0xFFFF1744)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final hullPath = Path()
      ..moveTo(center.dx - 16, center.dy)
      ..lineTo(center.dx - 6, center.dy - 12)
      ..lineTo(center.dx + 12, center.dy - 9)
      ..lineTo(center.dx + 16, center.dy)
      ..lineTo(center.dx + 12, center.dy + 9)
      ..lineTo(center.dx - 6, center.dy + 12)
      ..close();
    canvas.drawPath(hullPath, hullPaint);
    canvas.drawPath(hullPath, hullBorder);

    // Glowing red cyclops scanner eye facing left
    final eyePaint = Paint()..color = const Color(0xFFFF1744);
    canvas.drawCircle(Offset(center.dx - 5, center.dy), 4.5, eyePaint);
    canvas.drawCircle(Offset(center.dx - 6, center.dy - 1), 1.8, Paint()..color = Colors.white);

    // Rear plasma jet
    final jetLen = 6.0 + math.sin(phase * 3) * 3.0;
    final jetPaint = Paint()
      ..color = const Color(0xFFFF9100)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx + 16, center.dy), Offset(center.dx + 16 + jetLen, center.dy), jetPaint);
  }

  @override
  bool shouldRepaint(covariant CyberBirdPainter oldDelegate) => true;
}

// 4. Cyber Laser Pylons & Warp Portals
class CyberPipePainter extends CustomPainter {
  final List<PipePair> pipes;
  final double gameHeight;

  const CyberPipePainter({
    required this.pipes,
    required this.gameHeight,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final pipe in pipes) {
      if (pipe.shattered) continue;

      if (pipe.isPortal) {
        // Draw Cyber Warp Portal Ring!
        _drawWarpPortal(canvas, pipe);
      } else {
        _drawTopPylon(canvas, pipe);
        _drawBottomPylon(canvas, pipe);

        if (pipe.hasLaser) {
          final laserX = pipe.x + GameConstants.pipeWidth / 2;
          final laserTop = pipe.topHeight;
          final laserBottom = pipe.topHeight + pipe.gap;
          final coreCenter = Offset(laserX, laserTop + pipe.gap / 2);

          if (pipe.laserActive) {
            final laserGlow = Paint()
              ..color = const Color(0xFFFF1744).withValues(alpha: 0.55)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 10
              ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);

            final laserCore = Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.8;

            canvas.drawLine(Offset(laserX, laserTop), Offset(laserX, laserBottom), laserGlow);
            canvas.drawLine(Offset(laserX, laserTop), Offset(laserX, laserBottom), laserCore);
          } else {
            // Warning dashed line when laser is recharging
            final warnPaint = Paint()
              ..color = const Color(0xFFFF1744).withValues(alpha: 0.5)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5;
            for (double y = laserTop; y < laserBottom; y += 18) {
              canvas.drawLine(Offset(laserX, y), Offset(laserX, math.min(y + 9, laserBottom)), warnPaint);
            }
          }

          // Draw Targetable Laser Crystal Core in the center of the gap!
          // Shooting this crystal (or any part of the laser) with a Plasma Shot destroys the laser!
          final crystalGlow = Paint()
            ..color = const Color(0xFFFF1744).withValues(alpha: 0.7)
            ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6.0);
          canvas.drawCircle(coreCenter, 11, crystalGlow);

          final crystalPath = Path()
            ..moveTo(coreCenter.dx, coreCenter.dy - 10)
            ..lineTo(coreCenter.dx + 9, coreCenter.dy)
            ..lineTo(coreCenter.dx, coreCenter.dy + 10)
            ..lineTo(coreCenter.dx - 9, coreCenter.dy)
            ..close();
          canvas.drawPath(crystalPath, Paint()..color = const Color(0xFFFF1744));
          canvas.drawPath(
            crystalPath,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.8,
          );
        }
      }
    }
  }

  void _drawWarpPortal(Canvas canvas, PipePair pipe) {
    final center = pipe.getPortalCenter();
    final radius = pipe.gap * 0.44; // ~72px radius

    // 1. Outer Neon Cyan Glow Aura
    final glowPaint = Paint()
      ..color = const Color(0xFF00F3FF).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 10.0);
    canvas.drawCircle(center, radius, glowPaint);

    // 2. Torus Outer Tech Ring
    final outerRingPaint = Paint()
      ..color = const Color(0xFFFF007F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;
    canvas.drawCircle(center, radius, outerRingPaint);

    // 3. Inner Cyan Tech Ring
    final innerRingPaint = Paint()
      ..color = const Color(0xFF00F3FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, radius - 6, innerRingPaint);

    // 4. Swirling Translucent Vortex Field
    final vortexPaint = Paint()
      ..color = const Color(0xFF00F3FF).withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 6, vortexPaint);

    // 5. Tech notches around perimeter
    final notchPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5;
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final p1 = Offset(center.dx + (radius - 8) * math.cos(angle), center.dy + (radius - 8) * math.sin(angle));
      final p2 = Offset(center.dx + (radius + 6) * math.cos(angle), center.dy + (radius + 6) * math.sin(angle));
      canvas.drawLine(p1, p2, notchPaint);
    }

    // 6. Floating Spark Token in Center
    final corePaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);
    canvas.drawCircle(center, 8, corePaint);
    canvas.drawCircle(center, 6, Paint()..color = Colors.white);
  }

  void _drawTopPylon(Canvas canvas, PipePair pipe) {
    final bodyRect = pipe.getTopBodyRect();
    final capRect = pipe.getTopCapRect();
    _drawPylon(canvas, bodyRect, capRect, isTop: true, isMoving: pipe.moveAmplitude > 0);
  }

  void _drawBottomPylon(Canvas canvas, PipePair pipe) {
    final capRect = pipe.getBottomCapRect(gameHeight);
    final bodyRect = pipe.getBottomBodyRect(gameHeight);
    _drawPylon(canvas, bodyRect, capRect, isTop: false, isMoving: pipe.moveAmplitude > 0);
  }

  void _drawPylon(
    Canvas canvas,
    Rect bodyRect,
    Rect capRect, {
    required bool isTop,
    required bool isMoving,
  }) {
    if (bodyRect.height <= 0) return;

    // Body Fill (Dark obsidian metal)
    final bodyPaint = Paint()..color = const Color(0xFF141424);
    canvas.drawRect(bodyRect, bodyPaint);
    canvas.drawRect(capRect, bodyPaint);

    // Glowing Neon Border (Electric Magenta, or Cyan if Moving!)
    final borderColor = isMoving ? const Color(0xFF00F3FF) : const Color(0xFFFF007F);
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRect(bodyRect, borderPaint);
    canvas.drawRect(capRect, borderPaint);

    final centerX = bodyRect.center.dx;

    // MOVING PYLON SPECIAL: Glowing Plasma Thrusters & Warning Chevrons
    if (isMoving) {
      // 1. Plasma Thruster Jet firing from the outer edge of the pylon
      final thrusterY = isTop ? capRect.top : capRect.bottom;
      final dir = isTop ? -1.0 : 1.0;
      final thrusterPaint = Paint()
        ..color = const Color(0xFF00F3FF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);

      final thrusterPath = Path()
        ..moveTo(centerX - 12, thrusterY)
        ..lineTo(centerX, thrusterY + (16.0 * dir))
        ..lineTo(centerX + 12, thrusterY)
        ..close();
      canvas.drawPath(thrusterPath, thrusterPaint);

      // 2. Yellow hazard chevrons on shaft
      final chevronPaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2;
      final midY = bodyRect.center.dy;
      final chPath = Path()
        ..moveTo(centerX - 8, midY - 6)
        ..lineTo(centerX, midY)
        ..lineTo(centerX + 8, midY - 6);
      canvas.drawPath(chPath, chevronPaint);
    }

    // Energy Core Line running down the center
    final coreGlowPaint = Paint()
      ..color = const Color(0xFF00F3FF)
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3.0);
    final coreLinePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5;

    canvas.drawLine(Offset(centerX, bodyRect.top), Offset(centerX, bodyRect.bottom), coreGlowPaint);
    canvas.drawLine(Offset(centerX, bodyRect.top), Offset(centerX, bodyRect.bottom), coreLinePaint);

    // Laser Emitter Bar at Cap Lip
    final lipY = isTop ? capRect.bottom - 2 : capRect.top + 2;
    final emitterPaint = Paint()
      ..color = const Color(0xFF00F3FF)
      ..strokeWidth = 3.5;
    canvas.drawLine(Offset(capRect.left + 3, lipY), Offset(capRect.right - 3, lipY), emitterPaint);
  }

  @override
  bool shouldRepaint(covariant CyberPipePainter oldDelegate) => true;
}

// 5. Power-Up Painter (Coins, Shields, Slow-Mo)
class PowerUpPainter extends CustomPainter {
  final List<PowerUp> powerUps;

  const PowerUpPainter({required this.powerUps, super.repaint});

  @override
  void paint(Canvas canvas, Size size) {
    for (final item in powerUps) {
      if (item.collected) continue;
      final center = Offset(item.x, item.renderY);

      switch (item.type) {
        case PowerUpType.coin:
          _drawStarCoin(canvas, center);
          break;
        case PowerUpType.shield:
          _drawShieldItem(canvas, center);
          break;
        case PowerUpType.slowMo:
          _drawSlowMoItem(canvas, center);
          break;
        case PowerUpType.blaster:
          _drawBlasterItem(canvas, center);
          break;
      }
    }
  }

  void _drawBlasterItem(Canvas canvas, Offset center) {
    final glowPaint = Paint()
      ..color = const Color(0xFFFF007F).withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 8.0);
    canvas.drawCircle(center, 15, glowPaint);

    final bgPaint = Paint()..color = const Color(0xFF880E4F);
    canvas.drawCircle(center, 13, bgPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFFFF007F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, 13, borderPaint);

    final iconPaint = Paint()..color = Colors.white;
    // Draw a small gun/blaster shape
    final path = Path()
      ..moveTo(center.dx - 4, center.dy - 2)
      ..lineTo(center.dx + 4, center.dy - 2)
      ..lineTo(center.dx + 4, center.dy)
      ..lineTo(center.dx + 1, center.dy)
      ..lineTo(center.dx + 1, center.dy + 4)
      ..lineTo(center.dx - 2, center.dy + 4)
      ..lineTo(center.dx - 2, center.dy + 1)
      ..lineTo(center.dx - 4, center.dy + 1)
      ..close();
    canvas.drawPath(path, iconPaint);
  }

  void _drawStarCoin(Canvas canvas, Offset center) {
    final glowPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 8.0);
    canvas.drawCircle(center, 15, glowPaint);

    final tokenPaint = Paint()..color = const Color(0xFFFFC107);
    canvas.drawCircle(center, 12, tokenPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, 12, borderPaint);

    final starPaint = Paint()..color = Colors.white;
    const r = 7.0;
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final a1 = i * 4 * math.pi / 5 - math.pi / 2;
      final x = center.dx + r * math.cos(a1);
      final y = center.dy + r * math.sin(a1);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, starPaint);
  }

  void _drawShieldItem(Canvas canvas, Offset center) {
    final glowPaint = Paint()
      ..color = const Color(0xFF00F3FF).withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 8.0);
    canvas.drawCircle(center, 15, glowPaint);

    final bgPaint = Paint()..color = const Color(0xFF00838F);
    canvas.drawCircle(center, 13, bgPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFF00F3FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawCircle(center, 13, borderPaint);

    final iconPaint = Paint()..color = Colors.white;
    final shieldPath = Path()
      ..moveTo(center.dx, center.dy - 6)
      ..lineTo(center.dx + 5, center.dy - 3)
      ..lineTo(center.dx + 4, center.dy + 3)
      ..lineTo(center.dx, center.dy + 7)
      ..lineTo(center.dx - 4, center.dy + 3)
      ..lineTo(center.dx - 5, center.dy - 3)
      ..close();
    canvas.drawPath(shieldPath, iconPaint);
  }

  void _drawSlowMoItem(Canvas canvas, Offset center) {
    final glowPaint = Paint()
      ..color = const Color(0xFFBA68C8).withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 8.0);
    canvas.drawCircle(center, 15, glowPaint);

    final bgPaint = Paint()..color = const Color(0xFF6A1B9A);
    canvas.drawCircle(center, 13, bgPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFFE1BEE7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, 13, borderPaint);

    final boltPaint = Paint()..color = Colors.white;
    final boltPath = Path()
      ..moveTo(center.dx + 1, center.dy - 7)
      ..lineTo(center.dx - 4, center.dy)
      ..lineTo(center.dx, center.dy)
      ..lineTo(center.dx - 1, center.dy + 7)
      ..lineTo(center.dx + 4, center.dy)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(boltPath, boltPaint);
  }

  @override
  bool shouldRepaint(covariant PowerUpPainter oldDelegate) => true;
}

// 6. Particle System Painter
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  static final Paint _particlePaint = Paint()..style = PaintingStyle.fill;

  const ParticlePainter({required this.particles, super.repaint});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      _particlePaint.color = p.color.withValues(alpha: p.opacity);
      canvas.drawCircle(Offset(p.x, p.y), p.size * p.opacity, _particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => particles.isNotEmpty;
}
