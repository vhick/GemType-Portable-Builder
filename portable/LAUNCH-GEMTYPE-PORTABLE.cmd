@echo off
setlocal EnableExtensions
title GemType Portable

set "ROOT=%~dp0"
set "EXE=%ROOT%GemType-Portable.exe"
set "DATA=%ROOT%Data"
set "LOGDIR=%ROOT%LauncherLogs"
set "LOG=%LOGDIR%\Launch.log"

if not exist "%DATA%" mkdir "%DATA%" >nul 2>&1
if not exist "%LOGDIR%" mkdir "%LOGDIR%" >nul 2>&1

echo.>>"%LOG%"
echo ==== %date% %time% GemType Portable launch ====>>"%LOG%"
echo EXE=%EXE%>>"%LOG%"
echo DATA=%DATA%>>"%LOG%"

if not exist "%EXE%" (
  echo ERROR: GemType-Portable.exe not found.>>"%LOG%"
  echo.
  echo ERROR: GemType-Portable.exe was not found beside this launcher.
  echo.
  pause
  exit /b 1
)

start "" "%EXE%"
exit /b 0
