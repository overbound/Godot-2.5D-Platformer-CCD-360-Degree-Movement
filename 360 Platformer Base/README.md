# Sonic 360 Engine Base

Godot 4.5 platformer movement inspired by classic Sonic games, featuring 360-degree surface traversal. Built with GDScript using a 2.5D approach (3D engine, 2D gameplay plane).

## Features

- **360-degree ground movement** -- player walks on floors, walls, and ceilings with smooth surface transitions
- **Sonic-style physics** -- acceleration, deceleration, and friction
- **Face-graph collision** -- CCD (continuous collision detection) with adjacency-aware face tracking for seamless traversal across curved geometry (loops, quarter pipes)
- **Jump system** -- variable-height jump with hold-to-jump-higher, air jumps, jump grace period, and face exclusion to prevent re-landing on the same surface
- **Camera system** -- dead-zone following, speed-based lookahead, screen shake, entrance animations, and priority-based camera limit zones
- **Action/state machine** -- modular action system (`ActionParent`) for player states (Run, Jump) and enemy behaviors
- **Input buffering** -- frame-accurate button and axis handling with press/hold/release tracking
- **Sprite animation** -- frame-based animation with configurable speed callables, looping, reversing, and freeze frames
- **Enemy AI** -- base enemy class with patrol, hop, and idle behaviors; off-screen culling
- **Debug tools** -- collision visualization toggle (F3), slow motion (F12), scene reload (F2), 3D debug drawing

## Project Structure

```
nomorerobots_godot/
  project.godot              # Godot project config (4.5, GL Compatibility)
  LICENSE                    # MIT License
  scenes/
    player.tscn              # Main game scene (player, camera, level, enemies)
    level_0_circle_in.tscn   # Circle-in level piece scene
  Scripts/
    player/
      Player.gd              # Main player controller (Node3D)
      PlayerPhysics.gd       # 360-degree physics engine
      PlayerAnimation.gd     # Player sprite animation handler
      CameraController.gd    # Camera follow, lookahead, shake, limits
      CameraLimitZone.gd     # Area3D-based camera boundary zones
      ActionParent.gd        # Base class for player actions
      ActionRun.gd           # Ground/air movement action
      ActionJump.gd          # Jump action with variable height
      ActionableInput.gd     # Maps inputs to actions
    Input/
      InputHandle.gd         # Autoloaded input manager
      ButtonHandle.gd        # Single button state tracking
      AxisHandle.gd          # Axis state tracking (two-button composite)
    enemies/
      EnemiesParent.gd       # Base enemy class (CharacterBody3D)
      EnemyActionParent.gd   # Base class for enemy actions
      rog/
        RogEnemy.gd          # Hopping enemy
        RogAnimation.gd      # Rog sprite animation
        RogActionIdle.gd     # Rog idle/wait state
        RogActionHop.gd      # Rog hop movement state
      sealbot/
        SealbotEnemy.gd      # Patrolling enemy
        SealbotAnimation.gd  # Sealbot sprite animation
        SealbotActionPatrol.gd # Sealbot patrol with wall/edge detection
    animation/
      AnimationHandler.gd    # Frame-based animation state machine
      AnimationSet.gd        # Animation data (loop, speed, frames, texture)
    global/
      Draw3D.gd              # Autoloaded debug line/point drawing utility
      FrameCounter.gd        # Autoloaded physics frame counter
  Actors/
    Enemy/
      Rog.tscn               # Rog enemy scene (CharacterBody3D + Sprite3D)
      SealbotEnemy.tscn      # Sealbot enemy scene (CharacterBody3D + Sprite3D)
  models/
    level0_Circle_in.blend   # Blender source for circle-in level geometry
    levelblock.blend          # Blender source for level block geometry
    make_loop.py              # Blender script to generate loop-de-loop mesh
    loop_deloop_addon.py      # Blender addon: Add > Mesh > Loop De Loop
    quarterpipe_addon.py      # Blender addon: Add > Mesh > Quarter Pipe
  sprites/
    enemies/
      smallrog.png            # Rog enemy spritesheet (7 frames)
      sealbot.png             # Sealbot enemy spritesheet (7 frames)
```

## Architecture

### Autoloads

| Name           | Script                          | Purpose                              |
|----------------|---------------------------------|--------------------------------------|
| `Draw3d`       | `Scripts/global/Draw3D.gd`     | Debug 3D lines and points            |
| `InputHandler` | `Scripts/Input/InputHandle.gd` | Centralized input state management   |
| `FrameCount`   | `Scripts/global/FrameCounter.gd` | Physics frame counter and deltas   |

