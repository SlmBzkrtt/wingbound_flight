# WingBound: Multi Realms (v1.0.0)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart)](https://dart.dev)
[![Version](https://img.shields.io/badge/Release-v1.0.0-00E5FF)](https://github.com/SlmBzkrtt/wingbound_flight/releases/tag/v1.0.0)
[![Bundle ID](https://img.shields.io/badge/Bundle%20ID-com.selimbozkurt.wingbound__flight-7C4DFF)](#platform-support--store-readiness)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20Android%20%7C%20macOS-FF8C42)](#platform-support--store-readiness)

**WingBound: Multi Realms** is a high-performance, **60–120 FPS 4-in-1 arcade flight & naval action experience** built entirely with **Flutter**, a custom zero-allocation `CustomPainter` vector engine, **Impeller GLSL Fragment Shaders**, and **procedural 16-bit PCM WAV audio synthesis**.

> *"Four distinct dimensions. Four completely different laws of motion—from classic gravity flight and synthwave cyber-combat to 360° black hole orbital mechanics and the 1453 Golden Horn naval blockade."*

---

## 🌌 The 4 Realms & Flight Mechanics

Each realm transforms the physics engine, camera coordinate system, obstacle geometry, GLSL shader atmosphere, particle effects, and player controls:

| # | Realm | Pilot / Vessel Identity | Core Flight & Physics Mechanics | Hazards & Enemies | Power-Ups & Special Abilities | Hangar Skins (3) |
| :-: | :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | **Classic Sky** (`GameMode.classic`) | 🐦 Sky Aviator | Vertical gravity & impulse wing-flap physics with continuous multi-pipe flow (`250 → 215px` spacing) and progressive 4-tier speed/gap scaling (`142 → 172px/s`). | Precision 3D emerald & golden pillar corridors with narrowing vertical gaps (`196 → 162px`). | Progressive Level Milestones (`LVL 1` → `LVL 4`) & streak score multipliers. | *Altın Serçe*, *Zümrüt Anka*, *Kızıl Şahin* |
| **2** | **Cyber Neon** (`GameMode.cyberNeon`) | ⚡ Cyber Valkyrie | **Double-Jump** mid-air thrust, automatic plasma blaster fire, magnetic star-coin attraction (`110px` radius), and **Combo Fever** (`up to 4×` score). | Oscillating neon laser gates and incoming **Hunter Cyber Drones**. | **Hex Shield**, **Time-Dilation (Slow-Mo)**, **Heavy Pink Overdrive Blaster**, and **360° EMP Shockwave Blast**. | *Siber Valkür*, *Neon Hayalet*, *Altın Overdrive* |
| **3** | **Space Orbit** (`GameMode.spaceOrbit`) | 👨‍🚀 Event Horizon Explorer | **360° Polar Orbital Physics** around a supermassive **Black Hole**. Gravity continuously pulls your radius inward toward the Event Horizon (`r < 82px`) while taps fire outward ion thrusters (`r ≤ 242px`). | Radial titanium asteroid walls & crimson plasma pylons spaced continuously along the orbital ring (`~3 gates/orbit`). | **Plasma Shield**, **Gravitational Time Dilation**, **Star Crystals**, **Supernova Pulse**, and **7-Orbit Galactic Cycle (`+5` Bonus)**. | *Ufuk Kaşifi*, *Nebula Kruvazör*, *Solar Nova* |
| **4** | **1453 Conquest** (`GameMode.conquest1453`) | ⛵ Ottoman Kadırga (Galley) | **Top-Down Naval Blockade Runner** in the Golden Horn (*Haliç*). Steer port/starboard (*İskele / Sancak*) across sea lanes while automatically firing dual bow cannonballs (`SPACE / TAP` tacks & fires). | Byzantine stone sea walls, **Interlocking Iron Harbor Chains** (breakable by cannon fire), and **Greek Fire (*Rum Ateşi*) Ships**. | **Yağlı Kızak Hull Armor**, **Şahi Barutu (3× Heavy Cannon Volley)**, **Fetih Sancağı**, and **360° Şahi Topu Broadside Salvo**. | *Fatih Kadırgası*, *Altın Sancak*, *Karadeniz Kurdu* |

---

## 🎨 Key Highlights

- **100% Procedural Vector Graphics & GLSL Shaders (`shaders/realm_fx.frag`)**
  - Zero external PNG/JPEG sprite dependencies—every bird, cyber drone, black hole accretion disk, astronaut suit, and 6-oar Ottoman galley is rendered mathematically on the GPU canvas.
  - Real-time **Impeller GLSL Fragment Shader (`RealmShaderOverlayPainter`)** with premultiplied-alpha blending applies custom per-pixel post-processing for each realm:
    - *Classic Sky:* Warm golden sunbeams & soft atmospheric vignette.
    - *Cyber Neon:* Subtle CRT hologram scanlines & synthwave chromatic edge pulse.
    - *Space Orbit:* Gravitational lensing rings & cosmic event-horizon distortion.
    - *1453 Conquest:* Flickering torchlight shore glow over the Golden Horn waters.

- **12-Skin Character & Fleet Hangar (`lib/game/models/skin_model.dart`)**
  - Each realm includes **3 selectable skins/hulls** (`4 realms × 3 skins = 12 unique designs`) directly accessible via interactive hangar chips on the Mode Select cards.
  - Selected skins persist automatically via `SharedPreferences` and dynamically re-color character bodies, cyber plasma trails, astronaut telemetry cores, and Ottoman galley sails.

- **Realm-Specific Polyphonic 16-Bit 44.1kHz PCM WAV Audio Synthesizer (`GameAudioService`)**
  - Synthesizes **7 distinct procedural WAV buffers** directly in memory at startup—including realm-tailored action sounds (*Classic* airy wing whoosh, *Cyber* dual-oscillator laser pulse, *Space* deep ion thruster, *1453 Conquest* wooden oar water splash + cannon thud), 4-note major triad score arpeggios (`C5–E5–G5–C6`), sub-bass EMP/Şahi shockwaves, and collision impacts.
  - Preloads generated WAV buffers into a native 4-channel polyphonic `AVAudioPlayer` pool (`MainFlutterWindow.swift`) coupled with `HapticFeedback` tactile responses.

---

## 🏗️ Architecture & Performance Engineering

```text
lib/
├── main.dart                                      # Portrait lock, Edge-to-Edge UI, storage & audio pre-warming
└── game/
    ├── wingbound_game.dart                        # 60–120 FPS Ticker loop, 9:16 viewport & ValueNotifier canvas host
    ├── game_constants.dart                        # Logical resolution constants (430x764 / 560x995) & 4-tier difficulty curves
    ├── models/
    │   ├── game_mode.dart                         # GameMode enum (classic, cyberNeon, spaceOrbit, conquest1453)
    │   ├── skin_model.dart                        # RealmSkin & RealmSkinCatalog (12 customizable skins across 4 realms)
    │   ├── bird.dart                              # Classic & Cyber vertical physics model & hitbox calculation
    │   ├── pipe.dart                              # Dynamic moving/destructible obstacle model
    │   ├── power_up.dart                          # Cyber power-ups, LaserBolt projectiles & EnemyDrone models
    │   ├── space_models.dart                      # 360° Polar SpaceExplorer, OrbitGate & CosmicPowerUp models
    │   ├── conquest_models.dart                   # Top-Down OttomanGalley, SeaBarrier, Cannonball & EnemyFireShip models
    │   └── particle.dart                          # Pre-allocated object-pooled ParticleSystem (max 140 particles)
    ├── painters/
    │   ├── background_painter.dart                # Zero-repaint static Classic Sky multi-layered scenic CustomPainter
    │   ├── bird_painter.dart                      # Static-Path & cached-Paint Classic Aviator CustomPainter
    │   ├── pipe_painter.dart                      # 3D bevelled metallic/emerald pillar CustomPainter
    │   ├── ground_painter.dart                    # Zero-repaint static grass & soil CustomPainter
    │   ├── cyber_painters.dart                    # Static Synthwave skyline & grid, CyberBirdPainter, laser gates & ParticlePainter
    │   ├── space_painters.dart                    # Black Hole accretion disk, polar gates & astronaut CustomPainter
    │   ├── conquest_painters.dart                 # Golden Horn water, Byzantine chain locks & Ottoman Kadırga painter
    │   └── shader_fx_painter.dart                 # Impeller GLSL FragmentProgram loader & RealmShaderOverlayPainter
    ├── services/
    │   └── game_services.dart                     # Cached SharedPreferences storage & 7-sound PCM WAV audio synthesizer
    └── widgets/
        ├── mode_select_screen.dart                # Responsive mode selector with integrated 12-skin Fleet Hangar
        ├── ready_overlay.dart                     # Realm-specific pre-flight briefing & control guide overlay
        ├── scoreboard.dart                        # Zero-rebuild live score & realm badge HUD
        └── game_over_dialog.dart                  # Medal evaluation, high-score celebration & instant retry dialog
shaders/
└── realm_fx.frag                                  # Custom GLSL 460 core fragment shader for all 4 realms
```

### Key Technical Highlights
1. **Zero-Widget-Rebuild 60–120 FPS Render Loop:**
   - `_repaintTick` (`ValueNotifier<int>`) is passed only to active dynamic `CustomPainter(repaint: _repaintTick)` layers inside an isolated `RepaintBoundary`.
   - Static scenic layers (`BackgroundPainter`, `GroundPainter`, `CyberBackgroundPainter`, `CyberGroundPainter`) return `shouldRepaint => false` (`const`), eliminating background/ground redraw overhead while keeping visual focus 100% on the continuous obstacle stream.
   - Frame updates (`_onTick`) never call `setState()` during active gameplay unless a discrete HUD state changes (e.g., integer score increment, shield toggle, or game-over transition).
2. **Static Reusable `Paint` & `Path` Caching + Object-Pooled Particles:**
   - Painters cache `Paint` and `Path` instances at the class level (`static final Paint`), eliminating per-frame heap allocations and Garbage Collection (GC) frame drops on mobile devices.
   - `ParticleSystem` uses a fixed-capacity pool (`maxParticles = 140`) with swap-and-pop removal (`O(1)`) instead of allocating new lists every frame.
3. **Strict 9:16 Responsive Viewport (`SafeArea` + `AspectRatio` + `FittedBox`):**
   - The game canvas operates in a deterministic 9:16 logical coordinate space (`430×764` standard / `560×995` wide arena) wrapped in `SafeArea` → `AspectRatio(aspectRatio: 9 / 16)` → `FittedBox(fit: BoxFit.contain)`. Resizing desktop windows or playing on tablets/foldables never skews physics speeds or collision hitboxes.
4. **Lifecycle-Aware Resource Management:**
   - Implements `WidgetsBindingObserver` (`didChangeAppLifecycleState`) to automatically mute the `Ticker` and pause audio whenever the app transitions to `paused`, `inactive`, `hidden`, or `detached`, ensuring `0%` background CPU/GPU drain.

---

## 📱 Platform Support & Store Readiness

- **App Name:** `WingBound: Multi Realms`
- **Package / Bundle ID:** `com.selimbozkurt.wingbound_flight` (Android) / `com.selimbozkurt.wingboundflight` (iOS & macOS UTI)
- **Version:** `1.0.0+1`
- **Orientation:** Portrait (`DeviceOrientation.portraitUp`, `DeviceOrientation.portraitDown`)
- **Supported Targets:**
  - **Android:** API 21+ (`minSdk = maxOf(flutter.minSdkVersion, 21)`), Java/Kotlin JVM 17, automatic `key.properties` upload keystore signing (`android/key.properties.example`) with debug fallback, R8 code shrinking (`isMinifyEnabled = true`, `isShrinkResources = true`) & ProGuard rules (`android/app/proguard-rules.pro`).
  - **iOS:** iOS 12.0+, `CADisableMinimumFrameDurationOnPhone` enabled for 120Hz ProMotion displays, Portrait-locked orientation, `ITSAppUsesNonExemptEncryption = false` export compliance & `public.app-category.arcade-games` metadata.
  - **macOS:** Native Metal/Impeller desktop build (`WingBound.app`) with full keyboard (`SPACE`, `W`, `A/D`, `LEFT/RIGHT`, `E/X/SHIFT`, `ESC/M`) & mouse/trackpad controls, plus native 4-channel `AVAudioPlayer` sound engine.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.13.3` (or latest stable Flutter 3.x)
- Xcode (for iOS / macOS builds) or Android Studio (for Android builds)

### Installation & Run
```bash
# 1. Clean and fetch dependencies
flutter clean && flutter pub get

# 2. Run static analysis & unit/widget test suite (16/16 tests)
flutter analyze
flutter test

# 3. Launch on your target device
flutter run -d macos     # macOS Desktop
flutter run -d ios       # iOS Simulator / Device
flutter run -d android   # Android Emulator / Device
```

### Generating Store Icons & Native Splash (Optional)
Configuration templates for `flutter_launcher_icons` and `flutter_native_splash` are pre-configured in `pubspec.yaml`:
```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

### Production Store Builds
```bash
# Android App Bundle (Google Play)
flutter build appbundle --release

# iOS Archive (App Store Connect)
flutter build ipa --release

# macOS Release Bundle
flutter build macos --release
```

---

## 📄 License

Copyright © 2026 Selim Bozkurt (`com.selimbozkurt.wingbound_flight`). All rights reserved.
