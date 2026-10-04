import 'package:flutter/material.dart';
import '../game_constants.dart';
import '../models/bird.dart';

class BirdPainter extends CustomPainter {
  final Bird bird;

  // Sınıf seviyesinde önbelleğe alınmış Paint ve Path nesneleri
  static final Paint _outlinePaint = Paint()
    ..color = GameConstants.birdOutlineColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static final Paint _bodyPaint = Paint()
    ..color = GameConstants.birdBodyColor
    ..style = PaintingStyle.fill;

  static final Paint _bellyPaint = Paint()
    ..color = GameConstants.birdBellyColor
    ..style = PaintingStyle.fill;

  static final Paint _whitePaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  static final Paint _pupilPaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.fill;

  static final Paint _beakPaint = Paint()
    ..color = GameConstants.birdBeakColor
    ..style = PaintingStyle.fill;

  static final Paint _beakHighlightPaint = Paint()
    ..color = GameConstants.birdBeakHighlightColor
    ..style = PaintingStyle.fill;

  static final Paint _wingPaint = Paint()
    ..color = GameConstants.birdWingColor
    ..style = PaintingStyle.fill;

  static final Paint _wingShadowPaint = Paint()
    ..color = GameConstants.birdWingShadowColor
    ..style = PaintingStyle.fill;

  // Statik geometriler (Her karede yeniden Path oluşturmayı engeller)
  static final Path _tailPath = Path()
    ..moveTo(-16, 2)
    ..lineTo(-22, -2)
    ..lineTo(-22, 6)
    ..close();

  static final RRect _bodyRRect = RRect.fromRectAndRadius(
    Rect.fromCenter(center: const Offset(-2, 0), width: 34, height: 26),
    const Radius.circular(13),
  );

  static final Path _bellyPath = Path()
    ..addArc(
      Rect.fromCenter(center: const Offset(-2, 3), width: 30, height: 20),
      0.2,
      2.7,
    )
    ..lineTo(-2, 6)
    ..close();

  static final Path _wingUpPath = Path()
    ..moveTo(-8, -2)
    ..quadraticBezierTo(-18, -14, -14, -16)
    ..quadraticBezierTo(-6, -10, -4, -2)
    ..close();

  static final Path _wingDownPath = Path()
    ..moveTo(-8, 2)
    ..quadraticBezierTo(-18, 14, -12, 16)
    ..quadraticBezierTo(-5, 10, -3, 2)
    ..close();

  static final Path _wingFlatPath = Path()
    ..moveTo(-3, 1)
    ..quadraticBezierTo(-18, 2, -18, -4)
    ..quadraticBezierTo(-10, -8, -2, -2)
    ..close();

  static final Path _upperBeakPath = Path()
    ..moveTo(8, -1)
    ..lineTo(19, 1)
    ..lineTo(16, 5)
    ..lineTo(7, 4)
    ..close();

  static final Path _lowerBeakPath = Path()
    ..moveTo(8, 4)
    ..lineTo(16, 5)
    ..lineTo(13, 9)
    ..lineTo(7, 8)
    ..close();

  const BirdPainter({
    required this.bird,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(bird.x, bird.y);
    canvas.rotate(bird.rotation);

    // 1. Kuyruk
    canvas.drawPath(_tailPath, _bodyPaint);
    canvas.drawPath(_tailPath, _outlinePaint);

    // 2. Gövde & Karın
    canvas.drawRRect(_bodyRRect, _bodyPaint);
    canvas.drawPath(_bellyPath, _bellyPaint);

    // 3. Kanat (3 kareli animasyon, önceden hesaplanmış Path referansları)
    final Path wingPath = bird.wingFrame == 1
        ? _wingUpPath
        : (bird.wingFrame == 2 ? _wingDownPath : _wingFlatPath);

    canvas.drawPath(wingPath, _wingShadowPaint);
    canvas.drawPath(wingPath, _wingPaint);
    canvas.drawPath(wingPath, _outlinePaint);

    // 4. Göz
    const eyeCenter = Offset(6, -5);
    canvas.drawCircle(eyeCenter, 6.5, _whitePaint);
    canvas.drawCircle(eyeCenter, 6.5, _outlinePaint);
    canvas.drawCircle(const Offset(8, -5), 3.2, _pupilPaint);
    canvas.drawCircle(const Offset(7.2, -6.2), 1.2, _whitePaint);

    // 5. Gaga
    canvas.drawPath(_upperBeakPath, _beakHighlightPaint);
    canvas.drawPath(_upperBeakPath, _outlinePaint);
    canvas.drawPath(_lowerBeakPath, _beakPaint);
    canvas.drawPath(_lowerBeakPath, _outlinePaint);

    // 6. Gövde dış konturu
    canvas.drawRRect(_bodyRRect, _outlinePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BirdPainter oldDelegate) {
    return oldDelegate.bird.y != bird.y ||
        oldDelegate.bird.rotation != bird.rotation ||
        oldDelegate.bird.wingFrame != bird.wingFrame;
  }
}
