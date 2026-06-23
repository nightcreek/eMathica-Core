# M0 Golden Fixture Design

## 1. 本轮是否修改源码

否。

本轮只新增黄金样例设计文档，不修改任何 Swift 源码、项目配置或目录结构，也不创建真实 fixture 数据文件。

## 2. 设计目标

- `M0 Golden Fixtures` 的目标，是为后续 `Plane Beta / Plane v1 / Space v0.2` 提供一组长期可复用的回归样例，而不是临时 demo。
- 每个 fixture 最终都应覆盖统一闭环：
  - `create`
  - `preview`
  - `commit`
  - `edit`
  - `drag`
  - `delete`
  - `save`
  - `reopen`
  - `thumbnail`
- 每个 fixture 最终都要能按以下顺序完成平台验收：
  - `iPad`
  - `macOS`
  - `iPhone`
- fixture 的职责不仅是验证“能不能创建对象”，还要验证：
  - 图形质量
  - 依赖更新
  - 对象区 / Inspector 展示
  - `preview.png`
  - 首页缩略图
  - 保存 / 重开一致性
- 本轮只完成 fixture 设计、命名、验收模板和创建顺序规划，不创建真实 `.emathica` 包或截图文件。

## 3. Fixture 命名与目录建议

> 本节只设计未来目录，不在本轮创建目录。

建议未来目录结构：

```text
Tests/GoldenFixtures/
  Plane/
    2D_BasicGeometry/
    2D_ConstructionDependency/
    2D_Transform/
    2D_Conic/
    FunctionCAS/
    DynamicGeometry/
    ObjectPanelAlgebraEdit/
    UI_CompactAndGlass/
  SaveLoad/
    EmptyProject/
    FunctionMetadata/
    GeometryDependency/
    PreviewThumbnail/
    LargeProject/
    PackageEdgeCases/
  Space/
    3D_Primitives/
    3D_Solids/
    3D_Surfaces/
  CrossPlatform/
    iPad/
    macOS/
    iPhone/
```

每类目录未来建议放置：

- fixture project package
  - 真实 `.emathica` 包样例
- expected metadata
  - `metadata.json`
  - `document.json`
  - 必要时的字段 diff 说明
- expected preview image
  - `preview.png`
  - 必要时的 expected viewport / cropping note
- manual QA checklist
  - iPad / macOS / iPhone 的手工验收步骤
- regression notes
  - 已知缺陷
  - 当前允许偏差
  - 关联测试或修复任务

补充约束建议：

- `Plane` fixture 目录优先存“单一主题”的样例，不把多类风险混在一个包里。
- `SaveLoad` fixture 目录优先存“边界行为样例”，例如 metadata/document 漂移、preview 缺失、删除后保存、复杂函数字段 round-trip。
- `CrossPlatform` 目录优先存平台级 QA checklist，而不是重复复制所有 `.emathica` 包。

## 4. Fixture 总表

