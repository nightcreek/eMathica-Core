# EMathica Frontend Interaction + UI Boundary Audit

**审计日期**: 2026-06-21  
**审计范围**: 只读审计，未修改任何代码  
**审计方法**: 全量源文件阅读、grep 搜索、代码结构分析

---

## 1. 当前输入链路总览

### 1.1 Apple Pencil / 手写输入链路

```
Apple Pencil Stroke
  │
  ▼
PKCanvasView (PencilDrawingRepresentable.swift) 
  │   canvasViewDrawingDidChange() → parent.onDrawingChanged(drawing, size)
  │   canvasViewDidEndUsingTool()  → same callback
  ▼
CollectorWorkspaceState.updateCurrentDrawing(_:canvasSize:)
  │   currentDrawingData = drawing.dataRepresentation()
  │   hasHandwriting → drawing.strokes.isEmpty
  ▼
PKDrawing as Data  ← 直接存储到 state，没有 draft/session/commit 分层
  │
  ▼
LocalSampleStore.saveDrawing()  ← 没有经过 WorkspaceCommand / DocumentCommand
```

**问题**: Pencil stroke 没有 stroke session / draft / preview 分层。每笔直接落入 `currentDrawingData`，没有"暂存→预览→确认提交"的流程。仅在 `saveCurrentDraft()` 时有显式保存按钮。

### 1.2 触控手势输入链路

```
Touch / Gesture
  │
  ▼
PlaneCanvasView (SwiftUI View)
  │   5 个手势：
  │   ┌─ panGesture         (DragGesture, minDistance 2)
  │   ├─ zoomGesture        (MagnificationGesture)
  │   ├─ tapGesture         (SpatialTapGesture) ← 主状态机入口
  │   ├─ pointDragGesture   (DragGesture, minDistance 6)
  │   └─ constructionPreviewGesture (DragGesture, minDistance 0)
  │
  ├──▶ interactionState (PlaneInteractionState)   ← 直接 @State 修改
  │       └─ activeConstruction, constructionPreview, 等
  │
  ├──▶ dispatch(.createPoint(at:))                ← WorkspaceCommand
  ├──▶ dispatch(.selectObject(id:))               ← WorkspaceCommand
  ├──▶ dispatch(.moduleSpecific(id:payload:))     ← WorkspaceCommand
  └──▶ dispatch(.setCanvasViewport(...))           ← WorkspaceCommand
```

**关键设计**: 手势处理器通过 `dispatch(WorkspaceCommand)` 最终到达 `PlaneCommandHandler.handle()`，后者产出 `ModuleCommandOutput(documentCommands: [DocumentCommand], effects: [WorkspaceEffect])`。这是正确的命令链架构。

**但**：`interactionState` 的直接 @State 修改绕过了 `PlaneInteractionReducer`（该 reducer 存在但完全未被调用）。

### 1.3 鼠标输入链路

```
Mouse Click / Drag
  │
  └── 同触控手势链路
      SpatialTapGesture / DragGesture on macOS 通过 SwiftUI 统一处理
```

无专门的鼠标适配器。macOS 上的交互同 iPad 触控路径。

### 1.4 外接键盘输入链路

```
Hardware Keyboard Press
  │
  ▼
KeyboardShortcutManager.shared
  │   ⌘Z, ⌘⇧Z, ⌘S, ⌘N, ⌘E, ⌘⇧E, ⌘⌫, ⌘⇧⌫, ⌘⇧X
  │
  └──▶ (未知) 最终如何影响 WorkspaceCommand 或 state 不明
      (KeyboardShortcutManager 不在 PlaneCanvasView 或 CommandHandler 中被引用)
```

```
公式键盘 (MathKeyboardView)
  │  存在于 EMathicaWorkspaceKit 包中
  ▼
KeyboardAction 枚举
  │
  ├──▶ CollectorWorkspaceState.applyKeyboardAction(_:)  ← 直接修改 state
  │        └─ mathInputState.apply(action) → syncDerivedInputStrings()
  │
  └──▶ WorkspaceCommand.submitInput / .toggleKeyboard
          在 PlaneCommandHandler 中处理
```

**问题**: 外接键盘快捷键管理器 (`KeyboardShortcutManager`) 虽然存在，但并未集成到 `WorkspaceCommand` 的命令链路中。公式键盘通过两种路径（直接修改 `CollectorWorkspaceState` 和 `WorkspaceCommand`）存在不一致。

### 1.5 公式键盘输入链路

```
MathKeyboardView (EMathicaWorkspaceKit 包内)
  │
  ▼
KeyboardAction
  │   .insertCharacter, .deleteBackward, .moveCursor, .submit, 等
  │
  ├──▶ Plane: WorkspaceCommand.updateInputText → submitInput
  │        → PlaneCommandHandler → PlaneExpressionService.buildExpression()
  │        → DocumentCommand.addObject → EMathicaDocument.apply()
  │
  └──▶ Collector: CollectorWorkspaceState.applyKeyboardAction()
           → mathInputState.apply() → syncDerivedInputStrings()
           → upsert(sample) + persistSamples()
```

---

## 2. 当前 UI 结构总览

### 2.1 CoreHome (首页 / 项目浏览)

