# Conch Street Survival — Roblox Studio edition

Cooperative fish survival across Conch Street, three houses, the Krusty Krab and the Chum Bucket. Walk through a small exterior doorway to arrive in a much larger furnished interior. Everything is in one Roblox place; friends remain on the same server.

**This is the revised exterior build. Source checks and place serialization pass on Linux. Roblox Studio rendering, character loading, navigation, camera controls, multiplayer behavior and audio playback still need the Windows playtest below.**

## Open the download on Windows

1. Install [Roblox Studio](https://create.roblox.com/).
2. Extract the supplied ZIP. Open `ConchStreetSurvival.rbxl` in Roblox Studio.
3. Choose **Test / Play (F5)**, not **Run (F8)**. The game needs a client and a player.
4. Select your character. Walk around peacefully, or press **V** for a 20-second survival preparation countdown. The shop also has a **SURVIVAL** button.
5. Use **GEAR** or **B** to unlock the mouse and open the shop. The **FIELD GUIDE** explains the landmarks.

The place contains all scripts and editable modeled parts. No Rojo plugin, terminal, paid asset, HTTP access or API-service permission is needed to open it.

### Revised Conch Street

Open the replacement place in a new Studio tab rather than importing it into the old place. The street now has evenly spaced residential lots, a narrower teal road, separate paths, and the restaurants facing each other farther along the road. Patrick's low rock and weather vane sit beside a tall blue Moai with a heavy brow, porthole eyes, tapered nose, ears and arched wooden entrance. House heights are approximately 19 studs including Patrick's vane, 41 studs for the Moai, and 38 studs for the pineapple and leaves.

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

- Twenty unique discoveries give **80 coins each**, once per player per server session.
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

## Set up the music

The download includes three original synthesized WAV loops: `assets/Explore.wav`, `assets/Combat.wav`, and `assets/Danger.wav`. They contain no show recordings. **The place is silent until you import audio and configure its asset IDs.** Roblox requires hosted, permitted audio assets; an ordinary local WAV cannot play directly from a distributed place.

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

4. Playtest: exploration crossfades into combat, then danger when a survival player's health is below 30. **MUSIC ON/OFF** mutes locally.

Authorized SpongeBob audio IDs can replace these tracks. The included WAVs are original alternatives. [Audio import and permissions documentation](https://create.roblox.com/docs/audio/assets).

## Multiplayer test before publishing

Use Studio's **Server & Clients** mode with **two clients**. Keep the Output window open for both server and client errors.

1. Select different avatars. Confirm both load, look around in first person, and can see one another.
2. Enter and leave all five landmarks without pressing E. One player should remain outside while the other enters. Check both directions of the pineapple library/bedroom and Moai library/studio doorways.
3. Each player finds the same discovery: each gets 80 coins once. Repeating the prompt must award nothing. Verify supplies heal and respect their cooldown.
4. Buy weapons; check coin deduction, repeat-purchase prevention, reload timing, empty magazines and firing against furniture.
5. Hire each helper across the two players. Observe bubbles, rocks, close-range karate, and fish slowing in Gary's lingering slime. Confirm the fourth helper cannot be hired.
6. Both choose survival. Verify a shared wave number/enemy count, fish pursuing through doorways, barricades expiring, individual health, cooperative rewards and five-wave victory.
7. Let one player die and respawn. Then let the entire crew fall; verify defeat and restart. Disconnect a player and confirm their helpers disappear.
8. Run one client in Explore mode while the other fights. Verify peaceful players are not attacked. Check that a late arrival can join survival.
9. Repeat at normal screen size and a smaller window, then try touch/gamepad emulation. Verify mouse release and re-capture around the shop.
10. After importing audio, verify all three tracks and mute. Check frame rate in the densely furnished rooms and during a 40-fish raid before raising the player limit.

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

The deterministic location builders produce 8,172 modeled parts over 10 zones, with 18 reciprocal doorways. Interiors sit hundreds of studs from the street; the server changes the character's position and orientation while the client fades the transition. Fish route across the same portal graph and use Roblox pathfinding plus obstacle casts within each zone.

These are source-informed composite interiors, **not one canonical floor plan**. SpongeBob's architecture varies across episodes. The references were episode guides and still galleries, not an exhaustive viewing of every episode:

- [SpongeBob's house](https://spongebob.fandom.com/wiki/SpongeBob_SquarePants%27_house): recurring living room, nautical kitchen, library, bedroom and bathroom motifs.
- [Squidward's house](https://spongebob.fandom.com/wiki/Squidward_Tentacles%27_house): gold-bamboo library, shell lamps and portrait studio.
- [Patrick's house](https://spongebob.fandom.com/wiki/Patrick_Star%27s_house): lifted rock and sand furnishings.
- [Conch Street](https://spongebob.fandom.com/wiki/Conch_Street): Patrick, Squidward and SpongeBob's relative exterior silhouettes, lot spacing and frontage. Street distances are a playable approximation; the series does not establish a consistent measured town plan.
- [Krusty Krab](https://spongebob.fandom.com/wiki/Krusty_Krab): lobster-trap exterior, cashier boat, barrel seats, grill and office.
- [Chum Bucket](https://spongebob.fandom.com/wiki/Chum_Bucket): bucket/glove exterior, cafeteria and Karen's laboratory.
- The existing browser game's `web/src/research.ts` contains the more detailed episode and artwork notes; each location builder records its recurring motifs.

Modeled artwork and props are original geometric interpretations. Door placement and connections prioritize traversability. None of the offline checks establish Roblox's rendered quality or gameplay performance; use the Studio test above.