| 编号 | Fixture | 覆盖能力 | 当前优先级 | 当前状态 | 目标阶段 | 风险来源 | 后续是否需要真实文件 |
|---|---|---|---|---|---|---|---|
| 1 | Plane-2D-BasicGeometry | 点、线、线段、射线、圆、圆弧、选择、拖拽、删除、命名、对象区、保存重开、`preview.png` | P0 | 设计完成，待创建 | Plane Beta | Plane MVP 虽已闭环，但缺少统一长期 fixture | 是 |
| 2 | Plane-2D-ConstructionDependency | 中点、交点、平行线、垂线、源对象拖拽、派生更新、删除源对象、保存重开依赖保持 | P0 | 设计完成，待创建，高优先 | Plane Beta | `PlaneGeometryDependencyTests` 近期观察到失败 / not completed | 是 |
| 3 | Plane-2D-Transform | 平移、旋转、反射、位似、变换后样式与依赖、保存重开 | P1 | future fixture | Plane v1 | 能力矩阵显示多项未开始 | 是 |
| 4 | Plane-2D-Conic | circle、ellipse、parabola、hyperbola、general conic、implicit classification、一致性 | P1 | 设计完成，待创建 | Plane v1 | Graph quality 与 conic 分类仍缺集中回归 | 是 |
| 5 | Plane-Function-CAS | 显函数、隐函数、参数曲线、极坐标、分段函数、future CAS checks | P0 | 设计完成，待创建 | Plane Beta | graphing path / preview / thumbnail 三链不一致风险 | 是 |
| 6 | Plane-DynamicGeometry | slider、parameter、point-on-object、trace、locus、lock、visibility、animation | P2 | future fixture | Plane v1 | 多项能力未完成或仅部分具备 | 是 |
| 7 | Plane-ObjectPanel-AlgebraEdit | 长公式横向滚动、fallback 单行滚动、Inspector 横向滚动、全屏编辑、保存重开 | P1 | 设计完成，待创建 | Plane Beta | UI polish 已完成多轮小修，但缺统一回归包 | 是 |
| 8 | Plane-UI-CompactAndGlass | compact-height 默认折叠键盘、状态 chip、error banner、construction hint、glass token、多平台小窗口 | P1 | 设计完成，待创建 | Plane Beta | 当前更多依赖 UI regression 文档，不是实际 fixture | 否，优先 checklist + screenshot baseline |
| 9 | SaveLoad-EmptyProject | 空项目 metadata、空对象文档、fallback preview、首页稳定性 | P1 | 设计完成，待创建 | Plane Beta | 空项目链路简单，但仍缺真实 package 样例 | 是 |
| 10 | SaveLoad-FunctionMetadata | `rawInput / originalLatex / displayText / editorASTData / semantic metadata` round-trip | P0 | 设计完成，待创建 | Plane Beta | 函数字段多，display/edit 优先级不一致 | 是 |
| 11 | SaveLoad-GeometryDependency | dependency ID、status、unlink/deleteAffected、保存重开后派生关系 | P0 | 设计完成，待创建，高优先 | Plane Beta | SaveLoad 审计已明确这是 P1 风险集中点 | 是 |
| 12 | SaveLoad-PreviewThumbnail | `preview.png` 缺失、损坏、过旧、生成失败、首页 fallback | P0 | 设计完成，待创建 | Plane Beta | thumbnail 链路已有 fallback，但 stale / best-effort 风险未闭环 | 是 |
| 13 | SaveLoad-LargeProject | 20+ 对象、多函数、多依赖、多图元、保存耗时、thumbnail 读取 | P1 | 设计完成，待创建 | Plane v1 | 当前同步 I/O 与同步 preview render 风险明显 | 是 |
| 14 | Space-3D-Primitives | 3D 点、线、线段、平面、camera、work plane、selection、inspector、save/reopen | P2 | future fixture | Space v0.2 | 目前仅 Space v0.1 骨架稳定 | 是 |
| 15 | Space-3D-Solids | sphere、cone、cylinder、prism、pyramid、cube、intersections | P3 | future fixture | Space v0.2+ | 多数能力矩阵仍未开始 | 是 |
| 16 | Space-3D-Surfaces | parametric curves、parametric surfaces、implicit surfaces、quadrics、section curves、transparency、hidden-line | P3 | later fixture | M8 | 当前应明确 later，不应近期创建 | 是 |
| 17 | CrossPlatform-iPad-Pencil | Pencil tap/drag、finger pan/zoom、landscape、Stage Manager、compact height、external keyboard | P1 | 设计完成，待创建 | Plane Beta | 真实交互体验不能只靠 simulator | 否，优先 checklist |
| 18 | CrossPlatform-macOS-KeyboardMouse | mouse/trackpad、快捷键、窗口缩放、文件打开保存、对象区编辑 | P1 | 设计完成，待创建 | Plane Beta | macOS 交互与 iPad 不同，需独立 checklist | 否，优先 checklist |
| 19 | CrossPlatform-iPhone-Compact | compact layout、object panel、keyboard collapse、formula editing、Home preview、limited editing | P2 | future checklist | Plane v1 | iPhone 会拖慢主线，需控制节奏 | 否，优先 checklist |

## 5. 每个 Fixture 的验收模板

**Fixture: `<name>`**

