# eMathica Current Architecture Audit

审计范围：只读架构审计。

本轮是否修改源码：否。

本轮仅新增审计文档：`Docs/EMathicaCurrentArchitectureAudit.md`。

## 1. 审计摘要

当前代码已经不是“空壳项目”，而是一个已经把 `Plane` 主链路、首页最近项目、文档包保存/加载、`preview.png` 缩略图、以及 `MathCore` 的 AST/CAS/Sampling 基础全部接起来的工程。

但从边界上看，`WorkspaceKit` 仍然残留了部分 `Plane` 专属逻辑，`Plane` 内部也还有命名规则不一致、预览策略分层不完全统一、以及若干 legacy fallback。`Space` 则明显还停留在 v0.1 骨架阶段，已有画布、命令、命中测试、线框渲染，但没有独立的文档模型、Inspector、Snapping、Preview 模块。

最重要的结论是：

- `Plane` 的 MVP 主链路已经基本可跑。
- `Plane` 当前最大的风险不是“缺功能”，而是“路径分叉”和“命名不一致”。
- 首页缩略图链路已经存在，而且是离屏生成 + 磁盘读取，不需要在首页重算函数。
- `MathCore` 的类型、分类、评估、采样链路已经存在，且已被 `Plane` 语义预览和渲染消费。
- `Space` 不是完整产品形态，更像可运行骨架。

## 2. 当前完成度判断

### Plane

Plane 已形成以下闭环：

- 打开工作区
- 打开输入
- 实时草稿预览
- 提交函数/图形对象
- 创建点、线段、圆、圆弧、直线、射线、交点、中点、平行线、垂线
- 选择对象
- 点拖拽编辑
- 删除对象
- 保存项目
- 生成并读取 `preview.png`
- 重新打开项目

当前未完全收口的部分主要是：

- 函数命名规则存在双路径
- 几何命名规则存在“计数式重复”风险
- `WorkspaceKit` 仍残留 Plane/Space 专属信息
- 语义预览对 `explicitY` / `explicitX` 仍然保留 legacy 路径
- 首页缩略图取景范围固定，不是内容自适应

### Space

Space 已有可运行骨架：

- `SpaceWorkspaceModuleProvider`
- `SpaceCommandHandler`
- `SpaceCanvasView`
- `SpaceGeometryResolver`
- `SpaceHitTestService`
- `SpaceWireframeRenderer`

但还没有形成完整产品闭环。缺的不是一点点“修 bug”，而是模块层级本身仍未补齐。

### MathCore / DocumentSystem / CoreHome

- `DocumentSystem` 的持久化、包结构、`preview.png`、最近项目列表已经存在。
- `CoreHome` 已能显示 preview 图片，且不会在首页重新计算图形。
- `MathCore` 的 AST、CAS、GraphIntent、Sampling 已经完整搭出基础链路。

## 3. 目录和模块边界审计

