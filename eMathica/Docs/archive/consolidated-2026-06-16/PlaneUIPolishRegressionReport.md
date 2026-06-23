# Plane UI Polish Regression Report

## 1. 本轮是否修改源码

否。

本轮只新增回归文档，不修改任何 Swift 源码、项目配置或目录结构。

## 2. 本轮任务选择与原因

- 本轮按 `Docs/EMathicaGeoGebraCapabilityMatrix.md` 的优先级队列，选择 `A. Plane UI Polish Regression Report`。
- 选择原因：
  - 这是当前队列里风险最低、最适合先冻结成果的任务；
  - 近期 Plane UI 已连续完成多轮小修，如果不先固定一份正式回归基线，后续继续做图形质量、保存边界和依赖图审计时，容易把 UI 回退和核心能力问题混在一起；
  - 当前任务是只读文档工作，不会破坏 Plane MVP 和 Plane UI polish phase 1 的稳定性。

## 3. 回归范围

本轮回归范围只覆盖最近已经落地的 Plane / Home UI polish 成果，不扩到新的功能开发：

- 输入栏状态表达与提交失败可见性
- compact-height 下的数学键盘默认折叠策略
- 多步几何构造提示与取消入口
- 对象区长公式显示与横向滚动
- 对象区全屏编辑
- 首页 `preview.png` 异步读取 / 缓存
- 工作区 glass / keyboard glass 视觉 token

不在本轮范围内：

- Plane 几何对象语义
- 函数输入逻辑
- 函数预览逻辑
- 命名系统
- `DocumentSystem` 编解码逻辑
- `Space` 功能逻辑

## 4. 当前冻结候选项

| 区域 | 当前代码路径 | 自动化覆盖 | 当前判定 | 残余风险 |
|---|---|---|---|---|
| 输入栏 create/edit 状态提示 | `../../Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceState.swift:1493`, `../../Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift:663` | `eMathicaTests/PlaneInputDockPolishTests.swift` | 已形成冻结候选 | 仍需在真实设备 / clean simulator 上重复跑一次运行态回归 |
| 输入栏 commit error 可见提示 | `../../Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceState.swift:45`, `../../Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift:728` | `eMathicaTests/PlaneInputDockPolishTests.swift` | 已形成冻结候选 | 目前只看到状态层和测试层覆盖，缺一份专门 UI smoke |
| compact keyboard 默认折叠 | `../../Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceLayout.swift:8-32`, `../../Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceState.swift:1430-1465`, `../../Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift:244-251` | `eMathicaTests/PlaneCompactKeyboardPolishTests.swift` | 已形成冻结候选 | 短高窗口的极端组合场景仍需后续 visual regression |
| 多步构造提示与取消 | `eMathica/CalculatorModules/Plane/Interaction/PlaneInteractionState.swift:31-68`, `eMathica/CalculatorModules/Plane/Views/PlaneCanvasView.swift:269-309` | `eMathicaTests/PlaneConstructionHintTests.swift` | 已形成冻结候选 | 当前是状态文案与清理逻辑回归，不是完整手势 UI 回归 |
| 对象区表达式优先级与长公式展示 | `../../Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/ObjectPanel/WorkspaceObjectRowView.swift:289`, `../../Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/ObjectPanel/WorkspaceObjectRowView.swift:553-574`, `../../Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/Inspector/ObjectInspectorPanel.swift:100` | `eMathicaTests/WorkspaceObjectRowLayoutMetricsTests.swift` | 已形成冻结候选 | 多行 LaTeX 显式换行仍不在当前冻结范围 |
| 对象区全屏编辑 | `../../Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceState.swift:33`, `../../Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift:38-51`, `../../Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/ObjectPanel/AlgebraObjectPanelView.swift` | `eMathicaTests/ObjectPanelFullscreenTests.swift` | 已形成冻结候选 | 目前只有布尔状态 smoke test，缺少完整交互流程测试 |
| 首页缩略图异步读取 | `eMathica/CoreHome/ProjectThumbnailView.swift:66`, `eMathica/CoreHome/ProjectThumbnailView.swift:92` | `eMathicaTests/ProjectThumbnailLoadingTests.swift` | 已形成冻结候选 | 卡片数量极多时的真实滚动性能仍需后续观察 |
| glass / keyboard visual token | `../../Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/Keyboard/MathKeyboardView.swift:454`, `../../Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift:964`, `../../Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/ObjectPanel/AlgebraObjectPanelView.swift:194` | `eMathicaTests/PlaneVisualPolishTests.swift` | 已形成冻结候选 | 视觉观感仍建议继续用截图复核，不能只靠 token 测试 |

## 5. 自动化回归现状

### 5.1 当前已有专门测试文件

| 测试文件 | 覆盖主题 |
|---|---|
| `eMathicaTests/PlaneInputDockPolishTests.swift` | create/edit 状态标签、commit error 清理 |
| `eMathicaTests/PlaneCompactKeyboardPolishTests.swift` | compact-height 判定、默认折叠、手动展开 |
| `eMathicaTests/PlaneConstructionHintTests.swift` | 多步构造提示文案、取消清理 |
| `eMathicaTests/ObjectPanelFullscreenTests.swift` | 全屏对象区状态切换 |
| `eMathicaTests/WorkspaceObjectRowLayoutMetricsTests.swift` | 表达式 fallback 优先级、单行滚动策略、行高 metrics |
| `eMathicaTests/ProjectThumbnailLoadingTests.swift` | 首页缩略图异步读取与缓存 |
| `eMathicaTests/PlaneVisualPolishTests.swift` | 输入栏、对象区、键盘 glass visual token |