| 文件 | 职责 | 行数 | 备注 |
|------|------|------|------|
| `CoreHomeView.swift` | 顶层 View，持有 CoreHomeState | ~40 | 薄（好） |
| `CoreHomeState.swift` | 业务逻辑 + 项目 CRUD | ~250 | ViewModel 角色 |
| `CoreHomeUIState.swift` | 纯 UI 状态值类型 | ~30 | **结构好** |
| `CoreHomeResponsiveContainer.swift` | 响应式容器，派发到 Pad/Phone 布局 | ~100 | 好设计 |
| `CoreHomeLayoutProfile.swift` | 布局描述文件 | ~100 | 4 个 profile |
| `FluidCoreHomeMetrics.swift` | 流体尺寸计算 | ~150 | 细粒度 |
| `PadCoreHomeLayout.swift` | iPad 特定布局 | ~200 | scroll/non-scroll |
| `PhoneCoreHomeLayout.swift` | iPhone 特定布局 | ~380 | 含内联 portrait metrics |
| `GalleryDrawerView.swift` | 项目画廊面板 | ~700 | **过胖** |
| `ProjectCardView.swift` | 项目卡片 | ~200 | 正常 |
| `ProjectThumbnailView.swift` | 缩略图渲染 | ~100 | 含缓存逻辑 |
| `CoreHomeBackgroundView.swift` | 动画背景 | ~80 | 正常 |
| `HomeMockProjectStore.swift` | Mock 数据 | ~80 | **唯一 Mock 数据源** |
| `ProjectPreviewRenderer.swift` | 离线预览渲染 | ~400 | 正常 |

### 2.2 Plane Workspace (平面计算器)

| 文件 | 职责 | 行数 | 备注 |
|------|------|------|------|
| `PlaneCanvasView.swift` | 主画布视图 + 所有手势 | ~923 | **过胖** |
| `PlaneObjectRendererView.swift` | 对象 + 预览渲染 | ~450+ | SwiftUI Canvas |
| `PlaneAxisRendererView.swift` | 坐标轴渲染 | ~60 | 职责清晰 |
| `PlaneGridRendererView.swift` | 网格渲染 | ~60 | 职责清晰 |
| `PlaneCommandHandler.swift` | 命令处理器 | ~600+ | 含所有 payload handler |
| `PlaneInteractionState.swift` | 交互状态 | ~75 | 好设计 |
| `PlaneInteractionReducer.swift` | **未使用**的 reducer | ~15 | **死代码** |
| `PlaneConstructionMode.swift` | 构造模式枚举 | ~27 | 16 cases |
| `PlaneConstructionPreview.swift` | 预览枚举 | ~15 | 6 cases |
| `PlaneDraftPreviewService.swift` | Draft → Preview 管线 | ~530 | 语义采样 + 回退 |
| `PlaneHitTestService.swift` | 命中测试 | ~100 | 好 |
| `PlaneToolActions.swift` | **空文件** | ~4 | **占位符** |
| `PlaneToolProvider.swift` | 工具栏布局定义 | ~80 | 好 |

### 2.3 Space Workspace (3D 计算器)

| 文件 | 职责 | 行数 |
|------|------|------|
| `SpaceCanvasView.swift` | 3D 画布 + 手势 | ~350 |
| `SpaceCommandHandler.swift` | 3D 命令处理器 | ~40 |
| `SpaceWireframeRenderer.swift` | 线框渲染 | ~100 |

### 2.4 Document System

| 文件 | 职责 |
|------|------|
| `EMathicaDocument.swift` | 文档模型 + `apply()` 方法 |
| `DocumentCommand.swift` | 13 种原子命令枚举 |
| `DocumentObjectPatch.swift` | 部分更新结构体（全 Optional） |
| `ProjectStore.swift` | 协议：7 个方法 |
| `LocalProjectStore.swift` | 文件存储实现 |

### 2.5 State

| 文件 | 职责 |
|------|------|
| `CollectorWorkspaceState.swift` | **重度多功能** ObservableObject，管理 PKDrawing、公式输入、文件 IO、undo/redo、导出 |
| `KeyboardShortcutManager.swift` | 快捷键定义，但**未集成**到命令链路 |
| `UndoRedoManager.swift` | Undo/redo 栈 |
| `LocalSampleStore.swift` | 样本文件存储 |

### 2.6 Handwriting (PencilKit)

| 文件 | 职责 |
|------|------|
| `PencilDrawingRepresentable.swift` | PKCanvasView 封装（UIViewRepresentable） |
| `HandwritingCanvasView.swift` | 手写画布 View，直接访问 CollectorWorkspaceState |
| `HandwritingToolbarView.swift` | 画笔工具栏 |
| `DrawingToolSettings.swift` | 画笔设置（pen/pencil/marker/lasso） |

---

## 3. 理想架构边界

### 3.1 输入层推荐架构

```
Raw Input (Touch / Pencil / Mouse / Keyboard / MathKeyboard)
    │
    ▼
Input Adapter
    │   将平台特定事件转换为统一 Intent
    │   SpatialTapGesture → Intent.tap(location)
    │   PKStrokeCollection → Intent.stroke(ink)
    │   KeyboardEvent → Intent.keyPress(key)
    │   DragGesture → Intent.drag(from:to:)
    │
    ▼
Interaction State (前端纯状态)
    │   PlaneInteractionState (已存在，但 reducer 未使用)
    │   PlaneDragIntent (已存在，但私有且内联)
    │   ViewportState (当前是 CanvasState，混入 Document)
    │   SelectionState (当前是 WorkspaceEffect，好)
    │
    ▼
Intent Resolver
    │   将 Intent + InteractionState → WorkspaceCommand
    │   当前 PlanceCanvasView 的 tapGesture 内联实现了这个
    │
    ▼
Draft / Preview (前端瞬态)
    │   DraftMathObject (已存在，好)
    │   PlaneConstructionPreview (已存在，好)
    │   缺少: PKDrawing Draft/Session 层
    │
    ▼
WorkspaceCommand
    │   30+ cases, 已存在
    │
    ▼
ModuleCommandHandler.handle()
    │
    ▼
ModuleCommandOutput
    ├── DocumentCommand → EMathicaDocument.apply()
    └── WorkspaceEffect → UI State Mutation
```

