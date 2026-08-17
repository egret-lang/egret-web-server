#!/usr/bin/env bash
set -euo pipefail

BLUE_BG=$'\033[1;44;37m'
RESET=$'\033[0m'

blue_line() {
    printf '%s%s%s\n' "$BLUE_BG" "$1" "$RESET"
}

log() {
    blue_line "[$(date '+%H:%M:%S')] $1"
}

print_blue_file() {
    while IFS= read -r line; do
        blue_line "$line"
    done < "$1"
}

show_build_progress() {
    local dots="."

    while true; do
        printf '\r%s[%s] Starting egret-web-server build%s   %s' "$BLUE_BG" "$(date '+%H:%M:%S')" "$dots" "$RESET"
        case "$dots" in
            ".") dots=".." ;;
            "..") dots="..." ;;
            "...") dots="." ;;
        esac
        sleep 0.5
    done
}

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

build_start="$(date +%s)"
build_log="$(mktemp)"
egret build >"$build_log" 2>&1 &
build_pid="$!"
show_build_progress &
progress_pid="$!"
if ! wait "$build_pid"; then
    kill "$progress_pid" 2>/dev/null || true
    wait "$progress_pid" 2>/dev/null || true
    printf '\r'
    log "Build failed. Compiler output:"
    print_blue_file "$build_log"
    rm -f "$build_log"
    exit 1
fi
build_end="$(date +%s)"
kill "$progress_pid" 2>/dev/null || true
wait "$progress_pid" 2>/dev/null || true
printf '\r'
if [ -s "$build_log" ]; then
    print_blue_file "$build_log"
fi
rm -f "$build_log"
log "Build finished in $((build_end - build_start))s."

log "Starting egret-web-server with ./conf/web.conf..."
log "Listening URLs: http://127.0.0.1/index.html and https://127.0.0.1/index.html"
log "Press Ctrl+C to stop the server."
exec sudo ./build/egret-web-server -c ./conf/web.conf
