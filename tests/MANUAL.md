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
