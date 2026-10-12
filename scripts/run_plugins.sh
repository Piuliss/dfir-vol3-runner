#!/bin/bash
# run_plugins.sh - Volatility 3 plugin sweep against a mounted RAM file.
#
# Usage (host):
#   docker run --rm --platform linux/amd64 \
#       -v "$PWD/data/RAM.raw:/RAM.raw:ro" \
#       -v "$PWD/out:/out" \
#       honeyjack/dfir-vol3-runner:latest \
#       bash /out/run_plugins.sh
#
# Writes a single summary file /out/vol3_summary.txt and per-plugin files when --write enabled.
set -e

RAM="${RAM:-/RAM.raw}"
OUT="${OUT:-/out}"
CACHE="${CACHE:-/tmp/cache}"

mkdir -p "$OUT" "$CACHE"
cd "$CACHE"

run() {
    local plugin="$1"
    local label="${2:-$plugin}"
    echo "=== $label ===" >> "$OUT/vol3_summary.txt"
    if vol -f "$RAM" --cache-path "$CACHE" "$plugin" 2>/dev/null | tail -50 >> "$OUT/vol3_summary.txt"; then
        :
    fi
    echo "--- end $plugin ---" >> "$OUT/vol3_summary.txt"
}

run "windows.info"
run "windows.psscan"
run "windows.netscan"
run "windows.netstat"
run "windows.filescan"
run "windows.registry.hivelist"

# Per-PID dlllist for the first 16 PIDs (after psscan)
PIDS=$(vol -f "$RAM" --cache-path "$CACHE" windows.psscan 2>/dev/null \
       | awk 'NR>1 && $1 ~ /^[0-9]+$/ {print $1}' \
       | sort -u | head -16)
for pid in $PIDS; do
    echo "=== windows.dlllist --pid $pid ===" >> "$OUT/vol3_summary.txt"
    vol -f "$RAM" --cache-path "$CACHE" windows.dlllist --pid "$pid" 2>/dev/null \
        | head -50 >> "$OUT/vol3_summary.txt"
    echo "--- end dlllist pid $pid ---" >> "$OUT/vol3_summary.txt"
done

echo "DONE run_plugins" > "$OUT/vol3_summary.done"
