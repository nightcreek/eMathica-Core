# Unified Calculator Architecture

> **日期:** 2026-06-17
> **模式:** 只读架构审计
> **输入:** 全部 8 份 AI/Audits/ 文档 + 3 份 AI/Design/ 矩阵 + 源码审计
> **原则:** Calculator 是 View/Interaction Adapter，不是数据边界

---

## 1. Calculator 的正式定义

```
Calculator
  =
  View Adapter          (Canvas 渲染器)
  +
  Interaction Adapter   (Tool/Gesture/Command 处理器)
  +
  Tool Provider         (WorkspaceToolGroup 注册)
  +
  Capability Consumer   (Capability 调用者，非实现者)
```

### 1.1 Calculator 不是什么

| 常见误解 | 正确理解 |
|---------|---------|
| Calculator 是数据边界 | ❌ Object 属于 Document，不属于 Calculator |
| Calculator 拥有对象 | ❌ 对象由 Document 统一管理，Calculator 通过 `createdBy` 记录创建历史 |
| Calculator 决定 Object Kind | ❌ Kind 由数学语义决定，Calculator 是创建者而非定义者 |
| Calculator 实现数学能力 | ❌ 数学能力属于 Package（CAS/Graph/Sampling/Geometry），Calculator 是调用者 |
| Calculator 隔离数据 | ❌ Unified EMathicaDocument 的 objects 数组对所有 Calculator 可见 |

### 1.2 Calculator 是什么

| 职责 | 说明 | 示例 |
|------|------|------|
| **View Adapter** | 提供 Calculator 专属的 Canvas 视图 | `PlaneCanvasView` 渲染 2D 坐标系 + 网格 + 对象 |
| **Interaction Adapter** | 处理用户手势、工具操作、构造交互 | `PlaneInteractionReducer` 管理 11 种构造模式状态机 |
| **Tool Provider** | 注册 Calculator 的工具面板 | `PlaneToolProvider` 提供 15 个工具 (select/pan/delete + 12 geometry tools) |
| **Capability Consumer** | 调用 Package 提供的数学能力 | Plane 调用 `ExplicitFunctionSampler2D`、`AlgebraCore.analyzePlaneLatex()` |
| **Command Handler** | 处理 WorkspaceCommand 并返回 DocumentCommand + WorkspaceEffect | `PlaneCommandHandler` 处理 30+ 种命令 |

---

## 2. Calculator 的四层架构

```
┌─────────────────────────────────────────────────────────────┐
│                    Calculator Layer                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │    Plane     │  │    Space     │  │    Data◎     │  ...  │
│  │  Calculator  │  │  Calculator  │  │  Calculator  │       │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘       │
│         │                  │                  │               │
├─────────┼──────────────────┼──────────────────┼───────────────┤
│         │    WorkspaceKit Bridge (协议层)     │               │
│  ┌──────┴──────────────────┴──────────────────┴───────┐      │
│  │         WorkspaceModuleProviding                   │      │
│  │  - makeCanvasView()  - toolGroups                  │      │
│  │  - commandHandler     - makeDraftMathObject()       │      │
│  │  - geometryDependencyService (optional)            │      │
│  │  - semanticIntentAdapter (optional)                │      │
│  └──────┬─────────────────────────────────────────────┘      │
│         │                                                     │
├─────────┼─────────────────────────────────────────────────────┤
│         │          Document Layer (数据层)                    │
│  ┌──────┴──────────────────────────────────────────────┐     │
│  │              EMathicaDocument                        │     │
│  │  - objects: [MathObject]   ← object-first kind      │     │
│  │  - primaryCalculator: CalculatorID                   │     │
│  │  - enabledCalculators: [CalculatorID]                │     │
│  │  - canvasState / spaceCameraState                    │     │
│  └──────┬──────────────────────────────────────────────┘     │
│         │                                                     │
├─────────┼─────────────────────────────────────────────────────┤
│         │           Package Layer (能力层)                   │
│  ┌──────┴──────────────────────────────────────────────┐     │
│  │  EMathicaMathCore  (CAS + Graph + Sampling + Geometry)│    │
│  │  EMathicaDocumentKit  (DocumentCommand + ObjectPatch) │    │
│  │  EMathicaWorkspaceKit  (ModuleProviding + Command)    │    │
│  └─────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

**数据流向:**
```
User Gesture
  → Calculator.InteractionAdapter (PlaneInteractionReducer)
    → Calculator.CommandHandler (PlaneCommandHandler)
      → DocumentCommand.addObject/updateObject (EMathicaDocumentKit)
        → EMathicaDocument.apply(command)
          → [MathObject] 数组更新
      → WorkspaceEffect.select/clearSelection (EMathicaWorkspaceKit)
        → WorkspaceState 更新
  → Calculator.ViewAdapter (PlaneCanvasView)
    → 读取 EMathicaDocument.objects
      → 调用 Capability: geometry.present.* (PlaneObjectRendererView)
        → SwiftUI Canvas 渲染
