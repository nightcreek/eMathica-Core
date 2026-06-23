# P0-1 重构实施方案：PlaneInteractionReducer / PlaneConstructionStateMachine

**目标**：将 `PlaneCanvasView` 中散落的 `interactionState` 直接修改迁移到 `PlaneInteractionReducer`（或重命名为 `PlaneConstructionStateMachine`），使状态转换集中化、可测试、可审计。

**原则**：每一步都能编译，不改变外部行为，不动 `PlaneCanvasView` 以外的文件。

---

## 1. 所有 interactionState 直接修改位置清单

通过 grep `interactionState\.`（含 `.`）共找到 **45 处**引用，其中 **31 处为修改操作**，**14 处为只读操作**。

### 1.1 只读操作（保留在 View）

| # | 行号 | 代码 | 用途 |
|---|------|------|------|
| R1 | 36 | `interactionState.constructionPreview` | 传给 PlaneObjectRendererView 渲染 |
| R2 | 49 | `interactionState.draggingObjectID` | onChange 中检查是否有正在拖拽的对象 |
| R3 | 269 | `interactionState.constructionHintText` | 构造提示浮层显示 |
| R4 | 339 | `interactionState.draggingObjectID` | pointDragGesture 取当前拖拽 ID |
| R5 | 344 | `interactionState.draggingObjectID` | pointDragGesture end 取拖拽 ID |
| R6 | 354 | `interactionState.activeConstruction` | handleSegmentTap 分支判断 |
| R7 | 373 | `interactionState.activeConstruction` | handleCircleTap 分支判断 |
| R8 | 375 | `interactionState.pendingWorldPoint` | handleCircleTap 取圆心 |
| R9 | 395 | `interactionState.activeConstruction` | handleArcTap 分支判断 |
| R10 | 427 | `interactionState.activeConstruction` | handleLineTap 分支判断 |
| R11 | 446 | `interactionState.activeConstruction` | handleRayTap 分支判断 |
| R12 | 467 | `interactionState.activeConstruction` | handleIntersectionTap 分支判断 |
| R13 | 488 | `interactionState.activeConstruction` | handleMidpointTap 分支判断 |
| R14 | 510/526 | `interactionState.activeConstruction` | handleParallelTap 分支判断 |
| R15 | 550/566 | `interactionState.activeConstruction` | handlePerpendicularTap 分支判断 |
| R16 | 789~867 | `interactionState.activeConstruction` (多处) | constructionPreviewGesture 中读 activeConstruction 和 pendingWorldPoint |

### 1.2 修改操作（需要迁移）

按语义分为 **7 类**：

#### 类 S1: resetAll — 完全重置状态

| # | 行号 | 代码 | 触发时机 |
|---|------|------|----------|
| M1 | 52 | `interactionState = PlaneInteractionState()` | activeToolID 变化 |
| M2 | 309 | `interactionState.clearConstructionProgress()` | 用户点击 Cancel 按钮 |

#### 类 S2: startDrag / endDrag — 拖拽生命周期

| # | 行号 | 代码 | 触发时机 |
|---|------|------|----------|
| M3 | 333-334 | `interactionState.draggingObjectID = lockedID; isDraggingObject = true` | pointDragGesture began |
| M4 | 347-348 | `interactionState.draggingObjectID = nil; isDraggingObject = false` | pointDragGesture ended |

#### 类 S3: startConstruction — 第一击：进入构造模式

| # | 行号 | 代码 | 工具 |
|---|------|------|------|
| M5 | 365-368 | 设 `activeConstruction`, `pendingWorldPoint`, `pendingPointID`, `constructionPreview` | segment 第一击 |
| M6 | 387-390 | 同上 | circle 第一击 |
| M7 | 417-422 | 同上 (preview = nil) | arc 第一击 |
| M8 | 438-441 | 同上 + preview | line 第一击 |
| M9 | 457-460 | 同上 | ray 第一击 |
| M10 | 474-475 | 设 `activeConstruction`, `constructionPreview = nil` | intersection 第一击 |
| M11 | 495-501 | 设 `activeConstruction`, `pendingPointID`, `pendingWorldPoint`, `constructionPreview = nil` + dispatch select | midpoint 第一击 |
| M12 | 519-522 | 设 `activeConstruction`, 清 `pendingPointID/WorldPoint`, `preview = nil` + dispatch select | parallel 选参考对象 |
| M13 | 535-541 | 设 `activeConstruction`, `pendingPointID/WorldPoint`, `preview = nil` + dispatch select | parallel 选点 |
| M14 | 559-562 | 同上（清 pending） | perpendicular 选参考对象 |
| M15 | 575-581 | 同上（设 pending） | perpendicular 选点 |

