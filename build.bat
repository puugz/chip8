@echo off
cls

if not exist bin\ (
  mkdir bin\
)
cd bin\

set defines=
set no_console=false
set debug_mode=true

if "%no_console%"=="true" (
  set defines=%defines% -subsystem:windows
)
if "%debug_mode%"=="true" (
  set defines=%defines% -o:none -debug
)

odin build ..\src -use-separate-modules -out:chip8-emulator.exe %defines%
