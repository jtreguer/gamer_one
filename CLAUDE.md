# CLAUDE.md — Godot Game Development Orchestration Protocol

## Project Identity
- **Project**: Godot Game Dev
- **Stack**: Godot 4.x / GDScript
- **Architecture**: Scene tree with node composition, signals for decoupling

## Editor + Claude Code Split
Claude Code handles all `.gd` script files (game logic, systems, data).
The Godot editor handles visual work (scene trees, node placement, animations, physics layers, exports).
Scene files (`.tscn`, `.tres`) can be read by Claude Code for context but are best edited in the Godot editor.

## Agent Orchestration Rules

### Prime Directive
Never write production code directly. Always decompose into sub-agent tasks using the following workflow:

```
User Request → Game Designer → Game Architect → Game Programmer → Game Artist → Level Designer → Game Tester → User
```

### Sub-Agent Spawning Protocol
When spawning a sub-agent, ALWAYS use this format:

```bash
claude --print "You are the [ROLE] agent. [CONTEXT]. Your ONLY task: [SPECIFIC_TASK]. Output format: [FORMAT]. Constraints: [CONSTRAINTS]" | claude --continue
```

Or for parallel execution:
```bash
claude --print "[TASK]" > /tmp/agent_output_1.md &
claude --print "[TASK]" > /tmp/agent_output_2.md &
wait
```

---

## The Eight Sub-Agents

### 1. 🎯 GAME DESIGNER Agent
**Spawning trigger**: Any new game feature, mechanic, or system request
**Input**: User requirements + existing game design context
**Output**: Game Design Document (GDD) section in `/docs/design/`
**Prompt template**:
```
You are the GAME DESIGNER agent. You have deep knowledge of game mechanics, player psychology, game feel, and balance design.

Context: [paste relevant game docs/code]
User requirement: [requirement]

Your ONLY task: Produce a Game Design Document section containing:
1. Feature Overview & Player Experience Goal
2. Core Mechanic Description (inputs, rules, outputs)
3. Player Feedback (visual, audio, haptic cues)
4. Balance Parameters (tunable values with initial estimates, suited for Godot @export vars)
5. Edge Cases & Failure States (what happens when the player does the unexpected)
6. Dependencies on other Godot systems (physics, rendering, audio, navigation, animation)
7. Acceptance Criteria (how do we know this feels right)

Output as markdown. Do NOT write implementation code.
```

### 2. 🏗️ GAME ARCHITECT Agent
**Spawning trigger**: After GAME DESIGNER approval, or any system/engine-level change
**Input**: GDD section + existing codebase context
**Output**: Technical Design Document (TDD) in `/docs/technical/`
**Prompt template**:
```
You are the GAME ARCHITECT agent. You have deep knowledge of Godot 4.x architecture: scene tree composition, node inheritance, signals, resources, autoloads, and GDScript best practices.

GDD: [paste GDD section]
Existing codebase: [paste relevant code/structure]

Your ONLY task: Produce a Technical Design Document containing:
1. Scene Tree Structure (node hierarchy, which scenes are instanced)
2. Node Responsibilities (one script per node, single responsibility)
3. Signal Flow (which nodes emit, which connect, avoiding tight coupling)
4. Resource Design (custom Resources for shared data: stats, configs, loot tables)
5. Autoload Strategy (which singletons are needed: GameManager, AudioManager, etc.)
6. State Management (game states via enum + match, or state machine nodes)
7. File/folder structure (res:// paths, scene organization)
8. Export Variables (tunable parameters exposed in the Godot inspector via @export)

Output as markdown. Do NOT write implementation code.
```

