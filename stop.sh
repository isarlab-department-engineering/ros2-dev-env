#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$PROJECT_DIR"

export USER_ID=$(id -u)
export GROUP_ID=$(id -g)

docker compose down