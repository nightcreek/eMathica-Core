# Plane Compact Layout Audit

## 1. 本轮是否修改源码：否

本轮只做只读审计，没有修改任何产品源码。

## 2. 当前布局结构

当前 Plane 工作区的主要布局来自 [`WorkspaceView.swift`](/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift)：

- 根容器是 `GeometryReader`，基于 `proxy.size` 和 `proxy.safeAreaInsets` 计算 `WorkspaceLayoutMetrics.make(size:safeInsets:)`。
- 主结构是 `ZStack(alignment: .top)`，所有关键 UI 大多以 overlay 形式叠在画布上。
- 画布是底层层级 `canvasLayer`，并且 `ignoresSafeArea()`。
- 对象区是条件 overlay：`if configuration.showsObjectPanel && state.isObjectPanelPresented`。
- 工具栏、文档菜单、撤销/重做、检查器按钮都在同一个 overlay ZStack 内，按 `metrics.toolbarTop` / `metrics.inspectorTop` 定位。
- 输入 dock 也是 overlay，使用 `.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)` 锚在底部，并通过 `metrics.inputBarBottom` 让位于 safe area。
- 根层 `ZStack` 使用 `.ignoresSafeArea(edges: [.top, .bottom])`，所以整体并不是“先给画布留出输入栏高度”的 reflow 布局，而是“画布铺满 + 上下浮层叠加”。

按空间关系拆分：

- 正常布局参与的区域：
  - 画布层 `canvasLayer`
  - `GeometryReader` 提供的尺寸计算
- overlay 区域：
  - 工具栏
  - 文档菜单 / 撤销重做 / 检查器按钮
  - 对象区
  - 输入 dock
- 固定高度或近似固定高度区域：
  - `MathKeyboardView`
  - `KeyboardTabButton`
  - `GlassKeyButton`
  - `FormulaEditorView` 的最小高度逻辑
  - 对象区 row 高度与面板头部高度
- 可能遮挡画布的区域：
  - 底部输入 dock
  - 数学键盘
  - 右侧对象区
  - 顶部工具栏与检查器按钮群
- 受 safe area 影响的区域：
  - 主要是 `metrics.toolbarTop`
  - `metrics.objectPanelTop`
  - `metrics.inspectorPanelTop`
  - `metrics.inputBarBottom`

## 3. 高度预算表

| UI 部件 | 文件路径 | 高度来源 | 是否固定 | compact 风险 |
|---|---|---|---|---|
| 输入 dock 外壳 | [`WorkspaceView.swift`](/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift) | `WorkspaceInlineInputDock` 的 `VStack(spacing: 16)`，再加上下 padding 与外层 overlay 位置 | 部分固定 | 高：会和键盘、错误 banner、建议栏叠加消耗高度 |
| 输入 dock 状态 chip | [`WorkspaceView.swift`](/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift) | `Text` + `.padding(.horizontal, 8)` + `.padding(.vertical, 4)` + Capsule 背景 | 否，但很小 | 低：本身不大，但在极短窗口里会增加一层竖向占用 |
| FormulaEditorView 主编辑行 | [`FormulaEditorView.swift`](/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/Keyboard/FormulaEditorView.swift) | `preferredHeight(for:) = max(44, lineUnits * 22 + 12)` | 否，按表达式增长 | 中：多行模板会显著拉高 dock |
| diagnostics / draft 提示 | [`WorkspaceView.swift`](/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift) | `overlay(alignment: .bottomLeading)`，由 `Text` + 图标 + 字体大小决定 | 否 | 低到中：通常一行，但会挤压 editor 可见区域 |
| commit error banner | [`WorkspaceView.swift`](/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift) | `commitErrorBanner(message:)`，由 `Text` + 内边距 + 圆角卡片决定 | 否 | 中：错误文案长时会占一到两行 |
| 数学键盘整体最小高度 | [`WorkspaceView.swift`](/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift) | `WorkspaceInlineInputVisualMetrics.keyboardPanelMinHeight = 216` | 是 | 高：这是短高窗口里最明显的占高来源 |
| keyboard tab 高度 | [`MathKeyboardView.swift`](/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/Keyboard/MathKeyboardView.swift) | `KeyboardTabButton.frame(height: 36)` | 是 | 中：tab 本身不高，但固定存在 |
| key row 高度 | [`MathKeyboardView.swift`](/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/Keyboard/MathKeyboardView.swift) | `GlassKeyButton.frame(height: 40)` + row spacing 7 + VStack spacing 8 | 基本固定 | 高：键盘主内容区几乎不会自动压缩 |
| 输入 dock 与键盘间 spacing | [`WorkspaceView.swift`](/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift) | `VStack(spacing: WorkspaceInlineInputVisualMetrics.previewKeyboardSpacing)`，值为 16 | 固定 | 中：它不是最大项，但在短窗口里每 8-16pt 都重要 |
| 底部 safe area | [`WorkspaceLayout.swift`](/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceLayout.swift) | `inputBarBottom = max(2, safeInsets.bottom + 0)` | 取决于设备 | 中：只保留了最小底边距，不能提供额外“缓冲” |
| 顶部 toolbar / header | [`WorkspaceLayout.swift`](/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceLayout.swift) | `toolbarTop = max(16, safeInsets.top + 18)` | 部分固定 | 低到中：不算大，但会压缩可视画布上边缘 |
| 对象区 header + rows | [`AlgebraObjectPanelView.swift`](/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/ObjectPanel/AlgebraObjectPanelView.swift) | `headerHeight = 24`，`headerToContentSpacing = 12`，row 高度 `88/98`，`rowSpacing = 10`，`panelVerticalPadding = 28` | 基本固定 | 高：对象一多会迅速把面板撑高 |
| 对象区最小面板高度 | [`AlgebraObjectPanelView.swift`](/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/ObjectPanel/AlgebraObjectPanelView.swift) | `minimumPanelHeight = 150` | 是 | 中：对象少时还好，但短窗口下会和其他 overlay 抢空间 |

