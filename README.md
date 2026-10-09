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

The first run builds the Docker image and requires an internet connection. Later runs reuse the existing image and do not require internet, unless you pass `--rebuild`:

```bash
./start.sh --rebuild
```

To request NVIDIA GPU access for Gazebo and RViz2, use:

```bash
./start.sh --gpu
```

To use Cyclone DDS and set the ROS domain ID, pass the corresponding options:

```bash
./start.sh --cyclone --domain-id 30
```

Options can be combined, for example:

```bash
./start.sh --gpu --cyclone --domain-id 30
```

`--domain-id` accepts values from `0` to `232` and defaults to `0`. `--cyclone` selects `rmw_cyclonedds_cpp`; the script checks whether `ros-humble-rmw-cyclonedds-cpp` is already installed in the local image and rebuilds it if the package is missing. The first build that installs Cyclone DDS requires an internet connection; later starts can use the local image. `--rebuild` explicitly rebuilds the image.

GPU mode requires Docker Desktop GPU support and an NVIDIA GPU available through WSL2. Without `--gpu`, the simulation uses software rendering.

### WSL2 Host GPU Variables

Add these variables to the WSL2 Ubuntu user's `~/.bashrc` on the host system:

```bash
export LIBVA_DRIVER_NAME=d3d12
export GALLIUM_DRIVER=d3d12
export MESA_D3D12_DEFAULT_ADAPTER_NAME=NVIDIA
```

Reload the shell after editing:

```bash
source ~/.bashrc
```

These variables must be set in the host WSL2 environment before running `./start.sh --gpu`. They select the NVIDIA adapter through the WSLg D3D12 OpenGL path.

In GPU mode, the container also receives the WSLg Wayland runtime and NVIDIA graphics capabilities so Gazebo and RViz2 can use hardware OpenGL. If your WSL distribution exposes WSLg at a different runtime path, set `XDG_RUNTIME_DIR` before running `./start.sh --gpu`.

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

## Connecting to the Real Robot

To use this environment with a physical TurtleBot3 instead of the simulation:

1. Connect your host machine to the robot's Wi-Fi network.
2. Set the same ROS domain used by the robot on every terminal/shell that talks to it (host and container):

   ```bash
   export ROS_DOMAIN_ID=30
   ```

   Add this line to `~/.bashrc` (both on the WSL2 host and, if needed, inside the container) so it is always set.
3. Verify connectivity with `ros2 topic list`. You should see the robot's topics without starting the simulation.

### WSL2 Networking Troubleshooting

If `ros2 topic list` shows no topics from the robot, work through these steps in order:

1. **WSL network mode.** On Windows, open (or create) `%UserProfile%\.wslconfig` and make sure networking is set to mirrored mode, with the firewall disabled for WSL:

   ```ini
   [wsl2]
   networkingMode=mirrored

   [experimental]
   hostAddressLoopback=true
   ```

   Add under `[wsl2]`:

   ```ini
   firewall=false
   ```

   Restart WSL from PowerShell (`wsl --shutdown`) after editing this file.

2. **RMW implementation.** Fast DDS often has trouble with multicast discovery through WSL2/Wi-Fi. Switch to Cyclone DDS:

   ```bash
   sudo apt install ros-humble-rmw-cyclonedds-cpp
   export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
   ```

   Add the `export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp` line to `~/.bashrc` as well.

3. **Wi-Fi network profile.** In Windows, set the robot's Wi-Fi network profile to **Private** (Settings > Network & Internet > Wi-Fi > your network > Network profile type). Public profiles block the discovery traffic ROS 2 needs.

4. **Hyper-V firewall policy.** If topics are still not visible, allow inbound traffic on the Hyper-V virtual switch used by WSL2 from an elevated PowerShell prompt:

   ```powershell
   Get-NetFirewallHyperVVMSetting -PolicyStore ActiveStore
   Set-NetFirewallHyperVVMSetting -Name '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}' -DefaultInboundAction Allow
   ```

5. **Multiple network interfaces.** If WSL2 exposes more than one network interface (for example `eth0` for a wired/virtual adapter and `eth1` for Wi-Fi), Cyclone DDS may pick the wrong one. Force it to use the Wi-Fi interface by creating `~/cyclonedds.xml`:

   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <CycloneDDS xmlns="https://cdds.io/config">
     <Domain id="any">
       <General>
         <Interfaces>
           <NetworkInterface name="eth1" priority="default" multicast="true"/>
         </Interfaces>
       </General>
     </Domain>
   </CycloneDDS>
   ```

   Then add to `~/.bashrc`:

   ```bash
   export CYCLONEDDS_URI=file://$HOME/cyclonedds.xml
   ```

   Reload the shell and restart the ROS 2 daemon:

   ```bash
   source ~/.bashrc
   ros2 daemon stop
   ros2 topic list
   ```

## Stop the Environment

When you are finished, close Gazebo and RViz2, then run:

```bash
./stop.sh
```
