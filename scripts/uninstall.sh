#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "run as root: sudo $0" >&2
  exit 1
fi

kernel_release="${KERNELRELEASE:-$(uname -r)}"

systemctl disable --now x14-audio-ec-unmute.service 2>/dev/null || true
rm -f /etc/systemd/system/x14-audio-ec-unmute.service
rm -f /usr/local/sbin/x14-audio-ec-unmute
rm -f "/lib/modules/${kernel_release}/extra/x14_ec_bit_probe.ko"
depmod -a "$kernel_release"
systemctl daemon-reload

echo "Uninstalled for kernel ${kernel_release}."