## 4. 短高窗口风险场景

| 场景 | 风险等级 | 可能表现 | 依据 | 建议 |
|---|---|---|---|---|
| iPhone 竖屏 | P1 | 输入 dock 和键盘会占掉很大一部分下半屏，画布可见高度明显缩小 | `keyboardPanelMinHeight = 216`，且 dock 是 bottom overlay | 后续考虑 compact-height 断点，优先减少键盘占高 |
| iPad 横屏 | P2 | 通常可用，但对象区 + 键盘同时打开时会显得拥挤 | overlay 叠加而非 reflow | 先保持现状，等短高问题统一处理 |
| iPad 竖屏 | P1 | 画布可视区域被底部 dock 与右侧对象区双向挤压 | `objectPanelMaxHeight` + `keyboardPanelMinHeight` | 后续需要显式 compact 策略 |
| iPad Stage Manager 短高窗口 | P0 / P1 | 最容易出现“输入栏、键盘、对象区互相挤压” | 底部 overlay + 固定键盘最小高度 + 对象区可变高 | 优先做一个短高断点或自动折叠键盘的方案 |
| macOS 小窗口 | P1 | 画布与工具栏、对象区、输入 dock 同时存在时，内容会变得很窄 | `WorkspaceLayoutMetrics` 仍按统一 overlay 逻辑计算 | 后续做 window-height 断点，而不是整体改布局 |
| 键盘展开 + 对象区打开 | P1 | 右侧对象区压缩画布宽度，底部键盘压缩画布高度 | 对象区与键盘均为 overlay | 优先为短高窗口限制对象区或键盘其中一个的默认展开 |
| 键盘展开 + 输入错误 banner 显示 | P2 | 错误 banner 继续挤压本来就紧张的编辑栏高度 | `commitErrorBanner(message:)` 直接插入 dock 内 | 后续可考虑把错误压成单行或与 diagnostics 合并布局 |
| 键盘展开 + 长公式横向滚动 | P2 | 高度不是主要问题，但编辑区会更“密” | `FormulaEditorView` 横向 `ScrollView` + 动态高度 | 保持当前逻辑，后续可做更窄的 compact editor |
| 多步构造提示条 + 输入 dock 同时存在 | P2 | 画布底部提示层级变多，视觉上更拥挤 | `WorkspaceInlineInputDock` 与构造提示都在 bottom overlay 路径上 | 后续考虑合并提示层或做短高时隐藏次要提示 |
| Home 返回 Workspace 后重新打开输入 dock | P2 | 主要风险是状态恢复后立刻展开键盘，短窗口里显得突兀 | `isInputPresented` / `isKeyboardPresented` 状态会直接恢复 | 后续可考虑恢复时优先不自动展开键盘 |

## 5. compact 布局候选策略

| 方案 | 改动范围 | 风险 | 用户收益 | 推荐程度 |
|---|---|---|---|---|
| 方案 A：短高窗口自动折叠数学键盘 | `WorkspaceView` / 输入 dock 条件展示 | 低到中 | 立刻释放约 216pt 的底部高度 | 高 |
| 方案 B：数学键盘 compact mode | `MathKeyboardView` 及其 metrics | 中 | 保留键盘可见性，同时降低占高 | 中 |
| 方案 C：输入 dock 半高模式 | `WorkspaceView` 内 dock 文案、banner、间距 | 低 | 让编辑栏在极短窗口更不“胖” | 中高 |
| 方案 D：画布 bottom inset 预留 | `WorkspaceView` 画布区域 inset 策略 | 中 | 让画布内容不被底部浮层压住 | 中 |
| 方案 E：Stage Manager 专用断点 | `WorkspaceLayoutMetrics` / overlay 判断 | 低到中 | 对短高窗口进行明确分流 | 高 |

综合来看，最值得优先做的是：

- 先判断“是否进入 compact-height”
- 再决定是否默认折叠键盘或压缩输入 dock
- 不建议一上来重写 `MathKeyboardView`

## 6. 最小可执行修复建议

基于当前代码结构，下一轮最小修复建议是：

1. 先只做一个“可用高度是否低于阈值”的判断 helper，挂在 `WorkspaceLayoutMetrics` 或 `WorkspaceView` 的只读派生属性上。
2. 进入 compact 条件后，优先让数学键盘默认折叠，而不是同时改输入逻辑和键盘布局。
3. 如果仍不够，再把 commit error banner、draft diagnostics、状态 chip 做进一步压缩。
4. 在真正改布局前，先用小窗口 / Stage Manager 做一次截图验证，确认最挤的是键盘而不是对象区。

这意味着：

- 不建议直接重构整个 Workspace。
- 不建议现在重写键盘。
- 不建议同时碰输入逻辑和布局。
- 更适合先做一个“compact 断点 + 默认折叠策略”的小步修复。

## 7. 是否建议下一轮直接修

建议下一轮直接修，但范围必须很小。

推荐任务名称：

`Plane Compact Height Entry Point`

如果要拆得更保守，也可以分成两个任务：

1. `Plane Compact Height Heuristic`
2. `Plane Default Keyboard Collapse`

前者先加高度判定，后者只接这个判定去折叠键盘。

