# Plane Geometry Dependency Failure Audit

## 1. 本轮是否修改源码

否。

## 2. 审计范围

本轮只读检查了以下测试、模块和文件：

- 测试
  - `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathicaTests/PlaneGeometryDependencyTests.swift`
  - `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathicaTests/PlaneToolingTests.swift`
- Plane 依赖与重算
  - `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CalculatorModules/Plane/Services/PlaneGeometryDependencyRecomputeService.swift`
  - `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CalculatorModules/Plane/Services/PlaneGeometryResolver.swift`
  - `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CalculatorModules/Plane/Services/PlaneIntersectionSolver.swift`
  - `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CalculatorModules/Plane/Commands/PlaneCommandHandler.swift`
- 文档命令与删除路径
  - `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/DocumentSystem/DocumentCommand.swift`
  - `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/DocumentSystem/EMathicaDocument.swift`
  - `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/DocumentSystem/DocumentObjectPatch.swift`
  - `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceState.swift`
- ObjectPanel / Inspector / formatter
  - `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/ObjectPanel/GeometryDependencyPresentation.swift`
  - `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/Inspector/GeometryInspectorPropertyPresenter.swift`
  - `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/Shared/GeometryPropertyFormatter.swift`
  - `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/Shared/PlaneGeometryStubs.swift`

本轮没有修改任何实现、测试或项目配置。

## 3. 测试复现结果

| 命令 | 结果 | 说明 |
|---|---|---|
| `xcodebuild -scheme eMathica -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -derivedDataPath /private/tmp/eMathicaGeomDepAuditDD CODE_SIGNING_ALLOWED=NO test -only-testing:eMathicaTests/PlaneGeometryDependencyTests` | `not completed` | 已进入 simulator 并开始执行，stdout 中观察到多项失败，但本次运行未拿到稳定的最终 XCTest 汇总；中途停止。 |
| `xcodebuild -scheme eMathica -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -derivedDataPath /private/tmp/eMathicaGeomDepAuditDD CODE_SIGNING_ALLOWED=NO test -only-testing:eMathicaTests/PlaneGeometryDependencyTests/staticSegmentSecondaryTextIncludesLengthProperty -only-testing:eMathicaTests/PlaneGeometryDependencyTests/inspectorPointPropertiesIncludeCoordinate -only-testing:eMathicaTests/PlaneGeometryDependencyTests/movingLineCircleSourcesRecomputesDynamicIntersectionPoints -only-testing:eMathicaTests/PlaneGeometryDependencyTests/intersectionNoSolutionTransitionKeepsLastPosition` | `succeeded but unreliable` | 该拆分运行返回 `TEST SUCCEEDED`，但与整套运行观察到的失败不一致，说明单 case 过滤在当前 Swift Testing / XCTest 环境下不适合作为最终证据。 |

本轮在完整执行流中观察到的失败项包括：

- `staticSegmentSecondaryTextIncludesLengthProperty()`
- `inspectorVerticalLineSlopeDisplaysVerticalMarker()`
- `inspectorSegmentPropertiesIncludeEndpointsLengthAndAngle()`
- `inspectorIntersectionPropertiesIncludeSourceIndexAndCoordinateWhenDefined()`
- `movingLineCircleSourcesRecomputesDynamicIntersectionPoints()`
- `intersectionNoSolutionTransitionKeepsLastPosition()`
- `inspectorRayPropertiesIncludeStartDirectionAndAngle()`
- `inspectorLinePropertiesIncludeDirectionVectorSlopeAndAngle()`
- `inspectorCirclePropertiesIncludeCenterRadiusAndDiameter()`
- `staticCircleSecondaryTextIncludesRadiusProperty()`
- `inspectorPointPropertiesIncludeCoordinate()`

## 4. 失败用例总表