```

---

## 3. 当前 6 个 Calculator 是否符合该模型

### 3.1 Plane Calculator

| 维度 | 当前状态 | 符合度 | 问题 |
|------|---------|--------|------|
| **View Adapter** | `PlaneCanvasView` + `PlaneObjectRendererView` + `PlaneGridRendererView` + `PlaneAxisRendererView` | ✅ 完整 | 渲染代码分散在 App Target，未 package 化 |
| **Interaction Adapter** | `PlaneInteractionReducer` + `PlaneInteractionState` + `PlaneConstructionMode` + `PlaneConstructionPreview` | ✅ 完整 | 构造模式状态机过于复杂 (11 states) |
| **Tool Provider** | `PlaneToolProvider` (3 groups, 15 tools) | ✅ 完整 | Tool ID 命名 convention 良好 (`plane.*`) |
| **Capability Consumer** | 调用 CAS (AlgebraCore/SymbolicDifferentiator/EquationSolver)、Graph (SemanticGraphIntentAdapter)、Sampling (ExplicitFunctionSampler2D/ParametricCurveSampler)、Geometry (PlaneGeometryResolver) | ⚠️ 混合 | Plane 直接调用 MathCore 的内部实现，而非通过 protocol 抽象 |
| **Command Handler** | `PlaneCommandHandler` (1200+ lines, 30+ commands) | ✅ 完整 | 1200+ 行过于庞大，应拆分 |

**符合度评分: 85%** — 四层职责明确，但 Capability Consumer 职责与 Capability Implementor 混淆。

### 3.2 Space Calculator

| 维度 | 当前状态 | 符合度 | 问题 |
|------|---------|--------|------|
| **View Adapter** | `SpaceCanvasView` + `SpaceCalculatorPlaceholderView` | ⚠️ 部分 | Wireframe 渲染仅基础，无 surface 渲染 |
| **Interaction Adapter** | 手势处理在 `SpaceCanvasView` 内联 | ⚠️ 部分 | 无独立的 InteractionReducer，交互逻辑分散 |
| **Tool Provider** | `SpaceToolProvider` (2 groups, 7 tools) | ✅ 完整 | 合理的基础工具集 |
| **Capability Consumer** | 调用 SpaceMath3D (WorldPoint3D/Vector3D/Camera) | ⚠️ 部分 | 3D 采样、3D 分类、3D 几何依赖等能力未接入 |
| **Command Handler** | `SpaceCommandHandler` (basic 3D creation) | ⚠️ 部分 | 无 geometry dependency 处理，无 semantic intent |

**符合度评分: 45%** — 框架正确但实现不完整；`geometryDependencyService` 和 `semanticIntentAdapter` 返回 nil。

### 3.3 Data Calculator

| 维度 | 当前状态 | 符合度 | 问题 |
|------|---------|--------|------|
| **View Adapter** | `DataPlaceholderView` (仅 "开发中" 文本) | ❌ 无 | 无实现 |
| **Interaction Adapter** | 无 | ❌ 无 | 无实现 |
| **Tool Provider** | `DefaultWorkspaceModuleProvider` 的 2 个基础工具 | ❌ 极简 | 无 Data 专属工具 |
| **Capability Consumer** | 无 | ❌ 无 | 无实现 |
| **Command Handler** | `NoopCommandHandler` | ❌ 无 | 仅处理基础选择/工具切换 |

**符合度评分: 0%** — 完全占位，无任何 Calculator 功能。但框架已就位（`DefaultWorkspaceModuleProvider(module: .data)`）。

### 3.4 Music Calculator

| 维度 | 同 Data | 符合度 |
|------|---------|--------|
| 所有维度 | `DefaultWorkspaceModuleProvider(module: .music)` + `MusicPlaceholderView` | **0%** |

### 3.5 Notes Calculator

| 维度 | 同 Data | 符合度 |
|------|---------|--------|
| 所有维度 | `DefaultWorkspaceModuleProvider(module: .notes)` + `NotesPlaceholderView` | **0%** |

### 3.6 Modeling Calculator

| 维度 | 同 Data | 符合度 |
|------|---------|--------|
| 所有维度 | `DefaultWorkspaceModuleProvider(module: .modeling)` + `ModelingPlaceholderView` | **0%** |

---

## 4. Plane-Centric Reality vs Document-Centric Target

### 4.1 当前架构现实: Plane-Centric

```
当前:
  EMathicaDocument.moduleID = "plane" | "space" | ...
    → 文档锁定到特定 Calculator
    → 切换 Calculator = 切换文档

  MathObject.type = .function | .point | .circle | ...
    → 类型名偏向 2D Plane 语义
    → .function 同时表示 curve.explicit2d 和 formula.symbolic 和 Space plane.3d

  CalculatorModules/Plane/Services/
    → 所有几何/采样/命中测试服务 Plane 专属
    → PlaneGeometryResolver, PlaneHitTestService, PlaneDraftPreviewService

  结论: 系统假设文档 = 单一 Calculator 的工作空间