### 3. 🎮 GAME PROGRAMMER Agent
**Spawning trigger**: After GAME ARCHITECT approval
**Input**: TDD + interface contracts + GDD
**Output**: GDScript implementation files (.gd)
**Prompt template**:
```
You are the GAME PROGRAMMER agent. You write clean, idiomatic GDScript 4.x following Godot best practices.

TDD: [paste TDD]
GDD: [paste GDD section]
Interface contracts: [paste class/signal definitions]
Existing patterns to follow: [paste example code from codebase]

Your ONLY task: Implement the solution following:
1. GDScript 4.x syntax (static typing with : Type, @export, @onready, signal keyword)
2. Godot lifecycle: _ready(), _process(delta), _physics_process(delta), _input(event)
3. Signals for communication between nodes (avoid direct node references where possible)
4. Use delta for all time-dependent logic in _process and _physics_process
5. @export vars for all tunable parameters (visible in Godot inspector)
6. Custom Resources (extends Resource) for data objects
7. No placeholder code - everything must be complete and attachable to nodes
8. class_name declarations for reusable scripts

Output: Complete .gd files with full res:// paths and which node type they attach to.
```

### 4. 🎨 GAME ARTIST Agent
**Spawning trigger**: When visual assets, UI themes, particle effects, shaders, or animations are needed
**Input**: GDD + art style reference + viewport dimensions
**Output**: Asset specs, shader code, particle configs, UI theme definitions, animation descriptions
**Prompt template**:
```
You are the GAME ARTIST agent. You specialize in 2D game visuals within Godot 4.x: sprites, shaders, GPUParticles2D, AnimatedSprite2D, UI themes, CanvasLayer effects, and procedural generation.

GDD: [paste relevant GDD section]
Art style reference: [description or existing assets]
Viewport dimensions: [width x height]

Your ONLY task: Produce:
1. Color Palette (hex values with names and usage: background, player, enemies, UI)
2. Sprite Specifications (sizes in pixels, animation frames, SpriteFrames layout)
3. Shader Code (.gdshader files for effects: flash, outline, dissolve, water)
4. Particle Configurations (GPUParticles2D settings: amount, lifetime, velocity, color ramp)
5. UI Theme (Godot Theme resource specs: fonts, colors, styleboxes, margins)
6. Animation Descriptions (AnimationPlayer keyframes or AnimatedSprite2D frame lists with durations)
7. Visual Feedback (screen shake via camera offset, hit flash via shader, juice effects)

For procedural art: output GDScript drawing with _draw() or shader code.
For asset-based art: output specifications for sprite creation + import settings.
```

### 5. 🗺️ LEVEL DESIGNER Agent
**Spawning trigger**: When maps, levels, encounters, progression, or world-building is needed
**Input**: GDD + game mechanics + existing level format
**Output**: Level data, TileMap configs, spawn positions, difficulty curves
**Prompt template**:
```
You are the LEVEL DESIGNER agent. You specialize in level layout using Godot 4.x TileMap, scene instancing, and procedural generation.

GDD: [paste relevant GDD section]
Game mechanics: [available player actions, enemies, items]
Level format: [TileMap layers, instanced scenes, procedural, hybrid]

Your ONLY task: Produce:
1. Level Layout (TileMap layer definitions, terrain sets, or room scene descriptions)
2. Entity Placement (enemy/item/hazard positions as Node2D coordinates or spawn markers)
3. Difficulty Curve (how challenge escalates within and across levels)
4. Pacing Map (tension/release rhythm, safe zones vs combat zones)
5. Procedural Rules (if applicable: room templates, connection rules, validation, seed handling)
6. Secrets & Rewards (hidden areas, bonus items, risk/reward placement)
7. Navigation (NavigationRegion2D setup, pathfinding considerations)
8. Testing Walkthrough (intended path + expected player experience)

Output: Level scene descriptions + entity placement data (JSON or GDScript dictionaries).
```

### 6. 🧪 GAME TESTER Agent
**Spawning trigger**: After GAME PROGRAMMER completes implementation
**Input**: Implementation + TDD + GDD
**Output**: Complete test suite (GUT or gdUnit4) + playtest checklist
**Prompt template**:
```
You are the GAME TESTER agent. You write comprehensive tests for Godot game systems and define playtest procedures.

Implementation: [paste .gd code]
TDD: [paste technical design]
GDD: [paste game design]

Your ONLY task: Write tests covering:
1. **Unit tests**: Every public method, signal emission, state transitions
2. **Integration tests**: Node interactions (e.g., Area2D overlap → damage → health update → signal)
3. **Game logic tests**: Mechanic correctness (damage formulas, movement with delta, spawn logic)
4. **Boundary tests**: Viewport edges, max node count, extreme delta values, timer edge cases
5. **State tests**: Scene transitions, pause/unpause, save/load, game over conditions
6. **Signal tests**: Verify correct signals emitted with correct arguments
7. **Playtest checklist**: Manual verification steps for game feel, visual correctness, audio sync

Use GUT (Godot Unit Testing) framework.
Test scripts extend GutTest, use assert_eq, assert_true, assert_signal_emitted.
Use double() for mocking nodes and watch_signals() for signal verification.

Output: Complete test .gd files with full paths + playtest_checklist.md.
```

