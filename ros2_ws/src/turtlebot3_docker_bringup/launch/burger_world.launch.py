import os

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import ExecuteProcess, IncludeLaunchDescription, TimerAction
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import Command
from launch_ros.actions import Node


def generate_launch_description():
    gazebo_ros = get_package_share_directory('gazebo_ros')
    turtlebot3_gazebo = get_package_share_directory('turtlebot3_gazebo')
    turtlebot3_description = get_package_share_directory('turtlebot3_description')
    world = os.path.join(turtlebot3_gazebo, 'worlds', 'turtlebot3_world.world')
    model = os.path.join(turtlebot3_gazebo, 'models', 'turtlebot3_burger', 'model.sdf')
    urdf = os.path.join(turtlebot3_description, 'urdf', 'turtlebot3_burger.urdf')

    gazebo_server = ExecuteProcess(
        cmd=[
            'gzserver', '--verbose',
            '-slibgazebo_ros_init.so',
            '-slibgazebo_ros_factory.so',
            '-slibgazebo_ros_force_system.so',
            world,
        ],
        output='screen',
    )
    gazebo_client = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(gazebo_ros, 'launch', 'gzclient.launch.py')
        )
    )
    state_publisher = Node(
        package='robot_state_publisher',
        executable='robot_state_publisher',
        parameters=[{
            'robot_description': Command(['xacro ', urdf, ' namespace:=']),
            'use_sim_time': True,
        }],
    )
    spawn_robot = TimerAction(
        period=10.0,
        actions=[
            Node(
                package='gazebo_ros',
                executable='spawn_entity.py',
                arguments=['-entity', 'burger', '-file', model, '-x', '-2.0', '-y', '-0.5', '-z', '0.01', '-timeout', '90'],
                output='screen',
            )
        ],
    )

    return LaunchDescription([gazebo_server, gazebo_client, state_publisher, spawn_robot])