```

### 4.2 目标架构: Document-Centric

```
目标:
  EMathicaDocument
    primaryCalculator: CalculatorID     ← 默认打开的 Calculator
    enabledCalculators: [CalculatorID]  ← 可访问此文档的 Calculator 列表
    objects: [MathObject]              ← 所有对象，不分 Calculator

  MathObject
    kind: ObjectKind                   ← "point.2d" | "point.3d" | "curve.explicit2d"
    createdBy: CalculatorID            ← 创建者 (不可变)
    preferredViews: [ViewDescriptor]   ← 首选视图
    enabledCalculators: [CalculatorID] ← 可编辑此对象的 Calculator

  CalculatorModules/{Calculator}/Services/
    → 每个 Calculator 有独立的 Service Adapter
    → Adapter 实现共享的 Service Protocol (来自 Package)
    → PlaneGeometryAdapter : GeometryService
    → SpaceGeometryAdapter : GeometryService
```

### 4.3 过渡路径

```
阶段 A (当前 → P1)
  冻结 ObjectKind 规范
  定义 Unified EMathicaDocument 结构（primaryCalculator + enabledCalculators）
  定义 Service Protocols (GeometryService, HitTestService, PreviewService)
  不动源码

阶段 B (P1 → P2)
  实现 trans.json 存储
  实现 point.2d ↔ point.3d 转换
  为 Plane 服务添加 Protocol 抽象层（保留当前实现，添加适配）

阶段 C (P2 → P3)
  提取 CASCore / GraphIntentCore / SamplingCore 为独立 Package
  GeometryService / HitTestService / PreviewService 协议入 Package
  Plane 和 Space 各自实现 Adapter

阶段 D (P3 → P4)
  移除 Plane 专属服务直接调用
  Plane → 通过 GeometryService 协议调用
  Space → 同样通过 GeometryService 协议调用
  Data/Music/Notes 开始开发
