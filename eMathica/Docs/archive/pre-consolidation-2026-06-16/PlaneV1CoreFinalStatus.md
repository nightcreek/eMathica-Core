# Plane v1 Core Final Status

## 1. Scope

本文档用于冻结 Plane Calculator v1 Core 的最终范围与状态。  
本轮仅做状态整理，不包含任何行为改动。

核心原则：

1. Plane v1 Core 已进入 **bugfix-only** 阶段。
2. 未进入下一轮验收前，不再新增 Plane v1 Core 功能。
3. 后续扩展（采样准确性、艺术采样、3D）走独立路线。

---

## 2. Completed Modules

## A. Dynamic Geometry

### A.1 Supported dependency kinds

- `midpointOfPoints(pointAID, pointBID)`
- `parallelLine(referenceObjectID, throughPointID)`
- `perpendicularLine(referenceObjectID, throughPointID)`
- `intersectionOf(objectAID, objectBID, index)`
- `circleByCenterPoint(centerPointID, throughPointID)`
- `circleByCenterRadius(centerPointID, radius)`

### A.2 Source / derived / recompute

1. `midpointOfPoints`
   - source：point A, point B
   - derived：point
   - recompute：source 点移动后更新中点

2. `parallelLine`
   - source：reference line-like + through point
   - derived：line
   - recompute：through/reference 变化后更新方向与过点

3. `perpendicularLine`
   - source：reference line-like + through point
   - derived：line
   - recompute：through/reference 变化后更新垂直方向

4. `intersectionOf`
   - source：object A, object B（支持 line-like / circle 组合）
   - derived：point
   - recompute：source 几何变化后重新求交

5. `circleByCenterPoint`
   - source：center point + through point
   - derived：circle
   - recompute：center/through 变化后更新圆

6. `circleByCenterRadius`
   - source：center point + fixed radius
   - derived：circle
   - recompute：center 变化后更新圆心，半径保持

### A.3 noSolution / status behavior

`geometryDefinitionStatus`：
- `defined`
- `noSolution`
- `missingSource`
- `unsupported`
- `invalid`

行为：
- non-defined 对象不按正常对象渲染
- non-defined 对象不参与普通 hit-test
- preview 跳过 non-defined derived old geometry

### A.4 source deletion / convert-to-independent

- source 删除：
  - 依赖对象按策略转独立或删除（见 Deletion Policy）
- 显式 `转为独立对象`：
  - 清 dependency/status
  - 保留当前几何/样式/名称/可见性

### A.5 save/load / preview

- `.emathica` roundtrip 后 dependency/status 保持
- reopen 后动态依赖继续重算
- preview 跳过 non-defined derived

---

## B. Geometry Tools

| Tool | 完成度 | Dynamic | 写 dependency | 已知限制 |
|---|---|---|---|---|
| point | 已完成 | N/A | 否 | 无核心限制 |
| segment | 已完成 | 静态 | 否 | midpoint of segment 仍为静态 |
| line | 已完成 | 工具本体静态，派生可动态 | 派生路径写 | line tool 本体未引入 point+direction 表示 |
| ray | 已完成 | 静态 | 否 | 动态射线关系后置 |
| midpoint | 已完成 | two-point 动态 | 是 | segment midpoint 仍静态（v1策略） |
| parallel | 已完成 | 动态派生线 | 是 | 仅 v1 关系集，不扩展约束图 |
| perpendicular | 已完成 | 动态派生线 | 是 | 同上 |
| circle | 已完成 | 支持 center-point 与 center-radius 动态 | 是 | 三点圆/切线/圆弧后置 |
| intersection | 已完成 | line-like/line-circle/circle-circle 动态 | 是 | root identity tracking 高级策略后置 |

补充：
- parallel/perpendicular 已修复 helper point 泄漏问题，不再生成可操作辅助点对象。
- circle 工具遵循 fixed-radius policy，不在空白第二击创建 through helper point。

---

## C. Deletion / Recovery Safety

### C.1 删除确认策略（已完成）

1. 单删与批删都接入确认。
2. `unlink`：
   - 仅删除 selected
   - 直接相关对象转独立
3. `delete affected`：
   - 删除 selected + downstream recursive derived objects
4. Undo/Redo 对两种策略均可恢复。

### C.2 三层安全网（已完成）

1. **Undo/Redo（会话级）**
   - 当前打开会话内撤销/重做
2. **Revert（会话级）**
   - 回到本次打开时 baseline
3. **ObjectHistoryRecovery（文件级）**
   - 跨会话恢复被删除对象
   - 存入文档，最多 200 条

### C.3 ObjectHistoryRecovery v1（已完成）

1. `deletedObjectHistory` 数据层
2. 删除记录保存快照
3. 最近 200 条 trim
4. save/load roundtrip
5. `restoreDeletedObject`
6. 恢复一律转独立对象
7. 最小 UI：文档菜单入口 + sheet + 单对象恢复 + 空状态
8. Undo/Redo 兼容

---

## D. Save / Load / Preview / Recent

### D.1 已完成

1. `.emathica` roundtrip 支持 dynamic geometry/status/history
2. reopen 后 dynamic recompute 继续工作
3. `noSolution` reopen 后保持正确并可恢复 defined
4. preview 跳过 non-defined derived old geometry
5. circle preview 比例正确，不变椭圆
6. recent `updatedAt` 更新与排序修复

### D.2 当前限制

