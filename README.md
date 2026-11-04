# Portomorto — v0.6 Three-Room Prototype

A Godot 4.6 / GDScript side-view mechanics sandbox: responsive movement, two oriented portals, rigid crates, portal-capable projectiles, Focus time control, melee/ranged enemies, health, impact damage, hazards, and automatic respawn. No external assets, plugins, or dependencies.

## Run

Import `project.godot` with Godot **4.6.x** and press **F5** to play Room 1 → Room 2 → Room 3 → Completion. The main scene is `scenes/game.tscn`. The original mechanics lab remains available: open `scenes/sandbox.tscn` and press **F6**. Individual room scenes are composed by the game manager; use F5 for their full transition/death flow. Windows desktop is the intended target; development validation currently uses Godot 4.6.3 on Linux. A Windows executable requires the matching official Godot export templates; no binary is included.

| Control | Action |
|---|---|
| A / D or arrows | Move |
| Space / W / Up | Jump; release early for a shorter jump |
| Left / right mouse | Place or replace portal A / B |
| Hold Shift | Focus: simulation runs at 20%; aiming and camera use real time |
| F | Fire a projectile toward the mouse |
| Q / T | Select portal A / B for exit-effect configuration |
| E | Grab nearby eligible object / use nearest switch; release if carrying |
| Left mouse while carrying | Throw toward cursor (consumes Portal A placement input) |
| 1 / 2 / 3 | Standard / Accelerator / Rotator on selected portal |
| Mouse wheel up / down | Rotate selected Rotator +15° / −15° |
| R | Restart current room; on completion, begin again at Room 1 |
| F3 | Toggle debug text and vectors |

Slate rectangles accept portals on any sufficiently large face. Green preview means placement is valid; red means rejected. A single portal is dim and solid until paired. White flashes indicate transit. The far-right automatic emitter shoots a stationary damageable target; its health is shown in the overlay. Reset restores its health. Crates are amber, the player mint, and targets red.

## Three-room experience

**Room 1 — Portal Traversal:** A 340-unit gap is wider than a normal jump, even from the nearby elevated ledge. Walk near the end of the starting landing, place A on the floor under your feet and B on the far wall facing the landing, and fall through A. The exit is green. Optional shortcut: place B on the far floor close to the exit instead. Both routes use normal placement and crossing rules; no frame-perfect timing is required.

**Room 2 — Physics Puzzle:** Approach the crate, press E, and carry it toward the plate while aiming slightly above/right. Stop just left of the plate, aim above its center, and press E to drop the crate. Wait for the door to open, then **jump over the crate** so it stays on the plate. Characters and projectiles cannot activate this plate. The exit remains locked until the crate supplies the required mass, even if you bypass the physical door using portals. The room has a continuous floor, ceiling and side walls to keep the crate recoverable; R restores it immediately if needed.

**Room 3 — Combat Arena:** Defeat the melee and ranged enemy, then enter the green exit. F fires at the mouse. The crate, barrel, spikes, ledge and portal surfaces offer alternative approaches. One verified route is to move the crate out of the firing lane, use jump shots and Focus to defeat the enemies, then jump over the spike strip on the way out. The exit stays locked while either enemy lives.

The completion screen offers R to play again. Death restarts only the current room with full health and fresh objects. The room number, health, objective, effect configuration and restart hint are always visible. Controls are unchanged from v0.5 (E interaction, Q/T effect selection).

### Room lifecycle

`RoomManager` owns one room instance at a time and a small completion overlay. Three scene resources in `scenes/rooms/` configure the layouts built by `PrototypeRoom`. It composes the existing player, enemy, portal, interaction, camera, hazard and mechanism components; their gameplay scripts are unchanged.

Room exits emit a signal only when their objective is satisfied and the living player overlaps the exit. Transitions/restarts are deferred and guarded against duplicates. The old room is disabled and freed before the next one is created, so projectiles, health, held objects, mechanism states, hazard cooldowns, portal endpoints and effect Resources cannot leak between rooms. The camera immediately targets the fresh player. Focus is released and normal time restored; press Shift again in the new room to resume Focus. Input Map bindings are never reconstructed or erased.

The standalone sandbox keeps its previous reset behavior and all v0.1–v0.5 testing sections. It is separate from the three-room sequence.

## Interactive environments

The original combat and portal laboratory now includes four sections in the same room:

