# SpaceCalculatorArchitectureAudit-1

## 1. Current Space State

## 1.1 当前 Space 目录状态

当前 `CalculatorModules/Space` 只有占位视图：

- `CalculatorModules/Space/Views/SpaceCalculatorPlaceholderView.swift`

未发现以下实现：

1. `SpaceCanvasView`
2. `SpaceToolProvider`
3. `SpaceCommandHandler`
4. Space 专属 interaction/reducer/service 层

结论：当前 Space 仍是占位模块，尚未进入 3D 功能实现阶段。

## 1.2 模块注册现状

- `CalculatorModuleRegistry` 已注册 `space` 模块（标题/图标/副标题已配置）。
- 但 `space` 当前走 `DefaultWorkspaceModuleProvider`（通用工具组），并未接入 Space 专属 provider。

## 1.3 3D 类型现状

当前仅有 2D 相关：

- `WorldPoint` / `CanvasState` / `Viewport` / `GraphCamera`
- `GeometryDefinition` 仅支持 `point/segment/line/ray/circle`

未发现 3D 坐标与 3D 相机类型。

---

## 2. Reusable Plane Architecture

## 2.1 可复用层（推荐直接复用）

1. Workspace shell（`WorkspaceView` + module provider 机制）
2. Object panel 框架（行组件、菜单、选中逻辑）
3. Inspector 面板框架（section + presenter 模式）
4. `WorkspaceCommand` / `DocumentCommand` dispatch 机制
5. `EMathicaDocument` 包结构与 `.emathica` codec
6. Session Undo/Redo/Revert（snapshot model）
7. ObjectHistoryRecovery（deleted history + restore）
8. Save/Load/Preview/Recent 主链路
9. Tool provider / toolbar 体系
10. GeometryDependency “child-side dependency”设计思想
11. Presenter + diagnostics 分层组织方式

## 2.2 不可直接复用层（需 Space 专属实现）

1. `PlaneGeometryResolver`
2. `PlaneCanvasView`
3. 2D hit test service
4. 2D sampling/rendering pipeline
5. 2D viewport transform
6. 2D intersection solver

---

## 3. Space v0.1 Object Model (Recommended)

## 3.1 最小对象集合

### SpacePoint
- `position3D`（x, y, z）
- 显示：`A = (x, y, z)`

### SpaceSegment
- endpoint A/B（3D）
- length

### SpaceLine
- 推荐表示：`point + direction`
- 备选 two-point anchors（兼容简单但语义较弱）

### SpacePlane
- v0.1 推荐：`point + normal`
- 三点定义可作为工具输入变体（最终归一化到 point+normal）

### SpaceSurface
- `z = f(x, y)` 建议后置，不纳入 v0.1 必做

## 3.2 表示方案取舍

### line：point+direction vs two anchors

推荐 `point+direction`，理由：
1. 语义稳定（无“第二点漂移”问题）
2. 与 3D 几何运算天然匹配
3. 后续平行/垂直关系更好扩展

### plane：point+normal vs three-point-only

推荐 `point+normal` 作为存储真源，理由：
1. 对渲染/命中/求交更直接
2. 可由 three-point 构造并归一化
3. 与 dependency 重算更一致

---

## 4. 3D Coordinate / Camera Design

## 4.1 新增核心类型（v0.1 设计）

1. `WorldPoint3D { x, y, z }`
2. `Vector3D { x, y, z }`
3. `SpaceCameraState`
   - `position`
   - `target`
   - `up`
   - `distance`（或派生）
   - `projectionType`（perspective / orthographic）
   - 可选 `fov` / `near` / `far`（后置）

## 4.2 交互模型

1. orbit rotate
2. pan
3. zoom

## 4.3 持久化与 Undo

建议：

1. 相机状态写入 document（类似 2D `canvasState`）
2. 相机交互进入 Undo（同样做手势合并）
3. preview 使用保存时的 camera snapshot

## 4.4 与现有 `canvasState` 的关系

不建议把 3D 相机硬塞进现有 2D `canvasState`。  
推荐新增独立字段：`spaceCameraState`（或 module-scoped camera state）。

理由：
1. 2D/3D 语义差异大
2. 避免 2D 分支污染
3. 后续可按模块演进而不破坏 Plane

---

## 5. GeometryDefinition Strategy

## 5.1 方案比较

### 方案 A：扩展现有 `GeometryDefinition`

新增 kind：
- `point3D`
- `segment3D`
- `line3D`
- `plane3D`
- `surface3D`

优点：
1. 复用 MathObject + patch + save/load 主链路
2. 统一对象体系，迁移成本低
3. 与 Undo/Recovery/Inspector 管线兼容性更好