| 文件路径 | 当前职责 | 所在文件夹是否合理 | 问题 | 建议归属 |
|---|---|---|---|---|
| `/Users/night_creek/开发/eMathica/eMathica/eMathica/App/AppRootView.swift:4-20` | App 路由根视图，连接 Home / Workspace | 合理 | 未见明显问题 | `App` |
| `/Users/night_creek/开发/eMathica/eMathica/eMathica/CoreHome/CoreHomeView.swift:3-31` | 首页入口与新建项目弹窗 | 合理 | `onSecondaryAction` 仍是 TODO 注释 | `CoreHome` |
| `/Users/night_creek/开发/eMathica/eMathica/eMathica/CoreHome/Preview/ProjectPreviewRenderer.swift:76-133,349-411` | 离屏生成 `preview.png`，平面/空间分支渲染 | 合理 | 平面缩略图取景仍是固定 world bounds | `CoreHome/Preview` |
| `/Users/night_creek/开发/eMathica/eMathica/eMathica/CoreHome/ProjectThumbnailView.swift:21-39` | 首页卡片读取 `preview.png` 或回退形状 | 合理 | 缺少内容自适应缩略图信息 | `CoreHome` |
| `/Users/night_creek/开发/eMathica/eMathica/eMathica/CoreHome/ProjectCardView.swift:46-118` | 单个项目卡片 UI | 合理 | 预览图片没有内容级别的来源说明 | `CoreHome` |
| `/Users/night_creek/开发/eMathica/eMathica/eMathica/CoreHome/RecentProjectsGridView.swift:21-49` | 最近项目网格 | 合理 | 只负责透传 previewURL，不做内容推导 | `CoreHome` |
| `/Users/night_creek/开发/eMathica/eMathica/eMathica/CoreHome/CoreHomeState.swift:150-218` | 最近项目读取、创建、保存、重命名 | 合理 | `makeRecentProject` 对 `thumbnailKindRawValue` 固定为 `formulaNotes` | `CoreHome` |
| `/Users/night_creek/开发/eMathica/eMathica/eMathica/DocumentSystem/IO/LocalProjectStore.swift:19-217` | `.emathica` 包保存/读取/预览写回 | 合理 | `updatePreviewIfPossible` 是同步离屏渲染，存在主线程负担待确认 | `DocumentSystem/IO` |
| `/Users/night_creek/开发/eMathica/eMathica/eMathica/DocumentSystem/EMathicaDocument.swift:5-126` | 统一文档 mutation API | 合理 | 当前依赖调用方必须走 `apply(_:)`，否则无法统一历史/撤销 | `DocumentSystem` |
| `/Users/night_creek/开发/eMathica/eMathica/eMathica/DocumentSystem/Package/EMathicaPackageLayout.swift:3-25` | `.emathica` 包结构路径 | 合理 | 只有 `metadata.json`、`document.json`、`preview.png` 三件套 | `DocumentSystem/Package` |
| `/Users/night_creek/开发/eMathica/eMathica/eMathica/DocumentSystem/ProjectMetadata.swift:3-32` | 元数据结构，含 `previewImageName` | 合理 | 预览名存在但当前读取链主要依赖 `previewURL` | `DocumentSystem` |
| `/Users/night_creek/开发/eMathica/eMathica/eMathica/DocumentSystem/RecentProject.swift:3-29` | 首页最近项目模型 | 合理 | 缩略图类型是静态枚举字符串 | `DocumentSystem` |
| `/Users/night_creek/开发/eMathica/eMathica/eMathica/DocumentSystem/ProjectFileManagerPlaceholder.swift:3-4` | 文件管理占位 | 不合理 | 明确是遗留占位 | 保留但应视为废弃占位 |
| `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift:20-280` | 工作区外壳、工具栏、对象面板、输入栏 | 基本合理 | 仍直接知道 Plane/Space 相关上下文 | `WorkspaceKit` |
| `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceState.swift:10-1491` | 工作区状态机、输入、提交、预览、编辑 | 边界偏宽 | 残留 `SpaceWorkPlane`、Plane 命名、Plane 编辑/预览策略 | `WorkspaceKit` |
| `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceModuleProviding.swift:17-64` | 模块桥接协议，含 canvas / draft / build / services | 基本合理 | `WorkspaceCanvasContext` 直接暴露 `SpaceCameraState` / `SpaceWorkPlane` | `WorkspaceKit` |
| `/Users/night_creek/开发/eMathica/eMathica/eMathica/CalculatorModules/Plane/PlaneWorkspaceModuleProvider.swift:7-63` | Plane 模块提供器 | 合理 | `PlaneInputCanonicalizer` 仍是 identity | `CalculatorModules/Plane` |
| `/Users/night_creek/开发/eMathica/eMathica/eMathica/CalculatorModules/Plane/Services/PlaneInputCanonicalizer.swift:4-18` | Plane 输入规范化适配器 | 合理 | 逻辑尚未迁移，仍是 TODO | `CalculatorModules/Plane/Services` |
| `/Users/night_creek/开发/eMathica/eMathica/eMathica/CalculatorModules/Space/SpaceWorkspaceModuleProvider.swift:7-55` | Space 模块提供器 | 合理但未完成 | `makeDraftMathObject == nil`、`semanticIntentAdapter == nil` | `CalculatorModules/Space` |
| `/Users/night_creek/开发/eMathica/eMathica/eMathica/CalculatorModules/Space/Views/SpaceCalculatorPlaceholderView.swift` | Space 占位视图 | 不合理 | 明确是阶段性占位 | 保留但应视为历史遗留 |
| `/Users/night_creek/开发/eMathica/eMathica/eMathica/CalculatorModules/Data/Views/DataPlaceholderView.swift` | Data 占位视图 | 合理但未完成 | 仅占位 | `CalculatorModules/Data` |
| `/Users/night_creek/开发/eMathica/eMathica/eMathica/CalculatorModules/Modeling/Views/ModelingPlaceholderView.swift` | Modeling 占位视图 | 合理但未完成 | 仅占位 | `CalculatorModules/Modeling` |
| `/Users/night_creek/开发/eMathica/eMathica/eMathica/CalculatorModules/Music/Views/MusicPlaceholderView.swift` | Music 占位视图 | 合理但未完成 | 仅占位 | `CalculatorModules/Music` |
| `/Users/night_creek/开发/eMathica/eMathica/eMathica/CalculatorModules/Notes/Views/NotesPlaceholderView.swift` | Notes 占位视图 | 合理但未完成 | 仅占位 | `CalculatorModules/Notes` |
| `/Users/night_creek/开发/eMathica/eMathica/eMathica/PluginSystem/PluginPlaceholder.swift:3-4` | 插件系统占位 | 不合理 | 只有 TODO，没有实装管线 | `PluginSystem` |

结论：

- `App`、`CoreHome`、`DocumentSystem`、`CalculatorModules/Plane` 的目录命名与功能基本匹配。
- `WorkspaceKit`、`MathCore` 是真正的共享层，但当前 `WorkspaceKit` 仍残留具体模块知识。
- `PluginSystem` 和 `Space` 的一部分文件仍属于明确占位。
- 没有发现一组“完全重复、同义功能并存”的源码文件，但发现了多处 legacy / placeholder / archived 路径。

