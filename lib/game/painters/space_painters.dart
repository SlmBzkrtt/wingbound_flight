import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/space_models.dart';

class SpaceOrbitWorldPainter extends CustomPainter {
  final SpaceExplorer explorer;
  final List<OrbitGate> gates;
  final List<CosmicPowerUp> powerUps;
  final double gameTime;
  final bool hasPlasmaShield;
  final bool isInvulnerable;
  final double novaWaveRadius;
  final int skinIndex;

  const SpaceOrbitWorldPainter({
    required this.explorer,
    required this.gates,
    required this.powerUps,
    required this.gameTime,
    this.hasPlasmaShield = false,
    this.isInvulnerable = false,
    this.novaWaveRadius = 0.0,
    this.skinIndex = 0,
    super.repaint,
  });

  /// Smooth camera center that gently leans toward the space explorer so the large
  /// orbital accretion disk (radius up to 242px) fits comfortably on any screen width.
  static Offset getCameraCenter(Size size, SpaceExplorer explorer) {
    final camShiftX = math.cos(explorer.angle) * (explorer.radius * 0.22);
    final camShiftY = math.sin(explorer.angle) * (explorer.radius * 0.18);
    return Offset(
      size.width * 0.5 - camShiftX,
      size.height * 0.54 - camShiftY,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = getCameraCenter(size, explorer);

    // 1. Deep Space Nebula, Stars & Distant Ringed Planets Background
    _drawDeepSpaceBackground(canvas, size, center);

    // 2. Gravitational Orbit Field, Accretion Rings & Warp Portal Line
    _drawGravitationalOrbitField(canvas, center);

    // 3. Radial Asteroid & Plasma Laser Barriers (with High-Contrast Warp Corridor Gaps)
    final nextGate = _findNextUpcomingGate();
    for (final gate in gates) {
      if (gate.shattered) continue;
      _drawOrbitGate(canvas, center, gate, isNextGate: identical(gate, nextGate));
    }

    // 4. Cosmic Power-Ups (Plasma Shield, Star Crystal, Time Dilation)
    for (final item in powerUps) {
      if (item.collected) continue;
      _drawCosmicPowerUp(canvas, center, item);
    }

    // 5. Expanding Supernova Wave if active
    if (novaWaveRadius > 0.0) {
      final wavePaint = Paint()
        ..color = const Color(0xFFB388FF).withValues(
          alpha: (1.0 - (novaWaveRadius / 280.0)).clamp(0.0, 1.0),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 8.0);
      canvas.drawCircle(explorer.getPosition(center), novaWaveRadius, wavePaint);
    }

    // 6. Centerpiece: Supermassive Black Hole (Singularity, Photon Ring & Accretion Disk)
    _drawBlackHoleSingularity(canvas, center);

    // 7. 2.5D Astronaut / Space Explorer with Twin Ion Jetpack Thrusters
    _drawSpaceExplorer(canvas, center, nextGate);

    // 8. Perimeter Orbiting Pulsar Beacons
    _drawPerimeterPulsarBeacons(canvas, center);
  }

  OrbitGate? _findNextUpcomingGate() {
    OrbitGate? closest;
    double minPositiveAngularDist = double.infinity;

    for (final gate in gates) {
      if (gate.passed || gate.shattered) continue;
      double diff = (explorer.angle - gate.angle) % (2 * math.pi);
      if (diff < 0) diff += 2 * math.pi;
      if (diff < minPositiveAngularDist && diff < math.pi * 1.3) {
        minPositiveAngularDist = diff;
        closest = gate;
      }
    }
    return closest;
  }

  void _drawDeepSpaceBackground(Canvas canvas, Size size, Offset center) {
    final rect = Offset.zero & size;
    final bgGradient = const RadialGradient(
      center: Alignment(0.0, 0.06),
      radius: 1.15,
      colors: [
        Color(0xFF1F113B), // Deep cosmic violet nebula glow
        Color(0xFF0E0922), // Dark interstellar void
        Color(0xFF05030D), // Deep space border
      ],
    );
    canvas.drawRect(rect, Paint()..shader = bgGradient.createShader(rect));

    // Nebula clouds
    final nebulaPaint1 = Paint()
      ..color = const Color(0xFF7C4DFF).withValues(alpha: 0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 42.0);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.18), 90, nebulaPaint1);

