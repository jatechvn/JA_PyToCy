@echo off
cd /d %~dp0
set "PUB_CACHE=%~dp0.pub-cache"
flutter run -d windows
