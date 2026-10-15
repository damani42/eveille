#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/build/module-cache"
xcrun swiftc "$ROOT/Sources/AwakeSession.swift" "$ROOT/Tests/main.swift" \
  -module-cache-path "$ROOT/build/module-cache" -framework IOKit -o "$ROOT/build/EveilleTests"
"$ROOT/build/EveilleTests"
