# Plane UI / Interaction Polish Audit

## 1. 审计摘要
- Plane MVP 的功能闭环已经稳定，但 UI / 交互层仍有一批明显的“顺手程度”问题，主要集中在输入栏状态表达、键盘占屏、对象区长公式展示、画布多步构造可见性、以及 Home 卡片预览解码和选项入口的发现性。
- 当前 Plane 工作区与首页都已经形成了可用的玻璃化视觉体系，`LiquidGlassPanel` / `GlassPanel` / card glass / keyboard glass 之间风格基本统一，但键盘层级和输入栏层级存在“重复玻璃板”的观感风险。
- 设备适配方面，`CoreHomeResponsiveContainer`、`PadCoreHomeLayout`、`PhoneCoreHomeLayout`、`FluidCoreHomeMetrics` 和 `WorkspaceView` 的布局已经能覆盖 iPad / iPhone / 可变窗口；不过 iPhone 横屏是由工程配置锁定的，不是运行时 UI 自己处理的。
- 本轮只读，不修改源码；以下结论基于具体代码路径、布局结构和现有项目配置。

## 2. 本轮是否修改源码：否

## 3. 输入栏 / 公式编辑区审计

### 结论
- 输入栏当前就是 Plane 的主编辑区，`WorkspaceInlineInputDock` 里同时承载预览、提交、取消、软键盘切换和数学键盘面板。
- create / edit 的输入状态都复用同一条 `WorkspaceState` + `FormulaInputState` + `FormulaEditorView` 链路，因此功能上是一致的，但 UI 上几乎没有显式区分。
- 输入栏目前是底部 overlay，并没有为内容区“预留固定空间”；在小窗口、窄高度、或键盘展开时，确实有压住画布 / 对象区的风险。
- 外接键盘与屏幕键盘在 UIKit 路径上共享同一套 `handleKeyboardAction`，但 macOS 侧没有看到同等级的键盘捕获层，`HardwareKeyboardCaptureView` 只在 `#if canImport(UIKit)` 下启用。

| 问题 | 涉及文件 | 当前表现 | 风险等级 | 建议处理 |
|---|---|---|---|---|
| create / edit 模式缺少明确的 UI 区分 | `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift:585-603`, `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceState.swift:1376-1504` | 输入栏顶部永远显示 `f(x)`，按钮布局也完全一致；用户只能靠内容和行为猜测当前是 create 还是 edit | P1 | 后续加一个轻量 mode chip 或标题状态，不要改输入逻辑 |
| 底部输入栏 / 键盘在窄窗口可能遮挡内容 | `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift:163-170`, `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift:561-577`, `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift:785-849` | 输入栏和键盘是底部 overlay，`MathKeyboardView` 还有固定最小高度 `216`；在 Stage Manager / 小屏 / 小窗口时容易挤压画布与对象区 | P1 | 后续做 compact-height 策略或折叠键盘，不要大改布局树 |
| 输入错误 / 提交失败反馈偏弱 | `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift:625-636`, `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceState.swift:1158-1192`, `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceState.swift:1465-1466` | parse / draft diagnostics 只在公式编辑条左下角小字显示；commit 失败只写入 `lastErrorMessage`，Workspace 根视图里没有明显 banner / toast | P1 | 后续把提交失败做成轻量可见状态，不要藏在 state 里 |
| 长公式 / 复杂模板在输入栏和对象区容易变小或截断 | `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/Keyboard/FormulaEditorView.swift:41-71`, `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/ObjectPanel/WorkspaceObjectRowView.swift:532-560` | 输入区是水平 ScrollView，这点是对的；但对象区的只读表达式会按 `0.58/0.62` 缩放，fallback 文本还会截断 | P2 | 后续考虑“展开查看”或更宽松的 row 高度策略 |
| macOS 侧未看到同级硬键盘捕获层 | `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/Input/HardwareKeyboardCaptureView.swift:3-29`, `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/Keyboard/FormulaEditorView.swift:62-69` | UIKit 有 `UIViewRepresentable` 键盘捕获；AppKit 路径没有同等级实现，是否由其他机制兜底待确认 | P1 / 待确认 | 如果 macOS 要作为一等平台，后续先只读确认事件路由，再补 AppKit 捕获 |

