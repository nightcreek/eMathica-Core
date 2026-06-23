# eMathica GeoGebra Capability Matrix

## 1. 本轮是否修改源码

否。

本轮只新增能力矩阵文档，不修改任何 Swift 源码、项目配置或目录结构。

## 2. 总体目标

- eMathica 的长期目标，是对齐 GeoGebra 在平面几何、空间几何、以及为几何/函数工作流服务的必要代数与 CAS 能力。
- 当前主线**不纳入** Spreadsheet / Probability。
- 实现方式坚持 clean-room Swift / SwiftUI 重实现。
- GeoGebra 只作为：
  - 功能覆盖对标；
  - 架构分层参考；
  - 教学工作流参考。
- eMathica 的实际实现边界继续保持在现有体系内：
  - `MathCore`
  - `WorkspaceKit`
  - `Plane`
  - `Space`
  - `DocumentSystem`

## 3. 当前稳定基线

### 3.1 稳定基线

以下能力在当前仓库文档中已有明确依据，可视为后续 GeoGebra 对齐路线的稳定起点：

- `Plane MVP` 主闭环已完成：
  - 创建 Plane 项目
  - 函数 create/edit 实时预览
  - 函数 commit
  - 点、线段、圆、圆弧创建
  - 删除对象
  - 保存项目
  - `preview.png` 生成与首页读取
  - 重新打开项目继续编辑
- 首页缩略图链路已稳定存在：
  - 文档保存时生成 `preview.png`
  - 首页卡片直接读取磁盘预览图
- `MathCore` 基础链路已具备：
  - AST / `Expr`
  - `GraphIntent` / `GraphClassifier`
  - `SamplingCore`
  - 基础 `CASCore`
- `Space v0.1` 已具备可运行骨架：
  - `SpaceMathCore`
  - `SpaceCanvas`
  - `SpaceTools`
  - `SpaceHitTest`
  - `SpaceSnapping`
  - `SpaceWorkPlane`
  - `SpaceInspector`
  - `SpacePreview`

### 3.2 仍需回归验证

以下能力方向已经有实现或近期收口记录，但当前仓库中的正式验收文档不足，或仍依赖持续回归，不应直接视为“长期稳定无需关注”：

- Plane UI polish phase 1 相关成果：
  - 输入栏状态表达
  - 提交失败可见性
  - 多步构造提示与取消入口
- 对象区长公式横向滚动
- 对象区全屏编辑
- compact keyboard / compact-height 默认折叠策略
- 图形质量基线（尤其是复杂函数、断点、渐近线、隐函数采样质量）
- save/load 边缘场景
- Space v0.1 的保存/重开、预览、删除恢复等行为

### 3.3 基线判定说明

| 项 | 判定 | 依据 |
|---|---|---|
| Plane MVP 主闭环 | 稳定基线 | `Docs/PlaneMVPRegressionReport.md` |
| Home preview 生成与读取 | 稳定基线 | `Docs/PlaneMVPRegressionReport.md`, `eMathica/Docs/EMathicaCurrentArchitectureAudit.md` |
| MathCore / GraphIntent / Sampling / CAS 基础链路 | 稳定基线 | `eMathica/Docs/EMathicaCurrentArchitectureAudit.md` |
| Space v0.1 骨架 | 稳定基线 | `Docs/SpacePostPlaneMVPPlan.md` |
| Plane UI polish phase 1 | 仍需回归验证 | `Docs/PlaneUIPolishAudit.md` 为审计基线，但不是最终验收 |
| 对象区横向滚动 | 仍需回归验证 | 当前缺少独立正式回归文档 |
| 对象区全屏编辑 | 仍需回归验证 | 当前缺少独立正式回归文档 |
| compact keyboard | 仍需回归验证 | `Docs/PlaneCompactLayoutAudit.md` 提供审计依据，但不是最终闭环验收 |

## 4. 能力矩阵总表