#### 类 S4: advanceStep — 非最后一击的状态推进

| # | 行号 | 代码 | 工具 |
|---|------|------|------|
| M16 | 397-405 | 将 `arcSecondPoint` → `arcThirdPoint`（设 activeConstruction, pendingWorldPoint/ID, preview = nil） | arc 第二击 |

#### 类 S5: completeConstruction — 最后一击：创建对象

| # | 行号 | 代码 | 工具 |
|---|------|------|------|
| M17 | 362 | `interactionState = PlaneInteractionState()` (segment 创建后) | segment 第二击 |
| M18 | 382-384 | `interactionState = PlaneInteractionState(activeConstruction: .circleCenter)` (保留 circleCenter, 支持连画) | circle 第二击 |
| M19 | 414 | `interactionState = PlaneInteractionState(activeConstruction: .arcFirstPoint)` (保留 arcFirstPoint, 支持连画) | arc 第三击 |
| M20 | 435 | `interactionState = PlaneInteractionState()` (line 创建后) | line 第二击 |
| M21 | 454 | `interactionState = PlaneInteractionState()` (ray 创建后) | ray 第二击 |
| M22 | 470 | `interactionState = PlaneInteractionState()` (intersection 创建后) | intersection 第二击 |
| M23 | 485 | `interactionState = PlaneInteractionState()` (midpoint 基于 segment) | midpoint segment 点击 |
| M24 | 491 | `interactionState = PlaneInteractionState()` (midpoint 基于两点) | midpoint 第二点 |
| M25 | 516 | `interactionState = PlaneInteractionState()` (parallel 从 reference+point) | parallel 第二击 |
| M26 | 532 | `interactionState = PlaneInteractionState()` (parallel 从 point→reference) | parallel 第二击（另一种顺序） |
| M27 | 556 | `interactionState = PlaneInteractionState()` | perpendicular 第二击 |
| M28 | 572 | `interactionState = PlaneInteractionState()` | perpendicular 第二击（另一种顺序） |

#### 类 S6: updatePreview — 实时预览更新（构造拖拽中）

| # | 行号 | 代码 | 工具 |
|---|------|------|------|
| M29 | 791/795 | `interactionState.constructionPreview = .temporarySegment(...)` | segment 拖拽预览 |
| M30 | 802/806 | `interactionState.constructionPreview = .temporaryLine(...)` | line 拖拽预览 |
| M31 | 813/817 | `interactionState.constructionPreview = .temporaryRay(...)` | ray 拖拽预览 |
| M32 | 825/829 | `interactionState.constructionPreview = .temporaryCircle(...)` | circle 拖拽预览 |
| M33 | 842/844 | `interactionState.constructionPreview = .temporaryArc(...)` 或 nil (无效弧) | arc 拖拽预览 |
| M34 | 851/856 | `interactionState.constructionPreview = nil` (无 target 或无交点) | intersection 拖拽预览 |
| M35 | 864 | `interactionState.constructionPreview = .temporaryIntersections(...)` | intersection 交点预览 |

#### 类 S7: completeConstructionWithRestart — 创建后重置到特定起始状态

| # | 行号 | 代码 | 工具 |
|---|------|------|------|
| M36 | 382-384 | 同 M18：保留 circleCenter 支持连画 | circle |
| M37 | 414 | 同 M19：保留 arcFirstPoint 支持连画 | arc |

---

## 2. Event 枚举设计

将 `PlaneInteractionReducer` / `PlaneInteractionEvent` 替换为完整事件集：

