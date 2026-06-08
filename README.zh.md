# ThinkPad X14 Gen 1 Linux 内置扬声器 EC Latch 临时修复

这是针对 ThinkPad X14 Gen 1 / Realtek ALC257 在 Linux 下内置扬声器无声问题的临时修复。

## 安装

先安装内核构建依赖。Fedora：

```bash
sudo dnf install gcc make kernel-devel-$(uname -r)
```

如果 Fedora 仓库里已经没有当前运行内核对应的 `kernel-devel`，请先更新内核并重启，再安装：

```bash
sudo dnf upgrade kernel kernel-devel
sudo reboot
```

然后直接运行脚本：

```bash
curl -fsSL https://raw.githubusercontent.com/ray-d-song/thinkpad-x14-gen1-speaker-ec-fix/main/scripts/install.sh | sudo bash
```

## 现象

在已测试机器上，关键状态差异为：

```text
silent:  EC[0x3b] bit0 = 1, ALC257 coef 0x35 = 0x0d6a
working: EC[0x3b] bit0 = 0, ALC257 coef 0x35 = 0x8d6a
```

经过因果验证：

```text
EC[0x3b] bit0 = 1 -> internal speaker muted
EC[0x3b] bit0 = 0 -> internal speaker working
```

## 卸载

```bash
curl -fsSL https://raw.githubusercontent.com/ray-d-song/thinkpad-x14-gen1-speaker-ec-fix/main/scripts/uninstall.sh | sudo bash
```

## 注意

- 这是临时修复，不是上游内核补丁。
- 模块针对当前正在运行的内核构建；内核升级后需要重新执行安装命令
- `EC[0x3b] bit0` 是未公开 EC 位，目前只在这台受影响的 ThinkPad X14 Gen 1 上验证过。不要在未重新验证 EC diff 的其他机型上直接使用。