| 编号 | 能力族 | 具体能力 | GeoGebra 对标方向 | eMathica 当前状态 | 目标阶段 | 优先级 | 风险 | 验收样例 |
|---|---|---|---|---|---|---|---|---|
| P-001 | Plane 基础对象 | 自由点 | Geometry / Point | 已具备 | M2 | P0 | 三平台适配 | 2D basic geometry |
| P-002 | Plane 基础对象 | 路径点 | Geometry / Point on Object | 部分具备 | M3 | P1 | 依赖图扩张 | dynamic geometry |
| P-003 | Plane 基础对象 | 区域点 | Geometry / Point in Region | 待确认 | M3 | P1 | 依赖图扩张 | dynamic geometry |
| P-004 | Plane 基础对象 | 线 | Geometry / Line | 已具备 | M2 | P0 | 三平台适配 | 2D basic geometry |
| P-005 | Plane 基础对象 | 线段 | Geometry / Segment | 已具备 | M2 | P0 | 三平台适配 | 2D basic geometry |
| P-006 | Plane 基础对象 | 射线 | Geometry / Ray | 已具备 | M2 | P0 | 三平台适配 | 2D basic geometry |
| P-007 | Plane 基础对象 | 向量 | Geometry / Vector | 未开始 | M2 | P1 | UI复杂度 | 2D basic geometry |
| P-008 | Plane 基础对象 | 圆 | Geometry / Circle | 已具备 | M2 | P0 | 保存兼容 | 2D basic geometry |
| P-009 | Plane 基础对象 | 圆弧 | Geometry / Arc | 已具备 | M2 | P0 | 保存兼容 | 2D basic geometry |
| P-010 | Plane 基础对象 | 半圆 | Geometry / Semicircle | 待确认 | M2 | P1 | 依赖图扩张 | 2D construction |
| P-011 | Plane 基础对象 | 扇形 | Geometry / Sector | 待确认 | M2 | P1 | 依赖图扩张 | 2D construction |
| P-012 | Plane 基础对象 | 折线 | Geometry / Polyline | 待确认 | M2 | P1 | UI复杂度 | 2D basic geometry |
| P-013 | Plane 基础对象 | 多边形 | Geometry / Polygon | 未开始 | M2 | P1 | UI复杂度 | 2D basic geometry |
| P-014 | Plane 基础对象 | 正多边形 | Geometry / Regular Polygon | 未开始 | M5 | P2 | UI复杂度 | 2D transform |
| P-015 | Plane 构造工具 | 中点 | Geometry / Midpoint | 已具备 | M2 | P0 | 依赖图扩张 | 2D construction |
| P-016 | Plane 构造工具 | 交点 | Geometry / Intersect | 已具备 | M2 | P0 | 依赖图扩张 | 2D construction |
| P-017 | Plane 构造工具 | 平行线 | Geometry / Parallel Line | 已具备 | M2 | P0 | 依赖图扩张 | 2D construction |
| P-018 | Plane 构造工具 | 垂线 | Geometry / Perpendicular Line | 已具备 | M2 | P0 | 依赖图扩张 | 2D construction |
| P-019 | Plane 构造工具 | 垂直平分线 | Geometry / Perpendicular Bisector | 待确认 | M3 | P1 | 依赖图扩张 | 2D construction |
| P-020 | Plane 构造工具 | 角 | Geometry / Angle | 待确认 | M3 | P1 | UI复杂度 | 2D construction |
| P-021 | Plane 构造工具 | 角平分线 | Geometry / Angle Bisector | 未开始 | M3 | P1 | 依赖图扩张 | 2D construction |
| P-022 | Plane 构造工具 | 切线 | Geometry / Tangent | 未开始 | M4 | P1 | CAS联动 | 2D construction |
| P-023 | Plane 构造工具 | 法线 | Geometry / Normal Line | 未开始 | M4 | P2 | CAS联动 | function/CAS |
| P-024 | Plane 测量 | 长度 | Geometry / Length | 部分具备 | M3 | P1 | UI复杂度 | 2D basic geometry |
| P-025 | Plane 测量 | 距离 | Geometry / Distance | 部分具备 | M3 | P1 | UI复杂度 | 2D basic geometry |
| P-026 | Plane 测量 | 角度 | Geometry / Angle Measure | 待确认 | M3 | P1 | UI复杂度 | 2D construction |
| P-027 | Plane 测量 | 面积 | Geometry / Area | 待确认 | M3 | P1 | UI复杂度 | 2D transform |
| P-028 | Plane 测量 | 斜率 | Geometry / Slope | 部分具备 | M4 | P1 | CAS联动 | function/CAS |
| P-029 | Plane 测量 | 周长 | Geometry / Perimeter | 待确认 | M3 | P1 | UI复杂度 | 2D transform |
| P-030 | Plane 变换 | 平移 | Geometry / Translate | 未开始 | M3 | P0 | 依赖图扩张 | 2D transform |
| P-031 | Plane 变换 | 旋转 | Geometry / Rotate | 未开始 | M3 | P0 | 依赖图扩张 | 2D transform |
| P-032 | Plane 变换 | 反射 | Geometry / Reflect | 未开始 | M3 | P0 | 依赖图扩张 | 2D transform |
| P-033 | Plane 变换 | 位似 | Geometry / Dilate | 未开始 | M3 | P1 | 依赖图扩张 | 2D transform |
| P-034 | Plane 变换 | 缩放 | Geometry / Scale | 待确认 | M3 | P1 | 依赖图扩张 | 2D transform |
| P-035 | Plane 变换 | 轨迹 / locus | Geometry / Locus | 未开始 | M5 | P2 | 依赖图扩张 | dynamic geometry |
| P-036 | Plane 变换 | trace | Geometry / Trace | 部分具备 | M5 | P2 | UI复杂度 | dynamic geometry |
| P-037 | Plane 变换 | lock / visibility / layer | Geometry / Object Properties | 部分具备 | M5 | P1 | 保存兼容 | dynamic geometry |
| P-038 | Plane 函数 / CAS | 显函数 | Graphing / explicitY | 已具备 | M4 | P0 | 图形质量 | function/CAS |
| P-039 | Plane 函数 / CAS | 隐函数 | Graphing / implicit | 已具备 | M4 | P1 | 图形质量 | function/CAS |
| P-040 | Plane 函数 / CAS | 参数曲线 | Graphing / parametric | 已具备 | M4 | P1 | 图形质量 | function/CAS |
| P-041 | Plane 函数 / CAS | 极坐标 | Graphing / polar | 已具备 | M4 | P1 | 图形质量 | function/CAS |
| P-042 | Plane 函数 / CAS | 分段函数 | Graphing / piecewise | 已具备 | M4 | P1 | 图形质量 | function/CAS |
| P-043 | Plane 函数 / CAS | 定义域限制 | Graphing / Restrictions | 未开始 | M4 | P1 | CAS联动 | function/CAS |
| P-044 | Plane 函数 / CAS | 不等式 | Graphing / Inequalities | 未开始 | M5 | P2 | 图形质量 | function/CAS |
| P-045 | Plane 函数 / CAS | 求根 | CAS / Roots | 未开始 | M4 | P0 | CAS联动 | function/CAS |
| P-046 | Plane 函数 / CAS | 极值 | CAS / Extrema | 未开始 | M4 | P1 | CAS联动 | function/CAS |
| P-047 | Plane 函数 / CAS | 交点 | CAS / Intersections | 部分具备 | M4 | P1 | CAS联动 | function/CAS |
| P-048 | Plane 函数 / CAS | 导数 | CAS / Derivative | 未开始 | M4 | P0 | CAS联动 | function/CAS |
| P-049 | Plane 函数 / CAS | 切线 | CAS / Tangent | 未开始 | M4 | P1 | CAS联动 | function/CAS |
| P-050 | Plane 函数 / CAS | 法线 | CAS / Normal | 未开始 | M4 | P2 | CAS联动 | function/CAS |
| P-051 | Plane 函数 / CAS | 积分 | CAS / Integral | 未开始 | M4 | P1 | CAS联动 | function/CAS |
| P-052 | Plane 函数 / CAS | 化简 | CAS / Simplify | 部分具备 | M4 | P1 | CAS联动 | function/CAS |
| P-053 | Plane 函数 / CAS | 因式分解 | CAS / Factor | 部分具备 | M4 | P1 | CAS联动 | function/CAS |
| P-054 | Plane 函数 / CAS | 方程求解 | CAS / Solve | 未开始 | M4 | P0 | CAS联动 | function/CAS |
| P-055 | Plane 函数 / CAS | sliders / parameters | Geometry / Sliders | 部分具备 | M4 | P1 | 保存兼容 | dynamic geometry |
| P-056 | Plane 函数 / CAS | table of values | Algebra / Table | 未开始 | M4 | P1 | UI复杂度 | function/CAS |
| P-057 | Plane 高阶对象与导出 | 圆锥曲线 | Graphing / Conics | 部分具备 | M5 | P1 | 图形质量 | conic |
| P-058 | Plane 高阶对象与导出 | text | Geometry / Text | 未开始 | M5 | P2 | UI复杂度 | 2D basic geometry |
| P-059 | Plane 高阶对象与导出 | image | Geometry / Image | 未开始 | M5 | P2 | 保存兼容 | 2D basic geometry |
| P-060 | Plane 高阶对象与导出 | button | Geometry / Button | 未开始 | M5 | P2 | UI复杂度 | dynamic geometry |
| P-061 | Plane 高阶对象与导出 | input-box | Geometry / Input Box | 未开始 | M5 | P2 | UI复杂度 | dynamic geometry |
| P-062 | Plane 高阶对象与导出 | checkbox | Geometry / Checkbox | 未开始 | M5 | P2 | UI复杂度 | dynamic geometry |
| P-063 | Plane 高阶对象与导出 | SVG export | Export / SVG | 未开始 | M5 | P1 | 保存兼容 | conic |
| P-064 | Plane 高阶对象与导出 | PDF export | Export / PDF | 未开始 | M5 | P2 | 保存兼容 | conic |
| P-065 | Plane 高阶对象与导出 | TikZ export | Export / TikZ | 未开始 | M5 | P1 | 保存兼容 | conic |
| P-066 | Plane 高阶对象与导出 | clipboard export | Export / Clipboard | 未开始 | M5 | P1 | 三平台适配 | 2D basic geometry |
| S-001 | Space 基础 | 3D 点 | 3D Graphics / Point | 骨架已具备 | M6 | P1 | 3D稳定性 | 3D primitives |
| S-002 | Space 基础 | 3D 线 | 3D Graphics / Line | 骨架已具备 | M6 | P1 | 3D稳定性 | 3D primitives |
| S-003 | Space 基础 | 3D 线段 | 3D Graphics / Segment | 骨架已具备 | M6 | P1 | 3D稳定性 | 3D primitives |
| S-004 | Space 基础 | 3D 射线 | 3D Graphics / Ray | 待确认 | M6 | P1 | 3D稳定性 | 3D primitives |
| S-005 | Space 基础 | 3D 向量 | 3D Graphics / Vector | 待确认 | M6 | P1 | 3D稳定性 | 3D primitives |
| S-006 | Space 基础 | 平面 | 3D Graphics / Plane | 骨架已具备 | M6 | P1 | 3D稳定性 | 3D primitives |
| S-007 | Space 基础 | 3D 交点 | 3D Graphics / Intersect | 待确认 | M6 | P1 | 3D稳定性 | 3D primitives |
| S-008 | Space 基础 | camera | 3D Graphics / Camera | 骨架已具备 | M6 | P0 | 三平台适配 | 3D primitives |
| S-009 | Space 基础 | work plane | 3D Graphics / Work Plane | 骨架已具备 | M6 | P0 | 3D稳定性 | 3D primitives |
| S-010 | Space 基础 | 3D selection | 3D Graphics / Selection | 骨架已具备 | M6 | P1 | 3D稳定性 | 3D primitives |
| S-011 | Space 基础 | 3D inspector | 3D Graphics / Inspector | 骨架已具备 | M6 | P1 | UI复杂度 | 3D primitives |
| S-012 | Space 基础 | save/reopen | 3D Graphics / Save-Load | 骨架已具备 | M6 | P0 | 保存兼容 | 3D primitives |
| S-013 | Space 立体几何 | sphere | 3D Graphics / Sphere | 未开始 | M7 | P1 | 3D稳定性 | 3D solids |
| S-014 | Space 立体几何 | cone | 3D Graphics / Cone | 未开始 | M7 | P1 | 3D稳定性 | 3D solids |
| S-015 | Space 立体几何 | cylinder | 3D Graphics / Cylinder | 未开始 | M7 | P1 | 3D稳定性 | 3D solids |
| S-016 | Space 立体几何 | prism | 3D Graphics / Prism | 未开始 | M7 | P1 | 3D稳定性 | 3D solids |
| S-017 | Space 立体几何 | pyramid | 3D Graphics / Pyramid | 未开始 | M7 | P1 | 3D稳定性 | 3D solids |
| S-018 | Space 立体几何 | tetrahedron | 3D Graphics / Tetrahedron | 未开始 | M7 | P1 | 3D稳定性 | 3D solids |
| S-019 | Space 立体几何 | cube | 3D Graphics / Cube | 未开始 | M7 | P1 | 3D稳定性 | 3D solids |
| S-020 | Space 立体几何 | polyhedra | 3D Graphics / Polyhedra | 未开始 | M7 | P2 | 3D稳定性 | 3D solids |
| S-021 | Space 立体几何 | line-plane intersection | 3D Graphics / Intersections | 未开始 | M7 | P1 | 3D稳定性 | 3D solids |
| S-022 | Space 立体几何 | plane-plane intersection | 3D Graphics / Intersections | 未开始 | M7 | P1 | 3D稳定性 | 3D solids |
| S-023 | Space 立体几何 | parallel/perpendicular in 3D | 3D Graphics / Constructions | 未开始 | M7 | P1 | 3D稳定性 | 3D solids |
| S-024 | Space 曲线 / 曲面 | 3D parametric curves | 3D Graphics / Parametric Curve | 未开始 | M8 | P2 | 图形质量 | 3D surfaces |
| S-025 | Space 曲线 / 曲面 | parametric surfaces | 3D Graphics / Parametric Surface | 未开始 | M8 | P2 | 图形质量 | 3D surfaces |
| S-026 | Space 曲线 / 曲面 | implicit surfaces | 3D Graphics / Implicit Surface | 未开始 | M8 | P3 | 图形质量 | 3D surfaces |
| S-027 | Space 曲线 / 曲面 | quadrics | 3D Graphics / Quadrics | 未开始 | M8 | P2 | 3D稳定性 | 3D surfaces |
| S-028 | Space 曲线 / 曲面 | section curves | 3D Graphics / Section Curve | 未开始 | M8 | P2 | 图形质量 | 3D surfaces |
| S-029 | Space 曲线 / 曲面 | surface transparency | 3D Graphics / Surface Style | 未开始 | M8 | P2 | 三平台适配 | 3D surfaces |
| S-030 | Space 曲线 / 曲面 | hidden-line | 3D Graphics / Hidden-Line | 未开始 | M8 | P2 | 三平台适配 | 3D surfaces |
| D-001 | 文档与系统能力 | dependency graph | Core Geometry Dependency | 部分具备 | M1 | P0 | 依赖图扩张 | dynamic geometry |
| D-002 | 文档与系统能力 | object lifecycle | Document / History / Delete-Recover | 部分具备 | M1 | P0 | 保存兼容 | 2D basic geometry |
| D-003 | 文档与系统能力 | versioned serialization | Document / Package Evolution | 待确认 | M1 | P1 | 保存兼容 | 2D basic geometry |
| D-004 | 文档与系统能力 | object style | Style / Presets | 部分具备 | M1 | P1 | UI复杂度 | 2D basic geometry |
| D-005 | 文档与系统能力 | label | Naming / Labeling | 部分具备 | M1 | P1 | 保存兼容 | 2D basic geometry |
| D-006 | 文档与系统能力 | lock | Object Properties / Lock | 未开始 | M5 | P1 | UI复杂度 | dynamic geometry |
| D-007 | 文档与系统能力 | visibility | Object Properties / Visibility | 部分具备 | M1 | P1 | 保存兼容 | 2D basic geometry |
| D-008 | 文档与系统能力 | trace | Object Properties / Trace | 部分具备 | M5 | P2 | 图形质量 | dynamic geometry |
| D-009 | 文档与系统能力 | animation | Object Properties / Animation | 部分具备 | M5 | P2 | 三平台适配 | dynamic geometry |
| D-010 | 文档与系统能力 | layer/group | Object Properties / Grouping | 未开始 | M5 | P2 | UI复杂度 | 2D transform |
| D-011 | 文档与系统能力 | object panel | Workspace / Object Management | 部分具备 | M1 | P1 | UI复杂度 | 2D basic geometry |
| D-012 | 文档与系统能力 | inspector | Workspace / Inspector | 部分具备 | M1 | P1 | UI复杂度 | 2D basic geometry |
| D-013 | 文档与系统能力 | save/reopen | Document / Package | 已具备 | M1 | P0 | 保存兼容 | 2D basic geometry |
| D-014 | 文档与系统能力 | project thumbnail | Home / preview.png | 已具备 | M1 | P0 | 保存兼容 | 2D basic geometry |
| D-015 | 文档与系统能力 | iPad/macOS/iPhone 验收 | Cross-Platform Acceptance | 部分具备 | M0 | P0 | 三平台适配 | 2D basic geometry |

