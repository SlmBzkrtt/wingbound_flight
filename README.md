# WingBound: Multi Realms (v1.0.0)

**WingBound: Multi Realms** is a modern, high-performance arcade flight game built with Flutter (`CustomPainter` & 60/120 FPS `Ticker` engine). Designed with zero external image dependencies, every realm, character, particle effect, and obstacle is procedurally rendered on the GPU canvas.

---

## 🎮 4 Unique Realms & Flight Mechanics

1. **Classic Sky (`GameMode.classic`)**
   - Dynamic day, sunset, and starry night sky transitions.
   - Smooth physics-based wing flapping and progressive pipe gap scaling.

2. **Cyber Neon (`GameMode.cyberNeon`)**
   - Synthwave neon grid, moving laser barriers, and hunter drones.
   - Double-jump mechanics, plasma blaster power-ups, magnetic star crystals, time-dilation (Slow-Mo), and EMP shockwave blasts.

3. **Space Orbit (`GameMode.spaceOrbit`)**
   - 360° counter-clockwise orbital flight around a supermassive Black Hole & Event Horizon.
   - Radial asteroid/plasma gates, gravitational pull physics, and 7-orbit Galactic Cycle milestones.

4. **1453 Conquest (`GameMode.conquest1453`)**
   - Top-down naval blockade runner set in the Golden Horn (Haliç).
   - Steer the Ottoman Kadırga across 3 sea lanes, dodge Byzantine harbor chains and Greek fire ships, and fire broadside Şahi cannons.

---

## ⚡ Architecture & Performance Highlights

- **Zero-Allocation Render Loop:** All `CustomPainter` implementations (`BackgroundPainter`, `BirdPainter`, `PipePainter`, `GroundPainter`, `CyberPainters`, `SpaceOrbitWorldPainter`, `ConquestWorldPainter`, `ParticlePainter`) reuse static `Paint` objects and trigger via a dedicated `ValueNotifier<int>` (`repaint`) without rebuilding the Flutter widget tree.
- **Responsive 9:16 Viewport:** Wrapped in `SafeArea` + `AspectRatio(9 / 16)` + `FittedBox(BoxFit.contain)` to guarantee identical physics and hitboxes across phones, tablets, foldables, and desktop windows.
- **Offline-Ready Typography & Storage:** Pre-cached pixel typography (`PressStart2P`) with graceful offline fallback, plus persistent high scores and audio/haptic preferences via `SharedPreferences`.
- **Lifecycle Safe:** Automatically pauses the game loop (`Ticker`) when backgrounded or minimized (`AppLifecycleState`).

---

## 🚀 Getting Started

```bash
# Clean and fetch dependencies
flutter clean
flutter pub get

# Run static analysis and unit tests
flutter analyze
flutter test

# Launch on your target platform
flutter run
```

---

## 📦 Store Release Identity

- **Package / Bundle ID:** `com.selimbozkurt.wingbound_flight`
- **App Title:** `WingBound: Multi Realms`
- **Version:** `1.0.0+1`
