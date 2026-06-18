# Step 2：下载并解压预编译依赖库（/home/mydeps）

## 说明

`mydeps_gcc8.4.0.7z` 是 WonderTrader 官方提供的预编译依赖包（boost、spdlog 等），
CMakeLists.txt 中 Linux 依赖路径硬编码为 `/home/mydeps`，**不能改目录名**。

文件来源：wondertrader 仓库 `docker/mydeps_gcc8.4.0.7z`（随仓库一起克隆，无需单独下载）。

---

## 实际操作（在远程服务器上直接从仓库目录解压）

仓库已克隆到 `/wings/zeus-med-evalscope-ea134pub6/my_wondertrader/wondertrader/`，
`mydeps_gcc8.4.0.7z` 就在其中的 `docker/` 目录下，**无需从网上下载**，直接解压即可：

```bash
# 解压到 /home（路径硬编码，不能改）
cd /home
7za x /wings/zeus-med-evalscope-ea134pub6/my_wondertrader/wondertrader/docker/mydeps_gcc8.4.0.7z

# 验证
ls /home/mydeps/
# 应看到：include  lib
ls /home/mydeps/include/boost/  # 确认 boost 头文件存在
ls /home/mydeps/lib/ | head -10  # 看几个 .a 文件
```

---

## 执行结果

```
7-Zip (z) 26.01 (x64)
Folders: 1192  Files: 14355  Size: 138066404  Compressed: 10120853
Everything is Ok
```

## 验证清单

- [x] `ls /home/mydeps/` 看到 `include` 和 `lib` 两个目录
- [x] 共解压 14355 个文件，138MB，Everything is Ok