| 测试用例 | 当前结果 | 失败类型 | 涉及对象 | 初步原因 | 风险 |
|---|---|---|---|---|---|
| `staticSegmentSecondaryTextIncludesLengthProperty` | 失败 | `IMPLEMENTATION_REGRESSION` | 线段 | WorkspaceKit presenter 路径使用 `PlaneGeometryStubs` 中的空 resolver，无法解析长度属性 | P1 |
| `inspectorVerticalLineSlopeDisplaysVerticalMarker` | 失败 | `IMPLEMENTATION_REGRESSION` | 直线 | Inspector presenter 依赖 resolver/formatter 的几何属性，当前测试上下文命中 stub resolver | P1 |
| `inspectorSegmentPropertiesIncludeEndpointsLengthAndAngle` | 失败 | `IMPLEMENTATION_REGRESSION` | 线段 | 同上，展示层拿不到真实几何解算结果 | P1 |
| `inspectorIntersectionPropertiesIncludeSourceIndexAndCoordinateWhenDefined` | 失败 | `IMPLEMENTATION_REGRESSION` | 交点 | 展示层 resolver 分叉，source index / coordinate 无法稳定产出 | P1 |
| `movingLineCircleSourcesRecomputesDynamicIntersectionPoints` | 失败 | `TEST_OUTDATED` | 线圆交点 | 测试移动了点 `B`，但线仍保持 `y = 0`，交点本来就不应变化；期望值与当前几何事实不一致 | P1 |
| `intersectionNoSolutionTransitionKeepsLastPosition` | 失败 | `TEST_OUTDATED` | 两线交点 | 测试修改后两条线仍然相交，实际上没有进入 `.noSolution`；测试假设已过期 | P1 |
| `inspectorRayPropertiesIncludeStartDirectionAndAngle` | 失败 | `IMPLEMENTATION_REGRESSION` | 射线 | 展示层 resolver 分叉，方向与角度属性缺失 | P1 |
| `inspectorLinePropertiesIncludeDirectionVectorSlopeAndAngle` | 失败 | `IMPLEMENTATION_REGRESSION` | 直线 | 同上 | P1 |
| `inspectorCirclePropertiesIncludeCenterRadiusAndDiameter` | 失败 | `IMPLEMENTATION_REGRESSION` | 圆 | 同上 | P1 |
| `staticCircleSecondaryTextIncludesRadiusProperty` | 失败 | `IMPLEMENTATION_REGRESSION` | 圆 | 同上 | P1 |
| `inspectorPointPropertiesIncludeCoordinate` | 失败 | `IMPLEMENTATION_REGRESSION` | 点 | 同上 | P1 |

## 5. 中点依赖分析

### 当前实现观察

- 中点依赖通过 `geometryDependency` 与 `geometryDefinition.anchors` 记录源点对象。
- `PlaneGeometryDependencyRecomputeService` 会在源点变化后重新计算中点位置。
- 动态中点本身不能直接被普通拖拽更新；当前实现更接近“拖源点，派生对象重算”，而不是“拖派生对象反解源对象”。
- 删除源点时，当前产品路径不是未定义：
  - `unlink` 策略下会清理依赖，保留对象并转为静态；
  - `deleteAffected` 策略下会递归删除下游对象。

### 失败边界判断

- 本轮没有直接观察到中点核心重算 case 的系统性失败。
- 中点更像当前依赖体系里相对稳定的一类对象。
- 因此中点不是当前 `PlaneGeometryDependencyTests` 失败的主要来源。

### 当前结论

- `中点依赖行为`: `PASS / PARTIAL`
- 风险主要在：
  - 删除策略是否被所有测试和后续 fixture 明确覆盖；
  - 保存重开后的依赖持续性是否需要 fixture 级验证。

## 6. 交点依赖分析

### 当前实现观察

- 交点依赖支持：
  - 两线交点
  - 线圆交点
  - 圆圆交点
- `PlaneIntersectionSolver` 和 `PlaneGeometryDependencyRecomputeService.appendIntersectionPatches(...)` 会根据实时几何状态给出：
  - 单解
  - 多解中的指定 `solutionIndex`
  - `noSolution`
- `noSolution` 分支只更新 `geometryDefinitionStatus`，不改位置 patch，因此旧位置会被保留。这与“无解时保留最后可用位置”的产品语义是一致的。

### 失败边界判断

本轮观察到两类不同性质的交点问题：

