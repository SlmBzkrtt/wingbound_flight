import 'package:flutter/material.dart';
import '../game_constants.dart';

class GroundPainter extends CustomPainter {
  final double groundOffset;

  static final Paint _dirtPaint = Paint()..color = GameConstants.groundDirtColor;
  static final Paint _speckPaint = Paint()..color = const Color(0xFFC7BD79);
  static final Paint _grassBgPaint = Paint()..color = GameConstants.groundGrassColor1;
  static final Paint _stripePaint = Paint()..color = GameConstants.groundGrassColor2;
  static final Paint _borderPaint = Paint()
    ..color = GameConstants.groundBorderColor
    ..strokeWidth = 2.5;

  const GroundPainter({
    required this.groundOffset,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final groundY = size.height - GameConstants.groundHeight;
    final totalWidth = size.width;

    // 1. Toprak zemin
    final dirtRect = Rect.fromLTWH(
      0,
      groundY + GameConstants.grassHeight,
      totalWidth,
      GameConstants.groundHeight - GameConstants.grassHeight,
    );
    canvas.drawRect(dirtRect, _dirtPaint);

    // Kum dokusu benekleri
    for (double x = 12; x < totalWidth; x += 36) {
      canvas.drawRect(Rect.fromLTWH(x, groundY + 30, 4, 3), _speckPaint);
      canvas.drawRect(Rect.fromLTWH(x + 18, groundY + 54, 3, 3), _speckPaint);
      canvas.drawRect(Rect.fromLTWH(x + 8, groundY + 76, 5, 2), _speckPaint);
    }

    // 2. Çim şeridi
    final grassRect = Rect.fromLTWH(
      0,
      groundY,
      totalWidth,
      GameConstants.grassHeight,
    );
    canvas.drawRect(grassRect, _grassBgPaint);

    // 3. Diyagonal çim desenleri (Tek bir birleşik Path ile tek drawPath çağrısı)
    const stripeWidth = 14.0;
    final normalizedOffset = groundOffset % (stripeWidth * 2);

    canvas.save();
    canvas.clipRect(grassRect);

    final stripesPath = Path();
    for (double x = -stripeWidth * 2 - normalizedOffset;
        x < totalWidth + stripeWidth * 2;
        x += stripeWidth * 2) {
      stripesPath
        ..moveTo(x, groundY + GameConstants.grassHeight)
        ..lineTo(x + stripeWidth, groundY + GameConstants.grassHeight)
        ..lineTo(x + stripeWidth + 8, groundY)
        ..lineTo(x + 8, groundY)
        ..close();
    }
    canvas.drawPath(stripesPath, _stripePaint);
    canvas.restore();

    // 4. Kenar çizgileri
    canvas.drawLine(Offset(0, groundY), Offset(totalWidth, groundY), _borderPaint);
    canvas.drawLine(
      Offset(0, groundY + GameConstants.grassHeight),
      Offset(totalWidth, groundY + GameConstants.grassHeight),
      _borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant GroundPainter oldDelegate) {
    return (oldDelegate.groundOffset - groundOffset).abs() > 0.05;
  }
}
