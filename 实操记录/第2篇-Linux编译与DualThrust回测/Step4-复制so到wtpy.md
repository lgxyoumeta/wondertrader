# Step 4：把编译产物复制到 wtpy

## 操作命令

```bash
cd /wings/zeus-med-evalscope-ea134pub6/my_wondertrader/wondertrader
bash copy_bins_linux.sh
```

## 执行结果

脚本自动识别 wtpy 路径为 `../wtpy`，复制了以下文件：

| 目标文件 | 用途 |
|---------|------|
| `libWtBtPorter.so` | 回测 Python 接口（核心） |
| `libWtPorter.so` | 实盘 Python 接口（核心） |
| `libWtDtPorter.so` | 数据采集 Python 接口 |
| `libWtDtHelper.so` | 数据工具（csv↔bin转换） |
| `libWtDataStorage.so` / `libWtDataStorageAD.so` | 历史数据存储引擎 |
| `libWtExecMon.so` / `libWtExeFact.so` | 执行算法（TWAP/VWAP等） |
| `libWtRiskMonFact.so` | 风控插件 |
| `libWtMsgQue.so` / `libWtDtServo.so` | 消息队列/数据服务 |
| `parsers/` 子目录 | 行情解析器（CTP/XTP/Femas/UDP/Shm） |
| `traders/` 子目录 | 交易接口（CTP/XTP/Femas/Mocker等） |
| `executer/` 子目录 | 执行算法插件 |

## 验证结果

```
wtpy/wrapper/linux/ 下共有：
executer/  parsers/  traders/  __init__.py
libCTPLoader.so  libCTPOptLoader.so  libTraderDumper.so
libWtBtPorter.so  libWtDataStorage.so  libWtDataStorageAD.so
libWtDtHelper.so  libWtDtPorter.so  libWtDtServo.so
libWtExecMon.so  libWtMsgQue.so  libWtPorter.so  libWtRiskMonFact.so
```

## 验证清单

- [x] `copy_bins_linux.sh` 执行无报错
- [x] `wtpy/wrapper/linux/` 下存在 `libWtBtPorter.so`（回测必需）
- [x] `wtpy/wrapper/linux/` 下存在 `libWtPorter.so`（实盘必需）
- [x] `parsers/`、`traders/`、`executer/` 子目录均已创建
