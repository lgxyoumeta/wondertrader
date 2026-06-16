# 第二阶段：在 Linux 上把环境搭起来

---

## 第 2 篇：《从零开始：在 Linux 上编译 WonderTrader 并跑通 DualThrust 回测》

### 前置条件

- Ubuntu 18.04（虚拟机或云服务器均可）
- 已完成第一阶段，两个仓库克隆到**同一父目录下**：
  ```bash
  mkdir ~/work && cd ~/work
  git clone https://gitee.com/wondertrader/wondertrader.git
  git clone https://gitee.com/wondertrader/wtpy.git
  ```
  结果：
  ```
  ~/work/
  ├── wondertrader/    ← C++ 主仓库（含 src/、dist/、copy_bins_linux.sh）
  └── wtpy/            ← Python 封装层（含 demos/）
  ```

---

### 第一步：安装编译依赖

```bash
sudo apt-get update

# 一次安装所有依赖
sudo apt-get install -y sudo git gcc-8 g++-8 cmake p7zip-full
```

---

### 第二步：切换 gcc 版本到 gcc-8

Ubuntu 18.04 默认 gcc 是 gcc-7，WonderTrader 需要 gcc-8。**直接替换符号链接**（官方 Dockerfile 用的方式）：

```bash
sudo rm /usr/bin/gcc
sudo ln -s /usr/bin/gcc-8 /usr/bin/gcc
sudo ln -s /usr/bin/g++-8 /usr/bin/g++
```

验证：
```bash
gcc --version
# 应输出：gcc (Ubuntu 8.x.x-xxxx) 8.x.x
```

---

### 第三步：下载并解压预编译依赖库

WonderTrader 依赖 boost、spdlog 等，官方提供了预编译包。

从 WonderTrader Gitee 仓库的 Releases 页面下载 `mydeps_gcc8.4.0.7z`，然后解压到 `/home`：

```bash
# 将下载好的文件移动到 /home 下解压
cd /home
sudo 7za x /path/to/mydeps_gcc8.4.0.7z
```

解压后 `/home/mydeps/` 出现，包含 `include/` 和 `lib/`。
CMakeLists.txt 中 Linux 依赖路径硬编码为 `/home/mydeps`，**不能改目录名**。

```bash
# 验证
ls /home/mydeps/
# 应看到：include  lib
```

---

### 第四步：cmake 构建编译

```bash
cd ~/work/wondertrader/src

# 创建构建目录
mkdir -p build_all && cd build_all

# 生成 Makefile（Release 模式）
cmake .. -DCMAKE_BUILD_TYPE=Release

# 多核编译（-j4 代表用 4 线程，按实际 CPU 数调整）
make -j4
```

编译时间约 5~20 分钟。成功后编译产物出现在：
```
src/build_all/build_x64/Release/bin/
├── Loader/           *.so
├── WtBtPorter/       *.so
├── WtDtPorter/       *.so
└── WtPorter/         *.so
```

**常见编译报错处理：**

| 报错信息 | 原因 | 解决方法 |
|---------|------|---------|
| `fatal error: boost/xxx.hpp: No such file` | 依赖库解压位置不对 | 确认 `/home/mydeps/include/boost/` 存在 |
| `error: unrecognized command line option '-std=c++17'` | gcc 版本还是 gcc-7 | 重新执行第二步的符号链接替换 |
| `ld: cannot find -lxxx` | lib 找不到 | 确认 `/home/mydeps/lib/` 下有对应 `.a` 文件 |

---

### 第五步：把编译产物复制到 wtpy

```bash
# 回到 wondertrader 根目录
cd ~/work/wondertrader

# 执行脚本（默认目标：../wtpy，即与 wondertrader 同级的 wtpy 目录）
bash copy_bins_linux.sh
```

脚本会将 `Loader`、`WtBtPorter`、`WtDtPorter`、`WtPorter` 四个文件夹里的所有 `.so` 复制到 `../wtpy/wtpy/wrapper/linux/`。

```bash
# 验证
ls ~/work/wtpy/wtpy/wrapper/linux/
# 应看到若干 .so 文件
```