```

---

## 5. Plane 专属能力分析

### 5.1 可以为 Generic Capability 的能力

| Plane 专属服务 | 可抽象为 | 目标 Package | Space 复用? | Data 复用? |
|---------------|---------|-------------|------------|-----------|
| `PlaneGeometryResolver` | `GeometryService` 协议 | EMathicaGeometryCore | ✅ (3D 版本) | ✅ (数据点处理) |
| `PlaneHitTestService` | `HitTestService` 协议 | EMathicaGeometryCore | ✅ (3D 射线) | ✅ (散点图选择) |
| `PlaneDraftPreviewService` | `DraftPreviewService` 协议 | EMathicaPreviewKit | ✅ (3D 预览) | ✅ (表格预览) |
| `PlaneIntersectionSolver` | `IntersectionService` 协议 | EMathicaGeometryCore | ✅ (3D 相交) | ❌ |
| `PlaneLineClipping` | `LineClippingService` (通用 2D 裁剪) | EMathicaGeometryCore | ✅ (视口裁剪) | ✅ (图表裁剪) |
| `PlaneExpressionService` | `ExpressionParsingService` 协议 | EMathicaMathCore | ✅ | ✅ (公式解析) |
| `PlaneInputCanonicalizer` | `InputCanonicalizer` 协议 | EMathicaMathCore | ✅ | ✅ |

### 5.2 必须保留为 Plane Adapter 的能力

| Plane 专属服务 | 保留原因 |
|---------------|---------|
| `PlaneConstructionMode` (11 states) | 2D 几何构造是 Plane 的独特交互模式，Space/Data/Music/Notes 不需要 |
| `PlaneInteractionReducer` | 2D Canvas 手势处理的特定实现 |
| `PlaneInteractionState` | 2D 构造状态机（拖拽、吸附、预览） |
| `PlaneConstructionPreview` | 2D 临时视觉反馈（虚线辅助线、临时交点） |
| `PlaneToolIDs` / `PlaneToolActions` | 2D 工具面板的特定工具集 |
| `PlaneObjectNamingService` | Plane 特有的命名规则（A, B, C, f, g, h, c1, c2, ...） |
| `PlaneSemanticIntentAdapter` | 将 GraphIntent 映射到 Plane 的 SemanticGraphKind（其他 Calculator 可能用不同的映射） |
| `PlaneSemanticIntentResolver` | 同上 |
| `PlaneGeometryPresentationResolver` | 2D 坐标系下的几何对象呈现逻辑 |
| `PlaneLegacyExplicitSampling` | 应在 P3 废弃，不应保留 |
| `PlaneSampleSetAdapter` / `PlaneSamplingComparisonDebug` / `PlaneSemanticSamplingDebug` | 开发调试工具，应移除或移至 Debug Utilities |

### 5.3 未来迁移

| 能力 | 当前归属 | 迁移目标 |
|------|---------|---------|
| `PlaneFallbackSamplingService` | Plane/ | 废弃（由 `ExplicitFunctionSampler2D` 替代） |
| 表达式解析 `AlgebraCore.analyzePlaneLatex()` | MathCore (但方法名带 Plane) | 重命名为 `AlgebraCore.parseLatex()` |
| `MathObjectType` enum | MathCore (9 cases, 2D biased) | 迁移为 `ObjectKind` string (38 kinds) |

---

## 6. Calculator 与 Plugin System 的关系

### 6.1 三层协作模型

```
Plugin Block (用户组合的能力链)
  │
  │ 消费 Capability
  ▼
Capability (Package 提供的能力)
  │
  │ 产生输出数据
  ▼
Calculator (View/Interaction Adapter)
  │
  │ 消费 Plugin Block 结果
  ▼
