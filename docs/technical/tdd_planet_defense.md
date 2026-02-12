# Technical Design Document: Planet Defense

**Version**: 1.0
**Date**: 2026-02-12
**Status**: Draft - Pending Approval
**Depends on**: GDD Planet Defense v1.0 (`/docs/design/gdd_planet_defense.md`)

---

## 1. Scene Tree Structure

This section defines every scene file (`.tscn`) and the full node hierarchy within each. Nodes marked with **(scene)** are saved as their own `.tscn` file and instanced into the parent. All other nodes are inline children.

### 1.1 Main Scene (`res://scenes/main.tscn`)

This is the entry point set in `project.godot`. It owns the camera, background, and orchestrates scene-level transitions by swapping child scenes.

```
Main (Node2D) [script: main.gd]
  +-- Background (Node2D) [script: background.gd]           # Star field rendering
  +-- Camera2D (Camera2D) [script: camera_shake.gd]          # Centered; used for screen shake
  +-- GameWorld (Node2D)                                       # Parent for all gameplay nodes
  |     +-- Planet (scene) [res://scenes/game/planet.tscn]
  |     +-- Missiles (Node2D)                                  # Container for all missile instances
  |     |     +-- Interceptors (Node2D)                        # Container for player interceptors
  |     |     +-- Enemies (Node2D)                             # Container for enemy missiles
  |     +-- Blasts (Node2D)                                    # Container for blast instances
  |     +-- Effects (Node2D)                                   # Score popups, impact effects
  +-- Crosshair (Sprite2D) [script: crosshair.gd]             # Custom cursor replacement
  +-- UILayer (CanvasLayer)                                    # UI overlay, unaffected by camera shake
  |     +-- HUD (scene) [res://scenes/ui/hud.tscn]
  |     +-- WaveAnnounce (scene) [res://scenes/ui/wave_announce.tscn]
  |     +-- UpgradeShop (scene) [res://scenes/ui/upgrade_shop.tscn]
  |     +-- GameOverScreen (scene) [res://scenes/ui/game_over.tscn]
```

**Rationale**: A single main scene avoids full scene transitions (which lose state). Game state changes (PLAYING, UPGRADE_SHOP, GAME_OVER) are handled by showing/hiding UI children and pausing/unpausing GameWorld. The CanvasLayer ensures UI is not affected by Camera2D shake offsets.

### 1.2 Planet Scene (`res://scenes/game/planet.tscn`)

The planet and its silos. The planet itself is a visual Node2D; silos are child Node2Ds positioned on the circumference.

```
Planet (Node2D) [script: planet.gd]
  +-- PlanetBody (Node2D) [script: planet_body.gd]            # Draws the planet disk + atmosphere via _draw()
  +-- Silos (Node2D) [script: silo_manager.gd]                # Manages silo array, handles rotation
  |     +-- Silo0 (scene) [res://scenes/game/silo.tscn]       # Instanced at _ready, 6 times
  |     +-- Silo1 (scene)
  |     +-- Silo2 (scene)
  |     +-- Silo3 (scene)
  |     +-- Silo4 (scene)
  |     +-- Silo5 (scene)
  +-- PlanetCollisionArea (Area2D)                             # Used to reject clicks inside planet
        +-- CollisionShape2D (CircleShape2D)                   # Radius = planet_radius
```

**Note**: Silos are instanced from a silo scene in `_ready()` and positioned programmatically. The scene file contains the 6 silos pre-placed for editor visibility, but their positions are recalculated every frame by `silo_manager.gd` based on the current rotation angle. Alternatively, silos can be spawned purely in code -- the scene instances are preferred for editor preview.

### 1.3 Silo Scene (`res://scenes/game/silo.tscn`)

A single silo on the planet circumference.

```
Silo (Node2D) [script: silo.gd]
  +-- SiloSprite (Node2D) [script: silo_sprite.gd]            # Draws triangle marker via _draw()
  +-- ReloadTimer (Timer)                                      # One-shot timer for reload cooldown
  +-- ReloadIndicator (Node2D) [script: reload_indicator.gd]  # Draws radial cooldown arc via _draw()
```

### 1.4 Interceptor Missile Scene (`res://scenes/game/interceptor.tscn`)

Player's interceptor missile. Created at runtime when a silo fires.

```
Interceptor (Node2D) [script: interceptor.gd]
  +-- Trail (Line2D)                                           # Cyan trail, gradient fade
  +-- Head (Node2D) [script: missile_head.gd]                 # Draws bright point via _draw()
```

### 1.5 Enemy Missile Scene (`res://scenes/game/enemy_missile.tscn`)

Standard enemy missile. Also serves as MIRV warhead post-split (with `is_warhead = true`).

```
EnemyMissile (Node2D) [script: enemy_missile.gd]
  +-- Trail (Line2D)                                           # Red trail, gradient fade
  +-- Head (Node2D) [script: missile_head.gd]                 # Draws small dot via _draw()
```

### 1.6 MIRV Missile Scene (`res://scenes/game/mirv_missile.tscn`)

MIRV carrier. Extends enemy missile behavior with split logic.

```
MIRVMissile (Node2D) [script: mirv_missile.gd]
  +-- Trail (Line2D)                                           # Yellow-orange trail, pulsing
  +-- Head (Node2D) [script: missile_head.gd]                 # Larger dot, pulsing glow
  +-- PulseTimer (Timer)                                       # Drives the visual pulse effect
```

**Design decision**: MIRV is a separate scene rather than a flag on EnemyMissile because the pre-split visual behavior (pulsing glow, larger head, different trail color) and split logic are distinct enough to warrant separation. Post-split warheads reuse the EnemyMissile scene with `is_warhead = true`.

### 1.7 Blast Scene (`res://scenes/game/blast.tscn`)

The expanding detonation from an interceptor.

```
Blast (Node2D) [script: blast.gd]
  +-- BlastVisual (Node2D) [script: blast_visual.gd]          # Draws expanding/fading circle via _draw()
  +-- Particles (GPUParticles2D)                               # Radial particle burst on creation
```

**No Area2D**: Blast collision is handled via manual distance checks in `blast.gd._process()` against all active enemies in the Enemies container. This avoids frame-timing issues with Area2D overlap detection at high speeds (GDD Section 9.4 recommendation).

### 1.8 HUD Scene (`res://scenes/ui/hud.tscn`)

In-game heads-up display. Always visible during PLAYING state.

```
HUD (Control) [script: hud.gd]
  +-- ScoreLabel (Label)                                       # Top-left: current score
  +-- HighScoreLabel (Label)                                   # Top-right: high score
  +-- WaveLabel (Label)                                        # Top-center: current wave number
  +-- WarningVignette (ColorRect) [script: vignette.gd]       # Full-screen red vignette, hidden by default
```

### 1.9 Wave Announce Scene (`res://scenes/ui/wave_announce.tscn`)

Brief overlay shown at wave start. "WAVE 3" with fade-in/fade-out.

```
WaveAnnounce (Control) [script: wave_announce.gd]
  +-- CenterContainer (CenterContainer)
        +-- WaveText (Label)                                   # "WAVE X" with large font
```

### 1.10 Upgrade Shop Scene (`res://scenes/ui/upgrade_shop.tscn`)

Between-wave upgrade screen. Four upgrade rectangles + continue button.

```
UpgradeShop (Control) [script: upgrade_shop.gd]
  +-- Overlay (ColorRect)                                      # Semi-transparent dark background
  +-- Title (Label)                                            # "UPGRADE SHOP"
  +-- ScoreDisplay (Label)                                     # Current score (budget)
  +-- UpgradeContainer (HBoxContainer)                         # Horizontal row of upgrade cards
  |     +-- SpeedCard (scene) [res://scenes/ui/upgrade_card.tscn]   # Interceptor Speed
  |     +-- BlastCard (scene) [res://scenes/ui/upgrade_card.tscn]   # Blast Radius
  |     +-- ReloadCard (scene) [res://scenes/ui/upgrade_card.tscn]  # Reload Speed
  |     +-- RepairCard (scene) [res://scenes/ui/upgrade_card.tscn]  # Silo Repair
  +-- ContinueButton (Button)                                  # "CONTINUE" to next wave
```

### 1.11 Upgrade Card Scene (`res://scenes/ui/upgrade_card.tscn`)

A single upgrade card in the shop. Reused 4 times with different data.

```
UpgradeCard (PanelContainer) [script: upgrade_card.gd]
  +-- VBoxContainer (VBoxContainer)
        +-- Icon (TextureRect)                                 # Upgrade icon
        +-- NameLabel (Label)                                  # "Interceptor Speed"
        +-- LevelLabel (Label)                                 # "Level 3/5" or "REPAIR"
        +-- CostLabel (Label)                                  # "Cost: 4000" or "MAX"
```

### 1.12 Game Over Scene (`res://scenes/ui/game_over.tscn`)

Final screen shown after all silos are destroyed.

```
GameOverScreen (Control) [script: game_over.gd]
  +-- Overlay (ColorRect)                                      # Dark overlay
  +-- CenterContainer (CenterContainer)
        +-- VBoxContainer (VBoxContainer)
              +-- GameOverLabel (Label)                         # "GAME OVER"
              +-- FinalScoreLabel (Label)                       # Final score
              +-- StatsContainer (VBoxContainer)
              |     +-- WavesLabel (Label)                      # "Waves Survived: 12"
              |     +-- DestroyedLabel (Label)                  # "Missiles Destroyed: 87"
              |     +-- AccuracyLabel (Label)                   # "Accuracy: 74%"
              +-- RestartButton (Button)                        # "PLAY AGAIN"
```

---

## 2. Node Responsibilities

### 2.1 Main Scene Scripts

| Node Name | Node Type | Script | Responsibility | Lifecycle Methods |
|-----------|-----------|--------|----------------|-------------------|
| Main | Node2D | `main.gd` | Top-level orchestrator. Receives input for targeting. Spawns interceptors, enemies, blasts. Connects to GameManager signals for state changes. | `_ready`, `_unhandled_input`, `_process` |
| Background | Node2D | `background.gd` | Renders static star field via `_draw()`. Generates random star positions once in `_ready()`. | `_ready`, `_draw` |
| Camera2D | Camera2D | `camera_shake.gd` | Provides `shake(intensity, duration)` method. Applies decaying random offset in `_process()`. | `_ready`, `_process` |
| Crosshair | Sprite2D | `crosshair.gd` | Follows mouse position. Flashes red on rejected clicks. Hides default cursor. | `_ready`, `_process` |

