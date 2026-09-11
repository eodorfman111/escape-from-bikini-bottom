---
name: conch-native-testing
description: Build and smoke-test the Conch Street Electron package without weakening its sandbox or confusing Linux software-rendering limits with Windows behavior.
---

## Build and launch
- From `web/`, source `/home/ubuntu/.nvm/nvm.sh` and run `npm run desktop:package:linux`. Installed project dependencies are required.
- Package commands share `dist/`; coordinate with other agents so Windows and Linux builds do not race.
- Launch `release/ConchStreet-linux-x64/conch-street` as a non-root desktop user. No Vite server is needed for the packaged app.
- Set `ELECTRON_ENABLE_LOGGING=1` and `--enable-logging=stderr`, redirecting output to persistent evidence under `/home/ubuntu`.
- Preserve default-launch evidence first. If WebGL2 is blocklisted on a GPU-less host, a separate test-only invocation can use `--use-angle=swiftshader --enable-unsafe-swiftshader`. Explicitly report this software-rendering adjustment; do not change shipped defaults or use `--no-sandbox`/`--disable-web-security`.

## Native smoke flow
- Maximize with `wmctrl`, record the native window, click Just explore, wait for interiors to prepare, then click Explore the neighborhood.
- Verify first-person hands, 100 health, infinity ammo, actual W movement and relative mouse-look. P opens pause; Back to it resumes.
- For read-only diagnostics, use `--inspect=127.0.0.1:9229`; main-process inspector evaluation can access Electron via `process.mainModule.require('electron')`. Read BrowserWindow visibility, URL, renderer PID and `getLastWebPreferences()`. Query `document.pointerLockElement` through webContents to confirm native capture.
- Close inspector-enabled processes after testing. An invisible window with empty URL and renderer PID0 is a pre-navigation startup symptom, not evidence of a renderer CSP failure.
- Linux execution cannot certify a Windows EXE or its CMD diagnostic launcher.

## Devin Secrets Needed
None. The packaged game is offline and anonymous.
