# Conch Street desktop app

The desktop app bundles Electron, the game, and its local assets. Players do not
need Node, npm, a web server, or an internet connection to play. Field guide
websites still need internet access when opened in the player's browser.

## Development

Use Node 24 and npm, from `web/`:

```sh
npm ci
npm run typecheck
npm run lint
npm test
npm run desktop:start
```

`desktop:start` builds the game in desktop mode and opens the local `dist/index.html`.
`desktop:dev` is an alias for the same workflow. Neither uses a development server
or hot reload; rerun after edits. Electron 44 downloads its development executable
on first use, so the first launch or package build needs network access.

`npm run desktop:build` builds without opening a window. `npm run desktop:test`
runs the desktop security policy and input-handler unit tests in the shell.
`npm test` includes those tests alongside the game tests.

## Package for players

Each command builds the game first:

| Command | Target | Output inside `release/` |
| --- | --- | --- |
| `npm run desktop:package` | Supported host OS/architecture | Corresponding folder below |
| `npm run desktop:package:win` | Windows x64 | `ConchStreet-win32-x64/` |
| `npm run desktop:package:mac-arm64` | macOS Apple silicon | `ConchStreet-darwin-arm64/` |
| `npm run desktop:package:mac-x64` | macOS Intel | `ConchStreet-darwin-x64/` |
| `npm run desktop:package:linux` | Linux x64 | `ConchStreet-linux-x64/` |

Build on the target OS for release validation, especially for signing and
notarization. These produce portable application folders, not installers.
Packaging replaces the previous generated folder for that target.

- **Windows:** distribute the entire output folder, usually as a ZIP. After
  extraction, run `conch-street.exe`. Do not distribute the executable alone.
  The package includes `START-HERE.txt` with extraction and gameplay instructions.
  If the executable opens nothing, run `Start Conch Street.cmd`. It checks core
  runtime files, waits for the game to exit and reports its exit code. Diagnostic
  logs go to `%LOCALAPPDATA%\ConchStreet\logs` (or a `logs/` folder beside the
  launcher if `LOCALAPPDATA` is unavailable). Launcher output, main-process
  console output and Chromium diagnostics have separate files. The launcher
  clears `ELECTRON_RUN_AS_NODE` and keeps sandbox/security settings enabled.
  Windows version metadata uses the descriptive publisher label
  `Conch Street fan project`; it is not a code-signing identity.
- **macOS:** distribute `ConchStreet.app` from the output folder. Package/sign on
  macOS, and use a macOS-aware archive tool to preserve the app bundle:
  `ditto -c -k --sequesterRsrc --keepParent release/ConchStreet-darwin-arm64/ConchStreet.app ConchStreet-mac-arm64.zip`.
  Replace `arm64` with `x64` for Intel.
- **Linux:** distribute the entire output folder, preserving executable bits,
  e.g. `tar -C release -czf release/ConchStreet-linux-x64.tar.gz ConchStreet-linux-x64`.
  Extract it and run `./conch-street` inside the folder.

Only the built `dist/`, three desktop runtime modules, and a minimal package
manifest enter `resources/app.asar` (inside `Contents/Resources` on macOS).
Source files, tests, development dependencies, Roblox code, and repository
metadata are excluded. Electron supplies the executable runtime and its required
resources/licenses. Keep those together in the distributed application.

`release/` and `.desktop-build/` are ignored by Git.

## Security and offline assets

- Main process only: no preload, IPC API, or privileged renderer bridge.
- Renderer sandbox and context isolation enabled; Node integration disabled,
  including workers and subframes. Web security stays enabled.
- An isolated, in-memory session rejects network requests and files outside
  `dist/`, downloads, webviews, renderer navigation, and new windows.
- Permission checks and requests allow only pointer lock and fullscreen from
  this game's local main frame. Device permissions and all other permissions
  are denied.
- External links open only for native left/middle mouse clicks on matching
  anchors or Enter on a focused anchor. The main process reads the target from
  the DOM in an isolated JavaScript world, rechecks the local document/focus,
  and allows only HTTP(S) URLs without embedded credentials. Renderer
  `window.open`, synthetic DOM clicks, and navigation never launch a browser.
  No timer-based "recent user gesture" fallback is used.
- Page zoom is fixed at 100% to keep native mouse coordinates aligned with
  anchor hit testing. Visual zoom limits are configured after loading the page,
  once the renderer can respond to IPC. The window is visible during loading;
  startup failures and renderer crashes produce an error dialog and exit code 1.
  The Game menu offers fullscreen and quit.
- Desktop builds inject a Content Security Policy that restricts resources to
  local assets and disallows frames, forms, objects, and remote scripts.
  Inline styles remain enabled for the game's generated markup.

Vite uses `base: './'` and does not inline assets. Import assets through Vite,
use `new URL(..., import.meta.url)`, or use `import.meta.env.BASE_URL` for files
in `public/`. Avoid runtime root-relative paths such as `/music/theme.ogg`,
which resolve to the filesystem root under `file:`.

The game uses system fonts and locally generated art/music. For identical
typography on all platforms, add appropriately licensed local fonts and update
the game CSS. Future art/music must also be bundled locally. Desktop mode writes
to the same `dist/` as the website; run `npm run build` again before publishing
a normal web build.

## Release gaps

The scripts do not configure a Windows signing certificate, Apple Developer ID,
notarization, auto-update, custom native app icons, or installer generation.
The app ID is `io.github.eodorfman111.conchstreet`. Unsigned builds can trigger OS
trust warnings or be blocked by policy; a distributable release needs the target
OS chosen, appropriate signing, and execution testing on that OS.

Linux requires a graphical session, supported GPU drivers and Electron's system
libraries. Chromium sandbox support must be available through the distribution's
user-namespace/setuid-sandbox configuration. Do not work around launch failures
with `--no-sandbox` or disabled web security.

Shell-based type/lint/unit/build checks and Linux x64 and Windows x64 packaging
have passed. The Windows archive includes the executable, runtime resources,
game bundle and player instructions. No Electron GUI was launched.
macOS packaging, native OS execution, mouse/keyboard link behavior in Electron,
pointer lock, fullscreen, WebGL/audio playback, and signing remain release
validation tasks.

## Dependency release evidence

Direct dependencies are pinned and were independently checked against npm:

- `electron@44.2.0`: published **2026-09-04 03:15:23 UTC**;
  <https://registry.npmjs.org/electron>
- `@electron/packager@20.3.0`: published **2026-08-11 20:24:53 UTC**;
  <https://registry.npmjs.org/@electron%2fpackager>

Both are at least seven days old as of 2026-09-11 16:11 UTC.
The exact dependency tree and integrity hashes are in `package-lock.json`.

API references:

- <https://www.electronjs.org/docs/latest/tutorial/security>
- <https://www.electronjs.org/docs/latest/api/web-contents>
- <https://www.electronjs.org/docs/latest/api/session>
- <https://electron.github.io/packager/main/interfaces/Options.html>