| 字段 | 内容 |
|---|---|
| 目标 | 本 fixture 要冻结的最小产品能力 |
| 覆盖能力 | 对象 / 工具 / UI / save-load / preview / thumbnail |
| 初始对象 | 初始项目里应包含的最小对象集合 |
| 操作步骤 | 创建 -> 预览 -> 提交 -> 编辑 -> 拖拽 -> 删除 -> 保存 -> 重开 |
| 期望结果 | 每一步后画布、对象区、Inspector、命名、依赖、状态文案应出现的结果 |
| 保存重开检查 | 对象数量、对象 ID、name、dependency、geometry definition、函数 metadata 是否保留 |
| Home thumbnail 检查 | `preview.png` 是否存在、是否更新、首页是否读取成功、fallback 是否合理 |
| ObjectPanel / Inspector 检查 | 行展示、横向滚动、全屏编辑、属性字段是否一致 |
| iPad 检查 | Pencil / finger / Stage Manager / compact-height |
| macOS 检查 | mouse / trackpad / keyboard shortcut / 窗口 resize |
| iPhone 检查 | compact layout、键盘折叠、对象区可用性、首页缩略图 |
| 自动化测试建议 | 适合 XCTest / package test 的断言点 |
| 手工验收建议 | 适合截图、录屏、触控手感核验的点 |
| 当前风险 | 当前已知回归点、未完成能力、平台差异 |
| 后续任务 | 若该 fixture 失败，最小后续任务名称 |

## 6. Plane Fixtures 详细设计

### 6.1 Plane-2D-BasicGeometry

**目标**

- 固定 Plane MVP 最核心的基础几何对象闭环。

**必须覆盖**

- 点
- 线
- 线段
- 射线
- 圆
- 圆弧
- 选择
- 拖拽
- 删除
- 命名
- ObjectPanel 展示
- save/reopen
- `preview.png`

**建议初始对象**

- `A`, `B`
- 直线 `ℓ1`
- 线段 `s_1`
- 射线 `r1`
- 圆 `c1`
- 圆弧 `a1`

**操作步骤**

1. 新建 Plane 项目
2. 创建点 `A`、`B`
3. 创建直线、线段、射线
4. 创建圆和圆弧
5. 选择各对象，检查对象区 / Inspector
6. 拖拽点 `A`、`B`
7. 删除一个基础对象
8. 保存
9. 检查首页缩略图
10. 重新打开项目

**保存重开检查**

- 对象数量一致
- `id` 稳定
- 命名稳定
- 点位置 / 线端点 / 圆心半径 / 圆弧三点定义保持
- ObjectPanel 与 Inspector 文案一致

**当前风险**

- 圆弧文件级 save/load 覆盖仍不足
- preview 与 reopen 后 geometry 需要真实 package fixture 才能长期固定

**后续任务**

- `First Golden Fixture Creation: Plane-2D-BasicGeometry`

### 6.2 Plane-2D-ConstructionDependency

**目标**

- 固定当前依赖几何主线的行为语义与 save/load 一致性。

**必须覆盖**

- 中点
- 交点
- 平行线
- 垂线
- 源对象拖拽
- 派生对象更新
- 删除源对象
- 保存重开后依赖保持

**特别标记**

- 本 fixture 应视为 `P0/P1 bridge fixture`
- 原因：
  - `SaveLoadEdgeCasesAudit` 已把依赖对象 save/load 定位为高风险
  - `PlaneGeometryDependencyTests` 近期观察到 failure / not completed
  - 这是当前最需要 fixture 固化的问题域之一

**建议初始对象**

- 两个基础点
- 一条基础线 / 一条基础圆
- 基于它们创建：
  - 中点
  - 两个交点
  - 平行线
  - 垂线

**操作步骤**

1. 创建源对象
2. 创建派生对象
3. 拖拽源点 / 源线
4. 检查派生对象是否实时更新
5. 删除源对象，分别测试：
   - `unlink`
   - `deleteAffected`
6. 保存
7. 重开
8. 再次拖拽幸存源对象

**保存重开检查**

- `geometryDependency` 是否保留
- `geometryDefinitionStatus` 是否保留
- 派生对象 reopen 后是否仍能 recompute
- 删除语义是否与保存前一致

**当前风险**

- 依赖模型级测试存在，但真实 package 级 fixture 缺失
- 删除源对象后的保存语义是最容易漂移的边界

**后续任务**

