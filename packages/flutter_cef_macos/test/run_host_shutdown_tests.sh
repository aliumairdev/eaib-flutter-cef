#!/bin/bash
# Compile + run the standalone HostShutdownPolicy unit tests (how shutdown() ends
# cef_host). Swift stdlib only — no Xcode/pod harness needed.
set -euo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$(mktemp -d)/host_shutdown"
swiftc "$DIR/macos/Classes/HostShutdownPolicy.swift" "$DIR/test/HostShutdownPolicyTests.swift" -o "$OUT"
"$OUT"
