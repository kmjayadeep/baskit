#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

python3 - <<'PY'
from pathlib import Path
import re
files = sorted(p for p in Path('app/lib').rglob('*.dart') if not p.name.endswith('.g.dart'))
line_counts=[]
long_lines=0
comment_lines=0
todo_lines=0
large_files=0
very_large_files=0
for p in files:
    lines=p.read_text(errors='ignore').splitlines()
    n=len(lines)
    line_counts.append(n)
    if n>300: large_files+=1
    if n>600: very_large_files+=1
    for line in lines:
        s=line.strip()
        if len(line)>100: long_lines+=1
        if s.startswith('//') or s.startswith('/*') or s.startswith('*'):
            comment_lines+=1
        if 'TODO' in line or 'FIXME' in line:
            todo_lines+=1

total=sum(line_counts)
avg=(total/len(files)) if files else 0
# Readability proxy: penalize indicators that often make code harder to scan.
# Comments have a light penalty because the goal asks for readability without verbosity.
cost = (
    total * 0.02 +
    max(0, avg - 160) * 1.5 +
    large_files * 25 +
    very_large_files * 75 +
    long_lines * 2 +
    comment_lines * 0.4 +
    todo_lines * 10
)
print(f"METRIC dart_files={len(files)}")
print(f"METRIC total_lines={total}")
print(f"METRIC avg_file_lines={avg:.2f}")
print(f"METRIC large_files={large_files}")
print(f"METRIC very_large_files={very_large_files}")
print(f"METRIC long_lines={long_lines}")
print(f"METRIC comment_lines={comment_lines}")
print(f"METRIC todo_lines={todo_lines}")
print(f"METRIC readability_cost={cost:.2f}")
PY

set +e
(cd app && flutter analyze >/tmp/autoresearch_flutter_analyze.out 2>&1)
analyze_exit=$?
(cd app && flutter test >/tmp/autoresearch_flutter_test.out 2>&1)
test_exit=$?
set -e

printf 'METRIC flutter_analyze_exit=%s\n' "$analyze_exit"
printf 'METRIC flutter_test_exit=%s\n' "$test_exit"

if [[ "$analyze_exit" -ne 0 ]]; then
  echo "flutter analyze failed; last 80 lines:" >&2
  tail -80 /tmp/autoresearch_flutter_analyze.out >&2
fi
if [[ "$test_exit" -ne 0 ]]; then
  echo "flutter test failed; last 80 lines:" >&2
  tail -80 /tmp/autoresearch_flutter_test.out >&2
fi

exit 0
