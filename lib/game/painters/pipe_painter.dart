import 'package:flutter/material.dart';
import '../game_constants.dart';
import '../models/pipe.dart';

class PipePainter extends CustomPainter {
  final List<PipePair> pipes;
  final double gameHeight;

  // Sınıf seviyesinde tekil Paint nesneleri (Döngü içi Paint() tahsisi tamamen kaldırıldı)
  static final Paint _outlinePaint = Paint()
    ..color = GameConstants.pipeBorderColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;

  static final Paint _bodyPaint = Paint()
    ..color = GameConstants.pipeBodyColor
    ..style = PaintingStyle.fill;

  static final Paint _highlightPaint = Paint()
    ..color = GameConstants.pipeHighlightColor
    ..style = PaintingStyle.fill;

  static final Paint _shadowPaint = Paint()
    ..color = GameConstants.pipeShadowColor
    ..style = PaintingStyle.fill;

  static final Paint _lipPaint = Paint()
    ..color = const Color(0x4D2E4613)
    ..strokeWidth = 1.5;

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
      // Ekran dışı (Off-screen culling) kontrolü
      if (pipe.x + GameConstants.pipeWidth + 12 < 0 || pipe.x - 12 > size.width) {
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
    canvas.drawRect(Rect.fromLTWH(rect.left + 8, rect.top, 8, rect.height), _highlightPaint);
    canvas.drawRect(Rect.fromLTWH(rect.left + 4, rect.top, 2, rect.height), _highlightPaint);
    canvas.drawRect(Rect.fromLTWH(rect.right - 12, rect.top, 12, rect.height), _shadowPaint);
    canvas.drawRect(rect, _outlinePaint);
  }

  void _drawPipeCap(Canvas canvas, Rect rect) {
    canvas.drawRect(rect, _bodyPaint);
    canvas.drawRect(Rect.fromLTWH(rect.left + 8, rect.top, 8, rect.height), _highlightPaint);
    canvas.drawRect(Rect.fromLTWH(rect.left + 4, rect.top, 2, rect.height), _highlightPaint);
    canvas.drawRect(Rect.fromLTWH(rect.right - 12, rect.top, 12, rect.height), _shadowPaint);
    canvas.drawLine(
      Offset(rect.left + 2, rect.top + 3),
      Offset(rect.right - 2, rect.top + 3),
      _lipPaint,
    );
    canvas.drawRect(rect, _outlinePaint);
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
