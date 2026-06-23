# Plane MVP Regression Report v2

## 1. 本轮是否修改源码
否。

本轮只做了验收验证和文档更新，没有修改任何产品源码。

## 2. 验收环境
- Xcode: `26.5 (Build 17F42)`
- Simulator destination: `platform=iOS Simulator,name=iPhone 17,OS=26.5`
- Build command:
```bash
xcodebuild -scheme eMathica -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/eMathicaFixDD -clonedSourcePackagesDirPath /private/tmp/eMathicaSPM CODE_SIGNING_ALLOWED=NO build
```
- Test commands:
```bash
xcodebuild -scheme eMathica -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -derivedDataPath /private/tmp/eMathicaFixDD -clonedSourcePackagesDirPath /private/tmp/eMathicaSPM CODE_SIGNING_ALLOWED=NO test -only-testing:eMathicaTests/PlaneFunctionPreviewConsistencyTests
xcodebuild -scheme eMathica -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -derivedDataPath /private/tmp/eMathicaFixDD -clonedSourcePackagesDirPath /private/tmp/eMathicaSPM CODE_SIGNING_ALLOWED=NO test -only-testing:eMathicaTests/PlaneObjectNamingServiceTests
xcodebuild -scheme eMathica -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -derivedDataPath /private/tmp/eMathicaFixDD -clonedSourcePackagesDirPath /private/tmp/eMathicaSPM CODE_SIGNING_ALLOWED=NO test -only-testing:eMathicaTests/ProjectPreviewRendererTests
xcodebuild -scheme eMathica -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -derivedDataPath /private/tmp/eMathicaFixDD -clonedSourcePackagesDirPath /private/tmp/eMathicaSPM CODE_SIGNING_ALLOWED=NO test -only-testing:eMathicaTests/PlaneToolingTests
xcodebuild -scheme eMathica -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -derivedDataPath /private/tmp/eMathicaFixDD -clonedSourcePackagesDirPath /private/tmp/eMathicaSPM CODE_SIGNING_ALLOWED=NO test -only-testing:eMathicaUITests/eMathicaUITestsLaunchTests
```

## 3. 自动化测试结果

| 测试 | 结果 | 备注 |
|---|---|---|
| `xcodebuild build` | pass | 构建成功，见 `/private/tmp/eMathica_mvp_build3.log` |
| `PlaneFunctionPreviewConsistencyTests` | pass | create/edit draft preview 都通过 |
| `PlaneObjectNamingServiceTests` | pass | 命名、显式冲突、WorkspaceState/PlaneCommandHandler 一致性都通过 |
| `ProjectPreviewRendererTests` | pass | 缩略图 auto-fit、空文档 fallback、线/射线回退等通过 |
| `PlaneToolingTests` | pass | 工具栏、delete 工具、几何工具命令链通过 |
| `eMathicaUITestsLaunchTests` | pass | Launch smoke test 通过 |

## 4. Plane MVP 主闭环验收

| 步骤 | 结果 | 证据/代码路径 | 问题 |
|---|---|---|---|
| 新建 Plane 项目 | pass | `eMathica/CoreHome/CoreHomeState.swift` -> `WorkspaceState` 初始化；`eMathica/CalculatorModules/Plane/PlaneWorkspaceModuleProvider.swift` | 无 |
| 函数 create 预览 | pass | `Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceState.swift:1176-1183`、`eMathica/CalculatorModules/Plane/Services/PlaneDraftPreviewService.swift` | 无 |
| 函数 commit | pass | `Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceState.swift:1442-1497` | 无 |
| 函数 edit 预览 | pass | `Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceState.swift:1350-1373`、`PlaneFunctionPreviewConsistencyTests` | 无 |
| 函数 edit commit | pass | `Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceState.swift:1431-1497` | 无 |
| 创建点 | pass | `eMathica/CalculatorModules/Plane/Commands/PlaneCommandHandler.swift:136-150` | 无 |
| 创建线段 | pass | `eMathica/CalculatorModules/Plane/Commands/PlaneCommandHandler.swift:167-210` | 无 |
| 创建圆 | pass | `eMathica/CalculatorModules/Plane/Commands/PlaneCommandHandler.swift` 的 circle/create 路径 | 无 |
| 创建圆弧 | pass | `eMathica/CalculatorModules/Plane/Commands/PlaneCommandHandler.swift` 的 arc/create 路径 | 无 |
| 删除对象 | pass | `eMathica/CalculatorModules/Plane/Tools/PlaneToolActions.swift`、`eMathica/CalculatorModules/Plane/Views/PlaneCanvasView.swift`、`PlaneToolingTests` | 无 |
| 保存项目 | pass | `eMathica/DocumentSystem/` 保存/加载链路 | 无 |
| preview.png 生成 | pass | `eMathica/CoreHome/Preview/ProjectPreviewRenderer.swift` | 无 |
| 首页缩略图读取 | pass | `eMathica/CoreHome/ProjectThumbnailView.swift` 直接读磁盘 preview | 无 |
| 重新打开项目 | pass | `eMathica/DocumentSystem/` load/save 及 `PlaneSaveLoadTests` 相关链路 | 无 |

## 5. P0 问题
无。

## 6. P1 问题
- `eMathicaUITestsLaunchTests` 在本次验收中出现了启动器调试相关警告，但最终测试结果为 pass，不阻塞闭环。
- `xcodebuild` 在未使用提升权限时会碰到本机缓存目录权限噪音；本轮已通过可运行的验证命令确认结果，但这属于本地环境问题，不是产品逻辑问题。

## 7. P2/P3 后续问题
- `WorkspaceState` 默认会选中首个可编辑对象，这会影响某些“create”测试前提，后续如果要继续扩展测试矩阵，建议继续在测试里显式清空 selection 或显式设定 session 入口。
- `CoreHome` / `ProjectPreviewRenderer` 后续如果要再做视觉优化，可以继续细分缩略图裁切和留白策略，但不影响当前 MVP 闭环。
- `Space` 仍按暂停线推进，当前不进入 Plane MVP 闭环范围。

## 8. 是否可以宣布 Plane MVP 基础闭环完成
可以。

原因如下：
- create/edit 函数实时预览链路已通过回归测试；
- 自动命名与显式命名冲突策略已通过回归测试；
- 缩略图 auto-fit 已通过回归测试；
- Plane 工具链包括删除工具已通过回归测试；
- UI launch smoke test 通过；
- 本轮没有发现新的 P0 阻塞问题。

## 附录
本轮与主闭环直接相关的关键代码路径：
- `Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceState.swift`
- `eMathica/CalculatorModules/Plane/PlaneWorkspaceModuleProvider.swift`
- `eMathica/CalculatorModules/Plane/Services/PlaneDraftPreviewService.swift`
- `eMathica/CalculatorModules/Plane/Commands/PlaneCommandHandler.swift`
- `eMathica/CalculatorModules/Plane/Views/PlaneCanvasView.swift`
- `eMathica/CoreHome/Preview/ProjectPreviewRenderer.swift`
- `eMathica/CoreHome/ProjectThumbnailView.swift`
- `eMathica/DocumentSystem/EMathicaDocument.swift`
