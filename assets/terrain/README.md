# Swordfish Arena — Prototype Setup Guide

## File Overview
```
fish_player.gd     — Controls one fish: movement, chain segments, piercing logic
game_manager.gd    — Root scene script: spawns players, assigns devices
arena.gd           — Arena background + edge wrapping
fish_builder.gd    — (optional) helper class, not required at runtime
```

---

## Scene Setup in Godot 4

### Step 1 — Create the root scene
1. Create a new scene: **Node2D** as root
2. Attach `game_manager.gd` to the root node
3. Name it `Arena` and save as `arena.tscn`
4. Also attach `arena.gd`... actually: split into two nodes:
   - Root Node2D → `game_manager.gd`
   - Child Node2D named `ArenaVisuals` → `arena.gd`

### Step 2 — Project Settings
Go to **Project → Project Settings → Input Map** and verify these actions exist
(they're built-in defaults but confirm):
- `ui_left`, `ui_right`, `ui_up`, `ui_down` → Arrow keys and WASD
- `ui_accept` → Enter / Space

For WASD specifically, add:
- `ui_up` → W
- `ui_down` → S  
- `ui_left` → A
- `ui_right` → D

### Step 3 — No gravity
Go to **Project → Project Settings → Physics → 2D**
Set **Default Gravity** = `0`

### Step 4 — Run
Hit Play. One fish spawns for keyboard (WASD + arrow keys).
Each connected controller gets its own fish automatically.

---

## Controls

| Action | Keyboard (P1) | Controller |
|--------|--------------|------------|
| Steer | WASD | Left stick |
| Thrust forward | W / Up | Left stick up |
| Thrust back / unstick | S / Down | Left stick down |

**Turning** is tank-style: left/right rotates the fish head, forward/back thrusts.

**Unsticking:** When your bill is piercing an enemy, pull the left stick back (south)
past 60% to rip it free.

---

## How the Fish Works

```
[Bill tip] ←28px→ [Head/physics] ←28px→ [Body] ←28px→ [Tail]
     ↑ rigid           ↑ this is global_position      ↑ chain-follows
```

- **Head** = the actual physics position (`global_position` of the Node2D)
- **Bill** is placed rigidly ahead of head using `head_angle`
- **Body** and **Tail** use a distance-constrained chain follow with lag
- All four pieces are `Polygon2D` nodes repositioned every frame

---

## Piercing Logic

1. `BillArea` (Area2D at bill tip) detects overlap with `fish_body_area` group
2. On hit: attacker's velocity × 0.7 is applied to victim as impulse
3. A `PinJoint2D` is created at the bill tip, linking attacker ↔ victim
4. While stuck: attacker has reduced control, both fish move somewhat together
5. Reverse input (stick Y < -0.6) destroys the joint → fish separate

---

## Tuning Parameters (fish_player.gd @export vars)

| Var | Default | Effect |
|-----|---------|--------|
| `turn_speed` | 180°/s | How fast fish rotates |
| `thrust_force` | 400 | Acceleration force |
| `max_speed` | 350 | Top speed px/s |
| `damping` | 0.92 | How quickly fish slows (0=instant stop, 1=no friction) |
| `segment_distance` | 28px | Gap between body parts |
| `segment_lag` | 0.18 | Chain looseness (higher = more wavy) |

---

## Known Limitations / Next Steps

- **PinJoint2D** linking two plain Node2Ds won't work without `PhysicsBody2D` nodes.
  For the joint to function physically, convert fish to `RigidBody2D` or use a
  custom constraint (move victim by lerping toward attacker position each frame).
  The current code uses a **manual impulse + velocity coupling** approach as fallback.
  
- **Hitboxes** use Area2D, not physics bodies — this means no automatic collision
  response. All collision response is manual (intentional, gives more control).

- **Death/scoring** not yet implemented.

- **Wall collisions** use wrap-around instead of bounce (easy to change in arena.gd).

---

## Quick Fix: If PinJoint2D Doesn't Work

Replace `_stick_to()` in `fish_player.gd` with a manual coupling approach:

```gdscript
func _stick_to(victim: Node2D) -> void:
    is_piercing = true
    pierce_victim = victim
    victim.receive_impact(velocity * 0.7)
    # No joint — instead, in _physics_process while is_piercing:
    # pull victim toward our bill position each frame

func _physics_process(delta):
    ...
    if is_piercing and is_instance_valid(pierce_victim):
        var pull := (segment_positions[0] - pierce_victim.global_position) * 8.0 * delta
        pierce_victim.global_position += pull
```
