# Conch Street: Trouble in Bikini Bottom

A browser-based first-person fan game with procedurally modeled SpongeBob,
Squidward and Patrick homes, and a five-wave hostile-fish survival mode.
This app is independent of the original Rojo/Roblox Stage 1 in `../src`.

## Run

Requires Node 24 and npm.

```sh
cd web
npm ci
npm run dev
```

Open the Vite address printed in the terminal (port 3000). No backend, account,
API key, or downloaded game assets are required. Fonts are local, so the game
also works offline in the [standalone desktop package](DESKTOP.md).

```sh
npm run typecheck
npm run lint
npm test
npm run build
npm run preview
```

The production build is in `dist/` and works on a static host. The repository
does not currently configure git hooks.

## Play

- **Survival:** defeat all five waves. Your pistol takes two shots per normal
  fish, three on later waves. SpongeBob fires bubbles and Patrick throws rocks;
  companions are invulnerable helpers and can be disabled before starting.
- **Explore:** walk through the neighborhood and all modeled rooms without
  enemy waves or damage.
- Choose Reef Explorer, SpongeBob, Patrick or Squidward before starting.
  The first-person hands match the selection; helpers exclude your character.
- **WASD / arrows** move; **Shift** sprints; **mouse** looks; **click** fires.
- Walk through open doorways and staircase passages to travel automatically.
- **E** collects supplies and discovers Easter eggs.
- **R** reloads. Supply crates restore up to 35 health and grant 36 rounds,
  with a separate 30-second cooldown per location. Cleared waves grant health
  and ammo too.
- **B** rebuilds a breached door when standing near a ground-floor entrance.
  The door shuts on initial entry, buys time, and can be broken by fish.
  Rebuilding does not remove fish that already got inside.
- **Esc / P** pauses. Opening the field guide, losing window focus or hiding
  the tab pauses simulation. Music volume, look sensitivity and graphics
  quality are available in the pause menu. Automatic graphics uses economy
  resolution and disables shadows on detected software renderers.
- Touch devices have a movement joystick, drag-to-look and action buttons.
  When browser pointer capture is unavailable, drag-to-look also works with
  a mouse.

Enemy and companion navigation uses obstacle-aware routes. Enemies pursue
through home/floor transitions, so upstairs is temporary refuge. Doorways show
a live view of the next space and map movement and facing direction across
their thresholds. Interiors are deliberately bigger than their external shells.

## Reconstruction and sources

**This is not an exact, all-episodes reconstruction.** Research consulted
fan-maintained house descriptions, episode stills, their episode references,
and the *Boating School* transcript. It did not involve watching every episode.
Sources disagree about floor numbering, room placement and even room counts.
The in-game **Field guide** links the sources, lists episode references, and
explains modeled rooms, omitted rooms and invented connections.

Key sources:

- [SpongeBob's house, Encyclopedia SpongeBobia](https://spongebob.fandom.com/wiki/SpongeBob_SquarePants%27_house)
- [SpongeBob's house, SpongePedia](http://en.spongepedia.org/index.php?title=Spongebob%E2%80%99s_House)
- [Squidward's house, Encyclopedia SpongeBobia](https://spongebob.fandom.com/wiki/Squidward_Tentacles%27_house)
- [Squidward's house, SpongeBob Wiki](https://spongebobwiki.org/wiki/Squidward%27s_house)
- [Patrick's house, Encyclopedia SpongeBobia](https://spongebob.fandom.com/wiki/Patrick_Star%27s_house)
- [Patrick's house, SpongePedia](http://en.spongepedia.org/index.php?title=Patrick%E2%80%99s_House)
- [Boating School transcript](https://spongebob.fandom.com/wiki/Boating_School/transcript)

### Files

- `src/models.ts`: reusable procedural architecture, furniture, characters.
- `src/world.ts`: eight locations, room connections, collision and supplies.
- `src/rules.ts`: simulation rules, collision and navigation.
- `src/game.ts`: renderer, input, combat, companions and home pursuit.
- `src/main.ts` / `src/style.css`: menu, HUD, map, touch controls and dialogs.
- `src/research.ts`: source links and reconstruction notes used by the guide.
- `src/interiors.ts` / `src/decor.ts` / `src/artwork.ts`: furnished rooms and original art.
- `src/portals.ts`: live doorway cameras and movement transforms.
- `src/characters.ts`: selectable avatars and first-person rigs.
- `src/music.ts`: original adaptive Web Audio score.

## Scope

Single-player, in-memory progress; reloading the page resets the run. No
multiplayer or save system. Not all rooms ever seen in the show are included.
Some large set pieces are simplified. Fish vanish into bubbles rather than
using gore. All geometry, artwork, music and sound effects are generated in code.

An unofficial fan-made project. SpongeBob SquarePants and related characters
belong to their respective owners. No episode video, music or voice clips are
bundled.
