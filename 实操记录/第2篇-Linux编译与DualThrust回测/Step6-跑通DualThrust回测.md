# Step 6：跑通 DualThrust 回测

## 操作命令

```bash
cd /wings/zeus-med-evalscope-ea134pub6/my_wondertrader/wtpy/demos/cta_fut_bt
python3 runBT.py
```

## 踩坑过程

### 坑 1：配置文件编码问题（最关键）

**报错**：
```
[error] Loading session config file ../common/sessions.json failed
[error] Loading commodities config file ../common/commodities.json failed
[error] Loading contracts config file ../common/contracts.json failed
[error] segmentation violation（紧接着 crash）
```

**根因**：`demos/common/` 下的 JSON 文件是 **GBK 编码 + Windows CRLF 换行**，
C++ 框架在 Linux 上无法解析，导致 sessions/commodities 配置为空，
回测运行时 `get_kline_slice` 访问空指针 → segfault。

**解决方案**：用 Python 将所有配置文件转换为 UTF-8 + LF：

```bash
cd /wings/zeus-med-evalscope-ea134pub6/my_wondertrader/wtpy/demos/common

python3 -c "
files = ['sessions.json','commodities.json','contracts.json','holidays.json','hots.json','fees.json']
for f in files:
    try:
        with open(f, 'rb') as fp:
            raw = fp.read()
        text = raw.decode('gbk').replace('\r\n', '\n').replace('\r', '\n')
        with open(f, 'w', encoding='utf-8') as fp:
            fp.write(text)
        print(f'✓ {f}')
    except Exception as e:
        print(f'✗ {f}: {e}')
"
```

同时把 `configbt.yaml` 里的编码标志改为 `true`：

```bash
cd /wings/zeus-med-evalscope-ea134pub6/my_wondertrader/wtpy/demos/cta_fut_bt
sed -i 's/uft-8: false/utf-8: true/' configbt.yaml
```

> 注意：原配置里是 `uft-8`（拼写错误，u**f**t 而非 u**t**f），sed 替换时要用原始拼写。

### 坑 2：iconv 无 GBK 支持

系统 `iconv` 不支持 GBK 编码（`iconv: failed to start conversion processing`），
**改用 Python 的内置 `decode('gbk')` 解决**，无需任何额外安装。

---

## 成功运行输出

```
[info ] WonderTrader CTA backtest framework initialzied, version: UNIX v0.9.9 Build@Jun 16 2026 20:45:46
[info ] Reading data from ../storage/csv/CFFEX.IF.HOT_m5.csv ... 68145 items loaded
[info ] Bars transfered to file ../storage/his/min5/CFFEX/CFFEX.IF_HOT.dsb
[info ] DualThrust inited
[info ] Start to replay back data from 201909100930...
（逐日回放 20190910 → 20191031）
[info ] All back data replayed, replaying done
[info ] Strategy has been scheduled 1536 times, totally taking 53080 us, 34.557 us each time
[info ] PnL analyzing of strategy pydt_IF done
press any key to exit
```

## 验证清单

- [x] 无 segfault，无 Error 级别日志
- [x] 68145 条 CFFEX.IF.HOT 5分钟 K 线全部加载
- [x] 策略 DualThrust 调度 1536 次，运行正常
- [x] 绩效分析完成，输出在 `outputs_bt/pydt_IF/`

## 查看回测结果

```bash
ls outputs_bt/pydt_IF/
# 应看到：funds.csv  trades.csv  closes.csv  summary.json 等
cat outputs_bt/pydt_IF/summary.json
```
