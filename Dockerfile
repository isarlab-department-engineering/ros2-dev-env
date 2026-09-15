# ROS 2 Humble + TurtleBot3 Burger simulation (Gazebo + RViz2)
FROM osrf/ros:humble-desktop

ENV DEBIAN_FRONTEND=noninteractive \
    ROS_DISTRO=humble \
    TURTLEBOT3_MODEL=burger \
    GAZEBO_MODEL_PATH=/opt/gazebo_models:/opt/ros/humble/share/turtlebot3_gazebo/models \
    GAZEBO_MODEL_DATABASE_URI=""

# Pacchetti per la simulazione Gazebo, RViz2 e i pacchetti TurtleBot3
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-${ROS_DISTRO}-gazebo-ros-pkgs \
    ros-${ROS_DISTRO}-gazebo-ros2-control \
    ros-${ROS_DISTRO}-turtlebot3 \
    ros-${ROS_DISTRO}-turtlebot3-msgs \
    ros-${ROS_DISTRO}-turtlebot3-simulations \
    ros-${ROS_DISTRO}-rviz2 \
    ros-${ROS_DISTRO}-cartographer \
    ros-${ROS_DISTRO}-cartographer-ros \
    ros-${ROS_DISTRO}-navigation2 \
    ros-${ROS_DISTRO}-nav2-bringup \
    libnss-wrapper \
    python3-colcon-common-extensions \
    python3-rosdep \
    && rm -rf /var/lib/apt/lists/*

COPY gazebo_models /opt/gazebo_models

# Workspace di lavoro per eventuali pacchetti custom
RUN mkdir -p /workspace/ros2_ws/src /workspace/bags && chmod 777 /workspace
WORKDIR /workspace/ros2_ws

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
