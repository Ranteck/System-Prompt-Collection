# Project Memory

## Critical Debugging Lesson: Check Infrastructure Before Tuning

When the robot "ignores obstacles" or drives into walls, **check bridge/Nav2 liveness first** before adjusting costmap/DWB/collision_monitor params:

```bash
ros2 action list              # /navigate_to_pose should have servers
ros2 topic info /odom         # Publisher count > 0 (bridge alive)
ros2 topic info /scan         # Publisher count > 0 (laser working)
ros2 topic info /clock        # Publisher count > 0 (sim running)
```

If the Gazebo→ROS bridge dies (`/odom` Publisher count: 0), the TF chain `odom → base_link` breaks, Nav2 can't operate, and the robot moves blind via CHAMP locomotion controller only.

**Root cause found (2025-02-11)**: `go2_autonav.sh` was launching Nav2 before the bridge was ready. Fix: explicit topic waits + fallback bridge restart.

## Nav2 Config Notes

- `PolygonStop.points` in ROS 2 Jazzy collision_monitor must be string format `[[x,y], ...]`, NOT flat list `[x1, y1, x2, y2, ...]`
- `pointcloud_to_laserscan` `range_min` was 0.5m (created 50cm blind zone around robot) → fixed to 0.12m
- `patrol_controller` `scan_backup_distance` default 0.35m can push robot into walls → set to 0.0

## Key File Paths

- Nav2 params: `unitree_go2_ros2/unitree_go2_sim/config/nav2_go2_params.yaml`
- Patrol waypoints: `unitree_go2_ros2/unitree_go2_sim/config/patrol_waypoints.yaml`
- Launch script: `Scripts/go2_autonav.sh`
- Kill script: `Scripts/go2_kill_terms.sh`
- Launch file (pointcloud_to_laserscan): `unitree_go2_ros2/unitree_go2_sim/launch/unitree_go2_launch.py`
