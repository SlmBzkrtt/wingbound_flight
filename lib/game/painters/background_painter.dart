import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game_constants.dart';

class BackgroundPainter extends CustomPainter {
  final double parallaxOffset;

  // Sınıf seviyesinde önbellekli Paint nesneleri (60/120 FPS sıfır-allocation)
  static final Paint _skyPaint = Paint();
  static Size? _cachedSkySize;

  static final Paint _sunCorePaint = Paint()
    ..color = const Color(0xFFFFF9C4)
    ..style = PaintingStyle.fill;

  static final Paint _sunGlow1Paint = Paint()
    ..color = const Color(0x55FFE082)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18.0);

  static final Paint _sunGlow2Paint = Paint()
    ..color = const Color(0x28FFD54F)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36.0);

  static final Paint _farMountainPaint = Paint()
    ..color = const Color(0xFF7FAFC4)
    ..style = PaintingStyle.fill;

  static final Paint _midMountainPaint = Paint()
    ..color = const Color(0xFF6296AE)
    ..style = PaintingStyle.fill;

  static final Paint _snowCapPaint = Paint()
    ..color = const Color(0xE6F4FAFC)
    ..style = PaintingStyle.fill;

  static final Paint _cloudPaint = Paint()
    ..color = const Color(0xF2FFFFFF)
    ..style = PaintingStyle.fill;

  static final Paint _cloudShadowPaint = Paint()
    ..color = const Color(0xFFD5ECEF)
    ..style = PaintingStyle.fill;

  static final Paint _buildingPaint = Paint()
    ..color = const Color(0xFFB5DFDD)
    ..style = PaintingStyle.fill;

  static final Paint _buildingSidePaint = Paint()
    ..color = const Color(0xFF9ACBC8)
    ..style = PaintingStyle.fill;

  static final Paint _buildingOutlinePaint = Paint()
    ..color = const Color(0xFF6BA5A3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8;

  static final Paint _windowPaint = Paint()
    ..color = const Color(0xFFE0F7FA)
    ..style = PaintingStyle.fill;

  static final Paint _windowWarmPaint = Paint()
    ..color = const Color(0xFFFFF59D)
    ..style = PaintingStyle.fill;

  static final Paint _hillPaint = Paint()
    ..color = const Color(0xFF5FB465)
    ..style = PaintingStyle.fill;

  static final Paint _bushBackPaint = Paint()
    ..color = const Color(0xFF6AC270)
    ..style = PaintingStyle.fill;

  static final Paint _bushFrontPaint = Paint()
    ..color = const Color(0xFF85D682)
    ..style = PaintingStyle.fill;

  static final Paint _bushHighlightPaint = Paint()
    ..color = const Color(0xFFA8E8A3)
    ..style = PaintingStyle.fill;

  static final Paint _bushOutlinePaint = Paint()
    ..color = const Color(0xFF3E883B)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  static const List<List<double>> _buildings = [
    [36.0, 78.0],
    [48.0, 102.0],
    [32.0, 64.0],
    [54.0, 122.0],
    [40.0, 88.0],
    [44.0, 106.0],
    [34.0, 72.0],
    [50.0, 94.0],
  ];

  static const double _patternWidth = 386.0;

  const BackgroundPainter({
    this.parallaxOffset = 0.0,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final groundY = size.height - GameConstants.groundHeight;
    final skyRect = Rect.fromLTWH(0, 0, size.width, groundY);

    if (_cachedSkySize != size) {
      _cachedSkySize = size;
      _skyPaint.shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0.0, 0.45, 0.82, 1.0],
        colors: [
          Color(0xFF1E88E5),
          Color(0xFF4EC0CA),
          Color(0xFFB2EBF2),
          Color(0xFFE8F8F5),
        ],
      ).createShader(skyRect);
    }

    // 1. Zengin Çok Katmanlı Gökyüzü Gradyanı
    canvas.drawRect(skyRect, _skyPaint);

    // 2. Atmosferik Güneş ve Hale (Halo)
    final sunCenter = Offset(size.width * 0.76, groundY * 0.20);
    canvas.drawCircle(sunCenter, 68, _sunGlow2Paint);
    canvas.drawCircle(sunCenter, 44, _sunGlow1Paint);
    canvas.drawCircle(sunCenter, 26, _sunCorePaint);

    // 3. Uzak Karlı Dağ Sıradağları (0.14x Paralaks)
    _drawMountains(canvas, size, groundY);

    // 4. Hacimli Çift Katmanlı Bulutlar (0.22x Paralaks)
    _drawClouds(canvas, size, groundY);

    // 5. Perspektif Şehir Silüeti (0.40x Paralaks)
    _drawCitySkyline(canvas, size, groundY);

    // 6. Ön Plan Yeşil Tepeler ve Çam/Çalı Katmanı (0.70x Paralaks)
    _drawHillsAndBushes(canvas, size, groundY);
  }

  void _drawMountains(Canvas canvas, Size size, double groundY) {
    const mountainSpan = 260.0;
    final farStartX = -(parallaxOffset * 0.12) % mountainSpan - mountainSpan;

    final farPath = Path();
    for (double x = farStartX; x < size.width + mountainSpan; x += mountainSpan) {
      farPath
        ..moveTo(x, groundY)
        ..lineTo(x + 95, groundY - 195)
        ..lineTo(x + 175, groundY - 135)
        ..lineTo(x + 230, groundY - 210)
        ..lineTo(x + mountainSpan + 40, groundY)
        ..close();

      // Karlı zirve üçgenleri
      final snowPath = Path()
        ..moveTo(x + 95, groundY - 195)
        ..lineTo(x + 73, groundY - 150)
        ..lineTo(x + 95, groundY - 158)
        ..lineTo(x + 114, groundY - 150)
        ..close();
      canvas.drawPath(farPath, _farMountainPaint);
      canvas.drawPath(snowPath, _snowCapPaint);
    }

    final midStartX = -(parallaxOffset * 0.20) % mountainSpan - mountainSpan;
    final midPath = Path();
    for (double x = midStartX; x < size.width + mountainSpan; x += mountainSpan) {
      midPath
        ..moveTo(x - 20, groundY)
        ..lineTo(x + 70, groundY - 140)
        ..lineTo(x + 150, groundY - 95)
        ..lineTo(x + 210, groundY - 155)
        ..lineTo(x + mountainSpan + 30, groundY)
        ..close();
    }
    canvas.drawPath(midPath, _midMountainPaint);
  }

  void _drawClouds(Canvas canvas, Size size, double groundY) {
    // Üst yüksek irtifa bulutları
    final highCloudY = groundY * 0.26;
    const highSpacing = 210.0;
    final highStartX = -(parallaxOffset * 0.15) % highSpacing - highSpacing;

    for (double x = highStartX; x < size.width + highSpacing; x += highSpacing) {
      _drawSingleFluffyCloud(canvas, x, highCloudY, 0.78);
    }

    // Alçak ufuk bulutları
    final lowCloudY = groundY - 155;
    const cloudSpacing = 165.0;
    final startX = -(parallaxOffset * 0.25) % cloudSpacing - cloudSpacing;

    for (double x = startX; x < size.width + cloudSpacing; x += cloudSpacing) {
      _drawSingleFluffyCloud(canvas, x, lowCloudY, 1.0);
    }
  }

  void _drawSingleFluffyCloud(
    Canvas canvas,
    double x,
    double y,
    double scale,
  ) {
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(scale);

    // Alt gölge tabanı
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(2, 26, 112, 38),
        const Radius.circular(18),
      ),
      _cloudShadowPaint,
    );

    // Parlak beyaz bulut gövdesi
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 20, 112, 40),
        const Radius.circular(18),
      ),
      _cloudPaint,
    );
    canvas.drawCircle(const Offset(32, 22), 23, _cloudPaint);
    canvas.drawCircle(const Offset(66, 14), 29, _cloudPaint);
    canvas.drawCircle(const Offset(94, 25), 19, _cloudPaint);

    canvas.restore();
  }

  void _drawCitySkyline(Canvas canvas, Size size, double groundY) {
    final startX = -(parallaxOffset * 0.4) % _patternWidth - _patternWidth;

    for (double shift = startX;
        shift < size.width + _patternWidth;
        shift += _patternWidth) {
      double currentX = shift;
      for (int i = 0; i < _buildings.length; i++) {
        final b = _buildings[i];
        final w = b[0];
        final h = b[1];
        if (currentX + w >= 0 && currentX <= size.width) {
          final top = groundY - h - 18;
          final rect = Rect.fromLTWH(currentX, top, w, h + 18);
          canvas.drawRect(rect, _buildingPaint);

          // 3B yan derinlik şeridi
          canvas.drawRect(
            Rect.fromLTWH(currentX + w - 8, top, 8, h + 18),
            _buildingSidePaint,
          );
          canvas.drawRect(rect, _buildingOutlinePaint);

          // Çatı anteni / kule detayı
          if (i.isOdd) {
            canvas.drawLine(
              Offset(currentX + w * 0.5, top),
              Offset(currentX + w * 0.5, top - 12),
              _buildingOutlinePaint,
            );
          }

          int winIdx = 0;
          for (double wy = top + 10; wy < groundY - 28; wy += 14) {
            for (double wx = currentX + 6; wx < currentX + w - 10; wx += 10) {
              winIdx++;
              canvas.drawRect(
                Rect.fromLTWH(wx, wy, 5, 8),
                (winIdx + i) % 5 == 0 ? _windowWarmPaint : _windowPaint,
              );
            }
          }
        }
        currentX += w + 6;
      }
    }
  }

  void _drawHillsAndBushes(Canvas canvas, Size size, double groundY) {
    // Yumuşak yeşil tepeler
    const hillSpan = 180.0;
    final hillStart = -(parallaxOffset * 0.55) % hillSpan - hillSpan;
    for (double x = hillStart; x < size.width + hillSpan; x += hillSpan) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + hillSpan * 0.5, groundY + 6),
          width: hillSpan * 1.25,
          height: 58,
        ),
        _hillPaint,
      );
    }

    // Ön plan detaylı çalılar
    const bushSpacing = 80.0;
    final startX = -(parallaxOffset * 0.72) % bushSpacing - bushSpacing;

    for (double x = startX; x < size.width + bushSpacing; x += bushSpacing) {
      canvas.drawCircle(Offset(x + 20, groundY - 14), 22, _bushBackPaint);
      canvas.drawCircle(Offset(x + 20, groundY - 14), 22, _bushOutlinePaint);

      canvas.drawCircle(Offset(x + 55, groundY - 10), 20, _bushFrontPaint);
      canvas.drawCircle(Offset(x + 50, groundY - 15), 8, _bushHighlightPaint);
      canvas.drawCircle(Offset(x + 55, groundY - 10), 20, _bushOutlinePaint);
    }

    // Ufukta süzülen küçük kuş silüetleri
    final birdX = (size.width - (parallaxOffset * 0.35) % (size.width + 120)) - 40;
    final birdY = groundY * 0.28 + math.sin(parallaxOffset * 0.03) * 8.0;
    final flockPaint = Paint()
      ..color = const Color(0x88263238)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (int b = 0; b < 3; b++) {
      final bx = birdX + b * 18.0;
      final by = birdY + (b.isOdd ? -7.0 : 4.0);
      final p = Path()
        ..moveTo(bx - 5, by + 2)
        ..quadraticBezierTo(bx - 2, by - 3, bx, by)
        ..quadraticBezierTo(bx + 2, by - 3, bx + 5, by + 2);
      canvas.drawPath(p, flockPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) {
    return (oldDelegate.parallaxOffset - parallaxOffset).abs() > 0.05;
  }
}