### 2.2 Planet Scripts

| Node Name | Node Type | Script | Responsibility | Lifecycle Methods |
|-----------|-----------|--------|----------------|-------------------|
| Planet | Node2D | `planet.gd` | Holds planet_radius, rotation state. Provides `get_silo_positions()`, `get_nearest_available_silo()`, `is_point_inside_planet()`. Delegates to children. | `_ready`, `_process` |
| PlanetBody | Node2D | `planet_body.gd` | Draws planet disk (filled circle), surface detail, atmosphere ring via `_draw()`. Rotates visual based on parent rotation angle. | `_ready`, `_draw` |
| Silos | Node2D | `silo_manager.gd` | Manages the array of silo nodes. Updates their circumference positions each frame based on rotation angle. Provides `get_available_silos()`, `get_nearest_available_silo(target_pos)`. Emits `silo_destroyed`. | `_ready`, `_process` |
| Silo (each) | Node2D | `silo.gd` | Single silo state: READY, RELOADING, DESTROYED. Exposes `fire()` method (starts reload timer). Exposes `destroy()`. Emits `fired`, `reloaded`, `destroyed`. | `_ready` |
| SiloSprite | Node2D | `silo_sprite.gd` | Draws silo triangle/diamond marker pointing radially outward. Color changes based on parent silo state. | `_draw` |
| ReloadIndicator | Node2D | `reload_indicator.gd` | Draws radial arc showing reload progress. Queries parent silo for reload progress fraction. | `_process`, `_draw` |

### 2.3 Missile Scripts

| Node Name | Node Type | Script | Responsibility | Lifecycle Methods |
|-----------|-----------|--------|----------------|-------------------|
| Interceptor | Node2D | `interceptor.gd` | Moves from launch_pos toward target_pos at interceptor_speed. When it arrives, emits `detonated(position)` and `queue_free()`. Adds trail points each frame. | `_ready`, `_process` |
| EnemyMissile | Node2D | `enemy_missile.gd` | Moves from spawn_pos toward target_pos at assigned speed. On arrival, emits `impacted(position)` and begins trail fade. Has `destroy()` for blast kills -- emits `destroyed(position, is_warhead)`. | `_ready`, `_process` |
| MIRVMissile | Node2D | `mirv_missile.gd` | Extends enemy movement with split logic. Tracks distance to planet center. When within split range, emits `split(position, warhead_targets)`, spawns EnemyMissile warheads, and `queue_free()`. | `_ready`, `_process` |
| Head (shared) | Node2D | `missile_head.gd` | Draws a small bright circle for the missile head via `_draw()`. Configurable color and radius. | `_draw` |

### 2.4 Blast Scripts

| Node Name | Node Type | Script | Responsibility | Lifecycle Methods |
|-----------|-----------|--------|----------------|-------------------|
| Blast | Node2D | `blast.gd` | Manages blast lifecycle (EXPANDING, HOLDING, FADING). Tracks current_radius. Performs per-frame distance check against all enemies. Emits `enemy_caught(enemy_node)`. Calls `queue_free()` after fade. | `_ready`, `_process` |
| BlastVisual | Node2D | `blast_visual.gd` | Draws the expanding/holding/fading circle via `_draw()`. Queries parent for current_radius and phase. | `_process`, `_draw` |

### 2.5 UI Scripts

| Node Name | Node Type | Script | Responsibility | Lifecycle Methods |
|-----------|-----------|--------|----------------|-------------------|
| HUD | Control | `hud.gd` | Listens to GameManager signals: `score_changed`, `wave_changed`, `silo_count_changed`. Updates labels. Manages warning vignette visibility. | `_ready` |
| Vignette | ColorRect | `vignette.gd` | Pulse animation for red warning vignette when silos <= 2. | `_process` |
| WaveAnnounce | Control | `wave_announce.gd` | Shows "WAVE X" text with tween fade-in/out. Provides `announce(wave_number)` method. | `_ready` |
| UpgradeShop | Control | `upgrade_shop.gd` | Populates upgrade cards with current data from GameManager. Handles purchase clicks. Emits `shop_closed`. | `_ready` |
| UpgradeCard | PanelContainer | `upgrade_card.gd` | Displays single upgrade info. Handles click. Emits `purchased(upgrade_id)`. Dims when unaffordable or maxed. | `_ready`, `_gui_input` |
| GameOverScreen | Control | `game_over.gd` | Shows final stats from GameManager. Restart button triggers `GameManager.restart_game()`. | `_ready` |

### 2.6 Autoload Scripts

| Script | Responsibility | Lifecycle Methods |
|--------|----------------|-------------------|
| `game_manager.gd` | Game state machine (MENU, PLAYING, WAVE_TRANSITION, UPGRADE_SHOP, GAME_OVER). Wave spawning logic (timers, burst scheduling). Score tracking. Upgrade state. Wave configuration (uses WaveData). | `_ready`, `_process` |
| `audio_manager.gd` | SFX pool management (pre-created AudioStreamPlayer nodes). Music playback with crossfade. Volume control per bus. | `_ready` |

---

## 3. Signal Flow

### 3.1 Custom Signal Map

| Signal Name | Defined On | Emitted By | Connected To | Payload | GDD Reference |
|-------------|-----------|------------|--------------|---------|---------------|
| `interceptor_requested` | `main.gd` | `main.gd` (on valid click) | `main.gd` (self, to spawn interceptor) | `(silo: Node2D, target: Vector2)` | GDD 4.2 |
| `interceptor_launched` | `silo.gd` | `silo.gd` | `hud.gd` (for visual feedback), `audio_manager.gd` | `(silo_position: Vector2)` | GDD 6.1 |
| `silo_reloaded` | `silo.gd` | `silo.gd` | `audio_manager.gd` | `(silo_position: Vector2)` | GDD 6.2 |
| `detonated` | `interceptor.gd` | `interceptor.gd` | `main.gd` (to spawn blast) | `(position: Vector2)` | GDD 4.3 |
| `enemy_destroyed` | `enemy_missile.gd` | `enemy_missile.gd` | `game_manager.gd` (score), `main.gd` (effects) | `(position: Vector2, is_warhead: bool, is_mirv_presplit: bool)` | GDD 5.2 |
| `enemy_impacted` | `enemy_missile.gd` | `enemy_missile.gd` | `main.gd` (silo hit check), `audio_manager.gd` | `(impact_position: Vector2)` | GDD 4.6 |
| `mirv_split` | `mirv_missile.gd` | `mirv_missile.gd` | `main.gd` (to spawn warheads), `audio_manager.gd` | `(position: Vector2, warhead_targets: Array[Vector2])` | GDD 4.5 |
| `silo_destroyed` | `silo_manager.gd` | `silo_manager.gd` | `game_manager.gd`, `hud.gd`, `audio_manager.gd`, `camera_shake.gd` | `(silo_index: int, position: Vector2)` | GDD 4.6 |
| `all_silos_destroyed` | `silo_manager.gd` | `silo_manager.gd` | `game_manager.gd` | `()` | GDD 4.6 |
| `score_changed` | `game_manager.gd` | `GameManager` | `hud.gd`, `upgrade_shop.gd` | `(new_score: int)` | GDD 5.2 |
| `wave_started` | `game_manager.gd` | `GameManager` | `main.gd`, `hud.gd`, `wave_announce.gd` | `(wave_number: int)` | GDD 3 |
| `wave_completed` | `game_manager.gd` | `GameManager` | `main.gd`, `hud.gd`, `upgrade_shop.gd` | `(wave_number: int)` | GDD 3 |
| `game_state_changed` | `game_manager.gd` | `GameManager` | `main.gd`, `hud.gd`, `upgrade_shop.gd`, `game_over.gd` | `(new_state: GameManager.GameState)` | GDD 9.2 |
| `game_over` | `game_manager.gd` | `GameManager` | `main.gd`, `game_over.gd`, `audio_manager.gd` | `()` | GDD 4.6 |
| `upgrade_purchased` | `upgrade_shop.gd` | `upgrade_shop.gd` | `game_manager.gd`, `audio_manager.gd` | `(upgrade_id: String, new_level: int)` | GDD 5.3 |
| `shop_closed` | `upgrade_shop.gd` | `upgrade_shop.gd` | `game_manager.gd` (triggers next wave) | `()` | GDD 5.3 |
| `click_rejected` | `main.gd` | `main.gd` | `crosshair.gd`, `audio_manager.gd` | `(reason: String)` | GDD 8.2, 8.7 |
| `blast_enemy_caught` | `blast.gd` | `blast.gd` | `main.gd` (for multi-kill tracking) | `(enemy: Node2D, blast_position: Vector2)` | GDD 4.3 |
| `multi_kill` | `main.gd` | `main.gd` | `hud.gd` (popup), `camera_shake.gd`, `audio_manager.gd` | `(count: int, position: Vector2)` | GDD 6.1 |
| `wave_enemies_spawned` | `game_manager.gd` | `GameManager` | `main.gd` (to know when to check wave end) | `()` | GDD 3 |
| `silo_count_changed` | `silo_manager.gd` | `silo_manager.gd` | `hud.gd` (warning vignette) | `(active_count: int)` | GDD 4.6 |

### 3.2 Signal Flow Diagrams

#### Player Click -> Interceptor Launch Flow
```
1. main.gd._unhandled_input(event)
   |-- Is InputEventMouseButton, pressed, left button?
   |-- Get click position (event.position adjusted for camera)
   |-- Is point inside planet? (planet.is_point_inside_planet(pos))
   |   YES -> emit click_rejected("inside_planet") -> crosshair flashes red, error buzz
   |   NO  -> continue
   |-- silo_manager.get_nearest_available_silo(click_pos) -> silo or null
   |   null -> emit click_rejected("no_silo") -> crosshair flashes red, error buzz
   |   silo -> silo.fire() -> silo emits interceptor_launched
   |           main.gd spawns Interceptor scene at silo.global_position, target = click_pos
   |           GameManager.record_shot_fired()
```

