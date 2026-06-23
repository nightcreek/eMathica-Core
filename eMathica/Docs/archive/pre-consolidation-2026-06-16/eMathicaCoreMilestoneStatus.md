# eMathica Core Milestone Status

## 1. Milestone Summary

当前 eMathica 已形成两个核心计算器基线：

- Plane v1 Core
- Space v0.1 Core

当前阶段规则：

1. 两条主线均进入 **bugfix-only**。
2. 不再向 Core 冻结范围继续塞新功能。
3. 新能力必须走独立路线、独立验收与独立冻结文档。

---

## 2. Plane v1 Core Status

### Completed

- Plane geometry tools v1
- Dynamic Geometry v1
- line / circle / intersection dependency
- geometry status：`defined / noSolution / missingSource / unsupported / invalid`
- object row source/status 展示
- Geometry Inspector 属性展示
- GeometryPropertyFormatter（格式统一）
- Dependency deletion policy（含单删/批删）
- Session Undo/Redo/Revert
- Save/Load/Preview/Recent
- ObjectHistoryRecovery v1
- 真机验收 P0 修复闭环

### Frozen (bugfix-only)

- DynamicGeometry v1
- CircleCreationPolicy
- DependencyDeletionPolicy
- SessionUndoRedo
- SaveLoad/Preview/Recent baseline
- ObjectPanel text structure
- GeometryInspector properties
- GeometryPropertyFormatter
- ObjectHistoryRecovery v1

### Deferred

- clear deleted history
- batch restore
- restore dynamic relation
- dependency graph UI
- legacy helper point cleanup
- 删除确认 “不再提示” preference
- status icon polish
- 三点圆 / 切线 / 圆弧 / 多边形
- sampling accuracy 与 art sampling（独立路线）

---

## 3. Space v0.1 Core Status

### Completed

- SpaceMathCore
- SpaceDocumentModel
- SpaceCanvas
- SpaceCanvasVisualFix
- SpaceTools：point3D / segment3D / line3D / plane3D
- SpaceHitTest
- SpaceSnapping
- SpaceWorkPlane：XY / YZ / ZX
- SpaceInspector
- SpacePreview
- SpaceV0.1DeviceAcceptanceRunbook

### Frozen (bugfix-only)

- SpaceMathCore v0.1
- SpaceDocumentModel v0.1
- SpaceCanvas v0.1
- SpaceTools v0.1
- SpaceHitTest v0.1
- SpaceSnapping v0.1
- SpaceWorkPlane v0.1
- SpaceInspector v0.1
- SpacePreview v0.1

### Deferred

- Space CAS
- `z=f(x,y)` surface
- `z=y -> plane3D` classifier
- 3D dependency
- dynamic plane
- arbitrary work plane
- selected plane as work plane
- 3D drag editing
- SceneKit / Metal
- snapping visual indicator
- advanced camera controls

---

## 4. Shared Infrastructure Status

当前可复用主干能力：

- Workspace shell
- Tool/toolbar framework
- DocumentSystem / `.emathica`
- Save/Load
- Preview
- Recent
- Undo/Redo/Revert
- ObjectHistoryRecovery
- Object Panel framework
- Inspector framework
- GeometryDefinition model
- Geometry status model
- formatter/presenter pattern

复用边界说明：

- Plane 与 Space 共用上述主干。
- Plane 专属实现（PlaneCanvas / PlaneResolver / PlaneHitTest / PlaneSampling）不直接复用于 Space。
- Space 采用独立实现（SpaceCanvas / SpaceWireframeRenderer / SpaceGeometryResolver / SpaceHitTest）。

---

## 5. Current Stability Rule

1. Plane v1 Core：bugfix-only  
2. Space v0.1 Core：bugfix-only  
3. 任何新增能力必须独立立项  
4. 每条新路线必须包含：
   - audit
   - implementation slices
   - tests
   - device acceptance runbook
   - freeze/status document

---

## 6. Next Routes

### Route A: Stabilization
- 持续真机验收
- 仅修 bug
- 当前默认推荐路线

### Route B: Sampling Accuracy
- tan/asymptote
- discontinuity splitting
- high-frequency function sampling
- implicit sampling audit

### Route C: Artistic Sampling
- viewport-reactive sampling
- zoom trace / kaleidoscope-like behavior
- sampling style presets
- export image/video（后置）

### Route D: Space Dynamic Geometry
- 3D dependency model
- midpoint3D
- line through points dynamic
- plane through points dynamic
- source-removal/status model（Space）

### Route E: Space Expression / CAS
- `z=f(x,y)`
- parametric curve
- parametric surface
- implicit surface
- expression-to-geometry classifier

### Route F: Rendering Upgrade
- wireframe style持续升级
- depth sorting 增强
- SceneKit/Metal 评估
- advanced camera controls

---

## 7. Recommended Priority

推荐顺序：

1. **Stabilization（短期默认）**  
2. **SamplingAccuracy 或 ArtisticSampling（独立路线推进）**  
3. **Space Dynamic Geometry（中期）**  
4. **Space Expression/CAS（需更完整设计后）**  
5. **Rendering Upgrade（后置评估）**

目标导向建议：

- 若目标是“数学艺术表达”：优先 ArtisticSampling。
- 若目标是“数学工具稳定与准确性”：优先 SamplingAccuracy。
- 若目标是“Space 功能成长”：优先 Space Dynamic Geometry。

---

## 8. Current No-Go List

- 不在 Plane v1 Core 继续塞新工具
- 不在 Space v0.1 Core 继续塞 CAS/曲面/dependency
- 不将 `z=y` 自动当作 plane3D
- 不把 sampling art 混入普通采样准确性修复
- 不把 SceneKit/Metal 视为当前必要项
- 不做 HarmonyOS 适配
- 不做低版本适配
- 不做大规模 UI 图标微调任务

---

## 9. Acceptance Baseline

当前验收基线文档：

- Plane device acceptance runbook
- Space v0.1 device acceptance runbook

执行规则：

- 后续 bugfix 尽量回归对应 runbook。
- 新路线必须新增自己的 runbook，不复用旧 runbook 直接代替。

---

## 10. Final Rule

当前 eMathica Core Milestone 已进入稳定化阶段。  
**Plane v1 Core 与 Space v0.1 Core 均冻结为 bugfix-only。**  
后续新增能力必须进入独立路线，不得直接混入核心冻结范围。