## 4. 数学键盘 UI 审计

### 结论
- 数学键盘的按钮尺寸、tab 切换和按压动画都很克制，`MathKeyboardView` 里大量 `.transaction { tx.animation = nil }`，按钮没有多余延迟动画。
- 按键尺寸基本稳定：tab 约 36 高，普通 key 约 40 高，整体间距 7pt 左右，风格统一。
- 主要问题不是“不能用”，而是键盘本身太像一个独立的大面板：`WorkspaceInlineInputDock` 已经有一层 `GlassPanel`，`MathKeyboardView` 自己又有 `KeyboardGlassPanel` 和 `KeyboardKeysBackplate`，在视觉上容易偏重。
- iPad 可变窗口下还能用，但短高窗口会更明显地压缩内容区；iPhone 竖屏目前受工程配置约束，横屏不走 runtime UI 逻辑。

| 问题 | 涉及文件 | 当前表现 | 风险等级 | 建议处理 |
|---|---|---|---|---|
| 键盘在短高度窗口里容易占掉过多空间 | `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/Keyboard/MathKeyboardView.swift:1-38`, `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/Keyboard/MathKeyboardView.swift:395-414`, `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift:573-577` | 216 的最小高度 + 输入栏预览 + 间距，短窗口里会明显挤压画布 | P1 | 后续为 compact height 做折叠、分页或更小键盘密度 |
| 键盘和输入栏的玻璃层级偏多，风格有轻微割裂 | `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift:664-674`, `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/Keyboard/MathKeyboardView.swift:13-146` | 输入栏外壳、键盘容器、键盘背板三层都在发光，视觉上略厚 | P2 | 后续收掉一层支持板，不要直接把所有玻璃都叠在一起 |
| 不同尺寸下仍是同一套 key 密度，缺少显式断点策略 | `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/Keyboard/MathKeyboardView.swift:219-291`, `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/Keyboard/MathKeyboardView.swift:395-414` | key / tab 的尺寸是固定值为主，缺少针对超窄、超短窗口的分支 | P2 | 后续按 size class 或短高断点再做一次视觉密度调整 |

## 5. 预览栏 / 提交栏审计

### 结论
- 预览栏和输入栏的职责是清楚的：`FormulaEditorView` 负责表达式编辑，预览和提示都在同一条输入 dock 中。
- 主要按钮只有 `keyboard`、`xmark`、`↵` 三个，布局短而清楚，点击区域也还算够大（`FormulaBarIconButton.hitSize = 36`）。
- `submit / cancel / delete / arrow` 这些语义按钮并没有在栏内做太多状态反馈；edit 模式时也没有明显的“正在编辑已有对象”视觉提示。
- 当前能看到输入诊断，但看不到一个同等显眼的“提交失败原因”区域，所以 preview 成功但 commit 失败时，用户解释链路不完整。

| 问题 | 涉及文件 | 当前表现 | 风险等级 | 建议处理 |
|---|---|---|---|---|
| 预览栏对 create/edit 状态缺少明确提示 | `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift:585-603`, `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceState.swift:1376-1499` | 只有静态 `f(x)` 牌子，没有“新建 / 编辑中”状态标签 | P1 | 后续加一个轻量状态 chip，或者根据 `formulaEditSession.mode` 做标题变化 |
| commit 失败缺少用户可见解释 | `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceState.swift:1248-1268`, `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift:625-636` | `lastErrorMessage` 主要停留在 state，输入条里只看得到 draft 诊断 | P1 | 后续补一个轻量 banner / toast，不要用大弹窗 |
| 图标按钮够大，但语义仍偏“工具”而不是“流程” | `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift:594-603`, `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift:820-829` | `keyboard / xmark / ↵` 的功能明确，但没有状态说明和次级帮助文字 | P2 | 后续可以只加一个简短 tooltip 或状态提示，不要重做按钮 |
| 诊断提示位置过低、字号偏小 | `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift:625-636` | 诊断只占底部一条细字行，复杂公式时不够醒目 | P2 | 保持轻量，但把 severity 区分做得更可见一点 |

