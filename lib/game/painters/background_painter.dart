import 'package:flutter/material.dart';
import '../game_constants.dart';

class BackgroundPainter extends CustomPainter {
  final double parallaxOffset;

  // Paint nesneleri sınıf seviyesinde (static final) bir kez oluşturulur;
  // her karede (60/120 FPS) yeni nesne tahsisi (allocation) ve GC baskısı önlenir.
  static final Paint _skyPaint = Paint();
  static Size? _cachedSkySize;

  static final Paint _cloudPaint = Paint()
    ..color = const Color(0xD9FFFFFF)
    ..style = PaintingStyle.fill;

  static final Paint _buildingPaint = Paint()
    ..color = const Color(0xFFCBEAE8)
    ..style = PaintingStyle.fill;

  static final Paint _buildingOutlinePaint = Paint()
    ..color = const Color(0xFF8DC0BE)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  static final Paint _windowPaint = Paint()
    ..color = const Color(0xFFAFD5D4)
    ..style = PaintingStyle.fill;

  static final Paint _bushBackPaint = Paint()
    ..color = const Color(0xFF76C47A)
    ..style = PaintingStyle.fill;

  static final Paint _bushFrontPaint = Paint()
    ..color = const Color(0xFF8CD488)
    ..style = PaintingStyle.fill;

  static final Paint _bushOutlinePaint = Paint()
    ..color = const Color(0xFF4C9848)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  static const List<List<double>> _buildings = [
    [36.0, 75.0],
    [48.0, 95.0],
    [32.0, 60.0],
    [54.0, 115.0],
    [40.0, 85.0],
    [44.0, 100.0],
    [34.0, 70.0],
    [50.0, 90.0],
  ];

  // 36+6 + 48+6 + 32+6 + 54+6 + 40+6 + 44+6 + 34+6 + 50+6 = 386.0
  static const double _patternWidth = 386.0;

  const BackgroundPainter({
    this.parallaxOffset = 0.0,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final groundY = size.height - GameConstants.groundHeight;
    final skyRect = Rect.fromLTWH(0, 0, size.width, groundY);

    // Shader yalnızca ekran boyutu değiştiğinde yeniden üretilir
    if (_cachedSkySize != size) {
      _cachedSkySize = size;
      _skyPaint.shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          GameConstants.skyColorTop,
          GameConstants.skyColorBottom,
        ],
      ).createShader(skyRect);
    }

    canvas.drawRect(skyRect, _skyPaint);
    _drawClouds(canvas, size, groundY);
    _drawCitySkyline(canvas, size, groundY);
    _drawBushes(canvas, size, groundY);
  }

  void _drawClouds(Canvas canvas, Size size, double groundY) {
    final cloudY = groundY - 140;
    const cloudSpacing = 160.0;
    final startX = -(parallaxOffset * 0.2) % cloudSpacing - cloudSpacing;

    for (double x = startX; x < size.width + cloudSpacing; x += cloudSpacing) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, cloudY + 20, 110, 45),
          const Radius.circular(16),
        ),
        _cloudPaint,
      );
      canvas.drawCircle(Offset(x + 35, cloudY + 20), 24, _cloudPaint);
      canvas.drawCircle(Offset(x + 70, cloudY + 12), 30, _cloudPaint);
      canvas.drawCircle(Offset(x + 95, cloudY + 24), 18, _cloudPaint);
    }
  }

  void _drawCitySkyline(Canvas canvas, Size size, double groundY) {
    final startX = -(parallaxOffset * 0.4) % _patternWidth - _patternWidth;

    for (double shift = startX; shift < size.width + _patternWidth; shift += _patternWidth) {
      double currentX = shift;
      for (final b in _buildings) {
        final w = b[0];
        final h = b[1];
        if (currentX + w >= 0 && currentX <= size.width) {
          final top = groundY - h - 18;
          final rect = Rect.fromLTWH(currentX, top, w, h + 18);
          canvas.drawRect(rect, _buildingPaint);
          canvas.drawRect(rect, _buildingOutlinePaint);

          for (double wy = top + 10; wy < groundY - 26; wy += 14) {
            for (double wx = currentX + 6; wx < currentX + w - 8; wx += 10) {
              canvas.drawRect(Rect.fromLTWH(wx, wy, 5, 8), _windowPaint);
            }
          }
        }
        currentX += w + 6;
      }
    }
  }

  void _drawBushes(Canvas canvas, Size size, double groundY) {
    const bushSpacing = 80.0;
    final startX = -(parallaxOffset * 0.7) % bushSpacing - bushSpacing;

    for (double x = startX; x < size.width + bushSpacing; x += bushSpacing) {
      canvas.drawCircle(Offset(x + 20, groundY - 14), 22, _bushBackPaint);
      canvas.drawCircle(Offset(x + 20, groundY - 14), 22, _bushOutlinePaint);

      canvas.drawCircle(Offset(x + 55, groundY - 10), 20, _bushFrontPaint);
      canvas.drawCircle(Offset(x + 55, groundY - 10), 20, _bushOutlinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) {
    return (oldDelegate.parallaxOffset - parallaxOffset).abs() > 0.05;
  }
}