```swift
// 文件: PlaneInteractionEvent.swift (新建，替换原 PlaneInteractionReducer.swift)

enum PlaneInteractionEvent: Hashable {
    // ── 全量重置 ──
    /// 工具切换或用户主动取消，清空所有构造进度
    case resetAll

    // ── 拖拽生命周期 ──
    /// 开始拖拽一个已有点
    case startDragging(objectID: UUID)
    /// 结束拖拽
    case endDragging

    // ── 构造状态推进 ──
    /// 第一击：根据工具 id 和点击位置进入构造模式
    /// toolID: 当前工具标识
    /// location: 点击的世界坐标
    /// hitPointID: 如果点击在已有点上，该点的 UUID
    case beginConstruction(toolID: String, worldPoint: WorldPoint, hitPointID: UUID?)

    /// 构造中间步骤推进（非最终步）
    /// hitPointID: 可选已有点 ID
    case advanceConstruction(worldPoint: WorldPoint, hitPointID: UUID?)

    /// 构造最终步 → 创建对象
    /// View 层应该先调这个事件，然后读取 state 判断是否需要 dispatch WorkspaceCommand
    case completeConstruction(worldPoint: WorldPoint, hitPointID: UUID?)

    // ── 实时预览更新 ──
    /// 构造拖拽中更新预览位置
    case updatePreview(screenLocation: CGPoint, worldPoint: WorldPoint, hitPointID: UUID?)
}
```

**设计说明**：
- 不将 `toolID` 的 11 路分发放入 reducer —— tool 分发仍然是 View 的职责（因为是 `activeToolID` 的 SwiftUI 绑定）。
- `beginConstruction` 处理类 S3（第一击进入构造模式）
- `advanceConstruction` 处理类 S4（arc 第二击 → 第三击）
- `completeConstruction` 处理类 S5+S7（最后一击，需要 dispatch WorkspaceCommand 的副效应）
- `updatePreview` 处理类 S6（纯粹是 constructionPreview 字段更新）
- `resetAll` 处理类 S1
- `startDragging`/`endDragging` 处理类 S2

---

## 3. Reducer 完整实现

```swift
// 文件: PlaneInteractionEvent.swift（或 PlaneConstructionStateMachine.swift）

enum PlaneInteractionReducer {

    /// 核心 reduce 函数：接收事件，修改状态，返回需要 View 层执行的 side effect
    static func reduce(
        state: inout PlaneInteractionState,
        event: PlaneInteractionEvent
    ) -> PlaneInteractionEffect? {

        switch event {

        // ── 全量重置 ──
        case .resetAll:
            state = PlaneInteractionState()
            return nil

        // ── 拖拽 ──
        case .startDragging(let objectID):
            state.draggingObjectID = objectID
            state.isDraggingObject = true
            // View 层需要同步 dispatch .setObjectDragging(id:isDragging: true)
            return .setDragging(id: objectID, isDragging: true)

        case .endDragging:
            let draggingID = state.draggingObjectID
            state.draggingObjectID = nil
            state.isDraggingObject = false
            if let draggingID {
                return .setDragging(id: draggingID, isDragging: false)
            }
            return nil

        // ── 第一击：进入构造模式 ──
        case .beginConstruction(let toolID, let worldPoint, let hitPointID):
            return reduceBeginConstruction(
                state: &state,
                toolID: toolID,
                worldPoint: worldPoint,
                hitPointID: hitPointID
            )

        // ── 中间步 ──
        case .advanceConstruction(let worldPoint, let hitPointID):
            return reduceAdvanceConstruction(
                state: &state,
                worldPoint: worldPoint,
                hitPointID: hitPointID
            )

        // ── 最后一步 ──
        case .completeConstruction(let worldPoint, let hitPointID):
            return reduceCompleteConstruction(
                state: &state,
                worldPoint: worldPoint,
                hitPointID: hitPointID
            )

        // ── 预览更新 ──
        case .updatePreview(_, let worldPoint, let hitPointID):
            return reduceUpdatePreview(
                state: &state,
                worldPoint: worldPoint,
                hitPointID: hitPointID
            )
        }
    }

    // MARK: - Private helpers

    private static func reduceBeginConstruction(
        state: inout PlaneInteractionState,
        toolID: String,
        worldPoint: WorldPoint,
        hitPointID: UUID?
    ) -> PlaneInteractionEffect? {
        switch toolID {
        case "plane.segment":
            state.activeConstruction = .segmentSecondPoint(startWorldPoint: worldPoint, startPointID: hitPointID)
            state.pendingWorldPoint = worldPoint
            state.pendingPointID = hitPointID
            state.constructionPreview = .temporarySegment(start: worldPoint, current: worldPoint)
            return nil

        case "plane.line":
            state.activeConstruction = .lineSecondPoint(startWorldPoint: worldPoint, startPointID: hitPointID)
            state.pendingWorldPoint = worldPoint
            state.pendingPointID = hitPointID
            state.constructionPreview = .temporaryLine(pointA: worldPoint, pointB: worldPoint)
            return nil

        case "plane.ray":
            state.activeConstruction = .raySecondPoint(startWorldPoint: worldPoint, startPointID: hitPointID)
            state.pendingWorldPoint = worldPoint
            state.pendingPointID = hitPointID
            state.constructionPreview = .temporaryRay(start: worldPoint, through: worldPoint)
            return nil

        case "plane.circle":
            state.activeConstruction = .circleRadius(centerPointID: hitPointID)
            state.pendingWorldPoint = worldPoint
            state.pendingPointID = hitPointID
            state.constructionPreview = .temporaryCircle(center: worldPoint, currentRadiusPoint: worldPoint)
            return nil

        case "plane.arc":
            state.activeConstruction = .arcSecondPoint(firstWorldPoint: worldPoint, firstPointID: hitPointID)
            state.pendingWorldPoint = worldPoint
            state.pendingPointID = hitPointID
            state.constructionPreview = nil
            return nil

        case "plane.intersection":
            guard let hitObjectID = hitPointID.map({ UUID(uuidString: $0.uuidString)! }) ?? state.pendingPointID else {
                // 实际此路径需要由 View 传 objectID。重新设计：
                // beginConstruction 对 intersection 传的是 objectID 而非 pointID
                // 下面单独处理
                return .selectObject(id: nil) // no-op, shouldn't happen
            }
            state.activeConstruction = .intersectionSecondObject(firstObjectID: hitObjectID)
            state.constructionPreview = nil
            return .selectObject(id: hitObjectID)

        default:
            return nil
        }
    }

    // ... 其余辅助方法类似
}
```