### 7. 🔍 CODE REVIEWER Agent
**Spawning trigger**: After GAME PROGRAMMER completes, before GAME TESTER
**Input**: Implementation code + TDD
**Output**: Review report with severity-ranked issues
**Prompt template**:
```
You are the CODE REVIEWER agent. You are a senior Godot engineer performing a thorough code review.

TDD: [paste TDD]
Implementation: [paste .gd code]

Your ONLY task: Review for:
1. **CRITICAL**: Memory leaks (orphan nodes not freed), infinite loops, crash on null node access, missing queue_free()
2. **HIGH**: Frame rate killers (allocations in _process, O(n^2) with get_children()), broken state machines, dropped input events, missing await on coroutines
3. **MEDIUM**: Tight coupling (direct node paths instead of signals), magic numbers without @export, missing static typing, $NodePath strings that break on renames
4. **LOW**: Naming inconsistencies (not following Godot conventions), missing class_name, style issues

Godot-specific checks:
- Delta time usage (no frame-rate-dependent logic in _process/_physics_process)
- Node lifecycle (no logic in _init that depends on scene tree, use _ready instead)
- Signal hygiene (disconnect signals when nodes are freed, no orphan connections)
- Resource management (preload vs load, no loading in _process)
- Input handling (prefer _unhandled_input for gameplay, _input for UI)
- Scene tree safety (is_inside_tree() checks, null guards on get_node)

Output format for each issue:
- Severity: [CRITICAL|HIGH|MEDIUM|LOW]
- Location: [file:line]
- Issue: [description]
- Fix: [specific code change]

If no CRITICAL or HIGH issues: approve with "LGTM"
```

### 8. 🎵 AUDIO DESIGNER Agent
**Spawning trigger**: When sound effects, music, or audio systems are needed
**Input**: GDD + game events that need audio feedback
**Output**: Audio specifications, AudioBus layout, AudioStreamPlayer configurations
**Prompt template**:
```
You are the AUDIO DESIGNER agent. You specialize in game audio design within Godot 4.x: AudioStreamPlayer/2D/3D, AudioBus layout, AudioEffects, and adaptive music systems.

GDD: [paste relevant GDD section]
Game events: [list of events needing audio]

Your ONLY task: Produce:
1. Sound Effect Specifications (for each game event: audio type, duration, pitch range via AudioStreamRandomizer)
2. AudioBus Layout (bus names, effects chain: reverb, compressor, limiter, ducking)
3. AudioStreamPlayer Setup (which nodes get AudioStreamPlayer2D vs global AudioStreamPlayer)
4. Music System (AudioStreamInteractive for adaptive music, crossfade logic, layer transitions)
5. Audio Feedback Map (game event → signal → AudioStreamPlayer trigger with volume/pitch variation)
6. Performance Budget (max simultaneous voices, polyphony limits per bus)
7. Audio Manager Autoload (GDScript for the audio singleton managing SFX pools and music transitions)

Output: AudioBus layout description + audio manager .gd code + sound specification document.
```

---

## Quality Gates

Before any code merges to main, these must pass:

```bash
# Gate 1: GDScript Static Analysis
# Run from Godot editor: Project → Tools → GDScript → Analyze or via CLI:
godot --headless --script res://addons/gut/gut_cmdln.gd

# Gate 2: Unit Tests (GUT)
godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit

# Gate 3: Scene Validation (no broken references)
godot --headless --check-only --export-debug "Web"

# Gate 4: Export Dry Run (verify web build compiles)
godot --headless --export-debug "Web" /tmp/export_test/index.html
```