### 3.2 UI 推荐分层

```
Screen
  │   CoreHomeView, WorkspaceView, etc.
  │
  ▼
Layout / Region
  │   CoreHomeResponsiveContainer
  │   PadCoreHomeLayout / PhoneCoreHomeLayout
  │   PlaneCanvasView / SpaceCanvasView
  │
  ▼
Panel / Section
  │   GalleryDrawerView
  │   ObjectPanelView
  │   FormulaInputBar
  │   ToolbarView
  │
  ▼
Component
  │   ProjectCardView
  │   ProjectThumbnailView
  │   PlaneObjectRendererView
  │   MathKeyboardView
  │   HandwritingToolbarView
  │
  ▼
Primitive / Style Token
  │   ThumbnailShape
  │   LiquidGlassPanel / LiquidGlassTheme
  │   ColorToken
  │   canvasBackground (当前在 PlaneCanvasView 内联)
```

**当前差距**: 
- Canvas 背景颜色在 `PlaneCanvasView` 内联（hardcoded `[0.04, 0.06, 0.10]` 等）
- 构造提示浮层的视觉参数内联（胶囊样式、shadow、padding）
- 缺少统一的 Style Token / Design Token 系统

---

## 4. 已经做得正确的地方

1. **两层的命令架构 (WorkspaceCommand → DocumentCommand)** 已存在。`PlaneCommandHandler.handle()` 正确地区分出 `documentCommands` 和 `effects`，这是良好的 CQRS 模式。

2. **`EMathicaDocument.apply()` 是唯一的 document mutation 入口**。所有 13 种 `DocumentCommand` 都通过这个方法应用，保证了 undo/redo 和一致性。

3. **`DocumentObjectPatch` 使用全 Optional 模式**实现部分更新，避免全量对象复制。

4. **`PlaneInteractionState` 是纯 @State 前端状态**，没有进入 document 模型。它是 `Hashable` 值类型。

5. **`PlaneConstructionPreview` 是纯前端枚举**，仅用于渲染临时视觉反馈，不持久化。

6. **`PlaneDraftPreviewService`** 正确实现 draft → preview 管线，使用回退链（semantic → legacy → lastValidPreviewSamples），不直接修改 document。

7. **`DraftMathObject`** 作为纯预览数据对象，与 commited document objects 分离。

8. **`CoreHomeUIState` 从 CoreHomeState 中分离**，是纯值类型 UI 状态，不混入业务逻辑。

9. **模块化工具系统**：`PlaneToolProvider`、`PlaneToolIDs` 将工具定义从手势处理中分离。

10. **响应式布局架构**：`CoreHomeLayoutProfile` + `FluidCoreHomeMetrics` + `PadCoreHomeLayout`/`PhoneCoreHomeLayout` 是良好的分层设计。

11. **`HomeMockProjectStore`** 为 Preview 和测试提供 mock 数据，实现了 `ProjectStore` 协议。

12. **手势处理中对 dispatch 的使用**：所有 tap 和 drag handler 最终通过 `dispatch(WorkspaceCommand)` 触发 document mutation，而非直接修改 objects 数组。

---

## 5. 跨层风险清单

