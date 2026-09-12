# Location builder contract

Each location file is a Lune-only module, not a Roblox runtime script. It exports
`function(): { WorldKit.Part }`, imports `../WorldKit` and `../../src/shared/Config`
using relative string requires, and returns a flat list of part specifications.
Build kit: `local kit = WorldKit.new(zoneId, Config.Zones[zoneId].origin)`.
Exterior kit: `WorldKit.new("street", { exteriorX, 0, 0 })`.
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

All exterior entrance portals face +Z. House exterior entrance plane: z=16,
center X: pineapple 0, moai -55, rock -110. Restaurant entrance plane z=10,
center X: krusty 90, chum 175. Clear corridor x +/-7 from z=10 to z=35 (houses),
z=4 to z=28 (restaurants). Build exterior shell from pieces rather than placing
a solid sphere/cylinder in this passage. Curved decorative shells can be
noncollidable provided they do not VISUALLY fill the open doorway.

Modules and assigned zones:

- Pineapple.luau: exterior 0; sponge, spongeLibrary, spongeBedroom.
- Moai.luau: exterior -55; squid, squidLibrary, squidStudio.
- Rock.luau: exterior -110; patrick.
- Krusty.luau: exterior 90; krusty.
- Chum.luau: exterior 175; chum.

Part fields returned by WorldKit can be changed: `rotation` = XYZ degrees,
`material` a Roblox material name, `collide`, `transparency`, `light` (point-light
range), `label` (billboard text), `secret` (stable unique discovery ID), `supply`.
Allowed shapes Block, Ball, Cylinder, Wedge. Cylinder's long axis is X before
rotation. Kit cylinder default rotation {0,0,90} makes it vertical: size
{height, diameter, diameter}. Labels are billboard text; prefer physical modeled
signs with sparse billboard labels. No asset IDs, external textures, scripts,
network calls or random values. Deterministic colored geometry and materials.
Keep per-module part count below 1800. Use 3–5 secret props and one supply chest
per location, with unique IDs prefixed by location name.

Design targets: detailed cartoon underwater architecture, rounded furniture,
layered trims, rivets, real modeled paintings/signage/motifs rather than identical
rectangles, distinct lighting and materials. Walkable spacious connected rooms.
Model recurring details from web/src/research.ts, whose floor plans explicitly
remain playable composites rather than a universal canonical layout.
