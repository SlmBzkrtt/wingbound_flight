import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wingbound_flight/game/game_constants.dart';
import 'package:wingbound_flight/game/models/bird.dart';
import 'package:wingbound_flight/game/models/pipe.dart';
import 'package:wingbound_flight/game/models/space_models.dart';

void main() {
  group('Bird Physics Tests', () {
    test('Bird initializes with correct default values', () {
      final bird = Bird();
      expect(bird.x, equals(80.0));
      expect(bird.y, equals(300.0));
      expect(bird.velocity, equals(0.0));
      expect(bird.rotation, equals(0.0));
    });

    test('Bird jump sets upward velocity and tilts up', () {
      final bird = Bird();
      bird.jump();
      expect(bird.velocity, equals(GameConstants.jumpVelocity));
      expect(bird.rotation, lessThan(0.0));
    });

    test('Bird falls with gravity when updated', () {
      final bird = Bird(velocity: 0.0, y: 100.0);
      const dt = 0.1;
      bird.update(dt, 600.0);

      expect(bird.velocity, greaterThan(0.0));
      expect(bird.y, greaterThan(100.0));
    });

    test('Bird rotation tilts downwards as it falls', () {
      final bird = Bird(velocity: 200.0, y: 100.0);
      bird.update(0.2, 600.0);
      expect(bird.rotation, greaterThan(0.0));
    });

    test('Bird stops at ground boundary', () {
      const groundY = 500.0;
      final bird = Bird(velocity: 400.0, y: 495.0);
      bird.update(0.1, groundY);
      final maxAllowedY = groundY - GameConstants.birdHeight / 2;
      expect(bird.y, equals(maxAllowedY));
    });
  });

  group('Pipe & Collision Tests', () {
    test('Pipe dimensions and gap are properly calculated', () {
      final pipe = PipePair(
        x: 200,
        topHeight: 120,
        bottomHeight: 200,
        gap: 180,
      );

      expect(pipe.gap, equals(180));
      expect(pipe.passed, isFalse);

      final topBody = pipe.getTopBodyRect();
      expect(topBody.left, equals(200));
      expect(topBody.top, equals(0));
      expect(topBody.height, equals(120 - GameConstants.pipeCapHeight));
    });

    test('Collision detects when bird overlaps top pipe', () {
      final pipe = PipePair(
        x: 100,
        topHeight: 200,
        bottomHeight: 200,
        gap: 150,
      );

      final birdHitBox = Rect.fromCenter(
        center: const Offset(120, 100),
        width: 30,
        height: 24,
      );

      expect(pipe.collidesWith(birdHitBox, 600), isTrue);
    });

    test('Collision does not trigger when bird is safely in gap', () {
      final pipe = PipePair(
        x: 100,
        topHeight: 200,
        bottomHeight: 200,
        gap: 180,
      );

      final birdHitBox = Rect.fromCenter(
        center: const Offset(120, 290), // Inside 180 gap
        width: 30,
        height: 24,
      );

      expect(pipe.collidesWith(birdHitBox, 600), isFalse);
    });

    test('Collision detects when bird overlaps bottom pipe', () {
      final pipe = PipePair(
        x: 100,
        topHeight: 200,
        bottomHeight: 200,
        gap: 150,
      );

      final birdHitBox = Rect.fromCenter(
        center: const Offset(120, 380),
        width: 30,
        height: 24,
      );

      expect(pipe.collidesWith(birdHitBox, 600), isTrue);
    });
  });

  group('Progressive Difficulty Tier Tests', () {
    test('Level 1 is generous and accessible for beginners', () {
      final diff = GameConstants.getDifficulty(0);
      expect(diff.level, equals(1));
      expect(diff.pipeGap, greaterThanOrEqualTo(185.0)); // Wide gap
      expect(diff.pipeSpacing, greaterThanOrEqualTo(350.0)); // Ample breathing room
      expect(diff.pipeSpeed, lessThanOrEqualTo(130.0)); // Calm pace
    });

    test('Difficulty scales smoothly and caps at safe values', () {
      final l1 = GameConstants.getDifficulty(2);
      final l2 = GameConstants.getDifficulty(8);
      final l3 = GameConstants.getDifficulty(18);
      final l4 = GameConstants.getDifficulty(50);

      expect(l1.level, equals(1));
      expect(l2.level, equals(2));
      expect(l3.level, equals(3));
      expect(l4.level, equals(4));

      // Speed increases gradually
      expect(l2.pipeSpeed, greaterThan(l1.pipeSpeed));
      expect(l3.pipeSpeed, greaterThan(l2.pipeSpeed));
      expect(l4.pipeSpeed, greaterThan(l3.pipeSpeed));

      // Spacing decreases gradually but stays fair (never below 270)
      expect(l4.pipeSpacing, greaterThanOrEqualTo(270.0));

      // Gap stays comfortable (never below 150)
      expect(l4.pipeGap, greaterThanOrEqualTo(150.0));
    });

    test('Shattered pipe does not cause collision', () {
      final pipe = PipePair(
        x: 100,
        topHeight: 200,
        bottomHeight: 200,
        gap: 150,
        shattered: true,
      );

      final birdHitBox = Rect.fromCenter(
        center: const Offset(120, 100),
        width: 30,
        height: 24,
      );

      expect(pipe.collidesWith(birdHitBox, 600), isFalse);
    });
  });

  group('Space Orbit Mode Orbital & Gate Tests', () {
    test('SpaceExplorer thrustOutward pushes radius outward and update pulls inward', () {
      final explorer = SpaceExplorer(radius: 120.0);
      explorer.thrustOutward();
      expect(explorer.radialVelocity, greaterThan(0.0));

      explorer.update(0.1, 1.5);
      expect(explorer.radius, greaterThan(120.0));
      expect(explorer.totalAngleTraversed, closeTo(0.15, 0.001));
    });

    test('SpaceExplorer tracks full 360 degree orbit calculation', () {
      final explorer = SpaceExplorer();
      explorer.update(1.0, 2 * math.pi + 0.1);
      final orbits = (explorer.totalAngleTraversed / (2 * math.pi)).floor();
      expect(orbits, equals(1));
    });

    test('OrbitGate collision triggers outside gap and passes safely inside gap', () {
      final gate = OrbitGate(
        angle: 1.0,
        gapInnerRadius: 100.0,
        gapOuterRadius: 150.0,
      );

      // Safe inside warp corridor gap
      expect(gate.collidesWith(1.0, 125.0), isFalse);
      // Collides with inner asteroid barrier
      expect(gate.collidesWith(1.0, 80.0), isTrue);
      // Collides with outer asteroid barrier
      expect(gate.collidesWith(1.0, 168.0), isTrue);
    });
  });
}

