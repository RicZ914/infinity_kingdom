@echo off
setlocal

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\run_game.ps1" %*

if errorlevel 1 (
  echo.
  echo Failed to start Infinity Kingdom.
  pause
)
