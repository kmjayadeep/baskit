#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/app"
flutter analyze >/tmp/autoresearch_checks_analyze.out 2>&1 || { tail -80 /tmp/autoresearch_checks_analyze.out; exit 1; }
flutter test >/tmp/autoresearch_checks_test.out 2>&1 || { tail -80 /tmp/autoresearch_checks_test.out; exit 1; }
