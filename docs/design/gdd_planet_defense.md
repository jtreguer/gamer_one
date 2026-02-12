# Game Design Document: Planet Defense

**Version**: 1.0
**Date**: 2026-02-12
**Status**: Draft - Pending Approval

---

## 1. Game Overview

**Elevator Pitch**: Planet Defense is a top-down orbital defense game where the player protects a rotating planet from incoming extraterrestrial missiles by designating detonation points in space, triggering interceptor launches from silos positioned along the planet's spinning circumference.

**Genre**: Arcade / Strategy Defense

**Platform**: Desktop (Web via Godot HTML5 export, targeting itch.io). Mobile planned as a future phase.

**Inspiration**: Missile Command (Atari, 1980) — reimagined with a polar/orbital perspective. Where Missile Command presented a flat ground with cities to defend, Planet Defense wraps the defense line into a circle and adds rotation, creating a continuously shifting tactical landscape. The core tension is identical: limited defensive resources against an accelerating onslaught, forcing triage decisions about what to save.

**Viewport**: 800 x 600 pixels (matching current project settings). The planet sits at the center. Enemy missiles approach from all screen edges — 360 degrees of threat instead of Missile Command's top-only approach.

**Session Length**: 5-15 minutes per run. Designed for "one more wave" replayability.

---

## 2. Player Experience Goal

### Moment-to-Moment Feel

The player should feel like a **desperate orbital commander** making split-second triage decisions. The core emotional arc within each wave is:

1. **Assessment** (0-2s): Wave begins. Enemy missiles appear at the edges. The player scans the screen, identifies the most dangerous threats.
2. **Action** (continuous): Rapid clicking to place detonation points. The satisfying *thump* of interceptors launching. Watching blast radii expand and swallow enemy trails.
3. **Tension** (building): Some missiles slip through. Silos rotate out of optimal firing positions. Reload timers haven't finished. The player must prioritize — which silo can I afford to lose?
4. **Relief or Dread**: The wave ends with silos intact (relief and score bonus) or a silo is destroyed (dread — fewer resources for the next wave).

### Key Sensations

- **Power**: A well-placed detonation that catches 3 enemy missiles in one blast feels incredible. The screen should reward this with visual and audio punch.
- **Anxiety**: The rotation mechanic means the "nearest silo" is always changing. A silo that was perfectly positioned 2 seconds ago has now rotated away. This creates a gentle but persistent cognitive load that distinguishes Planet Defense from static-defense games.
- **Escalating Panic**: As waves progress, the screen fills with more trails, more warheads, more split points. The player's clicking becomes faster, more frantic. This is the Missile Command DNA — the inevitability of being overwhelmed.
- **Strategic Satisfaction**: Between waves, choosing upgrades (faster interceptors vs. larger blasts vs. faster reload) creates meaningful decisions that change how the next wave plays.

---

## 3. Core Gameplay Loop

### Wave Structure

```
WAVE START
  |
  v
[Show wave number + brief pause (1.5s)]
  |
  v
[Enemy missiles begin spawning from screen edges]
[Player clicks to designate detonation points]
[Nearest available silo launches interceptor toward click point]
[Interceptors travel, detonate, create blast radius]
[Enemy missiles caught in blast are destroyed]
[Enemy MIRVs may split mid-flight]
[Enemy missiles that reach planet surface destroy silos or score damage]
  |
  v
[All enemy missiles for this wave have been spawned]
  |
  v
[Wait until all missiles resolved (destroyed or impacted)]
  |
  v
WAVE END
  |
  v
[Score tally: missiles destroyed, silos surviving, accuracy bonus]
[Upgrade shop (spend score points on interceptor upgrades)]
  |
  v
NEXT WAVE (or GAME OVER if all silos destroyed)
```

### Within a Wave

Enemy missiles spawn in sub-waves (bursts) rather than all at once. A wave might consist of 3-5 bursts with 1-3 seconds between them. This creates breathing room and rhythm — tension, action, brief respite, more tension.

---

## 4. Core Mechanics

### 4.1 Planet & Silos

**The Planet** is a filled disk centered on the screen. It is a static defensive position that the player cannot move. The planet serves as both the thing being protected and the source of all defensive firepower.

- **Visual**: A circular disk at screen center. The surface has subtle visual detail (continents, grid lines, or glow) to convey rotation. A faint atmosphere ring around the disk softens the edge.
- **Radius**: 80 pixels (diameter 160px in an 800x600 viewport). Large enough to be visually prominent, small enough to leave ample space for interceptor travel and enemy approach.
- **Rotation**: The planet rotates continuously at a slow, steady rate. This is purely visual for the planet disk itself, but the silos physically move along the circumference. Rotation is clockwise when viewed from above (consistent with a northern-hemisphere top-down view).

**Silos** are positioned at equal intervals along the planet's circumference. They rotate with the planet.

- **Count**: 6 silos at game start (spaced 60 degrees apart). This gives good coverage with meaningful gaps.
- **Positioning**: Silo positions are calculated as points on the circumference: `position = planet_center + Vector2(cos(angle), sin(angle)) * planet_radius`, where `angle` includes the rotation offset.
- **Visual**: Small triangular or diamond-shaped markers on the circumference, pointing outward (radially). Each silo has a subtle ready/reloading indicator (bright when ready, dim when reloading).
- **Destruction**: When an enemy missile hits a silo, it is permanently destroyed for the current run. The silo marker is replaced with a crater/damage visual. Fewer silos means fewer launch points, longer effective distances to targets, and a spiraling difficulty increase — the classic Missile Command death spiral.

### 4.2 Crosshair & Targeting

