# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

WonderTrader 是一个基于 C++（C++17 标准）的高性能量化交易开发框架，覆盖行情数据采集、策略回测、实盘交易、运营调度等完整交易生命周期。Python 子框架 [wtpy](https://github.com/wondertrader/wtpy) 通过 Porter（FFI）模块封装 C++ 核心。

## 构建命令

### Linux (CMake)
```bash
# 依赖库须放在 /home/mydeps（头文件在 /home/mydeps/include，库文件在 /home/mydeps/lib）
# 需要：gcc 8.4.0+、boost、pthread

cd src
mkdir -p build_all && cd build_all
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)

# 输出路径：build_all/build_x64/Release/bin/<ProjectName>/
```

### Windows (Visual Studio)
`src/` 下提供多个 `.sln` 解决方案文件，按功能子集划分：
- `all.sln` — 全部模块
- `product.sln` — 生产环境模块
- `backtest.sln` — 回测模块
- `datakit.sln` — 数据工具模块
- `traders.sln` — 交易适配器
- `parsers.sln` — 行情解析适配器
- `uft.sln` — 极速交易引擎
- `tools.sln` — 工具集

MSVC 依赖库通过环境变量 `%MyDepends141%` 配置。

### Docker
```bash
cd docker
docker build -t wondertrader -f Dockerfile .
docker run -it wondertrader /bin/bash
```

### 运行测试
```bash
# 构建完成后，TestUnits 可执行文件位于：
# src/build_all/build_x64/Release/bin/TestUnits/TestUnits
# 使用 Google Test（内置于 src/TestUnits/gtest/）
./TestUnits  # 运行全部测试
```

### 复制构建产物到 wtpy
```bash
./copy_bins_linux.sh [wtpy_path]  # 默认路径为 ../wtpy
```

## 架构

### 交易引擎 (src/WtCore/)
核心包含四个策略引擎，均继承自 `WtEngine`：
- **CTA 引擎**（`WtCtaEngine`）— 同步策略引擎，事件+时间驱动，适用于中频策略
- **SEL 引擎**（`WtSelEngine`）— 异步策略引擎，时间驱动，适用于大标的池策略（如多因子选股）
- **HFT 引擎**（`WtHftEngine`）— 事件驱动，系统延迟约 1-2μs
- **UFT 引擎**（`src/WtUftCore/WtUftEngine`）— 独立的极速引擎，系统延迟约 200ns，仅支持 C++ 开发（不提供应用层接口）

每个引擎都有对应的 Ticker（如 `WtCtaTicker`）驱动事件循环，以及策略上下文类（如 `CtaStraBaseCtx` → `CtaStraContext`）。

### 策略上下文与接口 (src/Includes/)
策略接口以抽象类定义：
- `ICtaStraCtx` / `CtaStrategyDefs.h` — CTA 策略接口
- `ISelStraCtx` / `SelStrategyDefs.h` — SEL 策略接口
- `IHftStraCtx` / `HftStrategyDefs.h` — HFT 策略接口
- `IUftStraCtx` / `UftStrategyDefs.h` — UFT 策略接口

### 策略工厂（插件模式）
策略通过工厂插件（动态库）加载：
- `WtCtaStraFact` — CTA 策略（含 DualThrust 示例）
- `WtSelStraFact` — SEL 策略
- `WtHftStraFact` — HFT 策略（含示例）
- `WtUftStraFact` — UFT 策略
- `WtExeFact` — 执行算法单元（MinImpact、TWAP、VWAP 等）
- `WtRiskMonFact` — 风控监控插件

### 行情数据管线
- `IParserApi` / `IParserSpi`（src/Includes/IParserApi.h）— 行情解析适配器接口
- `Parser*` 模块 — 各交易所行情适配器（CTP、XTP、Femas、OES 等）
- `WtDtCore` — 数据工具核心：管理数据采集，支持 UDP/SHM 广播
- `QuoteFactory` — 独立行情采集可执行程序
- `WtDataStorage` / `WtDataStorageAD` — 存储引擎插件（基于 mmap，支持 MySQL）
- `WtDtHelper` — 数据辅助动态库（供 wtpy 进行数据处理）
- `WtDtServo` — 数据服务器，支持实时行情订阅

### 交易执行管线
- `ITraderApi`（src/Includes/ITraderApi.h）— 交易适配器接口
- `Trader*` 模块 — 各交易所交易适配器（CTP、XTP、Femas、OES 等）
- `TraderAdapter`（src/WtCore/）— 适配管理器，桥接策略与交易通道
- 执行架构为 **M+1+N**：M 个策略 → 1 个信号合并器 → N 个交易账户

### Porter 模块（供 wtpy 调用的 FFI/C 接口）
对外暴露 C 语言 API，供外部语言绑定使用：
- `WtPorter` — 实盘交易 C API（封装 `WtRtRunner`）
- `WtBtPorter` — 回测 C API（封装 `WtBtRunner`）
- `WtDtPorter` — 数据工具 C API（封装 `WtDtRunner`）

### 回测框架 (src/WtBtCore/)
- `HisDataReplayer` — 历史数据回放引擎
- `CtaMocker` / `SelMocker` / `HftMocker` / `UftMocker` — 各引擎的策略回测上下文
- `MatchEngine` — 模拟撮合引擎
- `WtBtRunner` — 独立回测可执行程序

### 可执行程序（Runner）
- `WtRunner` — 实盘交易运行器（CTA/SEL/HFT 引擎）
- `WtUftRunner` — UFT 引擎运行器
- `WtBtRunner` — 回测运行器
- `WtExecMon` — 独立算法执行监控器
- `LoaderRunner` — 合约数据加载器
- `QuoteFactory` — 独立行情采集服务

### 公共工具库
- `src/WTSUtils/` — 底层工具（LMDB 封装、YAML 解析、zstd 压缩、配置加载等）
- `src/WTSTools/` — WTS 层级工具
- `src/Share/` — 纯头文件工具库（BoostFile、DLLHelper、CodeHelper、TimeUtils、SpinMutex、StrUtil 等）
- `src/FasterLibs/` — 高性能容器（ankerl::unordered_dense、tsl）
- `src/Includes/FasterDefs.h` — 全局使用的快速哈希容器类型别名
- `src/API/` — 第三方交易所 SDK 头文件和库文件

### 核心数据类型 (src/Includes/)
- `WTSDataDef.hpp` — 行情数据结构（tick、bar 等）
- `WTSContractInfo.hpp` — 合约/品种信息
- `WTSTradeDef.hpp` — 成交/委托/持仓定义
- `WTSVariant.hpp` — 通用配置/变体类型（用于 JSON/YAML 配置解析）
- `WTSStruct.h` — 核心 bar/tick 结构体（`WTSBarStruct`、`WTSTickStruct`）

## 关键约定

- 命名空间使用 `NS_WTP_BEGIN` / `NS_WTP_END` 宏
- 配置文件基于 YAML（通过 WTSCfgLoader 解析为 WTSVariant）
- 动态模块加载使用 `DLLHelper`（封装 dlopen/LoadLibrary）
- 所有策略/行情解析/交易模块均编译为动态库（.so/.dll），运行时加载
- 输出路径遵循格式：`build_x64/{Release|Debug}/bin/<ProjectName>/`
- 平台检测：CMake 中 `MSVC` 对应 Windows MSVC 构建，`GNUCC`（原文如此）对应 GCC/MinGW/Linux
