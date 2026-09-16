#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$PROJECT_DIR"

export USER_ID=$(id -u)
export GROUP_ID=$(id -g)

compose_files=(-f docker-compose.yml)
if [[ "${1:-}" == "--gpu" ]]; then
	compose_files+=(-f docker-compose.gpu.yml)
elif [[ -n "${1:-}" ]]; then
	echo "Usage: $0 [--gpu]" >&2
	exit 2
fi

docker compose "${compose_files[@]}" up -d --build turtlebot3_sim

if [[ "${1:-}" == "--gpu" ]]; then
	echo "Container turtlebot3_sim avviato con GPU. Esegui ./start_simulation.sh per Gazebo e RViz2."
else
	echo "Container turtlebot3_sim avviato. Esegui ./start_simulation.sh per Gazebo e RViz2."
fi