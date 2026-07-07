@echo off
setlocal

rem Copy config\wezterm\*.lua to Windows WezTerm config directory.
rem Run this from the first cmd.exe tab opened by Windows WezTerm.

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "SETUP_DIR=%%~fI"
set "SOURCE_DIR=%SETUP_DIR%\config\wezterm"
set "TARGET_DIR=%USERPROFILE%\.config\wezterm"

if not exist "%SOURCE_DIR%\wezterm.lua" (
  echo Missing source: "%SOURCE_DIR%\wezterm.lua"
  echo Run this script from outputs\zsh_setup\bin, or use the WSL installer:
  echo   wsl -e sh -lc "cd ~/outputs/zsh_setup ^&^& sh bin/install-wezterm-windows-config"
  exit /b 1
)

echo Install WezTerm config for Windows WezTerm
echo Source: "%SOURCE_DIR%"
echo Target: "%TARGET_DIR%"

if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"
copy /Y "%SOURCE_DIR%\*.lua" "%TARGET_DIR%\" >nul

echo.
echo Done.
echo Reload WezTerm with Ctrl-Shift-r or restart WezTerm.
echo.
echo If you want to pin a WSL distro, run in cmd.exe or PowerShell:
echo   setx WEZTERM_WSL_DISTRO Ubuntu

endlocal
