#! /bin/bash

set -euo pipefail

if [ -z "${1:-}" ]; then
    echo "Usage: $0 <platform_subdir>" >&2
    echo "Example: $0 twitter" >&2
    exit 1
fi

PLATFORM="$1"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
WORKDIR="$SCRIPT_DIR/$PLATFORM"

if [ ! -d "$WORKDIR" ]; then
    echo "Platform directory not found: $WORKDIR" >&2
    exit 1
fi

cd "$WORKDIR"

CIRCUIT_NAME=$(grep '^name = ' Nargo.toml | sed 's/name = "\(.*\)"/\1/' | tr -d ' ')
if [ -z "$CIRCUIT_NAME" ]; then
    echo "Could not read circuit name from Nargo.toml" >&2
    exit 1
fi

NARGO_VERSION="1.0.0-beta.5"
BB_VERSION="0.84.0"

LOG_FILE="compile.log"

# Truncate log file at start
: > "$LOG_FILE"

log() {
    printf "[%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$1" | tee -a "$LOG_FILE"
}

log "=== Compiling $CIRCUIT_NAME noir circuit (platform: $PLATFORM) ==="

log "Step 0: Checking Noir and BB versions"
if [ "$(nargo --version | grep "nargo version = $NARGO_VERSION")" != "nargo version = $NARGO_VERSION" ]; then
    log "Noir version is not $NARGO_VERSION, running noirup --version $NARGO_VERSION"
    noirup --version $NARGO_VERSION >> "$LOG_FILE" 2>&1
fi

if [ "$(bb --version)" != "v$BB_VERSION" ]; then
    log "BB version is not $BB_VERSION, running bbup --version $BB_VERSION"
    bbup --version $BB_VERSION >> "$LOG_FILE" 2>&1
fi

log "Step 1: Compiling circuit"
nargo compile >> "$LOG_FILE" 2>&1
if [ $? -ne 0 ]; then
    log "Failed to compile circuit"
    exit 1
fi

log "Step 2: Writing VK"
bb write_vk --bytecode_path ./target/$CIRCUIT_NAME.json --output_path ./target --oracle_hash keccak >> "$LOG_FILE" 2>&1
if [ $? -ne 0 ]; then
    log "Failed to write VK"
    exit 1
fi

log "Step 3: Writing Solidity verifier"
bb write_solidity_verifier --vk_path ./target/vk --output_path ./target/HonkVerifier.sol >> "$LOG_FILE" 2>&1
if [ $? -ne 0 ]; then
    log "Failed to write Solidity verifier"
    exit 1
fi

log "=== Done compiling $CIRCUIT_NAME noir circuit ==="