| # | 文件 | 问题 | 输入类型/UI区域 | 风险等级 | 原因 | 建议处理方式 |
|---|------|------|-----------------|----------|------|-------------|
| 1 | `PlaneCanvasView.swift` (全部) | 923 行，5个手势 + 11个工具 + 16种构造模式 + hit test + 坐标转换 + 预览逻辑全部内联 | 触控手势/Canvas | **P0** | 同一文件承载状态机转换、命令分发、预览、hit test、坐标数学，职责过多 | 将手势分离为 `PlaneGestureHandler`，将状态机分离为 `PlaneConstructionStateMachine`，将 dispatch 逻辑集中到 `PlaneToolActionResolver` |
| 2 | `PlaneInteractionReducer.swift` | **完全未使用**：只有一个 `.reset` 事件，没有任何调用点 | 触控手势/交互状态 | **P1** | 存在但没有集成。`interactionState` 全部在 View 中直接 @State 修改，reducer 模式荡然无存 | 删除死代码，或将所有状态转换迁移到 reducer |
| 3 | `PencilDrawingRepresentable.swift` | Pencil stroke 直接通过 `onDrawingChanged` 回调写入 state | Apple Pencil | **P1** | `canvasViewDrawingDidChange` → `parent.drawingData = ...` 直接设置 binding，没有 stroke session/commit 分层 | 引入 `StrokeSession` 状态机：stroke start → stroke in progress (draft) → stroke end (commit or discard) |
| 4 | `CollectorWorkspaceState.swift` (全部) | 巨型 ObservableObject：管理 PKDrawing、LaTeX、文件 IO、undo/redo、导出 | Apple Pencil/Keyboard | **P1** | 单一对象承担了 ViewModel + Service + Store 三个角色。Pencil 手势直接修改 `currentDrawingData` | 拆分为 `PencilStrokeService`、`FormulaInputState`、`SampleRepository`，引入命令链 |
| 5 | `HandwritingCanvasView.swift` | 通过 `@EnvironmentObject` 直接访问 `CollectorWorkspaceState`，无命令层 | Apple Pencil | **P1** | View 直接调用 `workspace.updateCurrentDrawing()` 和 `workspace.saveCurrentDraft()` | 引入 `HandwritingIntent` + `HandwritingCommandHandler` |
| 6 | `KeyboardShortcutManager.swift` | 快捷键定义存在但未集成到 WorkspaceCommand 链路 | 外接键盘 | **P1** | 快捷键处理器不与 `WorkspaceCommand` 关联，可能在其他地方硬编码 | 将所有快捷键映射为 `WorkspaceCommand`，通过 `KeyboardShortcutHandler` 统一分发 |
| 7 | `CollectorWorkspaceState.applyKeyboardAction(_:)` | 公式键盘输入直接修改 `mathInputState` + 持久化到磁盘 | 公式键盘 | **P1** | 绕过 WorkspaceCommand 直接 upsert sample + persistSamples。Plane 模块键盘走 WorkspaceCommand，Collector 不走 | 统一键盘输入路径，全部经过 `WorkspaceCommand` |
| 8 | `PlaneCanvasView.swift` (内联 payload struct) | `PlaneSegmentCreatePayload`、`PlaneCircleCreatePayload` 等 7 个 Codable Struct 定义在 View 内 | 触控手势 | **P1** | Payload 类型与命令紧密相关，却定义在 View 内，无法被其他模块或测试复用 | 移到 `PlaneCommandPayloads.swift` 或 `PlaneCommandHandler.swift` |
| 9 | `CanvasState` 通过 `DocumentCommand.updateCanvasState` 持久化 | 视口状态（pan/zoom）进入 document 模型 | 触控手势/视口 | **P1** | 每次 pan/zoom 都产生 `.updateCanvasState` DocumentCommand，undo/redo 会恢复视口位置 — 这可能不是预期行为 | 考虑将 `ViewportState` 分离为纯前端状态，不与 document 持久化耦合 |
| 10 | `GalleryDrawerView.swift` | ~700 行，内嵌 toolbar、tab bar、batch action、重命名 sheet | CoreHome/画廊 | **P1** | View 过胖，`GalleryTopBar`、`GalleryBatchActionBar` 都是内联 private struct | 提取 `GalleryTopBarView`、`GalleryBatchActionBarView`、`GalleryGridView` |
| 11 | `PhoneCoreHomeLayout.swift` | ~380 行，含内联 `PhonePortraitMetrics` | CoreHome/Phone | **P1** | Phone 布局在有独立 `FluidCoreHomeMetrics` 的情况下又定义了私有的 metrics 结构 | 复用 `FluidCoreHomeMetrics` |
| 12 | `PlaneCanvasView.swift` (背景) | Canvas 背景颜色硬编码 (`Color(red: 0.04, green: 0.06, blue: 0.10)` 等) | Canvas/视觉 | **P2** | 视觉参数散落在 View 中，难以跨组件保持一致 | 提取为 `CanvasStyle` 或 `CanvasTheme` |
| 13 | `PlaneCanvasView.swift` (hint overlay) | 构造提示浮层的圆角、padding、shadow 全部内联 (lines 268-301) | Canvas/UI | **P2** | 无法复用，修改视觉需要改 View | 提取为 `ConstructionHintView` |
| 14 | `PlaneToolActions.swift` | **空文件**，仅注释 | 工具系统 | **P2** | 预期作为 tool→command 映射，但从未实现 | 填充或删除 |
| 15 | `boxSelect`、`curve` 工具 | 在 `PlaneToolIDs` 中定义但无 handler，`curve` 不在工具栏中 | 工具系统 | **P2** | 死代码 | 清理或实现 |
| 16 | `PlaneConstructionMode.functionInput`、`.curveInput` | 从未被任何 tap handler 设置 | 交互状态机 | **P2** | 定义了但从未使用 | 清理或实现 |
| 17 | `EMathicaApp` vs `OpenMathInkCollectorApp` | 两个 `@main` 入口点 | 应用入口 | **P1** | 只有一个是活跃的，造成混淆 | 统一为一个 `@main`，通过 target 区分 |
| 18 | `EMathicaWorkspaceKit` 和 `EMathicaDocumentKit` | 被 xcodeproj 引用但源代码不在磁盘上 | 架构 | **P2** | 已知架构负债，命令/文档类型在 App Target 重复定义 | 按已有计划恢复清理 |
| 19 | `SpaceCanvasView.swift` | 手势处理（drag/tap/zoom）与 PlaneCanvasView 重复 | 触控手势/Space | **P1** | 有两个画布视图各自实现手势逻辑，没有共享 GestureHandler | 提取共享 `CanvasGestureHandler` |
| 20 | `ProjectThumbnailView.swift` | 内联图片加载逻辑（`Data(contentsOf:)` + 缓存） | CoreHome/缩略图 | **P2** | I/O 逻辑在 View 层 | 提取 `ThumbnailLoaderService` |

---

## 6. Draft / Preview / Commit 检查

### 6.1 Plane 模块

| 阶段 | 实现 | 状态 |
|------|------|------|
| **Draft** | `PlaneDraftPreviewService.makeDraft()` 生成 `DraftMathObject`，包含 parsed AST、preview samples、diagnostics | ✅ 良好 |
| **Preview** | `DraftMathObject.previewSamples` 由 `PlaneObjectRendererView.drawDraftPreview()` 在 Canvas 上渲染为 cyan 虚线 | ✅ 良好 |
| **Commit** | `WorkspaceCommand.submitInput` → `PlaneCommandHandler` → `PlaneExpressionService.buildExpression()` → `DocumentCommand.addObject` | ✅ 良好 |
| **回退链** | semantic intent sampling → legacy viewport sampling → lastValidPreviewSamples | ✅ 良好 |

**结论**: Plane 模块的 Draft/Preview/Commit 管线是完善的。

### 6.2 Handwriting / PencilKit 模块