## 4. Workspace 和 CalculatorModules 解耦审计

### 当前主调用链

```mermaid
flowchart LR
    A[AppRootView] --> B[CalculatorModuleRegistry.moduleProvider(for:)]
    B --> C[WorkspaceView]
    C --> D[WorkspaceState.dispatch(_:)]
    D --> E[ModuleCommandHandler<br/>PlaneCommandHandler / SpaceCommandHandler]
    E --> F[DocumentCommand]
    F --> G[EMathicaDocument.apply(_:)]
    G --> H[LocalProjectStore.saveProject(_:)]
    H --> I[ProjectPreviewRenderer.renderPNGData(for:)]
    I --> J[preview.png]
    J --> K[ProjectThumbnailView]

    C --> L[WorkspaceCanvasContext]
    L --> M[PlaneCanvasView / SpaceCanvasView / Default placeholder]
    M --> D
```

### 可疑耦合点

| 位置 | 证据 | 判断 |
|---|---|---|
| `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceCanvasContext` | `spaceCameraState`、`spaceWorkPlane` 直接暴露给所有模块 | Workspace 仍知道 Space 专属类型 |
| `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceState.swift:39-40` | `activeSpaceWorkPlane` 是 WorkspaceState 成员 | Workspace 仍保留 Space 状态 |
| `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceState.swift:1294-1300` | `isFormulaEditableObject` 直接枚举 `.function/.point/.circle/.parameter` | Workspace 仍知道 Plane 对象类型 |
| `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceState.swift:1439-1460` | 提交创建时自己算 `f_\(ordinaryCount + 1)` | 命名规则与 `PlaneCommandHandler` 重叠 |
| `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceState.swift:1661-1679` | 存在 `canonicalPlaneCommitInput(from:)` 的死代码 | Plane 逻辑未完全迁出 |
| `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift:275-279` | `.moduleSpecific(id:payload:"TODO")` | 通用层仍留 placeholder 路由 |

### 职责边界判断

- `WorkspaceView` 现在更像壳层，职责主要是布局、面板、路由和状态托管。
- `WorkspaceState` 已经不是纯“工作区壳”，它仍承担一部分 Plane 级业务规则。
- `PlaneWorkspaceModuleProvider` 已经承担了 canvas、draft、expression、adapter、canonicalizer 这些模块职责，方向是对的。
- `PlaneCommandHandler` 已承担大部分对象创建和变换逻辑，但命名规则与 `WorkspaceState` 并未统一。

### 是否需要后续拆分

需要。优先级如下：

1. P0：统一普通函数命名路径。
2. P1：把 `WorkspaceState` 中剩余的 Plane 专属规则迁到 Plane 适配层。
3. P1：消除 `canonicalPlaneCommitInput` 死代码和 placeholder 路由。
4. P2：如果未来要严格解耦 Space，再考虑把 `spaceWorkPlane` 从通用 canvas context 中移出。

## 5. 平面计算器工具链审计

### 工具链总览