- **A — manipulation:** the starting crate and portal surfaces. E grabs the nearest eligible object or uses the nearest switch in reach, with line-of-sight checks. E releases a held object. Left click throws while carrying; otherwise left click still places Portal A. Right click always places B. **Portal B configuration moved from E to T**; Q configures A.
- **B — explosives:** two red barrels and a destructible barrier near the right-hand entrance. Shoot a barrel, strike it hard, throw it through portals, or trigger a chain reaction. The barrier accepts projectile, explosion and impact damage.
- **C — mechanisms:** a pressure plate, crate, switch and two doors. The plate OR switch opens the first door; the switch also controls the second. Doors stop if their swept path is occupied and continue after it clears. Switches can also be shot.
- **D — hazards:** a waypoint platform, descending crusher, spikes and a lethal field. The crusher damages on its descending underside and reverses on contact, rather than driving a body through the floor.

**R** restarts every interaction. Health, death/respawn, Focus, enemy combat and all portal modifiers remain available. All new graphics are primitive shapes; explosions show only a short translucent circle.

### Reusable components and scenes

`scenes/environment/` contains barrels, barriers, plates, switches, doors, platforms, crusher, spikes and lethal-area scenes. `scripts/environment/interaction_lab.gd` only lays out and wires the example room. Reuse these scenes in other rooms; none of their scripts names a particular door, switch or enemy.

- `Carryable` adds a rigid body to the `carryable` group. `ObjectInteraction` on the player accepts bodies in that group with a centered `CollisionShape2D` and mass in the exported range (0.1–8 by default). Frozen bodies are ineligible. The hold uses a damped spring with capped acceleration and gravity compensation; a shape sweep clips the target to available space, and normal rigid-body collision/CCD remains active. No per-frame position or velocity teleport is used. The held body temporarily ignores the carrier; collision is restored after release once their shapes separate. Re-grabbing cancels pending restoration. Transit by either participant and player death release the spring. Cross-portal carrying is deliberately not simulated.
- Throwing adds a mass-scaled impulse in the aim direction, preserving existing momentum. Carry distance, reach, spring/damping, acceleration limit and throw speed are exported. Input-stage handling consumes E and carried left-click before portal placement's unhandled-input stage. All bindings are editable in Input Map. A switch is selected ahead of a crate only if it is nearer.
- `Explosive` listens to the existing Health depletion signal (barrels have 20 health), then queues a single guarded detonation. Radius, force, damage and collision mask are exported. Damage and impulse fall off linearly with center distance. Force applies independently of health/invulnerability; damage uses the shared contract without a duplicate impulse. Chain reactions use deferred calls, never recursive damage stacks. The separate feedback component owns the brief circle.
- `Destructible` listens to Health depletion, disables its shape at the safe deferred boundary, and removes the obstacle. Barriers are not portal surfaces, preventing dangling endpoints on deleted geometry. No debris is spawned.
- Plates sum rigid-body mass and optionally equivalent character mass, with optional group filtering. They emit `activation_changed(source, active)` only on transitions. Removed and multiple simultaneous bodies are handled by current overlaps. Switches emit the same signal; their projectile/impact activation can be disabled and has a simulation-time cooldown.
- `MechanismDoor.receive_activation` keeps weak per-source states. OR is the default; `require_all` provides AND across registered inputs. Register each source initially with its current state when using AND. Any number of signals can connect to any number of devices. Opening and closing speeds are separate exports. Both directions use swept and overlap checks against the obstruction mask.
- `MovingPlatform` uses `AnimatableBody2D`, physics-tick motion, exported local waypoints, speed, and loop/ping-pong modes. Godot transfers platform motion to characters and rigid objects. **Moving platforms, doors and crushers reject portal placement**, even if mistakenly added to the portal-surface group. Portals remain supported on surrounding stationary surfaces.
- Hazards share the existing Area2D damage script with configurable damage, interval, impulse, collision mask, optional target group and lethal mode. Spikes use timed contact damage; the crusher adds a descending underside condition; the field applies maximum-health damage. All honor the central health invulnerability rules, including lethal areas. Damaging contact rearms after its interval in simulation time.

## Portal effects

Each endpoint independently owns an **exit effect**: configuring B changes travel from A to B; configuring A changes travel from B to A. Effect changes preserve existing placements. Configuration text remains visible with F3 debugging disabled. All new controls are editable in Project Settings → Input Map and operate immediately during Focus.

