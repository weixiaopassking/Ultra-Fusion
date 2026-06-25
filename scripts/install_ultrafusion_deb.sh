#!/usr/bin/env bash
# Download and install the Ultra-Fusion release .deb (v0.1.0).
# Usage:
#   ./scripts/install_ultrafusion_deb.sh
#   ./scripts/install_ultrafusion_deb.sh --mirror
#   ./scripts/install_ultrafusion_deb.sh --deb /path/to/ultrafusion_0.1.0_amd64.deb

set -euo pipefail

VERSION="0.1.0"
DEB_NAME="ultrafusion_${VERSION}_amd64.deb"
SHA256="c9a40d62df6100006431598d672c943f23f116e973e9c3b111d76d76c059196c"
GITHUB_URL="https://github.com/sjtuyinjie/Ultra-Fusion/releases/download/v${VERSION}/${DEB_NAME}"
MIRROR_URL="http://47.100.60.229:8088/loc_map/releases/ultrafusion/${DEB_NAME}"

USE_MIRROR=0
LOCAL_DEB=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Download and install the Ultra-Fusion release package.

Options:
  --mirror          Download from the project mirror instead of GitHub Releases
  --deb PATH        Install a local .deb file (skip download)
  -h, --help        Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mirror) USE_MIRROR=1; shift ;;
    --deb) LOCAL_DEB="${2:?--deb requires a path}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

if [[ "$(id -u)" -ne 0 ]]; then
  SUDO="sudo"
else
  SUDO=""
fi

if [[ -n "$LOCAL_DEB" ]]; then
  DEB_PATH="$LOCAL_DEB"
  if [[ ! -f "$DEB_PATH" ]]; then
    echo "Error: deb not found: $DEB_PATH" >&2
    exit 1
  fi
else
  DEB_PATH="$(mktemp /tmp/ultrafusion.XXXXXX.deb)"
  trap 'rm -f "$DEB_PATH"' EXIT

  if [[ "$USE_MIRROR" -eq 1 ]]; then
    URL="$MIRROR_URL"
    echo "Downloading from mirror: $URL"
  else
    URL="$GITHUB_URL"
    echo "Downloading from GitHub Releases: $URL"
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -O "$DEB_PATH" "$URL"
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL -o "$DEB_PATH" "$URL"
  else
    echo "Error: wget or curl is required." >&2
    exit 1
  fi

  echo "Verifying SHA256 checksum..."
  echo "${SHA256}  ${DEB_PATH}" | sha256sum -c -
fi

echo "Installing ${DEB_PATH} ..."
$SUDO dpkg -i "$DEB_PATH" || true
$SUDO apt-get install -f -y

echo ""
echo "Ultra-Fusion v${VERSION} installed."
echo "  Binary : uf_node  (/opt/ultrafusion/bin/uf_node)"
echo "  Configs: /opt/ultrafusion/config/"
echo "  RViz   : rviz -d /opt/ultrafusion/rviz/lio.rviz"
echo ""
echo "Quick test (after sourcing ROS):"
echo "  source /opt/ros/noetic/setup.bash"
echo "  uf_node m3dgr"