| 工具 | 用户入口 | 创建路径 | 预览路径 | 命中测试 | 渲染路径 | 编辑路径 | 风险 |
|---|---|---|---|---|---|---|---|
| 选择工具 | `PlaneToolProvider.swift:7-24` 的 `plane.select` | 不创建对象 | 无 | `PlaneHitTestService.hitTestObject` / `hitTestPoint` | `PlaneObjectRendererView` | 选择后对象面板 / 拖点 / 编辑输入 | 选择、平移、拖点三种交互在同一画布里并存，复杂度高 |
| 点工具 | `PlaneToolProvider.swift:25-40` 的 `plane.point` | `PlaneCanvasView.swift:173-182` -> `WorkspaceCommand.createPoint` -> `PlaneCommandHandler.swift:133-147` | 无专门草稿对象 | 选中/拖点时会命中点 | `PlaneObjectRendererView.drawPoint` | `PlaneCommandHandler.updateObjectPosition` 仅允许非依赖点 | 仅支持点的静态/直接拖拽，动态点需通过依赖链 |
| 线段工具 | `PlaneToolProvider.swift:25-40` 的 `plane.segment` | `PlaneCanvasView.swift:190-196` -> `dispatchSegmentCreation` -> `moduleSpecific("plane.createSegmentWithOptionalPoints")` -> `PlaneCommandHandler.swift:429-504` | `PlaneCanvasView.swift:302-319` + `PlaneObjectRendererView.drawPreview` | `PlaneHitTestService.hitTestObject` / `hitTestMidpointTarget` | `PlaneObjectRendererView.drawGeometryCircle/drawSegment` | 通过对象面板或命令层间接编辑；没有单独线段编辑器 | 创建时依赖 optional points / JSON payload，失败会 fallback 到直接创建 |
| 圆工具 | `PlaneToolProvider.swift:71-82` 的 `plane.circle` | `PlaneCanvasView.swift:223-229` -> `dispatchCircleCreation` -> `moduleSpecific("plane.createCircleWithOptionalCenter")` -> `PlaneCommandHandler.swift:506-599` | `PlaneCanvasView.swift:321-340` + `PlaneObjectRendererView.drawPreview` | 圆命中测试在 `PlaneHitTestService` 和 `PlaneGeometryResolver.circleGeometry` | `PlaneObjectRendererView.drawGeometryCircle` / semantic path | 通过对象面板 / geometry dependency 更新 | 预览链路和几何依赖链是双路径，需持续一致性维护 |
| 圆弧工具 | `PlaneToolProvider.swift:77-82` 的 `plane.arc` | `PlaneCanvasView.swift:231-237` -> `dispatchArcCreation` -> `moduleSpecific("plane.createArc")` -> `PlaneCommandHandler.swift:601-665` | `PlaneCanvasView.swift:343-372` + `PlaneObjectRendererView.drawPreview` | `PlaneHitTestService.hitTestObject` / `PlaneGeometryResolver.arcGeometry` | `PlaneObjectRendererView.drawGeometryArc` | 无独立弧编辑器；依赖几何对象链 | 三点共线时会直接失败，属于正常约束 |
| 函数工具 / 函数输入 | `PlaneToolProvider.swift:91-106` 的 `plane.function` | `WorkspaceView.swift:251-264` 打开输入；`WorkspaceState.commitFormulaEditing()` 创建对象 | `WorkspaceState.updateDraftPreviewNow()` -> `PlaneDraftPreviewService.makeDraft()` | `PlaneHitTestService.algebraObject` / `PlaneObjectRendererView.semanticPlotSegments` | `PlaneObjectRendererView.drawAlgebraObject` + `drawDraftPreview` | `loadExpressionForEditing` / `submitEditingObject` | 命名路径与 preview policy 尚未完全统一 |
| 删除工具 | 当前没有显式 `plane.delete` 工具 | 删除由对象面板 / 菜单 / 选择后命令触发 | 无 | 命中后通过 `deleteSelectedObjects` / `deleteObject` | `EMathicaDocument.apply(.deleteObject/.deleteObjects)` | 通过对象面板或命令链删除 | 如果 MVP 需要“显式删除工具”，当前工具栏没有 |
| 拖拽编辑 | `PlaneCanvasView.pointDragGesture` | 不创建对象 | 无 | `PlaneHitTestService.hitTestPoint` | `PlaneObjectRendererView` 随文档更新重绘 | `PlaneCanvasView.swift:261-300` -> `WorkspaceCommand.updateObjectPosition` -> `PlaneCommandHandler.swift:93-109` | 仅点可拖，线/圆/弧没有直接拖编辑器 |

### 结论

- 点工具和线段工具已经比较稳定。
- 圆工具和弧工具都已经复用了预览、渲染和命令链。
- 函数输入链路与几何对象链路已经分离，但都依赖 `WorkspaceState` 的输入状态机。
- 没有发现任何工具直接修改 `document.objects`，实际落点都走了 `DocumentCommand` / `document.apply(_:)`。
- 当前唯一明显的“工具缺口”是显式删除工具按钮，如果产品定义要求它存在，那它还没进入工具栏。

## 6. 函数输入和实时预览审计

### create 函数输入链路

`WorkspaceView.swift:251-264`
→ `WorkspaceState.dispatch(.openInput(mode: .expression))`
→ `WorkspaceState.startFormulaEditing(openKeyboard: true)`（`WorkspaceState.swift:1363-1397`）
→ `makeSession(mode: .createNew, ...)`
→ `FormulaInputState.syncDerivedStrings(context:)`
→ `WorkspaceState.updateInputText(...)` / 键盘输入
→ `WorkspaceState.scheduleDraftPreviewUpdate()` 或 `updateDraftPreviewNow()`
→ `WorkspaceState.updateDraftPreviewNow()`（`WorkspaceState.swift:1162-1186`）
→ `PlaneWorkspaceModuleProvider.makeDraftMathObject(...)`
→ `PlaneDraftPreviewService.makeDraft(...)`
→ `PlaneObjectRendererView.drawDraftPreview(...)`
→ `commitFormulaEditing()`
→ `moduleProvider.inputCanonicalizer.canonicalize(...)`
→ `moduleProvider.buildExpression(...)`
→ `document.apply(.addObject(...))`

### edit 函数输入链路

`WorkspaceState.loadExpressionForEditing(_:)`（`WorkspaceState.swift:1332-1345`）
→ `inputState(from:isEditing:)`
→ `makeSession(mode: .editExisting, ...)`
→ `FormulaInputState.syncDerivedStrings(context:)`
→ `WorkspaceState.updateInputText(...)`
→ `scheduleDraftPreviewUpdate()`
→ `moduleProvider.makeDraftMathObject(...)`
→ `PlaneDraftPreviewService.makeDraft(...)`
→ `submitEditingObject(objectID:)`（`WorkspaceState.swift:1249-1292`）
→ `moduleProvider.inputCanonicalizer.canonicalize(...)`
→ `moduleProvider.buildExpression(...)`
→ `document.apply(.updateObject(...))`

### 两条链路的共同点与差异