## 5. 当前阶段优先级建议

> 这不是建议立刻启动大规模 `M1` 重构。当前最合理的顺序，是先补回归基线与黄金样例，再进入共享依赖图设计。

| 优先级 | 建议任务 | 原因 | 是否改源码 | 推荐下一步 |
|---|---|---|---|---|
| P0 | Plane UI polish regression | Plane UI 近期已经有多轮小修，但正式回归基线仍不足，容易出现输入栏、对象区、键盘、玻璃层的回退 | 否 | 先出一份 regression report，固定验收清单 |
| P0 | Graph Quality Baseline | `GraphIntent + Sampling` 已存在，但复杂函数、断点、渐近线、隐函数质量仍会直接影响 GeoGebra 对齐主观体验 | 否 | 先做图形质量基线报告，再决定是否动采样 |
| P0 | SaveLoad Edge Cases | 未来 Plane/Space 扩对象面时，保存/重开兼容是高风险源头；应先摸清当前包结构与边缘案例 | 否 | 先做边界审计，不急于改 codec |
| P1 | M0 Golden Fixture 设计 | 没有统一 fixture，后续功能越多回归越难做，且三平台验收会失控 | 否 | 先定 fixture 列表与验收模板 |
| P1 | M1-A 依赖图只读审计 | 共享依赖图是长期关键，但现在直接重构风险高；先只读梳理现有 Plane/Space 依赖关系更安全 | 否 | 审计现有 dependency graph、lifecycle、serialization 接口 |

