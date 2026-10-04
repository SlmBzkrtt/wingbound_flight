import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/conquest_models.dart';

class ConquestWorldPainter extends CustomPainter {
  final OttomanGalley galley;
  final List<SeaBarrier> barriers;
  final List<Cannonball> cannonballs;
  final List<EnemyFireShip> enemyShips;
  final List<ConquestSupply> supplies;
  final double scrollOffset;
  final double gameTime;
  final bool hasArmorShield;
  final bool isInvulnerable;
  final bool hasSahiBuff;
  final double sahiWaveRadius;

  const ConquestWorldPainter({
    required this.galley,
    required this.barriers,
    required this.cannonballs,
    required this.enemyShips,
    required this.supplies,
    required this.scrollOffset,
    required this.gameTime,
    this.hasArmorShield = false,
    this.isInvulnerable = false,
    this.hasSahiBuff = false,
    this.sahiWaveRadius = 0.0,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Haliç (Golden Horn) Deep Water & 1453 Dawn Reflection
    _drawGoldenHornWater(canvas, size);

    // 2. Navigation Trajectory Guide & Next Barrier Alignment
    final nextBarrier = _findNextBarrier();
    _drawNavigationGuide(canvas, size, nextBarrier);

    // 3. Sea Fortifications & Destructible Haliç Iron Chains
    for (final barrier in barriers) {
      if (barrier.shattered) continue;
      _drawSeaBarrier(
        canvas,
        size,
        barrier,
        isNext: identical(barrier, nextBarrier),
      );
    }

    // 4. Ottoman Conquest Supplies (Yağlı Kızak, Şahi Barutu, Fetih Sancağı)
    for (final supply in supplies) {
      if (supply.collected) continue;
      _drawConquestSupply(canvas, supply);
    }

    // 5. Enemy Byzantine Fire Ships (Rum Ateşi Kayıkları)
    for (final ship in enemyShips) {
      if (ship.destroyed) continue;
      _drawEnemyFireShip(canvas, ship);
    }

    // 6. Cannonballs (Kızgın Top Gülleleri)
    for (final ball in cannonballs) {
      _drawCannonball(canvas, ball);
    }

    // 7. Şahi Topu Mega Shockwave Ring
    if (sahiWaveRadius > 0.0) {
      final wavePaint = Paint()
        ..color = const Color(0xFFFFB300).withValues(
          alpha: (1.0 - (sahiWaveRadius / 380.0)).clamp(0.0, 1.0),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 8.0);
      canvas.drawCircle(Offset(galley.x, galley.y - 20), sahiWaveRadius, wavePaint);
    }

    // 8. Left & Right Shorelines (Galata & Suriçi Kıyıları ve Yağlı Kızaklar)
    _drawShorelines(canvas, size);

    // 9. Player Character: 1453 Ottoman Assault Galley (Osmanlı Hücum Kalyonu)
    _drawOttomanGalley(canvas);
  }

  SeaBarrier? _findNextBarrier() {
    SeaBarrier? closest;
    double bestY = -double.infinity;
    for (final b in barriers) {
      if (b.passed || b.shattered) continue;
      if (b.y <= galley.y + 20 && b.y > bestY) {
        bestY = b.y;
        closest = b;
      }
    }
    return closest;
  }

  void _drawGoldenHornWater(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final waterGrad = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color(0xFF071A2C), // Deep shore shadow
        Color(0xFF0D2E4A), // Haliç deep navy
        Color(0xFF16425B), // Golden Horn central channel with dawn glow
        Color(0xFF0D2E4A),
        Color(0xFF071A2C),
      ],
      stops: [0.0, 0.18, 0.5, 0.82, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = waterGrad.createShader(rect));

    // Subtle 1453 crimson-gold dawn reflection down the center of the Golden Horn
    final dawnGlow = Paint()
      ..color = const Color(0xFFFF8F00).withValues(alpha: 0.07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30.0);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.45),
        width: size.width * 0.38,
        height: size.height,
      ),
      dawnGlow,
    );

    // Scrolling water wave ripples
    final wavePaint = Paint()
      ..color = const Color(0xFF4FC3F7).withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    const rowSpacing = 48.0;
    final offset = scrollOffset % rowSpacing;
    for (double y = -rowSpacing + offset; y < size.height + rowSpacing; y += rowSpacing) {
      final rowIdx = ((y - offset) / rowSpacing).round();
      for (int c = 0; c < 4; c++) {
        final wx = OttomanGalley.shoreWidth +
            32.0 +
            ((c * 110.0 + (rowIdx.isEven ? 24.0 : 68.0)) %
                (size.width - OttomanGalley.shoreWidth * 2 - 64.0));
        final path = Path()
          ..moveTo(wx - 14, y)
          ..quadraticBezierTo(wx - 7, y - 4, wx, y)
          ..quadraticBezierTo(wx + 7, y + 4, wx + 14, y);
        canvas.drawPath(path, wavePaint);
      }
    }
  }

  void _drawNavigationGuide(Canvas canvas, Size size, SeaBarrier? nextBarrier) {
    final isAligned = nextBarrier == null || nextBarrier.isShipAligned(galley.x);
    final guideColor = isAligned
        ? const Color(0xFF00E676)
        : const Color(0xFFFFD54F);

    // Dotted heading line ahead of the galley bow so player sees exact alignment with the channel!
    final targetY = nextBarrier != null ? math.max(60.0, nextBarrier.y) : 120.0;
    for (double y = galley.y - 48; y > targetY; y -= 22.0) {
      canvas.drawCircle(
        Offset(galley.x, y),
        2.5,
        Paint()..color = guideColor.withValues(alpha: 0.38),
      );
    }

    // Wake foam V-trail behind the stern
    for (int i = 1; i <= 5; i++) {
      final wy = galley.y + 30.0 + i * 13.0;
      final spread = i * 5.5;
      final alpha = (1.0 - i / 6.0) * 0.35;
      final wakePaint = Paint()
        ..color = Colors.white.withValues(alpha: alpha)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(galley.x - spread, wy),
        Offset(galley.x - spread - 4, wy + 7),
        wakePaint,
      );
      canvas.drawLine(
        Offset(galley.x + spread, wy),
        Offset(galley.x + spread + 4, wy + 7),
        wakePaint,
      );
    }
  }

  void _drawShorelines(Canvas canvas, Size size) {
    const sw = OttomanGalley.shoreWidth;
    final leftShore = Rect.fromLTWH(0, 0, sw, size.height);
    final rightShore = Rect.fromLTWH(size.width - sw, 0, sw, size.height);

    final earthPaint = Paint()..color = const Color(0xFF2B1D14);
    canvas.drawRect(leftShore, earthPaint);
    canvas.drawRect(rightShore, earthPaint);

    // Stone quay borders
    final stoneQuayPaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 4.0;
    canvas.drawLine(Offset(sw, 0), Offset(sw, size.height), stoneQuayPaint);
    canvas.drawLine(
      Offset(size.width - sw, 0),
      Offset(size.width - sw, size.height),
      stoneQuayPaint,
    );

    // Scrolling wooden greased slipway logs (Yağlı Kızaklar) & shoreline torches
    const logSpacing = 44.0;
    final offset = scrollOffset % logSpacing;
    final logPaint = Paint()
      ..color = const Color(0xFFA1887F)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    for (double y = -logSpacing + offset; y < size.height + logSpacing; y += logSpacing) {
      // Left shore slipway timbers
      canvas.drawLine(Offset(6, y), Offset(sw - 3, y), logPaint);
      // Right shore slipway timbers
      canvas.drawLine(
        Offset(size.width - sw + 3, y),
        Offset(size.width - 6, y),
        logPaint,
      );

      // Flickering siege torches every 3rd timber
      final idx = ((y - offset) / logSpacing).round();
      if (idx % 3 == 0) {
        final flicker = 1.0 + math.sin(gameTime * 10.0 + idx) * 0.2;
        for (final tx in [sw - 8.0, size.width - sw + 8.0]) {
          canvas.drawCircle(
            Offset(tx, y),
            8.0 * flicker,
            Paint()
              ..color = const Color(0xFFFF9800).withValues(alpha: 0.40)
              ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6.0),
          );
          canvas.drawCircle(Offset(tx, y), 3.5, Paint()..color = const Color(0xFFFFCA28));
        }
      }
    }
  }

  void _drawSeaBarrier(
    Canvas canvas,
    Size size,
    SeaBarrier barrier, {
    required bool isNext,
  }) {
    final y = barrier.y;
    final isAligned = barrier.isShipAligned(galley.x);
    final gapColor = isNext
        ? (isAligned ? const Color(0xFF00E676) : const Color(0xFFFFD54F))
        : const Color(0xFFFFD54F).withValues(alpha: 0.55);

    // 1. Highlight Open Channel Passage so the player clearly sees the safe gap!
    final gapGlow = Paint()
      ..color = gapColor.withValues(alpha: isNext ? 0.28 : 0.14)
      ..strokeWidth = isNext ? 14.0 : 8.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6.0);
    canvas.drawLine(
      Offset(barrier.gapLeft, y),
      Offset(barrier.gapRight, y),
      gapGlow,
    );

    // 2. If Haliç Iron Chain is active across the gap, draw interlocking iron links & target lock!
    if (barrier.hasChain) {
      final chainPaint = Paint()
        ..color = const Color(0xFFB0BEC5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2;

      for (double cx = barrier.gapLeft + 10; cx < barrier.gapRight - 6; cx += 14.0) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, y), width: 12, height: 7),
          chainPaint,
        );
      }

      // Central Chain Lock Target (Shoot with Cannonballs to break!)
      final lockCenter = Offset((barrier.gapLeft + barrier.gapRight) * 0.5, y);
      final pulse = 1.0 + math.sin(gameTime * 8.0) * 0.15;
      canvas.drawCircle(
        lockCenter,
        13.0 * pulse,
        Paint()
          ..color = const Color(0xFFFF1744).withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6.0),
      );
      canvas.drawCircle(lockCenter, 9.5, Paint()..color = const Color(0xFFB71C1C));
      canvas.drawCircle(
        lockCenter,
        9.5,
        Paint()
          ..color = const Color(0xFFFFD54F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
      canvas.drawCircle(lockCenter, 3.5, Paint()..color = Colors.white);
    }

    // 3. Left & Right Stone Sea Fortification Walls
    final leftRect = barrier.getLeftWallRect();
    final rightRect = barrier.getRightWallRect(size.width);

    for (final wRect in [leftRect, rightRect]) {
      if (wRect.width <= 2) continue;
      // Drop shadow on water
      canvas.drawRRect(
        RRect.fromRectAndRadius(wRect.shift(const Offset(0, 5)), const Radius.circular(6)),
        Paint()..color = Colors.black.withValues(alpha: 0.45),
      );
      // Stone wall body
      canvas.drawRRect(
        RRect.fromRectAndRadius(wRect, const Radius.circular(6)),
        Paint()..color = const Color(0xFF4E342E),
      );
      // Top battlement border
      canvas.drawRRect(
        RRect.fromRectAndRadius(wRect, const Radius.circular(6)),
        Paint()
          ..color = const Color(0xFFD7CCC8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );

      // Stone merlons (burç dişleri)
      for (double mx = wRect.left + 12; mx < wRect.right - 14; mx += 22.0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(mx, y), width: 12, height: 18),
            const Radius.circular(3),
          ),
          Paint()..color = const Color(0xFF6D4C41),
        );
      }
    }

    // 4. Glowing Channel Beacon Towers on the exact edges of the gap
    for (final tx in [barrier.gapLeft, barrier.gapRight]) {
      final towerPos = Offset(tx, y);
      canvas.drawCircle(towerPos, 13, Paint()..color = const Color(0xFF3E2723));
      canvas.drawCircle(
        towerPos,
        12,
        Paint()
          ..color = gapColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0,
      );
      canvas.drawCircle(towerPos, 5.0, Paint()..color = gapColor);
    }
  }

  void _drawEnemyFireShip(Canvas canvas, EnemyFireShip ship) {
    canvas.save();
    canvas.translate(ship.x, ship.y);

    // Crimson Greek Fire (Rum Ateşi) aura
    canvas.drawCircle(
      Offset.zero,
      20,
      Paint()
        ..color = const Color(0xFFFF5722).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6.0),
    );

    // Dark enemy boat hull pointing downward
    final hullPath = Path()
      ..moveTo(0, 20) // Bow pointing down toward player
      ..quadraticBezierTo(13, 6, 11, -16)
      ..lineTo(-11, -16)
      ..quadraticBezierTo(-13, 6, 0, 20)
      ..close();
    canvas.drawPath(hullPath, Paint()..color = const Color(0xFF3E2723));
    canvas.drawPath(
      hullPath,
      Paint()
        ..color = const Color(0xFFFF7043)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Burning Greek Fire brazier in center of boat
    canvas.drawCircle(const Offset(0, 2), 6.5, Paint()..color = const Color(0xFFD84315));
    canvas.drawCircle(const Offset(0, 2), 3.8, Paint()..color = const Color(0xFFFFEB3B));

    canvas.restore();
  }

  void _drawConquestSupply(Canvas canvas, ConquestSupply supply) {
    final pos = Offset(supply.x, supply.y);
    final r = 15.0 * supply.pulseScale;

    switch (supply.type) {
      case ConquestSupplyType.kizakShield:
        // Golden-Olive Armored Slipway Shield (Fatih Zırhı)
        canvas.drawCircle(
          pos,
          r + 4,
          Paint()
            ..color = const Color(0xFF26C6DA).withValues(alpha: 0.45)
            ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6.0),
        );
        canvas.drawCircle(pos, r, Paint()..color = const Color(0xFF00695C));
        canvas.drawCircle(
          pos,
          r,
          Paint()
            ..color = const Color(0xFFFFD54F)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
        // Shield emblem
        canvas.drawCircle(pos, 5.5, Paint()..color = const Color(0xFFFFD54F));
        break;

      case ConquestSupplyType.sahiPowder:
        // Fiery Crimson Şahi Cannon Powder Barrel
        canvas.drawCircle(
          pos,
          r + 4,
          Paint()
            ..color = const Color(0xFFFF1744).withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6.0),
        );
        canvas.drawCircle(pos, r, Paint()..color = const Color(0xFFB71C1C));
        canvas.drawCircle(
          pos,
          r,
          Paint()
            ..color = const Color(0xFFFFCA28)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
        // Cannonball trio icon
        canvas.drawCircle(Offset(pos.dx - 4, pos.dy + 2), 3.2, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(pos.dx + 4, pos.dy + 2), 3.2, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(pos.dx, pos.dy - 4), 3.2, Paint()..color = Colors.white);
        break;

      case ConquestSupplyType.fetihBanner:
        // Golden-Crimson Three Crescent Banner (+3 Fetih Puanı)
        canvas.drawCircle(
          pos,
          r + 4,
          Paint()
            ..color = const Color(0xFFFFB300).withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6.0),
        );
        canvas.drawCircle(pos, r, Paint()..color = const Color(0xFFC62828));
        canvas.drawCircle(
          pos,
          r,
          Paint()
            ..color = const Color(0xFFFFD700)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
        // Golden Crescent
        canvas.drawCircle(pos, 6.0, Paint()..color = const Color(0xFFFFD700));
        canvas.drawCircle(
          Offset(pos.dx + 2.2, pos.dy - 1.0),
          4.8,
          Paint()..color = const Color(0xFFC62828),
        );
        break;
    }
  }

  void _drawCannonball(Canvas canvas, Cannonball ball) {
    final pos = Offset(ball.x, ball.y);
    final radius = ball.isSahi ? 8.5 : 5.5;
    final glowColor = ball.isSahi ? const Color(0xFFFF1744) : const Color(0xFFFFB300);

    // Fiery trail behind cannonball
    canvas.drawLine(
      pos,
      Offset(pos.dx, pos.dy + (ball.isSahi ? 22 : 14)),
      Paint()
        ..color = glowColor.withValues(alpha: 0.65)
        ..strokeWidth = radius * 1.4
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      pos,
      radius + 3,
      Paint()
        ..color = glowColor.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0),
    );
    canvas.drawCircle(pos, radius, Paint()..color = const Color(0xFF263238));
    canvas.drawCircle(
      Offset(pos.dx - 1.5, pos.dy - 1.5),
      radius * 0.4,
      Paint()..color = const Color(0xFFFFD54F),
    );
  }

  void _drawOttomanGalley(Canvas canvas) {
    canvas.save();
    canvas.translate(galley.x, galley.y);
    canvas.rotate(galley.bankAngle);

    // 1. Invulnerability or Armor Shield Aura
    if (isInvulnerable) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 64, height: 86),
        Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0,
      );
    }

    if (hasArmorShield) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 62, height: 84),
        Paint()
          ..color = const Color(0xFF26C6DA).withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6.0),
      );
    }

    // 2. Animated Rowing Oars (3 pairs of oars on port & starboard!)
    final oarSwing = math.sin(galley.oarPhase) * 6.0;
    final oarPaint = Paint()
      ..color = const Color(0xFFD7CCC8)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    final splashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final oy in [-10.0, 2.0, 14.0]) {
      // Left oar (İskele küreği)
      final lxEnd = Offset(-28.0, oy + oarSwing);
      canvas.drawLine(Offset(-13.0, oy), lxEnd, oarPaint);
      canvas.drawCircle(lxEnd, 3.0, splashPaint);

      // Right oar (Sancak küreği)
      final rxEnd = Offset(28.0, oy - oarSwing);
      canvas.drawLine(Offset(13.0, oy), rxEnd, oarPaint);
      canvas.drawCircle(rxEnd, 3.0, splashPaint);
    }

    // 3. Golden Bow Spur / Ram (Altın Mahmuz) pointing North (-Y)
    final ramPath = Path()
      ..moveTo(0, -44)
      ..lineTo(5, -30)
      ..lineTo(-5, -30)
      ..close();
    canvas.drawPath(ramPath, Paint()..color = const Color(0xFFFFD700));

    // 4. Main Wooden Galley Hull (Kadırga Gövdesi)
    final hullPath = Path()
      ..moveTo(0, -35) // Sharp bow
      ..quadraticBezierTo(19, -15, 17, 22) // Starboard curve
      ..quadraticBezierTo(12, 34, 0, 34) // Stern right
      ..quadraticBezierTo(-12, 34, -17, 22) // Stern left
      ..quadraticBezierTo(-19, -15, 0, -35) // Port curve
      ..close();

    // Hull shadow
    canvas.drawPath(
      hullPath.shift(const Offset(0, 4)),
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );
    // Rich oak hull fill
    canvas.drawPath(hullPath, Paint()..color = const Color(0xFF5D4037));
    // Golden-bronze gunwale border
    canvas.drawPath(
      hullPath,
      Paint()
        ..color = const Color(0xFFD4AF37)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Inner wooden deck planks
    final deckRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, 2), width: 22, height: 46),
      const Radius.circular(10),
    );
    canvas.drawRRect(deckRect, Paint()..color = const Color(0xFF8D6E63));

    // 5. Bow-Mounted Brass Şahi Cannon (Şahi Topu)
    final cannonRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, -25), width: 8, height: 14),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      cannonRect,
      Paint()..color = hasSahiBuff ? const Color(0xFFFF1744) : const Color(0xFFFFB300),
    );
    canvas.drawRRect(
      cannonRect,
      Paint()
        ..color = const Color(0xFF3E2723)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 6. Billowing Crimson Ottoman Sail (Al Sancak Yelkeni ve Hilal)
    final sailPath = Path()
      ..moveTo(-20, -4)
      ..quadraticBezierTo(0, -16, 20, -4)
      ..lineTo(17, 8)
      ..quadraticBezierTo(0, -2, -17, 8)
      ..close();
    canvas.drawPath(sailPath, Paint()..color = const Color(0xFFC62828));
    canvas.drawPath(
      sailPath,
      Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Golden Crescent on the Crimson Sail
    canvas.drawCircle(const Offset(0, -5), 5.0, Paint()..color = const Color(0xFFFFD700));
    canvas.drawCircle(const Offset(1.8, -6.0), 4.0, Paint()..color = const Color(0xFFC62828));

    // Mast & Waving Pennant
    canvas.drawCircle(const Offset(0, 2), 4.0, Paint()..color = const Color(0xFF3E2723));

    // 7. Levent Captain at the Stern Helm (Kavuklu Kaptan-ı Derya / Levent)
    canvas.drawCircle(const Offset(0, 20), 6.5, Paint()..color = const Color(0xFF1B5E20)); // Green Caftan shoulders
    canvas.drawCircle(const Offset(0, 19), 4.8, Paint()..color = const Color(0xFFF5F5F5)); // White Ottoman Kavuk
    canvas.drawCircle(const Offset(0, 19), 2.2, Paint()..color = const Color(0xFFC62828)); // Red Kavuk top (Destar)

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ConquestWorldPainter oldDelegate) => true;
}