1. **测试假设已过期**
   - `movingLineCircleSourcesRecomputesDynamicIntersectionPoints`
     - 测试把 `B(2,0)` 改成 `B(3,0)`，但线仍是 `y = 0`。
     - 圆心 `(0,0)` 半径 `1` 时，交点仍是 `(-1,0)` 和 `(1,0)`。
     - 所以“交点应变化”的断言本身不成立。
   - `intersectionNoSolutionTransitionKeepsLastPosition`
     - 测试更新后两线仍存在交点 `(2,0)`，并未进入 `noSolution`。
     - 断言 `.noSolution` 与“保留旧点”不符合当前场景。

2. **展示层/Inspector 层回退**
   - `inspectorIntersectionPropertiesIncludeSourceIndexAndCoordinateWhenDefined`
   - 该失败更像 resolver 边界问题，而不是交点核心依赖图无法重算。

### 当前结论

- `交点重算核心语义`: `PARTIAL`
- `交点展示/Inspector`: `PARTIAL`
- 当前更需要：
  - 先重新基线化交点测试场景；
  - 再决定是否存在真实的实现回退。

## 7. 平行线 / 垂线依赖分析

### 当前实现观察

- 平行线 / 垂线依赖使用“参考线 + 过点”组合保存。
- `PlaneGeometryDependencyRecomputeService` 会基于当前源线和当前点重新生成方向向量。
- 从完整测试流观察，平行线 / 垂线相关的主要依赖测试大多通过，没有进入这次失败名单。

### 删除与保存语义

- 删除参考线或过点时，当前实现同样受 `unlink / deleteAffected` 双策略控制。
- 保存重开层面，本轮没有观察到平行线 / 垂线依赖专门失败的证据。

### 当前结论

- `平行线 / 垂线依赖`: `PASS / PARTIAL`
- 目前它们不是最高优先失败源，但仍应纳入 `Plane-2D-ConstructionDependency` 与 `SaveLoad-GeometryDependency` fixture。

## 8. 线段端点依赖分析

### 当前实现观察

- 线段创建时，`PlaneCommandHandler.handleCreateSegmentWithOptionalPoints(...)` 会把端点写入：
  - `geometryDefinition.anchors = [.object(startPoint.id), .object(endPoint.id)]`
- `PlaneGeometryResolver` 会优先用 anchors 解析端点；同时还保留了对 legacy `computeExpression` 前缀 `segment:<id,id>` 的兼容解析。
- 这说明：
  - 当前模型层确实保存了端点对象引用；
  - 不是“线段只是静态坐标快照”。

### 失败边界判断

- 本轮观察到与线段相关的失败集中在：
  - `staticSegmentSecondaryTextIncludesLengthProperty`
  - `inspectorSegmentPropertiesIncludeEndpointsLengthAndAngle`
- 这两个失败更像展示层无法得到真实几何解析结果，而不是端点依赖本身丢失。

### 当前结论

- `线段端点依赖模型`: `PASS`
- `线段展示层属性读取`: `PARTIAL`

## 9. 删除源对象语义分析

### 当前实现

当前删除源对象语义不是未定义，而是**显式双策略**：

1. `unlink`
   - 删除被选源对象
   - 受影响的派生对象保留
   - 通过 `dependencyCleanupPatchesForRemovedSources(...)` 清空 `geometryDependency`
   - 同时清空 `geometryDefinitionStatus`
   - 结果上等价于“转为静态对象”

2. `deleteAffected`
   - 删除被选源对象
   - 递归删除所有依赖它们的下游对象

### 当前测试关系

- 一部分测试默认假设“删除源对象后派生对象仍然以某种形式存在”。
- 另一部分 fixture 规划又希望验证“保存重开后依赖保持”。
- 这意味着后续必须把：
  - 当前默认 UI 走的是哪条删除策略；
  - fixture 要验证哪条策略；
  - 哪些测试是以 `unlink` 为基准，哪些是以 `deleteAffected` 为基准  
  明确写死，否则后续仍会混乱。

### 后续建议语义

建议保留当前双策略产品语义，不要把它们混成单一路径。

- `unlink`：适合用户希望保留结果对象的场景
- `deleteAffected`：适合保持依赖图整洁的场景

因此这一节更像“测试与 fixture 口径需要明确”，而不是“实现完全没定义”。

## 10. 保存重开语义分析

### 当前实现观察

