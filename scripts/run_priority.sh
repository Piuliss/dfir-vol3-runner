#!/bin/bash
# run_priority.sh - Hashdump + Lsadump + Cachedump + Syscall trace + Registry printkey.
# High-noise plugins that often produce larger output; useful on a hashdumping target.
set -e

RAM="${RAM:-/RAM.raw}"
OUT="${OUT:-/out}"
CACHE="${CACHE:-/tmp/cache}"

mkdir -p "$OUT" "$CACHE"
cd "$CACHE"

run() {
    local plugin="$1"
    local label="${2:-$plugin}"
    echo "=== $label ===" >> "$OUT/vol3_priority.txt"
    vol -f "$RAM" --cache-path "$CACHE" "$plugin" 2>/dev/null | head -50 >> "$OUT/vol3_priority.txt"
    echo "--- end $plugin ---" >> "$OUT/vol3_priority.txt"
}

run "windows.registry.hivelist"
run "windows.registry.printkey"
run "windows.hashdump"
run "windows.lsadump"
run "windows.cachedump"
run "windows.sessions"
run "windows.info"
run "windows.envars"
run "windows.getsids"
run "windows.process_info"
run "windows.cmdline"
run "windows.pstree"
run "windows.pslist"
run "windows.privileges"
run "windows.malfind"

echo "DONE priority" > "$OUT/vol3_priority.done"
