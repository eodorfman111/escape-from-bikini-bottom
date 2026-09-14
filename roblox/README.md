# Conch Street Survival — Roblox Studio edition

Cooperative fish survival across Bikini Bottom, three houses, the Krusty Krab, Chum Bucket, Mrs. Puff's Boating School and Jellyfish Fields. Walk through an opaque exterior doorway to arrive in a larger furnished interior. Everything is in one Roblox place; friends remain on the same server.

**This is the expanded neighborhood build. Source checks and place serialization pass on Linux. Roblox Studio rendering, character loading, runtime navigation, transition timing, camera controls, multiplayer behavior and audio playback still need the Windows playtest below.**

## Open the download on Windows

1. Install [Roblox Studio](https://create.roblox.com/).
2. Extract the supplied ZIP. Open `ConchStreetSurvival.rbxl` in Roblox Studio.
3. Choose **Test / Play (F5)**, not **Run (F8)**. The game needs a client and a player.
4. Select your character. Walk around peacefully, or press **V** for a 20-second survival preparation countdown. The shop also has a **SURVIVAL** button.
5. Use **GEAR** or **B** to unlock the mouse and open the shop. The **FIELD GUIDE** explains the landmarks.

The place contains all scripts and editable modeled parts. No Rojo plugin, terminal, paid asset, HTTP access or API-service permission is needed to open it.

### Expanded Bikini Bottom

Open the replacement place in a new Studio tab rather than importing it into the old place. The playable district spans 900 × 540 studs, and the three home centers are now 80 studs apart. Patrick's low rock and weather vane sit beside a tall blue Moai with a heavy brow, porthole eyes, tapered nose, ears and arched wooden entrance. House heights are approximately 19 studs including Patrick's vane, 41 studs for the Moai, and 38 studs for the pineapple and leaves.

- SpongeBob's living room, kitchen, library, bedroom and bathroom share one remote interior. Enclosed, level hallways connect the rooms; there are no internal pineapple teleports.
- Exterior doors have opaque faces. A full-screen transition covers the client before the server relocates the player. A four-second timeout releases the player outside the door if the client does not acknowledge the cover.
- The Krusty Krab has wider dining aisles, a cashier boat, serving hatch, grill, office, connected restrooms, walk-in freezer, dry storage and a rear service doorway leading to the dumpster courtyard.
- Walk east along the road to Mrs. Puff's yellow school, lighthouse, furnished classroom, Good Noodle Board, Roger display and practice course with cones, ramps, bleachers and parked training boats.
- The parked Patty Wagon sits beside the pineapple. Follow the southern footpath to Jellyfish Fields for another discovery and supplies. Vehicles are editable scenery in this revision, not drivable.
- Floating world labels are removed. HUD, field-guide text and interaction prompts remain.

Patrick's rock opens automatically when a player approaches and closes after everyone leaves. Walk toward the exposed pit to enter the larger interior. The lid is cosmetic; the server still controls the doorway transition. In a two-client Studio test, check that both clients see it open when either player approaches.

`Config.Exteriors` controls each landmark's position, scale and facing. The world builder and portal configuration share these transforms; changing street scale does not shrink the remote interiors. Editable exterior models are grouped under `Workspace → ConchWorld → street`. Curved props use explicitly scaled sphere meshes, while the Moai and rock silhouettes use wedge surfaces.

## Controls and objectives

| Action | Keyboard/mouse | Gamepad |
| --- | --- | --- |
| Move / look / jump | WASD / mouse / Space | Roblox movement controls |
| Fire | Hold left mouse | RT |
| Reload | R | X |
| Shop / release mouse | B | Y |
| Toggle survival / exploration | V or shop button | Shop button |
| Field guide | G or shop button | Shop button |
| Equip weapon | 1, 2, 3 or shop | Shop |
| Supplies, discoveries, barricades | E at prompt | Roblox prompt |
| Enter or exit a house | Walk through its doorway | Walk through |

Touch fire/reload buttons and Roblox movement controls are included, but touch and gamepad usability are untested.

- Twenty-six unique discoveries give **80 coins each**, once per player per server session.
- Start with **100 coins**. Fish defeats give **12 coins** to the player or helper owner responsible. Living survival participants earn **60 coins** for a completed wave.
- Five shared waves scale with living participants, capped at 40 fish. Every player explicitly opts into survival. Explorers are ignored by fish.
- A defeated player respawns after five seconds. If all survival participants are down, the raid ends. Press **SURVIVAL** to start again.
- Supply boxes restore health and all magazines, with a per-player 30-second cooldown.
- Barricades cost 40 coins and delay fish at either side of the doorway for 15 seconds. Players and their helpers can still pass.
- Coins, purchases and discoveries are **session-only**, with no persistent DataStore or Robux purchases.

| Gear | Price | Role |
| --- | ---: | --- |
| Bubble Blaster | Free | 14-shot magazine; quick bubbles briefly slow a fish |
| Spatula Launcher | 220 | Heavy damage and small splash |
| Jellyfish Zapper | 380 | Wider area damage and slowing |
| SpongeBob helper | 100 | Ranged bubble fire |
| Patrick helper | 180 | Rocks with splash damage |
| Sandy helper | 300 | Close-range karate area attack and push |
| Gary helper | 160 | Lingering slime patches slow and damage fish |

Hire up to three helpers. Dismissing a helper gives no refund; hiring again costs coins. Selected avatars are cosmetic and have the same stats.

## Music and optional replacements

The place ships with hosted Roblox Creator Store tracks by APMOfficial and a default volume of 0.3:

| State | Track | Asset ID |
| --- | --- | --- |
| Exploration | Marching To Honolulu | 1845891274 |
| Combat | Tropical Jazz OL | 1839199215 |
| Low health | Intense Chase | 1848090337 |

These are tropical/action music, not recordings from SpongeBob. Roblox's metadata identified these tracks and APMOfficial as their creator when selected. The client preloads them, loops and crossfades between states, and displays **AUDIO LOAD ERROR** if loading fails. Playback has not been heard in Windows Studio here: verify the Studio volume, **MUSIC ON**, and Output for asset/permission errors if it is silent.

No upload is needed for the configured defaults when Roblox permits them in your experience. For replacements, the download also includes original synthesized `assets/Explore.wav`, `assets/Combat.wav`, and `assets/Danger.wav` loops. Local WAVs must be uploaded and permitted before Roblox can stream them:

1. Publish a private copy of the experience to your Roblox account.
2. Import the WAVs through Studio's Asset Manager or the Creator Dashboard. Wait for moderation and grant the experience permission to use each audio asset when necessary.
3. Open `ReplicatedStorage → Conch → AudioConfig` in Studio and set the three strings:

   ```lua
   return {
       Explore = "rbxassetid://YOUR_EXPLORATION_AUDIO_ID",
       Combat = "rbxassetid://YOUR_COMBAT_AUDIO_ID",
       Danger = "rbxassetid://YOUR_DANGER_AUDIO_ID",
       Volume = 0.3,
   }
   ```

4. Playtest: exploration crossfades into combat, then danger when a survival player's health is below 30. **MUSIC ON/OFF** mutes locally. Repeat this check for the supplied default tracks even if you make no replacements.

Authorized SpongeBob audio IDs can replace these tracks. The included WAVs are original alternatives. [Audio import and permissions documentation](https://create.roblox.com/docs/audio/assets).

## Multiplayer test before publishing

Use Studio's **Server & Clients** mode with **two clients**. Keep the Output window open for both server and client errors.

1. Select different avatars. Confirm both load, look around in first person, and can see one another.
2. Enter and leave all remote interiors without pressing E. One player should remain outside while the other enters. Confirm the screen covers relocation, the player regains movement, and no empty shell is visible through the door. Check the Moai library/studio and Krusty rear-service doorways in both directions.
3. Walk continuously from SpongeBob's living room through the library to the bedroom and bathroom, then return and visit the kitchen. No fade or relocation should occur between these rooms. Bring helpers and pursuing fish through the hallways. Tour the restaurant service rooms, classroom, practice course, Patty Wagon and Jellyfish Fields.
4. Each player finds the same discovery: each gets 80 coins once. Repeating the prompt must award nothing. Verify supplies heal and respect their cooldown.
5. Buy weapons; check coin deduction, repeat-purchase prevention, reload timing, empty magazines and firing against furniture.
6. Hire each helper across the two players. Observe bubbles, rocks, close-range karate, and fish slowing in Gary's lingering slime. Confirm the fourth helper cannot be hired.
7. Both choose survival. Verify a shared wave number/enemy count, fish pursuing through doorways, barricades expiring, individual health, cooperative rewards and five-wave victory.
8. Let one player die and respawn. Confirm their helpers return to the street. Then let the entire crew fall; verify defeat and restart. Disconnect a player and confirm their helpers disappear.
9. Run one client in Explore mode while the other fights. Verify peaceful players are not attacked. Check that a late arrival can join survival.
10. Repeat at normal screen size and a smaller window, then try touch/gamepad emulation. Verify mouse release and re-capture around the shop.
11. Verify all three music states and mute. Check frame rate in the densely furnished rooms and during a 40-fish raid before raising the player limit.

[Official testing modes](https://create.roblox.com/docs/studio/testing-modes).

## Publish the experience

After playtesting:

1. Choose **File → Publish to Roblox**, enter the name, description, creator and supported devices, then create the experience. New experiences are private by default.
2. Share Playtest access with your friends for the multiplayer check.
3. Use the experience's Creator Dashboard publishing controls when ready to release publicly. Follow the current audience and publishing requirements there.
4. Publish again after changing audio configuration or map/gameplay content.

[Official publishing guide](https://create.roblox.com/docs/production/publishing/publish-experiences-and-places). This download has not been published to your Roblox account.

## Rebuild from source

The separate `roblox/` project does not replace the original obby or browser/Electron game.

Install the pinned tools in `aftman.toml` through [Aftman](https://github.com/LPGhatguy/aftman), or put matching releases on PATH:

- Rojo 7.6.1
- Lune 0.10.4
- StyLua 2.3.1
- Selene 0.29.0
- Luau LSP 1.69.0
- Node.js 24 only if regenerating the original music

From the repository's `roblox` directory (inside `source/roblox` in the download):

```sh
aftman install
lune run tools/build.luau
lune run tools/check.luau
node tools/music.mjs
```

`check.luau` downloads the Luau LSP 1.69.0 Roblox declarations on first use and generates local Lune declarations. It runs formatting, lint, Roblox API type analysis, Rojo assembly, economy/combat/portal tests, and geometric/serialization checks. Generated artifacts, type caches and audio files are ignored by Git.

Output:

- `build/ConchStreetSurvival.rbxl`: complete editable place
- `build/World.rbxm`: static modeled world
- `assets/*.wav`: original music loops

For live source syncing, build the world first, then run `rojo serve default.project.json` and connect from Studio's Rojo plugin. Rebuild after changing location geometry. Changes made only in Studio are not automatically written back to these Luau builders.

## Architecture and research

`src/server/Game.server.luau` owns wallets, loadouts, health, firing/raycast results, helpers, fish and shared phases. Remote actions are type checked and rate limited; prices and damage come from the server's Config. Server prompts verify distance and zone. Player avatars use Roblox's normal movement replication; this prototype does not implement a full anti-cheat movement system.

`src/client/Game.client.luau` handles character selection, controls, camera, HUD, shop, field guide, visual effects and local music. `Rules.luau` isolates economy, magazine, portal and wave decisions for offline regression tests.

The deterministic location builders produce roughly 9,500 modeled parts over eight zones, with 16 portal endpoints forming eight reciprocal pairs. Interiors sit hundreds of studs from the street. The server freezes an entering player, waits for the client's covered-screen acknowledgement, relocates the character and releases movement. Fish and helpers use Roblox pathfinding plus obstacle casts within each zone; asynchronous routes are invalidated after portal travel or respawn. The pineapple uses a level connected floor plan so these ground-based actors can follow every room connection.

Offline checks include deterministic dimensions and transforms, serialization, player-width supported routes through the pineapple, restaurant service rooms and classroom, portal clearance, unique rewards, opaque door covers, absence of BillboardGuis, landmark content and nonempty audio IDs. They cannot verify Roblox's asset availability, navigation mesh or rendered appearance.

These are source-informed composite interiors, **not one canonical floor plan**. SpongeBob's architecture varies across episodes. The references were episode guides and still galleries, not an exhaustive viewing of every episode:

- [SpongeBob's house](https://spongebob.fandom.com/wiki/SpongeBob_SquarePants%27_house): recurring living room, nautical kitchen, library, bedroom and bathroom motifs.
- [Squidward's house](https://spongebob.fandom.com/wiki/Squidward_Tentacles%27_house): gold-bamboo library, shell lamps and portrait studio.
- [Patrick's house](https://spongebob.fandom.com/wiki/Patrick_Star%27s_house): lifted rock and sand furnishings.
- [Conch Street](https://spongebob.fandom.com/wiki/Conch_Street): Patrick, Squidward and SpongeBob's relative exterior silhouettes, lot spacing and frontage. Street distances are a playable approximation; the series does not establish a consistent measured town plan.
- [Krusty Krab](https://spongebob.fandom.com/wiki/Krusty_Krab): lobster-trap exterior, five maritime flags, cashier boat, wheel tables, barrel seats, serving hatch and rear service rooms. References including *Krusty Krab Training Video*, *Krabs à la Mode*, *Penny Foolish* and *Truth or Square* show recurring details, but the rear-room arrangement changes.
- [Chum Bucket](https://spongebob.fandom.com/wiki/Chum_Bucket): bucket/glove exterior, cafeteria and Karen's laboratory.
- [Mrs. Puff's Boating School](https://spongebob.fandom.com/wiki/Mrs._Puff%27s_Boating_School): school, lighthouse, classroom and driving course. *Boating School* establishes the course; *New Student Starfish* supplies classroom details, the ten desks, [Good Noodle Board](https://spongebob.fandom.com/wiki/Good_Noodle_Board) and Roger display. Dimensions and aisle placement are adapted for playable clearance.
- [Patty Wagon](https://spongebob.fandom.com/wiki/Patty_Wagon): *The SpongeBob SquarePants Movie* describes the sesame finish, pickle wheels, grilled interior, front lamps and small red flag. The model uses an original anchor emblem rather than printed lettering.
- The existing browser game's `web/src/research.ts` contains the more detailed episode and artwork notes; each location builder records its recurring motifs.

Modeled artwork and props are original geometric interpretations. Door placement and connections prioritize traversability. None of the offline checks establish Roblox's rendered quality or gameplay performance; use the Studio test above.
