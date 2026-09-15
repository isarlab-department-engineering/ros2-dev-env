#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$PROJECT_DIR"

export USER_ID=$(id -u)
export GROUP_ID=$(id -g)

if ! docker compose ps --status running --services | grep -qx 'turtlebot3_sim'; then
    echo "Il container non e' in esecuzione. Avvialo prima con ./start.sh." >&2
    exit 1
fi

docker compose exec -it turtlebot3_sim bash -lc '
    source /opt/ros/humble/setup.bash
    if [ -f /workspace/ros2_ws/install/setup.bash ]; then
        source /workspace/ros2_ws/install/setup.bash
    fi
    cd /workspace/ros2_ws
    exec bash
'