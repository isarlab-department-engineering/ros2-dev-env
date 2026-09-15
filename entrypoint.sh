#!/usr/bin/env bash
set -e

if ! getent passwd "$(id -u)" >/dev/null; then
    export NSS_WRAPPER_PASSWD=/tmp/passwd
    export NSS_WRAPPER_GROUP=/tmp/group
    export LD_PRELOAD=libnss_wrapper.so
    printf 'ros:x:%s:%s:ROS User:/workspace:/bin/bash\n' "$(id -u)" "$(id -g)" > "$NSS_WRAPPER_PASSWD"
    printf 'ros:x:%s:\n' "$(id -g)" > "$NSS_WRAPPER_GROUP"
fi

# Sorgentizza l'ambiente ROS 2 e il workspace locale (se compilato)
source /opt/ros/humble/setup.bash
if [ -f /workspace/ros2_ws/install/setup.bash ]; then
    source /workspace/ros2_ws/install/setup.bash
fi

exec "$@"