## 6. 对象区 / ObjectPanel 审计

### 结论
- 对象区已经比早期顺很多：函数对象优先走 `FormulaEditorView` 的只读渲染，回退顺序是 `displayText -> originalLatex -> rawInput -> name`。
- 几何对象的 secondary 文本来自 `GeometryDependencyPresentation`，会优先给出关系描述、状态、长度 / 半径等信息，已经比纯类型名友好得多。
- 选中态是明确的：行背景、边框、左侧可见点和右上角 badge 都会响应；删除也可从行菜单进入。
- 当前主要问题是“长公式”和“大对象列表”两个维度：前者容易缩得太小，后者只有滚动，没有搜索 / 分组 / 过滤。

| 问题 | 涉及文件 | 当前表现 | 风险等级 | 建议处理 |
|---|---|---|---|---|
| 函数行的只读表达式缩放偏小 | `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/ObjectPanel/WorkspaceObjectRowView.swift:51-57`, `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/ObjectPanel/WorkspaceObjectRowView.swift:532-560` | 有 AST 就渲染，但 `scaleEffect(0.58/0.62)` 会让长公式变得很小 | P2 | 后续考虑“展开查看”或更大的行高，不要在 row 里继续挤压 |
| Inspector 和对象列表的展示语义不完全一致 | `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/Inspector/ObjectInspectorPanel.swift:95-117`, `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/ObjectPanel/WorkspaceObjectRowView.swift:288-316` | Inspector 主字段只显示 `displayText`，列表则优先渲染公式视图并做 fallback | P2 | 后续统一“展示字段优先级”，但不用马上重构渲染组件 |
| 大量对象时缺少搜索 / 过滤 / 分组 | `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/ObjectPanel/AlgebraObjectPanelView.swift:12-84` | 面板可滚动，但没有搜索、过滤或折叠分组 | P2 | 后续先加搜索或按类型分组，别先上大一统对象管理面板 |
| 删除入口隐藏在更多菜单里，发现性一般 | `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/ObjectPanel/WorkspaceObjectRowView.swift:109-186` | 能删，但要先打开 row 菜单，发现性不如直接按钮 | P2 | 后续若频繁被误用，可考虑给对象区提供更明显的批量删除入口 |
| 几何摘要已经可读，但仍依赖行内两层信息 | `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/ObjectPanel/GeometryDependencyPresentation.swift:23-123` | 关系和状态是分行展示的，信息完整但略长 | P2 | 后续可以做更短的摘要模板，不必立刻改逻辑 |

## 7. Plane 画布手势审计

### 结论
- 画布手势链路已经比较完整：平移、缩放、点击选择、点拖拽、delete 工具、以及线 / 圆 / 圆弧 / 交点 / 平行 / 垂线等多步构造都能跑通。
- `select` 工具下，点拖拽和画布平移已经做了分流：命中点时拖点，不命中点时平移画布。
- `delete` 工具点击命中对象就删除，点空白就清空选择，不会报错。
- 目前最大的交互缺口不是“能不能做”，而是“用户是否看得出自己正处在哪一步”：多步构造主要靠预览对象本身，没有明显的步骤提示或取消按钮。