Document (持久化)
```

### 6.2 Calculator 消费插件结果

| Calculator | 可消费的插件输出 | 示例 |
|-----------|----------------|------|
| **Plane** | point.2d, curve.explicit2d, set.point2d, formula.symbolic | 插件生成一条拟合曲线 → Plane 渲染到坐标系 |
| **Space** | point.3d, curve.parametric3d, surface.* | 插件生成参数曲面 → Space 3D 渲染 |
| **Data** | table.data, table.function, set.* | 插件计算结果集 → Data 表格显示 |
| **Music** | wave.audio | 插件生成音频波形 → Music 播放 |
| **Notes** | formula.symbolic, text.block | 插件生成公式 → Notes 排版 |
| **Modeling** | surface.*, curve.parametric3d | 插件生成几何模型 → Modeling 渲染 |

### 6.3 Calculator 产生插件输入

| Calculator | 可为插件提供的输入 | 示例 |
|-----------|-------------------|------|
| **Plane** | MathObject (curve/point/geometry), CanvasState (viewport) | 用户选中一条曲线 → 插件对其进行傅里叶分析 |
| **Space** | MathObject (3D geometry), SpaceCameraState | 用户选中曲面 → 插件计算曲率分布 |
| **Data** | table.data (CSV), table.function | 用户导入数据 → 插件进行统计分析 |
| **Notes** | formula.symbolic (LaTeX) | 用户输入公式 → 插件验证/简化 |

### 6.4 哪些 Capability 可暴露给插件

```
Safe (可暴露):
  - cas.* (normalize, simplify, differentiate, solve)
  - graph.classify.*
  - graph.sample.*
  - formula.render.*
  - expr.parse.*, expr.format.*
  - geometry.intersection, geometry.distance
  - style.*

Restricted (需用户确认):
  - document.object.*
  - command.*
  - selection.*
  - preview.*
  - object.convert.*
  - animation.parameter.play

Internal (不可暴露):
  - workspace.*
  - document.package.codec
  - input.*
  - plugin.*
```

---

## 7. Calculator 注册与发现

### 7.1 当前注册方式

```swift
// CalculatorModuleRegistry.swift (当前)
enum CalculatorModuleRegistry {
    static let all: [CalculatorModule] = [
        CalculatorModule(id: .plane,   title: "平面计算器", ...),
        CalculatorModule(id: .space,   title: "立体计算器", ...),
        CalculatorModule(id: .modeling, title: "建模", ...),
        CalculatorModule(id: .music,   title: "音乐", ...),
        CalculatorModule(id: .data,    title: "数据分析", ...),
        CalculatorModule(id: .notes,   title: "笔记与公式", ...)
    ]
}
```

### 7.2 未来发现方式

```
统一注册:
  Calculator Registry (EMathicaWorkspaceKit)
    ├── CalculatorDescriptor { id, title, subtitle, iconName }
    ├── CalculatorCapabilityDescriptor { supportedKinds, supportedConversions }
    └── CalculatorProvider { createModuleProvider() → WorkspaceModuleProviding }

能力声明:
  每个 Calculator 声明:
    - supportedKinds: [ObjectKind]         (可 Create/Edit)
    - viewableKinds: [ObjectKind]          (可 View/Embed)
    - supportedConversions: [Conversion]   (可触发 Convert)
    - consumedCapabilities: [CapabilityID] (调用的 Capability)
    - providedInputs: [ObjectKind]         (可为插件提供的输入)