#### Interceptor Detonation -> Enemy Destruction Flow
```
1. interceptor.gd._process(delta)
   |-- Move toward target
   |-- Reached target? (distance < threshold)
   |   YES -> emit detonated(global_position) -> queue_free()

2. main.gd receives detonated signal
   |-- Spawns Blast scene at position
   |-- camera_shake.shake(DETONATION_INTENSITY)
   |-- AudioManager.play_sfx("detonation")

3. blast.gd._process(delta)
   |-- Update phase (EXPANDING -> HOLDING -> FADING)
   |-- If phase is EXPANDING or HOLDING:
   |   |-- For each enemy in Enemies container:
   |   |   |-- distance = blast_position.distance_to(enemy.global_position)
   |   |   |-- If distance < current_radius AND enemy not already caught by this blast:
   |   |       |-- Mark enemy as caught
   |   |       |-- enemy.destroy()
   |   |       |-- emit blast_enemy_caught(enemy, global_position)
   |   |       |-- Increment kill_count for this blast
   |-- If phase transition to FADING and kill_count >= 3:
   |   |-- main.gd receives and emits multi_kill(kill_count, position)
   |-- If fade complete: queue_free()

4. enemy_missile.gd.destroy()
   |-- emit enemy_destroyed(global_position, is_warhead, false)
   |-- Begin trail fade (do NOT queue_free yet -- trail needs to fade)
   |-- After trail_lifetime: queue_free()
```

#### Enemy Impact -> Silo Destruction Flow
```
1. enemy_missile.gd._process(delta)
   |-- Move toward target
   |-- Reached planet circumference? (distance_to(planet_center) <= planet_radius)
   |   YES -> emit enemy_impacted(global_position)

2. main.gd receives enemy_impacted signal
   |-- silo_manager.check_silo_hit(impact_position)
   |   |-- For each active silo:
   |       |-- angular_distance = arc length between impact point and silo position
   |       |-- If angular_distance < silo_hit_tolerance:
   |           |-- silo.destroy()
   |           |-- emit silo_destroyed(silo_index, silo.global_position)
   |           |-- camera_shake.shake(SILO_DESTROYED_INTENSITY)
   |           |-- AudioManager.play_sfx("silo_destroyed")
   |           |-- Spawn destruction effect
   |           |-- Check remaining silos -> if 0: emit all_silos_destroyed

3. game_manager.gd receives silo_destroyed / all_silos_destroyed
   |-- If all_silos_destroyed: transition to GAME_OVER state
   |-- emit game_state_changed(GAME_OVER) -> game_over.gd shows screen
```

#### Wave Lifecycle Flow
```
1. GameManager transitions to PLAYING state
   |-- emit wave_started(wave_number)
   |-- wave_announce.gd shows "WAVE X" for wave_start_delay seconds
   |-- Start burst timer (burst_interval)

2. On each burst timer timeout:
   |-- Calculate missiles for this burst
   |-- Start spawn timer (spawn_interval)
   |-- On each spawn timer timeout:
   |   |-- Determine if MIRV or regular (based on mirv_chance)
   |   |-- Calculate spawn position (screen edge) and target (circumference)
   |   |-- Validate no planet occlusion (GDD 8.4)
   |   |-- emit enemy_spawn_requested -> main.gd spawns the missile
   |-- After all bursts complete: emit wave_enemies_spawned

3. main.gd monitors Enemies container
   |-- _process: if wave_enemies_spawned AND Enemies.get_child_count() == 0:
   |   |-- All enemies resolved (destroyed or impacted)
   |   |-- Notify GameManager -> transition to WAVE_TRANSITION

4. GameManager in WAVE_TRANSITION:
   |-- Calculate wave bonuses (wave clear, silo survival, accuracy)
   |-- emit wave_completed(wave_number)
   |-- Transition to UPGRADE_SHOP state
   |-- emit game_state_changed(UPGRADE_SHOP) -> upgrade_shop.gd shows

5. upgrade_shop.gd emits shop_closed
   |-- GameManager increments wave_number
   |-- Transition to PLAYING -> loop back to step 1
```

---

## 4. Resource Design

### 4.1 WaveData Resource (`res://scripts/resources/wave_data.gd`)

Defines the configuration for a single wave. Generated by `GameManager` using the wave formulas from GDD Section 5.1, or loaded from a pre-authored array for the first 10 waves.

```gdscript
class_name WaveData
extends Resource

@export var wave_number: int = 1
@export var enemy_count: int = 6
@export var speed_min: float = 80.0
@export var speed_max: float = 120.0
@export var mirv_chance: float = 0.0
@export var mirv_min_warheads: int = 2
@export var mirv_max_warheads: int = 2
@export var burst_count: int = 2
@export var silo_target_ratio: float = 0.6
```

**Usage**: `GameManager` creates or retrieves a `WaveData` for the current wave and passes it to the spawn logic. The first 10 waves can be hand-authored as `.tres` files for precise control; waves 11+ are generated from the GDD formulas.

### 4.2 UpgradeData Resource (`res://scripts/resources/upgrade_data.gd`)

Defines a single upgrade path.

```gdscript
class_name UpgradeData
extends Resource

@export var id: String = ""                          # "interceptor_speed", "blast_radius", "reload_speed", "silo_repair"
@export var display_name: String = ""                # "Interceptor Speed"
@export var max_level: int = 5                       # 0 for non-levelable (silo_repair)
@export var costs: Array[int] = []                   # [1000, 2000, 4000, 8000, 16000]
@export var effect_per_level: float = 0.0            # +60 px/s, +6 px, -0.18s (varies by upgrade)
@export var base_value: float = 0.0                  # Starting value before upgrades
@export var icon: Texture2D = null                   # Icon for shop display
@export var description: String = ""                 # "Increases interceptor travel speed"
```

**Pre-authored**: Four `.tres` files are created in `res://assets/data/`:
- `upgrade_interceptor_speed.tres`: costs=[1000,2000,4000,8000,16000], effect_per_level=60.0, base_value=400.0
- `upgrade_blast_radius.tres`: costs=[1500,3000,6000,12000,24000], effect_per_level=6.0, base_value=40.0
- `upgrade_reload_speed.tres`: costs=[1200,2400,4800,9600,19200], effect_per_level=-0.18, base_value=1.5
- `upgrade_silo_repair.tres`: max_level=0 (special handling), cost computed dynamically as `5000 * wave_number`

### 4.3 GameConfig Resource (`res://scripts/resources/game_config.gd`)

Centralizes all balance parameters from GDD Section 7 as `@export` variables. A single `.tres` instance is loaded by GameManager.

```gdscript
class_name GameConfig
extends Resource

# --- 7.1 Planet & World ---
@export var planet_radius: float = 80.0
@export var initial_silo_count: int = 6
@export var rotation_speed: float = 0.15              # radians/sec
@export var silo_hit_tolerance: float = 15.0           # pixels
@export var silo_target_ratio: float = 0.6

# --- 7.2 Interceptor Missiles ---
@export var interceptor_speed: float = 400.0
@export var blast_radius: float = 40.0
@export var blast_expand_time: float = 0.3
@export var blast_hold_time: float = 0.2
@export var blast_fade_time: float = 0.2
@export var silo_reload_time: float = 1.5

# --- 7.3 Enemy Missiles ---
@export var enemy_speed_min_base: float = 80.0
@export var enemy_speed_max_base: float = 120.0
@export var enemy_speed_escalation: float = 8.0
@export var enemy_speed_max_escalation: float = 12.0
@export var enemy_speed_cap: float = 300.0
@export var initial_enemy_count: int = 6
@export var enemy_count_escalation: int = 2
@export var enemy_count_cap: int = 60
@export var spawn_margin: float = 20.0
@export var trail_lifetime: float = 5.0

# --- 7.4 MIRV ---
@export var mirv_start_wave: int = 5
@export var mirv_base_chance: float = 0.15
@export var mirv_chance_per_wave: float = 0.03
@export var mirv_chance_cap: float = 0.55
@export var mirv_split_dist_min: float = 150.0
@export var mirv_split_dist_max: float = 250.0
@export var mirv_min_warheads: int = 2
@export var mirv_max_warheads: int = 4
@export var mirv_warhead_spread: float = 0.52          # ~30 degrees

# --- 7.5 Scoring & Upgrades ---
@export var points_enemy_kill: int = 100
@export var points_mirv_presplit: int = 250
@export var points_warhead_kill: int = 75
@export var wave_clear_bonus: int = 500
@export var silo_survival_bonus: int = 200
@export var accuracy_bonus_threshold: float = 0.8
@export var accuracy_bonus: int = 300
@export var silo_repair_cost_mult: int = 5000

# --- 7.6 Wave Timing ---
@export var wave_start_delay: float = 1.5
@export var burst_interval: float = 2.0
@export var spawn_interval: float = 0.3
```

**Usage**: A single `default_config.tres` instance is saved in `res://assets/data/`. GameManager loads it at `_ready()`. All balance tuning happens by editing this `.tres` in the Godot inspector -- no code changes required.

---

## 5. Autoload Strategy

### 5.1 GameManager (`res://scripts/autoload/game_manager.gd`)

**Registered as**: Autoload singleton named `GameManager`

