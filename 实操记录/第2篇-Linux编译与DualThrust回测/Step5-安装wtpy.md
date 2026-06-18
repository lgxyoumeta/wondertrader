# Step 5：安装 wtpy

## 操作命令

```bash
cd /wings/zeus-med-evalscope-ea134pub6/my_wondertrader/wtpy
pip3 install -e . --no-deps
pip3 install deap psutil pyquery xlsxwriter pyaml chardet
```

## 问题与解决

### 问题 1：pandas==1.3.5 与 Python 3.11 不兼容

`pip3 install -e .` 直接安装时，构建 pandas 1.3.5 失败（`ModuleNotFoundError: No module named 'pkg_resources'`，
根因是 setuptools 太老 + pandas 1.3.5 本身不支持 Python 3.11）。

**解决方案**：
```bash
# 1. 升级 setuptools/pip
pip3 install --upgrade setuptools pip

# 2. 单独安装兼容 Python 3.11 的 pandas
pip3 install "pandas>=1.5.0,<2.0.0"
# 实际安装：pandas-1.5.3（有 cp311 wheel，无需源码编译）

# 3. 跳过依赖解析直接装 wtpy
pip3 install -e . --no-deps
```

> `wtpy 0.9.9.3 requires pandas==1.3.5` 的 warning 可忽略，pandas 1.5.3 实际兼容。

### 问题 2：缺少运行依赖

```
wtpy 0.9.9.3 requires deap, which is not installed.
wtpy 0.9.9.3 requires psutil, which is not installed.
wtpy 0.9.9.3 requires pyquery, which is not installed.
wtpy 0.9.9.3 requires xlsxwriter, which is not installed.
```

**解决方案**：
```bash
pip3 install deap psutil pyquery xlsxwriter pyaml chardet
```

## 验证清单

- [x] `Successfully installed wtpy-0.9.9.3`
- [x] pandas 1.5.3 安装成功（兼容 Python 3.11）
- [x] deap / psutil / pyquery / xlsxwriter / pyaml / chardet 全部安装完成
