# Prism 🔦

A physics-based light-and-mirrors puzzle game built with Flutter — no game
engine, no image assets, just `CustomPainter`, additive blending, and a small
pure-Dart ray tracer.

Drag mirrors onto the grid and rotate them to bend beams of light into their
targets. Prisms split white light into red, green, and blue; filters strip
beams down to a single color; and beams that meet at a target mix additively
(red + blue = magenta).

## How to play

- **Drag** a glowing tile to move it to an empty cell.
- **Tap** a mirror to flip its orientation (`/` ↔ `\`).
- Light every target with **exactly** its required color — extra colors spoil
  the mix.

Twelve levels ramp up the mechanics: mirrors → filters → prism splitting →
color mixing → crossing beams, wall detours, recombination, and prisms used
as color-dependent benders. Progress is saved locally; each level unlocks
the next. Sound effects are procedurally generated sine-wave chimes
(see `assets/audio/`), with a mute toggle that persists.

## The optics, briefly

- Light colors are bitmasks over the RGB primaries, so **mixing is `OR`** and
  **filtering is `AND`**.
- A prism sends red straight through, bends green left, and blue right
  (relative to the beam's direction of travel).
- The ray tracer (`lib/game/tracer.dart`) walks beams cell by cell from each
  source, emitting renderable segments and accumulating color at targets.

## Running it

```sh
flutter run -d chrome   # web
flutter run             # any connected device/emulator
flutter test            # engine tests + a solvability proof for every level
```

Android and web targets are checked in; add more with
`flutter create --platforms ios,macos,linux,windows .`

## Project layout

```
lib/
  game/        pure Dart, no Flutter dependency beyond dart:ui Offset/Color
    dir.dart     beam directions and mirror reflection math
    light.dart   RGB bitmask color model
    piece.dart   sources, mirrors, prisms, filters, targets, walls
    level.dart   board model + the six handcrafted levels
    tracer.dart  the ray-tracing engine
  services/
    progress.dart       completion/unlock state + settings (shared_preferences)
    sfx.dart            fire-and-forget sound effects (audioplayers)
  ui/
    board_painter.dart  CustomPainter: glowing beams, pieces, drag feedback,
                        win particle bursts
    game_screen.dart    gestures, sounds, win celebration, navigation
    level_select_screen.dart  level grid with lock/complete states
```

Every level definition is covered by a test that applies its intended
solution and asserts the tracer reports a win — so the levels can't silently
become unsolvable as the engine evolves.
