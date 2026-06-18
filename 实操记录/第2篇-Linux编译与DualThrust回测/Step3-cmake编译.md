# Step 3：cmake 构建编译

## 操作命令

```bash
cd /wings/zeus-med-evalscope-ea134pub6/my_wondertrader/wondertrader/src
mkdir -p build_all && cd build_all
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j64
```

## cmake 配置输出（关键信息）

```
-- The C compiler identification is GNU 10.2.1
-- The CXX compiler identification is GNU 10.2.1
-- Operation System is UNIX-like OS's
-- Generator is Unix Makefiles
-- MyDepends is at /home/mydeps
-- Platform is x64
-- Configuring done (0.5s)
-- Generating done (0.1s)
-- Build files have been written to: .../src/build_all
```

## 编译过程说明

- 所有 warning 均可忽略（`-Wwrite-strings`、`-Wdeprecated-declarations` 是历史代码遗留问题）
- 第一次 `make -j64` 出现一个报错：
  ```
  Error copying file ".../bin/libWtDataStorage.so" to ".../bin/WtDtPorter/"
  ```
  **原因**：64 核并行编译时序问题，`WtDtPorter` 在复制依赖时 `WtDataStorage.so` 尚未就绪。
  **解决**：直接重跑一次 `make -j64`，已编译的 target 不会重复编译，`WtDtPorter` 补全链接。

## 最终结果

```
[100%] Built target TestPorter
```

全部 100% 编译完成，无 Error。

## 验证清单

- [x] `cmake` 配置零错误，MyDepends 路径正确
- [x] `make -j64` 最终 100% 完成
- [x] 关键产物确认存在：
  - `build_x64/Release/bin/WtBtPorter/libWtBtPorter.so`
  - `build_x64/Release/bin/WtPorter/libWtPorter.so`
  - `build_x64/Release/bin/WtDtPorter/libWtDtPorter.so`