| 项 | create | edit |
|---|---|---|
| 预览生成 | 共用 `PlaneDraftPreviewService.makeDraft` | 共用 `PlaneDraftPreviewService.makeDraft` |
| 输入状态 | `makeSession(mode:.createNew)` | `makeSession(mode:.editExisting)` |
| 提交行为 | 新建 `MathObject` 并 `addObject` | 更新已有对象并 `updateObject` |
| canonicalize/buildExpression | 都走 `moduleProvider.inputCanonicalizer` 和 `moduleProvider.buildExpression` | 同样走这条链 |
| 结果对象 | 新函数对象 | 原对象的 expression / AST metadata 被覆盖 |

### 当前断点风险

| 风险点 | 证据 | 影响 |
|---|---|---|
| `isInputPresented` 参与预览 guard | `WorkspaceState.swift:1151-1159` | 输入未打开时不会触发草稿更新 |
| 空输入直接短路 | `WorkspaceState.swift:1162-1167` | 草稿会被清空，属于预期但要注意 |
| edit / create 的输入启动路径不同 | `WorkspaceState.swift:1363-1397` | 需要持续保证两条路径的行为一致 |
| 预览失败回退到 lastValid | `PlaneDraftPreviewService.swift:105-110`、`PlaneObjectRendererView.swift:523-545` | 用户不会看到空白，但也可能掩盖某些采样问题 |

### 预览失败与 fallback

是有 fallback 的：

- `PlaneDraftPreviewService` 会附带 parse / sampling diagnostics。
- 当当前预览采样为空时，会退回 `lastValidPreviewSamples`。
- 语义 intent 解析失败时，`PlaneFallbackSamplingService` 也会写 diagnostics。

### 对象区显示什么

待确认。

本轮没有直接读到对象面板源码，所以不能断言它显示的是：

- 原始 LaTeX
- 还是 `displayText`
- 还是 `originalLatex`

但从当前写入链路看，`WorkspaceState.attachStructuredInputMetadataToSelectedObject()` 会同时写入 `sourceExpression`、`computeExpression`、`editorASTData`、`originalLatex`，所以对象面板具备显示多种文本来源的条件。

## 7. 普通函数命名系统审计

### 结论先行

当前存在两条主路径，且规则不一致。

| 创建方式 | 文件:行 | 命名代码 | 使用频率估计 | 风险 |
|---|---|---|---|---|
| 工具栏/inline 输入创建普通函数 | `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceState.swift:1429-1471` | `let ordinaryCount = document.objects.filter { ... }.count`，`let name = "f_\(ordinaryCount + 1)"` | 高，用户最常见 | 删除 `f_1` 后重新创建时可能和现存 `f_2` 等发生重复；这是当前主风险 |
| `PlaneCommandHandler.createFunction` | `/Users/night_creek/开发/eMathica/eMathica/eMathica/CalculatorModules/Plane/Commands/PlaneCommandHandler.swift:149-169` | `functionDefinitionName(from:) ?? nextFunctionName(existing:)` | 中 | 与 `WorkspaceState` 主路径不一致，行为可能分叉 |
| `PlaneCommandHandler.submitInput` | `/Users/night_creek/开发/eMathica/eMathica/eMathica/CalculatorModules/Plane/Commands/PlaneCommandHandler.swift:281-309` | 同上 | 中 | 与 `WorkspaceState` 主路径不一致 |
| 导函数创建 | `/Users/night_creek/开发/eMathica/eMathica/eMathica/CalculatorModules/Plane/Commands/PlaneCommandHandler.swift:668-761` | `name = "\(baseName)\(suffix)(\(variable.name))"` | 低-中 | 与普通函数命名不是同一条规则，但属于另一套派生命名 |

### 现状分析

- `WorkspaceState` 的创建路径是“按当前普通函数数量 + 1”。
- `PlaneCommandHandler.nextFunctionName(existing:)` 是“按已有名字取最大数 + 1”。
- 这两种规则不是等价的。
- 因此，删除中间项后再创建时，主路径存在重复命名风险。

### 用户重命名支持

支持。证据来自 `PlaneCommandHandler.swift:65-69` 的 `renameObject` 命令。

### 几何对象是否也有类似命名问题

有，而且不止函数。

- `createLine` / `handleCreateDerivedLine` / `handleCreateCircleWithOptionalCenter` / `handleCreateArc` 都有自己的计数式命名。
- 其中多处命名逻辑依赖 `count + 1`，例如 `ℓ\(count + 1)`、`r\(count + 1)`、`c\(count + 1)`、`a\(count + 1)`。
- 这些路径同样可能在删除后重建时产生跳号或重复的可读性问题。

### 后续修复建议

1. 统一普通函数、导函数、几何对象的命名策略。
2. 让 `WorkspaceState` 与 `PlaneCommandHandler` 共用同一命名服务。
3. 对“已删除对象是否保留编号”的产品规则做一次明确决定。

## 8. 首页文件卡片和函数缩略图预览审计

### 当前首页文件卡片链路

