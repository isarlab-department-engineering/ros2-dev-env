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

docker compose exec -T turtlebot3_sim bash -lc '
    source /opt/ros/humble/setup.bash
    cd /workspace/ros2_ws
    colcon build --packages-select turtlebot3_docker_bringup --symlink-install
'

docker compose exec -d turtlebot3_sim bash -lc '
    source /opt/ros/humble/setup.bash
    source /workspace/ros2_ws/install/setup.bash
    exec ros2 launch turtlebot3_docker_bringup burger_world.launch.py > /tmp/turtlebot3-gazebo.log 2>&1
'

docker compose exec turtlebot3_sim bash -lc '
    source /opt/ros/humble/setup.bash
    source /workspace/ros2_ws/install/setup.bash
    exec ros2 launch turtlebot3_bringup rviz2.launch.py
'