- `PlaneGeometryDependencyTests Failure Audit`
- `First Golden Fixture Creation: Plane-2D-ConstructionDependency`

### 6.3 Plane-2D-Transform

**目标**

- 为 Plane v1 的变换能力预留统一 fixture 入口。

**必须覆盖**

- 平移
- 旋转
- 反射
- 位似
- 变换后的对象样式
- 变换后的依赖
- 保存重开

**当前状态**

- `future fixture`
- 当前能力矩阵中，多项变换能力仍是 `未开始`

**设计原则**

- 本 fixture 现在只冻结结构，不假设功能已实现
- 真正创建真实 fixture 文件前，应先完成能力存在性复审

**后续任务**

- `Plane Transform Capability Audit`

### 6.4 Plane-2D-Conic

**目标**

- 固定 conic / implicit classification / preview / commit / thumbnail 的一致性。

**必须覆盖**

- circle
- ellipse
- parabola
- hyperbola
- general conic
- implicit classification
- preview / commit / thumbnail 一致性

**建议样例**

- `x^2 + y^2 = 4`
- `x^2 / 9 + y^2 / 4 = 1`
- `y = x^2`
- `x = y^2`
- `x^2 - y^2 = 1`

**当前风险**

- conic 与 generic implicit 仍跨越两套质量域
- thumbnail 与 live render 不完全共采样密度

**后续任务**

- `Conic Graphing Consistency Audit`

### 6.5 Plane-Function-CAS

**目标**

- 固定当前 Plane 图形主线的代表性样例与 save/load / thumbnail 一致性。

**必须覆盖**

- `y = x`
- `y = x^2`
- `y = sin(x)`
- `y = 1/x`
- `y = tan(x)`
- `y = sqrt(x)`
- 隐函数：圆
- 参数曲线：单位圆
- 极坐标：rose
- piecewise
- `derivative / integral / root / extrema` 作为 `future checks`

**检查重点**

- parse / intent / sampling 路径
- create/edit preview
- commit 后对象显示
- save/reopen 后 metadata 是否漂移
- `preview.png` 与 live render 是否一致

**当前风险**

- `explicitY / explicitX` 仍多走 legacy path
- 断点 / 渐近线 / 高频函数质量仍需后续单独修复

**后续任务**

- `Function Metadata SaveLoad Consistency Audit/Fix`
- `Explicit Function Discontinuity Audit/Fix`

### 6.6 Plane-DynamicGeometry

**目标**

- 为 dynamic geometry 能力预留统一回归面。

**必须覆盖**

- slider / parameter
- point-on-object
- trace
- locus
- lock
- visibility
- animation

**当前状态**

- `future fixture`
- 当前能力矩阵显示：
  - `slider / parameters` 为部分具备
  - `trace / visibility / animation` 为部分具备或未开始
  - `locus` 未开始

**策略**

- 本 fixture 先列为 Plane v1 目标，不在 Plane Beta 阶段强推

**后续任务**

- `Dynamic Geometry Capability Audit`

### 6.7 Plane-ObjectPanel-AlgebraEdit

**目标**

- 固定对象区代数表达与全屏编辑相关的 UI polish 成果。

**必须覆盖**

- 对象区长公式横向滚动
- fallback 单行横向滚动
- Inspector 显示字段横向滚动
- 对象区全屏编辑
- 编辑后保存重开
- 编辑后 `preview.png` 更新

**检查重点**

- `displayText -> originalLatex -> rawInput -> name` 优先级
- 编辑后 reopen 时 ObjectPanel 显示是否一致
- 全屏编辑退出后内容是否保留

**当前风险**

- 这是 UI 与 save/load 的交叉区域，最适合用单独 fixture 固定

**后续任务**

- `First Golden Fixture Creation: Plane-ObjectPanel-AlgebraEdit`

### 6.8 Plane-UI-CompactAndGlass

**目标**

- 固定当前 Plane 工作区 UI polish phase 1 的高风险小窗口 / 玻璃风格行为。

**必须覆盖**

- compact-height 默认折叠键盘
- input dock 状态
- commit error banner
- construction hint
- glass visual token
- object panel
- keyboard
- iPad / macOS / iPhone 小窗口检查

**说明**

