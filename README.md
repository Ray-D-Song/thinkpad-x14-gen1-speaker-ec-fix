# ThinkPad X14 Gen 1 Linux Internal Speaker EC Latch Temporary Fix

This is a temporary workaround for the internal speaker no-sound issue on ThinkPad X14 Gen 1 / Realtek ALC257 under Linux.

## Installation

Install the kernel build dependencies first. Fedora:

```bash
sudo dnf install gcc make kernel-devel-$(uname -r)
```

If Fedora no longer provides the `kernel-devel` package matching the currently running kernel, update the kernel and kernel-devel together, reboot, then install:

```bash
sudo dnf upgrade kernel kernel-devel
sudo reboot
```

Then run the script directly:

```bash
curl -fsSL https://raw.githubusercontent.com/ray-d-song/thinkpad-x14-gen1-speaker-ec-fix/main/scripts/install.sh | sudo bash
```

## Symptom

On the tested machine, the key state difference is:

```text
silent:  EC[0x3b] bit0 = 1, ALC257 coef 0x35 = 0x0d6a
working: EC[0x3b] bit0 = 0, ALC257 coef 0x35 = 0x8d6a
```

This was causally verified:

```text
EC[0x3b] bit0 = 1 -> internal speaker muted
EC[0x3b] bit0 = 0 -> internal speaker working
```

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/ray-d-song/thinkpad-x14-gen1-speaker-ec-fix/main/scripts/uninstall.sh | sudo bash
```

## Notes

- This is a temporary workaround, not an upstream kernel patch.
- The module is built for the currently running kernel. Re-run the install command after kernel upgrades.
- `EC[0x3b] bit0` is an undocumented EC bit. It has only been validated on this affected ThinkPad X14 Gen 1. Do not use it on other models without re-validating the EC diff.