## 6. M0 Golden Fixtures 初稿

| fixture | 覆盖能力 | 对象数量 | 验收步骤 | 保存重开检查 | 目标阶段 |
|---|---|---|---|---|---|
| 2D basic geometry | 点、线、线段、射线、圆、圆弧、命名、选择、删除 | 小型（5-10） | 创建 -> 选择 -> 拖拽 -> 删除 -> 保存 -> 重开 | 名称是否保留、对象数量是否一致、缩略图是否更新 | M0 |
| 2D construction | 中点、交点、平行线、垂线、依赖更新 | 中型（10-20） | 创建 -> 拖拽源对象 -> 检查派生更新 -> 删除源对象 -> 保存 -> 重开 | 依赖关系是否保留、删除后是否一致、重开后派生是否仍正确 | M0 |
| 2D transform | 平移、旋转、反射、位似、可见性/锁定（后续） | 中型（10-20） | 创建 -> 变换 -> 编辑 -> 删除 -> 保存 -> 重开 | 变换结果是否保留、标签是否保留、视口是否保留 | M0 |
| conic | 圆、椭圆、抛物线、双曲线、圆锥曲线识别/绘制 | 中型（10-20） | 输入/构造 -> 预览 -> 提交 -> 编辑 -> 保存 -> 重开 | 表达式是否保留、分类是否一致、缩略图是否正确 | M0 |
| function/CAS | 显函数、隐函数、参数曲线、极坐标、分段函数、导数/积分/求根（后续） | 中型（10-20） | 输入 -> 预览 -> 提交 -> 编辑 -> 求值/派生 -> 保存 -> 重开 | 表达式与 AST metadata 是否保留、预览图是否更新 | M0 |
| dynamic geometry | 参数、slider、trace、locus、依赖拖拽 | 中型（10-20） | 创建 -> 改参数 -> 拖拽 -> 检查联动 -> 保存 -> 重开 | 参数值是否保留、联动关系是否保留、trace/visibility 状态是否保留 | M0 |
| 3D primitives | 3D 点、线、线段、平面、camera、work plane、selection | 小型（5-10） | 创建 -> 旋转视角 -> 选择 -> 删除 -> 保存 -> 重开 | 相机/视角是否保留、work plane 是否保留、对象是否保留 | M0 |
| 3D solids | sphere、cone、cylinder、prism、pyramid、cube、交点/平行垂直（后续） | 中型（10-20） | 创建 -> 选择 -> 编辑 -> 删除 -> 保存 -> 重开 | 立体参数是否保留、相机是否保留、缩略图是否更新 | M0 |
| 3D surfaces | 参数曲面、隐式曲面、quadrics、section curves、透明度/hidden-line | 大型（20+） | 创建 -> 调整采样/视角 -> 编辑 -> 保存 -> 重开 | 曲面参数是否保留、相机是否保留、显示样式是否保留 | M0 |