- 该 fixture 更适合作为：
  - screenshot baseline
  - manual QA checklist
  - 少量状态型自动化测试
- 不优先创建大型 `.emathica` 包

**后续任务**

- `Plane UI Compact/Glass Screenshot Regression Checklist`

## 7. SaveLoad Fixtures 详细设计

### 7.1 SaveLoad-EmptyProject

**目标**

- 固定空项目从创建到首页显示的最小链路。

**覆盖**

- 空 `document.json`
- `metadata.json`
- `preview.png` 缺省或 fallback
- 首页卡片稳定显示

**吸收风险**

- Home 列表依赖 `metadata.json`
- 打开项目依赖 `document.json`

**后续任务**

- `First Golden Fixture Creation: SaveLoad-EmptyProject`

### 7.2 SaveLoad-FunctionMetadata

**目标**

- 固定函数对象多字段 round-trip，不让 reopen 后语义漂移。

**必须覆盖**

- `rawInput`
- `originalLatex`
- `displayText`
- `editorASTData`
- `sourceExpression`
- `computeExpression`
- `semanticGraphKind`
- `semanticParameterSymbol`
- `semanticParameterRange`

**建议样例**

- `y = x`
- `y = sin(x)`
- `y = 1/x`
- implicit circle
- parametric circle
- polar rose
- piecewise

**吸收风险**

- 函数对象保存字段多
- 对象区显示优先级与重新编辑优先级不同

**后续任务**

- `SaveLoad Function Metadata Consistency Fix`

### 7.3 SaveLoad-GeometryDependency

**目标**

- 固定依赖对象 package round-trip 与删除语义。

**必须覆盖**

- 中点
- 交点
- 平行线
- 垂线
- 动态圆
- `unlink`
- `deleteAffected`
- 删除源对象后的 reopen

**吸收风险**

- dependency save/load 主线已有模型级测试，但缺真实 package fixture
- 删除源对象后的保存语义最容易退化

**后续任务**

- `Geometry Dependency SaveLoad Audit/Fix`

### 7.4 SaveLoad-PreviewThumbnail

**目标**

- 固定 `preview.png` 与首页缩略图的边缘行为。

**必须覆盖**

- `preview.png` 正常生成
- `preview.png` 缺失
- `preview.png` 损坏
- `preview.png` 过旧
- 保存时 preview render 失败
- 首页 fallback

**吸收风险**

- preview 更新是 best-effort
- stale preview 没有检测
- Home thumbnail 读取与项目正文读取源不同

**后续任务**

- `Preview PNG Missing/Corrupt Fallback Fix`
- `Preview PNG Stale Fallback Fix`

### 7.5 SaveLoad-LargeProject

**目标**

- 固定大项目保存 / 缩略图 / 首页读取的性能边界。

**必须覆盖**

- 20+ 对象
- 多函数
- 多几何依赖
- 多个 preview 元素
- 首页列表连续读取多个项目

**吸收风险**

- `CoreHomeState` / `LocalProjectStore` 当前大量同步 I/O
- save 时同步 preview render

**后续任务**

- `Large Project SaveLoad Performance Audit`

## 8. Space Fixtures 详细设计

### 8.1 Space-3D-Primitives

**目标**

- 为 Space v0.2 的最小稳定编辑闭环建立首个真实 fixture。

**覆盖**

- 3D 点
- 3D 线
- 3D 线段
- 平面
- camera
- work plane
- selection
- inspector
- save/reopen

**当前状态**

- 当前仅适合设计，不适合立即创建
- 应等 Plane Beta 核心 fixture 先落地

### 8.2 Space-3D-Solids

**覆盖**

- sphere
- cone
- cylinder
- prism
- pyramid
- cube
- intersections

**当前状态**

- `future fixture`
- 当前未完成能力必须明确标成 future，不假设已有实现

### 8.3 Space-3D-Surfaces

**覆盖**

- parametric curves
- parametric surfaces
- implicit surfaces
- quadrics
- section curves
- transparency
- hidden-line

**当前状态**

- `later / M8`
- 不建议近期实现或创建真实 fixture

## 9. Cross-platform 验收设计

### iPad

检查重点：

- Pencil tap / drag
- finger pan / zoom
- landscape
- Stage Manager
- compact height
- external keyboard

