@echo off

md "%0\..\build" 2> nul
if exist "%0\..\build\windows" del "%0\..\build\windows"
md "%0\..\build\windows"

ocra ./src/main.rb res/audio res/customers res/units res/logo.png --windows --output "%0\..\build\windows\MiniMallMaker.exe"