| 阶段 | 实现 | 状态 |
|------|------|------|
| **Draft** | ❌ 无 — PKDrawing 直接在 `currentDrawingData` 中 | **缺失** |
| **Preview** | ❌ 无 — 无 transient stroke preview | **缺失** |
| **Commit** | `saveCurrentDraft()` 按钮 → 写入文件 | 存在但无命令链 |
| **Stroke Session** | ❌ 无 — 每笔 stroke 直接写入 state | **缺失** |

**结论**: Handwriting/PencilKit 模块缺少 Draft/Preview 分层。每次 stroke 直接进入 state，没有 "stroke session → draft → preview → commit" 流程。

---

## 7. Apple Pencil 专项检查

### 7.1 集成方式

- 通过 `PencilDrawingRepresentable.swift` (UIViewRepresentable) 封装 `PKCanvasView`
- `drawingPolicy = .anyInput`（接受 Apple Pencil 和手指）
- `PencilDrawingRepresentable` 用在 `HandwritingCanvasView.swift` 中

### 7.2 问题

1. **缺乏 stroke session 边界**：`canvasViewDrawingDidChange` 在每笔 stroke 变化时立即同步到 `CollectorWorkspaceState.currentDrawingData`，没有 pending/draft/committed 三态。

2. **缺乏预渲染/post-processing 钩子**：没有在 stroke 完成后进行识别、平滑、或 AST 转换的阶段。`canvasViewDidEndUsingTool` 也只是再次保存数据。

3. **Pencil 与 Plane Canvas 无集成**：Apple Pencil 仅在 Handwriting 功能中使用，没有在 Plane 画布上作为精确输入设备使用（例如用 Pencil 画几何图形）。

4. **没有 `PlanePencilHandler`**：Plane 模块完全没有 PencilKit 输入路径。所有几何创建都通过 tap/drag gesture。

### 7.3 建议

- 引入 `StrokeSession` 状态机：`.idle` → `.drawing(strokeCollection)` → `.preview(recognized)` → `.committed` / `.cancelled`
- 在 Plane 画布上考虑用 Pencil 作自由手绘输入 → 识别为几何

---

## 8. 外接键盘专项检查

### 8.1 快捷键系统

`KeyboardShortcutManager.shared` 定义以下快捷键：

| 快捷键 | 操作 |
|--------|------|
| ⌘Z | Undo |
| ⌘⇧Z | Redo |
| ⌘S | Save |
| ⌘N | New Project |
| ⌘E / ⌘⇧E | （未明确） |
| ⌘⌫ / ⌘⇧⌫ | Delete |
| ⌘⇧X | （未明确） |

### 8.2 问题

1. **快捷键未集成到 WorkspaceCommand 链路**：`KeyboardShortcutManager` 的方法体是 `fatalError("not yet integrated")`（从文档推断），快捷键目前可能通过 SwiftUI `.keyboardShortcut()` modifier 直接处理。

2. **macOS 键盘捕获缺失**：`Docs/Plane/PlaneKnownIssues.md` 明确指出 "macOS keyboard capture absent"。

3. **公式键盘（MathKeyboardView）在 Plane 和 Collector 中走不同路径**：
   - Plane: `WorkspaceCommand.updateInputText` → `submitInput`
   - Collector: `CollectorWorkspaceState.applyKeyboardAction()` → 直接修改

### 8.3 建议

- 将所有快捷键映射为 `WorkspaceCommand`，通过统一 `KeyboardShortcutHandler.handle(keyEvent:)` 分发
- `KeyboardShortcutManager` 应产出 `[WorkspaceCommand]` 而非直接执行

---

## 9. 手势与命中测试专项检查

### 9.1 手势架构

```
PlaneCanvasView
  │
  ├── panGesture (Drag, minDist 2)           → dispatch .setCanvasViewport
  ├── zoomGesture (Magnification)             → dispatch .setCanvasViewport
  ├── tapGesture (SpatialTap)                 → 11-way switch on activeToolID
  │     └── 每个 handler 内部实现状态机
  ├── pointDragGesture (Drag, minDist 6)      → dispatch .updateObjectPosition
  └── constructionPreviewGesture (Drag, minDist 0) → interactionState.constructionPreview
```

### 9.2 问题

1. **手势优先级和冲突处理不明确**：5 个手势通过 `.simultaneousGesture` 叠加。`pointDragGesture` (minDist 6) 和 `panGesture` (minDist 2) 可能冲突。

2. **`PlaneDragIntent` 私有枚举**：作为手势决定 pan vs drag 的分发器，但完全在 View 内实现，无法测试。

3. **没有统一的 `GestureHandler`**：Plane 和 Space 各自实现自己的手势逻辑（SpaceCanvasView 也有 drag/zoom/tap），重复代码约 40%。

4. **`PlaneHitTestService` 好但不能被手势直接使用**：`PlaneCanvasView` 通过私有方法调用 hit test 服务，没有中间层。

5. **`constructionPreviewGesture` 的 `.onEnded` 为空**：preview 在第二次 tap 时才清除 —— 如果用户取消（点击 cancel 按钮或切换工具），`clearConstructionProgress()` 被调用，但 preview 清除在 `interactionState` 重置中发生。这可能导致视觉残留。

### 9.3 建议

- 提取 `CanvasGestureHandler`：封装 5 个手势的优先级和冲突解决
- `PlaneDragIntent` 应为 `PlaneGestureIntent` 移到外部文件
- 考虑 `highPriorityGesture` 替代部分 `simultaneousGesture` 以减少冲突

---

## 10. UI 组件边界检查

### 10.1 过胖 View