**Crosshair**: The default mouse cursor is replaced with a crosshair graphic. The crosshair must feel precise and responsive — zero input lag is critical.

- **Visual**: A simple cross or circle-cross, brightly colored (contrasting with the dark space background). Subtle pulse or glow to keep it visible against explosions and trails.
- **Constraint**: The crosshair can be placed anywhere on screen, but clicks inside the planet disk are ignored (you cannot detonate inside your own planet). A brief visual indicator (red flash on crosshair) communicates this rejection.

**Nearest-Silo Selection Algorithm**:

When the player clicks:

1. Calculate the Euclidean distance from the click point to each silo's current world position.
2. Filter out silos that are currently reloading (cooldown active) or destroyed.
3. From the remaining available silos, select the one with the shortest distance to the click point.
4. If no silos are available (all reloading or destroyed), the click is rejected with a "no silo available" audio/visual cue (a dull buzz, crosshair flashes red).
5. The selected silo launches an interceptor toward the click point.

**Why nearest-silo**: This creates emergent strategy. The player learns to click near the silos they want to use. As silos rotate, the "nearest available" silo changes — the player must internalize the rotation to maintain tactical control. This is the core skill ceiling of the game.

**Alternative considered**: Let the player explicitly select silos (like Missile Command's three-base system with keyboard buttons). Rejected because the rotation mechanic makes explicit selection confusing — the silos don't have fixed identities like "left/center/right." The nearest-silo algorithm turns rotation into an intuitive spatial puzzle instead of a menu-management task.

### 4.3 Interceptor Missiles

**Launch**: When a silo fires, the interceptor begins at the silo's current position on the planet circumference and travels in a straight line toward the designated detonation point.

- **Visual**: A bright streak (Line2D trail) in a distinct color (blue/cyan) to differentiate from enemy missiles. The head of the interceptor is a small bright point.
- **Speed**: Interceptors travel faster than enemy missiles (base speed ~400 px/s vs enemy base ~120 px/s). This ensures the player's shots feel responsive and powerful. Speed is upgradeable.
- **Travel time matters**: The interceptor is not instant. It must physically travel to the detonation point. During this travel time, enemy missiles continue moving. This means the player must lead their shots — clicking where enemies will be, not where they are. This is the Missile Command skill that separates novices from experts.

**Detonation**: When the interceptor reaches its designated point, it explodes.

- **Blast radius**: A circular area of effect. Any enemy missile (or enemy warhead) whose position falls within this radius at any point during the explosion's active frames is destroyed.
- **Blast duration**: The explosion expands from zero to full radius over ~0.3 seconds, holds at full radius for ~0.2 seconds, then fades over ~0.2 seconds. Total blast visibility: ~0.7 seconds. Enemy missiles can be caught during the expansion and hold phases (the first ~0.5 seconds). The fade is purely visual.
- **Base blast radius**: 40 pixels. Upgradeable to a maximum of 70 pixels.
- **Visual**: Expanding circle of bright color (white core, colored edge), with screen shake proportional to the number of enemies caught. Particle burst.

**Chain Reactions**: When an enemy missile is destroyed by a blast, it does NOT create a secondary explosion. This was considered but rejected for the initial design: chain reactions in Missile Command were one of the game's most satisfying emergent mechanics, but they also trivialized difficulty at high skill levels. Planet Defense achieves density-satisfaction through the upgrade system and larger blast radii instead.

**Future consideration**: Chain reactions could be added as a late-game upgrade or power-up for experienced players.

### 4.4 Enemy Missiles

**Spawn**: Enemy missiles originate from the edges of the screen (all four edges, 360 degrees). Each missile is given a target point on the planet's circumference at the moment of spawn.

- **Target selection**: 60% of enemy missiles target an active silo directly. 40% target a random point on the circumference (surface bombardment). This ratio ensures silos are threatened while preventing perfect prediction. The silo-targeting missiles create urgency; the random ones create noise and force resource expenditure.
- **Spawn positions**: Distributed along the screen edges. A minimum spacing between spawn points prevents visually overlapping entry trails. Missiles do not spawn from behind the planet (the center region of each screen edge where the planet would occlude the approach is excluded — see Edge Cases section 8).

**Trajectory**: Each enemy missile travels in a straight line from its spawn point to its target point on the planet circumference. The trajectory is fixed at spawn — enemies do not track rotating silos. This means a silo-targeting missile may miss its specific silo target if the planet has rotated enough by the time it arrives, but it will still hit whatever is at that circumference point (possibly a different silo, possibly empty surface).

- **Design note**: Fixed trajectories are essential. If enemies tracked rotation, the player could never predict interception points. Fixed paths create a puzzle the player can solve.

**Speed**: Enemy missiles have variable speed within a per-wave range. Within a single wave, speeds are randomized between `wave_min_speed` and `wave_max_speed`. This variation prevents the player from developing a single timing rhythm.

- **Base speed**: 80-120 px/s in wave 1. Escalates per wave.
- **Maximum practical speed**: ~300 px/s. Beyond this, interception becomes essentially reaction-impossible and the game stops being fun.

**Trails**: Each enemy missile leaves a visible trail behind it.

- **Visual**: A Line2D or series of fading points in a threatening color (red/orange). The trail persists for the duration of the wave (like Missile Command's iconic trails). Trails serve a critical gameplay function: they show the player where threats are coming from and where they're going. Without trails, the screen becomes unreadable at high missile counts.
- **Trail fading**: Trails gradually fade in opacity over ~5 seconds after the missile is destroyed or impacts. They do not disappear instantly — the fading trails of destroyed missiles give the player a sense of accomplishment and help them track which threats have been handled.

### 4.5 MIRV Mechanic

**What**: Some enemy missiles are MIRV (Multiple Independently-targetable Reentry Vehicle) carriers. At a predetermined point along their trajectory, they split into multiple warheads, each with its own target on the planet circumference.

**When they split**: MIRV missiles split when they reach a distance of 150-250 pixels from the planet center (roughly halfway through their approach in many cases). The exact split distance is randomized within this range per MIRV. Splitting too early gives the player too much time to react; splitting too late makes them functionally identical to regular missiles.

**Split count**: 2, 3, or 4 warheads. Distribution depends on the wave:
- Early MIRV waves (wave 5-8): Mostly 2-way splits.
- Mid waves (wave 9-14): Mix of 2 and 3-way splits.
- Late waves (wave 15+): Mix of 3 and 4-way splits with occasional 2-way.

**Warhead targeting**: Each warhead from a MIRV gets its own target point on the planet circumference. These targets are spread out (minimum 30 degrees apart) to maximize coverage and prevent a single blast from catching all of them.

**Visual telegraph**: MIRV-carrying missiles must be visually distinguishable from regular missiles BEFORE they split. This is a fairness requirement — the player needs to be able to prioritize MIRVs.
- **Pre-split indicator**: MIRV missiles are slightly larger, have a pulsing glow, or have a different trail color (yellow-orange vs red for regular).
- **Split animation**: A brief flash at the split point, then the warheads diverge along their new trajectories. Each warhead is smaller than the parent missile. New trails begin from the split point.
- **Audio cue**: A distinct "cracking" or "splitting" sound when a MIRV activates.

**Strategic implication**: MIRVs should be prioritized for early interception (before the split), since destroying the carrier pre-split eliminates all warheads with a single blast. Post-split, each warhead requires its own interception. This creates the key MIRV decision: spend a shot early on a missile that might be a MIRV, or wait to confirm and risk needing 3-4 shots instead of 1.

### 4.6 Silo Destruction & Loss Condition

**Silo hit**: When an enemy missile (or MIRV warhead) reaches its target point on the planet circumference and an active silo is within a hit tolerance of 15 pixels (angular distance along the circumference), the silo is destroyed.

- **Hit detection**: Check if the angular distance between the missile's impact point and any active silo is less than the hit tolerance angle. This accounts for near-misses — a missile aimed at a circumference point very close to a silo still destroys it.
- **Destruction visual**: Large explosion at the silo position. The silo marker is replaced with a crater. Brief screen shake. The silo flash-burns outward. This should feel devastating — losing a silo is a significant setback.
- **Destruction audio**: A heavy, low-frequency boom distinct from interceptor detonations. The player must viscerally feel the loss.
- **Permanent for the run**: Destroyed silos do not regenerate. This is the core punishment loop and the source of Missile Command's legendary tension. Each loss makes the next wave harder.

**Surface hit (no silo)**: When an enemy missile reaches a circumference point with no nearby silo, it impacts harmlessly on the planet surface. A minor impact visual plays (small dust cloud), but no gameplay consequence. This keeps the 40% surface-targeting missiles as a resource drain (the player may waste interceptors on them) rather than a punishment.

**Game Over**: The game ends when all silos are destroyed. The final silo's destruction triggers:
1. All remaining enemy missiles impact uncontested (dramatic visual).
2. The planet shows a destruction animation (cracks spreading, flash).
3. Game over screen with final score, waves survived, missiles destroyed, accuracy percentage.
4. Option to restart or return to menu.

**Near-game-over tension**: When only 1-2 silos remain, the game should communicate urgency. Suggestions:
- Heartbeat audio pulse.
- Screen edge vignette (red tint).
- The remaining silo markers flash or pulse.
- Music becomes more intense or shifts to a minor key.

### 4.7 Reload & Ammo

**Model: Cooldown-based (infinite ammo with per-silo reload timer)**

Each silo can fire one interceptor, then enters a reload state. During reload, the silo cannot fire. After the reload timer completes, the silo becomes available again.

**Why cooldown over limited ammo**: Limited ammo per wave (Missile Command's model) creates interesting endgame decisions but punishes new players harshly — running out of ammo with missiles still incoming is frustrating and not learnable. A cooldown system keeps the player always active, always able to respond, while still constraining their fire rate. The "limited resource" tension comes from the reload gap, not from a dwindling counter.

- **Base reload time**: 1.5 seconds. This feels snappy enough that a 6-silo setup provides near-continuous fire while still creating moments where the ideal silo is unavailable.
- **Upgradeable**: Reload time can be reduced through the upgrade system (minimum 0.6 seconds).
- **Visual feedback**: A radial cooldown indicator on each silo (like an ability cooldown in an action game). The silo dims when reloading and brightens when ready.

**Ammo consideration for future**: A "limited special ammo" system could be layered on top — for example, a super-blast with 3x radius that has limited charges per wave. This is a future consideration, not part of the initial design.

---

## 5. Progression & Difficulty Curve

### 5.1 Wave Structure

**Total waves**: Endless (the game continues until all silos are destroyed). There is no "win" state — the goal is to survive as long as possible and achieve a high score. This follows the Missile Command philosophy: the game always wins eventually.

**Wave composition**:

| Wave | Enemy Count | Speed Range (px/s) | MIRV Chance | MIRV Split | Bursts | Notes |
|------|-------------|---------------------|-------------|------------|--------|-------|
| 1 | 6 | 80-100 | 0% | - | 2 | Tutorial pace. Player learns click-to-launch. |
| 2 | 8 | 80-110 | 0% | - | 2 | Slightly more. Still relaxed. |
| 3 | 10 | 90-120 | 0% | - | 3 | First three-burst wave. Rhythm established. |
| 4 | 12 | 90-130 | 0% | - | 3 | Speed variance increases. |
| 5 | 14 | 100-140 | 15% | 2 | 3 | MIRV introduction. Visual telegraph tutorial. |
| 6 | 16 | 100-150 | 20% | 2 | 4 | More MIRVs. Prioritization matters. |
| 7 | 18 | 110-160 | 20% | 2 | 4 | Density increasing. |
| 8 | 20 | 110-170 | 25% | 2-3 | 4 | Three-way splits appear. |
| 9 | 22 | 120-180 | 30% | 2-3 | 5 | Five bursts. Less breathing room. |
| 10 | 25 | 120-190 | 30% | 2-3 | 5 | Quarter milestone. Bonus score. |
| 11-14 | +3/wave | +10 max/wave | 35% | 2-3 | 5 | Steady escalation. |
| 15 | 40 | 150-250 | 40% | 3-4 | 6 | Major difficulty spike. Four-way MIRVs. |
| 16-19 | +3/wave | +10 max/wave | 45% | 3-4 | 6 | Survival territory. |
| 20+ | +2/wave | +5 max/wave (cap 300) | 50% | 3-4 | 6 | Endgame. Speed caps. Volume is the threat. |

**Wave formula (for waves beyond the table)**:
- `enemy_count = 25 + (wave - 10) * 3` (capped at 60)
- `speed_min = min(80 + wave * 8, 200)`
- `speed_max = min(100 + wave * 12, 300)`
- `mirv_chance = min(0.10 + wave * 0.03, 0.55)`
- `burst_count = min(2 + floor(wave / 3), 7)`

### 5.2 Score System

**Points per event**:
- Enemy missile destroyed: 100 points
- MIRV carrier destroyed pre-split: 250 points (bonus for prevention)
- MIRV warhead destroyed post-split: 75 points (less than a full missile — incentivizes pre-split kills)
- Wave clear bonus: 500 * wave_number (for clearing a wave with no silo losses)
- Surviving silo bonus (end of wave): 200 * surviving_silo_count * wave_number
- Accuracy bonus: If accuracy > 80% for the wave, bonus = 300 * wave_number

**Score display**: Current score shown in the top-left corner. High score shown in top-right. Score pops with a brief scale animation when points are added.

### 5.3 Upgrade System (Between Waves)

After each wave, the player enters an upgrade screen where they can spend score points on improvements. This creates meaningful decisions and a reason to play accurately (higher score = more upgrade budget).

**Upgrade categories**:

| Upgrade | Levels | Cost per Level | Effect per Level |
|---------|--------|----------------|------------------|
| Interceptor Speed | 5 | 1000, 2000, 4000, 8000, 16000 | +60 px/s (base 400 -> max 700) |
| Blast Radius | 5 | 1500, 3000, 6000, 12000, 24000 | +6 px (base 40 -> max 70) |
| Reload Speed | 5 | 1200, 2400, 4800, 9600, 19200 | -0.18s (base 1.5s -> min 0.6s) |
| Silo Repair | N/A | 5000 * wave_number | Restores one destroyed silo |

**Shop Screen UI**:
The upgrade shop is deliberately minimal — four rectangles laid out side by side, one per upgrade (Interceptor Speed, Blast Radius, Reload Speed, Silo Repair). Each rectangle displays a clear icon representing the upgrade nature, the current level (if applicable), and the cost. A single click on a rectangle purchases the upgrade immediately — no confirmation dialog, no drag-and-drop, no hover menus. If the player cannot afford it or it is already maxed, the rectangle is visually dimmed. A "Continue" button (or click anywhere outside the rectangles) proceeds to the next wave.

**Design notes on upgrades**:
- Costs escalate exponentially to prevent any single upgrade from being maxed early.
- Silo Repair is intentionally expensive and scales with wave number. It is a comeback mechanic, not a routine purchase.
- The player cannot upgrade beyond max level. The three upgrade paths create a build identity: "speed build" (fast interceptors, precise clicks), "blast build" (large radii, area denial), "sustain build" (fast reload, volume of fire).
- The shop must feel fast. The player is in an action flow — a heavy UI breaks the rhythm. One-click purchasing keeps momentum.

---

## 6. Player Feedback

### 6.1 Visual Feedback

| Event | Visual Cue |
|-------|------------|
| **Interceptor launch** | Bright flash at silo. Interceptor streak begins. Silo dims (reloading). |
| **Interceptor detonation** | Expanding circle: white core fading to blue edge. Brief screen-wide flash (low opacity). Particles radiate outward. |
| **Enemy destroyed by blast** | Enemy trail cuts off. Small secondary burst at destruction point. Score popup (+100) floats upward. |
| **Multiple enemies in one blast** | Larger screen shake. "MULTI KILL" text popup. Score numbers cascade. Chromatic aberration pulse. |
| **Silo destroyed** | Large red-orange explosion on planet circumference. Screen shake (heavy). Brief slowdown (0.8x for 0.3s — hitstop). Crater replaces silo. Red flash at screen edges. |
| **MIRV split** | Flash at split point. Parent trail ends. 2-4 new smaller trails diverge. Brief radial burst at split point. |
| **Wave clear** | All trails fade. "WAVE CLEAR" text with wave number. Planet pulses with a protective glow. Score tally animates in. |
| **Game over** | Final explosion sequence. Planet cracks. White flash. Score summary fades in over darkened background. |
| **Click rejected (no silo)** | Crosshair flashes red. Brief "X" symbol at click point. |
| **Low silo warning (1-2 left)** | Screen edge vignette (red). Remaining silos pulse urgently. Background hue shifts warmer. |

### 6.2 Audio Feedback

| Event | Audio Cue |
|-------|-----------|
| **Interceptor launch** | Short, sharp "whoosh" with pitch variation per silo. Ascending tone. |
| **Interceptor detonation** | Deep "thump" with reverb. Satisfying low-frequency punch. |
| **Enemy destroyed** | Crisp "crackle" layered on top of detonation. Higher pitch for multi-kills. |
| **Silo destroyed** | Heavy bass boom. Distinct from interceptor detonation — more "destruction" less "controlled explosion." Warning klaxon note. |
| **MIRV split** | Sharp "crack" or "pop" — like something breaking apart. |
| **Wave clear** | Triumphant ascending chime. Brief musical sting. |
| **Game over** | Low rumble fading to silence. Somber tone. |
| **Click rejected** | Short dull buzz or "error" beep. |
| **Silo ready (reload complete)** | Subtle "ping" — quiet enough to not annoy but audible enough to inform. |
| **Background music** | Ambient synth. Low intensity in early waves, builds in tempo and layers as waves progress. Drops to minimal during upgrade screen. |

---

## 7. Balance Parameters

All values below are intended for Godot `@export` variables, allowing real-time tuning in the inspector without code changes.

### 7.1 Planet & World

| Parameter | Variable Name | Type | Default | Range | Notes |
|-----------|---------------|------|---------|-------|-------|
| Planet radius | `planet_radius` | float | 80.0 | 50-120 | Pixels from center to circumference |
| Silo count (start) | `initial_silo_count` | int | 6 | 3-8 | Number of silos at game start |
| Planet rotation speed | `rotation_speed` | float | 0.15 | 0.05-0.5 | Radians per second. 0.15 = full rotation in ~42s |
| Silo hit tolerance | `silo_hit_tolerance` | float | 15.0 | 8-25 | Pixels along circumference for hit detection |
| Silo targeting ratio | `silo_target_ratio` | float | 0.6 | 0.3-0.9 | Fraction of enemies that target silos vs random surface |

### 7.2 Interceptor Missiles

| Parameter | Variable Name | Type | Default | Range | Notes |
|-----------|---------------|------|---------|-------|-------|
| Interceptor base speed | `interceptor_speed` | float | 400.0 | 250-700 | Pixels per second |
| Blast radius (base) | `blast_radius` | float | 40.0 | 25-70 | Pixels |
| Blast expand time | `blast_expand_time` | float | 0.3 | 0.15-0.5 | Seconds to reach full radius |
| Blast hold time | `blast_hold_time` | float | 0.2 | 0.1-0.4 | Seconds at full radius (still lethal) |
| Blast fade time | `blast_fade_time` | float | 0.2 | 0.1-0.5 | Seconds to fade out (visual only) |
| Silo reload time (base) | `silo_reload_time` | float | 1.5 | 0.6-3.0 | Seconds between shots per silo |

### 7.3 Enemy Missiles

| Parameter | Variable Name | Type | Default | Range | Notes |
|-----------|---------------|------|---------|-------|-------|
| Enemy speed min (wave 1) | `enemy_speed_min_base` | float | 80.0 | 50-150 | Pixels per second, minimum for wave 1 |
| Enemy speed max (wave 1) | `enemy_speed_max_base` | float | 120.0 | 80-200 | Pixels per second, maximum for wave 1 |
| Speed escalation per wave | `enemy_speed_escalation` | float | 8.0 | 3-15 | Added to min speed per wave |
| Speed max escalation per wave | `enemy_speed_max_escalation` | float | 12.0 | 5-20 | Added to max speed per wave |
| Speed hard cap | `enemy_speed_cap` | float | 300.0 | 200-400 | Maximum enemy speed regardless of wave |
| Enemy count (wave 1) | `initial_enemy_count` | int | 6 | 4-10 | Missiles in wave 1 |
| Enemy count escalation | `enemy_count_escalation` | int | 2 | 1-4 | Additional missiles per wave |
| Enemy count cap | `enemy_count_cap` | int | 60 | 30-80 | Maximum enemies per wave |
| Spawn margin | `spawn_margin` | float | 20.0 | 0-50 | Pixels inset from screen edge for spawn |
| Trail lifetime | `trail_lifetime` | float | 5.0 | 2-10 | Seconds before destroyed missile trail fades |

### 7.4 MIRV

| Parameter | Variable Name | Type | Default | Range | Notes |
|-----------|---------------|------|---------|-------|-------|
| MIRV introduction wave | `mirv_start_wave` | int | 5 | 3-8 | First wave MIRVs can appear |
| MIRV base chance | `mirv_base_chance` | float | 0.15 | 0.05-0.3 | Probability at mirv_start_wave |
| MIRV chance escalation | `mirv_chance_per_wave` | float | 0.03 | 0.01-0.05 | Added per wave after introduction |
| MIRV chance cap | `mirv_chance_cap` | float | 0.55 | 0.3-0.7 | Maximum MIRV probability |
| MIRV split distance min | `mirv_split_dist_min` | float | 150.0 | 100-200 | Min pixels from planet center to split |
| MIRV split distance max | `mirv_split_dist_max` | float | 250.0 | 180-350 | Max pixels from planet center to split |
| MIRV min warheads | `mirv_min_warheads` | int | 2 | 2-2 | Minimum warheads per split |
| MIRV max warheads | `mirv_max_warheads` | int | 4 | 2-6 | Maximum warheads per split |
| Warhead spread angle | `mirv_warhead_spread` | float | 0.52 | 0.3-1.5 | Min radians between warhead targets (~30 deg) |

### 7.5 Scoring & Upgrades

| Parameter | Variable Name | Type | Default | Range | Notes |
|-----------|---------------|------|---------|-------|-------|
| Points per enemy kill | `points_enemy_kill` | int | 100 | 50-200 | |
| Points per MIRV pre-split kill | `points_mirv_presplit` | int | 250 | 150-400 | |
| Points per warhead kill | `points_warhead_kill` | int | 75 | 40-150 | |
| Wave clear bonus multiplier | `wave_clear_bonus` | int | 500 | 200-1000 | Multiplied by wave number |
| Silo survival bonus | `silo_survival_bonus` | int | 200 | 100-400 | Per silo, multiplied by wave number |
| Accuracy threshold | `accuracy_bonus_threshold` | float | 0.8 | 0.6-0.95 | Minimum accuracy for bonus |
| Accuracy bonus multiplier | `accuracy_bonus` | int | 300 | 100-500 | Multiplied by wave number |
| Silo repair cost multiplier | `silo_repair_cost_mult` | int | 5000 | 2000-10000 | Multiplied by wave number |

### 7.6 Wave Timing

| Parameter | Variable Name | Type | Default | Range | Notes |
|-----------|---------------|------|---------|-------|-------|
| Wave start delay | `wave_start_delay` | float | 1.5 | 0.5-3.0 | Seconds before first enemy spawns |
| Burst interval | `burst_interval` | float | 2.0 | 1.0-4.0 | Seconds between sub-wave bursts |
| Spawn interval within burst | `spawn_interval` | float | 0.3 | 0.1-0.8 | Seconds between individual missile spawns in a burst |

---

## 8. Edge Cases & Failure States

### 8.1 All Silos Destroyed

**Scenario**: The last silo is destroyed mid-wave.
**Behavior**: Game Over triggers immediately. Remaining enemy missiles continue to impact the planet (purely visual — dramatic effect). The player watches helplessly as the planet is bombarded, reinforcing the weight of failure. After all missiles resolve (or a 5-second timeout), the game over screen appears with the final score.

### 8.2 All Silos Reloading

**Scenario**: The player clicks but every surviving silo is on cooldown.
**Behavior**: The click is rejected. The crosshair flashes red and a "dull buzz" plays. The click point briefly shows an "X" marker. The player is NOT penalized in any way — the click simply doesn't produce a launch. This teaches the player to pace their clicks or wait for silo readiness indicators.

**Design note**: This situation naturally resolves in 0.5-1.5 seconds (depending on reload timers). It creates a brief, tense window where the player is defenseless, which is acceptable and adds to tension. If playtesting shows this is too punishing (especially with few silos), the reload time can be reduced.

### 8.3 Enemy Missile Hits Surface Between Silos

**Scenario**: An enemy missile reaches the planet circumference at a point that is not near any silo.
**Behavior**: The missile impacts harmlessly. A small visual effect plays (surface dust/debris) but no silo is destroyed and no score penalty occurs. The impact point shows a brief scorch mark that fades after 2 seconds.

**Design reasoning**: This is intentional. Surface-targeting missiles (40% of spawns) serve as decoys that drain the player's attention and interceptor availability without causing permanent damage. The player must decide whether a given missile is heading toward a silo or empty surface — and whether to spend a shot on it.

### 8.4 Missiles Spawning From Behind the Planet

**Scenario**: The spawn algorithm picks a screen edge point that, when drawing a line to the target on the planet circumference, would require the missile to pass through the planet disk.
**Behavior**: This must be prevented at spawn time. The spawn algorithm should:

1. Generate a candidate spawn point on a screen edge.
2. Generate a target point on the planet circumference.
3. Check if the line segment from spawn to target intersects the planet disk (circle-line intersection test with `planet_radius - 5` to add margin).
4. If intersection detected: either pick a new spawn point on a different edge, or adjust the spawn point along the current edge until the path clears the planet.
5. Guarantee: every enemy missile has a clear, unobstructed path from its spawn point to its target.

**Why this matters**: A missile that appears to travel through the planet would be visually confusing and feel unfair (the player can't see it behind the planet). All threats must be visible at all times.

### 8.5 MIRV Splits Very Close to Planet

**Scenario**: A MIRV missile splits at the minimum distance (150px from center), giving warheads very little travel time to their targets.
**Behavior**: This is intentional difficulty. The warheads still need to travel to their separate target points. Even at 150px from center (70px from surface), at enemy speed 120 px/s, the player has ~0.6 seconds to react. This is tight but possible with good blast placement.

**Mitigation**: If this proves too punishing, the `mirv_split_dist_min` can be increased to give more reaction time.

### 8.6 Player Clicks Extremely Rapidly

**Scenario**: The player spam-clicks the mouse.
**Behavior**: Each click is processed independently through the nearest-available-silo algorithm. Rapid clicking will rapidly exhaust available silos (putting them all on cooldown), then subsequent clicks will be rejected. There is no input throttle — the game's natural rate limit is the number of available silos and their reload times.

### 8.7 Player Clicks Inside the Planet

**Scenario**: The player clicks within the planet disk area.
**Behavior**: The click is rejected. The crosshair shows a brief red flash. No interceptor is launched. Reasoning: detonating inside your own planet makes no tactical sense and would visually clutter the planet surface.

### 8.8 Interceptor and Enemy Missile Collision Mid-flight

**Scenario**: An interceptor passes through an enemy missile on its way to the designated detonation point.
**Behavior**: No interaction. Interceptors only destroy enemies upon detonation at their designated point (via blast radius). They do not have collision detection during travel. This is consistent with Missile Command and is important for predictability — the player designates WHERE the explosion happens, not what it hits along the way.

### 8.9 Enemy Missile Reaches Target During Blast Fade

**Scenario**: An enemy missile enters a blast radius during the fade phase (after the hold phase ends).
**Behavior**: The missile is NOT destroyed. The fade phase is purely visual. Only the expand and hold phases are lethal. This must be visually clear — the blast opacity/color should clearly communicate "still dangerous" vs "fading away."

---

## 9. Dependencies on Godot Systems

### 9.1 Node Types & Their Roles

| Godot Node | Usage | Notes |
|------------|-------|-------|
| **Node2D** | Planet, Silos, Missiles (interceptor + enemy) | Base for all game entities with position |
| **Area2D + CollisionShape2D (circle)** | Blast radius detection | Area2D for the detonation. Enemy missiles as Area2D or use manual distance checks |
| **Line2D** | Missile trails (both interceptor and enemy) | Add points as missile moves. Set gradient for fade effect |
| **Sprite2D or draw()** | Planet visual, silo markers, crosshair, explosions | `_draw()` for procedural circles; Sprite2D if using textures |
| **GPUParticles2D** | Explosion particles, trail particles, silo destruction | Particle systems for visual juice |
| **Timer** | Silo reload, wave timing, burst intervals, blast duration | Godot Timer nodes for all time-based events |
| **AudioStreamPlayer** | Music, global SFX | Non-positional audio for music and UI sounds |
| **AudioStreamPlayer2D** | Positional SFX (explosions, launches) | 2D positional audio for spatial feedback |
| **CanvasLayer** | UI (HUD, score, wave indicator, upgrade screen) | Separate layer so UI is not affected by camera shake |
| **Camera2D** | Screen shake | Attach to main scene; offset for shake effect |
| **Label / RichTextLabel** | Score display, wave text, upgrade UI, game over text | UI text elements |
| **Control nodes** | Upgrade screen buttons, menus | VBoxContainer, HBoxContainer, Button, etc. |
| **AnimationPlayer** | Screen transitions, UI animations, wave announcements | Tween or AnimationPlayer for polish |
| **Tween** | Blast radius expansion, fade effects, score popups | Programmatic animations |

### 9.2 Autoload Singletons

| Autoload | Responsibility |
|----------|----------------|
| **GameManager** | Game state (playing, paused, wave_transition, game_over), wave counter, score, upgrade state |
| **AudioManager** | SFX pool management, music playback, volume control |

### 9.3 Signal Architecture (High Level)

```
Player clicks → Main scene receives input
  → Calculates nearest available silo
  → Emits interceptor_launch(silo, target_point)

InterceptorMissile reaches target
  → Emits detonated(position, radius)
  → Blast Area2D checks overlapping enemy areas
  → For each enemy hit: emits enemy_destroyed(enemy, position)

EnemyMissile reaches planet
  → Emits impacted(position)
  → Main scene checks if a silo is at that position
  → If yes: emits silo_destroyed(silo_index)
  → GameManager checks remaining silos → emits game_over if zero

MIRVMissile reaches split distance
  → Emits mirv_split(position, warhead_targets)
  → Spawns warhead missiles

Wave timer completes
  → GameManager emits wave_complete
  → Transition to upgrade screen
```

### 9.4 Physics & Collision

This game does NOT require Godot's physics engine (no rigid bodies, no gravity simulation). All movement is calculated via position += direction * speed * delta in `_process()` or `_physics_process()`. Collision detection for blasts uses either:

- **Area2D overlap**: Each blast and enemy missile has an Area2D. Use `area_entered` signal. Simple but may have frame-timing issues at high speeds.
- **Manual distance check**: In each frame, check `blast_position.distance_to(enemy_position) < blast_radius`. More predictable, avoids tunneling. **Recommended approach** given the simplicity of the collision shapes (circles and points).

A hybrid is acceptable: Area2D for the blast (since it expands over time and needs continuous overlap detection), with enemy missiles as simple position-based entities checked against the blast circle each frame.

---

## 10. Acceptance Criteria

The game is considered "feeling right" when the following measurable goals are met:

### 10.1 Responsiveness
- [ ] Click-to-launch latency is imperceptible (< 1 frame / 16ms).
- [ ] Crosshair tracks mouse position with zero visible lag.
- [ ] Interceptor launch is visually confirmed within the same frame as the click.

### 10.2 Readability
- [ ] At 20 enemy missiles on screen simultaneously, the player can distinguish individual missile paths.
- [ ] MIRV missiles are identifiable before they split in at least 80% of playtest observations.
- [ ] The player can tell which silos are available vs. reloading at a glance.
- [ ] Enemy missiles heading toward silos vs. empty surface are distinguishable by their trajectory (trails show destination).

### 10.3 Game Feel
- [ ] Destroying 3+ enemies in a single blast feels rewarding (screen shake + audio + visual feedback combine for "juice").
- [ ] Losing a silo feels significant and punishing (distinct from background noise).
- [ ] The rotation mechanic is noticeable but not disorienting. Playtesters understand within 2 waves that silos are moving.
- [ ] The game reaches "frantic but fair" difficulty by wave 8-10 for an average player.
- [ ] An average player survives to wave 8-12 on their first run.
- [ ] A skilled player can survive to wave 20+ with good upgrade choices.

### 10.4 Performance
- [ ] Maintains 60 FPS with 40 enemy missiles, 6 active blasts, and full trail rendering.
- [ ] No visible frame drops during MIRV split animations.
- [ ] Web export runs smoothly in Chrome and Firefox.

### 10.5 Session Quality
- [ ] A full game session (game start to game over) takes 5-15 minutes for a mid-skill player.
- [ ] The player wants to immediately restart after a game over ("one more try" factor).
- [ ] The upgrade system creates at least 3 meaningfully different playstyles.

---

## 11. Visual Style Notes

**Direction: Retro-Neon Minimalism**

The visual style should evoke the stark, abstract feel of early arcade games while using modern rendering for polish. Think Geometry Wars meets Missile Command — clean shapes, vivid colors against deep black, with glow and particle effects for energy.

### Color Palette (Initial Proposal)

| Element | Color | Hex | Notes |
|---------|-------|-----|-------|
| Background (space) | Near-black with subtle star field | `#0a0a14` | Very dark blue-black. Occasional faint star twinkle. |
| Planet body | Deep teal/cyan | `#1a4a5a` | Darker center, lighter edge. Subtle surface pattern. |
| Planet atmosphere | Soft cyan glow | `#3af0e8` (low opacity) | Thin ring outside planet edge. Conveys "atmosphere." |
| Silos (ready) | Bright green | `#40ff40` | Clearly visible, "ready" color. |
| Silos (reloading) | Dim green/grey | `#2a6630` | Obviously different from ready state. |
| Silo (destroyed) | Dark red/brown | `#4a1a0a` | Crater color. |
| Interceptor missile | Bright cyan/blue | `#40d0ff` | Player's color. Clearly "friendly." |
| Interceptor trail | Cyan (fading) | `#40d0ff` to transparent | Thinner than enemy trails. |
| Blast (expanding) | White core, blue edge | `#ffffff` to `#40d0ff` | Bright and satisfying. |
| Enemy missile | Red-orange | `#ff4040` | Classic "threat" color. |
| Enemy trail | Red (fading) | `#ff4040` to `#601010` | Thick, ominous trails. |
| MIRV missile | Yellow-orange (pulsing) | `#ffaa20` | Distinct from regular enemies. Pulsing glow. |
| MIRV warhead | Orange-red | `#ff6020` | Smaller than parent. |
| Crosshair | Bright white/yellow | `#ffffff` or `#ffff60` | Maximum contrast. |
| UI text | White | `#e0e0e0` | Clean, readable. |
| Score popups | Gold | `#ffd040` | Celebratory. |
| Warning vignette | Dark red | `#600000` (low opacity) | Edge vignette when silos are low. |

### Rendering Notes
- All game elements use simple geometric shapes (circles, lines, triangles). No complex sprites are needed for the initial version.
- Liberal use of additive blending for glows and explosions (CanvasItem blend mode).
- Subtle bloom/glow effect on bright elements if performance allows (shader or CanvasItem modulation).
- Star field in background: 50-100 small white dots at random positions, a few with slow twinkle animation. Static (no scrolling).

---

## 12. Future Considerations

These features are designed for but NOT implemented in the initial version. The architecture should not preclude them.

### 12.1 Mobile Input
- Touch replaces mouse click. Crosshair follows touch point (or appears at touch position).
- Multi-touch could allow designating multiple detonation points rapidly.
- Need to ensure UI elements (upgrade screen) have touch-friendly hit areas (minimum 44x44 px).
- Planet and silo visuals may need to scale up for smaller screens.

### 12.2 Boss Waves
- Every 10 waves, a "boss" appears: a large enemy ship that orbits the screen edge and launches coordinated missile barrages.
- The boss has a health bar and requires multiple blast hits to destroy.
- Boss adds a priority target (destroy the source) vs. resource management (intercept the missiles) tension.

### 12.3 Power-Ups
- Occasionally, a friendly supply pod enters from the screen edge. The player must NOT shoot it (anti-trigger discipline).
- Power-ups could include: temporary blast radius boost, instant reload on all silos, shield bubble that blocks one hit on a silo, EMP that slows all enemy missiles for 5 seconds.
- Power-ups drift slowly across the screen and must be "collected" by clicking on them (different action than attack).

### 12.4 Multiplayer
- **Co-op**: Two players share the same planet, each controlling their own crosshair. Silos are divided between players. Requires split-color crosshairs and careful silo assignment.
- **Competitive**: Two planets on screen, each player defending their own. Enemy missiles attack both. Could include "redirect" mechanic where intercepting an enemy near your planet sends it toward the opponent.

### 12.5 Persistent Progression
- Meta-progression between runs: permanent upgrades purchased with a "prestige" currency earned per run (based on score thresholds).
- Unlockable planet skins, explosion effects, crosshair styles.
- Leaderboard (local first, online later).

### 12.6 Advanced Enemy Types
- **Shielded missiles**: Require two blast hits to destroy. First hit removes shield, second destroys.
- **Stealth missiles**: No trail visible until they reach a certain distance from the planet. Radar ping gives brief positional hints.
- **Decoy missiles**: Look like real missiles but disappear harmlessly at mid-range. Waste the player's interceptors.
- **Guided missiles**: Slowly curve toward the nearest active silo. Harder to predict but slower than regular missiles.

### 12.7 Environmental Hazards
- **Asteroid field**: Debris that blocks interceptor paths (interceptors detonate on contact with asteroids, wasting the shot).
- **Solar flare**: Periodic event that disables all silos for 2-3 seconds. Announced in advance so the player can pre-place shots.

---

*End of Game Design Document: Planet Defense v1.0*
*This document drives all downstream architecture, implementation, art, audio, and testing work.*
*Approved by: [Pending]*