- `geometryDependency`、`geometryDefinition`、`geometryDefinitionStatus` 都走文档对象持久化。
- `EMathicaDocument.apply(.updateObject)` 会在 patch 未覆盖字段时保留旧值。
- 这使得例如交点进入 `noSolution` 时，旧位置可以在文档模型里继续保留。

### 当前风险

- 本轮没有从失败测试里直接观察到“保存重开后依赖对象必然丢失”的硬证据。
- 但结合上一轮 `SaveLoad Edge Cases Audit`，仍然存在 fixture 级高风险：
  - 依赖对象的 source id 是否在所有对象族都完整保留
  - 删除后转静态对象的状态是否在保存后仍一致
  - `metadata.json` / `document.json` 双写源不会直接破坏 dependency，但会放大调试难度

### 对 `SaveLoad-GeometryDependency` fixture 的影响

- 该 fixture 仍应保持高优先级。
- 当前失败更像：
  - 测试过期
  - presenter boundary 回退
  而不一定是 save/load 核心崩坏。

## 11. P0/P1/P2/P3 问题清单

| 优先级 | 问题 | 影响对象 | 涉及模块 | 建议后续任务 |
|---|---|---|---|---|
| P1 | WorkspaceKit 展示层命中 `PlaneGeometryStubs` 空 resolver，导致点/线/线段/射线/圆/交点的 ObjectPanel / Inspector 属性测试集体失败 | 点、线、线段、射线、圆、交点 | `GeometryDependencyPresentation`、`GeometryInspectorPropertyPresenter`、`PlaneGeometryStubs`、真实 `PlaneGeometryResolver` 边界 | `WorkspaceKit PlaneGeometryResolver Boundary Audit/Fix` |
| P1 | 交点测试场景已与当前几何事实不一致，导致 `movingLineCircleSourcesRecomputesDynamicIntersectionPoints` 与 `intersectionNoSolutionTransitionKeepsLastPosition` 失真 | 交点 | `PlaneGeometryDependencyTests`、`PlaneIntersectionSolver`、`PlaneGeometryDependencyRecomputeService` | `PlaneGeometryDependencyTests Update After Semantics Decision` |
| P1 | 删除源对象存在 `unlink / deleteAffected` 双策略，但 fixture 与测试尚未统一按哪条产品语义验收 | 中点、交点、平行线、垂线、线段等派生对象 | `WorkspaceState`、删除确认链路、geometry cleanup patches | `Delete Source Object Dependency Policy Design` |
| P2 | 保存重开对 geometry dependency 的系统级黄金样例仍未建立，当前只能从零散测试和源码推断 | 所有依赖对象 | DocumentSystem、geometry dependency persistence | `Geometry Dependency SaveLoad Consistency Fix` 前置为 `SaveLoad-GeometryDependency` fixture 创建 |
| P2 | 平行线 / 垂线虽然未在本轮失败名单中，但还没有独立失败审计与 fixture 级回归样例 | 平行线、垂线 | Plane dependency recompute + save/load paths | `Parallel/Perpendicular Dependency Minimal Fix` 前置为 audit/fixture 建立 |
| P3 | 单个 `-only-testing` 过滤结果与整套运行结果不一致，当前 XCTest / Swift Testing 环境对 case 级定位的稳定性不足 | 测试环境 | XCTest runner / simulator filtering | `PlaneGeometryDependencyTests Runner Reliability Audit` |

## 12. 下一轮建议

按当前证据强弱与后续 fixture 优先级，建议下一轮只做以下 4 个最小任务之一：

1. `WorkspaceKit PlaneGeometryResolver Boundary Audit/Fix`
   - 先确认 `PlaneGeometryStubs` 与 app 侧真实 resolver 的边界是否就是当前展示层失败根因。

2. `PlaneGeometryDependencyTests Update After Semantics Decision`
   - 先把两个明显过期的交点测试重新基线化，再继续判断是否还有真实回退。

3. `Delete Source Object Dependency Policy Design`
   - 把 `unlink / deleteAffected` 的产品语义、测试语义、fixture 语义统一写清楚。

4. `Geometry Dependency SaveLoad Consistency Fix`
   - 仅在前面三项边界明确后再做，避免在语义未定前直接改持久化路径。