### PlaneInteractionEffect — 返回给 View 的副效应

```swift
// 文件: PlaneInteractionEvent.swift

/// reduce 函数返回的副效应，由 View 执行
enum PlaneInteractionEffect: Hashable {
    case selectObject(id: UUID)
    case clearSelection
    case setDragging(id: UUID, isDragging: Bool)
    /// 需要 View 创建几何对象（encode payload + dispatch moduleSpecific）
    case createGeometry(constructionMode: PlaneConstructionMode)
}
```

---

## 4. 迁移顺序（6 步，每步可编译）

### Step 1：原地替换 `PlaneInteractionReducer` / `PlaneInteractionEvent`

**目标**：只改 `PlaneInteraction/` 目录，不改 `PlaneCanvasView`。

**操作**：
1. 在 `PlaneInteractionReducer.swift` 中删除旧的 `PlaneInteractionReducer` 和 `PlaneInteractionEvent`。
2. 新建 `PlaneConstructionStateMachine.swift` 包含新的完整事件枚举和 reducer（如第 3 节所示）。
3. 旧的 `PlaneInteractionReducer` 文件保留但标记为 `@available(*, deprecated)` 并改为调用新 reducer。

**编译验证**：其他文件引用旧的 `PlaneInteractionEvent.reset`，deprecated + 桥接后应能编译。

**状态**：编译 ✅，View 未变 ❌

### Step 2：View 中使用新事件（替换 M1-M3 的三处全量重置）

**目标**：将 `PlaneCanvasView` 中 `interactionState` 的最简单修改替换为 reducer 调用。

**修改 View 中 2 个位置**：

```swift
// 原 M1 (line 52): .onChange(of: activeToolID) { ... interactionState = PlaneInteractionState() ... }
// 改为：
PlaneInteractionReducer.reduce(state: &interactionState, event: .resetAll)

// 原 M2 (line 309): cancelCurrentConstruction() { interactionState.clearConstructionProgress() }
// 改为：
func cancelCurrentConstruction() {
    PlaneInteractionReducer.reduce(state: &interactionState, event: .resetAll)
}
```

**编译验证**：2 处修改，reducer 已存在，编译通过。

**状态**：编译 ✅

### Step 3：迁移拖拽状态（M3-M4）

**目标**：将 `pointDragGesture` 中的 `interactionState.draggingObjectID = ...` 替换为 reducer。

**修改 `pointDragGesture` 中 2 处**：

```swift
// 原 M3 (line 332-334):
// interactionState.draggingObjectID = lockedID
// interactionState.isDraggingObject = true
// 改为：
let effect = PlaneInteractionReducer.reduce(state: &interactionState, event: .startDragging(objectID: lockedID))
if case .setDragging(let id, _) = effect {
    dispatch(.setObjectDragging(id: id, isDragging: true))
}

// 原 M4 (line 347-348):
// interactionState.draggingObjectID = nil
// interactionState.isDraggingObject = false
// 改为：
let effect = PlaneInteractionReducer.reduce(state: &interactionState, event: .endDragging)
if case .setDragging(let id, _) = effect {
    dispatch(.setObjectDragging(id: id, isDragging: false))
}
```