`CoreHomeState.previewURL(for:)`
→ `ProjectStore.previewURL(for:)`
→ `LocalProjectStore.previewURL(for:)`
→ `EMathicaPackageLayout.previewURL`
→ 磁盘上的 `preview.png`
→ `ProjectCardView`
→ `ProjectThumbnailView.platformImage(from:)`

### 当前预览图链路

`LocalProjectStore.createProject(...)` / `saveProject(...)`
→ `updatePreviewIfPossible(for:at:)`
→ `ProjectPreviewRenderer.renderPNGData(for:)`
→ 写入 `preview.png`

### 现状判断

1. 当前文件卡片有预览图路径。
2. 当前 `preview.png` 已有生成和保存逻辑。
3. 首页打开时已经是“读预览图”，不是重新算函数。
4. `ProjectPreviewRenderer` 已经支持离屏渲染函数/几何/Space 预览。

### 关键证据

- `LocalProjectStore.swift:42-61` 和 `85-103` 在创建/保存时写回 preview。
- `ProjectThumbnailView.swift:21-39` 优先读 `previewURL`。
- `ProjectPreviewRenderer.swift:76-133` 负责离屏生成 PNG。
- `ProjectPreviewRenderer.swift:349-411` 使用固定 `WorldBounds.default` 构建场景。

### 缺失环节

| 缺口 | 现状 | 影响 |
|---|---|---|
| 缩略图取景自适应 | `ProjectPreviewRenderer.buildScene` 使用固定 `WorldBounds.default` | 多对象或大范围作品的缩略图可能被裁切或留白过多 |
| 缩略图内容更精确表达 | `makeRecentProject` 固定 `thumbnailKindRawValue: "formulaNotes"` | 当 `preview.png` 缺失时，所有项目 fallback 都过于泛化 |
| 大图 decode 风险 | `ProjectThumbnailView` 每卡都同步开图 | 首页大量卡片时存在主线程解码风险，待确认 |

### 建议实现方案

- 继续把 `preview.png` 作为首页主路径，不要在首页重新采样函数。
- 将缩略图自适应取景放在 `ProjectPreviewRenderer` 层处理，而不是卡片层。
- 保存文档时同步刷新 `preview.png` 是正确的位置，继续保留在 `DocumentSystem`。

### 最小改动路径

1. 保持 `LocalProjectStore.saveProject` / `createProject` 的离屏生成不变。
2. 在 `ProjectPreviewRenderer.buildScene` 中补一层 content bounds / auto-fit 逻辑。
3. 若 `preview.png` 缺失，再逐步改进 `thumbnailKindRawValue` 的 fallback 规则。

## 9. MathCore / AST / CAS / Sampling 审计

### 子系统状态

| 子系统 | 已实现 | 是否接入主链路 | 风险 | MVP 是否必须修 |
|---|---|---|---|---|
| `Expr` / `Symbol` / `MathFunction` / `Relation` / `Piecewise` / `Matrix` | `Expr.swift:8-38` 已包含算术、关系、分段、矩阵、赋值、函数定义等 AST | 是，`MathNodeSemanticLowering`、`ExprEvaluator`、`GraphClassifier` 都在消费 | `ExprEvaluator` 对关系/赋值/函数定义返回 undefined，这是预期但要清楚边界 | 是，AST 基础必须保留 |
| `ExpressionNormalizer` | `ExpressionNormalizer.swift:1-74` 扁平化加法/乘法并递归归一化 | 间接接入 `Canonicalizer` 和 `GraphClassifier` | 归一化范围较基础，不能替代更高层语义整理 | 否，但属于基础设施 |
| `ExpressionSimplifier` | `ExpressionSimplifier.swift:1-181` 已做 0/1 简化、整数有理数、嵌套扁平化 | 间接接入 `Canonicalizer`、`GraphClassifier` | 不要把它当完整 CAS | 否，但基础链路需要稳定 |
| `Canonicalizer` | `Canonicalizer.swift:1-81` 把 `Expr` 转为 `CanonicalExpr` | 基础设施存在，但本轮未见 Plane 主渲染直接调用它 | 与 Plane 实际绘图链路之间仍有一层抽象差异 | 否 |
| `GraphIntent` / `GraphClassifier` | `GraphIntent.swift:1-29`、`GraphClassifier.swift:18-214` 已支持 explicitY / explicitX / implicit / parametric2D / polar / point / circle / conic / piecewise | 是，`PlaneSemanticIntentResolver` 明确使用 | 分类结果和 fallback 分叉要持续对齐 | 是 |
| `ExprEvaluator` | `ExprEvaluator.swift:18-133` 已支持数值、函数、分段等 | 是，被 explicit / implicit / parametric / conic / semantic sampling 间接消费 | 对超出支持范围的表达式会返回 undefined | 是 |
| `Sampling` | `GraphIntentSampler2D.swift:49-185` 已按 intent 分发；`ExplicitFunctionSampler2D.swift:15-320` 支持自适应细化；`ImplicitCurveSampler2D.swift:15-190` 支持网格 + marching squares + stitching | 是，`PlaneFallbackSamplingService.sampler(qualityProfile:)` 已接入 | 对复杂函数 / 断点 / 渐近线仍依赖采样策略和 fallback | 是 |

