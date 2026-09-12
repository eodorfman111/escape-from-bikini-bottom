# Location builder contract

Each location file is a Lune-only module, not a Roblox runtime script. It exports
`function(): { WorldKit.Part }`, imports `../WorldKit` and `../../src/shared/Config`
using relative string requires, and returns a flat list of part specifications.
Build kit: `local kit = WorldKit.new(zoneId, Config.Zones[zoneId].origin)`.
Exterior kit: `WorldKit.new("street", { 0, 0, 0 })`.
`World.luau` applies the matching `Config.Exteriors` origin, scale and yaw to
street parts only. The portal pairs apply the same transform.
Combine kits with `table.insert(result, part)` over each kit's `parts`.

Units are studs. A human rig is around 5–6 studs tall. Interior width/depth are
96×88 (restaurants 116×100), much larger than the exteriors. Floor surface y=0.
Use `kit:room(width, depth, height, wallRGB, floorRGB, hasRightSideDoor)` to create
walkable walls with a 12-stud-wide, 17-stud-tall front opening at local z=depth/2.
The positive-X side opening is only for rooms with an outgoing stairs portal:
sponge, spongeLibrary, squid, squidLibrary. All other rooms have no side door.
Leave a clear approach at least 14 studs wide for every opening. Never block it
with steps, rugs thicker than 0.25 studs, glass, doorway fills or furniture.
All floors are level; portal visuals can imply stairs/elevators without obstructing
the actual path. Internal kitchen/bathroom partitions must have large openings.

Exterior entrances face local +Z, centered at local X=0. House exterior
entrance plane: local z=16; restaurant entrance plane: local z=10.
The Chum Bucket rotates 180 degrees to face the Krusty Krab across the road.
Clear corridor x +/-7 from z=10 to z=35 (houses),
z=4 to z=28 (restaurants). Build exterior shell from pieces rather than placing
a solid sphere/cylinder in this passage. Curved decorative shells can be
noncollidable provided they do not VISUALLY fill the open doorway.

Modules and assigned zones:

- Pineapple.luau: exterior key `pineapple`; sponge, spongeLibrary, spongeBedroom.
- Moai.luau: exterior key `moai`; squid, squidLibrary, squidStudio.
- Rock.luau: exterior key `rock`; patrick.
- Krusty.luau: exterior key `krab`; krusty.
- Chum.luau: exterior key `bucket`; chum.

Part fields returned by WorldKit can be changed: `rotation` = XYZ degrees,
`material` a Roblox material name, `collide`, `transparency`, `light` (point-light
range), `label` (billboard text), `secret` (stable unique discovery ID), `supply`,
`group` (editable Model), `castShadow` (defaults to true).
Allowed shapes Block, Ball, Cylinder, Wedge. Cylinder's long axis is X before
rotation. Kit cylinder default rotation {0,0,90} makes it vertical: size
{height, diameter, diameter}. Ball specs become block-backed SpecialMesh spheres
so each axis follows the requested dimensions. `triangle` and `quad` create
wedge surfaces; use these for controlled shell profiles. The `PatrickLid`
group is noncollidable and animated around `Config.RockHinge` by the client.
Labels are billboard text; prefer physical modeled
signs with sparse billboard labels. No asset IDs, external textures, scripts,
network calls or random values. Deterministic colored geometry and materials.
Keep geometry economical and check total part count after rebuilding. Use 3–5 secret props and one supply chest
per location, with unique IDs prefixed by location name.

Design targets: detailed cartoon underwater architecture, rounded furniture,
layered trims, rivets, real modeled paintings/signage/motifs rather than identical
rectangles, distinct lighting and materials. Walkable spacious connected rooms.
Model recurring details from web/src/research.ts, whose floor plans explicitly
remain playable composites rather than a universal canonical layout.
