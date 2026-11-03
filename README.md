# Portomorto — v0.3 Functional Combat

A Godot 4.6 / GDScript side-view mechanics sandbox: responsive movement, two oriented portals, rigid crates, portal-capable projectiles, Focus time control, melee/ranged enemies, health, impact damage, hazards, and automatic respawn. No external assets, plugins, or dependencies.

## Run

Import `project.godot` with Godot **4.6.x**, then press **F6** in `scenes/sandbox.tscn` or **F5** to run the project. Windows desktop is the intended target; development validation currently uses Godot 4.6.3 on Linux. A Windows executable requires the matching official Godot export templates; no binary is included.

| Control | Action |
|---|---|
| A / D or arrows | Move |
| Space / W / Up | Jump; release early for a shorter jump |
| Left / right mouse | Place or replace portal A / B |
| Hold Shift | Focus: simulation runs at 20%; aiming and camera use real time |
| F | Fire a projectile toward the mouse |
| R | Reset the entire sandbox |
| F3 | Toggle debug text and vectors |

Slate rectangles accept portals on any sufficiently large face. Green preview means placement is valid; red means rejected. A single portal is dim and solid until paired. White flashes indicate transit. The far-right automatic emitter shoots a stationary damageable target; its health is shown in the overlay. Reset restores its health. Crates are amber, the player mint, and targets red.

## Combat sandbox

The orange melee enemy pursues within detection range and attacks at close range. The purple ranged enemy approaches until in firing range, then shoots physical projectiles. Shoot with **F**, redirect enemy fire back into its shooter, knock enemies through portals, or launch crates into enemies. The red floor strip near the middle is a damaging hazard. The elevated second crate is available for gravity/portal launches.

Player health is always shown in the bottom text. Accepted damage grants 0.5 simulation seconds of invulnerability; death stops movement/firing and reloads the room after 0.8 simulation seconds. **R** remains an immediate manual reset. Releasing Shift restores time, including while waiting to respawn.

`EnemyBrain` owns idle/approach/attack decisions and attack cooldowns. `EnemyMotor` owns gravity, bounded acceleration, knockback, collision, and the shared portal traveller. Both enemy scenes expose speed and health; the Brain child exposes detection/attack ranges, cadence, damage, and projectile speed. No AI or combat rules were added to portal code.

`ImpactDamage` measures closing velocity along the collision normal, subtracting the other body's velocity. Default threshold is 700 units/second (above a normal jump), damage is 0.1 per excess unit/second, capped at 100. The shared contact ledger suppresses duplicate reports from either participant and rearms after separation for more than three physics ticks. Fall and collision damage use the same contract. Contact impulses come from Godot's solver; impact damage adds no second impulse. Projectiles retain their separate direct-damage contract. Thresholds and coefficients scale with world units.

Enemy projectiles can hurt enemies, including their own shooter after clearing its muzzle. Player projectiles retain the original player-excluding collision mask. Melee checks line of sight so it cannot hit through walls. Hazards use bounded per-body intervals, and invulnerability is checked centrally by `HealthComponent` for all damage sources.

## Structure and tuning

- `scenes/entities/`: reusable player, crate, projectile, and target scenes. Collision shapes and `Visual` children are independent. Replace a visual without changing movement or portal code.
- `scripts/player/`: `CharacterBody2D` movement and exported `MovementSettings` resource. Acceleration, braking, air control, gravity, jump cut, coyote time, buffering, and crate push force are configurable. Air movement does not clamp above-run-speed launch momentum. Gravity and contact friction still apply normally.
- `scripts/portals/`: placement, endpoint data, coordinate math, and transit service. Placement raycasts use the World layer and the `portal_surfaces` group. Static rectangular collision shapes are the supported surface contract, including rotated rectangles.
- `scripts/components/portal_traveller.gd`: shared eligibility, velocity, shape support, and collision-exception handling. Character bodies resolve their swept motion after `move_and_slide`; rigid bodies forward their `_integrate_forces` state. A new entity composes this component and uses the appropriate adapter, rather than implementing portal math again.
- `scripts/combat/`, `scripts/components/health.gd`: `DamageEvent` → `Damage.deliver` → `HealthComponent.receive` is the shared damage/impulse contract. Signals drive presentation separately. A depleted target stays in place for inspection; no death/progression system is implied.
- `scripts/world/time_control.gd`: sole owner of `Engine.time_scale`; physics already receives scaled delta. `real_delta` is for camera/presentation only. Input remains sampled each rendered frame, and focus loss/reset restores normal time.
- `scripts/presentation/`: independent primitive visuals, camera, portal feedback, and optional debug overlay.
- `scripts/world/sandbox.gd`: sandbox composition and geometry. Exported `world_scale` explicitly resizes physics dimensions and physical tuning without scaling body transforms; `camera_zoom` controls framing independently. Rendering settings and viewport size remain standard Godot project settings, with no pixel-grid or filter lock.