## 7. 风险清单

| 风险 | 影响模块 | 风险等级 | 规避方式 |
|---|---|---|---|
| 过早重构 WorkspaceKit | `WorkspaceKit`, `Plane`, `Space` | 高 | 先只读审计再设计接口 |
| Plane/Space 依赖图抽象过早 | `MathCore`, `Plane`, `Space`, `DocumentSystem` | 高 | 先 fixture 后 feature，再做共享依赖图设计 |
| iPhone 适配拖慢主线 | `WorkspaceView`, `CoreHome`, `Plane`, `Space` | 中 | iPad 先闭环后再压缩到小屏 |
| CAS 过早扩张 | `CASCore`, `EvaluationCore`, `Plane` | 高 | 先围绕 GeoGebra 几何主线补必要 CAS，不开全量 CAS 分支 |
| Space 曲面过早铺开 | `Space`, `SpaceMathCore`, `SamplingCore` | 高 | Plane 稳定后再扩 Space surfaces |
| GeoGebra 参考边界不清 | 全局路线、任务拆分、验收口径 | 高 | 明确只对标 geometry / 3D / 必要 CAS，不把 Spreadsheet / Probability 混入主线 |
| golden fixture 缺失导致回归困难 | `Plane`, `Space`, `DocumentSystem`, `CoreHome` | 高 | 先建立 M0 fixture，再扩对象族和工具链 |

## 8. 下一轮任务建议

| 任务 | 类型 | 预计范围 | 是否建议立即做 |
|---|---|---|---|
| Plane UI Polish Regression Report | 只读回归文档 | 输入栏、对象区、键盘、glass、compact 布局的正式回归清单 | 是 |
| Graph Quality Baseline Report | 只读技术审计 | `GraphIntent`、`SamplingCore`、函数/隐函数/断点/渐近线质量基线 | 是 |
| SaveLoad Edge Cases Audit | 只读边缘审计 | `DocumentSystem`、`.emathica` 包、preview、对象 metadata、重开一致性 | 是 |

## 9. 说明

- 本文档只整理 capability matrix，不直接推进功能开发。
- GeoGebra 相关内容在本文中只用于功能与工作流对标，不构成代码移植方案。
- 若后续进入具体实现，应优先从：
  - regression baseline
  - golden fixture
  - save/load 边界
  - dependency graph 只读审计
  这四类前置工作开始，而不是直接进入大规模重构。