| View | 行数 | 问题 | 建议 |
|------|------|------|------|
| `PlaneCanvasView.swift` | ~923 | 手势 + 状态机 + 坐标转换 + dispatch + 视觉 | 分离为：`PlaneGestureHandler`、`PlaneConstructionStateMachine`、`PlaneCanvasBackgroundView`、`ConstructionHintView` |
| `GalleryDrawerView.swift` | ~700 | TopBar + TabBar + BatchActions + 重命名 Sheet 全部内联 | 提取 4-5 个子 View |
| `PhoneCoreHomeLayout.swift` | ~380 | 内联 `PhonePortraitMetrics`、landscape/portrait 两套布局 | 复用 `FluidCoreHomeMetrics` 提取 `PhoneLandscapeLayout` |
| `PlaneCommandHandler.swift` | ~600+ | 30+ 种命令 + 12 个 payload handler | 可按 payload 类型拆分为多个 handler extension 或子 handler |
| `CollectorWorkspaceState.swift` | ~543 | ViewModel + Service + Store 三合一 | 拆分为 `PencilStrokeService` + `FormulaInputState` + `SampleRepository` |

### 10.2 View 嵌套深度

典型 `GalleryDrawerView` 嵌套深度估算：
```
GalleryDrawerView
  └─ LiquidGlassPanel
       └─ VStack
            ├─ drawerHandle
            ├─ GalleryTopBar (private)
            │    ├─ GalleryTabBar (extracted 文件)
            │    └─ SearchField / SortMenu
            ├─ HSplitView / 内容区域
            │    ├─ CalculatorModuleSidebarView
            │    └─ RecentProjectsGridView
            │         └─ LazyVGrid
            │              └─ ProjectCardView × N
            │                   ├─ ProjectThumbnailView
            │                   └─ (title + module + date)
            └─ GalleryBatchActionBar (private)
```

嵌套深度: ~8 层。建议将 `GalleryTopBar` 和 `GalleryBatchActionBar` 提取为独立文件。

### 10.3 视觉参数散落

| 参数 | 位置 | 值 |
|------|------|----|
| Canvas 背景色 | `PlaneCanvasView.swift:60-69` | `[0.04, 0.06, 0.10]` / `[0.94, 0.96, 1.0]` |
| 构造提示圆角 | `PlaneCanvasView.swift:290-296` | `Capsule(style: .continuous)` |
| 构造提示阴影 | `PlaneCanvasView.swift:297` | `radius: 6, x: 0, y: 3` |
| Grid 渲染参数 | `PlaneGridRendererView.swift` | 内联 |
| Axis 渲染参数 | `PlaneAxisRendererView.swift` | 内联 |
| 缩略图大小 | `ProjectCardView.swift` | 内联 |

建议提取为 `CanvasTheme` / `CanvasStyle` 等设计 token。

---

## 11. UI 状态边界检查

### 11.1 正确归为前端状态的对象

| 状态 | 位置 | 评估 |
|------|------|------|
| `PlaneInteractionState` (activeConstruction, pendingPointID, 等) | `@State` in PlaneCanvasView | ✅ 正确，纯前端 |
| `PlaneConstructionPreview` (temporarySegment, 等) | `interactionState.constructionPreview` | ✅ 正确，仅用于渲染 |
| `PlaneDragIntent` (none/panCanvas/dragPoint) | `@State` in PlaneCanvasView | ✅ 正确，纯前端 |
| `CoreHomeUIState` (selectedFilter, searchText, isSelectionMode) | 值类型 struct | ✅ 正确 |
| `panStartOrigin` / `pinchStartState` | `@State` in PlaneCanvasView | ✅ 正确 |
| `draftMathObject` (DraftMathObject?) | 从外部传入，渲染用 | ✅ 正确 |

### 11.2 可能混入 document 的状态

| 状态 | 位置 | 风险 |
|------|------|------|
| **CanvasState** | 通过 `DocumentCommand.updateCanvasState` 持久化到 `EMathicaDocument.canvasState` | ⚠️ 视口(pan/zoom)进入文档模型。每次 pan/zoom 产生 document mutation。undo/redo 会恢复视口位置 |
| **Selection** | `WorkspaceEffect.selectObject` / `.clearSelection` | ✅ 分离得好，纯前端 effect |
| **ActiveToolID** | `WorkspaceEffect.setActiveTool` | ✅ 分离得好 |

### 11.3 建议

将 `CanvasState` 拆分为两部分：
- **`ViewportState`**（纯前端）：origin, scale — 不持久化
- **`DocumentViewState`**（持久化）：showGrid, showAxis, minScale, maxScale — 需要持久化

这样 pan/zoom 不产生 document mutation。

---

## 12. Layout 与响应式检查

### 12.1 当前布局架构

- **CoreHome**: 4 个 profile (`phonePortrait`, `phoneLandscape`, `padPortrait`, `padLandscape`)
- **检测方式**: 基于 width ≥ 700 + sizeClass（非 `UIDevice.current.userInterfaceIdiom`）
- **macOS**: 使用 width ≥ 700 进入 iPad 路径（无专门 macOS profile）
- **分屏/SlideOver**: 通过 width + sizeClass 自然处理

### 12.2 问题

1. **无 macOS 专属布局 profile**：macOS 应有 `macWindowed`、`macFullscreen`、`macPopover` 等布局 profile

2. **iPhone Landscape 在项目级别禁用**：xcodeproj 限制 iPhone 仅支持 portrait，不在 SwiftUI 层面处理

3. **Plane Canvas 响应式不足**：`PlaneCanvasView` 使用 `GeometryReader` 获取 size，但工具条、输入栏、对象面板在横竖屏切换时的布局调整逻辑不明显

