#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$PROJECT_DIR"

export USER_ID=$(id -u)
export GROUP_ID=$(id -g)

rebuild=0
gpu=0
cyclone=0
domain_id="${ROS_DOMAIN_ID:-0}"
while (($#)); do
	arg="$1"
	case "$arg" in
		--gpu) gpu=1 ;;
		--rebuild) rebuild=1 ;;
		--cyclone) cyclone=1 ;;
		--domain-id)
			if (($# < 2)); then
				echo "Missing value for --domain-id" >&2
				exit 2
			fi
			shift
			domain_id="$1"
			;;
		--domain-id=*) domain_id="${arg#*=}" ;;
		*)
			echo "Usage: $0 [--gpu] [--cyclone] [--domain-id N] [--rebuild]" >&2
			exit 2
			;;
	esac
	shift
done

if [[ ! "$domain_id" =~ ^[0-9]+$ ]] || ((domain_id > 232)); then
	echo "ROS domain ID must be an integer from 0 to 232." >&2
	exit 2
fi

export ROS_DOMAIN_ID="$domain_id"
if [[ "$cyclone" -eq 1 ]]; then
	export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
else
	export RMW_IMPLEMENTATION="${RMW_IMPLEMENTATION:-rmw_fastrtps_cpp}"
fi

compose_files=(-f docker-compose.yml)
if [[ "$gpu" -eq 1 ]]; then
	compose_files+=(-f docker-compose.gpu.yml)
fi

# Costruisce l'immagine solo se assente, se manca Cyclone DDS o su richiesta
# esplicita, evitando di contattare il registry Docker ad ogni avvio.
needs_build=0
if [[ "$rebuild" -eq 1 ]] || ! docker image inspect ros2-humble-turtlebot3-sim >/dev/null 2>&1; then
	needs_build=1
elif [[ "$cyclone" -eq 1 ]]; then
	cyclone_status=$(docker run --rm --entrypoint dpkg-query ros2-humble-turtlebot3-sim -W -f='${Status}' ros-humble-rmw-cyclonedds-cpp 2>/dev/null || true)
	if [[ "$cyclone_status" != "install ok installed" ]]; then
		needs_build=1
	fi
fi

if [[ "$needs_build" -eq 1 ]]; then
	docker compose "${compose_files[@]}" build
fi

docker compose "${compose_files[@]}" up -d turtlebot3_sim

if [[ "$gpu" -eq 1 ]]; then
	echo "Container turtlebot3_sim avviato con GPU, RMW=$RMW_IMPLEMENTATION, ROS_DOMAIN_ID=$ROS_DOMAIN_ID. Esegui ./start_simulation.sh per Gazebo e RViz2."
else
	echo "Container turtlebot3_sim avviato con RMW=$RMW_IMPLEMENTATION, ROS_DOMAIN_ID=$ROS_DOMAIN_ID. Esegui ./start_simulation.sh per Gazebo e RViz2."
fi