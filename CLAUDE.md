# BLASTRO — Project Context & Architecture Rules

## 1. Project Overview & Target Platforms
**BLASTRO** is a portrait-mode mobile 2D roguelite puzzle game fusing *Block Blast* (8x8 polyomino placement) with *Balatro* (Chips x Mult scoring, Jokers, Antes, Consumables).

- **Target Platforms:**
  - **Phase 1:** Android (API 24+, APK/AAB via Gradle)
  - **Phase 2:** iOS (iOS 15+, IPA via Xcode)
  - **Strict Restriction:** NEVER use web-only APIs (`dart:html`, `dart:js`).
- **Orientation & Layout:** Strictly locked to Portrait (`DeviceOrientation.portraitUp`). All UI overlays MUST respect `SafeArea` top/bottom insets (notches, punch-holes, gesture bars).
- **Mobile Touch UX (Mandatory):**
  - **Drag Finger Offset:** When dragging a piece from the bottom tray, render the piece `80dp` ABOVE the touch coordinate (`Vector2(0, -80)`) at `1.0x` board cell scale so the player's thumb never occludes the cells.
  - **Snap & Ghost Preview:** Show a semi-transparent ghost footprint on the 8x8 grid when hovering over a valid placement; highlight completable rows/columns pulsing before drop.
  - **Haptics:** Trigger `HapticFeedback.selectionClick()` on piece pickup, `lightImpact()` on placement, and escalating `mediumImpact()` / `heavyImpact()` during Phase 2–4 score triggers.
- **Offline Lifecycle Persistence:** Auto-save run state locally (`shared_preferences` / `hive` JSON snapshot) after every placement and shop action so Android backgrounding (`AppLifecycleState.paused`) never loses a run.

---

## 2. Core Domain & 4-Phase Scoring Rules