- 仍需持续关注极端大文档与密集对象下的 preview 刷新时序与资源占用。

---

## E. Object Panel / Inspector

### E.1 Object row（已完成）

1. source/status 优先级稳定
2. 文案已统一为 `转为独立对象`
3. segment length / circle radius 已接入（低风险属性）

### E.2 Inspector 几何属性（已完成）

覆盖：
- point
- segment
- circle
- line
- ray
- intersection
- dynamic dependency detail

规则：
- non-defined 对象不将旧几何值当有效值显示
- status/source 与几何属性语义一致

### E.3 格式统一（已完成）

- `GeometryPropertyFormatter` 统一格式策略：
  - 坐标/长度/半径/直径/向量：2 位小数
  - 方向角：1 位小数 + `°`
  - 斜率：2 位小数，垂直线显示 `垂直`

---

## F. Input / Expression

### F.1 当前状态（核心路径可用）

1. parametric / piecewise 核心路径已可用并有修复
2. inequality token normalization 已接入
3. implicit multiplication 核心场景已修复
4. diagnostics 链路可用（解析/分类/采样）

### F.2 限制说明（不夸大）

- 复杂表达式角落场景仍需持续观察。
- 采样准确性仍不是 v1 Core 最终形态（见 Sampling 后置）。

---

## G. Sampling / Performance

### G.1 当前结论

1. 当前 sampling 可支撑 v1 Core，但不是终态。
2. `tan/asymptote` 精度策略后置。
3. dense scene（高对象密度）性能需继续观察。

### G.2 明确不在 Plane v1 Core

- Viewport reactive sampling art
- sampling style preset system
- 高阶准确性模式（作为独立路线推进）

---

## 3. Frozen Modules (Bugfix-only)

以下模块建议冻结为 bugfix-only：

1. DynamicGeometry v1
   - 冻结原因：依赖链路已完整，跨模块耦合高
   - 仅修：重算错误、状态错误、回归 bug

2. CircleCreationPolicy
   - 冻结原因：圆工具语义已稳定，through helper point 泄漏已规避
   - 仅修：创建分支错误、fixed-radius 跟随错误

3. DependencyDeletionPolicy
   - 冻结原因：单删/批删 + unlink/delete affected 已成闭环
   - 仅修：误删/漏删、确认策略回归

4. SessionUndoRedo
   - 冻结原因：事务合并与快捷键行为已稳定
   - 仅修：步数异常、恢复错误、输入态冲突回归

5. SaveLoad/Preview/Recent baseline
   - 冻结原因：roundtrip 与 preview 核心行为已打通
   - 仅修：编码丢字段、预览错误、recent 更新回归

6. ObjectPanel text structure
   - 冻结原因：source/status 可读性问题已完成 v1.1 调整
   - 仅修：文案截断/优先级回归

7. GeometryInspector properties
   - 冻结原因：最小可用属性集已完成
   - 仅修：解析错误、non-defined 显示错误

8. GeometryPropertyFormatter
   - 冻结原因：格式策略已统一
   - 仅修：格式不一致/异常值显示 bug

9. ObjectHistoryRecovery v1
   - 冻结原因：数据层 + 最小恢复 UI 已闭环
   - 仅修：history 记录错误、恢复错误、undo 交互回归

---

## 4. Device-tested Behaviors (Passed)

已通过真机复测要点：

1. 点拖动 Undo 合并为单步
2. delete affected 递归删除圆与交点
3. unlink 保持不递归删除
4. 公式编辑态 Cmd+Z 不再输入 `z/y`
5. 删除普通点后可恢复
6. 删除动态圆后恢复为独立对象
7. delete affected 后 history 可记录多个对象
8. restore 后 Undo/Redo 正常
9. 保存-关闭-重开后 history 仍在且可恢复

---

## 5. Remaining Limitations / Deferred Items

## P1 后置

1. ObjectHistoryRecovery clear history
2. batch restore
3. deleted history search/filter
4. restore dynamic relation
5. dependency graph UI
6. legacy helper point cleanup（历史遗留清理）
7. delete confirmation “不再提示” preference
8. object panel status icon polish

## P2 后置

1. 三点圆
2. 切线
3. 圆弧
4. 多边形
5. 低版本 iOS 适配
6. HarmonyOS
7. tool icon fine polish

## Sampling / Art 独立路线

1. `SamplingAccuracy-Tangent-1`
2. `ViewportReactiveSamplingArt-Audit-1`
3. sampling style preset system

---

## 6. Next-stage Roadmap Options

## 路线 1：Plane v1 持续稳定化（推荐当前默认）

1. 按 `PlaneDeviceAcceptanceRunbook` 持续真机复测
2. 仅修 bug，不扩功能
3. 以回归风险最低方式完成冻结阶段

## 路线 2：采样准确性路线

1. `SamplingAccuracy-Tangent-1`
2. asymptote detection
3. discontinuity splitting
4. high-frequency sampling audit

## 路线 3：艺术采样路线

1. `ViewportReactiveSamplingArt-Audit-1`
2. Zoom Trace Sampling
3. sampling style presets
4. export image/video 后置

## 路线 4：Space Calculator 前置设计

1. 立体计算器对象模型
2. 3D viewport
3. 3D geometry dependency
4. 3D save/load

---

## 7. Final Rule

在下一次验收周期开始前，**Plane v1 Core 不新增功能**，仅接受 bugfix。  
新能力请进入独立分支路线与独立验收计划。