**编译验证**：effect 处理需要加 `if case`，编译通过。

**状态**：编译 ✅

### Step 4：迁移构造第一击（M5-M15）

**目标**：将 `handleSegmentTap`、`handleLineTap` 等 11 处第一击逻辑集中为 `beginConstruction` 事件。

**修改模式**（以 handleSegmentTap 为例）：

```swift
// 原代码：
private func handleSegmentTap(world: WorldPoint, pointID: UUID?) {
    switch interactionState.activeConstruction {
    case .segmentSecondPoint(let startWorldPoint, let startPointID):
        // ... 完整构造
        ...
    default:
        // === 第一击：直接修改 ===
        interactionState.activeConstruction = .segmentSecondPoint(startWorldPoint: world, startPointID: pointID)
        interactionState.pendingWorldPoint = world
        interactionState.pendingPointID = pointID
        interactionState.constructionPreview = .temporarySegment(start: world, current: world)
    }
}

// 改为：
private func handleSegmentTap(world: WorldPoint, pointID: UUID?) {
    switch interactionState.activeConstruction {
    case .segmentSecondPoint(let startWorldPoint, let startPointID):
        // 完整构造：这一块不动（Step 5 处理）
        dispatchSegmentCreation(...)
        PlaneInteractionReducer.reduce(state: &interactionState, event: .resetAll)
    default:
        // 第一击：委托 reducer
        let toolID = activeToolID // "plane.segment" 等
        let _ = PlaneInteractionReducer.reduce(
            state: &interactionState,
            event: .beginConstruction(toolID: toolID, worldPoint: world, hitPointID: pointID)
        )
    }
}
```

对其他类似 `handleLineTap`、`handleRayTap`、`handleCircleTap`、`handleArcTap` 的 `default` 分支做相同修改。

对于 `handleIntersectionTap`、`handleMidpointTap`、`handleParallelTap`、`handlePerpendicularTap` 的 `default` 分支也做相同修改。

**特别处理**: `handleIntersectionTap` 中 `beginConstruction` 的 `hitPointID` 传的是 `firstObjectID`（UUID 而非可能 nil）。因为我们的事件 `beginConstruction` 带 `hitPointID: UUID?`，intersection 实际传入的是 objectID。可以在事件中不加区分，由 View 决定传什么 ID，reducer 根据 toolID 语义解释。

**注意**：handleMidpointTap 等还调用了 `dispatch(.selectObject(id: pointID))`，这个 side effect 现在由 reducer 的返回值 `PlaneInteractionEffect.selectObject` 处理。View 收到 effect 后调用 `dispatch`。

**编译验证**：所有 `default` 分支改为 reducer 调用。需要确认 handleArcTap 的 `advanceStep`（arcSecondPoint→arcThirdPoint）保留不动（Step 6 处理）。

**状态**：编译 ✅

### Step 5：迁移构造完成创建对象（M17-M28）

**目标**：将 `completeConstruction` 中 "resetAll + dispatch WorkspaceCommand" 的逻辑分离。

在 `handleSegmentTap` 等函数的 `.segmentSecondPoint` case 中：

```swift
// 原代码：
case .segmentSecondPoint(let startWorldPoint, let startPointID):
    dispatchSegmentCreation(startWorldPoint: startWorldPoint, startPointID: startPointID,
                            endWorldPoint: world, endPointID: pointID)
    interactionState = PlaneInteractionState()  // ← 这个移到 reducer

// 改为：
case .segmentSecondPoint(let startWorldPoint, let startPointID):
    // dispatch 仍然在 View（它需要访问 PlaneSegmentCreatePayload 等私有点）
    dispatchSegmentCreation(startWorldPoint: startWorldPoint, startPointID: startPointID,
                            endWorldPoint: world, endPointID: pointID)
    // 状态重置委托给 reducer
    let _ = PlaneInteractionReducer.reduce(state: &interactionState, event: .resetAll)
```

对于 circle 和 arc，`completeConstruction` 后还要保留特定起始状态（支持连画）：

