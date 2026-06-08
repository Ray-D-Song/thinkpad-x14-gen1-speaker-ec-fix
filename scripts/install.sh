#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run as root, for example: curl ... | sudo bash" >&2
  exit 1
fi

repo="ray-d-song/thinkpad-x14-gen1-speaker-ec-fix"
branch="${BRANCH:-main}"
raw_base="${RAW_BASE:-https://raw.githubusercontent.com/${repo}/${branch}}"
kernel_release="${KERNELRELEASE:-$(uname -r)}"
module_dir="/lib/modules/${kernel_release}/extra"
build_dir="/lib/modules/${kernel_release}/build"
work_dir=""

cleanup() {
  if [[ -n "$work_dir" && -d "$work_dir" ]]; then
    rm -rf "$work_dir"
  fi
}
trap cleanup EXIT

fetch() {
  local src="$1"
  local dst="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "${raw_base}/${src}" -o "$dst"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$dst" "${raw_base}/${src}"
  else
    echo "curl or wget is required to download install files" >&2
    exit 1
  fi
}

if [[ -f ./src/x14_ec_bit_probe.c && -f ./scripts/x14-audio-ec-unmute && -f ./systemd/x14-audio-ec-unmute.service ]]; then
  repo_dir="$(pwd)"
else
  work_dir="$(mktemp -d /tmp/x14-speaker-ec-fix.XXXXXX)"
  mkdir -p "$work_dir/src" "$work_dir/scripts" "$work_dir/systemd"
  fetch "Makefile" "$work_dir/Makefile"
  fetch "src/x14_ec_bit_probe.c" "$work_dir/src/x14_ec_bit_probe.c"
  fetch "scripts/x14-audio-ec-unmute" "$work_dir/scripts/x14-audio-ec-unmute"
  fetch "systemd/x14-audio-ec-unmute.service" "$work_dir/systemd/x14-audio-ec-unmute.service"
  repo_dir="$work_dir"
fi

cd "$repo_dir"

if [[ ! -d "$build_dir" ]]; then
  cat >&2 <<EOF
Missing kernel build directory:
  $build_dir

Install the matching kernel development package for the running kernel, then run this installer again.

Fedora:
  sudo dnf install gcc make kernel-devel-${kernel_release}

If Fedora no longer provides kernel-devel-${kernel_release}, update kernel and kernel-devel together, reboot into the new kernel, then rerun this installer:
  sudo dnf upgrade kernel kernel-devel
  sudo reboot
EOF
  exit 1
fi

make clean >/dev/null 2>&1 || true
make KDIR="$build_dir"

install -d -m 0755 "$module_dir" /usr/local/sbin
install -m 0644 src/x14_ec_bit_probe.ko "$module_dir/x14_ec_bit_probe.ko"
install -m 0755 scripts/x14-audio-ec-unmute /usr/local/sbin/x14-audio-ec-unmute
install -m 0644 systemd/x14-audio-ec-unmute.service /etc/systemd/system/x14-audio-ec-unmute.service

restorecon -v "$module_dir/x14_ec_bit_probe.ko" /usr/local/sbin/x14-audio-ec-unmute /etc/systemd/system/x14-audio-ec-unmute.service 2>/dev/null || true
depmod -a "$kernel_release"
systemctl daemon-reload
systemctl enable x14-audio-ec-unmute.service
systemctl start x14-audio-ec-unmute.service

systemctl --no-pager --full status x14-audio-ec-unmute.service || true
echo
echo "Installed."

if [[ -t 0 ]]; then
  read -r -p "Reboot now? [y/N] " answer
  case "$answer" in
    [yY]|[yY][eE][sS])
      systemctl reboot
      ;;
    *)
      echo "Reboot later to verify the fix."
      ;;
  esac
else
  echo "Run 'sudo reboot' to verify the fix."
fi