4. **`FluidCoreHomeMetrics` 只在 CoreHome 使用**：Plane 模块没有类似的流体 metrics 系统，使用固定数值

### 12.3 建议

- 添加 `macWindowed` profile（含窗口 resize 响应）
- 为 Plane 模块添加 `PlaneLayoutMetrics` 系统
- 引入 `LayoutProfile` 协议，所有模块统一 profile 决议

---

## 13. Preview / Mock / 可调试性检查

### 13.1 #Preview 使用情况

| 文件 | Preview 代码 | Mock 数据 |
|------|-------------|-----------|
| `AppRootView.swift` | ✅ `AppRootView().environment(AppNavigationState())` | `HomeMockProjectStore`（10 个项目） |
| `CoreHomeView.swift` | ✅ `CoreHomeView()` | `HomeMockProjectStore` |
| `StatisticsView.swift` | ✅ `StatisticsView()` | ❌ 无 mock |
| `HandwritingToolbarView.swift` | ✅ `.preferredColorScheme(.dark)` | ❌ 无 mock |
| `ConsentFlowView.swift` | ✅ `ConsentFlowView().environmentObject(ContributorConsentManager.shared)` | 真实单例 |
| `SettingsView.swift` | ✅ `SettingsView()` | ❌ 无 mock |
| `PlaneCanvasView.swift` | ❌ **无 Preview** | — |
| `PlaneObjectRendererView.swift` | ❌ **无 Preview** | — |
| `SpaceCanvasView.swift` | ❌ **无 Preview** | — |
| `PlaneCommandHandler.swift` | ❌ **无 Preview** | — |
| `GalleryDrawerView.swift` | ❌ **无 Preview** | — |

### 13.2 问题

1. **关键交互视图无 Preview**：`PlaneCanvasView`、`SpaceCanvasView`、`PlaneObjectRendererView` 等核心渲染视图没有 #Preview，导致必须运行完整 app 才能测试手势/交互。

2. **Mock 数据仅覆盖 CoreHome**：`HomeMockProjectStore` 只提供项目列表 mock。没有 `PlaneMockObjects`、没有 `MockDraftMathObject`、没有 `MockCanvasGestureState`。

3. **Preview 缺少环境设置**：没有 `.modelContainer`、`.environmentObject`、no mock `EMathicaDocument`。

4. **Preview 复用不足**：7 个 Preview 全部在各自文件内，没有共享 preview 扩展或 preview helpers。

### 13.3 建议

- 为每个主要 View 添加 #Preview，至少包含默认状态
- 创建 `PreviewHelpers.swift` 包含：
  - `mockPlaneObjects()` → `[MathObject]`
  - `mockCanvasState()` → `CanvasState`
  - `mockDraftMathObject()` → `DraftMathObject`
  - `mockInteractionState()` → `PlaneInteractionState`
- 为 `PlaneCanvasView` 创建 Preview wrapper 提供全部绑定

---

## 14. 命名与目录结构检查

### 14.1 命名评估

| 命名 | 位置 | 评估 | 建议 |
|------|------|------|------|
| `PlaneInteractionState` | Plane/Interaction/ | ✅ 好 |
| `PlaneConstructionMode` | Plane/Interaction/ | ✅ 好 |
| `PlaneConstructionPreview` | Plane/Interaction/ | ✅ 好 |
| `PlaneDraftPreviewService` | Plane/Services/ | ✅ 好 |
| `PlaneCommandHandler` | Plane/Commands/ | ✅ 好 |
| `PlaneDragIntent` | PlaneCanvasView.swift 内 | ⚠️ 私有 | 提取为 `PlaneGestureIntent` 到单独文件 |
| `GalleryDrawerView` | CoreHome/ | ⚠️ `Drawer` 不准确 | 应该是 `GalleryPanelView` 或 `ProjectGalleryView` |
| `CoreHomeResponsiveContainer` | CoreHome/Layout/ | ✅ 好 |
| `FluidCoreHomeMetrics` | CoreHome/Layout/ | ⚠️ `Fluid` 词意模糊 | `CoreHomeSizingMetrics` 或 `CoreHomeDimensionMetrics` |
| `PencilDrawingRepresentable` | FeatureUtilities/Handwriting/ | ⚠️ `Representable` 是 UIKit 桥接模式 | `PencilCanvasWrapper` 或 `PencilCanvasBridge` |
| `CollectorWorkspaceState` | State/ | ⚠️ 职责过多名称不体现 | 应拆分为多个文件 |
| `PadCoreHomeLayout` / `PhoneCoreHomeLayout` | CoreHome/Layout/ | ✅ 好 |
| `PlaneToolActions` | Plane/Tools/ | ⚠️ 空文件 | 填充或删除 |
| `plane.boxSelect` | PlaneToolIDs.swift | ⚠️ 未实现 | 清理或实现 |
| `PlaneIntersectionPreviewResolver` | Plane/Services/ | ✅ 具体明确 |

### 14.2 目录结构评估

```
CalculatorModules/Plane/
├── Commands/              ← ✅ 好
├── Interaction/           ← ✅ 好
├── Rendering/             ← ✅ 好
├── Services/              ← ✅ 好（23 个服务文件略多，但职责明确）
├── Tools/                 ← ✅ 好（PlaneToolActions 空文件需处理）
└── Views/                 ← ✅ 好（4 个文件）
```

```
CoreHome/
├── Background/            ← ✅ 好
├── Layout/                ← ✅ 好（5 个文件）
├── Mocks/                 ← ✅ 好（但有且仅有 HomeMockProjectStore）
├── Preview/               ← ✅ 好
├── CoreHomeView.swift     ← ✅ 顶层 View
├── CoreHomeState.swift    ← ✅ ViewModel
├── CoreHomeUIState.swift  ← ✅ 纯 UI 状态
├── GalleryDrawerView.swift ← ⚠️ 过胖
├── ProjectCardView.swift  ← ✅
├── ProjectThumbnailView.swift ← ✅
└── (GalleryTabBar.swift, 其他) ← ✅ 提取了 TabBar
```

