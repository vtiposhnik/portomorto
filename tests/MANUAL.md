# Desktop acceptance route

These checks require interactive Godot on a desktop. They are **not marked passed** by headless automation.

1. Open `scenes/sandbox.tscn`, run, and confirm HUD/text/preview are readable at 1280×720 and a resized window. Toggle F3; inspect normals and velocity vectors.
2. Run, reverse, stop, and jump at display caps of 30/60/144 FPS. Compare short/held jumps, walk-off coyote jumps, and jumps pressed just before landing. Test floor, platform underside, and boundary walls.
3. Place A on the ground and B on the right wall. Fall through A; verify a sideways launch. Repeat wall→floor, wall→ceiling, floor→floor, and with the tilted platform.
4. Place floor/ceiling portals vertically aligned. Drop a crate and observe repeated chaining. Walk across aperture edges, attempt replacement while a body is partly inserted, and check for trapping. Move the crate into an exit to check obstruction handling.
5. Aim near platform ends and narrow faces; preview must reject portals that do not fit. Try overlapping endpoints, an unpaired portal, and approaching a surface's back side.
6. Hold Shift while moving, aiming, firing, and replacing both portals. Camera/preview should remain responsive. Release Shift and alt-tab to check immediate time restoration. Reset during Focus and verify no stale portals or slowed time remain.
7. Push the crate and shoot it. Route projectiles between wall portals into the red target. Watch target health fall by 25 per hit, with a white hit flash. Reset restores the target. The automatic emitter is in the far-right range.
8. Repeat at sandbox `world_scale` 0.5 and 1.5 and adjust `camera_zoom`. Confirm dimensions, collisions, jump arcs, and portal apertures remain proportional.

Record engine version, OS, frame cap, reproduction coordinates, portal normals, and observed velocities for any failure. Do not infer success from an open window or idle scene alone.

## v0.3 combat checks (desktop playtest pending)

- Approach each enemy: check pursuit/range, melee cooldown, and aimed ranged shots. Stand behind a wall to confirm attacks cannot originate through it.
- Fire at enemies, push a crate into them gently (no impact damage), then launch a crate with a floor-to-wall portal (impact damage). Knock an enemy into either endpoint and observe AI resume after exit.
- Place portals to intercept a ranged attack and send it back toward its shooter. Enemy shots remain physical and can damage other enemies.
- Drop an enemy onto the hazard or from a large height. Ordinary walking and jumping should not deal impact damage; hard landings should.
- Hold Focus during attacks and portal replacement. Observe player health and the brief invulnerability window, then test death, automatic respawn, and manual reset during combat.
- Check repeated impacts after separation and long continuous contact for duplicate damage. Dense stacks and simultaneous impacts need further desktop stress testing; this iteration does not claim those cases exhaustively verified.

## v0.4 effects checks (desktop playtest pending)

- Configure A and B independently with Q/T and 1/2/3; confirm placement persists and HUD identifies the selected **exit** effect. Rebind one key and the wheel actions in Input Map.
- During Focus, select, switch, rotate in both directions, place/reposition portals, then release Focus. Check live mouse and HUD responsiveness.
- Compare standard and accelerated floor→wall, ceiling→floor, wall→wall and tilted-surface launches. Repeat with player, both enemies, crate and projectile; verify the cap under repeated boosts.
- Send a projectile through a ±15°/30° Rotator into a target. Try an inward/tangent angle: traversal should be blocked, including at rest. Switch to an unsafe angle while an object is partly inserted and check recovery.
- Use the right-hand runway and high ceiling for high-speed launches. Compare crate collision damage before and after acceleration, then redirect enemy fire. Test crowded exits and near-edge approaches; one swept traversal per physics update remains the supported limit.

## v0.5 environment checks (desktop playtest pending)

- Grab, aim, swing, release and re-grab a crate with E. Throw with left click and confirm no A portal is placed by the same click. Check mass limits, wall/ceiling contact, and quick mouse reversals. Right click must still place B. T now selects B for configuration.
- Carry during Focus, throw through accelerator/rotator portals, and cross a portal while carrying (the object is released). Check player collision restoration after a close drop.
- Shoot and strike barrels; observe single detonations, radial forces and bounded chain reactions. Send a barrel through a portal and use explosions to launch crates. Damage barriers with shots, blasts and impacts, then walk through the cleared space.
- Put multiple bodies on a plate, remove them one at a time, destroy one, and teleport one onto it. Use a switch to open both doors. Block a closing door with a crate; remove it and verify closing resumes. Check AND configuration after registering all source states.
- Ride platforms in both path modes and place crates on them. Attempt portal placement on a platform/door/crusher: it must be rejected. Test surrounding stationary portals.
- Test spikes, descending crusher strike/retreat, and the lethal field against player and enemies. Try contact during invulnerability and Focus. Confirm death/reset restores all mechanisms and objects.
- Repeat at world scales 0.5 and 1.5. Pay particular attention to carried-object collision margins, crusher sensors and crowded doorway cases.

## v0.6 three-room route (desktop playtest pending)

Use F5 (`scenes/game.tscn`), not F6 on an individual room scene.

1. Room 1: inspect the gap and ledges. Walk toward the end of the near landing, link the floor beneath you to the far wall, and enter A. Confirm the green exit advances to Room 2. On another run, try the far-floor shortcut near the exit. A normal jump across the gap should fail and restart Room 1.
2. Room 2: E grabs the crate; aim above/right while carrying. Drop it centered over the plate, wait for the door, and jump over the crate. Confirm the plate requires the crate, not the player. Try relocating the crate with portals, then R to restore the puzzle.
3. Room 3: defeat both enemies with F, Focus and/or environmental interactions. Try moving or throwing the crate, detonating the barrel, redirecting shots and using the spikes. The exit must stay locked while either enemy is alive. After clearing the arena, pass the spike strip and enter the exit to see completion.
4. In every room, hold Shift while aiming and configuring portals. Check camera tracking, preview visibility, readable objective/health text and the E/T controls. Resize the window. Verify death and R restore the current room, not Room 1, including objects and portal effects.
5. Rebind a control, transition and restart; the binding should persist. Carry an object when restarting and confirm there is no leftover collision exception or duplicated player/portal system. At completion there should be no active actors or slow time; R starts a fresh Room 1.

Do not mark desktop usability or alternate creative solutions passed based solely on the scripted route. Record any stuck crates, obscured placement targets, unexpected gate states or exit/death timing issues during playtesting.
