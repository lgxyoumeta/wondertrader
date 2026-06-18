# Step 1：安装编译工具

## 实际环境

- 系统：Alibaba Cloud Linux 3（龙蜥，内核 4.19，兼容 CentOS/RHEL）
- 架构：x86_64
- gcc：**10.2.1**（自带，无需切换版本，直接支持 C++17）
- 工作目录：`/wings/zeus-med-evalscope-ea134pub6/my_wondertrader/`

> 文档描述的 Ubuntu 18.04 + gcc-8 在此环境不适用，gcc 10.2.1 已满足要求，跳过切换 gcc 步骤。

---

## cmake 安装

cmake 已预装（版本 3.26.5），yum 确认后无需操作：

```bash
sudo yum install -y cmake
# 输出：Package cmake-3.26.5-2.0.2.al8.x86_64 is already installed. Nothing to do.

cmake --version
# cmake version 3.26.5
```

---

## p7zip 安装（用于解压 mydeps_gcc8.4.0.7z）

dnf/yum 源中无 p7zip，改用官方预编译二进制安装：

```bash
cd /tmp
wget https://www.7-zip.org/a/7z2601-linux-x64.tar.xz
mkdir -p /tmp/7zip && tar -xf 7z2601-linux-x64.tar.xz -C /tmp/7zip
sudo cp /tmp/7zip/7zzs /usr/local/bin/7za
sudo chmod +x /usr/local/bin/7za

# 验证
7za i
# 输出：7-Zip (z) 26.01 (x64) ...
```

> **注意**：文件名随版本变化，当前（2026-06）最新版为 `7z2601-linux-x64.tar.xz`，`7za i` 能正常输出即成功。

---

## 验证清单

- [x] `cmake --version` → cmake version 3.26.5
- [x] `7za i` → 7-Zip (z) 26.01 (x64)