- **Standard** is the default (no effect Resource). Existing coordinate transforms and speed preservation remain unchanged.
- **Accelerator** multiplies transformed velocity by 1.5, capped at 2400 units/second by default. `AcceleratorEffect` exports both values. Its cap scales with sandbox world units. The cap can reduce an already-faster entrant; this is an explicit stability limit, not controller braking.
- **Rotator** rotates transformed velocity by a signed angle while preserving speed. Wheel up is +15° (clockwise in Godot's y-down world); wheel down is −15°. Angles wrap at ±180°. It rotates the actual standard exit vector, not just the surface normal.

Angles that produce inward or tangent exit velocity are **rejected**: the entrance stays solid rather than reflecting or silently clamping the requested angle. Direction validation also handles resting entrants. An effect change that invalidates an in-progress entry recovers that body to the entrance's safe side. A geometrically valid green placement preview does not guarantee a particular velocity/rotation can traverse it.

The right-hand laboratory contains a long runway, high ceiling for vertical launches, a tilted platform, a crate, a target, and a projectile emitter. Configure B as Accelerator, place A under a falling crate and B on a wall facing a target, then compare standard and accelerated impacts. The original combat room remains available.

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

To add an effect, derive a Resource from `PortalEffect`, override `modify(result)`, and assign it to an endpoint's `effect`. The result contains `position`, `velocity`, and `motion` (the unspent displacement already transformed into exit coordinates). Apply the same speed/direction changes to velocity and motion. Implement this as a pure transform: clearance prediction may call it repeatedly, including a unit-vector probe for resting bodies; never mutate entities or retain traversal state in the Resource. Only the central resolver commits a traversal and emits its signal. The exit position is checked after modification and the modified remainder is swept against solid geometry. Ordinary portals have no effect Resource; additional effects need no new body-specific teleport code.

## Automated verification

From the repository root:

```sh
godot --headless --editor --import --quit
godot --headless --script tests/run.gd
godot --headless --script tests/combat.gd
godot --headless --script tests/effects.gd
godot --headless --script tests/environment.gd
godot --headless --script tests/playthrough.gd
godot --headless --quit-after 360
```

v0.6 verification uses Godot 4.6.3 on Linux. **196 checks pass across five suites**: 67 foundation, 22 combat, 29 portal effects, 49 environment and 29 room/playthrough checks. The playthrough executes movement, ray-validated portal placement, physical carrying/releasing, projectiles, actual exit overlaps, death and restart. It does not teleport the player across rooms, force puzzle flags or kill enemies directly to complete the route. Separate reset checks deliberately damage entities before verifying fresh room state.

The headless playthrough sets a 1280×720 window so simulated mouse events match the camera's coordinate transform. It verifies both Room 1 routes, repeats the crate puzzle after restart, fights the arena, reaches completion, checks Focus/camera/control persistence, and verifies arena restoration after death and manual restart. Editor import and main-scene launch are also checked. These are automated results; desktop visual usability and Windows export remain unverified.

The test runner exits nonzero on assertion failures. It exercises actual Godot physics bodies, not just formulas: movement, floor/ceiling collisions, jump buffering/coyote time, external momentum, crate pushing, oriented velocity transforms, player/crate/projectile transit, projectile damage and knockback after transit, blocked exits, invalid placement, back-face collision, aperture recovery, rotated surfaces, repeated chaining, Focus input/transit, world scale, and scene reset.

In restricted cloud shells, use writable XDG locations outside the checkout, e.g. `XDG_DATA_HOME=/workspace/.runtime/data XDG_CONFIG_HOME=/workspace/.runtime/config XDG_CACHE_HOME=/workspace/.runtime/cache` before Godot. The editor's remote-debug socket can be denied by the shell sandbox; game/headless tests do not require that socket. Use the existing checkout; cloud tasks are already isolated and need no worktree.

See [manual validation](tests/MANUAL.md) for keyboard/mouse and visual acceptance checks that remain to be performed on a desktop.

## Known limits

- Explosion queries consider at most 128 overlapping physics shapes per blast and do not model wall occlusion. Dense piles, very heavy objects and extreme-speed compression need further stress testing.
- Door obstruction is conservative: a body on top or touching its sweep can prevent opening as well as closing. Released cargo may temporarily ignore the player until they separate; it continues colliding with world geometry.
- Desktop visual/input feel and Windows export have not been manually validated in this headless environment. Automated input and physics checks do not substitute for those checks.
- Portal surfaces must be stationary rectangles with a centered `CollisionShape2D`; travellers currently support centered circles and upright rectangles. Moving portals, compound/polygon shapes, spinning crates, and scaled body transforms are outside the current scope.
- Transit is atomic when the center crosses; there is no split-body rendering or view through a portal. A partially inserted shape can visually overlap its supporting surface briefly.
- Placement conservatively rejects nearby endpoints by center distance, including some nonoverlapping corner configurations. Occupied endpoints must clear before replacement.
- One crossing is resolved per body update; high-speed projectiles use CCD and exit motion is swept, but arbitrary extreme speeds and multiple portals crossed within one physics tick are not guaranteed.
- The stationary test target still remains after depletion; enemies disappear on death. Crates remain physical objects after their health is depleted.
- Enemy navigation is intentionally limited: horizontal pursuit, range checks, and attack line-of-sight. Enemies do not plan jumps, find paths around walls, or understand portals. Progression, additional weapons, and advanced movement remain absent.