| 问题 | 涉及文件 | 当前表现 | 风险等级 | 建议处理 |
|---|---|---|---|---|
| 画布命中阈值固定，未按设备 / 指针类型细分 | `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CalculatorModules/Plane/Services/PlaneHitTestService.swift:6-35`, `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CalculatorModules/Plane/Services/PlaneHitTestService.swift:38-181` | 点和对象命中都靠固定 `12pt`，没有区分鼠标 / 触控 / Pencil | P2 | 后续先只读确认实际误触，再决定是否细化阈值 |
| 多步构造缺少显式“取消当前步骤”入口 | `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CalculatorModules/Plane/Views/PlaneCanvasView.swift:173-537`, `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CalculatorModules/Plane/Interaction/PlaneInteractionState.swift:5-24` | 通过预览能看出正在构造，但没有明显的 cancel/back UI | P1 | 后续加一个轻量取消入口或状态提示，不要重写构造机 |
| 构造预览是主要状态提示，但没有步骤数或说明文案 | `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CalculatorModules/Plane/Views/PlaneCanvasView.swift:309-537`, `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CalculatorModules/Plane/Views/PlaneObjectRendererView.swift:27-28` | segment / line / ray / circle / arc / intersection 都能预览，但用户必须自己理解当前模式 | P2 | 后续可以只加一个小型构造提示条，不碰命令逻辑 |
| 点拖拽与画布平移分流合理，但仍需要在极小屏下复核 | `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CalculatorModules/Plane/Views/PlaneCanvasView.swift:70-119`, `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CalculatorModules/Plane/Views/PlaneCanvasView.swift:268-307` | 逻辑上已分流，但触控板 / 鼠标 / 手指的手感还要靠实机再看 | P2 | 进入 polish 阶段前先做一次设备验收，不要直接大改 |

## 8. 首页 / 文件卡片 UI 审计

### 结论
- 首页卡片已经是可用的“最近文件入口”：`ProjectCardView` 显示预览图、标题、模块名、修改时间；`ProjectThumbnailView` 会优先读磁盘 `preview.png`，缺失时退回到风格化形状。
- Home 已经按设备分流：`CoreHomeResponsiveContainer` 会在 `PadCoreHomeLayout` 与 `PhoneCoreHomeLayout` 之间切换，且 `FluidCoreHomeMetrics` / `CoreHomeLayoutMetrics` 都在做尺寸自适应。
- 首页的选择、搜索、删除、移动入口都已经有了，但多数入口集中在“选择模式”里，平时可见性一般。
- `ProjectThumbnailView` 现在是同步从磁盘读图，卡片多时存在主线程解码风险；另外 `scaledToFill()` 可能会裁掉一部分缩略图边缘，但这和 preview 图本身的内容适配有关，当前不是功能 bug。

| 问题 | 涉及文件 | 当前表现 | 风险等级 | 建议处理 |
|---|---|---|---|---|
| preview 图同步解码可能拖慢首页 | `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CoreHome/ProjectThumbnailView.swift:21-38`, `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CoreHome/ProjectThumbnailView.swift:57-67` | 每张卡片在 body 里同步 `UIImage/NSImage(contentsOf:)` 读图 | P1 | 后续做缓存 / 延迟解码 / 预热，不要改 preview 链路本身 |
| 缺失 preview 时 fallback 虽可用，但更偏占位而非内容摘要 | `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CoreHome/ProjectThumbnailView.swift:28-38` | fallback 是风格化图形，不是内容级缩略图 | P2 | 目前可接受；后续可在没有 preview.png 时加更聪明的文档摘要图 |
| 首页的选择 / 删除 / 移动入口主要藏在选择模式里 | `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CoreHome/GalleryDrawerView.swift:236-360`, `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CoreHome/Layout/PhoneCoreHomeLayout.swift:232-356` | 能管理，但要先进入选择模式；对新用户来说可发现性一般 | P2 | 后续可加更明确的管理入口或快捷说明 |
| preview 卡片是 `scaledToFill`，有轻微裁切风险 | `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CoreHome/ProjectThumbnailView.swift:23-38` | 图卡会填满固定比例，过宽 / 过高的预览会被裁边 | P2 | 目前接受；若后续 preview 内容更丰富，再考虑统一留白策略 |

