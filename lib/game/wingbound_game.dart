import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'game_constants.dart';
import 'models/bird.dart';
import 'models/conquest_models.dart';
import 'models/game_mode.dart';
import 'models/particle.dart';
import 'models/pipe.dart';
import 'models/power_up.dart';
import 'models/space_models.dart';
import 'painters/background_painter.dart';
import 'painters/bird_painter.dart';
import 'painters/conquest_painters.dart';
import 'painters/cyber_painters.dart';
import 'painters/ground_painter.dart';
import 'painters/pipe_painter.dart';
import 'painters/shader_fx_painter.dart';
import 'painters/space_painters.dart';
import 'services/game_services.dart';
import 'widgets/game_over_dialog.dart';
import 'widgets/mode_select_screen.dart';
import 'widgets/ready_overlay.dart';
import 'widgets/scoreboard.dart';

enum GameState { menu, ready, playing, gameOver }

class WingBoundGame extends StatefulWidget {
  const WingBoundGame({super.key});

  @override
  State<WingBoundGame> createState() => _WingBoundGameState();
}

class _WingBoundGameState extends State<WingBoundGame>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;

  /// Canvas katmanını tüm Widget ağacını yeniden oluşturmadan (setState olmadan)
  /// doğrudan RenderObject seviyesinde tetikleyen hafif sinyal.
  final ValueNotifier<int> _repaintTick = ValueNotifier<int>(0);

  // Sanal (Mantıksal) Oyun Çözünürlüğü (Responsive FittedBox referansı)
  double _logicalWidth = GameConstants.logicalStandardWidth;
  double _logicalHeight = GameConstants.logicalHeight;

  GameMode _mode = GameMode.classic;
  GameState _gameState = GameState.menu;

  final Bird _bird = Bird();
  final List<PipePair> _pipes = [];
  final List<PowerUp> _powerUps = [];
  final ParticleSystem _particleSystem = ParticleSystem();
  final math.Random _random = math.Random();

  // Mode 3: Black Hole Space Orbit state
  final SpaceExplorer _explorer = SpaceExplorer();
  final List<OrbitGate> _orbitGates = [];
  final List<CosmicPowerUp> _cosmicPowerUps = [];
  double _nextGateAngle = SpaceExplorer.startAngle - math.pi * 0.90;
  double? _lastOrbitGapRadius;

  // Mode 4: 1453 Conquest of Constantinople (Golden Horn Galley & Şahi Cannon) state
  final OttomanGalley _galley = OttomanGalley();
  final List<SeaBarrier> _seaBarriers = [];
  final List<Cannonball> _cannonballs = [];
  final List<EnemyFireShip> _enemyFireShips = [];
  final List<ConquestSupply> _conquestSupplies = [];
  double? _lastConquestGapCenterX;

  int _score = 0;
  int _classicHighScore = 0;
  int _cyberHighScore = 0;
  int _spaceHighScore = 0;
  int _conquestHighScore = 0;
  bool _isNewHighScore = false;

  // Progressive difficulty tracking
  int _currentLevel = 1;
  String? _levelAnnouncement;
  double _announcementTimer = 0.0;
  double? _lastGapCenterY;
  double _gameTime = 0.0;

  // Cyber Neon, Space Orbit & 1453 Conquest Special Mechanics
  bool _hasShield = false;
  double _slowMoTimer = 0.0;
  double _invulnerableTimer = 0.0;
  int _jumpsUsed = 0;
  int _comboStreak = 0;

  // Blaster, Plasma, Cannon & EMP/Nova/Şahi mechanics
  double _blasterTimer = 0.0;
  double _blasterFireCooldown = 0.0;
  double _empRadius = 0.0;
  double _empCooldown = 0.0;
  final List<LaserBolt> _projectiles = [];
  final List<EnemyDrone> _drones = [];

  double _groundOffset = 0.0;
  double _parallaxOffset = 0.0;
  double _idleTime = 0.0;
  double _flashOpacity = 0.0;
  Color _flashColor = Colors.white;
  bool _canRestart = false;

  final FocusNode _focusNode = FocusNode();

  // Önbelleğe alınmış (Cached) HUD TextStyle nesneleri (Her karede GoogleFonts çözümlemesini önler)
  static final TextStyle _hudBadgeStyle = GoogleFonts.pressStart2p(
    fontSize: 8.0,
    color: Colors.white,
  );
  static final TextStyle _hudActionActiveStyle = GoogleFonts.pressStart2p(
    fontSize: 8.5,
    color: Colors.white,
  );
  static final TextStyle _hudActionCooldownStyle = GoogleFonts.pressStart2p(
    fontSize: 8.5,
    color: Colors.white54,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHighScores();
    _ticker = createTicker(_onTick);
    _ticker.start();
    // Menüdeyken ticker'ı sessize al (0% arka plan CPU/GPU tüketimi)
    _ticker.muted = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      // Uygulama arka plana alındığında oyun döngüsünü ve sesleri durdur
      _ticker.muted = true;
      _lastTick = Duration.zero;
      GameAudioService.instance.pauseAll();
    } else if (state == AppLifecycleState.resumed) {
      // Uygulama öne geldiğinde yalnızca oyun ekranındaysa döngüyü devam ettir
      _lastTick = Duration.zero;
      _ticker.muted = (_gameState == GameState.menu);
    }
  }

  Future<void> _loadHighScores() async {
    await GameStorageService.instance.init();
    await GameAudioService.instance.init();
    await RealmShaderService.instance.init();
    if (!mounted) return;
    setState(() {
      _classicHighScore = GameStorageService.instance.getHighScore(GameMode.classic);
      _cyberHighScore = GameStorageService.instance.getHighScore(GameMode.cyberNeon);
      _spaceHighScore = GameStorageService.instance.getHighScore(GameMode.spaceOrbit);
      _conquestHighScore = GameStorageService.instance.getHighScore(GameMode.conquest1453);
    });
  }

  Future<void> _saveHighScore(int score) async {
    await GameStorageService.instance.saveHighScore(_mode, score);
  }

  int get _currentHighScore {
    switch (_mode) {
      case GameMode.classic:
        return _classicHighScore;
      case GameMode.cyberNeon:
        return _cyberHighScore;
      case GameMode.spaceOrbit:
        return _spaceHighScore;
      case GameMode.conquest1453:
        return _conquestHighScore;
    }
  }

  int get _comboMultiplier {
    if (_comboStreak >= 9) return 4;
    if (_comboStreak >= 6) return 3;
    if (_comboStreak >= 3) return 2;
    return 1;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _repaintTick.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_gameState == GameState.menu) return;

    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }

    double dt = (elapsed - _lastTick).inMicroseconds / 1000000.0;
    _lastTick = elapsed;

    if (dt > 0.05) dt = 0.05;

    // HUD değişim kontrolü için önceki değerleri kaydet
    final prevScore = _score;
    final prevState = _gameState;
    final prevShield = _hasShield;
    final prevCombo = _comboStreak;
    final prevOrbits = _explorer.orbitsCompleted;
    final prevChains = _galley.chainsBroken;
    final prevSteer = _galley.steerDir;
    final prevAnnouncement = _levelAnnouncement;
    final prevEmpDeci = (_empCooldown * 10).ceil();
    final prevBlasterDeci = (_blasterTimer * 10).ceil();
    final prevSlowMoDeci = (_slowMoTimer * 10).ceil();
    final prevInvulnActive = _invulnerableTimer > 0;
    final hadFlash = _flashOpacity > 0.0;

    // Flash decay
    if (_flashOpacity > 0.0) {
      _flashOpacity = math.max(0.0, _flashOpacity - dt * 4.0);
    }

    if (!mounted) return;

    _updateGame(dt);

    // 1. Canvas katmanını her karede (Widget ağacını rebuild etmeden) yeniden çizdir
    _repaintTick.value++;

    // 2. Widget ağacını (HUD / Dialog) YALNIZCA ekranda gösterilen metin/durum değiştiyse güncelle!
    final hudChanged = prevScore != _score ||
        prevState != _gameState ||
        prevShield != _hasShield ||
        prevCombo != _comboStreak ||
        prevOrbits != _explorer.orbitsCompleted ||
        prevChains != _galley.chainsBroken ||
        prevSteer != _galley.steerDir ||
        prevAnnouncement != _levelAnnouncement ||
        prevEmpDeci != (_empCooldown * 10).ceil() ||
        prevBlasterDeci != (_blasterTimer * 10).ceil() ||
        prevSlowMoDeci != (_slowMoTimer * 10).ceil() ||
        prevInvulnActive != (_invulnerableTimer > 0) ||
        hadFlash ||
        _flashOpacity > 0.0 ||
        _announcementTimer > 0.0;

    if (hudChanged) {
      setState(() {});
    }
  }

  void _firePlasmaShot() {
    if (_mode != GameMode.cyberNeon || _gameState != GameState.playing) return;
    final isHeavy = _blasterTimer > 0;
    _projectiles.add(
      LaserBolt(
        x: _bird.x + 22,
        y: _bird.y,
        isHeavy: isHeavy,
      ),
    );
    _particleSystem.addBurst(
      _bird.x + 22,
      _bird.y,
      isHeavy ? const Color(0xFFFF007F) : const Color(0xFF00F3FF),
      count: 4,
    );
  }

  void _fireCannonballVolley() {
    if (_mode != GameMode.conquest1453 || _gameState != GameState.playing) return;
    final isSahi = _blasterTimer > 0;
    if (isSahi) {
      // 3-way Heavy Şahi Cannon Barrage!
      _cannonballs.add(Cannonball(x: _galley.x, y: _galley.y - 34, vx: 0.0, vy: -590.0, isSahi: true));
      _cannonballs.add(Cannonball(x: _galley.x - 10, y: _galley.y - 30, vx: -65.0, vy: -560.0, isSahi: true));
      _cannonballs.add(Cannonball(x: _galley.x + 10, y: _galley.y - 30, vx: 65.0, vy: -560.0, isSahi: true));
    } else {
      // Standard Bow Cannon Shot
      _cannonballs.add(Cannonball(x: _galley.x, y: _galley.y - 34, vx: 0.0, vy: -560.0, isSahi: false));
    }
    _particleSystem.addBurst(
      _galley.x,
      _galley.y - 34,
      isSahi ? const Color(0xFFFF1744) : const Color(0xFFFFB300),
      count: 5,
    );
  }

  void _triggerEmpBlast() {
    if (_gameState != GameState.playing) return;
    GameAudioService.instance.playSpecialAbility(_mode);

    if (_mode == GameMode.conquest1453) {
      _fireCannonballVolley();
      if (_empCooldown > 0) return;
      _empCooldown = 4.0;
      _empRadius = 10.0;
      _flashOpacity = 0.32;
      _flashColor = const Color(0xFFFFB300);

      int cleared = 0;
      for (final barrier in _seaBarriers) {
        if (!barrier.shattered && barrier.y > -20 && barrier.y < _galley.y + 40) {
          if (barrier.hasChain) {
            barrier.hasChain = false;
            _galley.chainsBroken++;
            cleared++;
            _particleSystem.addBurst(
              (barrier.gapLeft + barrier.gapRight) * 0.5,
              barrier.y,
              const Color(0xFFFFB300),
              count: 24,
            );
          }
        }
      }
      for (final ship in _enemyFireShips) {
        if (!ship.destroyed && ship.y > -20 && ship.y < _galley.y + 40) {
          ship.destroyed = true;
          cleared++;
          _particleSystem.addBurst(ship.x, ship.y, const Color(0xFFFF5722), count: 24);
        }
      }

      if (cleared > 0) {
        final bonus = cleared * 2;
        _score += bonus;
        _levelAnnouncement = 'ŞAHİ TOPU GÜMBÜRDEDİ! 💣 +$bonus';
        _announcementTimer = 1.4;
        _checkHighScore();
      } else {
        _levelAnnouncement = 'ŞAHİ TOPU ATEŞLENDİ! 💣';
        _announcementTimer = 1.0;
      }
      return;
    }

    if (_mode == GameMode.spaceOrbit) {
      if (_empCooldown > 0) return;
      _empCooldown = 4.0;
      _empRadius = 10.0;
      _flashOpacity = 0.28;
      _flashColor = const Color(0xFFB388FF);

      int cleared = 0;
      for (final gate in _orbitGates) {
        if (!gate.shattered && (_explorer.angle - gate.angle).abs() < math.pi * 0.8) {
          gate.shattered = true;
          cleared++;
        }
      }
      if (cleared > 0) {
        _score += cleared;
        _levelAnnouncement = 'SÜPERNOVA YOLU AÇTI! 💥 +$cleared';
        _announcementTimer = 1.3;
        _checkHighScore();
      } else {
        _levelAnnouncement = 'SÜPERNOVA DALGASI! 💥';
        _announcementTimer = 0.9;
      }
      return;
    }

    if (_mode != GameMode.cyberNeon) return;
    // Always fire a plasma shot when pressed
    _firePlasmaShot();

    if (_empCooldown > 0) return;
    _empCooldown = 4.0;
    _empRadius = 10.0;
    _flashOpacity = 0.35;
    _flashColor = const Color(0xFF00F3FF);

    int clearedCount = 0;
    for (final pipe in _pipes) {
      if (pipe.hasLaser && pipe.x > -20 && pipe.x < 460) {
        pipe.hasLaser = false;
        pipe.laserActive = false;
        clearedCount++;
        _particleSystem.addBurst(
          pipe.x + GameConstants.pipeWidth / 2,
          pipe.topHeight + pipe.gap / 2,
          const Color(0xFF00F3FF),
          count: 24,
        );
      }
    }

    for (final drone in _drones) {
      if (!drone.destroyed && drone.x > -20 && drone.x < 460) {
        drone.destroyed = true;
        clearedCount++;
        _particleSystem.addBurst(drone.x, drone.y, const Color(0xFFFF1744), count: 24);
      }
    }

    if (clearedCount > 0) {
      final bonus = clearedCount * 2;
      _score += bonus;
      _levelAnnouncement = 'EMP DALGASI! +$bonus ⚡';
      _announcementTimer = 1.3;
      _checkHighScore();
    } else {
      _levelAnnouncement = 'EMP ATEŞLENDİ! ⚡';
      _announcementTimer = 0.9;
    }
  }

  void _updateGame(double dt) {
    if (_gameState == GameState.menu) return;

    final gameWidth = _logicalWidth;
    final gameHeight = _logicalHeight;
    final groundY = gameHeight - GameConstants.groundHeight;
    final playableHeight = gameHeight - GameConstants.groundHeight;

    final difficulty = GameConstants.getDifficulty(_score);

    // Apply SlowMo time-scale in Cyber, Space Orbit, or Conquest Mode
    double effectiveDt = dt;
    if (_mode != GameMode.classic && _slowMoTimer > 0) {
      _slowMoTimer = math.max(0.0, _slowMoTimer - dt);
      effectiveDt = dt * 0.68;
    }

    _gameTime += effectiveDt;

    // Invulnerability timer countdown
    if (_invulnerableTimer > 0) {
      _invulnerableTimer = math.max(0.0, _invulnerableTimer - dt);
    }

    // EMP / Nova / Şahi wave cooldown & expansion
    if (_empCooldown > 0) {
      _empCooldown = math.max(0.0, _empCooldown - dt);
    }
    if (_empRadius > 0) {
      _empRadius += 720.0 * dt;
      if (_empRadius > 380.0) {
        _empRadius = 0.0;
      }
    }

    // Dedicated Mode 3 (Black Hole Space Orbit) Update Loop!
    if (_mode == GameMode.spaceOrbit) {
      _updateSpaceOrbitGame(dt, effectiveDt, gameWidth, gameHeight);
      return;
    }

    // Dedicated Mode 4 (1453 Conquest of Constantinople: Golden Horn Galley) Update Loop!
    if (_mode == GameMode.conquest1453) {
      _updateConquestGame(dt, effectiveDt, gameWidth, gameHeight);
      return;
    }

    // Cyber Auto-Fire:
    // - When Blaster Overdrive is active: rapid Heavy Pink Lasers (0.22s) that break pipes + lasers + drones!
    // - Standard Cyber Mode: steady Cyan Plasma Pulse (0.48s) that breaks Laser Gates & Enemy Drones!
    if (_mode == GameMode.cyberNeon && _gameState == GameState.playing) {
      if (_blasterTimer > 0) {
        _blasterTimer = math.max(0.0, _blasterTimer - dt);
      }
      _blasterFireCooldown -= dt;
      final fireInterval = _blasterTimer > 0 ? 0.22 : 0.48;
      if (_blasterFireCooldown <= 0) {
        _blasterFireCooldown = fireInterval;
        _firePlasmaShot();
      }
    }

    // Update projectiles
    for (int i = _projectiles.length - 1; i >= 0; i--) {
      _projectiles[i].x += 620.0 * dt;
      if (_projectiles[i].x > gameWidth + 60) {
        _projectiles.removeAt(i);
      }
    }

    // Update level milestone popup timer
    if (_announcementTimer > 0) {
      _announcementTimer = math.max(0.0, _announcementTimer - dt);
      if (_announcementTimer == 0.0) {
        _levelAnnouncement = null;
      }
    }

    // Update particles
    _particleSystem.update(dt);

    switch (_gameState) {
      case GameState.menu:
        break;

      case GameState.ready:
        _idleTime += dt;
        _bird.idleBob(_idleTime, gameHeight * 0.42);
        _groundOffset = (_groundOffset + difficulty.pipeSpeed * dt) % 1000;
        _parallaxOffset += difficulty.pipeSpeed * 0.35 * dt;

        if (_mode == GameMode.cyberNeon) {
          _particleSystem.addThrusterSparks(_bird.x - 18, _bird.y, const Color(0xFF00F3FF));
        }
        break;

      case GameState.playing:
        // Update Bird
        _bird.update(effectiveDt, groundY);

        // Cyber Thruster exhaust particles
        if (_mode == GameMode.cyberNeon) {
          _particleSystem.addThrusterSparks(
            _bird.x - 18,
            _bird.y,
            _slowMoTimer > 0 ? const Color(0xFFBA68C8) : const Color(0xFF00F3FF),
          );

          // Reset double jump if bird falls and starts dropping
          if (_bird.velocity > 180 && _jumpsUsed > 1) {
            _jumpsUsed = 1;
          }
        }

        // Ceiling protection
        if (_bird.y - GameConstants.birdHeight / 2 <= 0) {
          _bird.y = GameConstants.birdHeight / 2;
          _bird.velocity = 0;
        }

        // Ground collision check
        if (_bird.y + GameConstants.birdHeight / 2 >= groundY) {
          if (_mode == GameMode.cyberNeon && _invulnerableTimer > 0) {
            _bird.y = groundY - GameConstants.birdHeight / 2 - 4;
            _bird.velocity = -240.0;
          } else if (_mode == GameMode.cyberNeon && _hasShield) {
            // Shield protects against ground!
            _hasShield = false;
            _invulnerableTimer = 1.8;
            _comboStreak = 0;
            _bird.y = groundY - GameConstants.birdHeight / 2 - 10;
            _bird.velocity = GameConstants.jumpVelocity * 1.05;
            _flashOpacity = 0.7;
            _flashColor = const Color(0xFF00F3FF);
            _levelAnnouncement = 'KALKAN KURTARDI! 🛡️';
            _announcementTimer = 1.8;
            _particleSystem.addBurst(_bird.x, groundY - 12, const Color(0xFF00F3FF), count: 28);
          } else {
            _triggerGameOver(groundY);
            return;
          }
        }

        // Scroll ground and background
        _groundOffset = (_groundOffset + difficulty.pipeSpeed * effectiveDt) % 1000;
        _parallaxOffset += difficulty.pipeSpeed * 0.35 * effectiveDt;

        // Update Enemy Cyber Drones & Check Projectile / Bird Collisions
        if (_mode == GameMode.cyberNeon) {
          for (final drone in _drones) {
            if (drone.destroyed) continue;
            drone.update(effectiveDt, difficulty.pipeSpeed);

            // Check if any player projectile hits the drone
            for (int i = _projectiles.length - 1; i >= 0; i--) {
              if (_projectiles[i].getHitBox().overlaps(drone.getHitBox())) {
                drone.destroyed = true;
                _projectiles.removeAt(i);
                _particleSystem.addBurst(drone.x, drone.y, const Color(0xFFFF1744), count: 26);
                _particleSystem.addBurst(drone.x, drone.y, const Color(0xFF00F3FF), count: 14);
                _score += 2;
                _levelAnnouncement = 'DRON AVLANDI! 👾 +2';
                _announcementTimer = 1.1;
                _checkHighScore();
                break;
              }
            }

            if (drone.destroyed) continue;

            // Check if drone hits bird
            if (drone.getHitBox().overlaps(_bird.getHitBox())) {
              if (_invulnerableTimer > 0) {
                drone.destroyed = true;
                _particleSystem.addBurst(drone.x, drone.y, const Color(0xFF00F3FF), count: 20);
              } else if (_hasShield) {
                _hasShield = false;
                _invulnerableTimer = 1.8;
                _comboStreak = 0;
                drone.destroyed = true;
                _bird.velocity = -240.0;
                _flashOpacity = 0.7;
                _flashColor = const Color(0xFF00F3FF);
                _levelAnnouncement = 'KALKAN DRONU KIRDI! 🛡️';
                _announcementTimer = 1.6;
                _particleSystem.addBurst(drone.x, drone.y, const Color(0xFF00F3FF), count: 30);
              } else {
                _triggerGameOver(groundY);
                return;
              }
            }
          }
          _drones.removeWhere((d) => d.destroyed || d.x < -40);
        }

        // Update Pipes & Dynamic Movement & Collisions
        for (final pipe in _pipes) {
          pipe.x -= difficulty.pipeSpeed * effectiveDt;

          // Dynamic moving obstacle update in Cyber Neon Mode
          if (_mode == GameMode.cyberNeon) {
            pipe.updateMovement(_gameTime, playableHeight, effectiveDt);
          }

          // Pipe & Laser Gate collision check with player projectiles
          if (!pipe.shattered) {
            for (int i = _projectiles.length - 1; i >= 0; i--) {
              final bolt = _projectiles[i];
              final projRect = bolt.getHitBox();

              // 1. Any shot (Standard Cyan Plasma OR Heavy Pink Blaster) hitting the gap disables the Laser Gate!
              if (pipe.hasLaser && projRect.overlaps(pipe.getLaserTargetRect())) {
                pipe.hasLaser = false;
                pipe.laserActive = false;
                if (bolt.isHeavy) {
                  pipe.shattered = true;
                }
                _projectiles.removeAt(i);
                _particleSystem.addBurst(
                  pipe.x + GameConstants.pipeWidth / 2,
                  projRect.center.dy,
                  const Color(0xFF00F3FF),
                  count: 26,
                );
                _particleSystem.addBurst(
                  pipe.x + GameConstants.pipeWidth / 2,
                  projRect.center.dy,
                  const Color(0xFFFF1744),
                  count: 18,
                );
                _score += 1;
                _levelAnnouncement = 'LAZER İMHA! ⚡ +1';
                _announcementTimer = 1.0;
                _checkHighScore();
                break;
              }

              // 2. Hitting the solid pipe body:
              // Heavy Pink Blaster shatters the entire pipe! Standard Cyan Plasma sparks off solid metal.
              if (pipe.collidesWithBody(projRect, gameHeight)) {
                _projectiles.removeAt(i);
                if (bolt.isHeavy) {
                  pipe.shattered = true;
                  _particleSystem.addBurst(pipe.x + 30, projRect.center.dy, const Color(0xFFFF007F), count: 28);
                  _score += 1;
                  _levelAnnouncement = 'BORU PARÇALANDI! 💥 +1';
                  _announcementTimer = 1.0;
                  _checkHighScore();
                } else {
                  _particleSystem.addBurst(pipe.x + 6, projRect.center.dy, const Color(0xFF00F3FF), count: 6);
                }
                break;
              }
            }
          }

          // Score point when passing bird center
          if (!pipe.passed && (pipe.x + GameConstants.pipeWidth / 2 < _bird.x)) {
            pipe.passed = true;
            _jumpsUsed = 0; // Reset jumps upon clearing an obstacle!

            if (_mode == GameMode.cyberNeon) {
              _comboStreak++;
              final mult = _comboMultiplier;
              _score += mult;

              if (mult > 1 && _comboStreak % 3 == 0) {
                _levelAnnouncement = 'KOMBO x$mult! 🔥';
                _announcementTimer = 1.2;
              }
            } else {
              _score++;
            }

            // Level up check
            final newDifficulty = GameConstants.getDifficulty(_score);
            if (newDifficulty.level > _currentLevel) {
              _currentLevel = newDifficulty.level;
              _levelAnnouncement = newDifficulty.levelTitle;
              _announcementTimer = 2.0;
            }

            _checkHighScore();
          }

          // Pipe collision check
          if (pipe.collidesWith(_bird.getHitBox(), gameHeight)) {
            if (_mode == GameMode.cyberNeon && _invulnerableTimer > 0) {
              continue;
            } else if (_mode == GameMode.cyberNeon && _hasShield) {
              // Shield absorbs collision!
              _hasShield = false;
              _invulnerableTimer = 1.8;
              _comboStreak = 0; // Reset combo on hit
              pipe.shattered = true;
              pipe.hasLaser = false;
              _bird.velocity = -260.0;
              _flashOpacity = 0.7;
              _flashColor = const Color(0xFF00F3FF);
              _levelAnnouncement = 'KALKAN KURTARDI! 🛡️💥';
              _announcementTimer = 1.8;
              _particleSystem.addBurst(_bird.x, _bird.y, const Color(0xFF00F3FF), count: 32);
              _particleSystem.addBurst(pipe.x + 30, _bird.y, const Color(0xFFFF007F), count: 24);
            } else {
              _triggerGameOver(groundY);
              return;
            }
          }
        }

        // Update Cyber Power-Ups with Magnetic Attraction
        if (_mode == GameMode.cyberNeon) {
          for (final powerUp in _powerUps) {
            if (powerUp.collected) continue;
            powerUp.update(effectiveDt, difficulty.pipeSpeed);

            // Magnetic attraction for stars
            if (powerUp.type == PowerUpType.coin) {
              final dx = _bird.x - powerUp.x;
              final dy = _bird.y - powerUp.renderY;
              final dist = math.sqrt(dx * dx + dy * dy);
              if (dist < 110.0 && dist > 1.0) {
                powerUp.x += (dx / dist) * 180.0 * effectiveDt;
                powerUp.y += (dy / dist) * 180.0 * effectiveDt;
              }
            }

            // Check collection by bird
            if (powerUp.getHitBox().overlaps(_bird.getHitBox())) {
              powerUp.collected = true;
              _onCollectPowerUp(powerUp);
            }
          }
          _powerUps.removeWhere((p) => p.collected || p.x < -30);
        }

        // Remove offscreen pipes
        _pipes.removeWhere((p) => p.x + GameConstants.pipeWidth + 20 < 0);

        // Spawn new pipes using dynamic spacing
        if (_pipes.isEmpty || (gameWidth - _pipes.last.x >= difficulty.pipeSpacing)) {
          _spawnPipe(gameHeight, gameWidth, difficulty);
        }
        break;

      case GameState.gameOver:
        if (_bird.y + GameConstants.birdHeight / 2 < groundY) {
          _bird.velocity += GameConstants.gravity * dt * 1.5;
          _bird.y += _bird.velocity * dt;
          _bird.rotation = 1.35;
          if (_bird.y + GameConstants.birdHeight / 2 >= groundY) {
            _bird.y = groundY - GameConstants.birdHeight / 2;
            _bird.velocity = 0;
          }
        }
        break;
    }
  }

  void _updateSpaceOrbitGame(double dt, double effectiveDt, double gameWidth, double gameHeight) {
    final center = SpaceOrbitWorldPainter.getCameraCenter(
      Size(gameWidth, gameHeight),
      _explorer,
    );

    if (_announcementTimer > 0) {
      _announcementTimer = math.max(0.0, _announcementTimer - dt);
      if (_announcementTimer == 0.0) {
        _levelAnnouncement = null;
      }
    }

    _particleSystem.update(dt);

    switch (_gameState) {
      case GameState.menu:
        break;
      case GameState.ready:
        _idleTime += dt;
        _explorer.radius = SpaceExplorer.defaultRadius + math.sin(_idleTime * 3.5) * 6.0;
        break;
      case GameState.playing:
        final orbitDiff = SpaceOrbitDifficulty.fromScore(_score);
        _explorer.update(effectiveDt, orbitDiff.angularSpeed);

        // Check full 360-degree counter-clockwise orbit around the Black Hole
        final completedLaps = (_explorer.totalAngleTraversed / (2 * math.pi)).floor();
        if (completedLaps > _explorer.orbitsCompleted) {
          _explorer.orbitsCompleted = completedLaps;
          final ePos = _explorer.getPosition(center);
          _particleSystem.addBurst(ePos.dx, ePos.dy, const Color(0xFF00E5FF), count: 26);

          if (_explorer.orbitsCompleted % 7 == 0) {
            _score += 5;
            _hasShield = true;
            _levelAnnouncement = 'GALAKTİK DÖNGÜ TAMAMLANDI! (7 TUR) 🌌 +5';
            _announcementTimer = 2.2;
          } else {
            final orbitInCycle = _explorer.orbitsCompleted % 7;
            _score += 2;
            _levelAnnouncement = '$orbitInCycle. YÖRÜNGE TAMAMLANDI! 🪐 +2';
            _announcementTimer = 1.5;
          }
          _checkHighScore();
        }

        // Spawn radial asteroid/plasma gates ahead of the explorer with smooth gap transitions
        while (_explorer.angle - _nextGateAngle < math.pi * 1.45) {
          final gapSize = orbitDiff.gapSize;
          final minCenter = SpaceExplorer.minRadius + gapSize * 0.5 + 8.0;
          final maxCenter = SpaceExplorer.maxRadius - gapSize * 0.5 - 8.0;

          double gapCenter;
          if (_lastOrbitGapRadius == null) {
            gapCenter = SpaceExplorer.defaultRadius;
          } else {
            final low = math.max(minCenter, _lastOrbitGapRadius! - orbitDiff.maxGapDelta);
            final high = math.min(maxCenter, _lastOrbitGapRadius! + orbitDiff.maxGapDelta);
            gapCenter = low + _random.nextDouble() * (high - low);
          }
          _lastOrbitGapRadius = gapCenter;

          _orbitGates.add(
            OrbitGate(
              angle: _nextGateAngle,
              gapInnerRadius: gapCenter - gapSize / 2,
              gapOuterRadius: gapCenter + gapSize / 2,
            ),
          );

          // Spawn cosmic power-ups between gates (~48% chance)
          if (_random.nextDouble() < 0.48) {
            final roll = _random.nextDouble();
            CosmicPowerType pType;
            if (roll < 0.42) {
              pType = CosmicPowerType.starCrystal;
            } else if (roll < 0.78) {
              pType = CosmicPowerType.plasmaShield;
            } else {
              pType = CosmicPowerType.timeDilation;
            }
            final powerRadius = (gapCenter + (_random.nextDouble() - 0.5) * 44.0)
                .clamp(SpaceExplorer.minRadius + 16.0, SpaceExplorer.maxRadius - 16.0);
            _cosmicPowerUps.add(
              CosmicPowerUp(
                angle: _nextGateAngle - orbitDiff.gateSpacingAngle * 0.5,
                radius: powerRadius,
                type: pType,
              ),
            );
          }

          _nextGateAngle -= orbitDiff.gateSpacingAngle;
        }

        // Check gate passing & collisions
        for (final gate in _orbitGates) {
          if (!gate.passed && gate.isCrossedBy(_explorer.angle)) {
            gate.passed = true;
            _comboStreak++;
            _score += _comboMultiplier;

            // Announce Space Orbit difficulty stage progression
            final newStage = SpaceOrbitDifficulty.fromScore(_score);
            if (newStage.stage > _currentLevel) {
              _currentLevel = newStage.stage;
              _levelAnnouncement = newStage.stageTitle;
              _announcementTimer = 1.8;
            }

            _checkHighScore();
          }

          if (gate.collidesWith(_explorer.angle, _explorer.radius)) {
            if (_invulnerableTimer > 0) {
              continue;
            } else if (_hasShield) {
              _hasShield = false;
              _invulnerableTimer = 1.8;
              _comboStreak = 0;
              gate.shattered = true;
              _flashOpacity = 0.55;
              _flashColor = const Color(0xFF00E5FF);
              _levelAnnouncement = 'PLAZMA KALKANI KORUDU! 🛡️';
              _announcementTimer = 1.6;
              final ePos = _explorer.getPosition(center);
              _particleSystem.addBurst(ePos.dx, ePos.dy, const Color(0xFF00E5FF), count: 24);
            } else {
              _triggerGameOver(gameHeight);
              return;
            }
          }
        }

        // Update & collect cosmic power-ups
        final explorerPos = _explorer.getPosition(center);
        for (final power in _cosmicPowerUps) {
          if (power.collected) continue;
          power.update(effectiveDt);
          final pPos = power.getPosition(center);
          if ((explorerPos - pPos).distance < 34.0) {
            power.collected = true;
            switch (power.type) {
              case CosmicPowerType.plasmaShield:
                _hasShield = true;
                _levelAnnouncement = 'PLAZMA KALKANI ALINDI! 🛡️';
                _announcementTimer = 1.4;
                _particleSystem.addBurst(pPos.dx, pPos.dy, const Color(0xFF00E5FF), count: 20);
                break;
              case CosmicPowerType.starCrystal:
                final bonus = 3 * _comboMultiplier;
                _score += bonus;
                _levelAnnouncement = 'YILDIZ KRİSTALİ! +$bonus 💎';
                _announcementTimer = 1.3;
                _particleSystem.addBurst(pPos.dx, pPos.dy, const Color(0xFFFFD740), count: 20);
                _checkHighScore();
                break;
              case CosmicPowerType.timeDilation:
                _slowMoTimer = 4.5;
                _levelAnnouncement = 'ZAMAN BÜKÜLMESİ AKTİF! ⏳';
                _announcementTimer = 1.4;
                _particleSystem.addBurst(pPos.dx, pPos.dy, const Color(0xFFB388FF), count: 20);
                break;
            }
          }
        }

        // Clean up old gates & power-ups far behind the explorer
        _orbitGates.removeWhere((g) => g.angle - _explorer.angle > math.pi * 0.85);
        _cosmicPowerUps.removeWhere((p) => p.collected || (p.angle - _explorer.angle > math.pi * 0.85));
        break;

      case GameState.gameOver:
        break;
    }
  }

  void _updateConquestGame(double dt, double effectiveDt, double gameWidth, double gameHeight) {
    if (_announcementTimer > 0) {
      _announcementTimer = math.max(0.0, _announcementTimer - dt);
      if (_announcementTimer == 0.0) {
        _levelAnnouncement = null;
      }
    }

    _particleSystem.update(dt);

    switch (_gameState) {
      case GameState.menu:
        break;
      case GameState.ready:
        _idleTime += dt;
        _galley.x = gameWidth * 0.5 + math.sin(_idleTime * 2.5) * 18.0;
        _galley.y = gameHeight * 0.74;
        _galley.oarPhase = (_galley.oarPhase + dt * 5.0) % (2 * math.pi);
        break;
      case GameState.playing:
        final diff = ConquestDifficulty.fromScore(_score);
        _galley.update(effectiveDt, gameWidth, gameHeight);
        _groundOffset = (_groundOffset + diff.scrollSpeed * effectiveDt) % 10000;

        // Auto-fire bow cannonballs so chains & fire ships ahead are blasted!
        if (_blasterTimer > 0) {
          _blasterTimer = math.max(0.0, _blasterTimer - dt);
        }
        _blasterFireCooldown -= dt;
        final fireInterval = _blasterTimer > 0 ? 0.24 : 0.45;
        if (_blasterFireCooldown <= 0) {
          _blasterFireCooldown = fireInterval;
          _fireCannonballVolley();
        }

        // Update cannonballs
        for (int i = _cannonballs.length - 1; i >= 0; i--) {
          _cannonballs[i].update(dt);
          if (_cannonballs[i].y < -40 ||
              _cannonballs[i].x < 0 ||
              _cannonballs[i].x > gameWidth) {
            _cannonballs.removeAt(i);
          }
        }

        // Update Enemy Byzantine Fire Ships & Check Cannonball / Galley Collisions
        final minShipX = OttomanGalley.shoreWidth + 28.0;
        final maxShipX = gameWidth - OttomanGalley.shoreWidth - 28.0;
        for (final enemy in _enemyFireShips) {
          if (enemy.destroyed) continue;
          enemy.update(effectiveDt, diff.scrollSpeed, minShipX, maxShipX);

          // Check cannonball hit on enemy fire ship
          for (int i = _cannonballs.length - 1; i >= 0; i--) {
            if (_cannonballs[i].getHitBox().overlaps(enemy.getHitBox())) {
              enemy.destroyed = true;
              _cannonballs.removeAt(i);
              _particleSystem.addBurst(enemy.x, enemy.y, const Color(0xFFFF5722), count: 24);
              _particleSystem.addBurst(enemy.x, enemy.y, const Color(0xFFFFD54F), count: 14);
              _score += 2;
              _levelAnnouncement = 'RUM ATEŞİ GEMİSİ BATIRILDI! 💥 +2';
              _announcementTimer = 1.1;
              _checkHighScore();
              break;
            }
          }

          if (enemy.destroyed) continue;

          // Check collision with player's Ottoman Galley
          if (enemy.getHitBox().overlaps(_galley.getHitBox())) {
            if (_invulnerableTimer > 0) {
              enemy.destroyed = true;
              _particleSystem.addBurst(enemy.x, enemy.y, const Color(0xFFFFB300), count: 20);
            } else if (_hasShield) {
              _hasShield = false;
              _invulnerableTimer = 1.8;
              _comboStreak = 0;
              enemy.destroyed = true;
              _flashOpacity = 0.6;
              _flashColor = const Color(0xFF26C6DA);
              _levelAnnouncement = 'FATİH ZIRHI KORUDU! 🛡️';
              _announcementTimer = 1.5;
              _particleSystem.addBurst(enemy.x, enemy.y, const Color(0xFF26C6DA), count: 26);
            } else {
              _triggerGameOver(gameHeight);
              return;
            }
          }
        }
        _enemyFireShips.removeWhere((e) => e.destroyed || e.y > gameHeight + 60);

        // Update Sea Fortification Barriers & Haliç Iron Chains
        for (final barrier in _seaBarriers) {
          barrier.y += diff.scrollSpeed * effectiveDt;

          if (!barrier.shattered) {
            for (int i = _cannonballs.length - 1; i >= 0; i--) {
              final ball = _cannonballs[i];
              final ballBox = ball.getHitBox();

              // 1. Cannonball hitting the Haliç Iron Chain shatters the chain!
              if (barrier.hasChain && ballBox.overlaps(barrier.getChainTargetRect())) {
                barrier.hasChain = false;
                _galley.chainsBroken++;
                if (ball.isSahi) {
                  barrier.shattered = true;
                }
                _cannonballs.removeAt(i);
                _particleSystem.addBurst(
                  (barrier.gapLeft + barrier.gapRight) * 0.5,
                  barrier.y,
                  const Color(0xFFFFD54F),
                  count: 26,
                );
                _score += 2;
                _levelAnnouncement = 'HALİÇ ZİNCİRİ KIRILDI! ⛓️💥 +2';
                _announcementTimer = 1.2;
                _checkHighScore();
                break;
              }

              // 2. Heavy Şahi Cannonball hitting stone sea walls shatters the entire fortification!
              if (barrier.collidesWithWall(ballBox, gameWidth)) {
                _cannonballs.removeAt(i);
                if (ball.isSahi) {
                  barrier.shattered = true;
                  _particleSystem.addBurst(ball.x, barrier.y, const Color(0xFFFF5722), count: 26);
                  _score += 1;
                  _levelAnnouncement = 'SUR YIKILDI! 💣 +1';
                  _announcementTimer = 1.0;
                  _checkHighScore();
                } else {
                  _particleSystem.addBurst(ball.x, barrier.y + 10, const Color(0xFFD7CCC8), count: 5);
                }
                break;
              }
            }
          }

          // Score when passing barrier
          if (!barrier.passed && barrier.y > _galley.y) {
            barrier.passed = true;
            _comboStreak++;
            _score += _comboMultiplier;

            final newStage = ConquestDifficulty.fromScore(_score);
            if (newStage.stage > _currentLevel) {
              _currentLevel = newStage.stage;
              _levelAnnouncement = newStage.stageTitle;
              _announcementTimer = 1.8;
            }
            _checkHighScore();
          }

          // Check galley collision with barrier wall or unbroken chain
          if (barrier.collidesWithShip(_galley.getHitBox(), gameWidth)) {
            if (_invulnerableTimer > 0) {
              continue;
            } else if (_hasShield) {
              _hasShield = false;
              _invulnerableTimer = 1.8;
              _comboStreak = 0;
              barrier.shattered = true;
              barrier.hasChain = false;
              _flashOpacity = 0.65;
              _flashColor = const Color(0xFF26C6DA);
              _levelAnnouncement = 'FATİH ZIRHI SURU YARDI! 🛡️💥';
              _announcementTimer = 1.6;
              _particleSystem.addBurst(_galley.x, _galley.y - 20, const Color(0xFF26C6DA), count: 28);
            } else {
              _triggerGameOver(gameHeight);
              return;
            }
          }
        }

        // Update & collect Ottoman Conquest Supplies
        for (final supply in _conquestSupplies) {
          if (supply.collected) continue;
          supply.update(effectiveDt, diff.scrollSpeed);
          if (supply.getHitBox().overlaps(_galley.getHitBox())) {
            supply.collected = true;
            switch (supply.type) {
              case ConquestSupplyType.kizakShield:
                _hasShield = true;
                _levelAnnouncement = 'YAĞLI KIZAK ZIRHI ALINDI! 🛡️';
                _announcementTimer = 1.4;
                _particleSystem.addBurst(supply.x, supply.y, const Color(0xFF26C6DA), count: 20);
                break;
              case ConquestSupplyType.sahiPowder:
                _blasterTimer = 9.0;
                _levelAnnouncement = 'ŞAHİ BARUTU AKTİF! 💣';
                _announcementTimer = 1.4;
                _particleSystem.addBurst(supply.x, supply.y, const Color(0xFFFF1744), count: 24);
                break;
              case ConquestSupplyType.fetihBanner:
                final bonus = 3 * _comboMultiplier;
                _score += bonus;
                _levelAnnouncement = 'FETİH SANCAĞI! +$bonus 🌙';
                _announcementTimer = 1.3;
                _particleSystem.addBurst(supply.x, supply.y, const Color(0xFFFFD700), count: 22);
                _checkHighScore();
                break;
            }
          }
        }
        _conquestSupplies.removeWhere((s) => s.collected || s.y > gameHeight + 50);
        _seaBarriers.removeWhere((b) => b.y > gameHeight + 60);

        // Spawn new sea barriers from top
        if (_seaBarriers.isEmpty || _seaBarriers.last.y >= diff.barrierSpacing - 40) {
          _spawnSeaBarrier(gameWidth, diff);
        }
        break;

      case GameState.gameOver:
        break;
    }
  }

  void _spawnSeaBarrier(double gameWidth, ConquestDifficulty diff) {
    final minCenter = OttomanGalley.shoreWidth + diff.gapWidth * 0.5 + 18.0;
    final maxCenter = gameWidth - OttomanGalley.shoreWidth - diff.gapWidth * 0.5 - 18.0;
    if (maxCenter <= minCenter) return;

    double gapCenter;
    if (_lastConquestGapCenterX == null) {
      gapCenter = gameWidth * 0.5;
    } else {
      final low = math.max(minCenter, _lastConquestGapCenterX! - diff.maxGapDelta);
      final high = math.min(maxCenter, _lastConquestGapCenterX! + diff.maxGapDelta);
      gapCenter = low + _random.nextDouble() * (high - low);
    }
    _lastConquestGapCenterX = gapCenter;

    final spawnChain = _score >= 2 && _random.nextDouble() < 0.42;
    const spawnY = -40.0;

    _seaBarriers.add(
      SeaBarrier(
        y: spawnY,
        gapLeft: gapCenter - diff.gapWidth * 0.5,
        gapRight: gapCenter + diff.gapWidth * 0.5,
        hasChain: spawnChain,
      ),
    );

    // Spawn Enemy Byzantine Fire Ship in the water between barriers (~38% chance)
    if (_score >= 1 && _random.nextDouble() < 0.38) {
      final shipX = (gapCenter + (_random.nextDouble() - 0.5) * 90.0)
          .clamp(minCenter, maxCenter);
      _enemyFireShips.add(
        EnemyFireShip(
          x: shipX,
          y: spawnY - diff.barrierSpacing * 0.5,
          phase: _random.nextDouble() * math.pi * 2,
        ),
      );
    }

    // Spawn Ottoman Conquest Supply (~38% chance when no chain is on the gap)
    if (!spawnChain && _random.nextDouble() < 0.38) {
      final roll = _random.nextDouble();
      ConquestSupplyType sType;
      if (roll < 0.40) {
        sType = ConquestSupplyType.fetihBanner;
      } else if (roll < 0.72) {
        sType = ConquestSupplyType.kizakShield;
      } else {
        sType = ConquestSupplyType.sahiPowder;
      }
      _conquestSupplies.add(
        ConquestSupply(
          x: gapCenter,
          y: spawnY,
          type: sType,
        ),
      );
    }
  }

  void _onCollectPowerUp(PowerUp powerUp) {
    switch (powerUp.type) {
      case PowerUpType.coin:
        final bonus = 2 * _comboMultiplier;
        _score += bonus;
        _levelAnnouncement = '+$bonus YILDIZ! ⭐';
        _announcementTimer = 1.2;
        _particleSystem.addBurst(powerUp.x, powerUp.renderY, const Color(0xFFFFD700), count: 18);
        _checkHighScore();
        break;
      case PowerUpType.shield:
        _hasShield = true;
        _levelAnnouncement = 'KALKAN ALINDI! 🛡️';
        _announcementTimer = 1.4;
        _particleSystem.addBurst(powerUp.x, powerUp.renderY, const Color(0xFF00F3FF), count: 22);
        break;
      case PowerUpType.slowMo:
        _slowMoTimer = 4.0;
        _levelAnnouncement = 'ZAMAN YAVAŞLADI! ⚡';
        _announcementTimer = 1.4;
        _particleSystem.addBurst(powerUp.x, powerUp.renderY, const Color(0xFFBA68C8), count: 20);
        break;
      case PowerUpType.blaster:
        _blasterTimer = 10.0;
        _levelAnnouncement = 'SÜPER SİLAH AKTİF! 🔫';
        _announcementTimer = 1.4;
        _particleSystem.addBurst(powerUp.x, powerUp.renderY, const Color(0xFFFF007F), count: 25);
        break;
    }
  }

  void _checkHighScore() {
    if (_mode == GameMode.classic) {
      if (_score > _classicHighScore) {
        _classicHighScore = _score;
        _isNewHighScore = true;
        _saveHighScore(_classicHighScore);
      }
    } else if (_mode == GameMode.cyberNeon) {
      if (_score > _cyberHighScore) {
        _cyberHighScore = _score;
        _isNewHighScore = true;
        _saveHighScore(_cyberHighScore);
      }
    } else if (_mode == GameMode.spaceOrbit) {
      if (_score > _spaceHighScore) {
        _spaceHighScore = _score;
        _isNewHighScore = true;
        _saveHighScore(_spaceHighScore);
      }
    } else if (_mode == GameMode.conquest1453) {
      if (_score > _conquestHighScore) {
        _conquestHighScore = _score;
        _isNewHighScore = true;
        _saveHighScore(_conquestHighScore);
      }
    }
  }

  void _spawnPipe(double gameHeight, double gameWidth, DifficultyConfig difficulty) {
    final playableHeight = gameHeight - GameConstants.groundHeight;
    final gap = difficulty.pipeGap;
    final minGapCenter = GameConstants.minPipeHeight + gap / 2;
    final maxGapCenter = playableHeight - GameConstants.minPipeHeight - gap / 2;

    if (maxGapCenter <= minGapCenter) return;

    double targetCenter;
    if (_lastGapCenterY == null) {
      targetCenter = playableHeight * 0.48;
    } else {
      final minBound = math.max(minGapCenter, _lastGapCenterY! - difficulty.maxGapDelta);
      final maxBound = math.min(maxGapCenter, _lastGapCenterY! + difficulty.maxGapDelta);
      targetCenter = minBound + _random.nextDouble() * (maxBound - minBound);
    }
    _lastGapCenterY = targetCenter;

    final topHeight = targetCenter - gap / 2;
    final bottomHeight = playableHeight - targetCenter - gap / 2;

    final pipeX = gameWidth + 10;

    // In Cyber Neon Mode, moving obstacles and shootable laser gates
    double moveSpeed = 0.0;
    double moveAmp = 0.0;
    bool spawnLaser = false;

    if (_mode == GameMode.cyberNeon) {
      if (_score >= 6 && _random.nextDouble() < 0.35) {
        moveSpeed = 2.2;
        moveAmp = 20.0;
      }
      if (_score >= 4 && _random.nextDouble() < 0.32) {
        spawnLaser = true;
      }
    }

    _pipes.add(
      PipePair(
        x: pipeX,
        topHeight: topHeight,
        bottomHeight: bottomHeight,
        gap: gap,
        moveSpeed: moveSpeed,
        moveAmplitude: moveAmp,
        hasLaser: spawnLaser,
      ),
    );

    // Spawn Enemy Cyber Drone in the corridor between pipes (~35% chance in Cyber Mode)
    if (_mode == GameMode.cyberNeon && _score >= 2 && _random.nextDouble() < 0.35) {
      final droneY = (targetCenter + (_random.nextDouble() - 0.5) * 70.0)
          .clamp(minGapCenter, maxGapCenter);
      _drones.add(
        EnemyDrone(
          x: pipeX + difficulty.pipeSpacing * 0.52,
          baseY: droneY,
          phase: _random.nextDouble() * math.pi * 2,
        ),
      );
    }

    // Balanced Power-Up Spawning: ~32% chance (only if pipe doesn't have a laser crystal in center)
    if (_mode == GameMode.cyberNeon && !spawnLaser && _random.nextDouble() < 0.32) {
      final roll = _random.nextDouble();
      PowerUpType type;
      if (roll < 0.38) {
        type = PowerUpType.coin; // 38% Star Coin
      } else if (roll < 0.60) {
        type = PowerUpType.shield; // 22% Shield
      } else if (roll < 0.78) {
        type = PowerUpType.slowMo; // 18% Slow-Mo
      } else {
        type = PowerUpType.blaster; // 22% Blaster Overdrive
      }

      _powerUps.add(
        PowerUp(
          x: pipeX + GameConstants.pipeWidth / 2,
          y: targetCenter,
          type: type,
        ),
      );
    }
  }

  void _triggerGameOver(double groundY) {
    GameAudioService.instance.playHit();
    _gameState = GameState.gameOver;
    _flashOpacity = 0.85;
    _flashColor = Colors.white;
    _canRestart = false;
    _comboStreak = 0;

    if (_mode == GameMode.cyberNeon) {
      _particleSystem.addBurst(_bird.x, _bird.y, const Color(0xFFFF007F), count: 28);
    } else if (_mode == GameMode.conquest1453) {
      _particleSystem.addBurst(_galley.x, _galley.y, const Color(0xFFFF5722), count: 28);
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _canRestart = true;
        });
      }
    });
  }

  void _onActionTriggered([int? forcedSteerDir]) {
    switch (_gameState) {
      case GameState.menu:
        break;
      case GameState.ready:
        GameAudioService.instance.playJump(_mode);
        setState(() {
          _gameState = GameState.playing;
          _jumpsUsed = 1;
          if (_mode == GameMode.spaceOrbit) {
            _explorer.thrustOutward();
          } else if (_mode == GameMode.conquest1453) {
            _galley.tack(forcedSteerDir);
            _fireCannonballVolley();
          } else {
            _bird.jump();
            _firePlasmaShot();
          }
        });
        break;
      case GameState.playing:
        GameAudioService.instance.playJump(_mode);
        if (_mode == GameMode.spaceOrbit) {
          _explorer.thrustOutward();
        } else if (_mode == GameMode.conquest1453) {
          _galley.tack(forcedSteerDir);
          _fireCannonballVolley();
        } else if (_mode == GameMode.cyberNeon) {
          _firePlasmaShot();
          if (_jumpsUsed == 0) {
            _bird.jump();
            _jumpsUsed = 1;
          } else if (_jumpsUsed == 1) {
            _bird.velocity = GameConstants.jumpVelocity * 0.95;
            _bird.rotation = -0.42;
            _jumpsUsed = 2;
            _particleSystem.addBurst(_bird.x - 14, _bird.y + 4, const Color(0xFFFF007F), count: 16);
            _particleSystem.addBurst(_bird.x - 14, _bird.y + 4, const Color(0xFF00F3FF), count: 12);
          } else {
            _bird.jump();
          }
        } else {
          _bird.jump();
        }
        _repaintTick.value++;
        break;
      case GameState.gameOver:
        if (_canRestart) {
          _restartGame();
        }
        break;
    }
  }

  void _startWithMode(GameMode mode) {
    final isWide = mode == GameMode.spaceOrbit || mode == GameMode.conquest1453;
    _logicalWidth = isWide
        ? GameConstants.logicalWideWidth
        : GameConstants.logicalStandardWidth;

    _lastTick = Duration.zero;
    _ticker.muted = false;

    setState(() {
      _mode = mode;
      _gameState = GameState.ready;
      _score = 0;
      _currentLevel = 1;
      _levelAnnouncement = null;
      _announcementTimer = 0.0;
      _lastGapCenterY = null;
      _gameTime = 0.0;
      _hasShield = false;
      _slowMoTimer = 0.0;
      _invulnerableTimer = 0.0;
      _blasterTimer = 0.0;
      _blasterFireCooldown = 0.0;
      _empRadius = 0.0;
      _empCooldown = 0.0;
      _jumpsUsed = 0;
      _comboStreak = 0;
      _isNewHighScore = false;
      _pipes.clear();
      _powerUps.clear();
      _projectiles.clear();
      _drones.clear();
      _orbitGates.clear();
      _cosmicPowerUps.clear();
      _explorer.reset();
      _nextGateAngle = SpaceExplorer.startAngle - math.pi * 0.90;
      _lastOrbitGapRadius = null;
      _seaBarriers.clear();
      _cannonballs.clear();
      _enemyFireShips.clear();
      _conquestSupplies.clear();
      _lastConquestGapCenterX = null;
      _galley.reset(_logicalWidth, _logicalHeight);
      _particleSystem.particles.clear();
      _bird.reset(_logicalHeight * 0.42);
      _flashOpacity = 0.0;
      _canRestart = false;
    });
  }

  void _returnToMenu() {
    // Menüye dönüldüğünde oyun döngüsünü duraklat (CPU/GPU tasarrufu)
    _ticker.muted = true;
    _lastTick = Duration.zero;

    setState(() {
      _gameState = GameState.menu;
      _pipes.clear();
      _powerUps.clear();
      _projectiles.clear();
      _drones.clear();
      _orbitGates.clear();
      _cosmicPowerUps.clear();
      _seaBarriers.clear();
      _cannonballs.clear();
      _enemyFireShips.clear();
      _conquestSupplies.clear();
      _particleSystem.particles.clear();
    });
  }

  void _restartGame() {
    _lastTick = Duration.zero;
    _ticker.muted = false;

    setState(() {
      _gameState = GameState.ready;
      _score = 0;
      _currentLevel = 1;
      _levelAnnouncement = null;
      _announcementTimer = 0.0;
      _lastGapCenterY = null;
      _gameTime = 0.0;
      _hasShield = false;
      _slowMoTimer = 0.0;
      _invulnerableTimer = 0.0;
      _blasterTimer = 0.0;
      _blasterFireCooldown = 0.0;
      _empRadius = 0.0;
      _empCooldown = 0.0;
      _jumpsUsed = 0;
      _comboStreak = 0;
      _isNewHighScore = false;
      _pipes.clear();
      _powerUps.clear();
      _projectiles.clear();
      _drones.clear();
      _orbitGates.clear();
      _cosmicPowerUps.clear();
      _explorer.reset();
      _nextGateAngle = SpaceExplorer.startAngle - math.pi * 0.90;
      _lastOrbitGapRadius = null;
      _seaBarriers.clear();
      _cannonballs.clear();
      _enemyFireShips.clear();
      _conquestSupplies.clear();
      _lastConquestGapCenterX = null;
      _galley.reset(_logicalWidth, _logicalHeight);
      _particleSystem.particles.clear();
      _bird.reset(_logicalHeight * 0.42);
      _flashOpacity = 0.0;
      _canRestart = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCyber = _mode == GameMode.cyberNeon;
    final isSpace = _mode == GameMode.spaceOrbit;
    final isConquest = _mode == GameMode.conquest1453;
    final isSpecialMode = isCyber || isSpace || isConquest;
    final currentDifficulty = GameConstants.getDifficulty(_score);

    // 1. MENÜ EKRANI: Sabit piksel yerine LayoutBuilder + ConstrainedBox ile responsive yapı
    if (_gameState == GameState.menu) {
      return Scaffold(
        backgroundColor: const Color(0xFF100C22),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 480;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460.0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: isWideScreen
                        ? const [
                            BoxShadow(
                              color: Colors.black54,
                              blurRadius: 28,
                              spreadRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: constraints.maxHeight,
                    child: ModeSelectScreen(
                      classicHighScore: _classicHighScore,
                      cyberHighScore: _cyberHighScore,
                      spaceHighScore: _spaceHighScore,
                      conquestHighScore: _conquestHighScore,
                      onSelectMode: _startWithMode,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    // 2. OYUN EKRANI: 9:16 AspectRatio + FittedBox + SafeArea + RepaintBoundary İzolasyonu
    return Scaffold(
      backgroundColor: isSpace
          ? const Color(0xFF070412)
          : isConquest
              ? const Color(0xFF071624)
              : const Color(0xFF151522),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final targetLogicalW = (isSpace || isConquest)
                ? GameConstants.logicalWideWidth
                : GameConstants.logicalStandardWidth;
            final targetLogicalH = targetLogicalW * (16.0 / 9.0);

            _logicalWidth = targetLogicalW;
            _logicalHeight = targetLogicalH;

            final isWideWindow = constraints.maxWidth > targetLogicalW + 24;
            final canvasSize = Size(_logicalWidth, _logicalHeight);

            return Center(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: FittedBox(
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  child: Container(
                    width: _logicalWidth,
                    height: _logicalHeight,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      boxShadow: isWideWindow
                          ? [
                              BoxShadow(
                                color: isCyber
                                    ? const Color(0xFF00F3FF).withValues(alpha: 0.25)
                                : isSpace
                                    ? const Color(0xFFB388FF).withValues(alpha: 0.28)
                                    : isConquest
                                        ? const Color(0xFFE53935).withValues(alpha: 0.28)
                                        : Colors.black54,
                            blurRadius: 28,
                            spreadRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Focus(
                  focusNode: _focusNode,
                  autofocus: true,
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent) {
                      if (event.logicalKey == LogicalKeyboardKey.keyM ||
                          event.logicalKey == LogicalKeyboardKey.escape) {
                        _returnToMenu();
                        return KeyEventResult.handled;
                      }

                      if (event.logicalKey == LogicalKeyboardKey.keyX ||
                          event.logicalKey == LogicalKeyboardKey.keyE ||
                          event.logicalKey == LogicalKeyboardKey.keyF ||
                          event.logicalKey == LogicalKeyboardKey.shiftLeft ||
                          event.logicalKey == LogicalKeyboardKey.shiftRight) {
                        _triggerEmpBlast();
                        return KeyEventResult.handled;
                      }

                      if (isConquest &&
                          (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                              event.logicalKey == LogicalKeyboardKey.keyA)) {
                        _onActionTriggered(-1);
                        return KeyEventResult.handled;
                      }
                      if (isConquest &&
                          (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                              event.logicalKey == LogicalKeyboardKey.keyD)) {
                        _onActionTriggered(1);
                        return KeyEventResult.handled;
                      }

                      if (event.logicalKey == LogicalKeyboardKey.space ||
                          event.logicalKey == LogicalKeyboardKey.arrowUp ||
                          event.logicalKey == LogicalKeyboardKey.keyW ||
                          event.logicalKey == LogicalKeyboardKey.enter) {
                        _onActionTriggered();
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // KATMAN A: İzole Edilmiş Oyun Canvas Katmanı (RepaintBoundary)
                      // _repaintTick (ValueNotifier) sayesinde HUD widget'larını rebuild etmeden
                      // doğrudan GPU/Canvas üzerinde 60/120 FPS çizilir.
                      RepaintBoundary(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (isConquest) ...[
                              CustomPaint(
                                size: canvasSize,
                                painter: ConquestWorldPainter(
                                  galley: _galley,
                                  barriers: _seaBarriers,
                                  cannonballs: _cannonballs,
                                  enemyShips: _enemyFireShips,
                                  supplies: _conquestSupplies,
                                  scrollOffset: _groundOffset,
                                  gameTime: _gameTime,
                                  hasArmorShield: _hasShield,
                                  isInvulnerable: _invulnerableTimer > 0,
                                  hasSahiBuff: _blasterTimer > 0,
                                  sahiWaveRadius: _empRadius,
                                  skinIndex: GameStorageService.instance.getSelectedSkin(_mode),
                                  repaint: _repaintTick,
                                ),
                              ),
                              CustomPaint(
                                size: canvasSize,
                                painter: ParticlePainter(
                                  particles: _particleSystem.particles,
                                  repaint: _repaintTick,
                                ),
                              ),
                            ] else if (isSpace) ...[
                              CustomPaint(
                                size: canvasSize,
                                painter: SpaceOrbitWorldPainter(
                                  explorer: _explorer,
                                  gates: _orbitGates,
                                  powerUps: _cosmicPowerUps,
                                  gameTime: _gameTime,
                                  hasPlasmaShield: _hasShield,
                                  isInvulnerable: _invulnerableTimer > 0,
                                  novaWaveRadius: _empRadius,
                                  skinIndex: GameStorageService.instance.getSelectedSkin(_mode),
                                  repaint: _repaintTick,
                                ),
                              ),
                              CustomPaint(
                                size: canvasSize,
                                painter: ParticlePainter(
                                  particles: _particleSystem.particles,
                                  repaint: _repaintTick,
                                ),
                              ),
                            ] else ...[
                              if (isCyber)
                                CustomPaint(
                                  size: canvasSize,
                                  painter: CyberBackgroundPainter(
                                    parallaxOffset: _parallaxOffset,
                                    repaint: _repaintTick,
                                  ),
                                )
                              else
                                CustomPaint(
                                  size: canvasSize,
                                  painter: BackgroundPainter(
                                    parallaxOffset: _parallaxOffset,
                                    repaint: _repaintTick,
                                  ),
                                ),
                              if (isCyber)
                                CustomPaint(
                                  size: canvasSize,
                                  painter: CyberPipePainter(
                                    pipes: _pipes,
                                    gameHeight: _logicalHeight,
                                    repaint: _repaintTick,
                                  ),
                                )
                              else
                                CustomPaint(
                                  size: canvasSize,
                                  painter: PipePainter(
                                    pipes: _pipes,
                                    gameHeight: _logicalHeight,
                                    repaint: _repaintTick,
                                  ),
                                ),
                              if (isCyber)
                                CustomPaint(
                                  size: canvasSize,
                                  painter: PowerUpPainter(
                                    powerUps: _powerUps,
                                    repaint: _repaintTick,
                                  ),
                                ),
                              if (isCyber)
                                CustomPaint(
                                  size: canvasSize,
                                  painter: CyberGroundPainter(
                                    groundOffset: _groundOffset,
                                    repaint: _repaintTick,
                                  ),
                                )
                              else
                                CustomPaint(
                                  size: canvasSize,
                                  painter: GroundPainter(
                                    groundOffset: _groundOffset,
                                    repaint: _repaintTick,
                                  ),
                                ),
                              CustomPaint(
                                size: canvasSize,
                                painter: ParticlePainter(
                                  particles: _particleSystem.particles,
                                  repaint: _repaintTick,
                                ),
                              ),
                              if (isCyber)
                                CustomPaint(
                                  size: canvasSize,
                                  painter: CyberBirdPainter(
                                    bird: _bird,
                                    hasShield: _hasShield,
                                    isInvulnerable: _invulnerableTimer > 0,
                                    empRadius: _empRadius,
                                    projectiles: _projectiles,
                                    drones: _drones,
                                    skinIndex: GameStorageService.instance.getSelectedSkin(_mode),
                                    repaint: _repaintTick,
                                  ),
                                )
                              else
                                CustomPaint(
                                  size: canvasSize,
                                  painter: BirdPainter(
                                    bird: _bird,
                                    skinIndex: GameStorageService.instance.getSelectedSkin(_mode),
                                    repaint: _repaintTick,
                                  ),
                                ),
                            ],
                            // Gerçek Zamanlı GLSL Fragment Shader Atmosfer Katmanı (Impeller GPU)
                            IgnorePointer(
                              child: CustomPaint(
                                size: canvasSize,
                                painter: RealmShaderOverlayPainter(
                                  mode: _mode,
                                  gameTime: _gameTime,
                                  intensity: (_empRadius > 0 || _slowMoTimer > 0) ? 1.0 : 0.0,
                                  repaint: _repaintTick,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // KATMAN B: Dokunma Alanı
                      if (_gameState == GameState.playing)
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (_) {
                              _focusNode.requestFocus();
                              _onActionTriggered();
                            },
                          ),
                        ),

                      // KATMAN C: İzole Edilmiş HUD & Arayüz Katmanı (RepaintBoundary + SafeArea)
                      RepaintBoundary(
                        child: SafeArea(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Özel Yetenek Butonu (EMP / NOVA / ŞAHİ)
                              if (_gameState == GameState.playing && isSpecialMode)
                                Positioned(
                                  bottom: 24,
                                  right: 16,
                                  child: GestureDetector(
                                    onTapDown: (_) {
                                      _focusNode.requestFocus();
                                      _triggerEmpBlast();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _empCooldown <= 0
                                            ? (isSpace
                                                ? const Color(0xFFB388FF).withValues(alpha: 0.28)
                                                : isConquest
                                                    ? const Color(0xFFE53935).withValues(alpha: 0.32)
                                                    : const Color(0xFF00F3FF).withValues(alpha: 0.25))
                                            : Colors.black54,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: _empCooldown <= 0
                                              ? (isSpace
                                                  ? const Color(0xFFB388FF)
                                                  : isConquest
                                                      ? const Color(0xFFFFB300)
                                                      : const Color(0xFF00F3FF))
                                              : Colors.white30,
                                          width: 2,
                                        ),
                                        boxShadow: _empCooldown <= 0
                                            ? [
                                                BoxShadow(
                                                  color: isSpace
                                                      ? const Color(0x66B388FF)
                                                      : isConquest
                                                          ? const Color(0x66D4AF37)
                                                          : const Color(0x6600F3FF),
                                                  blurRadius: 10,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isSpace
                                                ? Icons.flare
                                                : isConquest
                                                    ? Icons.local_fire_department
                                                    : Icons.bolt,
                                            size: 18,
                                            color: _empCooldown <= 0
                                                ? (isSpace
                                                    ? const Color(0xFFFF9100)
                                                    : isConquest
                                                        ? const Color(0xFFFFD54F)
                                                        : const Color(0xFF00F3FF))
                                                : Colors.white54,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _empCooldown <= 0
                                                ? (isSpace
                                                    ? 'NOVA [X]'
                                                    : isConquest
                                                        ? 'ŞAHİ [X]'
                                                        : 'EMP [X]')
                                                : '${(isSpace ? "NOVA" : isConquest ? "ŞAHİ" : "EMP")} ${_empCooldown.toStringAsFixed(1)}s',
                                            style: _empCooldown <= 0
                                                ? _hudActionActiveStyle
                                                : _hudActionCooldownStyle,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                              // Üst Skor, Yörünge/Zincir ve Aktif Güçlendirme Rozetleri
                              if (_gameState == GameState.playing)
                                Positioned(
                                  top: 16,
                                  left: 12,
                                  right: 12,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: isCyber
                                                      ? const Color(0xFF00F3FF).withValues(alpha: 0.6)
                                                      : isSpace
                                                          ? const Color(0xFFB388FF).withValues(alpha: 0.8)
                                                          : isConquest
                                                              ? const Color(0xFFD4AF37).withValues(alpha: 0.8)
                                                              : Colors.white24,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                isSpace
                                                    ? '🪐 YÖRÜNGE: ${_explorer.orbitsCompleted % 7}/7 (GALAKSİ: ${_explorer.orbitsCompleted ~/ 7})'
                                                    : isConquest
                                                        ? '⚓ ZİNCİR: ${_galley.chainsBroken} • DÜMEN: ${_galley.steerDir > 0 ? "SANCAK ▶" : "◀ İSKELE"}'
                                                        : currentDifficulty.levelTitle,
                                                overflow: TextOverflow.ellipsis,
                                                style: _hudBadgeStyle.copyWith(
                                                  color: isSpace
                                                      ? const Color(0xFFB388FF)
                                                      : isConquest
                                                          ? const Color(0xFFFFD54F)
                                                          : Colors.white.withValues(alpha: 0.9),
                                                ),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: _returnToMenu,
                                            tooltip: 'Menü [M]',
                                            icon: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.black45,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white30),
                                              ),
                                              child: const Icon(
                                                Icons.menu,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Scoreboard(score: _score),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        alignment: WrapAlignment.center,
                                        children: [
                                          if (isSpecialMode && _comboStreak >= 3)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isSpace
                                                    ? const Color(0xFF4A148C)
                                                    : isConquest
                                                        ? const Color(0xFFC62828)
                                                        : const Color(0xFFFF007F),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: Colors.white, width: 1),
                                              ),
                                              child: Text(
                                                isSpace
                                                    ? 'KOZMİK x$_comboMultiplier 🪐'
                                                    : isConquest
                                                        ? 'FETİH x$_comboMultiplier ⚔️'
                                                        : 'KOMBO x$_comboMultiplier 🔥',
                                                style: _hudBadgeStyle,
                                              ),
                                            ),
                                          if ((isCyber || isConquest) && _blasterTimer > 0)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isConquest
                                                    ? const Color(0xFFB71C1C)
                                                    : const Color(0xFF880E4F),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: isConquest
                                                      ? const Color(0xFFFFD54F)
                                                      : const Color(0xFFFF007F),
                                                ),
                                              ),
                                              child: Text(
                                                '${isConquest ? "💣 ŞAHİ BARUTU" : "🔫 SÜPER SİLAH"} ${_blasterTimer.toStringAsFixed(1)}s',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          if (isSpecialMode && _hasShield)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF00838F),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: const Color(0xFF00F3FF)),
                                              ),
                                              child: Text(
                                                isSpace
                                                    ? '🛡️ PLAZMA KALKANI'
                                                    : isConquest
                                                        ? '🛡️ FATİH ZIRHI'
                                                        : '🛡️ KALKAN',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          if (isSpecialMode && _invulnerableTimer > 0)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF00B0FF),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: Colors.white),
                                              ),
                                              child: const Text(
                                                '✨ KORUNUYOR',
                                                style: TextStyle(fontSize: 10, color: Colors.white),
                                              ),
                                            ),
                                          if (isSpecialMode && _slowMoTimer > 0)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isSpace
                                                    ? const Color(0xFF311B92)
                                                    : const Color(0xFF6A1B9A),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: const Color(0xFFE1BEE7)),
                                              ),
                                              child: Text(
                                                '${isSpace ? "⏳ ZAMAN BÜKÜLMESİ" : "⚡"} ${(_slowMoTimer).toStringAsFixed(1)}s',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                              // Seviye / Başarım Bildirim Afişi
                              if (_gameState == GameState.playing && _levelAnnouncement != null)
                                Positioned(
                                  top: 132,
                                  left: 12,
                                  right: 12,
                                  child: Center(
                                    child: AnimatedOpacity(
                                      opacity: _announcementTimer > 0.4
                                          ? 1.0
                                          : (_announcementTimer / 0.4),
                                      duration: const Duration(milliseconds: 100),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isCyber
                                              ? const Color(0xFF1E143E)
                                              : isSpace
                                                  ? const Color(0xFF0B071C)
                                                  : isConquest
                                                      ? const Color(0xFF2A0E12)
                                                      : const Color(0xFFF7CF34),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isCyber
                                                ? const Color(0xFF00F3FF)
                                                : isSpace
                                                    ? const Color(0xFFB388FF)
                                                    : isConquest
                                                        ? const Color(0xFFD4AF37)
                                                        : const Color(0xFF2C2416),
                                            width: 3,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: isCyber
                                                  ? const Color(0xFF00F3FF).withValues(alpha: 0.4)
                                                  : isSpace
                                                      ? const Color(0xFFB388FF).withValues(alpha: 0.45)
                                                      : isConquest
                                                          ? const Color(0xFFD4AF37).withValues(alpha: 0.4)
                                                          : Colors.black38,
                                              offset: const Offset(0, 5),
                                              blurRadius: isSpecialMode ? 12 : 0,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          _levelAnnouncement!,
                                          textAlign: TextAlign.center,
                                          style: _hudBadgeStyle.copyWith(
                                            fontSize: 10.5,
                                            color: isCyber
                                                ? const Color(0xFF00F3FF)
                                                : isSpace
                                                    ? const Color(0xFFFF9100)
                                                    : isConquest
                                                        ? const Color(0xFFFFD54F)
                                                        : const Color(0xFF2C2416),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              // Hazır (Ready) Katmanı
                              if (_gameState == GameState.ready)
                                ReadyOverlay(
                                  mode: _mode,
                                  highScore: _currentHighScore,
                                  onStart: _onActionTriggered,
                                  onOpenMenu: _returnToMenu,
                                ),

                              // Oyun Bitti (Game Over) Diyaloğu
                              if (_gameState == GameState.gameOver)
                                GameOverDialog(
                                  mode: _mode,
                                  score: _score,
                                  bestScore: _currentHighScore,
                                  isNewHighScore: _isNewHighScore,
                                  onRestart: _restartGame,
                                  onReturnToMenu: _returnToMenu,
                                ),
                            ],
                          ),
                        ),
                      ),

                      // KATMAN D: Çarpışma Flaş Efekti
                      if (_flashOpacity > 0.0)
                        IgnorePointer(
                          child: Container(
                            color: _flashColor.withValues(alpha: _flashOpacity),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
        ),
      ),
    );
  }
}
