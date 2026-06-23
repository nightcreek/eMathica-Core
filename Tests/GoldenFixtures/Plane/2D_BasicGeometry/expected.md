# Plane-2D-BasicGeometry Expected Behavior

## Object Count

基础 fixture 对象总数：`10`

应包含：

- `A`, `B`, `C`, `D`, `E`
- `l_AB`, `s_AC`, `r_ED`, `c_AB`, `arc_ACD`

## Naming

当前 golden fixture 使用显式固定名称：

- 点：`A`, `B`, `C`, `D`, `E`
- 直线：`l_AB`
- 线段：`s_AC`
- 射线：`r_ED`
- 圆：`c_AB`
- 圆弧：`arc_ACD`

说明：

- 这组名称是 fixture 自己冻结的测试基线，不要求与 UI 自动命名完全一致。
- save / reopen 后名称不应漂移。

## Geometry Properties

应可解析：

- `A`：坐标
- `l_AB`：过点、方向向量、斜率、方向角
- `s_AC`：端点、长度、方向角
- `r_ED`：起点、方向向量、方向角
- `c_AB`：圆心、半径、直径
- `arc_ACD`：三点圆弧几何可解析（center / radius / angles 非空）

## Drag Behavior

移动源点后：

- 移动 `B` 应更新 `l_AB` 与 `c_AB`
- 移动 `C` 应更新 `s_AC` 与 `arc_ACD`
- 移动 `D` 应更新 `r_ED` 与 `arc_ACD`

当前通过条件：

- `line / segment / ray / circle` 的 resolver 结果更新
- `arc_ACD.points` 与 `arcGeometry` 更新

## Delete Behavior

删除一个无依赖对象：

- 删除 `l_AB`
- 对象数量减少为 `9`
- 其他对象保留
- 不应产生 dangling dependency
- 删除后 preview 仍可生成

## Save/Reopen Behavior

save / reopen 后：

- 对象数量一致
- `id / name` 保持
- `geometryDefinition` 保持
- `anchors` 保持
- `arc_ACD.geometryDependency` 保持
- reopen 后再次拖拽源点，resolver 仍能解析更新后的几何

## Preview Behavior

应能生成 preview：

- 基础 fixture 文档
- save / reopen 后文档
- 删除无依赖对象后的文档

## Known Limitations

- 本轮未提交真实 `.emathica` package
- 本轮未提供 expected preview image baseline
- 本轮未覆盖跨平台手工 QA
- `arc` 的 Inspector 展示仍受当前共享 geometry presentation 能力限制，本轮不把完整 arc Inspector 属性作为硬通过条件