如果 wtpy 不在默认路径，传参数指定：
```bash
bash copy_bins_linux.sh /custom/path/to/wtpy
```

---

### 第六步：安装 wtpy

```bash
cd ~/work/wtpy

# 用开发模式安装，这样使用的是刚才复制进来的 .so，而非 PyPI 的预编译版本
pip install -e .
```

---

### 第七步：跑通 DualThrust 回测

wtpy 仓库的 demos 目录包含可直接运行的示例，CTA 期货回测在 `cta_fut_bt/`：

```bash
cd ~/work/wtpy/demos/cta_fut_bt
ls
# runBT.py          ← 回测启动脚本
# configbt.yaml     ← 回测配置文件
# logcfgbt.yaml     ← 日志配置文件
```

demos 目录的完整结构（数据和策略是多个 demo 共用的）：
```
demos/
├── common/           ← 共用基础配置（commodities.json、sessions.json 等）
├── storage/
│   ├── csv/          ← CSV 格式历史数据（如 CFFEX.IF.HOT_m5.csv）
│   └── bin/          ← 二进制格式历史数据（.dsb 文件）
├── Strategies/       ← 共用策略文件
│   ├── DualThrust.py
│   └── ...
└── cta_fut_bt/       ← 我们要跑的回测 demo
    ├── runBT.py
    ├── configbt.yaml
    └── logcfgbt.yaml
```

直接运行：
```bash
python runBT.py
```

**runBT.py 做了什么**（关键部分）：
```python
engine = WtBtEngine(EngineType.ET_CTA)
# 初始化：第一个参数是 common/ 目录，第二个是本目录的 configbt.yaml
engine.init('../common/', "configbt.yaml")
# 配置回测时间范围（格式：YYYYMMDDHHmm）
engine.configBacktest(201909100930, 201912011500)
# 配置历史数据来源：csv 格式，路径指向 demos/storage/
engine.configBTStorage(mode="csv", path="../storage/")
engine.commitBTConfig()

# 创建 DualThrust 策略实例
straInfo = StraDualThrust(
    name='pydt_IF',
    code="CFFEX.IF.HOT",   # 沪深300股指期货主力合约
    barCnt=50,              # 预加载50根K线
    period="m5",            # 5分钟K线
    days=30,                # 用过去30天计算通道
    k1=0.1, k2=0.1,        # 上下轨系数
    isForStk=False
)
engine.set_cta_strategy(straInfo, slippage=0)
engine.run_backtest(bAsync=False)
```

**回测完成后**，结果输出到 `outputs_bt/pydt_IF/` 目录，包含：
- `funds.csv`：每日资金变化（字段：date、dynbalance、closeprofit 等）
- `trades.csv`：每笔成交记录
- `closes.csv`：每次平仓记录
- 终端同时输出关键指标：总收益、年化收益率、最大回撤、夏普比率

---

### configbt.yaml 关键字段说明

```yaml
replayer:
    basefiles:
        commodity: ../common/commodities.json   # 品种信息
        contract:  ../common/contracts.json     # 合约列表
        holiday:   ../common/holidays.json      # 节假日
        hot:       ../common/hots.json          # 主力合约换月规则
        session:   ../common/sessions.json      # 交易时段
    mode: csv           # 数据格式：csv 或 bin
    store:
        path: ../storage/   # 历史数据根目录
    stime: 201909010900     # 回测开始时间（YYYYMMDDHHmm）
    etime: 201912011500     # 回测结束时间
    fees: ../common/fees.json   # 手续费配置
env:
    mocker: cta         # 回测引擎类型，此处用 CTA 引擎
```

---

### 本篇检查清单

- [ ] `gcc --version` 输出 gcc 8.x.x
- [ ] `ls /home/mydeps/` 能看到 `include` 和 `lib` 两个目录
- [ ] `make -j4` 编译完成，无 `Error`（Warning 可忽略）
- [ ] `ls ~/work/wtpy/wtpy/wrapper/linux/` 能看到若干 `.so` 文件
- [ ] `python runBT.py` 运行完成，终端打印出总收益率、最大回撤等指标
- [ ] `outputs_bt/pydt_IF/funds.csv` 文件存在，用 Excel 或 Python 打开能看到每日资金数据
