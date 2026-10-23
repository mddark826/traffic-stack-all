@echo off
REM Place the official 10KHits exchanger .exe in this folder, then run this file.
REM It simply starts the exchanger; sign in with your 10KHits account inside the app.
for %%F in (*.exe) do (
  echo Starting %%F ...
  start "" "%%F"
  goto :done
)
echo No .exe found in this folder.
echo Download the 10KHits exchanger from your 10KHits account first.
pause
:done
