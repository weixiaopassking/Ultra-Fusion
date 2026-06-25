#!/usr/bin/env bash
# Install ROS Noetic and runtime dependencies for native (non-Docker) Ultra-Fusion.
# Tested on Ubuntu 20.04.
#
# Usage:
#   ./scripts/install_native_deps.sh

set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  SUDO="sudo"
else
  SUDO=""
fi

if ! grep -q '20.04' /etc/os-release 2>/dev/null; then
  echo "Warning: Ultra-Fusion is tested on Ubuntu 20.04 + ROS Noetic." >&2
fi

echo "==> Adding ROS Noetic apt source ..."
$SUDO apt-get update
$SUDO apt-get install -y --no-install-recommends \
  ca-certificates curl gnupg2 lsb-release

if [[ ! -f /usr/share/keyrings/ros-archive-keyring.gpg ]]; then
  curl -fsSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc \
    | $SUDO gpg --dearmor -o /usr/share/keyrings/ros-archive-keyring.gpg
fi

if [[ ! -f /etc/apt/sources.list.d/ros1.list ]]; then
  echo "deb [signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" \
    | $SUDO tee /etc/apt/sources.list.d/ros1.list >/dev/null
fi

echo "==> Installing ROS Noetic and system libraries ..."
$SUDO apt-get update
$SUDO apt-get install -y --no-install-recommends \
  build-essential cmake git wget \
  libatlas-base-dev libboost-thread-dev libeigen3-dev libfmt-dev \
  libgflags-dev libgoogle-glog-dev libopencv-dev libpcl-dev \
  libsuitesparse-dev libtbb-dev \
  ros-noetic-cv-bridge ros-noetic-geometry-msgs ros-noetic-image-transport \
  ros-noetic-nav-msgs ros-noetic-pcl-conversions ros-noetic-pcl-ros \
  ros-noetic-rosbag ros-noetic-roscpp ros-noetic-rospy ros-noetic-rviz \
  ros-noetic-sensor-msgs ros-noetic-sophus ros-noetic-std-msgs ros-noetic-tf

echo "==> Building Ceres Solver 2.1.0 ..."
BUILD_JOBS="${BUILD_JOBS:-$(nproc)}"
TMP_CERES="$(mktemp -d)"
git clone --branch 2.1.0 --depth 1 https://github.com/ceres-solver/ceres-solver.git "$TMP_CERES"
cmake -S "$TMP_CERES" -B "$TMP_CERES/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_EXAMPLES=OFF -DBUILD_SHARED_LIBS=ON -DBUILD_TESTING=OFF -DMINIGLOG=OFF
cmake --build "$TMP_CERES/build" --target install -- -j"$BUILD_JOBS"
rm -rf "$TMP_CERES"

echo "==> Building yaml-cpp 0.8.0 ..."
TMP_YAML="$(mktemp -d)"
git clone --branch 0.8.0 --depth 1 https://github.com/jbeder/yaml-cpp.git "$TMP_YAML"
cmake -S "$TMP_YAML" -B "$TMP_YAML/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DYAML_CPP_BUILD_CONTRIB=OFF -DYAML_CPP_BUILD_TESTS=OFF -DYAML_CPP_BUILD_TOOLS=OFF
cmake --build "$TMP_YAML/build" --target install -- -j"$BUILD_JOBS"
rm -rf "$TMP_YAML"

$SUDO ldconfig

echo ""
echo "Native dependencies installed."
echo "Next step: install the Ultra-Fusion release package:"
echo "  ./scripts/install_ultrafusion_deb.sh"
echo ""
echo "Then source ROS in every new shell:"
echo "  source /opt/ros/noetic/setup.bash"
