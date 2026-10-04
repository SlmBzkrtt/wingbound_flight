import 'package:flutter/material.dart';
import '../game_constants.dart';
import '../models/pipe.dart';

class PipePainter extends CustomPainter {
  final List<PipePair> pipes;
  final double gameHeight;

  // Sınıf seviyesinde önbellekli Paint nesneleri (Döngü içi Paint() tahsisi yok)
  static final Paint _outlinePaint = Paint()
    ..color = GameConstants.pipeBorderColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.6;

  static final Paint _bodyPaint = Paint()
    ..color = GameConstants.pipeBodyColor
    ..style = PaintingStyle.fill;

  static final Paint _highlightPaint = Paint()
    ..color = GameConstants.pipeHighlightColor
    ..style = PaintingStyle.fill;

  static final Paint _specularPaint = Paint()
    ..color = const Color(0xCCB9F6CA)
    ..style = PaintingStyle.fill;

  static final Paint _shadowPaint = Paint()
    ..color = GameConstants.pipeShadowColor
    ..style = PaintingStyle.fill;

  static final Paint _deepShadowPaint = Paint()
    ..color = const Color(0xFF3E6B1C)
    ..style = PaintingStyle.fill;

  static final Paint _rivetPaint = Paint()
    ..color = const Color(0xFFDCE775)
    ..style = PaintingStyle.fill;

  static final Paint _lipPaint = Paint()
    ..color = const Color(0x662E4613)
    ..strokeWidth = 2.0;

  const PipePainter({
    required this.pipes,
    required this.gameHeight,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < pipes.length; i++) {
      final pipe = pipes[i];
      if (pipe.shattered) continue;
      if (pipe.x + GameConstants.pipeWidth + 12 < 0 ||
          pipe.x - 12 > size.width) {
        continue;
      }
      _drawTopPipe(canvas, pipe);
      _drawBottomPipe(canvas, pipe);
    }
  }

  void _drawTopPipe(Canvas canvas, PipePair pipe) {
    _drawPipeSection(canvas, pipe.getTopBodyRect());
    _drawPipeCap(canvas, pipe.getTopCapRect());
  }

  void _drawBottomPipe(Canvas canvas, PipePair pipe) {
    _drawPipeSection(canvas, pipe.getBottomBodyRect(gameHeight));
    _drawPipeCap(canvas, pipe.getBottomCapRect(gameHeight));
  }

  void _drawPipeSection(Canvas canvas, Rect rect) {
    if (rect.height <= 0) return;

    canvas.drawRect(rect, _bodyPaint);
    // 3B Sol parlama şeritleri
    canvas.drawRect(
      Rect.fromLTWH(rect.left + 7, rect.top, 9, rect.height),
      _highlightPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.left + 10, rect.top, 3, rect.height),
      _specularPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.left + 3, rect.top, 2, rect.height),
      _highlightPaint,
    );
    // 3B Sağ gölge şeritleri
    canvas.drawRect(
      Rect.fromLTWH(rect.right - 14, rect.top, 14, rect.height),
      _shadowPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.right - 5, rect.top, 5, rect.height),
      _deepShadowPaint,
    );
    canvas.drawRect(rect, _outlinePaint);
  }

  void _drawPipeCap(Canvas canvas, Rect rect) {
    final capRRect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    canvas.save();
    canvas.clipRRect(capRRect);

    canvas.drawRect(rect, _bodyPaint);
    canvas.drawRect(
      Rect.fromLTWH(rect.left + 7, rect.top, 9, rect.height),
      _highlightPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.left + 10, rect.top, 3, rect.height),
      _specularPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.right - 14, rect.top, 14, rect.height),
      _shadowPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.right - 5, rect.top, 5, rect.height),
      _deepShadowPaint,
    );
    canvas.drawLine(
      Offset(rect.left + 2, rect.top + 3),
      Offset(rect.right - 2, rect.top + 3),
      _lipPaint,
    );

    // Perçin / Mekanik Sütun Detayları
    canvas.drawCircle(
      Offset(rect.left + 7, rect.center.dy),
      2.2,
      _rivetPaint,
    );
    canvas.drawCircle(
      Offset(rect.right - 7, rect.center.dy),
      2.2,
      _rivetPaint,
    );

    canvas.restore();
    canvas.drawRRect(capRRect, _outlinePaint);
  }

  @override
  bool shouldRepaint(covariant PipePainter oldDelegate) {
    if (oldDelegate.gameHeight != gameHeight ||
        oldDelegate.pipes.length != pipes.length) {
      return true;
    }
    return pipes.isNotEmpty;
  }
}