    final nebulaPaint2 = Paint()
      ..color = const Color(0xFFFF6D00).withValues(alpha: 0.11)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48.0);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.84), 105, nebulaPaint2);

    // Twinkling deep-space stars across the cosmos
    for (int i = 0; i < 48; i++) {
      final sx = (i * 73.0 + 19.0) % size.width;
      final sy = (i * 47.0 + 11.0) % size.height;
      final twinkle = 0.45 + 0.55 * math.sin(gameTime * 2.5 + i).abs();
      final r = (i % 4 == 0) ? 1.9 : 1.1;
      final starColor = (i % 5 == 0)
          ? const Color(0xFF80D8FF)
          : (i % 7 == 0)
              ? const Color(0xFFFFD180)
              : Colors.white;
      canvas.drawCircle(
        Offset(sx, sy),
        r,
        Paint()..color = starColor.withValues(alpha: twinkle * 0.8),
      );
    }

    // Distant ringed exoplanet in top-right corner
    final planetCenter = Offset(size.width - 56, size.height * 0.13);
    canvas.drawCircle(
      planetCenter,
      16,
      Paint()..color = const Color(0xFF3949AB),
    );
    canvas.save();
    canvas.translate(planetCenter.dx, planetCenter.dy);
    canvas.rotate(-0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 48, height: 11),
      Paint()
        ..color = const Color(0xFFB388FF).withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6,
    );
    canvas.restore();
  }

  void _drawGravitationalOrbitField(Canvas canvas, Offset center) {
    // 1. Subtle cosmic accretion dust disk across the orbital arena
    final diskGradient = RadialGradient(
      colors: [
        const Color(0xFFFF6D00).withValues(alpha: 0.26),
        const Color(0xFF7C4DFF).withValues(alpha: 0.18),
        const Color(0xFF311B92).withValues(alpha: 0.12),
      ],
      stops: const [0.18, 0.62, 1.0],
    );
    final arenaRect = Rect.fromCircle(center: center, radius: SpaceExplorer.maxRadius + 14);
    canvas.drawCircle(
      center,
      SpaceExplorer.maxRadius + 14,
      Paint()..shader = diskGradient.createShader(arenaRect),
    );

    // 2. Concentric gravitational wave orbit rings
    final ringPaint = Paint()
      ..color = const Color(0xFFB388FF).withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (double r = SpaceExplorer.minRadius; r <= SpaceExplorer.maxRadius; r += 32.0) {
      canvas.drawCircle(center, r, ringPaint);
    }

    // 3. Explorer's Current Orbital Trajectory Ring (Helps player see exact orbit path through gaps!)
    final activeTrackPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, explorer.radius, activeTrackPaint);

    // 4. Outer Gravitational Containment Ring
    final outerShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;
    canvas.drawCircle(center, SpaceExplorer.maxRadius + 16, outerShadow);

    final outerRingPaint = Paint()
      ..color = const Color(0xFF7C4DFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.8;
    canvas.drawCircle(center, SpaceExplorer.maxRadius + 14, outerRingPaint);

    // 5. Inner Event Horizon Warning Ring
    final innerHorizonPaint = Paint()
      ..color = const Color(0xFFFF9100).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, SpaceExplorer.minRadius - 8, innerHorizonPaint);

    // 6. Radial spacetime grid lines curving into the gravity well
    final gridLinePaint = Paint()
      ..color = const Color(0xFFB388FF).withValues(alpha: 0.12)
      ..strokeWidth = 1.1;
    for (int i = 0; i < 16; i++) {
      final a = i * math.pi / 8 + gameTime * 0.08;
      canvas.drawLine(
        Offset(
          center.dx + (SpaceExplorer.minRadius - 8) * math.cos(a),
          center.dy + (SpaceExplorer.minRadius - 8) * math.sin(a),
        ),
        Offset(
          center.dx + (SpaceExplorer.maxRadius + 14) * math.cos(a),
          center.dy + (SpaceExplorer.maxRadius + 14) * math.sin(a),
        ),
        gridLinePaint,
      );
    }

    // 7. Quantum Warp Lap Line (360° Orbit Completion Gate at pi * 0.25)
    const startAngle = SpaceExplorer.startAngle;
    final lineStart = Offset(
      center.dx + (SpaceExplorer.minRadius - 12) * math.cos(startAngle),
      center.dy + (SpaceExplorer.minRadius - 12) * math.sin(startAngle),
    );
    final lineEnd = Offset(
      center.dx + (SpaceExplorer.maxRadius + 12) * math.cos(startAngle),
      center.dy + (SpaceExplorer.maxRadius + 12) * math.sin(startAngle),
    );

    final warpGlowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.48)
      ..strokeWidth = 8.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 5.0);
    final warpCorePaint = Paint()
      ..color = const Color(0xFF84FFFF)
      ..strokeWidth = 3.0;
    canvas.drawLine(lineStart, lineEnd, warpGlowPaint);
    canvas.drawLine(lineStart, lineEnd, warpCorePaint);
  }

  void _drawOrbitGate(
    Canvas canvas,
    Offset center,
    OrbitGate gate, {
    required bool isNextGate,
  }) {
    final cosA = math.cos(gate.angle);
    final sinA = math.sin(gate.angle);

    final isAligned = gate.isRadiusAligned(explorer.radius);

    // Metallic Asteroid / Plasma Pylon styles
    final wallShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.60)
      ..strokeWidth = 24.0
      ..strokeCap = StrokeCap.round;

    final wallBorderPaint = Paint()
      ..color = const Color(0xFFFF1744) // Crimson plasma hazard border
      ..strokeWidth = 19.0
      ..strokeCap = StrokeCap.round;

    final wallCorePaint = Paint()
      ..color = const Color(0xFF263238) // Dark metallic titanium asteroid core
      ..strokeWidth = 13.0
      ..strokeCap = StrokeCap.round;

    // 1. Inner barrier segment (from minRadius to gapInnerRadius)
    if (gate.gapInnerRadius > SpaceExplorer.minRadius + 2) {
      final p1 = Offset(
        center.dx + (SpaceExplorer.minRadius - 6) * cosA,
        center.dy + (SpaceExplorer.minRadius - 6) * sinA,
      );
      final p2 = Offset(
        center.dx + gate.gapInnerRadius * cosA,
        center.dy + gate.gapInnerRadius * sinA,
      );
      canvas.drawLine(p1, p2, wallShadowPaint);
      canvas.drawLine(p1, p2, wallBorderPaint);
      canvas.drawLine(p1, p2, wallCorePaint);
    }

    // 2. Outer barrier segment (from gapOuterRadius to maxRadius)
    if (gate.gapOuterRadius < SpaceExplorer.maxRadius - 2) {
      final p3 = Offset(
        center.dx + gate.gapOuterRadius * cosA,
        center.dy + gate.gapOuterRadius * sinA,
      );
      final p4 = Offset(
        center.dx + (SpaceExplorer.maxRadius + 10) * cosA,
        center.dy + (SpaceExplorer.maxRadius + 10) * sinA,
      );
      canvas.drawLine(p3, p4, wallShadowPaint);
      canvas.drawLine(p3, p4, wallBorderPaint);
      canvas.drawLine(p3, p4, wallCorePaint);
    }

    // 3. SAFE WARP CORRIDOR GAP (Boşluk Gösterimi)
    final gapStart = Offset(
      center.dx + gate.gapInnerRadius * cosA,
      center.dy + gate.gapInnerRadius * sinA,
    );
    final gapEnd = Offset(
      center.dx + gate.gapOuterRadius * cosA,
      center.dy + gate.gapOuterRadius * sinA,
    );

    // Highlight color: Bright Neon Green/Cyan when aligned, Solar Amber otherwise
    final gapColor = isNextGate
        ? (isAligned ? const Color(0xFF00E676) : const Color(0xFFFFAB00))
        : const Color(0xFFB388FF).withValues(alpha: 0.55);

    final safeZoneGlow = Paint()
      ..color = gapColor.withValues(alpha: isNextGate ? 0.38 : 0.18)
      ..strokeWidth = isNextGate ? 14.0 : 8.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6.0);
    canvas.drawLine(gapStart, gapEnd, safeZoneGlow);

    // Dotted warp guide nodes across the safe gap
    const dashCount = 5;
    for (int i = 1; i < dashCount; i++) {
      final t = i / dashCount;
      final dotPos = Offset.lerp(gapStart, gapEnd, t)!;
      canvas.drawCircle(
        dotPos,
        isNextGate ? 3.2 : 2.2,
        Paint()..color = gapColor.withValues(alpha: isNextGate ? 0.9 : 0.5),
      );
    }

    // 4. Glowing Emitter Caps at the exact edges of the safe gap
    final capOuterRadius = isNextGate ? 9.0 : 7.0;
    canvas.drawCircle(gapStart, capOuterRadius + 2, Paint()..color = Colors.black54);
    canvas.drawCircle(gapEnd, capOuterRadius + 2, Paint()..color = Colors.black54);

    canvas.drawCircle(gapStart, capOuterRadius, Paint()..color = gapColor);
    canvas.drawCircle(gapEnd, capOuterRadius, Paint()..color = gapColor);

    canvas.drawCircle(gapStart, capOuterRadius * 0.45, Paint()..color = Colors.white);
    canvas.drawCircle(gapEnd, capOuterRadius * 0.45, Paint()..color = Colors.white);

    // 5. Target Intersection Reticle on the next gate at Explorer's current radius
    if (isNextGate) {
      final intersectPos = Offset(
        center.dx + explorer.radius * cosA,
        center.dy + explorer.radius * sinA,
      );
      canvas.drawCircle(
        intersectPos,
        7.0,
        Paint()
          ..color = isAligned ? const Color(0xFF00E676) : const Color(0xFFFF5252)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  void _drawCosmicPowerUp(Canvas canvas, Offset center, CosmicPowerUp item) {
    final pos = item.getPosition(center);
    final r = 16.0 * item.pulseScale;

    switch (item.type) {
      case CosmicPowerType.plasmaShield:
        // Cyan Quantum Plasma Shield Core
        final glow = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 7.0);
        canvas.drawCircle(pos, r + 4, glow);
        canvas.drawCircle(pos, r, Paint()..color = const Color(0xFF006064));
        canvas.drawCircle(
          pos,
          r,
          Paint()
            ..color = const Color(0xFF84FFFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
        // Hexagonal shield icon inside
        final shieldPath = Path()
          ..moveTo(pos.dx, pos.dy - 8)
          ..lineTo(pos.dx + 7, pos.dy - 3)
          ..lineTo(pos.dx + 5, pos.dy + 6)
          ..lineTo(pos.dx, pos.dy + 9)
          ..lineTo(pos.dx - 5, pos.dy + 6)
          ..lineTo(pos.dx - 7, pos.dy - 3)
          ..close();
        canvas.drawPath(shieldPath, Paint()..color = Colors.white);
        break;

      case CosmicPowerType.starCrystal:
        // Golden-Orange Supernova Star Crystal
        final glow = Paint()
          ..color = const Color(0xFFFF9100).withValues(alpha: 0.60)
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 7.0);
        canvas.drawCircle(pos, r + 4, glow);
        canvas.drawCircle(pos, r, Paint()..color = const Color(0xFF3E2723));
        canvas.drawCircle(
          pos,
          r,
          Paint()
            ..color = const Color(0xFFFFD740)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
        // 4-point star diamond
        final starPath = Path()
          ..moveTo(pos.dx, pos.dy - 9)
          ..lineTo(pos.dx + 4, pos.dy - 3)
          ..lineTo(pos.dx + 9, pos.dy)
          ..lineTo(pos.dx + 4, pos.dy + 3)
          ..lineTo(pos.dx, pos.dy + 9)
          ..lineTo(pos.dx - 4, pos.dy + 3)
          ..lineTo(pos.dx - 9, pos.dy)
          ..lineTo(pos.dx - 4, pos.dy - 3)
          ..close();
        canvas.drawPath(starPath, Paint()..color = const Color(0xFFFFD740));
        break;

      case CosmicPowerType.timeDilation:
        // Violet Relativistic Time Dilation Hourglass / Vortex
        final glow = Paint()
          ..color = const Color(0xFFB388FF).withValues(alpha: 0.60)
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 7.0);
        canvas.drawCircle(pos, r + 4, glow);
        canvas.drawCircle(pos, r, Paint()..color = const Color(0xFF311B92));
        canvas.drawCircle(
          pos,
          r,
          Paint()
            ..color = const Color(0xFFEA80FC)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
        // Hourglass / Infinity symbol inside
        final hourglass = Path()
          ..moveTo(pos.dx - 6, pos.dy - 7)
          ..lineTo(pos.dx + 6, pos.dy - 7)
          ..lineTo(pos.dx - 6, pos.dy + 7)
          ..lineTo(pos.dx + 6, pos.dy + 7)
          ..close();
        canvas.drawPath(
          hourglass,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
        break;
    }
  }

  void _drawBlackHoleSingularity(Canvas canvas, Offset center) {
    // 1. Relativistic Polar Quasar Jets shooting diagonally from the Black Hole poles
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.45);
    final jetPaint = Paint()
      ..color = const Color(0xFF7C4DFF).withValues(alpha: 0.35)
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
    canvas.drawLine(const Offset(0, -68), const Offset(0, 68), jetPaint);
    canvas.restore();

    // 2. Outer Gravitational Lensing Halo (Turuncu-Mor Olay Ufku Bükülmesi)
    final outerHalo = Paint()
      ..color = const Color(0xFFFF6D00).withValues(alpha: 0.48)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22.0);
    canvas.drawCircle(center, 58, outerHalo);

    // 3. Swirling Accretion Disk (Dönen Yığılma Diski)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-gameTime * 1.4);

    final accretionRect = Rect.fromCircle(center: Offset.zero, radius: 56);
    final accretionShader = const SweepGradient(
      colors: [
        Color(0xFFFF6D00),
        Color(0xFFFFD740),
        Color(0xFFAA00FF),
        Color(0xFFFF3D00),
        Color(0xFFFF6D00),
      ],
      stops: [0.0, 0.25, 0.55, 0.80, 1.0],
    ).createShader(accretionRect);

    canvas.drawCircle(
      Offset.zero,
      54,
      Paint()
        ..shader = accretionShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0),
    );

    // Spiral plasma filaments being sucked into the Event Horizon
    final filamentPaint = Paint()
      ..color = const Color(0xFFFFE57F).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      final arcRect = Rect.fromCircle(center: Offset.zero, radius: 44);
      canvas.drawArc(arcRect, a, 0.65, false, filamentPaint);
    }
    canvas.restore();

    // 4. Warped Lensed Accretion Arc (Gargantua style tilted plasma ring)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.32);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 122, height: 34),
      Paint()
        ..color = const Color(0xFFFFAB00).withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0),
    );
    canvas.restore();

    // 5. Bright White-Gold Photon Ring (Foton Küresi)
    canvas.drawCircle(
      center,
      36,
      Paint()
        ..color = const Color(0xFFFFF8E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3.0),
    );

    // 6. Pitch-Black Singularity Core (Karadelik Tekilliği / Olay Ufku)
    canvas.drawCircle(
      center,
      34,
      Paint()..color = const Color(0xFF020106),
    );

    // Subtle inner gravitational depth rim
    canvas.drawCircle(
      center,
      32,
      Paint()
        ..color = const Color(0xFF4A148C).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawSpaceExplorer(Canvas canvas, Offset center, OrbitGate? nextGate) {
    final pos = explorer.getPosition(center);

    // 1. Draw glowing Cyan/Violet Ion Thruster Exhaust Trail behind the astronaut
    for (int i = 1; i <= 7; i++) {
      final trailAngle = explorer.angle + i * 0.07;
      final trailPos = Offset(
        center.dx + explorer.radius * math.cos(trailAngle),
        center.dy + explorer.radius * math.sin(trailAngle),
      );
      final alpha = (1.0 - i / 8.0) * 0.55;
      canvas.drawCircle(
        trailPos,
        6.5 - i * 0.7,
        Paint()
          ..color = (i.isEven ? const Color(0xFF00E5FF) : const Color(0xFFB388FF))
              .withValues(alpha: alpha),
      );
    }

    // 2. Exact Hitbox / Orbital Telemetry Ring around the Astronaut
    final isAlignedWithNext = nextGate == null || nextGate.isRadiusAligned(explorer.radius);
    final baseRingColor = isAlignedWithNext
        ? const Color(0xFF00E676)
        : const Color(0xFFFFAB00);

    canvas.drawCircle(
      pos,
      20.0,
      Paint()
        ..color = baseRingColor.withValues(alpha: 0.20)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      pos,
      20.0,
      Paint()
        ..color = baseRingColor.withValues(alpha: 0.88)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    // 3. Invulnerability or Plasma Shield Forcefield
    if (isInvulnerable) {
      canvas.drawCircle(
        pos,
        30,
        Paint()
          ..color = const Color(0xFFFFD740).withValues(alpha: 0.70)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0,
      );
    }

    if (hasPlasmaShield) {
      final shieldGlow = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6.0);
      canvas.drawCircle(pos, 28, shieldGlow);
      canvas.drawCircle(
        pos,
        27,
        Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.18),
      );
    }

    // 4. Draw Large 2.5D Sci-Fi Astronaut with Twin Ion Jetpack Thrusters
    final moveDirX = math.sin(explorer.angle);
    final facingLeft = moveDirX < 0;
    final bobOffset = math.sin(explorer.thrusterFrame * math.pi / 2).abs() * 2.2;

    canvas.save();
    canvas.translate(pos.dx, pos.dy - bobOffset);
    if (facingLeft) {
      canvas.scale(-1.0, 1.0);
    }

    // --- TWIN ION JETPACK & PLASMA FLAMES (Sırt Roketi) ---
    final jetpackRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(-10, -4), width: 12, height: 18),
      const Radius.circular(4),
    );
    canvas.drawRRect(jetpackRect, Paint()..color = const Color(0xFF546E7A));
    canvas.drawRRect(
      jetpackRect,
      Paint()
        ..color = const Color(0xFF263238)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // Dynamic Ion Flame Plume firing from Jetpack nozzles
    final flameLen = 9.0 + (explorer.thrusterFrame % 2) * 5.0;
    final flamePath = Path()
      ..moveTo(-13, 5)
      ..lineTo(-10, 5 + flameLen)
      ..lineTo(-7, 5)
      ..close();
    canvas.drawPath(
      flamePath,
      Paint()
        ..color = const Color(0xFF00E5FF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3.0),
    );
    canvas.drawCircle(const Offset(-10, 6), 2.5, Paint()..color = Colors.white);

    // --- ASTRONAUT MAGNETIC BOOTS & LEGS ---
    final legSwing = math.sin(explorer.thrusterFrame * math.pi / 2) * 4.0;
    final suitWhite = Paint()..color = const Color(0xFFF5F7FA);
    final suitBorder = Paint()
      ..color = const Color(0xFF263238)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final bootPaint = Paint()..color = const Color(0xFF37474F);

    canvas.drawLine(
      Offset(-4 + legSwing * 0.4, 6),
      Offset(-5 + legSwing, 14),
      Paint()
        ..color = const Color(0xFFECEFF1)
        ..strokeWidth = 5.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(5 - legSwing * 0.4, 6),
      Offset(5 - legSwing, 14),
      Paint()
        ..color = const Color(0xFFECEFF1)
        ..strokeWidth = 5.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(-5 + legSwing, 15.5), width: 9, height: 5),
        const Radius.circular(2),
      ),
      bootPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(5 - legSwing, 15.5), width: 9, height: 5),
        const Radius.circular(2),
      ),
      bootPaint,
    );

    // --- PRESSURIZED SPACE SUIT TORSO ---
    final torsoRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, -3), width: 24, height: 20),
      const Radius.circular(7),
    );
    canvas.drawRRect(torsoRect, suitWhite);
    canvas.drawRRect(torsoRect, suitBorder);

    final skinCoreColor = skinIndex == 1
        ? const Color(0xFFE040FB)
        : skinIndex == 2
            ? const Color(0xFFFF9100)
            : const Color(0xFF00E5FF);
    final skinStripeColor = skinIndex == 1
        ? const Color(0xFFFFD54F)
        : skinIndex == 2
            ? const Color(0xFF00E5FF)
            : const Color(0xFFFF6D00);

    // Sci-Fi Chest Telemetry & Oxygen Core Module
    final chestPanel = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(2, -4), width: 12, height: 9),
      const Radius.circular(3),
    );
    canvas.drawRRect(chestPanel, Paint()..color = const Color(0xFF263238));
    canvas.drawCircle(
      const Offset(2, -4),
      2.8,
      Paint()..color = skinCoreColor,
    );

    // Mission Stripes on Suit
    canvas.drawLine(
      const Offset(-9, 3),
      const Offset(9, 3),
      Paint()
        ..color = skinStripeColor
        ..strokeWidth = 2.8,
    );

    // --- ASTRONAUT HELMET & GOLDEN/CYAN REFLECTIVE VISOR ---
    const helmetCenter = Offset(0, -19);
    canvas.drawCircle(helmetCenter, 11.5, suitWhite);
    canvas.drawCircle(helmetCenter, 11.5, suitBorder);

    // Panoramic Reflective Gold/Cyan Helmet Visor
    final visorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(2.5, -19), width: 15, height: 12),
      const Radius.circular(6),
    );
    final visorGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFD740),
        Color(0xFFFF6D00),
        Color(0xFF311B92),
      ],
    ).createShader(visorRect.outerRect);
    canvas.drawRRect(visorRect, Paint()..shader = visorGradient);
    canvas.drawRRect(
      visorRect,
      Paint()
        ..color = const Color(0xFF263238)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // Starlight glare reflection on visor
    canvas.drawLine(
      const Offset(-1, -22),
      const Offset(5, -22),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    // Helmet Communications Antenna with blinking beacon on top
    canvas.drawLine(
      const Offset(-4, -30),
      const Offset(-4, -35),
      Paint()
        ..color = const Color(0xFF90A4AE)
        ..strokeWidth = 2.0,
    );
    canvas.drawCircle(
      const Offset(-4, -36),
      2.4,
      Paint()..color = const Color(0xFF00E5FF),
    );

    canvas.restore();
  }

  void _drawPerimeterPulsarBeacons(Canvas canvas, Offset center) {
    const beaconCount = 8;
    const beaconRadius = SpaceExplorer.maxRadius + 16;

    for (int i = 0; i < beaconCount; i++) {
      final a = i * (2 * math.pi / beaconCount);
      final pos = Offset(
        center.dx + beaconRadius * math.cos(a),
        center.dy + beaconRadius * math.sin(a),
      );

      final pulse = math.sin(gameTime * 6.0 + i * 1.4) * 2.0;

      // Metallic Satellite Node Base
      canvas.drawCircle(pos, 6.0, Paint()..color = const Color(0xFF263238));
      canvas.drawCircle(
        pos,
        6.0,
        Paint()
          ..color = const Color(0xFFB388FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // Pulsing Quasar Energy Node
      final glowPaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.48)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6.0);
      canvas.drawCircle(pos, 7.0 + pulse.abs(), glowPaint);

      canvas.drawCircle(pos, 3.6, Paint()..color = const Color(0xFF84FFFF));
      canvas.drawCircle(pos, 1.6, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant SpaceOrbitWorldPainter oldDelegate) => true;
}