```swift
// circle 第二击（M18）：
// 原来：interactionState = PlaneInteractionState(activeConstruction: .circleCenter)
// 改为将“保留 circleCenter”编码为事件
PlaneInteractionReducer.reduce(state: &interactionState, event: .completeConstruction(
    worldPoint: world, hitPointID: pointID
))
// reducer 中 completeConstruction 判断 activeConstruction 类型，
// 如果是 circleRadius 或 arcThirdPoint，重置到 circleCenter / arcFirstPoint 而非完全清空
```

**设计决策**：`completeConstruction` 事件的 reducer 行为是：
- segment → resetAll
- line → resetAll
- ray → resetAll
- intersection → resetAll
- midpoint (segment) → resetAll
- midpoint (two points) → resetAll
- parallel → resetAll
- perpendicular → resetAll
- **circle** → reset 到 `.circleCenter`（支持连画）
- **arc** → reset 到 `.arcFirstPoint`（支持连画）

这样 View 只需要发 `completeConstruction`，不需要知道 reducer 内部的 reset 策略。

**编译验证**：每个 `handle*Tap` 的第二击 case 中的 `interactionState = PlaneInteractionState()` 被替换为 reducer 调用。`dispatch*Creation` 仍然在 View 中。

**状态**：编译 ✅

### Step 6：迁移构造中间步骤和预览更新（M16, M29-M35）

**目标**：将 arc 的 `advanceStep` 和 `constructionPreviewGesture` 中的 7 处 preview 更新放入 reducer。

**6a：arc 中间步骤（M16）**

```swift
// handleArcTap 中 arcSecondPoint case：
case .arcSecondPoint(let firstWorldPoint, let firstPointID):
    // 原来 5 行直接修改：
    // interactionState.activeConstruction = .arcThirdPoint(...)
    // interactionState.pendingWorldPoint = world
    // interactionState.pendingPointID = pointID
    // interactionState.constructionPreview = nil
    // 改为：
    let _ = PlaneInteractionReducer.reduce(
        state: &interactionState,
        event: .advanceConstruction(worldPoint: world, hitPointID: pointID)
    )
```

**6b：constructionPreviewGesture（M29-M35）**

```swift
// 原 constructionPreviewGesture.onChanged 中每个 tool 分支：
// interactionState.constructionPreview = .temporarySegment(start: start, current: current)
// 改为：
let _ = PlaneInteractionReducer.reduce(
    state: &interactionState,
    event: .updatePreview(screenLocation: value.location, worldPoint: current, hitPointID: hitID)
)
```

**重要设计决策**：`updatePreview` 事件需要知道当前 `activeToolID`、`activeConstruction`、对象列表来做 hit-test。有两种设计：

- **方案 A（推荐）**：View 仍负责 hit-test 和工具判断，但将计算后的 preview 值传给 reducer。
  这样做 reducer 变成无状态的简单 setter？那就不值的了。

- **方案 B（更好的）**：View 仍然在 `constructionPreviewGesture.onChanged` 中计算 `PlaneConstructionPreview` 值，但通过 `updatePreview` 事件统一设置。

我们选择 **方案 B 的变体**：让 reducer 处理 `updatePreview` 事件，该事件携带已计算好的 preview 值：

```swift
case .updatePreview(let preview):
    state.constructionPreview = preview
```

这样 View 仍然做计算（hit-test、screenToWorld 等），reducer 做赋值。View 的代码从原来 80 行 `interactionState.constructionPreview = ...` 减少为类似：

```swift
// constructionPreviewGesture.onChanged 中每个分支的最后：
PlaneInteractionReducer.reduce(state: &interactionState, event: .updatePreview(preview))
```

**但这只减少了 1 行**，不是值当的抽取。

**最终决策**：`constructionPreviewGesture` 中的 `interactionState.constructionPreview = ...` 是纯赋值，不需要经过 reducer。此处仍保留直接修改，保证 reducer 不被高频率的拖拽事件冲刷。

**例外**：只在 `constructionPreviewGesture` 之外的 preview 修改（如 M7 `constructionPreview = nil`、M10-M15 中的 `constructionPreview = nil`）走 reducer。

**编译验证**：Step 6a 可编译。`constructionPreviewGesture` 不变。

**状态**：编译 ✅（如果 6b 保留原样）

---

## 5. 保留在 View 中的逻辑