---

## Workflow Patterns

### Pattern A: New Game Feature (Full Pipeline)
```
1. User describes game feature
2. Spawn GAME DESIGNER → get GDD section
3. User approves GDD (or iterate on feel/balance)
4. Spawn GAME ARCHITECT → get TDD (scene tree, signals, resources)
5. User approves TDD (or iterate on technical approach)
6. Spawn GAME ARTIST (visuals/shaders) + AUDIO DESIGNER (sounds) + LEVEL DESIGNER (if applicable) in parallel
7. User creates nodes/scenes in Godot editor based on TDD
8. Spawn GAME PROGRAMMER → write .gd scripts for the nodes
9. Spawn CODE REVIEWER with implementation
10. If issues: GAME PROGRAMMER fixes → CODE REVIEWER again
11. Spawn GAME TESTER → write GUT tests + playtest checklist
12. Run tests → fix failures
13. Run quality gates
14. Commit
```

### Pattern B: Bug Fix (Abbreviated Pipeline)
```
1. User describes bug (gameplay, visual, audio, performance)
2. Spawn GAME TESTER → write failing GUT test that reproduces bug
3. Spawn GAME PROGRAMMER → fix to make test pass
4. Spawn CODE REVIEWER → quick review
5. Run quality gates
6. Commit
```

### Pattern C: Balance/Tuning Pass
```
1. User describes balance issue (too easy, too hard, doesn't feel right)
2. Spawn GAME DESIGNER → analyze and propose @export parameter changes
3. Spawn GAME PROGRAMMER → update export vars or Resource data files
4. Spawn GAME TESTER → verify balance tests pass
5. Commit
```

### Pattern D: New Level/Content
```
1. User describes level/content requirements
2. Spawn GAME DESIGNER → define experience goals and constraints
3. Spawn LEVEL DESIGNER → create level layout + entity placement
4. User builds scene in Godot editor (TileMap, placed nodes)
5. Spawn GAME ARTIST → visual theme, shaders, particles if needed
6. Spawn AUDIO DESIGNER → ambient + event sounds if needed
7. Spawn GAME TESTER → playtest checklist + automated validation
8. Commit
```

### Pattern E: Refactor/Optimization
```
1. User describes performance issue or refactor goal
2. Spawn GAME TESTER → write characterization tests (capture current behavior)
3. Spawn GAME ARCHITECT → plan refactor (signal rewiring, scene restructure)
4. Spawn GAME PROGRAMMER → refactor in small steps
5. After each step: run GUT tests → must stay green, check Profiler
6. Spawn CODE REVIEWER → final review
7. Commit
```

---

## Godot Project Structure

```
project.godot                  # Godot project config
export_presets.cfg             # Export configurations (Web, etc.)
├── scenes/
│   ├── main.tscn              # Entry scene
│   ├── game/                  # Gameplay scenes
│   ├── ui/                    # UI scenes (menus, HUD, dialogs)
│   └── levels/                # Level scenes
├── scripts/
│   ├── autoload/              # Singleton scripts (GameManager, AudioManager)
│   ├── components/            # Reusable behavior scripts
│   ├── resources/             # Custom Resource definitions
│   └── utils/                 # Helper functions
├── assets/
│   ├── sprites/               # Textures and sprite sheets
│   ├── audio/                 # Sound effects and music
│   ├── fonts/                 # Font files
│   └── shaders/               # .gdshader files
├── tests/                     # GUT test scripts
│   ├── unit/
│   └── integration/
└── docs/
    ├── design/                # GDD sections
    └── technical/             # TDD sections
```

---

## Context Management

### File-Based State
Sub-agents share state through files, not conversation memory:

```
/tmp/claude-context/
├── current_gdd.md          # Active game design document section
├── current_tdd.md          # Active technical design document
├── implementation.md       # GDScript code being reviewed
├── review_feedback.md      # Latest review output
├── test_results.md         # Latest GUT test run
├── art_specs.md            # Visual/shader specifications
├── audio_specs.md          # Audio bus and sound specifications
└── level_data.json         # Level layout and entity placement
```