### 14.3 问题

1. **`GalleryDrawerView.swift` 命名与胖度不匹配**：命名为 Drawer 但包含 tab bar、sidebar、batch actions、rename sheet。

2. **`CollectorWorkspaceState.swift` 在 `State/` 目录但包含业务逻辑和 I/O**：应该拆分为 `CollectorUIState`、`CollectorService`、`PencilStrokeRepository`。

3. **`PlaneToolActions.swift` 空文件**：占位符遗留。

4. **PlaneCanvasView.swift 内定义 7 个 payload struct**：应该移到 `PlaneCommandPayloads.swift`。

---

## 15. 建议重构顺序

### P0 — 输入事件污染核心模型 / 破坏 undo/redo / 破坏 document consistency

| # | 问题 | 优先级 | 预计工作量 |
|---|------|--------|-----------|
| P0-1 | `PlaneInteractionReducer` 完全未使用，状态机转换散布在 View 中 | **P0** | 2-3天：将状态转换迁移到 reducer，或设计新的 `PlaneConstructionStateMachine` |
| P0-2 | `CanvasState` (视口) 通过 DocumentCommand 持久化到 document 模型 | **P0** | 1-2天：拆分 `ViewportState`（前端）和 `DocumentViewState`（持久化） |
| P0-3 | Pencil stroke 直接落入 `currentDrawingData`，无 stroke session/commit 分层 | **P0** | 3-5天：引入 `StrokeSession` 状态机 + `HandwritingCommandHandler` |
| P0-4 | `CollectorWorkspaceState` 中公式键盘输入直接 upsert + persist 到磁盘，绕过 WorkspaceCommand | **P0** | 2-3天：统一键盘输入路径 |

### P1 — UI 难维护 / 难适配 Apple Pencil / 外接键盘 / iPad 分屏

| # | 问题 | 优先级 | 预计工作量 |
|---|------|--------|-----------|
| P1-1 | `PlaneCanvasView.swift` 923 行过胖 | **P1** | 3-5天：分离手势、状态机、payload、背景 |
| P1-2 | `GalleryDrawerView.swift` 700 行过胖 | **P1** | 1-2天：提取子 View |
| P1-3 | KeyboardShortcutManager 未集成 WorkspaceCommand | **P1** | 1-2天：实现 `KeyboardShortcutHandler` |
| P1-4 | Plane 和 Space 重复手势代码 | **P1** | 2-3天：提取 `CanvasGestureHandler` |
| P1-5 | 两个 `@main` 入口点 | **P1** | 0.5天：统一为单个 `@main` |
| P1-6 | `PhoneCoreHomeLayout` 内联 metrics | **P1** | 0.5天：复用 `FluidCoreHomeMetrics` |
| P1-7 | 无 macOS 专属布局 profile | **P1** | 2-3天：添加 `macWindowed` profile |
| P1-8 | `PlaneCanvasView` 内联 7 个 payload struct | **P1** | 0.5天：提取到 `PlaneCommandPayloads.swift` |

### P2 — 视觉、命名、Preview、重复代码等维护性问题

| # | 问题 | 优先级 | 预计工作量 |
|---|------|--------|-----------|
| P2-1 | 关键交互视图无 #Preview | **P2** | 2-3天：为 PlaneCanvasView、SpaceCanvasView、PlaneObjectRendererView 添加 Preview + mock |
| P2-2 | Canvas 视觉参数散落（背景色、圆角、阴影） | **P2** | 1天：提取 `CanvasTheme` |
| P2-3 | `PlaneToolActions.swift` 空文件 | **P2** | 0.25天：填充或删除 |
| P2-4 | `boxSelect`、`curve` 工具死代码 | **P2** | 0.5天：清理或实现 |
| P2-5 | `PlaneConstructionMode.functionInput`、`.curveInput` 未使用 | **P2** | 0.5天：清理 |
| P2-6 | `ProjectThumbnailView` 内联 I/O 逻辑 | **P2** | 0.5天：提取 `ThumbnailLoaderService` |
| P2-7 | 命名清理（GalleryDrawerView → GalleryPanelView, FluidCoreHomeMetrics → CoreHomeDimensionMetrics 等） | **P2** | 1天 |
| P2-8 | `CollectorWorkspaceState` 拆分 | **P2** | 3-5天：拆分职责 |

---

## 总结

**eMathica 的项目架构总体上方向正确**：两层命令架构（WorkspaceCommand → DocumentCommand）、前端/后端状态分离（PlaneInteractionState 是纯 @State）、Draft/Preview 管线（给 Plane 公式）都已建立。文档系统通过 `EMathicaDocument.apply()` 提供统一的 mutation 入口。

**主要风险集中在**：
1. **手势状态机未使用 reducer** — 最核心的架构违规（P0）
2. **CanvasState 视口持久化到 document** — undo/redo 行为可能不符合用户预期（P0）
3. **PencilKit 系统完全没有 Draft/Preview/Commit 分层**（P0）
4. **PlaneCanvasView 过胖** — 是架构中最大的单点（P1）
5. **键盘快捷键未集成命令系统**（P1）
6. **Preview/Mock 数据严重不足**（P2）

**推荐优先处理 P0 的三项**（手势 reducer + 视口拆分 + Pencil stroke session），它们直接影响数据一致性和 undo/redo 的正确性。