| 逻辑 | 保留原因 |
|------|----------|
| `activeToolID` 的 11 路分发（tapGesture switch） | View 持有 `activeToolID` 绑定，分发应由 View 负责 |
| `screenToWorld` 坐标转换 | 纯几何计算，不涉及状态机 |
| hit-test 调用（`resolvedPointHit`, `hitTestObject` 等） | 依赖 `objects` 和 `canvasState` 两个外部数据源 |
| `dispatch*Creation` 方法（dispatchSegmentCreation 等） | 编码 payload 需要访问私有的 Codable struct |
| `constructionPreviewGesture` 中的 preview 计算 | 高频调用，hit-test 和 world 计算必须就近 |
| `dispatch(.selectObject(id:))` 调用（效果执行） | View 持有 `dispatch` 闭包 |
| `panStartOrigin`/`pinchStartState` 管理 | 纯手势辅助状态，与 construction 无关 |

## 6. 移入 Reducer 的逻辑

| 逻辑 | 原因 |
|------|------|
| `activeConstruction` 状态转换 | 状态机核心，集中化后可测试 |
| `pendingPointID`/`pendingWorldPoint` 的设/清 | 与 `activeConstruction` 耦合 |
| `constructionPreview` 在非拖拽时的清/设 | 与构造步骤耦合 |
| `isDraggingObject`/`draggingObjectID` 的设/清 | 拖拽状态属于交互状态机 |
| `PlaneInteractionEffect` 的生成（selectObject, setDragging） | View 根据 effect 执行 dispatch，分离职责 |

---

## 7. 重构后 PlaneCanvasView 手势处理伪代码

```swift
// tapGesture 简化后：
private func tapGesture(in size: CGSize) -> some Gesture {
    SpatialTapGesture()
        .onEnded { event in
            let location = event.location
            let world = screenToWorld(location, ...)
            let hitID = resolvedPointHit(at: location, ...)?.id

            if activeToolID == "plane.point" {
                dispatch(.createPoint(at: world))
                return
            }
            if activeToolID == "plane.select" { ... return }
            if activeToolID == "plane.delete" { ... return }

            // 构造工具 —— 委托 handleConstructionTap
            handleConstructionTap(toolID: activeToolID, world: world, hitPointID: hitID, location: location)
        }
}

private func handleConstructionTap(toolID: String, world: WorldPoint, hitPointID: UUID?, location: CGPoint) {
    // 读取当前构建状态
    let constructionMode = interactionState.activeConstruction
    let isBuilding = constructionMode != nil && constructionMode != .none

    if !isBuilding {
        // 第一击: delegate to reducer
        let effect = PlaneInteractionReducer.reduce(
            state: &interactionState,
            event: .beginConstruction(toolID: toolID, worldPoint: world, hitPointID: hitPointID)
        )
        applyEffect(effect)
        return
    }

    // 判断当前步是否为最终步
    if isFinalStep(constructionMode) {
        // 最终步: 先创建对象，再更新状态
        dispatchGeometryCreation(constructionMode: constructionMode, world: world, hitPointID: hitPointID)
        let effect = PlaneInteractionReducer.reduce(
            state: &interactionState,
            event: .completeConstruction(worldPoint: world, hitPointID: hitPointID)
        )
        applyEffect(effect)
    } else if isAdvanceStep(constructionMode) {
        // 中间步: 仅更新状态
        let effect = PlaneInteractionReducer.reduce(
            state: &interactionState,
            event: .advanceConstruction(worldPoint: world, hitPointID: hitPointID)
        )
        applyEffect(effect)
    } else {
        // 不应发生
        assertionFailure("Unhandled construction mode: \(constructionMode)")
    }
}

private func isFinalStep(_ mode: PlaneConstructionMode?) -> Bool {
    guard let mode else { return false }
    switch mode {
    case .segmentSecondPoint, .lineSecondPoint, .raySecondPoint,
         .circleRadius, .arcThirdPoint,
         .intersectionSecondObject, .midpointSecondPoint,
         .parallelSecondReference, .perpendicularSecondReference:
        return true
    default:
        return false
    }
}

private func isAdvanceStep(_ mode: PlaneConstructionMode?) -> Bool {
    guard let mode else { return false }
    switch mode {
    case .arcSecondPoint:
        return true
    default:
        return false
    }
}

private func applyEffect(_ effect: PlaneInteractionEffect?) {
    guard let effect else { return }
    switch effect {
    case .selectObject(let id):       dispatch(.selectObject(id: id))
    case .setDragging(let id, let dragging): dispatch(.setObjectDragging(id: id, isDragging: dragging))
    default: break
    }
}
```

---

## 8. 测试策略

重构后的 reducer 是纯函数：`(PlaneInteractionState, PlaneInteractionEvent) -> (PlaneInteractionState, PlaneInteractionEffect?)`。