**State held**:
- `current_state: GameState` -- the game state machine enum
- `current_wave: int` -- current wave number
- `score: int` -- current score
- `high_score: int` -- persistent high score (saved to user://)
- `shots_fired: int` -- total interceptors launched this wave (for accuracy)
- `shots_hit: int` -- total enemies destroyed this wave (for accuracy)
- `upgrade_levels: Dictionary` -- `{"interceptor_speed": 0, "blast_radius": 0, "reload_speed": 0}` (0-5)
- `config: GameConfig` -- loaded balance parameters
- `current_wave_data: WaveData` -- generated wave data for current wave
- `wave_enemies_spawned: bool` -- whether all enemies for this wave have been spawned
- `destroyed_silo_count: int` -- track silos destroyed (for repair cost and game over check)

**Signals defined**:
- `game_state_changed(new_state: GameState)`
- `wave_started(wave_number: int)`
- `wave_completed(wave_number: int)`
- `wave_enemies_spawned()`
- `score_changed(new_score: int)`
- `game_over()`

**Methods**:
- `start_game()` -- reset state, transition to PLAYING
- `restart_game()` -- full reset, transition to PLAYING
- `add_score(points: int)` -- add points, emit score_changed
- `record_shot_fired()` -- increment shots_fired
- `record_shot_hit()` -- increment shots_hit
- `get_effective_interceptor_speed() -> float` -- base + upgrade bonus
- `get_effective_blast_radius() -> float` -- base + upgrade bonus
- `get_effective_reload_time() -> float` -- base + upgrade bonus (reduction)
- `purchase_upgrade(upgrade_id: String) -> bool` -- deduct score, update level
- `generate_wave_data(wave_num: int) -> WaveData` -- apply GDD formulas
- `transition_to(new_state: GameState)` -- state machine transition
- `get_wave_accuracy() -> float` -- shots_hit / shots_fired (clamped)
- `calculate_wave_bonuses() -> int` -- end-of-wave bonus calculation

**Does NOT own**: Spawn scheduling timers live in `main.gd` because they need access to the scene tree to instance nodes. GameManager provides the data (WaveData); main.gd executes the spawning.

### 5.2 AudioManager (`res://scripts/autoload/audio_manager.gd`)

**Registered as**: Autoload singleton named `AudioManager`

**State held**:
- `sfx_pool: Dictionary` -- `{"launch": [AudioStreamPlayer, ...], "detonation": [...], ...}`
- `music_player: AudioStreamPlayer` -- single music player
- `sfx_bus: StringName` -- "SFX" bus name
- `music_bus: StringName` -- "Music" bus name

**Methods**:
- `play_sfx(sfx_name: String, position: Vector2 = Vector2.ZERO)` -- plays from pool
- `play_music(stream: AudioStream, fade_in: float = 1.0)` -- crossfade to new music
- `stop_music(fade_out: float = 1.0)` -- fade out music
- `set_sfx_volume(db: float)` -- adjust SFX bus
- `set_music_volume(db: float)` -- adjust Music bus

**SFX pool strategy**: On `_ready()`, pre-create 8 AudioStreamPlayer nodes for SFX. When `play_sfx` is called, find the first idle player, set its stream, and play. This avoids runtime node creation. Positional SFX (detonations, launches) use AudioStreamPlayer2D nodes in the pool instead -- however, since our game is top-down with a fixed camera, positional audio provides minimal benefit. We use non-positional AudioStreamPlayer for simplicity, with pitch variation for variety.

**AudioBus layout** (configured in Godot editor):
```
Master
  +-- Music (effects: LowPassFilter for ducking during explosions)
  +-- SFX (effects: Limiter to prevent clipping at high density)
```

---

## 6. State Management

### 6.1 Game State Machine

```gdscript
enum GameState {
    MENU,              # Title screen (future -- initially skip straight to PLAYING)
    PLAYING,           # Active gameplay, input accepted
    WAVE_TRANSITION,   # Brief pause after wave clear, score tally
    UPGRADE_SHOP,      # Shop screen visible, gameplay paused
    GAME_OVER          # Game over screen visible
}
```

**State transition diagram**:

```
                    +-------+
                    | MENU  |
                    +---+---+
                        |
                   start_game()
                        |
                        v
        +----------> PLAYING <-----------+
        |               |                |
        |          all enemies            |
        |           resolved              |
        |               |                |
        |               v                |
        |       WAVE_TRANSITION          |
        |               |                |
        |        bonuses tallied          |
        |               |                |
        |               v                |
        |         UPGRADE_SHOP           |
        |               |                |
        |         shop_closed()          |
        |               |                |
        +---------------+                |
                                         |
    all_silos_destroyed (from any PLAYING state)
                        |
                        v
                    GAME_OVER
                        |
                   restart_game()
                        |
                        v
                      PLAYING (reset)
```

**State behavior table**:

| State | GameWorld Paused | Input Accepted | UI Visible | Spawning Active |
|-------|-----------------|----------------|------------|-----------------|
| MENU | Yes | Start button only | Title screen | No |
| PLAYING | No | Mouse clicks for targeting | HUD only | Yes (during wave) |
| WAVE_TRANSITION | Yes (missiles stop) | No | HUD + wave complete text | No |
| UPGRADE_SHOP | Yes | Shop clicks only | HUD + shop overlay | No |
| GAME_OVER | Yes (except final bombardment animation) | Restart button only | Game over screen | No |

**Implementation**: Pausing gameplay uses `GameWorld.process_mode = Node.PROCESS_MODE_DISABLED` for full pause, and `Node.PROCESS_MODE_INHERIT` to resume. The UILayer always processes (`.process_mode = Node.PROCESS_MODE_ALWAYS`) so UI animations continue during pause.

### 6.2 Silo State Machine

```gdscript
enum SiloState {
    READY,        # Can fire. Bright visual.
    RELOADING,    # Cooldown active. Dim visual, radial timer showing.
    DESTROYED     # Permanently out. Crater visual.
}
```

**Transitions**:
```
READY --[fire()]--> RELOADING --[ReloadTimer.timeout]--> READY
READY --[destroy()]--> DESTROYED
RELOADING --[destroy()]--> DESTROYED
```

A silo can be destroyed while reloading (enemy missile doesn't wait for reload). DESTROYED is terminal -- no transition out (except silo_repair upgrade, which creates a new silo node rather than transitioning an existing one).

### 6.3 Blast State Machine

```gdscript
enum BlastPhase {
    EXPANDING,    # Radius growing from 0 to max. Lethal.
    HOLDING,      # Radius at max. Lethal.
    FADING        # Radius at max but alpha decreasing. NOT lethal.
}
```

**Transitions** (time-driven):
```
EXPANDING --[blast_expand_time elapsed]--> HOLDING --[blast_hold_time elapsed]--> FADING --[blast_fade_time elapsed]--> queue_free()
```

**Current radius during EXPANDING**: `current_radius = max_radius * (elapsed / blast_expand_time)` -- linear interpolation. Could use ease-out for juicier feel: `current_radius = max_radius * ease(elapsed / blast_expand_time, -2.0)`.

### 6.4 Enemy Missile State

Enemy missiles do not need a formal state machine. They have two behavioral modes:

1. **Alive**: Moving toward target, head visible, trail growing.
2. **Destroyed/Impacted**: Head hidden, movement stopped, trail fading over `trail_lifetime`. The node remains in the tree during trail fade to render the fading Line2D, then `queue_free()`.

A simple `var is_alive: bool = true` flag suffices. The `_process` function checks this flag to decide whether to update position.

---

## 7. File/Folder Structure

Complete `res://` file tree for the project:

```
res://
+-- project.godot
+-- CLAUDE.md
+-- default_bus_layout.tres                           # AudioBus layout (Master, Music, SFX)
|
+-- assets/
|   +-- data/
|   |   +-- default_config.tres                       # GameConfig resource instance
|   |   +-- upgrade_interceptor_speed.tres            # UpgradeData instance
|   |   +-- upgrade_blast_radius.tres                 # UpgradeData instance
|   |   +-- upgrade_reload_speed.tres                 # UpgradeData instance
|   |   +-- upgrade_silo_repair.tres                  # UpgradeData instance
|   |
|   +-- sprites/
|   |   +-- crosshair.png                             # Crosshair texture (or generated via _draw)
|   |
|   +-- audio/
|   |   +-- sfx/
|   |   |   +-- launch.wav                            # Interceptor launch
|   |   |   +-- detonation.wav                        # Interceptor detonation
|   |   |   +-- enemy_destroy.wav                     # Enemy destroyed
|   |   |   +-- silo_destroyed.wav                    # Silo destruction
|   |   |   +-- mirv_split.wav                        # MIRV split
|   |   |   +-- click_rejected.wav                    # Rejected click buzz
|   |   |   +-- silo_ready.wav                        # Reload complete ping
|   |   |   +-- wave_clear.wav                        # Wave clear chime
|   |   |   +-- upgrade_purchase.wav                  # Upgrade bought
|   |   |
|   |   +-- music/
|   |       +-- gameplay.ogg                          # Main gameplay loop
|   |       +-- gameover.ogg                          # Game over sting
|   |
|   +-- fonts/
|   |   +-- main_font.tres                            # Theme font (or .ttf + .tres import)
|   |
|   +-- shaders/
|       +-- glow.gdshader                             # Additive glow for bright elements
|       +-- vignette.gdshader                         # Screen-edge red vignette
|
+-- scenes/
|   +-- main.tscn                                     # Entry scene
|   +-- game/
|   |   +-- planet.tscn                               # Planet + silos
|   |   +-- silo.tscn                                 # Single silo
|   |   +-- interceptor.tscn                          # Player interceptor missile
|   |   +-- enemy_missile.tscn                        # Standard enemy / MIRV warhead
|   |   +-- mirv_missile.tscn                         # MIRV carrier
|   |   +-- blast.tscn                                # Detonation blast
|   |
|   +-- ui/
|       +-- hud.tscn                                  # In-game HUD
|       +-- wave_announce.tscn                        # Wave start announcement
|       +-- upgrade_shop.tscn                         # Upgrade shop overlay
|       +-- upgrade_card.tscn                         # Single upgrade card
|       +-- game_over.tscn                            # Game over screen
|
+-- scripts/
|   +-- autoload/
|   |   +-- game_manager.gd                           # GameManager singleton
|   |   +-- audio_manager.gd                          # AudioManager singleton
|   |
|   +-- game/
|   |   +-- main.gd                                   # Main scene orchestrator
|   |   +-- background.gd                             # Star field rendering
|   |   +-- camera_shake.gd                           # Screen shake on Camera2D
|   |   +-- crosshair.gd                              # Custom cursor
|   |   +-- planet.gd                                 # Planet container logic
|   |   +-- planet_body.gd                            # Planet visual rendering
|   |   +-- silo_manager.gd                           # Silo array management
|   |   +-- silo.gd                                   # Individual silo state
|   |   +-- silo_sprite.gd                            # Silo visual marker
|   |   +-- reload_indicator.gd                       # Silo reload radial arc
|   |   +-- interceptor.gd                            # Player missile logic
|   |   +-- enemy_missile.gd                          # Enemy missile logic
|   |   +-- mirv_missile.gd                           # MIRV carrier logic
|   |   +-- missile_head.gd                           # Shared missile head visual
|   |   +-- blast.gd                                  # Blast lifecycle + hit detection
|   |   +-- blast_visual.gd                           # Blast circle rendering
|   |   +-- spawn_validator.gd                        # Validates spawn positions (GDD 8.4)
|   |
|   +-- ui/
|   |   +-- hud.gd                                    # HUD updates
|   |   +-- vignette.gd                               # Warning vignette pulse
|   |   +-- wave_announce.gd                          # Wave announcement animation
|   |   +-- upgrade_shop.gd                           # Shop logic
|   |   +-- upgrade_card.gd                           # Single card logic
|   |   +-- game_over.gd                              # Game over screen logic
|   |   +-- score_popup.gd                            # Floating score number
|   |
|   +-- resources/
|   |   +-- game_config.gd                            # GameConfig resource class
|   |   +-- wave_data.gd                              # WaveData resource class
|   |   +-- upgrade_data.gd                           # UpgradeData resource class
|   |
|   +-- utils/
|       +-- math_utils.gd                             # Angle calculations, circle-line intersection
|       +-- color_palette.gd                          # Named color constants from GDD 11
|
+-- tests/
|   +-- unit/
|   |   +-- test_silo.gd                              # Silo state transitions
|   |   +-- test_blast.gd                             # Blast lifecycle, hit detection
|   |   +-- test_enemy_missile.gd                     # Movement, impact detection
|   |   +-- test_mirv.gd                              # Split logic, warhead spawning
|   |   +-- test_game_manager.gd                      # State machine, score, wave generation
|   |   +-- test_spawn_validator.gd                   # Spawn validation edge cases
|   |   +-- test_math_utils.gd                        # Math utility functions
|   |
|   +-- integration/
|       +-- test_wave_flow.gd                         # Full wave start->clear->shop->next
|       +-- test_targeting.gd                         # Click->silo selection->launch->detonate
|
+-- docs/
    +-- design/
    |   +-- gdd_planet_defense.md                     # Game Design Document
    +-- technical/
        +-- tdd_planet_defense.md                     # This document
```

### Script-to-Node Attachment Map

| Script | Attaches To (Node Type) | Scene File |
|--------|------------------------|------------|
| `main.gd` | Node2D (Main) | `main.tscn` |
| `background.gd` | Node2D (Background) | `main.tscn` (inline) |
| `camera_shake.gd` | Camera2D | `main.tscn` (inline) |
| `crosshair.gd` | Sprite2D | `main.tscn` (inline) |
| `planet.gd` | Node2D (Planet) | `planet.tscn` |
| `planet_body.gd` | Node2D (PlanetBody) | `planet.tscn` (inline) |
| `silo_manager.gd` | Node2D (Silos) | `planet.tscn` (inline) |
| `silo.gd` | Node2D (Silo) | `silo.tscn` |
| `silo_sprite.gd` | Node2D (SiloSprite) | `silo.tscn` (inline) |
| `reload_indicator.gd` | Node2D (ReloadIndicator) | `silo.tscn` (inline) |
| `interceptor.gd` | Node2D (Interceptor) | `interceptor.tscn` |
| `enemy_missile.gd` | Node2D (EnemyMissile) | `enemy_missile.tscn` |
| `mirv_missile.gd` | Node2D (MIRVMissile) | `mirv_missile.tscn` |
| `missile_head.gd` | Node2D (Head) | inline child in all missile scenes |
| `blast.gd` | Node2D (Blast) | `blast.tscn` |
| `blast_visual.gd` | Node2D (BlastVisual) | `blast.tscn` (inline) |
| `hud.gd` | Control (HUD) | `hud.tscn` |
| `vignette.gd` | ColorRect (WarningVignette) | `hud.tscn` (inline) |
| `wave_announce.gd` | Control (WaveAnnounce) | `wave_announce.tscn` |
| `upgrade_shop.gd` | Control (UpgradeShop) | `upgrade_shop.tscn` |
| `upgrade_card.gd` | PanelContainer (UpgradeCard) | `upgrade_card.tscn` |
| `game_over.gd` | Control (GameOverScreen) | `game_over.tscn` |
| `score_popup.gd` | Node2D (instanced at runtime) | none -- created in code |
| `spawn_validator.gd` | none (static utility, no node) | none -- autoloaded class or static |
| `math_utils.gd` | none (static utility, no node) | none -- autoloaded class or static |
| `color_palette.gd` | none (constants only, no node) | none -- preloaded |

---

## 8. Export Variables

### 8.1 `planet.gd`

| @export Variable | Type | Default | GDD Parameter |
|-----------------|------|---------|---------------|
| `planet_radius` | `float` | `80.0` | 7.1 planet_radius |
| `rotation_speed` | `float` | `0.15` | 7.1 rotation_speed |

### 8.2 `silo_manager.gd`

| @export Variable | Type | Default | GDD Parameter |
|-----------------|------|---------|---------------|
| `initial_silo_count` | `int` | `6` | 7.1 initial_silo_count |
| `silo_hit_tolerance` | `float` | `15.0` | 7.1 silo_hit_tolerance |

### 8.3 `silo.gd`

| @export Variable | Type | Default | GDD Parameter |
|-----------------|------|---------|---------------|
| `base_reload_time` | `float` | `1.5` | 7.2 silo_reload_time |

**Note**: The effective reload time is `base_reload_time + upgrade_modifier`, queried from `GameManager.get_effective_reload_time()`. The `@export` provides the base for inspector tuning; runtime values come from the GameConfig resource via GameManager.

### 8.4 `interceptor.gd`

| @export Variable | Type | Default | GDD Parameter |
|-----------------|------|---------|---------------|
| `base_speed` | `float` | `400.0` | 7.2 interceptor_speed |
| `trail_color` | `Color` | `Color("#40d0ff")` | GDD 11 interceptor trail |
| `trail_width` | `float` | `2.0` | Visual tuning |
| `head_color` | `Color` | `Color("#40d0ff")` | GDD 11 interceptor missile |
| `head_radius` | `float` | `3.0` | Visual tuning |

### 8.5 `enemy_missile.gd`

| @export Variable | Type | Default | GDD Parameter |
|-----------------|------|---------|---------------|
| `speed` | `float` | `100.0` | Set per-instance from WaveData speed range |
| `trail_color` | `Color` | `Color("#ff4040")` | GDD 11 enemy trail |
| `trail_width` | `float` | `2.5` | Visual tuning |
| `head_color` | `Color` | `Color("#ff4040")` | GDD 11 enemy missile |
| `head_radius` | `float` | `4.0` | Visual tuning |
| `is_warhead` | `bool` | `false` | GDD 4.5 -- true for MIRV warheads |
| `trail_lifetime` | `float` | `5.0` | 7.3 trail_lifetime |

### 8.6 `mirv_missile.gd`

| @export Variable | Type | Default | GDD Parameter |
|-----------------|------|---------|---------------|
| `speed` | `float` | `100.0` | Set per-instance from WaveData |
| `trail_color` | `Color` | `Color("#ffaa20")` | GDD 11 MIRV missile |
| `trail_width` | `float` | `3.0` | Visual tuning |
| `head_color` | `Color` | `Color("#ffaa20")` | GDD 11 MIRV missile |
| `head_radius` | `float` | `5.0` | Visual tuning (larger than regular) |
| `split_distance_min` | `float` | `150.0` | 7.4 mirv_split_dist_min |
| `split_distance_max` | `float` | `250.0` | 7.4 mirv_split_dist_max |
| `pulse_speed` | `float` | `3.0` | Visual tuning (glow pulse frequency) |

### 8.7 `blast.gd`

| @export Variable | Type | Default | GDD Parameter |
|-----------------|------|---------|---------------|
| `max_radius` | `float` | `40.0` | 7.2 blast_radius (set from GameManager.get_effective_blast_radius()) |
| `expand_time` | `float` | `0.3` | 7.2 blast_expand_time |
| `hold_time` | `float` | `0.2` | 7.2 blast_hold_time |
| `fade_time` | `float` | `0.2` | 7.2 blast_fade_time |
| `core_color` | `Color` | `Color("#ffffff")` | GDD 11 blast white core |
| `edge_color` | `Color` | `Color("#40d0ff")` | GDD 11 blast blue edge |

### 8.8 `camera_shake.gd`

| @export Variable | Type | Default | GDD Parameter |
|-----------------|------|---------|---------------|
| `detonation_shake_intensity` | `float` | `3.0` | GDD 6.1 interceptor detonation |
| `multi_kill_shake_intensity` | `float` | `8.0` | GDD 6.1 multiple enemies in one blast |
| `silo_destroyed_shake_intensity` | `float` | `12.0` | GDD 6.1 silo destroyed |
| `shake_decay_rate` | `float` | `5.0` | Tuning: how fast shake decays |

### 8.9 `background.gd`

| @export Variable | Type | Default | GDD Parameter |
|-----------------|------|---------|---------------|
| `star_count` | `int` | `80` | GDD 11: 50-100 stars |
| `background_color` | `Color` | `Color("#0a0a14")` | GDD 11 background |
| `star_color` | `Color` | `Color("#ffffff")` | GDD 11 |
| `twinkle_count` | `int` | `8` | Number of stars that twinkle |
| `twinkle_speed` | `float` | `2.0` | Twinkle animation speed |

### 8.10 `crosshair.gd`

| @export Variable | Type | Default | GDD Parameter |
|-----------------|------|---------|---------------|
| `default_color` | `Color` | `Color("#ffffff")` | GDD 11 crosshair |
| `reject_color` | `Color` | `Color("#ff4040")` | GDD 6.1 click rejected |
| `reject_flash_duration` | `float` | `0.15` | Visual tuning |

---

## 9. Input Handling

### 9.1 Input Method

All gameplay input is mouse-only (keyboard shortcuts are future/optional).

### 9.2 Input Processing Location

- **`main.gd._unhandled_input(event)`**: Handles all gameplay clicks (left mouse button to target). Uses `_unhandled_input` so that UI elements (upgrade shop buttons, restart button) consume their input first via `_gui_input` / `_input`, and gameplay clicks only fire when no UI element handled the event. This follows Godot best practices (GDD 9.1: "_unhandled_input for gameplay, _input for UI").

- **`crosshair.gd._process(delta)`**: Updates crosshair position to `get_global_mouse_position()` every frame. Does NOT use input events -- position tracking via `_process` ensures zero-lag cursor following.

- **`upgrade_card.gd._gui_input(event)`**: Handles click on individual upgrade cards. Uses `_gui_input` since these are Control nodes.

- **`game_over.gd._ready()`**: Connects restart button's `pressed` signal.

### 9.3 Click Processing Pipeline

```gdscript
# In main.gd

func _unhandled_input(event: InputEvent) -> void:
    if GameManager.current_state != GameManager.GameState.PLAYING:
        return

    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        var click_pos: Vector2 = get_global_mouse_position()
        _process_click(click_pos)

func _process_click(click_pos: Vector2) -> void:
    # Step 1: Reject clicks inside planet (GDD 8.7)
    var planet_center: Vector2 = planet.global_position
    if click_pos.distance_to(planet_center) < planet.planet_radius:
        click_rejected.emit("inside_planet")
        return

    # Step 2: Find nearest available silo (GDD 4.2)
    var silo: Node2D = planet.silo_manager.get_nearest_available_silo(click_pos)
    if silo == null:
        click_rejected.emit("no_silo")   # GDD 8.2
        return

    # Step 3: Launch interceptor
    silo.fire()
    _spawn_interceptor(silo.global_position, click_pos)
    GameManager.record_shot_fired()
```

### 9.4 Nearest Silo Algorithm

```gdscript
# In silo_manager.gd

func get_nearest_available_silo(target_pos: Vector2) -> Node2D:
    var best_silo: Node2D = null
    var best_distance: float = INF

    for silo in silos:
        if silo.state != Silo.SiloState.READY:
            continue
        var dist: float = silo.global_position.distance_to(target_pos)
        if dist < best_distance:
            best_distance = dist
            best_silo = silo

    return best_silo  # null if no silo available
```

### 9.5 Crosshair Implementation

The crosshair is a `Sprite2D` node (not a custom cursor set via `Input.set_custom_mouse_cursor()`) for the following reasons:
1. Sprite2D allows shader effects (glow, pulse) easily.
2. Sprite2D allows programmatic color changes (flash red on rejection).
3. Custom cursor API has platform-specific limitations on cursor size and animation.

The system cursor is hidden via `Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)` in `crosshair.gd._ready()`. The Sprite2D position is updated in `_process()` to `get_global_mouse_position()`.

If the crosshair texture is not provided as a `.png`, it is drawn procedurally in `crosshair.gd._draw()`: two perpendicular lines forming a cross, with a small gap at the center.

---

## 10. Rendering Strategy

### 10.1 Rendering Method Summary

| Element | Rendering Approach | Rationale |
|---------|-------------------|-----------|
| Star field | `_draw()` on Background node | Static points, drawn once (or redrawn on twinkle). Simple and cheap. |
| Planet disk | `_draw()` on PlanetBody | Filled circle with concentric rings for surface detail. Rotation visual via animated pattern. `draw_circle()` and `draw_arc()`. |
| Planet atmosphere | `_draw()` on PlanetBody | `draw_arc()` with low-opacity cyan, slightly larger radius. |
| Silos (ready) | `_draw()` on SiloSprite | Small triangle (3-point polygon) pointing radially outward. Color from state. |
| Silo reload arc | `_draw()` on ReloadIndicator | `draw_arc()` partial circle showing cooldown progress. |
| Silo crater (destroyed) | `_draw()` on SiloSprite | Small irregular shape or darkened circle at silo position. |
| Interceptor trail | Line2D node | Native Line2D with width curve and gradient (cyan to transparent). Points appended each frame. |
| Interceptor head | `_draw()` on MissileHead | Small filled circle, bright color. |
| Enemy trail | Line2D node | Native Line2D with gradient (red to dark red). Points appended each frame. Fades after destruction. |
| Enemy head | `_draw()` on MissileHead | Small filled circle, red. |
| MIRV trail | Line2D node | Same as enemy but yellow-orange color. |
| MIRV pulse glow | `_draw()` on MissileHead | Oscillating radius/alpha on the head circle, driven by `PulseTimer`. |
| Blast circle | `_draw()` on BlastVisual | `draw_circle()` for core, `draw_arc()` for edge ring. Radius and alpha animated per phase. |
| Blast particles | GPUParticles2D | One-shot radial burst. Preset in scene. `emitting = true` on `_ready()`. |
| Score popups | `_draw()` or Label in code | Spawned Node2D with `_draw()` text or a Label. Tweened upward + fade. |
| HUD text | Label nodes | Standard Godot Label with theme font. |
| Warning vignette | ColorRect + shader | Full-screen ColorRect with `vignette.gdshader` or modulated alpha edges. |
| Crosshair | Sprite2D or `_draw()` | Sprite if texture provided; `_draw()` for procedural cross. |

### 10.2 Trail Rendering Detail

Trails are the most visually prominent and performance-sensitive rendering element.

**Implementation** (Line2D per missile):
- Each missile scene has a child `Line2D` node.
- In `_process(delta)`, if the missile is alive, append `global_position` as a new point.
- **Point limit**: Cap at 100 points per trail. When exceeding, remove the oldest point. At 60 FPS, 100 points = ~1.67 seconds of trail. For longer visual trails, increase the limit or reduce point frequency (add a point every 2 frames).
- **Gradient**: Line2D's `gradient` property is set to fade from full opacity at the end (newest point) to zero opacity at the start (oldest point). Color: cyan for interceptors, red for enemies, yellow-orange for MIRVs.
- **Width curve**: Line2D's `width_curve` tapers from full width at the head to thin at the tail.

**Trail fade after destruction** (GDD 4.4):
- When a missile is destroyed or impacts, movement stops but the Line2D remains.
- A Tween animates the Line2D's `modulate.a` from 1.0 to 0.0 over `trail_lifetime` seconds.
- After the tween completes, the missile node calls `queue_free()`.

### 10.3 Blast Rendering Detail

```gdscript
# In blast_visual.gd

func _draw() -> void:
    var parent_blast: Node2D = get_parent()
    var radius: float = parent_blast.current_radius
    var alpha: float = parent_blast.current_alpha

    # Core circle (white, filled)
    var core_color := Color(1.0, 1.0, 1.0, alpha * 0.8)
    draw_circle(Vector2.ZERO, radius * 0.6, core_color)

    # Edge ring (blue, filled larger circle behind core)
    var edge_color := Color(0.25, 0.82, 1.0, alpha * 0.5)
    draw_circle(Vector2.ZERO, radius, edge_color)

    # Outer glow ring (very transparent, even larger)
    var glow_color := Color(0.25, 0.82, 1.0, alpha * 0.15)
    draw_circle(Vector2.ZERO, radius * 1.3, glow_color)
```

### 10.4 Planet Rendering Detail

```gdscript
# In planet_body.gd

func _draw() -> void:
    var radius: float = get_parent().planet_radius
    var rotation_angle: float = get_parent().current_rotation

    # Planet disk (filled)
    draw_circle(Vector2.ZERO, radius, Color("#1a4a5a"))

    # Surface detail: rotating lines to show rotation (latitude/longitude grid)
    # Draw a few arcs that rotate with the planet
    for i in range(3):
        var arc_angle: float = rotation_angle + i * (TAU / 3.0)
        var arc_color := Color(0.15, 0.4, 0.5, 0.3)
        draw_arc(Vector2.ZERO, radius * (0.4 + i * 0.2), arc_angle, arc_angle + PI, 16, arc_color, 1.0)

    # Atmosphere ring (outer glow)
    var atmo_color := Color("#3af0e8")
    atmo_color.a = 0.15
    draw_arc(Vector2.ZERO, radius + 4, 0, TAU, 64, atmo_color, 3.0)
```

### 10.5 Draw Order (Z-Index)

Godot 2D renders children in tree order (later children draw on top). Within same parent, `z_index` overrides.

| Layer | Z-Index | Contents |
|-------|---------|----------|
| Background | 0 (default) | Star field |
| Planet body | 1 | Planet disk + atmosphere |
| Enemy trails | 2 | Line2D trails |
| Interceptor trails | 3 | Line2D trails (drawn above enemy trails for clarity) |
| Blasts | 4 | Expanding circles + particles |
| Missile heads | 5 | Small bright dots (must be on top of trails) |
| Silo markers | 6 | On top of planet surface |
| Crosshair | 10 | Always on top of game elements |
| UI Layer | CanvasLayer (separate) | HUD, shop, announcements |

Z-indices are set on the container nodes (e.g., `Enemies.z_index = 2`, `Blasts.z_index = 4`). Child nodes inherit unless overridden.

---

## 11. Performance Considerations

### 11.1 Object Pooling Strategy

**Assessed need**: At peak load (wave 20+, GDD worst case), the screen may have:
- Up to 60 enemy missiles (enemy_count_cap) -- but only a portion active at once due to burst spawning
- Up to 6 interceptors in flight
- Up to 6 active blasts
- Trail fade nodes (destroyed missiles waiting for trail to disappear)

**Decision: No object pooling for initial implementation.** Rationale:
- Peak simultaneous node count is modest (< 100 game entities).
- Godot's node instantiation (`instantiate()`) is fast for simple scenes.
- `queue_free()` is deferred and batched, avoiding frame spikes.
- Pooling adds complexity that is not justified until profiling shows a bottleneck.

**If profiling shows issues**, the pooling approach would be:
1. Pre-create pools of 30 enemy missiles, 10 interceptors, 8 blasts at game start.
2. Instead of `instantiate()`, pull from pool and reset state.
3. Instead of `queue_free()`, hide and return to pool.
4. Pool management lives in `main.gd` since it owns the Missiles/Blasts containers.

### 11.2 Trail Point Management

Trails are the primary memory/performance concern:
- Each point in a Line2D is a `Vector2` (8 bytes) plus color gradient data.
- With 60 enemies x 100 points = 6,000 points. This is trivial for memory but Line2D with many points can be expensive to render.

**Mitigations**:
- **Point cap**: 100 points per trail (configurable). Older points removed via `remove_point(0)`.
- **Point frequency**: Add a point every other frame (30 points/sec instead of 60) for enemies. Interceptors add every frame since their trails are shorter.
- **Trail simplification**: For fading trails (dead missiles), no new points are added. The Line2D just fades via `modulate.a`.
- **Dead trail cleanup**: After trail fade completes, the node is freed. With `trail_lifetime = 5s`, at most ~50 dead trail nodes exist simultaneously in an extreme scenario.

### 11.3 `_draw()` Performance

Nodes using `_draw()` only re-render when `queue_redraw()` is called. Strategy:
- **Background**: Draw once in `_ready()` (after generating stars). Only call `queue_redraw()` on twinkle timer (every ~0.5s, for only the twinkling stars).
- **Planet body**: `queue_redraw()` every frame (rotation changes the surface detail). This is a single node drawing a few circles/arcs -- negligible cost.
- **Silo sprites**: `queue_redraw()` only on state change (READY->RELOADING, etc.) -- not every frame.
- **Reload indicators**: `queue_redraw()` every frame during RELOADING state only. At most 6 nodes.
- **Missile heads**: `queue_redraw()` not needed if the head node simply moves (position change doesn't require redraw since `_draw()` uses `Vector2.ZERO`). However, the MIRV pulse effect requires periodic `queue_redraw()`.
- **Blast visual**: `queue_redraw()` every frame during active phases. At most 6 simultaneous blasts.

**Total per-frame `_draw()` calls**: ~1 (planet) + ~6 (reload indicators) + ~1 (MIRV pulse) + ~6 (blasts) = ~14 custom draw calls. Negligible.

### 11.4 Physics / Collision Performance

No Godot physics engine is used. Blast hit detection is a manual per-frame distance check:

```
For each active blast (max 6):
    For each alive enemy (max ~40 active simultaneously):
        distance_squared check (avoids sqrt)
```

Worst case: 6 * 40 = 240 distance checks per frame. Using `distance_squared_to()` (no sqrt), this is trivial.

### 11.5 Preload vs Load Strategy

| Asset | Strategy | Rationale |
|-------|----------|-----------|
| All `.tscn` scenes | `preload()` at script top level | Scenes are small, loaded once, used repeatedly. |
| `GameConfig` resource | `preload()` in GameManager | Loaded once at game start. |
| `UpgradeData` resources | `preload()` in GameManager | 4 small resources, loaded once. |
| Audio streams (SFX) | `preload()` in AudioManager | All SFX < 100KB each. Loaded once. |
| Audio streams (Music) | `load()` on first use | Music files are larger. Load when first needed. Still only 1-2 files. |
| Font resources | `preload()` in theme `.tres` | Small, used everywhere. |
| Shaders | `preload()` via scene attachment | Compiled on first use; preload triggers compilation at load time. |

**Rule**: Everything in this project is small enough to `preload()`. Use `load()` only if a resource exceeds 1MB or is conditionally needed.

### 11.6 60 FPS Budget

At 60 FPS, each frame has ~16.6ms. Budget allocation:

| System | Budget | Notes |
|--------|--------|-------|
| Input processing | < 0.1ms | Single click check |
| Game logic (_process) | < 2ms | Move all missiles, update blast phases |
| Collision checks | < 0.5ms | 240 distance checks |
| _draw() rendering | < 2ms | ~14 custom draw calls |
| Line2D rendering (trails) | < 4ms | ~60 trails with up to 100 points each |
| Particles (GPU) | < 1ms | GPU-side, minimal CPU cost |
| UI updates | < 0.5ms | Label text changes |
| **Total** | **< 10ms** | Comfortable margin for 60 FPS |

---

## 12. Implementation Order

Each step is independently testable. Dependencies are marked with arrows.

### Phase 1: Core Foundation

**Step 1: Project Setup & Autoloads**
- Create folder structure
- Create `GameConfig` resource class and `default_config.tres`
- Create `GameManager` autoload with state machine (no logic yet, just states and transitions)
- Create `AudioManager` stub (play methods that do nothing)
- Register autoloads in `project.godot`
- Create `math_utils.gd` and `color_palette.gd`
- **Test**: GameManager state transitions, GameConfig loads correctly

**Step 2: Planet & Silos (Static)**
- Create `planet.gd`, `planet_body.gd` (draw planet disk + atmosphere)
- Create `silo.gd` with state machine (READY, RELOADING, DESTROYED)
- Create `silo_manager.gd` with static silo positioning (no rotation yet)
- Create `silo_sprite.gd` and `reload_indicator.gd`
- Create `planet.tscn` and `silo.tscn`
- **Test**: Silos render at correct positions, state changes work, reload timer works
- **Depends on**: Step 1

**Step 3: Planet Rotation**
- Add rotation logic to `planet.gd` (increment angle by `rotation_speed * delta`)
- Update `silo_manager.gd` to recalculate silo positions from rotation angle each frame
- **Test**: Silos visibly rotate around planet center. Positions match expected angles.
- **Depends on**: Step 2

**Step 4: Main Scene & Input**
- Create `main.tscn` with the full node hierarchy (except UI scenes)
- Create `main.gd` with `_unhandled_input` for click processing
- Create `crosshair.gd` (follows mouse, hides system cursor)
- Create `background.gd` (star field)
- Implement click pipeline: planet rejection, nearest silo selection, silo.fire()
- Create `camera_shake.gd` stub
- **Test**: Click outside planet selects nearest ready silo and starts its reload. Click inside planet is rejected. Click when all reloading is rejected.
- **Depends on**: Steps 2, 3

### Phase 2: Missiles & Combat

**Step 5: Interceptor Missiles**
- Create `interceptor.gd` (move toward target, emit detonated on arrival)
- Create `missile_head.gd` (shared head visual)
- Create `interceptor.tscn` with Line2D trail
- Wire click -> silo.fire() -> spawn interceptor at silo position
- **Test**: Clicking spawns interceptor that travels to click point and detonates (visual only).
- **Depends on**: Step 4

**Step 6: Blasts**
- Create `blast.gd` with EXPANDING/HOLDING/FADING lifecycle
- Create `blast_visual.gd` (draw expanding circle)
- Create `blast.tscn` with GPUParticles2D
- Wire interceptor.detonated -> spawn blast
- Add camera shake on detonation
- **Test**: Interceptor arrives, blast appears, expands, holds, fades, and frees itself. Camera shakes.
- **Depends on**: Step 5

**Step 7: Enemy Missiles**
- Create `enemy_missile.gd` (move from spawn to target, emit impacted on arrival)
- Create `enemy_missile.tscn` with Line2D trail
- Create `spawn_validator.gd` (validate spawn positions, GDD 8.4 no-occlusion check)
- Add basic manual spawning for testing (spawn a few enemies from screen edge)
- **Test**: Enemy missiles travel from screen edge to planet circumference. Trail renders correctly. Impact visual on planet surface.
- **Depends on**: Step 4

**Step 8: Blast Hit Detection**
- Implement distance check in `blast.gd._process()` against enemies in the Enemies container
- Wire enemy destruction: blast catches enemy -> `enemy.destroy()` -> trail fade -> queue_free
- Add score popup spawning on enemy destruction
- Add multi-kill detection and camera shake scaling
- **Test**: Spawn enemies and interceptor. Blast destroys enemies within radius. Score popup appears. Multi-kill detected for 3+ kills.
- **Depends on**: Steps 6, 7

**Step 9: Silo Destruction**
- Implement impact -> silo hit check in `main.gd` (angular distance comparison)
- Wire `silo.destroy()` with visual (crater) and audio
- Add heavy screen shake and hit-stop (time scale 0.8 for 0.3s) on silo destruction
- Wire `all_silos_destroyed` to GameManager
- **Test**: Enemy missile targeting a silo destroys it. Crater appears. When all silos destroyed, GameManager transitions to GAME_OVER.
- **Depends on**: Steps 7, 8

### Phase 3: MIRV & Wave Logic

**Step 10: MIRV Missiles**
- Create `mirv_missile.gd` with distance-based split logic
- Create `mirv_missile.tscn` with pulsing visual
- Implement split: spawn N EnemyMissile warheads with spread targets
- Wire MIRV pre-split destruction for bonus points
- **Test**: MIRV visually distinct. Splits at correct distance. Warheads diverge to separate targets. Pre-split kill awards bonus points.
- **Depends on**: Step 7

**Step 11: Wave Spawning System**
- Implement `WaveData` resource and wave formula generation in `GameManager`
- Implement burst-based spawning in `main.gd` (timers for burst intervals and spawn intervals)
- Determine MIRV vs regular per missile (random check against mirv_chance)
- Implement silo targeting vs random surface targeting (60/40 split)
- Implement wave completion detection (all enemies spawned AND Enemies container empty)
- **Test**: Wave 1 spawns 6 enemies in 2 bursts. Wave 5 includes MIRVs. Wave completion detected correctly.
- **Depends on**: Steps 7, 10

**Step 12: Score System**
- Implement full scoring in `GameManager`: enemy kill, MIRV pre-split, warhead, wave clear bonus, silo survival bonus, accuracy bonus
- Track shots fired / shots hit for accuracy
- **Test**: Score values match GDD formulas for various scenarios.
- **Depends on**: Steps 8, 11

### Phase 4: UI & Game Flow

**Step 13: HUD**
- Create `hud.tscn` and `hud.gd`
- Connect to GameManager signals: score_changed, wave_started, silo_count_changed
- Implement warning vignette (red screen edge when silos <= 2)
- **Test**: Score updates in real-time. Wave number displays. Vignette appears when silos low.
- **Depends on**: Steps 12, 9

**Step 14: Wave Announce**
- Create `wave_announce.tscn` and `wave_announce.gd`
- Tween-based "WAVE X" display with fade in/out during `wave_start_delay`
- **Test**: "WAVE 1" appears and fades at game start. "WAVE 2" appears between waves.
- **Depends on**: Step 11

**Step 15: Upgrade Shop**
- Create `UpgradeData` resource class and 4 `.tres` instances
- Create `upgrade_card.tscn` and `upgrade_card.gd`
- Create `upgrade_shop.tscn` and `upgrade_shop.gd`
- Wire purchase logic: click card -> deduct score -> update upgrade level -> refresh display
- Wire `shop_closed` signal to GameManager to start next wave
- Implement effective value getters in GameManager (speed, radius, reload with upgrades)
- **Test**: Shop appears after wave. Correct costs displayed. Purchase deducts score and improves stats. Maxed upgrades dimmed. Continue starts next wave.
- **Depends on**: Steps 12, 13

**Step 16: Game Over Screen**
- Create `game_over.tscn` and `game_over.gd`
- Display final stats: score, waves survived, missiles destroyed, accuracy
- Implement `restart_game()` in GameManager (full state reset)
- Wire restart button
- **Test**: Game over screen shows after all silos destroyed. Stats are accurate. Restart resets everything.
- **Depends on**: Steps 9, 12, 15

### Phase 5: Polish & Juice

**Step 17: Visual Effects Polish**
- Implement score_popup.gd (floating gold numbers that tween upward and fade)
- Add "MULTI KILL" text popup for 3+ kills
- Add impact effect for surface hits (small dust puff)
- Add silo destruction explosion effect (large, red-orange)
- Add MIRV split flash effect
- Refine planet surface visual (more detailed rotation indicator)
- **Depends on**: Steps 8, 9, 10

**Step 18: Camera & Screen Effects**
- Implement full camera shake with proper decay
- Add hit-stop (time scale reduction) on silo destruction
- Add screen flash on detonation (brief white overlay at low opacity)
- Implement vignette shader for low-silo warning
- **Depends on**: Step 17

**Step 19: Audio Integration**
- Create or source all SFX files
- Implement AudioManager SFX pool (pre-created AudioStreamPlayer nodes)
- Wire all game events to AudioManager.play_sfx() calls
- Add pitch variation to repeated sounds (launch, detonation)
- Add music playback (gameplay loop, game over sting)
- Configure AudioBus layout (Master, Music, SFX)
- **Depends on**: Step 16 (all gameplay complete)

**Step 20: Silo Repair Upgrade**
- Implement silo repair in upgrade shop (special case: dynamic cost, spawns new silo node)
- Wire into silo_manager: find destroyed silo slot, create new silo, position correctly
- **Depends on**: Step 15

### Phase 6: Final Integration & Testing

**Step 21: Full Playthrough Polish**
- Tune all balance parameters via `default_config.tres` based on playtesting
- Verify difficulty curve matches GDD Section 5.1 table
- Ensure "one more try" feel: game over -> restart is frictionless
- Verify web export works (test in Chrome, Firefox)
- **Depends on**: All previous steps

**Step 22: Automated Tests**
- Write GUT unit tests for: silo state machine, blast hit detection, wave generation, score calculation, spawn validation, math utilities
- Write integration tests for: full wave flow, targeting pipeline
- **Depends on**: All previous steps

---

## Appendix A: Key Algorithms

### A.1 Spawn Position Validation (GDD 8.4)

```gdscript
# In spawn_validator.gd

static func generate_valid_spawn(
    target_pos: Vector2,
    planet_center: Vector2,
    planet_radius: float,
    viewport_size: Vector2,
    margin: float
) -> Vector2:
    # Try up to 10 random screen-edge positions
    for _attempt in range(10):
        var spawn_pos: Vector2 = _random_screen_edge_point(viewport_size, margin)

        # Check if path from spawn to target intersects planet disk
        if not _line_intersects_circle(spawn_pos, target_pos, planet_center, planet_radius - 5.0):
            return spawn_pos

    # Fallback: pick a point on the edge nearest to the target but offset
    # to clear the planet. This guarantees a valid path.
    return _fallback_spawn(target_pos, planet_center, planet_radius, viewport_size, margin)

static func _line_intersects_circle(
    line_start: Vector2,
    line_end: Vector2,
    circle_center: Vector2,
    circle_radius: float
) -> bool:
    # Standard line-segment / circle intersection test
    var d: Vector2 = line_end - line_start
    var f: Vector2 = line_start - circle_center

    var a: float = d.dot(d)
    var b: float = 2.0 * f.dot(d)
    var c: float = f.dot(f) - circle_radius * circle_radius

    var discriminant: float = b * b - 4.0 * a * c
    if discriminant < 0:
        return false

    discriminant = sqrt(discriminant)
    var t1: float = (-b - discriminant) / (2.0 * a)
    var t2: float = (-b + discriminant) / (2.0 * a)

    # Intersection with segment if t in [0, 1]
    return (t1 >= 0.0 and t1 <= 1.0) or (t2 >= 0.0 and t2 <= 1.0)
```

### A.2 MIRV Warhead Target Spread (GDD 4.5)

```gdscript
# In mirv_missile.gd

func _generate_warhead_targets(count: int, planet_center: Vector2, planet_radius: float) -> Array[Vector2]:
    var targets: Array[Vector2] = []
    var min_spread: float = config.mirv_warhead_spread  # ~0.52 rad (~30 deg)

    # Start from a random base angle on the circumference
    var base_angle: float = randf() * TAU

    for i in range(count):
        var angle: float = base_angle + i * min_spread
        # Add small random offset for variation
        angle += randf_range(-0.1, 0.1)
        var target: Vector2 = planet_center + Vector2(cos(angle), sin(angle)) * planet_radius
        targets.append(target)

    return targets
```

### A.3 Silo Hit Detection (GDD 4.6)

```gdscript
# In silo_manager.gd

func check_silo_hit(impact_position: Vector2) -> void:
    var planet_center: Vector2 = get_parent().global_position
    var planet_radius: float = get_parent().planet_radius

    # Convert impact position to angle on circumference
    var impact_dir: Vector2 = (impact_position - planet_center).normalized()
    var impact_angle: float = impact_dir.angle()

    for silo in silos:
        if silo.state == Silo.SiloState.DESTROYED:
            continue

        var silo_dir: Vector2 = (silo.global_position - planet_center).normalized()
        var silo_angle: float = silo_dir.angle()

        # Angular distance (handling wrap-around)
        var angle_diff: float = abs(angle_difference(impact_angle, silo_angle))

        # Convert angular distance to arc length
        var arc_distance: float = angle_diff * planet_radius

        if arc_distance < silo_hit_tolerance:
            silo.destroy()
            silo_destroyed.emit(silos.find(silo), silo.global_position)
            break  # Only destroy one silo per impact
```

### A.4 Wave Data Generation (GDD 5.1)

```gdscript
# In game_manager.gd

func generate_wave_data(wave_num: int) -> WaveData:
    var data := WaveData.new()
    data.wave_number = wave_num

    # Enemy count: 6 base, +2 per wave, cap 60
    data.enemy_count = mini(
        config.initial_enemy_count + (wave_num - 1) * config.enemy_count_escalation,
        config.enemy_count_cap
    )

    # Speed range
    data.speed_min = minf(
        config.enemy_speed_min_base + (wave_num - 1) * config.enemy_speed_escalation,
        config.enemy_speed_cap - 20.0  # Ensure min < cap
    )
    data.speed_max = minf(
        config.enemy_speed_max_base + (wave_num - 1) * config.enemy_speed_max_escalation,
        config.enemy_speed_cap
    )

    # MIRV chance (0 before mirv_start_wave)
    if wave_num < config.mirv_start_wave:
        data.mirv_chance = 0.0
    else:
        data.mirv_chance = minf(
            config.mirv_base_chance + (wave_num - config.mirv_start_wave) * config.mirv_chance_per_wave,
            config.mirv_chance_cap
        )

    # MIRV warhead count range (escalates with wave)
    data.mirv_min_warheads = config.mirv_min_warheads
    if wave_num >= 15:
        data.mirv_max_warheads = config.mirv_max_warheads  # 3-4
    elif wave_num >= 8:
        data.mirv_max_warheads = 3
    else:
        data.mirv_max_warheads = 2

    # Burst count
    data.burst_count = mini(2 + wave_num / 3, 7)

    data.silo_target_ratio = config.silo_target_ratio

    return data
```

---

## Appendix B: Godot Editor Setup Notes

These steps must be performed in the Godot editor (not by Claude Code):

1. **project.godot**: Set `application/run/main_scene` to `res://scenes/main.tscn`.
2. **project.godot**: Verify `display/window/size/viewport_width=800` and `viewport_height=600`.
3. **Autoloads**: Register `res://scripts/autoload/game_manager.gd` as `GameManager` and `res://scripts/autoload/audio_manager.gd` as `AudioManager` in Project Settings > Autoload.
4. **AudioBus**: Create "Music" and "SFX" buses under Master in the Audio tab (bottom panel).
5. **Scene files (`.tscn`)**: Create the scene trees described in Section 1 using the editor. Attach scripts from Section 7's attachment map. Claude Code writes the `.gd` files; the editor wires them to nodes.
6. **Export preset**: Add a "Web" export preset for itch.io deployment (Project > Export > Add Preset > Web).

---

## Appendix C: Future-Proofing Notes

The architecture intentionally accommodates the future features listed in GDD Section 12:

| Future Feature | How Architecture Supports It |
|---------------|------------------------------|
| Mobile input (12.1) | Input processing is in `_unhandled_input` with position-based logic. Touch events produce the same `InputEventMouseButton` data. No keyboard dependencies. |
| Boss waves (12.2) | Enemies container accepts any Node2D with a common interface. A boss scene would be a new scene type with its own script, spawned by the wave system. WaveData could add a `boss: bool` field. |
| Power-ups (12.3) | A new "Powerups" container node under GameWorld. Powerup scenes follow the same pattern as missiles (move, interact, queue_free). GameManager adds powerup state. |
| Multiplayer (12.4) | Crosshair is a separate node, not tied to Input.mouse_position directly. Multiple crosshair nodes could track different input sources. Silo assignment logic in silo_manager can be extended with ownership. |
| Persistent progression (12.5) | GameManager already tracks high_score to `user://`. A meta-progression system would extend this with a SaveManager autoload. |
| Advanced enemy types (12.6) | Enemy missiles use a common pattern (move from A to B, emit signals). Shielded/stealth/guided missiles are new scenes with new scripts extending the base behavior. The spawn system selects which scene to instance based on WaveData. |
| Environmental hazards (12.7) | New container node under GameWorld for hazards. Interceptor collision with asteroids would be a distance check in interceptor._process (currently no mid-flight collision, but trivial to add). |

---

*End of Technical Design Document: Planet Defense v1.0*
*This document drives all implementation work by the GAME PROGRAMMER agent.*
*Approved by: [Pending]*