风险：
1. 2D/3D kind 混合，需要 resolver 侧按模块隔离

### 方案 B：新增 `SpaceGeometryDefinition`

优点：
1. 3D 边界最清晰

风险：
1. DocumentObjectPatch/Inspector/ObjectPanel 分叉更重
2. save/load 与 presenter 成本增大

## 5.2 推荐

**v0.1 推荐方案 A**：扩展现有 `GeometryDefinition`。  
前提：明确模块隔离（Plane resolver 不读 3D kind；Space resolver 不读 2D kind）。

---

## 6. Dependency Strategy

## 6.1 v0.1 依赖关系建议

建议先规划以下 3D dependency（可先设计后实现）：

1. `midpointOfPoints3D`
2. `lineThroughPoints3D`
3. `planeThroughThreePoints3D`

后置：
- 平行/垂直 3D 关系
- line-plane / plane-plane 求交

## 6.2 模型扩展建议

优先推荐：扩展现有 `GeometryDependencyKind`，增加 3D case。  
理由：
1. 保持 child-side dependency 思路一致
2. source-removal / convert-to-independent / history 机制可复用

## 6.3 状态模型

3D 继续沿用 `geometryDefinitionStatus`：
- defined / noSolution / missingSource / unsupported / invalid

---

## 7. Tool Scope (Space v0.1)

## 7.1 必做（推荐）

1. select
2. point3D
3. segment3D
4. line3D
5. plane3D
6. camera orbit/pan/zoom

## 7.2 可选（v0.1.5）

1. midpoint3D
2. line-plane intersection
3. plane-plane intersection

## 7.3 后置

1. sphere/cylinder/cone
2. surface `z=f(x,y)` / parametric surface
3. tangent plane / normal vector tools
4. mesh editing

---

## 8. Rendering Approach Recommendation

## 8.1 方案对比

1. SwiftUI + Canvas + 自定义投影（wireframe）
   - 优点：轻量、可控、与现有 Workspace 风格一致
   - 风险：需自行处理遮挡/深度体验

2. SceneKit
   - 优点：3D 能力现成，交互和摄像机基础设施较成熟
   - 风险：与现有 2D 管线和样式体系融合成本更高

3. RealityKit
   - 对 v0.1 过重，建议后置

4. Metal
   - 明确后置（工程复杂度过高）

## 8.2 v0.1 推荐路线

**推荐：先做自定义 3D->2D 投影 + SwiftUI Canvas wireframe。**

理由：
1. 先验证对象模型与交互闭环
2. 与现有 document/undo/object panel 管线耦合最低
3. 可在 v0.2 再评估 SceneKit/Metal 迁移

---

## 9. Save / Load / Preview Strategy

1. Space 对象继续进入 `document.objects`
2. 新增 camera state 持久化字段（建议 `spaceCameraState`）
3. preview 按 camera snapshot 渲染静态封面
4. recent 继续通过 module type 区分（现有 module registry 可复用）
5. ObjectHistoryRecovery 对 Space 可直接复用
6. Undo/Revert 可直接复用 snapshot 机制

---

## 10. Object Panel / Inspector Strategy

## 10.1 Object row（v0.1）

建议最小显示：
1. point3D：坐标
2. segment3D：长度
3. line3D：方向摘要
4. plane3D：法向摘要

## 10.2 Inspector（v0.1）

1. point：x/y/z
2. segment：端点/长度
3. line：point/direction
4. plane：point/normal/方程摘要

## 10.3 格式化

建议新增 `SpaceGeometryPropertyFormatter`，不要直接挤占 2D formatter。  
可复用命名与规则风格，但保持 2D/3D 分离。

---

## 11. Implementation Roadmap

1. `SpaceArchitecture-1`（本轮）
2. `SpaceMathCore-1`
   - WorldPoint3D / Vector3D / CameraState / projection math
3. `SpaceDocumentModel-1`
   - geometry kind 扩展 / camera state / save-load
4. `SpaceCanvas-1`
   - wireframe 3D viewport + orbit/pan/zoom
5. `SpaceTools-1`
   - point/segment/line/plane
6. `SpaceInspector-1`
   - 3D object properties
7. `SpaceUndoSaveLoad-1`
   - undo/save/recover/preview 验收

---

## 12. Risks

1. 2D/3D kind 混用导致 resolver 误读
2. camera state 与 2D canvas state 语义冲突
3. 3D hit test 与选择体验复杂度上升
4. preview 渲染性能与一致性风险
5. 早期过度扩工具集导致范围失控

控制策略：
1. v0.1 先做 wireframe + 最小对象集
2. 严格分离 Space resolver 与 Plane resolver
3. 优先闭环：工具 -> 保存 -> 重开 -> Undo -> 预览

