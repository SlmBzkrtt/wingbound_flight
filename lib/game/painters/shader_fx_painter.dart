import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/game_mode.dart';

/// Impeller / Skia GLSL Fragment Shader yöneticisi ve CustomPainter katmanı.
/// Her evren (Classic, Cyber Neon, Space Orbit, 1453 Conquest) için GPU üzerinde
/// gerçek zamanlı atmosferik mercekleme, CRT scanline ve kor ışık efektleri üretir.
class RealmShaderService {
  RealmShaderService._();
  static final RealmShaderService instance = RealmShaderService._();

  ui.FragmentProgram? _program;
  ui.FragmentShader? _shader;
  bool _loading = false;

  ui.FragmentShader? get shader => _shader;

  Future<void> init() async {
    if (_program != null || _loading) return;
    _loading = true;
    try {
      _program = await ui.FragmentProgram.fromAsset('shaders/realm_fx.frag');
      _shader = _program!.fragmentShader();
    } catch (_) {
      // Birim testleri veya desteklenmeyen ortamlarda sessizce devre dışı kalır
    } finally {
      _loading = false;
    }
  }
}

class RealmShaderOverlayPainter extends CustomPainter {
  final GameMode mode;
  final double gameTime;
  final double intensity;

  static final Paint _shaderPaint = Paint();

  RealmShaderOverlayPainter({
    required this.mode,
    required this.gameTime,
    this.intensity = 0.0,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shader = RealmShaderService.instance.shader;
    if (shader == null) return;

    final double modeIndex;
    switch (mode) {
      case GameMode.classic:
        modeIndex = 0.0;
        break;
      case GameMode.cyberNeon:
        modeIndex = 1.0;
        break;
      case GameMode.spaceOrbit:
        modeIndex = 2.0;
        break;
      case GameMode.conquest1453:
        modeIndex = 3.0;
        break;
    }

    // uniform vec2 uSize (0, 1)
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    // uniform float uTime (2)
    shader.setFloat(2, gameTime);
    // uniform float uMode (3)
    shader.setFloat(3, modeIndex);
    // uniform float uIntensity (4)
    shader.setFloat(4, intensity.clamp(0.0, 1.0));

    _shaderPaint.shader = shader;
    canvas.drawRect(Offset.zero & size, _shaderPaint);
  }

  @override
  bool shouldRepaint(covariant RealmShaderOverlayPainter oldDelegate) {
    return oldDelegate.mode != mode ||
        oldDelegate.gameTime != gameTime ||
        oldDelegate.intensity != intensity;
  }
}
