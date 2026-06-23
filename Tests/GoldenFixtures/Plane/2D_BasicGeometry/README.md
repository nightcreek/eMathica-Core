# Plane-2D-BasicGeometry Golden Fixture

## 覆盖能力

- 自由点
- 直线
- 线段
- 射线
- 圆
- 圆弧
- 对象命名稳定性
- ObjectPanel / Inspector 几何属性展示
- 源点拖拽后的基础几何解析更新
- 删除无依赖对象
- save / reopen 后 `id / name / geometryDefinition / anchors` 保持
- preview / thumbnail 可渲染

## 对象列表

自由点：

- `A`：`(0, 0)`
- `B`：`(4, 0)`
- `C`：`(1, 3)`
- `D`：`(3, 2)`
- `E`：`(-2, 1)`

基础几何对象：

- `l_AB`：直线 `AB`
- `s_AC`：线段 `AC`
- `r_ED`：射线 `ED`
- `c_AB`：圆心 `A`、过 `B` 的圆
- `arc_ACD`：三点圆弧 `A -> C -> D`

## 几何定义

- `l_AB` 使用 `GeometryDefinition(kind: .line, anchors: [.object(A), .object(B)])`
- `s_AC` 使用 `GeometryDefinition(kind: .segment, anchors: [.object(A), .object(C)])`
- `r_ED` 使用 `GeometryDefinition(kind: .ray, anchors: [.object(E), .object(D)])`
- `c_AB` 使用 `GeometryDefinition(kind: .circle, anchors: [.object(A), .object(B)])`
- `arc_ACD` 当前采用稳定的三点圆弧模型：
  - `geometryDefinition.kind = .arc`
  - `geometryDependency = .arcByThreePoints(A, C, D)`

说明：

- 本 fixture 把 `line / segment / ray / circle` 冻结为 anchor-based 基础几何样例。
- `arc` 目前沿用当前稳定的三点圆弧依赖模型，这样可以覆盖拖拽后重算和 save/reopen。

## 操作步骤

自动化基线覆盖：

1. 构造基础文档
2. 验证命名和对象数量
3. 验证 line / segment / ray / circle / arc 的几何解析
4. 移动源点，验证解析结果更新
5. 删除无依赖对象 `l_AB`
6. save / reopen
7. preview 渲染

## 自动化测试入口

当前 fixture 采用 **test builder 动态生成**，真实 `.emathica` 包文件本轮未提交。

对应测试文件：

- `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathicaTests/PlaneBasicGeometryGoldenFixtureTests.swift`

主要测试：

- `basicGeometryFixtureCanBeBuilt`
- `basicGeometryFixtureResolvesObjectProperties`
- `basicGeometryFixtureUpdatesAfterSourcePointMove`
- `basicGeometryFixtureSurvivesSaveReopen`
- `basicGeometryFixtureDeleteIndependentObjectKeepsDocumentValid`
- `basicGeometryFixturePreviewRenders`

## 当前限制

- 本轮未提交真实 `.emathica` 包文件
- 本轮未提交 expected preview image
- 本轮未覆盖手工 iPad / macOS / iPhone 验收
- 本轮不覆盖函数 metadata、graphing 质量或复杂依赖删除策略
- `arc` 的 Inspector 属性仍受当前共享 geometry presentation 能力限制，本轮主要验证 arc 几何可解析和可持久化

