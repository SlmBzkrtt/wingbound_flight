import 'dart:math' as math;
import 'package:flutter/material.dart';

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double life;
  final double maxLife;
  final double size;
  final Color color;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.maxLife,
    required this.size,
    required this.color,
  }) : life = maxLife;

  bool update(double dt) {
    x += vx * dt;
    y += vy * dt;
    life -= dt;
    return life > 0;
  }

  double get opacity => (life / maxLife).clamp(0.0, 1.0);
}

class ParticleSystem {
  final List<Particle> particles = [];
  final math.Random _random = math.Random();

  void addThrusterSparks(double x, double y, Color color) {
    if (particles.length > 80) return;
    for (int i = 0; i < 2; i++) {
      particles.add(
        Particle(
          x: x + _random.nextDouble() * 4 - 2,
          y: y + _random.nextDouble() * 6 - 3,
          vx: -120.0 - _random.nextDouble() * 80,
          vy: (_random.nextDouble() - 0.5) * 60,
          maxLife: 0.35 + _random.nextDouble() * 0.2,
          size: 3.0 + _random.nextDouble() * 3.0,
          color: color,
        ),
      );
    }
  }

  void addBurst(double x, double y, Color color, {int count = 16}) {
    for (int i = 0; i < count; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 60.0 + _random.nextDouble() * 160;
      particles.add(
        Particle(
          x: x,
          y: y,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          maxLife: 0.5 + _random.nextDouble() * 0.3,
          size: 3.5 + _random.nextDouble() * 4.0,
          color: color,
        ),
      );
    }
  }

  void update(double dt) {
    particles.removeWhere((p) => !p.update(dt));
  }
}