### 具体结论

1. 当前 AST 类型足够支撑平面计算器 MVP。
2. `Normalizer` / `Simplifier` / `Canonicalizer` 已作为基础设施存在，但 Plane 主绘图链主要还是走 `AlgebraCore` + `GraphClassifier` + `GraphIntentSampler2D`，并不是单一路径。
3. `GraphIntent` 真的被用来选择采样策略，证据在 `PlaneSemanticIntentResolver.swift:48-70` 和 `GraphIntentSampler2D.swift:49-185`。
4. `explicitY` / `explicitX` 仍然偏 legacy，`PlaneSemanticPreviewPolicy.swift:10-16` 明确把它们留在旧路径。
5. `parametric2D`、`polar`、`implicit`、`piecewise`、`circle`、`conic` 已有语义采样链。
6. `ExplicitFunctionSampler2D` 已支持 `uniform`、`uniformWithBasicRefinement`、`adaptiveScreenSpace`、`hybridExploratory`，默认行为由 `CurveSamplingOptions2D.defaults(for:)` 决定。
7. `ImplicitCurveSampler2D` 已具备 marching squares + segment stitching，且 `PlaneFallbackSamplingService` 对其开启了 stitching。

### 复杂函数 / 分段函数 / 断点 / 垂直渐近线风险

- 复杂函数的风险主要在采样密度不足、断点切段和可视范围过宽。
- 分段函数的风险主要在 intent 识别与 branch 一致性。
- 断点和渐近线的风险主要在跳变检测与 refinement depth 上限。
- 这些都不是“没有链路”，而是“链路存在但需要持续验证”的问题。

## 10. Space 立体计算器状态审计

### 当前文件现状

| Space 模块 | 当前状态 | 是否可用 | 风险 | 后续建议 |
|---|---|---|---|---|
| `SpaceMathCore` | 仅见 `SpaceMath3D.swift`，包含 `WorldPoint3D`、`Vector3D`、`SpaceCameraState`、`SpaceWorkPlane` | 可用，但很薄 | 只有基础 3D/相机/工作平面类型 | 继续留在 MathCore，别扩成独立重型子系统 |
| `SpaceDocumentModel` | 当前仓库未找到同名源码文件 | 不可用 | 文档模型未独立成层 | 待确认是否需要新建 |
| `SpaceCanvas` | `SpaceCanvasView.swift:5-360` 已存在 | 可用 | 只有基础 3D 交互与画布，没有 inspector / snapping 封装层 | 先稳定现有骨架 |
| `SpaceTools` | `SpaceToolIDs.swift`、`SpaceToolProvider.swift` 已存在 | 可用 | 工具数量少 | 先补稳定性，不要膨胀 |
| `SpaceHitTest` | `SpaceHitTestService.swift` 已存在 | 可用 | 命中分层简单，v0.1 只够基础对象 | 继续只做 bugfix |
| `SpaceSnapping` | 当前未发现独立模块；吸附逻辑只在 `SpaceGeometryResolver.snappedOrWorkPlanePoint` 内 | 部分可用 | 还不是独立系统 | 如需扩展，再抽模块 |
| `SpaceWorkPlane` | 存在于 `SpaceMath3D.swift:231-246` | 可用 | 目前只有 XY / YZ / ZX | 够 v0.1 |
| `SpaceInspector` | 当前未发现同名源码文件 | 不可用 | Inspector 未完成 | 不建议现在扩展功能 |
| `SpacePreview` | 当前未发现独立模块；预览由 `ProjectPreviewRenderer` + `SpaceWireframeRenderer` 完成 | 部分可用 | 没有独立 preview 模块层 | 先用现有离屏预览实现 |

### Space v0.1 是否已经形成可运行骨架

是，已经形成“可运行骨架”，因为：

- `SpaceWorkspaceModuleProvider`
- `SpaceCommandHandler`
- `SpaceCanvasView`
- `SpaceGeometryResolver`
- `SpaceHitTestService`
- `SpaceWireframeRenderer`

这些模块已经连成了一条最小可用链。

但它不是完整产品骨架，因为：

- `makeDraftMathObject` 直接返回 `nil`
- `semanticIntentAdapter` 直接返回 `nil`
- `geometryDependencyService` 还没实现
- 没有独立 `SpaceDocumentModel`
- 没有独立 `SpaceInspector`
- 没有独立 `SpaceSnapping`
- 没有独立 `SpacePreview`

### 3D 曲面 / 参数曲面 / 隐式曲面

当前源码里没有看到这些能力已经实现为完整产品功能。

`SpaceWireframeRenderer` 当前只处理：

- point3D
- segment3D
- line3D
- plane3D

因此 3D 曲面、参数曲面、隐式曲面都应视为未实现，而不是已完成。

### Plane 与 Space 的共享与不该共享

- 共享是合理的地方：`SpaceCameraState`、`SpaceWorkPlane`、`ProjectPreviewRenderer` 的 Space 分支、`MathCore` 的 3D 向量和投影工具。
- 不该共享的地方：`WorkspaceCanvasContext` 直接暴露 `SpaceWorkPlane` 给所有模块的做法，属于边界偏宽。

