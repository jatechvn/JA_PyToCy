#!/bin/bash
cd "$(dirname "$0")"
export PUB_CACHE="$(pwd)/.pub-cache"
if [[ "$OSTYPE" == "darwin"* ]]; then
  flutter run -d macos
else
  flutter run -d linux
fi