```

---

## 8. 架构评分

### 8.1 当前架构 (Plane-Centric)

| 维度 | 评分 | 说明 |
|------|------|------|
| Calculator 职责清晰度 | ●●●●○ 80% | Plane 职责明确，Space 框架正确但实现不完整 |
| 数据与视图分离 | ●●●○○ 60% | `EMathicaDocument` 已独立于 Calculator，但 `moduleID` 绑定仍存在 |
| Capability 抽象度 | ●●○○○ 40% | Plane 直接调用 MathCore 内部实现，非协议抽象 |
| 跨 Calculator 协作 | ●○○○○ 20% | 仅 View Adaptation，无 Materialize Conversion |
| 可扩展性 | ●●●○○ 60% | `WorkspaceModuleProviding` 协议设计良好，Plugin 预留 |
| 代码去重 | ●●○○○ 40% | DocumentSystem 与 EMathicaDocumentKit 重复 |
| **综合** | **●●●○○ 50%** | |

### 8.2 目标架构 (Document-Centric)

| 维度 | 目标评分 | 关键变化 |
|------|---------|---------|
| Calculator 职责清晰度 | ●●●●● 100% | Calculator = View + Interaction + Tool + Capability Consumer |
| 数据与视图分离 | ●●●●● 100% | Unified EMathicaDocument 不绑定 Calculator |
| Capability 抽象度 | ●●●●● 100% | 所有能力通过 Package Protocol 调用 |
| 跨 Calculator 协作 | ●●●●○ 80% | Materialize Conversion + trans.json + Plugin Pipeline |
| 可扩展性 | ●●●●● 100% | 新 Calculator 只需实现 WorkspaceModuleProviding |
| 代码去重 | ●●●●● 100% | DocumentSystem 去重完成 |
| **综合** | **●●●●● 97%** | |

### 8.3 迁移难度

| 迁移阶段 | 难度 | 说明 |
|---------|------|------|
| P0: DocumentSystem 去重 | **Low** | 低风险删除+验证，工程量小 |
| P1: Design Freeze | **Low** | 纯设计文档，不动源码 |
| P2: MathCore Split | **Medium** | 需修改 Package.swift（Architecture Freeze 后才允许） |
| P3: Normalize First | **Medium** | 废除 Legacy 采样、统一渲染入口，需重构+测试 |
| P4: Future Calculators | **High** | Data/Music/Notes/Modeling 从头开发 |
| Service Protocol 抽象 | **High** | 重构 Plane 所有服务调用，添加协议层 |
| trans.json + Conversion | **Medium** | 新功能开发，不破坏现有代码 |
| Plugin System | **Very High** | 全新系统，依赖所有上游成熟 |

---

## 9. 最推荐的下一步

### 9.1 只能推荐设计冻结

| 推荐 | 优先级 | 原因 |
|------|--------|------|
| **P1 Object-First Kind 设计冻结** | 立即 | 所有后续架构决策依赖 kind 规范 |
| **Unified EMathicaDocument 结构冻结** | 立即 | primaryCalculator / enabledCalculators 字段定义 |
| **Calculator 能力声明格式冻结** | 短期 | supportedKinds / supportedConversions 格式 |
| **Service Protocol 接口草案** | 短期 | GeometryService / HitTestService / DraftPreviewService 协议定义 |

### 9.2 禁止推荐

| 禁止 | 原因 |
|------|------|
| 立即重构 Plane 服务 | 需先冻结协议，否则重构后仍需再次调整 |
| 立即删除 DocumentSystem 代码 | 需在独立低风险执行任务中完成（grep 验证引用） |
| 立即创建新 Package | Architecture Freeze 期间禁止修改 Package.swift / xcodeproj |
| 立即实现 trans.json | 需先冻结 kind 规范和存储格式 |

---

## 10. 当前最大架构风险

1. **MathObjectType 阻碍多 Calculator 扩展** — 9 个 case 的平面枚举无法表达 38 种 object kind；Space 已通过 type hacking 绕过限制
2. **DocumentSystem 与 Package 重复** — `GeometryDefinition` 陈旧副本缺少 `.arc` case，App Target 可能引用了错误的版本
3. **Plane 占有过多能力** — `PlaneExpressionService` 和 `AlgebraCore.analyzePlaneLatex()` 将 LaTeX 解析锁定在 Plane 上下文，其他 Calculator 无法复用
4. **缺失跨 Calculator 协作机制** — 无 Materialize Conversion、无 trans.json、无 Plugin Pipeline，多 Calculator 场景要么 View Adaptation（不变 kind），要么手动重建
5. **Architecture Freeze 约束** — Package.swift / xcodeproj 不可修改，大量架构改进被延后到 v1.0+
