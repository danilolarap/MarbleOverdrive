@echo off
setlocal
cd /d "%~dp0"
if not exist "%~dp0logs" mkdir "%~dp0logs"
set "gameGodot="
if defined GODOT_BIN if exist "%GODOT_BIN%" set "gameGodot=%GODOT_BIN%"
if not defined gameGodot if exist "%~dp0tools\godot\Godot_v4.4.1-stable_win64.exe" set "gameGodot=%~dp0tools\godot\Godot_v4.4.1-stable_win64.exe"
if not defined gameGodot for /f "delims=" %%G in ('where godot.exe 2^>nul') do if not defined gameGodot set "gameGodot=%%G"
if not defined gameGodot for /f "delims=" %%G in ('where godot4.exe 2^>nul') do if not defined gameGodot set "gameGodot=%%G"
if not defined gameGodot (
    echo Instala Godot 4.4 o superior, o configura GODOT_BIN con la ruta al ejecutable.
    echo Install Godot 4.4+, or set GODOT_BIN to its executable path.
    echo Abre project.godot en el editor y pulsa F5.
    pause
    exit /b 1
)
if not exist "%~dp0.godot\global_script_class_cache.cfg" (
    "%gameGodot%" --headless --editor --path "%~dp0." --quit --log-file "%~dp0logs\import.log"
    if errorlevel 1 exit /b 1
)
start "Marble Overdrive" "%gameGodot%" --path "%~dp0." --log-file "%~dp0logs\game.log"
exit /b 0