## 9. 响应式布局 / 设备适配审计

### 结论
- iPhone 横屏是通过工程配置禁用的，而不是 UI 里动态判断出来的：`project.pbxproj` 明确设置了 iPhone 仅支持 portrait，iPad 则允许四个方向。
- iPad / Stage Manager / 可变窗口适配的主机制已经有了：Home 通过 `FluidCoreHomeMetrics` 和 `PadCoreHomeLayout`，Workspace 通过 `WorkspaceLayoutMetrics`、`WorkspaceView` 的 `GeometryReader` 和 safe area 计算来响应尺寸变化。
- 小窗口下 Home 会切到 `ScrollView`，Workspace 的对象面板宽度也有上下限并可拖拽调节，这些都说明基本适配已经不是问题。
- 真正还要留意的是：输入栏 / 键盘 / 对象面板这些“悬浮式 UI”在短高窗口里很容易一起挤到内容上。

| 问题 | 涉及文件 | 当前表现 | 风险等级 | 建议处理 |
|---|---|---|---|---|
| iPhone 横屏是工程级禁用，不是运行时 UI 处理 | `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica.xcodeproj/project.pbxproj:525-526`, `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica.xcodeproj/project.pbxproj:640-641` | iPhone 只开 portrait；iPad 支持 portrait / upsideDown / landscapeLeft / landscapeRight | 说明项，非 bug | 文档里明确写死，后续若要 iPhone 横屏，先改工程配置再谈 UI |
| 小窗口下悬浮输入层和键盘会挤压内容 | `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift:27-172`, `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift:561-849` | 画布、对象区、输入条、键盘都在同一层级里叠放，没做显式内容重排 | P1 | 后续按高度断点做更小的 dock 或自动折叠 |
| macOS / UIKit 键盘输入路径不完全对称 | `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/Input/HardwareKeyboardCaptureView.swift:3-29`, `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/Keyboard/FormulaEditorView.swift:62-69` | UIKit 有键盘捕获；AppKit 未见对等桥接 | P1 / 待确认 | 后续先确认 macOS 目标是否需要一等硬键盘体验，再补最小桥接 |
| 断点策略分散在多个文件里 | `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CoreHome/Layout/CoreHomeLayoutProfile.swift:1-77`, `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CoreHome/Layout/FluidCoreHomeMetrics.swift:1-170`, `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift:27-172` | Home 和 Workspace 都在各自做尺寸判断，规则是对的，但不够集中 | P2 | 后续可以先只读整理断点表，再决定是否抽公共尺寸策略 |

## 10. 视觉风格一致性审计

### 结论
- 整体视觉语言是一致的：圆角、玻璃、薄材质、蓝色强调、深浅色双套都已经贯通到 Home、Workspace、对象区、工具栏和键盘。
- 目前的问题不是“风格完全不统一”，而是 token 和 opacity 过于分散，很多地方都是本地常量而不是统一主题入口。
- 旧视觉残留主要体现在“多层玻璃叠加”和“按钮风格差异”：键盘、输入栏、卡片、对象行都在叠不同层的 panel / material / stroke / shadow。