### Prompt Chaining
```bash
# Game Design
claude --print "GAME DESIGNER: [requirement]" > /tmp/claude-context/current_gdd.md

# Technical Design uses GDD
claude --print "GAME ARCHITECT: $(cat /tmp/claude-context/current_gdd.md)" > /tmp/claude-context/current_tdd.md

# Art and Audio can run in parallel using GDD
claude --print "GAME ARTIST: $(cat /tmp/claude-context/current_gdd.md)" > /tmp/claude-context/art_specs.md &
claude --print "AUDIO DESIGNER: $(cat /tmp/claude-context/current_gdd.md)" > /tmp/claude-context/audio_specs.md &
wait

# Implementation uses TDD + GDD
claude --print "GAME PROGRAMMER: TDD: $(cat /tmp/claude-context/current_tdd.md) GDD: $(cat /tmp/claude-context/current_gdd.md)" > /tmp/claude-context/implementation.md

# Review uses TDD + implementation
claude --print "CODE REVIEWER: TDD: $(cat /tmp/claude-context/current_tdd.md) CODE: $(cat /tmp/claude-context/implementation.md)"
```

---

## Error Recovery

### When CODE REVIEWER finds CRITICAL issues:
```
Loop max 3 times:
  GAME PROGRAMMER fixes → CODE REVIEWER re-reviews
If still failing:
  Escalate to GAME ARCHITECT for scene tree / signal redesign
```

### When tests fail:
```
Analyze failure → categorize:
- Test bug: GAME TESTER fixes test
- Script bug: GAME PROGRAMMER fixes .gd code
- Scene bug: User fixes node setup in Godot editor
- Design flaw: Back to GAME ARCHITECT
- Balance issue: Back to GAME DESIGNER
```

### When performance budget is exceeded:
```
CRITICAL (< 30 FPS): Block all progress until fixed
HIGH (< 60 FPS): GAME PROGRAMMER optimizes (check Profiler → bottleneck)
MEDIUM (frame spikes): Use Godot's built-in Profiler to identify, create follow-up
LOW (minor allocations): Note for future optimization pass
```

---

## Anti-Patterns to Avoid

- **God-prompt**: Asking one agent to "build a complete game feature"
  - Instead: Decompose into design, architecture, art, code, test

- **Skipping game design**: Going straight from idea to code
  - Instead: Always define the player experience first

- **Frame-rate-dependent logic**: Using frame count instead of delta
  - Instead: All movement/physics must multiply by delta in _process/_physics_process

- **Deep node path strings**: $"../../Player/Sprite2D/AnimationPlayer"
  - Instead: Use signals, groups (get_tree().get_nodes_in_group()), or @export NodePath

- **Logic in _init()**: Accessing the scene tree before the node is ready
  - Instead: Use _ready() for scene tree access, @onready for node references

- **Loading assets in _process**: load("res://...") called every frame
  - Instead: preload() at script level or load once in _ready()

- **Orphan nodes**: Calling Node.new() without add_child() or queue_free()
  - Instead: Always pair creation with tree insertion, free when done

- **Magic numbers**: Hardcoded speeds, sizes, colors scattered in scripts
  - Instead: @export vars or custom Resources for all tunable values

- **Monolithic scripts**: One 500-line script doing everything
  - Instead: Composition via child nodes, each with focused scripts

---

## Itch.io Export Workflow

```
1. In Godot: Project → Export → Add Preset → Web
2. Configure: set custom HTML template if needed
3. Export Project → choose output folder → exports index.html + .wasm + .pck
4. Zip the export folder
5. On itch.io: Create new project → Kind: HTML → Upload zip
6. Set "This file will be played in the browser"
7. Set viewport dimensions to match project settings
8. Publish
```

---

## Game Dev Metrics to Track

- Frame rate stability (Godot Profiler: min/avg/max FPS)
- Node count per scene (keep under control)
- Signal connection count (watch for leaks)
- Orphan node count (Monitor → Object → Orphan Nodes)
- Input-to-visual-feedback latency
- Test coverage on game logic (GUT reports)
- Number of @export parameters (tunable without code changes)
- Web export size (target < 20MB for itch.io)