### macOS

检查重点：

- mouse click / drag
- trackpad pan / zoom
- keyboard shortcuts
- window resize
- file open / save

### iPhone

检查重点：

- compact layout
- object panel usability
- keyboard collapse
- formula editing
- Home preview
- limited editing mode

平台验收顺序要求：

1. iPad
2. macOS
3. iPhone

## 10. 自动化与手工验收分工

| 类型 | 适合自动化 | 适合手工 |
|---|---|---|
| Save/reopen object count | 是 | 否 |
| `preview.png` 是否存在 | 是 | 否 |
| `metadata.json / document.json` 字段一致性 | 是 | 否 |
| dependency update correctness | 是 | 是 |
| 删除源对象后的依赖语义 | 是 | 是 |
| graph visual quality | 部分适合 | 是 |
| glass 质感 | 否 | 是 |
| Pencil 手感 | 否 | 是 |
| compact-height 默认折叠行为 | 是 | 是 |
| ObjectPanel 横向滚动 / 全屏编辑 | 部分适合 | 是 |
| Stage Manager 小窗口体验 | 否 | 是 |
| thumbnail 缺失 / 损坏 fallback | 是 | 是 |

建议原则：

- 结构、字段、对象数量、文件存在性优先自动化
- 视觉质量、交互手感、Pencil、glass 风格优先手工
- 依赖更新、graph quality、thumbnail 一致性采用“自动化基线 + 手工截图复核”

## 11. fixture 创建顺序建议

### Phase 1: Plane Beta 必需

建议包含：

- `Plane-2D-BasicGeometry`
- `Plane-2D-ConstructionDependency`
- `Plane-Function-CAS`
- `SaveLoad-FunctionMetadata`
- `SaveLoad-GeometryDependency`
- `SaveLoad-PreviewThumbnail`
- `Plane-ObjectPanel-AlgebraEdit`

**理由**

- 这组 fixture 直接覆盖当前 Plane MVP、graph baseline、save/load 高风险区和 UI polish 的核心可见面。
- 尤其 `ConstructionDependency` 与 `GeometryDependency SaveLoad` 是当前最应该先被固定的边界。

### Phase 2: Plane v1

建议包含：

- `Plane-2D-Transform`
- `Plane-2D-Conic`
- `Plane-DynamicGeometry`
- `SaveLoad-LargeProject`
- `CrossPlatform-iPhone-Compact`

**理由**

- 这些能力要么尚未完整实现，要么属于 Plane v1 的拓展面。
- 先让 Plane Beta 的基础与风险面稳定，再扩。

### Phase 3: Space v0.2+

建议包含：

- `Space-3D-Primitives`
- `Space-3D-Solids`
- `Space-3D-Surfaces`

**理由**

- Space 仍应在 Plane 进一步稳定后再推进。
- `3D_Surfaces` 应明确排到更后面，不与 Plane Beta 竞争主线注意力。

## 12. 下一轮建议

建议从以下 5 个最小任务中选择下一步，按优先级排序：

1. `PlaneGeometryDependencyTests Failure Audit`
2. `First Golden Fixture Creation: Plane-2D-ConstructionDependency`
3. `First Golden Fixture Creation: Plane-2D-BasicGeometry`
4. `SaveLoad Function Metadata Consistency Fix`
5. `Preview PNG Stale Fallback Fix`

### 最优先建议

**`PlaneGeometryDependencyTests Failure Audit`**

原因：

- 当前已明确观察到该测试域存在 failure / not completed；
- `Plane-2D-ConstructionDependency` 与 `SaveLoad-GeometryDependency` 都把依赖主线列为最高优先 fixture；
- 如果不先把失败边界审清楚，就直接创建真实 fixture，后续只会把不稳定状态“固化进样例”。

### 第二优先建议

**`First Golden Fixture Creation: Plane-2D-ConstructionDependency`**

前提：

- 在上一步 failure audit 至少把失败边界分类清楚之后再做。

### 第三优先建议

**`First Golden Fixture Creation: Plane-2D-BasicGeometry`**

原因：

- 它是最小、最稳、最适合先打通 fixture 目录结构和 QA 模板的第一批真实样例之一。