### 继续做 Space 前，Plane 需要先稳定什么

1. 函数命名规则统一。
2. 主页缩略图取景稳定。
3. 预览 / 输入 / 编辑链路不再靠 `WorkspaceState` 做太多具体模块判断。
4. Plane 的命令和 geometry dependency 行为不再分叉。

## 11. 当前平面计算器 MVP 缺口清单

| 优先级 | 缺口 | 涉及文件 | 当前状态 | 为什么影响 MVP | 建议处理方式 |
|---|---|---|---|---|---|
| P0 | 普通函数命名主路径与 `PlaneCommandHandler` 不一致，且主路径可能在删除后复名 | `WorkspaceState.swift:1429-1460`、`PlaneCommandHandler.swift:149-169,281-309,364-377` | 已实现但双路径 | 会导致函数对象名字重复或跳号，影响后续编辑、引用和一致性 | 把命名逻辑收敛为一条共享服务 |
| P0 | 几何对象命名仍然是多处 count-based / local rule | `PlaneCommandHandler.swift:133-147,171-213,506-665,1013-1213` | 已实现但规则分散 | 删除后重建时可能出现编号重复或不可预测 | 统一几何命名服务 |
| P1 | 首页缩略图取景固定，不是内容自适应 | `ProjectPreviewRenderer.swift:349-411` | 已有 preview.png，但 viewport 固定 | 多对象作品的缩略图可能不完整或留白过多 | 在 `ProjectPreviewRenderer` 层做 auto-fit |
| P1 | `WorkspaceState` 仍承担 Plane 专属输入/命名/编辑规则 | `WorkspaceState.swift:1249-1491,1661-1679` | 已实现 | 不是功能缺失，但增加后续改动风险 | 继续迁移到 Plane 适配层 |
| P1 | 显式删除工具不在工具栏中 | `PlaneToolProvider.swift:5-109`、`WorkspaceView.swift:325-327` | 有删除能力，但没有 `plane.delete` 工具 | 如果产品定义要求工具栏直接删除，这是一个缺口 | 决定是否补一个显式删除工具 |
| P1 | `explicitY` / `explicitX` 仍走 legacy preview 语义 | `PlaneSemanticPreviewPolicy.swift:10-16`、`PlaneObjectRendererView.swift:629-680` | 已实现但双路径 | 复杂函数预览一致性需要持续验证 | 继续观察，必要时统一到 semantic 采样 |
| P2 | `WorkspaceView.handleToolAction` 的 moduleSpecific 仍是 TODO payload | `WorkspaceView.swift:275-279` | 仅占位 | 当前 Plane 主路径没用到，但未来扩展会踩坑 | 后续补齐或删除占位 |
| P2 | 对象区显示源文本的具体来源未直接确认 | `WorkspaceState.swift:1231-1247` | 写入链完整 | 可能影响用户对“编辑的是原始 LaTeX 还是显示文本”的理解 | 读对象面板源码后再定 |
| P2 | `CoreHomeState.makeRecentProject` 的 fallback thumbnailKind 很泛化 | `CoreHomeState.swift:195-204` | 已实现 | preview 缺失时视觉表达不够准确 | 逐步让 fallback 反映模块类型 |
| P3 | Space、Data、Modeling、Music、Notes 仍为占位 | 对应 placeholder views | 未完成 | 不影响 Plane MVP | 后续版本再做 |

### MVP 结论

严格按当前源码判断，Plane MVP 已经非常接近闭环，真正会伤到闭环的是“命名一致性”和“缩略图取景质量”，不是“功能完全没做”。

## 12. 建议的下一轮 Codex 修复任务拆分

| 任务 | 目标 | 建议范围 | 优先级 |
|---|---|---|---|
| 任务 1 | 统一函数/几何命名服务 | `WorkspaceState` + `PlaneCommandHandler` + 几何命名分支 | P0 |
| 任务 2 | 清理 `WorkspaceState` 中残留的 Plane 规则 | 去掉死代码 `canonicalPlaneCommitInput`，缩小 `WorkspaceState` 专属逻辑 | P1 |
| 任务 3 | 把首页缩略图做成内容自适应取景 | `ProjectPreviewRenderer.buildScene` | P1 |
| 任务 4 | 决定显式删除工具是否进入工具栏 | `PlaneToolProvider` / `WorkspaceView` | P1 或 P2 |
| 任务 5 | 统一 semantic preview policy | `PlaneSemanticPreviewPolicy` / `PlaneObjectRendererView` / `PlaneDraftPreviewService` | P1 |
| 任务 6 | 明确对象区显示原始文本还是 displayText | `ObjectPanel` / `WorkspaceState` | P2 |
| 任务 7 | Space 继续保持 bugfix-only 或补骨架 | `Space*` 模块 | P3 |

---

结论一句话：

Plane 已经有 MVP 骨架了，但命名和缩略图还没完全收口；`WorkspaceKit` 仍有边界泄漏；`Space` 还只是可运行骨架；`MathCore` 基础链路已经扎实。
