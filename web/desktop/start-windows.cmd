@echo off
setlocal
set "GAME_DIR=%~dp0"
for %%F in ("conch-street.exe" "resources\app.asar" "icudtl.dat" "resources.pak" "v8_context_snapshot.bin" "locales\en-US.pak") do (
  if not exist "%GAME_DIR%%%~F" goto incomplete
)

set "LOG_DIR=%LOCALAPPDATA%\ConchStreet\logs"
if not defined LOCALAPPDATA set "LOG_DIR=%GAME_DIR%logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
echo Starting Conch Street at %DATE% %TIME% > "%LOG_DIR%\launcher.log"
if errorlevel 1 goto log_error

set "ELECTRON_RUN_AS_NODE="
set "ELECTRON_ENABLE_LOGGING=1"
set "ELECTRON_LOG_FILE=%LOG_DIR%\chromium.log"
echo Starting Conch Street. Leave this window open while you play.
echo Diagnostic logs: "%LOG_DIR%"
start "" /wait "%GAME_DIR%conch-street.exe" --enable-logging=file "--log-file=%LOG_DIR%\chromium.log" > "%LOG_DIR%\console.log" 2>&1
set "GAME_EXIT=%ERRORLEVEL%"
echo Exit code: %GAME_EXIT% >> "%LOG_DIR%\launcher.log"
echo.
echo The game has closed. Exit code: %GAME_EXIT%
echo If no game window appeared, share the files in "%LOG_DIR%".
pause
exit /b %GAME_EXIT%

:incomplete
echo Some game files are missing.
echo Right-click the original ZIP, choose Extract All, then open the new folder.
echo Keep this launcher, the EXE, and all other files together.
pause
exit /b 1

:log_error
echo Could not write diagnostic logs to "%LOG_DIR%".
echo Move the extracted game folder to a writable location and try again.
pause
exit /b 1