- **Grid & Tray:** 8x8 matrix (`0..7` rows/cols). 3-piece tray drawn from `BlockBag` (24 shapes). No rotation unless `joker_gyroscope` or a consumable is active. All 3 tray pieces must be placed before drawing the next tray unless a Discard charge is spent. Leftover pieces never carry across blinds (see *Blind Transition* below).
- **Intersection Rule:** When a row and column clear simultaneously (*Cross Clear*), the shared intersection cell `(r, c)` triggers **TWICE** during Phase 2.
- **Combo Window (3-Placement Rule):** Increments on any clearing placement. Survives up to 2 consecutive non-clearing setup moves; resets to `0` on the 3rd consecutive non-clearing placement.
- **Board Persistence:** The 8x8 board state persists across `Small -> Big -> Boss Blind` within an Ante, resetting only after defeating a Boss Blind. Every occupied cell (including enhancements, editions and seals) stays intact on a transition inside an Ante.
- **Blind Transition (Full Tray Refresh):** When a Blind is defeated and the player enters the next Blind, the board is kept per *Board Persistence*, but any leftover pieces in the tray are **discarded** and a brand-new full 3-piece tray is dealt from the `BlockBag`. This also applies after a Boss Blind (new Ante, empty board). The rule is `BlindTransition.enterNext` in `lib/core/roguelite/blind_transition.dart`.
- **Blind Flow & Blind Select:** `Blind defeated -> Cash Out -> Shop -> Blind Select -> Play Blind`. A new run also starts at Blind Select. The Blind Select screen shows all 3 Blinds of the Ante (Completed / Skipped / Current / Locked) with Target Score and Reward. Small and Big may be skipped (forfeits that Blind's reward and the shop; board and tray are untouched); the Boss Blind cannot be skipped.
- **Boss Blind Visibility:** The Boss for an Ante is a pure function of `(ante, seed)` (`BossRegistry.pick`), so its name and exact rule are shown on the Boss card at Blind Select during the Small and Big Blinds. During the Boss round the HUD shows a red warning banner (name + rule), and blocks/Jokers the Boss switches off (`BossBlind.debuffsCell` / `debuffsJoker`) get a red cross.
- **Dual Lose Conditions:** Run ends if:
  1. `traysRemaining == 0 && currentScore < blindTarget`, OR
  2. No remaining tray piece fits anywhere on the 8x8 grid AND `discardsRemaining == 0`.

### 4-Phase Deterministic Scoring
Formula: `FinalMoveScore = (TotalChips * TotalMult).floor() + allClearBonus`

1. **Phase 1 (Geometry & Streak):** Identify `ClearArchetype` (`Single`, `ParallelDouble`, `CrossClear`, `Triple`, `DoubleCross`, `Quad`, `Zone3x3`, `Penta`, `Hexa`, `CleanSweep`). Set base Chips & Mult from archetype level + add active `ComboStreak` to Mult.
2. **Phase 2 (Cleared Cells):** Scan cleared rows left-to-right (`c=0..7`), then cleared columns top-to-bottom (`r=0..7`). Apply `+10` base chips, Enhancements (`Bonus`, `Mult`, `Glass`, `Lucky`), Editions (`Foil`, `Holo`, `Polychrome`), Seals (`RedSeal` retriggers), and `onCellScored` Joker hooks.
3. **Phase 3 (Board Residue):** Scan remaining occupied cells on the 8x8 grid from `(0,0)` to `(7,7)`. Trigger `Steel` cells (`x1.5` Mult), `Mime` retriggers, and `onResidueScanned` Joker hooks.
4. **Phase 4 (Joker Bar):** Iterate active jokers strictly left-to-right (`0 -> N`). Apply `+Chips`, `+Mult`, and `XMult` in exact list order (`Blueprint` copies right, `Brainstorm` copies index 0).

---

## 3. Tech Stack & Strict Architecture Boundaries

- **Stack:**
  - Flutter (`3.24+`), Dart (`3.5+` strict null-safety)
  - Flame Engine (`flame` for 8x8 canvas, drag-drop, particles, floating score popups)
  - `flutter_riverpod` (state management)
  - `shared_preferences` (local run persistence)
- **Zero-Flutter Core Rule:** `lib/core/` MUST have **ZERO** imports from `package:flutter` or `package:flame`. All game rules, matrix math, seeded RNG, and the 4-phase scoring pipeline must be 100% pure Dart so `flutter test` runs headlessly in milliseconds.

### Directory Structure
```text
lib/
├── core/
│   ├── grid/          # grid_matrix.dart, line_detector.dart, fit_validator.dart
│   ├── polyomino/     # polyomino_catalog.dart (24 shapes), block_bag.dart
│   ├── scoring/       # scoring_pipeline.dart, clear_archetypes.dart, combo_window.dart
│   └── roguelite/     # joker_registry.dart, joker_effects.dart, ante_scaling.dart, boss_blinds.dart, consumables.dart, shop_generator.dart
├── state/             # run_notifier.dart, run_persistence.dart
├── game/              # Flame components: blastro_game.dart, board_component.dart, tray_piece_component.dart, score_popup_effect.dart
└── ui/                # Flutter Overlays: hud_top_bar.dart, joker_reorder_bar.dart, shop_sheet.dart, bag_modal.dart

test/
└── core/              # Pure Dart unit tests mirroring lib/core/
```

---

## 4. Code Conventions & Verification Commands

- **File Size Cap:** Keep every `.dart` file between **100 and 200 lines** (hard max **250 lines**). Split large catalogs or widgets immediately.
- **Explicit Naming:** NEVER create `utils.dart` or `helpers.dart`. Use specific domain names (e.g., `matrix_collision.dart`, `ante_target_table.dart`).
- **Execution Protocol:** For tasks touching **>3 files**, present a concise file-by-file plan first and wait for approval before writing code.

### Verification Gate (Run before finishing any task)
```bash
# 1. Static analysis — Must report 0 issues/warnings
flutter analyze

# 2. Unit tests — All pure Dart tests in test/core/ must pass
flutter test

# 3. Android build check — Run when modifying native/UI layers
flutter build apk --debug
```
