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
rm -rf target