可以直接编写单元测试：

```swift
// PlaneInteractionReducerTests.swift 测试用例模板

func test_beginConstruction_segment_setsCorrectState() {
    var state = PlaneInteractionState()
    let world = WorldPoint(x: 1, y: 2)

    let effect = PlaneInteractionReducer.reduce(
        state: &state,
        event: .beginConstruction(toolID: "plane.segment", worldPoint: world, hitPointID: nil)
    )

    XCTAssertEqual(state.activeConstruction, .segmentSecondPoint(startWorldPoint: world, startPointID: nil))
    XCTAssertEqual(state.pendingWorldPoint, world)
    XCTAssertNil(state.pendingPointID)
    XCTAssertNotNil(state.constructionPreview)
    XCTAssertNil(effect)
}

func test_completeConstruction_segment_resetsState() {
    var state = PlaneInteractionState()
    state.activeConstruction = .segmentSecondPoint(startWorldPoint: .init(x: 0, y: 0), startPointID: nil)
    state.pendingWorldPoint = .init(x: 0, y: 0)

    let effect = PlaneInteractionReducer.reduce(
        state: &state,
        event: .completeConstruction(worldPoint: .init(x: 3, y: 4), hitPointID: nil)
    )

    XCTAssertEqual(state, PlaneInteractionState())  // 完全重置
    XCTAssertNil(effect)
}

func test_completeConstruction_circle_preservesCircleCenter() {
    var state = PlaneInteractionState()
    state.activeConstruction = .circleRadius(centerPointID: nil)
    state.pendingWorldPoint = .init(x: 0, y: 0)

    let _ = PlaneInteractionReducer.reduce(
        state: &state,
        event: .completeConstruction(worldPoint: .init(x: 5, y: 0), hitPointID: nil)
    )

    XCTAssertEqual(state.activeConstruction, .circleCenter)
    XCTAssertEqual(state.pendingWorldPoint, .init(x: 0, y: 0))
}

func test_advanceConstruction_arc_advancesToThirdPoint() {
    var state = PlaneInteractionState()
    state.activeConstruction = .arcSecondPoint(firstWorldPoint: .init(x: 0, y: 0), firstPointID: nil)

    let _ = PlaneInteractionReducer.reduce(
        state: &state,
        event: .advanceConstruction(worldPoint: .init(x: 1, y: 1), hitPointID: nil)
    )

    guard case .arcThirdPoint = state.activeConstruction else {
        XCTFail("Expected arcThirdPoint, got \(String(describing: state.activeConstruction))")
        return
    }
}
```

---

## 9. 文件变更清单

| 文件 | 操作 | 说明 |
|------|------|------|
| `Plane/Interaction/PlaneInteractionReducer.swift` | **删除** | 替换为新文件 |
| `Plane/Interaction/PlaneConstructionStateMachine.swift` | **新建** | 包含 `PlaneInteractionEvent`、`PlaneInteractionEffect`、`PlaneInteractionReducer` |
| `Plane/Views/PlaneCanvasView.swift` | **修改** | 约 30 处修改（M1-M28），减少约 100 行 |
| `Plane/Interaction/PlaneInteractionState.swift` | **不变** | 仅新增对 `PlaneInteractionEffect` 的 import 可能 |
| `Plane/Interaction/PlaneConstructionMode.swift` | **不变** | 状态机枚举不变 |
| `Plane/Interaction/PlaneConstructionPreview.swift` | **不变** | 预览枚举不变 |

---

## 10. 迁移总工作量估算

| 步骤 | 改动文件数 | 预估工时 | 可测试 |
|------|-----------|---------|--------|
| Step 1: 新事件枚举 + reducer 骨架 | 1 新建 + 1 删除 | 2h | 单元测试即可 |
| Step 2: View 中 resetAll 替换 | 1 修改 | 0.5h | 目测 + 编译 |
| Step 3: 拖拽状态替换 | 1 修改 | 0.5h | 运行拖拽 |
| Step 4: 第一击替换（11 处） | 1 修改 | 2h | 每个工具逐一测试 |
| Step 5: 完成创建替换（12 处） | 1 修改 | 2h | 每个工具逐一测试 |
| Step 6: 中间步替换 | 1 修改 | 0.5h | arc 工具测试 |
| 编写单元测试 | 1 新建 | 2h | ✅ |
| **合计** | **~5 文件** | **~10h** | |