### Physics Layers

| Layer | Name                        | Usage                          |
|-------|-----------------------------|--------------------------------|
| 2     | foreground                  | Level geometry                 |
| 3     | foreground_active           | Active foreground elements     |
| 10    | Interactable                | General interactables          |
| 11    | EnemyGroundCollisions       | Enemy ground detection         |
| 12    | OneWayPlatform              | Pass-through platforms         |
| 15    | PlayerStopZone              | Speed reduction zones          |

### Player Physics

The physics system (`PlayerPhysics.gd`) implements classic Sonic-style movement:

- **Surface modes**: Floor, Ceiling, Right Wall, Left Wall -- determined by ground normal angle
- **Ground movement**: Speed is tracked as `groundSpeed` projected along the ground vector
- **Air movement**: Standard gravity with velocity clamping; sub-stepped collision for accuracy
- **Wall transitions**: Face-graph adjacency tracking allows smooth movement across mesh triangle edges with miter correction at sharp angles
- **One-way platforms**: Collision layer bit filtering with drop-through support

### Action System

Both player and enemies use an action-based state machine:

- `ActionParent` / `EnemyActionParent` define `beginAction()`, `action()`, `endAction()`, `canPerform()`, `canEnd()`, `postPhysics()`, `physicsSkip()`
- Actions are swapped via buffered transitions to prevent mid-frame state corruption
- `ActionableInput` maps button/axis combinations to specific actions

### Blender Tools

Three Python scripts in `models/` for generating level geometry:

- **`make_loop.py`** -- Standalone script that creates a loop-de-loop mesh in the Blender scripting workspace
- **`loop_deloop_addon.py`** -- Blender addon (Add > Mesh > Loop De Loop) with configurable radius, segments, wall depth, width, floor height, and cap height
- **`quarterpipe_addon.py`** -- Blender addon (Add > Mesh > Quarter Pipe) with configurable arc radius, depth, and segments

## Controls

| Input          | Action                          |
|----------------|---------------------------------|
| Left/Right     | Move                            |
| Space / A / Enter | Jump (hold for higher)       |
| Down           | Drop through one-way platform   |
| F12            | Toggle slow motion (0.2x)       |
| F2             | Reload current scene            |
| F3             | Toggle collision debug drawing  |

## Requirements

- Godot 4.5+
- GL Compatibility renderer

## Known Issues

### Slope Lock Not Implemented

In the classic Sonic Physics Guide, when the player runs up a slope steeper than their current speed can climb, their controls lock and they slide backward downhill until reaching flatter ground. This engine does not implement that behavior. The player can continue attempting to move on steep slopes without being forced to slide back.

### Wall/Ceiling Fall-Off Not Implemented

In the classic Sonic Physics Guide, when the player is on a wall or ceiling and their speed drops below a threshold, they should detach and fall. This engine does not implement that behavior. The player will remain attached to walls and ceilings regardless of their speed. The `fallThreshold` variable and associated fall-off logic have been removed from the codebase.

### Slope Factor Removed

The slope factor (`slopeFactor`), which in classic Sonic pulls the player downhill on sloped surfaces, has been removed. On walls and ceilings at low speeds it caused the player's ground speed to oscillate across zero, which made the sprite rotation flip direction each frame and triggered face-edge jitter on curved surfaces. Without the fall-off behavior (see above) to resolve this, the slope factor had to be removed entirely.

### Single Angle Point vs. Dual Sensor Model

The classic Sonic physics system uses two ground sensors (left and right) positioned at the player's feet to detect the surface angle. Each sensor can hit a different surface, and the resulting angle is averaged or chosen based on which sensor is active. This allows for more nuanced behavior on uneven terrain, such as one foot on a slope and one on flat ground.

This engine uses a single ground detection point instead. The player's ground angle is determined by a single raycast downward along the ground normal, meaning there is no left/right sensor differentiation. This simplifies the collision model but results in less accurate behavior on uneven or transitioning surfaces compared to the original Sonic physics.


## Credits

- This movement example merges ideas from two movement systems — one written by MercurySilver and one written by Overbound. The two engiens were merged using Claude, DeepSeek, and MiMo models.
- **Sealbot sprite** — Designed by Strife Sabrina DiDuro

## Disclaimer

This engine is provided as-is. The physics implementation is inspired by classic Sonic games but is not a 1:1 recreation of the original physics. Values, behaviors, and edge cases may differ from the official Sonic engine. Use this as a starting point for your own projects and adjust to fit your needs.
