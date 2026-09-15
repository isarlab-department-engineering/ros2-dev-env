# ROS 2 Humble SLAM Development Environment

This repository provides a Docker-based ROS 2 Humble environment for developing and testing a SLAM algorithm with a TurtleBot3 Burger in Gazebo Classic and RViz2.

The supported environment is Ubuntu 22.04 running in WSL2, with Docker Desktop installed on Windows and WSL integration enabled for the Ubuntu distribution. Gazebo and RViz2 are displayed through WSLg on the Windows desktop.

Before starting, confirm that Docker Desktop is running and that its WSL integration for Ubuntu is enabled.

## Persistent Directories

- `ros2_ws/` is mounted inside the container at `/workspace/ros2_ws`. Put all your ROS 2 source packages in `ros2_ws/src`. Build products in `build/`, `install/`, and `log/` remain on your computer.
- `bags/` is mounted at `/workspace/bags`. Use it to store ROS bag recordings that must persist after the container stops.

## Start the Environment

From the repository root, run:

```bash
./start.sh
```

The first run builds the Docker image. Later runs reuse the image unless the Docker configuration changes.

Start the TurtleBot3 Burger simulation and RViz2:

```bash
./start_simulation.sh
```

This script builds the simulation support package, starts Gazebo with a TurtleBot3 Burger, then opens RViz2. Keep the terminal open while RViz2 is running.

## Develop Your SLAM Package

Open another terminal in the repository root and connect to the container:

```bash
./connect.sh
```

The shell starts in `/workspace/ros2_ws` with ROS 2 Humble and the workspace already sourced.

Create your own ROS 2 package inside `src`. For example, create a Python package named `my_slam`:

```bash
cd /workspace/ros2_ws/src
ros2 pkg create --build-type ament_python my_slam --dependencies rclpy sensor_msgs nav_msgs geometry_msgs tf2_ros
```

Edit the package files from your host editor under `ros2_ws/src/my_slam/`. The same files are immediately available in the container.

After adding or changing code, build and source the workspace:

```bash
cd /workspace/ros2_ws
colcon build --symlink-install
source install/setup.bash
```

Run a node from your package with:

```bash
ros2 run my_slam <executable_name>
```

Use `ros2 topic list`, `ros2 topic echo`, and RViz2 to inspect the simulated sensor data and your algorithm output. The TurtleBot publishes the laser scan on `/scan`, and it provides odometry and transforms needed for SLAM.

## Record and Replay Data

Record selected topics to the persistent bags directory:

```bash
ros2 bag record -o /workspace/bags/slam_run /scan /odom /tf /tf_static
```

Replay a recording later:

```bash
ros2 bag play /workspace/bags/slam_run
```

## Stop the Environment

When you are finished, close Gazebo and RViz2, then run:

```bash
./stop.sh
```
