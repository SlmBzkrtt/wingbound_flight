import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game_constants.dart';

class Bird {
  double x;
  double y;
  double velocity;
  double rotation; // Radians
  int wingFrame; // 0, 1, 2
  double _frameTimer = 0.0;

  Bird({
    this.x = 80.0,
    this.y = 300.0,
    this.velocity = 0.0,
    this.rotation = 0.0,
    this.wingFrame = 0,
  });

  void jump() {
    velocity = GameConstants.jumpVelocity;
    rotation = -0.45; // ~ -25 degrees tilt up
  }

  void update(double dt, double groundY) {
    // Gravity physics
    velocity += GameConstants.gravity * dt;
    if (velocity > GameConstants.maxFallSpeed) {
      velocity = GameConstants.maxFallSpeed;
    }

    y += velocity * dt;

    // Rotation physics: tilts up on jump, dives down when falling
    if (velocity < 0) {
      // Ascending
      rotation = -0.42;
    } else {
      // Descending - smoothly pitch down towards +75 degrees
      rotation += 2.8 * dt;
      if (rotation > 1.3) {
        rotation = 1.3; // ~ 75 degrees down
      }
    }

    // Wing flapping animation
    _frameTimer += dt;
    if (_frameTimer >= 0.1) {
      _frameTimer = 0.0;
      wingFrame = (wingFrame + 1) % 3;
    }

    // Clamp bottom to ground
    final maxAllowedY = groundY - GameConstants.birdHeight / 2;
    if (y > maxAllowedY) {
      y = maxAllowedY;
    }
  }

  // Bobbing animation for the start screen
  void idleBob(double time, double baseY) {
    y = baseY + math.sin(time * 6.0) * 6.0;
    velocity = 0;
    rotation = 0;
    wingFrame = ((time * 10).floor() % 3);
  }

  // Hitbox with slight inset for fair retro arcade gameplay
  Rect getHitBox() {
    const insetX = 4.0;
    const insetY = 3.0;
    return Rect.fromCenter(
      center: Offset(x, y),
      width: GameConstants.birdWidth - (insetX * 2),
      height: GameConstants.birdHeight - (insetY * 2),
    );
  }

  void reset(double startY) {
    y = startY;
    velocity = 0;
    rotation = 0;
    wingFrame = 0;
    _frameTimer = 0.0;
  }
}
