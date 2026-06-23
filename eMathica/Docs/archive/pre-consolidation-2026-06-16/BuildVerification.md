# BuildVerification

## 1) 当前本地环境问题（已观测）

在当前机器上，GraphCore / CASCore / SamplingCore 的回归验证会被两类环境问题阻塞：

1. `CoreSimulatorService` 不可用，且 `supportedRuntimes=[]`  
   - 典型报错：`No available simulator runtimes for platform iphonesimulator`
   - 影响：即使只做 `build` / `build-for-testing`，也可能在 `actool` 阶段失败（资源编译依赖 simulator runtime）。

2. iOS 设备向构建会触发签名约束  
   - 典型报错：缺少 provisioning profile（当未使用 simulator destination 或配置不当时）。
   - 缓解：使用 `CODE_SIGNING_ALLOWED=NO`，并优先 simulator build path。

> 结论：当前失败主要是 **运行环境问题**，不是 GraphCore/CASCore/SamplingCore 逻辑编译错误。

---

## 2) 推荐命令（由轻到重）

以下命令默认在项目根目录执行：

`/Users/night_creek/开发/eMathica/eMathica/eMathica`

### A. 项目与 scheme 基础检查

```bash
xcodebuild -list
```

验证范围：
- 工程可读
- `target` / `scheme` 是否存在

---

### B. destination 与 simulator runtime 检查

```bash
xcodebuild -scheme eMathica -showdestinations
```

验证范围：
- 可用 destinations
- 是否存在有效 iOS simulator runtime（不是 placeholder）

---

### C. 无签名 app build（尽量轻量）

```bash
xcodebuild \
  -scheme eMathica \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /private/tmp/eMathicaDD \
  CODE_SIGNING_ALLOWED=NO \
  build
```

验证范围：
- 主 target 编译可行性

已知阻塞：
- 若 simulator runtime 缺失，会在 asset catalog (`actool`) 阶段失败。

---

### D. 无签名 build-for-testing（推荐逻辑层入口）

```bash
xcodebuild \
  -scheme eMathica \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /private/tmp/eMathicaDD \
  CODE_SIGNING_ALLOWED=NO \
  build-for-testing
```

验证范围：
- App + test target 编译
- 不执行测试运行器

已知阻塞：
- 仍可能被 simulator runtime 缺失卡住（同 `actool`）。

---

### E. 定向逻辑层测试（仅在 simulator runtime 正常时）

GraphCore:
```bash
xcodebuild \
  -scheme eMathica \
  -destination 'platform=iOS Simulator,name=<Your Simulator>' \
  -derivedDataPath /private/tmp/eMathicaDD \
  test-without-building \
  -only-testing:eMathicaTests/GraphCoreTests
```

SamplingCore:
```bash
xcodebuild \
  -scheme eMathica \
  -destination 'platform=iOS Simulator,name=<Your Simulator>' \
  -derivedDataPath /private/tmp/eMathicaDD \
  test-without-building \
  -only-testing:eMathicaTests/SamplingCoreTests
```

CASCore:
```bash
xcodebuild \
  -scheme eMathica \
  -destination 'platform=iOS Simulator,name=<Your Simulator>' \
  -derivedDataPath /private/tmp/eMathicaDD \
  test-without-building \
  -only-testing:eMathicaTests/CASCoreTests
```

> 注意：当前 `eMathicaTests` 是 app-hosted（`TEST_HOST`/`BUNDLE_LOADER`），不是纯 SPM test bundle。

---

## 3) 一键脚本

可使用：

```bash
./Scripts/verify_mathcore.sh
```

脚本行为：
- 运行 `-list` / `-showdestinations` / `build-for-testing`
- 默认 `CODE_SIGNING_ALLOWED=NO`
- 清晰输出失败类型提示（simulator runtime、权限、签名）

---

## 4) 常见失败原因分类

1. **Signing profile 问题**  
   - 多出现在 iOS 设备向 build
   - 优先用 simulator destination + `CODE_SIGNING_ALLOWED=NO`

2. **CoreSimulator runtime 缺失**  
   - `showdestinations` 只有 simulator placeholder
   - `actool` 报 `No available simulator runtimes`

3. **DerivedData 权限/锁问题**  
   - 报 `Operation not permitted`、`build.db locked`、result bundle 写入失败
   - 建议使用可写目录（如 `/private/tmp/eMathicaDD`）

---

## 5) CI 建议

1. 在 CI 镜像中预装可用 iOS simulator runtime。  
2. 使用固定 destination（避免自动匹配到 placeholder）。  
3. 统一 `DerivedData` 路径并确保可写。  
4. 避免并发 xcodebuild 抢占同一 DerivedData/build.db。  
5. 逻辑层回归优先执行：
   - `build-for-testing`
   - `test-without-building + only-testing(GraphCore/CASCore/SamplingCore)`

---

## 6) 后续结构建议（非本轮实施）

如需彻底摆脱 simulator/runtime 对纯数学逻辑测试的影响，建议评估：

- 将 `MathCore` 抽成独立 Swift Package（或独立 framework + 非 app-host tests）
- 将 GraphCore/CASCore/SamplingCore/EvaluationCore 测试迁移到纯 Swift 测试入口

这会显著降低 Xcode UI target、asset catalog、sim runtime 对逻辑层回归的耦合。
