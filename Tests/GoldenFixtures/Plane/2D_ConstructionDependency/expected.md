# Plane-2D-ConstructionDependency Expected State

## 基础创建完成后

对象总数：`11`

应包含：

- `A`, `B`, `C`, `D`
- `ℓ1`, `ℓ2`
- `M`, `X`, `p`, `q`, `Y`

依赖状态：

- `M.geometryDependency = midpoint(A, B)`
- `X.geometryDependency = intersection(ℓ1, ℓ2, index: 0)`
- `p.geometryDependency = parallel(ℓ1, C)`
- `q.geometryDependency = perpendicular(ℓ1, D)`
- `Y.geometryDependency = intersection(p, q, index: 0)`

所有派生对象初始应为：

- `geometryDefinitionStatus = .defined`

## 源对象拖拽后

操作：

- 将 `B` 从 `(4, 1)` 移动到 `(4, 3)`

预期：

- `M` 更新为 `(2, 1.5)`
- `X` 更新为 `(2, 1.5)`
- `p` 与 `q` 的几何方向发生变化
- `Y` 继续存在，且 `geometryDependency` 保留
- `M / X / p / q` 仍保持 `geometryDefinitionStatus = .defined`

备注：

- 当前 golden fixture 把“源对象拖拽后的依赖重算”基线限制在直接依赖对象。
- `Y` 作为二级依赖对象，当前主要用于验证删除语义、静态化和 save/reopen 一致性，不把实时联动位置变化作为本轮硬性通过条件。

## unlink 场景

操作：

- 通过默认快捷删除语义删除 `D`

预期：

- `D` 不存在
- `q` 保留最后有效几何状态
- `q.geometryDependency == nil`
- `q.geometryDefinitionStatus == nil`
- `Y` 继续存在
- `Y` 不应含 dangling dependency
- save / reopen 后状态保持一致

## deleteAffected 场景

操作：

- 删除 `D`
- 确认策略选择 `deleteAffected`

预期：

- `D` 不存在
- `q` 作为直接派生对象被删除
- `Y` 作为下游幸存对象被静态化
- `Y.geometryDependency == nil`
- `Y.geometryDefinitionStatus == nil`
- save / reopen 后删除结果保持一致
- 文档中不应存在 dangling dependency

## preview / thumbnail

预期：

- 基础 fixture 文档可生成 preview
- `unlink` 后的文档可生成 preview
- `deleteAffected` 后的文档可生成 preview
- preview 渲染不应因依赖对象状态变化而崩溃
