import 'dart:math' as math;
import 'package:flutter/material.dart';

enum PowerUpType {
  coin, // +2 bonus points
  shield, // Absorbs 1 hit
  slowMo, // Slows time for 4.5 seconds
  blaster, // Shoots lasers forward
}

class PowerUp {
  double x;
  double y;
  final PowerUpType type;
  bool collected;
  double _bobTimer = 0.0;

  PowerUp({
    required this.x,
    required this.y,
    required this.type,
    this.collected = false,
  });

  double get renderY => y + math.sin(_bobTimer * 5.0) * 5.0;

  Rect getHitBox() {
    return Rect.fromCircle(
      center: Offset(x, renderY),
      radius: 26.0,
    );
  }

  void update(double dt, double speed) {
    x -= speed * dt;
    _bobTimer += dt;
  }
}