The sandbox runs physics at 120 Hz. World distances use Godot units, velocities units/second, acceleration units/second², and gameplay timers simulation seconds. Avoid nonuniformly scaling physics nodes. `WorldUnits` resizes shape resources explicitly. Crates remain upright, so portals transform translation and velocity, not body spin.

## Portal mechanics and extension

For entrance normal `n₁`, exit normal `n₂`, and tangents `t = (-n.y, n.x)`, ordinary portals transform vectors as:

```text
v_out = -t₂ * dot(v_in, t₁) - n₂ * dot(v_in, n₁)
```

This is a rotation that maps inward to outward and preserves speed. The tangential position offset is reversed consistently. A swept center must cross from positive to nonpositive signed entrance-plane distance; proximity alone does nothing. Bodies are placed beyond their projected collision extent at the exit, and remaining motion is swept for clearance. Re-entry relies on direction and geometry, with no time cooldown.

Per-body exceptions open the supporting wall only while the body fits the aperture and its exit is clear. Other geometry remains collidable. An obstructed exit keeps the entrance solid. If clearance changes or a partly inserted body moves out of the aperture, it is recovered to the front before wall collision resumes. Replacing an occupied aperture is rejected until the body clears it.

To add a later portal effect, derive a small resource from `PortalEffect`, override `modify(result)`, and assign it to an endpoint's `effect`. The result has `position` and `velocity`; exit clearance is checked after modification. Ordinary portals have no effect resource. There are no speculative effect types or genre systems.

## Automated verification

From the repository root:

```sh
godot --headless --editor --import --quit
godot --headless --script tests/run.gd
godot --headless --script tests/combat.gd
godot --headless --quit-after 360
```

v0.3 verification uses Godot 4.6.3 on Linux. The **67 foundation regression checks pass**, and **22 combat checks pass at 30 and 144 FPS caps**. Editor import completed without script errors and the sandbox ran 900 frames without runtime errors. The combat suite exercises attacks, damage rejection/recovery, enemy death, portal knockback, relative-speed impacts, hazards, redirected enemy fire, Focus combat, and automatic room respawn. These are automated results, not desktop playtest results.

The test runner exits nonzero on assertion failures. It exercises actual Godot physics bodies, not just formulas: movement, floor/ceiling collisions, jump buffering/coyote time, external momentum, crate pushing, oriented velocity transforms, player/crate/projectile transit, projectile damage and knockback after transit, blocked exits, invalid placement, back-face collision, aperture recovery, rotated surfaces, repeated chaining, Focus input/transit, world scale, and scene reset.

In restricted cloud shells, use writable XDG locations outside the checkout, e.g. `XDG_DATA_HOME=/workspace/.runtime/data XDG_CONFIG_HOME=/workspace/.runtime/config XDG_CACHE_HOME=/workspace/.runtime/cache` before Godot. The editor's remote-debug socket can be denied by the shell sandbox; game/headless tests do not require that socket. Use the existing checkout; cloud tasks are already isolated and need no worktree.

See [manual validation](tests/MANUAL.md) for keyboard/mouse and visual acceptance checks that remain to be performed on a desktop.

## Known limits

- Desktop visual/input feel and Windows export have not been manually validated in this headless environment. Automated input and physics checks do not substitute for those checks.
- Portal surfaces must be stationary rectangles with a centered `CollisionShape2D`; travellers currently support centered circles and upright rectangles. Moving portals, compound/polygon shapes, spinning crates, and scaled body transforms are outside v0.1.
- Transit is atomic when the center crosses; there is no split-body rendering or view through a portal. A partially inserted shape can visually overlap its supporting surface briefly.
- Placement conservatively rejects nearby endpoints by center distance, including some nonoverlapping corner configurations. Occupied endpoints must clear before replacement.
- One crossing is resolved per body update; high-speed projectiles use CCD and exit motion is swept, but arbitrary extreme speeds and multiple portals crossed within one physics tick are not guaranteed.
- The stationary test target still remains after depletion; enemies disappear on death. Crates remain physical objects after their health is depleted.
- Enemy navigation is intentionally limited: horizontal pursuit, range checks, and attack line-of-sight. Enemies do not plan jumps, find paths around walls, or understand portals. Progression, alternate portal effects, and advanced movement remain absent.