### 5.2 本轮执行结果

| 项目 | 结果 | 备注 |
|---|---|---|
| `xcodebuild build` | pass | 本轮单独使用 `/private/tmp/eMathicaUIPolishRegressionBuildDD` 构建成功 |
| 定向 UI polish test 运行 | incomplete | 本轮在本机 `xcodebuild test` / `test-without-building` 执行尾声遇到 Xcode / Simulator 环境级卡住；没有得到可签字的最终 pass/fail 汇总行 |
| 模拟器环境 | partial | 本轮明确启动了 `iPhone 17 (iOS 26.5)`，首次启动存在 Data Migration，说明此前测试不稳定与本机运行环境有关 |

### 5.3 本轮测试结论解释

- 本轮**不能**把 UI polish 相关测试写成“本次全绿”，因为当前机器上的 `xcodebuild test` 没有稳定吐出最终汇总结果。
- 但本轮也**没有**出现新的产品级编译失败或源码级回退证据：
  - 构建成功；
  - 所有 UI polish 主题都有对应的专门测试文件；
  - 回归覆盖的代码路径与之前 capability matrix 的任务拆分是一致的。
- 因此，本轮文档把这些项归类为“**冻结候选**”，而不是“永久稳定无需再看”。

## 6. 与现有文档基线的关系

| 文档 | 当前作用 |
|---|---|
| `Docs/PlaneMVPRegressionReport.md` | 提供 Plane MVP 主闭环的已验收基线 |
| `Docs/PlaneUIPolishAudit.md` | 提供 UI 问题清单与 polish 范围基线 |
| `Docs/PlaneCompactLayoutAudit.md` | 提供 compact-height / 短高窗口风险基线 |
| `Docs/EMathicaGeoGebraCapabilityMatrix.md` | 把 Plane UI polish regression 正式列为当前优先队列的第一项 |

这份文档的定位不是替代上面几份文档，而是补上“最近几轮 UI 小修如何正式冻结”的回归层。

## 7. 当前冻结判断

### 7.1 可以冻结的内容

以下内容可以作为 **Plane UI polish phase 1 的当前冻结候选基线**：

- 输入栏的 create/edit 状态表达
- commit error 的轻量可见提示
- compact-height 下数学键盘默认折叠
- 多步构造提示与取消入口
- 对象区长公式单行横向滚动策略
- 对象区全屏编辑入口
- 首页缩略图异步读取 / 缓存
- keyboard / object panel / input dock 的 visual token 范围

### 7.2 不能宣称完全冻结的内容

以下内容本轮不应写成“已经彻底稳定无需再测”：

- glass 视觉观感本身
  - 原因：当前视觉 token 有测试，但视觉效果仍依赖真实截图复核
- compact keyboard 的所有窗口组合
  - 原因：当前只有状态与 metrics 级测试，没有完整 Stage Manager / 小屏可视回归
- 对象区全屏编辑的完整交互链
  - 原因：当前只有状态切换 smoke test，没有“编辑内容保留 + 退出恢复”的全链 UI 测试

## 8. 当前 P1 / P2 残余问题

| 级别 | 问题 | 说明 |
|---|---|---|
| P1 | `xcodebuild test` 执行层稳定性不足 | 当前机器上的 simulator 启动、data migration、Xcode activity log 记录器会影响测试收尾稳定性 |
| P1 | glass 观感仍依赖截图复核 | token 与 opacity 有自动化覆盖，但深浅色最终观感仍需要真实截图确认 |
| P2 | 对象区全屏编辑缺少更完整的 UI 流程回归 | 当前只有状态测试，后续如果继续扩对象区功能，建议补一层更完整的 smoke |
| P2 | compact-height 仍缺少更极端窗口组合回归 | 当前对短高窗口有策略，但还缺更系统的多尺寸回归矩阵 |

## 9. 本轮结论

- `Plane UI polish regression` 这项任务可以视为**已完成文档冻结**。
- 结论层面：
  - Plane UI polish phase 1 已经具备一组明确的冻结候选项；
  - 每个候选项都能追到真实代码路径；
  - 每个候选项都有对应的定向测试文件；
  - 本轮 `build` 成功；
  - 本轮 `test` 执行结果受本机 Xcode / Simulator 环境影响，未拿到干净的最终汇总，因此冻结结论是“**可继续推进，但需保留后续回归意识**”，不是“从此不再回头看”。

## 10. 下一轮建议

建议严格按 capability matrix 继续执行下一项：

1. `Graph Quality Baseline Report`
2. 原因：
   - UI 层已经有正式冻结文档；
   - 下一步最值得确认的是 `explicitY / implicit / parametric / polar / piecewise / asymptote / discontinuity` 的当前绘图质量；
   - 这能直接决定 Plane Beta 往前推进时，我们先修 UI 还是先修图形质量。