| 问题 | 涉及文件 | 当前表现 | 风险等级 | 建议处理 |
|---|---|---|---|---|
| 视觉 token 分散在多个局部常量里 | `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/Keyboard/MathKeyboardView.swift:395-414`, `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/ObjectPanel/WorkspaceObjectRowView.swift:453-462`, `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift:846-849`, `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CoreHome/Layout/FluidCoreHomeMetrics.swift:1-170` | 每个模块都在定义自己的 opacity / radius / spacing，风格一致但来源碎 | P2 | 后续若要继续 polish，先建立一张 UI token 清单，再决定是否收口 |
| 键盘 / 预览栏 / 卡片之间存在轻微的玻璃层级割裂 | `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift:664-674`, `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/Keyboard/MathKeyboardView.swift:13-146`, `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CoreHome/ProjectCardView.swift:145-165` | 都是玻璃，但厚度、边框、阴影与背板层级不完全统一 | P2 | 后续只收一个“支持板”层，不要把所有玻璃都继续加厚 |
| 深浅色对比度整体可用，但次级文字有时偏轻 | `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/ObjectPanel/WorkspaceObjectRowView.swift:63-67`, `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CoreHome/ProjectCardView.swift:65-73`, `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CoreHome/GalleryDrawerView.swift:178-184` | 次级信息大多用 secondary / opacity，视觉干净但有些轻 | P2 | 后续可只对高信息密度场景做轻微加粗，不改整体风格 |
| 背景与前景风格是一套，但没有统一的 design token 文档 | `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CoreHome/CoreHeroBackgroundView.swift`, `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/Toolbar/ToolGroupCapsuleView.swift:58-66` | 视觉方向统一，代码入口分散 | P3 | 后续如果要长期维护，值得先做一份 Plane UI polish checklist |

## 11. 后续修复任务拆分

| 顺序 | 任务 | 优先级 | 建议范围 | 是否适合 Codex 直接修 |
|---|---|---|---|---|
| 1 | 给输入栏加一个轻量的 create/edit 状态提示 | P1 | `WorkspaceView` / `WorkspaceState`，只影响输入 dock 标题和状态文案 | 是 |
| 2 | 给 Workspace 的提交失败补一个轻量可见 banner / toast | P1 | `WorkspaceView` / `WorkspaceState`，不要改命令链 | 是，但先只读确认现有 toast 入口 |
| 3 | 为短高窗口做输入栏 / 键盘折叠或 compact 布局 | P1 | `WorkspaceView` / `MathKeyboardView`，只收 UI 密度，不动输入逻辑 | 否，先只读确认断点和高度预算 |
| 4 | 给多步几何构造加显式取消 / 状态提示 | P1 | `PlaneCanvasView` / `PlaneInteractionState`，只补 UX，不改构造命令 | 否，先只读确认现有交互语义 |
| 5 | 让硬件键盘在 macOS 目标也有对等输入捕获 | P1 / 待确认 | `HardwareKeyboardCaptureView` 周边，先确认平台目标和事件路由 | 否，先只读确认 macOS 需求 |
| 6 | 调整对象行长公式的展示密度 | P2 | `WorkspaceObjectRowView` / `ObjectInspectorPanel`，只改展示不改表达式来源 | 是 |
| 7 | 给对象区加搜索 / 过滤 / 分组 | P2 | `AlgebraObjectPanelView` / `WorkspaceState`，只加管理入口，不碰对象模型 | 否，先只读确认对象规模与使用频率 |
| 8 | 收敛键盘 / 输入栏 / 卡片的玻璃层级 | P2 | `WorkspaceView` / `MathKeyboardView` / `ProjectCardView` / `ThemeKit`，只做视觉减法 | 否，先只读确认当前哪一层最重 |
| 9 | 优化 Home preview.png 的同步读图成本 | P1 / P2 | `ProjectThumbnailView`，只做缓存 / 延迟解码，不改 preview 生成链路 | 是，但先确认卡片数量和卡顿场景 |
| 10 | 建一张 UI token / 断点清单，作为后续 polish 的唯一入口 | P3 | Docs 先行，不动逻辑代码 | 是，优先文档化 |

## 12. 是否建议进入 UI polish 阶段
- 建议进入，但要按 P1 / P2 / P3 分层推进，不要做“大一统 UI 重构”。
- 现在最值得先修的是：输入栏状态表达、提交失败可见性、短高窗口下的键盘/输入栏布局、以及多步构造的取消与提示。
- 对象区、首页卡片和视觉 token 的工作可以并行排队，但最好先做只读确认，再决定是否动代码。

