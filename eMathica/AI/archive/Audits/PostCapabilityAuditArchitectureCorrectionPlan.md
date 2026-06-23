# Post Capability Audit Architecture Correction Plan

> **日期:** 2026-06-16
> **模式:** 只读规划
> **输入:** Fine-Grained Capability Audit 全套 7 份文档 + 源码验证
> **原则:** 识别危险重复再谈拆分，设计冻结先于 package 化

---

## 1. Executive Summary

Fine-Grained Capability Audit 发现了约 140 个能力点，绘制了 19 个未来 Package 蓝图，但其中有 **过度拆分倾向**。

本次校正的核心结论：

1. **P0 只有一件事必须做：DocumentSystem 去重。** 不去重就谈拆分 MathCore 是本末倒置。
2. **P1 设计冻结先于实现。** `object-first kind`、统一的 `EMathicaDocument`、`trans.json`、跨计算器转换的 capability 命名 —— 这些规则不确定，后面拆什么都白拆。
3. **P2 MathCore 拆分是合理的长期目标，但不应急于。** CAS/GraphIntent/Sampling 三个子目录成熟度足够，但 Geometry 还掺杂着 App 端的 Plane 逻辑，应等 P1 设计冻结后再拆。
4. **P3 "Normalize First, Package Later"。** FormulaRenderKit / PreviewKit / MathInputKit 的原审计标注为 `ready to package` 是过早的。应在统一服务入口、消除内部重复后再 package 化。
5. **P4 其余 12 个包 (ObjectKit → PluginKit) 应为 Inventory Only。** 这些包的代码分散在 MathCore + WorkspaceKit 中，各自只有几十行到几百行，不构成独立 package 的体量。

---

## 2. Corrections to Original Capability Audit

### 2.1 原结论 vs 校正后

| Package | 原标注 | 校正后 | 原因 |
|---------|--------|--------|------|
| EMathicaCASCore | migration candidate | ✅ 保持 (P2) | 代码集中在 CASCore/ + AlgebraCore/，无跨模块耦合 |
| EMathicaGraphIntentCore | migration candidate | ✅ 保持 (P2) | 代码集中在 GraphCore/，分类逻辑独立 |
| EMathicaSamplingCore | migration candidate | ✅ 保持 (P2) | 代码集中在 SamplingCore/，采样器相互独立 |
| EMathicaGeometryCore | migration candidate | ⚠️ P2 (需等 P1) | 当前 GeometryKind 与 MathObjectType 耦合，且 Plane 端有重复类型定义 |
| EMathicaDocumentKit | already packaged + needs dedup | ✅ P0 | 确认有 6 个文件在 DocumentSystem 重复 |
| EMathicaFormulaRenderKit | ready to package | ❌ P3 (Normalize First) | 渲染分散在 3 处，无统一入口 |
| EMathicaMathInputKit | ready to package | ❌ P3 (Normalize First) | 外部 Package 存在但未在 Xcode 中采用 |
| EMathicaPreviewKit | ready to package | ❌ P3 (Normalize First) | Draft 和 Project preview 有采样逻辑重复 |
| EMathicaObjectKit | inventory only | ✅ 保持 (P4) | 代码量不足 (<200行等效)，等 object-first kind 冻结 |
| EMathicaDependencyKit | inventory only + empty shell | ✅ 保持 (P4) | DependencyGraph 为空占位符，等实现后再考虑 |
| EMathicaSelectionKit | inventory only | ✅ 保持 (P4) | Plane/Space hit-test 差异大，统一抽象收益待验证 |
| EMathicaInspectorKit | inventory only | ✅ 保持 (P4) | 当前作为 WorkspaceKit 子系统运行良好 |
| EMathicaPluginKit | inventory only + empty shell | ✅ 保持 (P4) | Protocol/Manifest 定义文件小，执行管线未实现 |
| EMathicaExportKit | empty shell recommended | ✅ 保持 (P4) | 仅有 preview.png 是基础 |
| EMathicaAnimationKit | inventory only + empty shell | ✅ 保持 (P4) | 仅有 parameter slider 播放 |
| EMathicaAssetKit | empty shell recommended | ✅ 保持 (P4) | 仅有 ProjectPackageStructure.assetsPath |

### 2.2 主要修正说明

**修正 A: FormulaRenderKit 降级 (ready to package → P3)**

三处渲染代码分散且无统一入口：
- `FeatureUtilities/Preview/LatexRenderService.swift` — `EMathicaMathRenderService` + `TextSubstitutionRenderService` 降级
- `SharedUI/Components/FormulaLabelPreviewView.swift` — `FormulaLabelPreviewView` 通过 `RenderServiceManager` 调用
- `WorkspaceKit/Keyboard/FormulaEditorView.swift` — 内联公式渲染（编辑+渲染双重职责）

三处均使用 `MathRenderer` 底层，但调用方式各不相同。在拆 package 之前应：
1. 统一 `FormulaRenderService` 协议定义
2. 所有渲染入口使用同一服务
3. 评估 `TextSubstitutionRenderService` 是否应提升为主策略而非降级

**修正 B: PreviewKit 降级 (ready to package → P3)**

Draft Preview 和 Project Preview 存在采样冗余：
- `PlaneDraftPreviewService` (530行) — 显式 700 samples, 参数 320 samples
- `ProjectPreviewRenderer` (927行) — 三级降级 (Geometry → Semantic → Legacy)
- Legacy 路径使用了 `PlaneLegacyExplicitSampling`，与 MathCore 的 `ExplicitFunctionSampler2D` 功能重叠

在拆 package 前应：
1. 废弃 `PlaneLegacyExplicitSampling`
2. Draft preview 和 Project preview 共享统一的采样路径
3. 统一 `PreviewSamplingStrategy` 协议

**修正 C: MathInputKit 降级 (ready to package → P3)**

`EMathicaMathInputKit` 是外部 Package (`/开发/eMathica/Packages/EMathicaMathInputKit/`)，但：
- 不在 Xcode `packageProductDependencies` 中
- 当前键盘/输入代码仍在 WorkspaceKit 内部（`Keyboard/`, `Input/`, `StructuredInput/`）
- WorkspaceKit 内有 ~10 个文件是 InputKit 候选迁移目标

应先：
1. 审计外部 Package 内容与 WorkspaceKit 内部代码的差异
2. 在 Xcode 中正式采用 `EMathicaMathInputKit`
3. 评估 WorkspaceKit 中可迁移的部分

---

## 3. Corrected Package Priority

```
P0 — Must Fix Before Further Package Work
├── DocumentSystem duplication (详细见 §4)
├── GeometryDefinition stale copy (详细见 §4.3)
├── Package source/reference consistency
└── .gitignore 确认（已完成 ✅）

P1 — Design Freeze Before Implementation
├── Object-first kind 规范冻结（详细见 §6）
├── 统一 EMathicaDocument（消除 primaryCalculator / enabledCalculators 歧义）
├── trans.json 格式 + 字段冻结（详细见 §10）
├── Object conversion capability 命名冻结
├── Document version migration 路径
└── WorkspaceKit → App Target 6 个类型依赖解决

P2 — Mature Package Candidates (Post P1)
├── EMathicaCASCore           (CASCore/ + AlgebraCore/ 已成熟)
├── EMathicaGraphIntentCore   (GraphCore/ 已成熟)
├── EMathicaSamplingCore      (SamplingCore/ 已成熟)
└── EMathicaGeometryCore      (需等 P1 几何类型定稿)

P3 — Normalize First, Package Later (Post P2)
├── EMathicaFormulaRenderKit  (先统一三入口)
├── EMathicaPreviewKit        (先消除 draft/project preview 重复)
└── EMathicaMathInputKit      (先在 Xcode 中正式采用)

P4 — Future Inventory Only (No Package Now)
├── EMathicaObjectKit
├── EMathicaDependencyKit
├── EMathicaSelectionKit
├── EMathicaInspectorKit
├── EMathicaExportKit
├── EMathicaAnimationKit
├── EMathicaAssetKit
└── EMathicaPluginKit
```

---

## 4. P0: DocumentSystem Deduplication Plan

### 4.1 重复验证

**DocumentSystem/ (App Target)** — 10 个文件：

| 文件 | 类型 | 与 Package 关系 |
|------|------|----------------|
| `EMathicaDocument.swift` | `struct` (internal) | ⚠️ 重复 — Package 有 `public struct` |
| `DocumentCommand.swift` | `enum` (internal) | ⚠️ 重复 — Package 有 `public enum` |
| `DocumentObjectPatch.swift` | `struct` (internal) | ⚠️ 重复 — Package 有 `public struct` |
| `ProjectMetadata.swift` | `struct` (internal) | ⚠️ 重复 — Package 有 `public struct` |
| `RecentProject.swift` | `struct` (internal) | ⚠️ 重复 — Package 有 `public struct` |
| `ProjectFileManagerPlaceholder.swift` | `enum` (internal) | ⚠️ 重复 — Package 有 `public enum` |
| `ProjectPackageStructure.swift` | `struct` (internal) | ⚠️ 重复 — Package 有 `public struct` |
| `IO/ProjectStore.swift` | `protocol` (internal) | ⚠️ 重复 — Package 有 `public protocol` |
| `IO/ProjectStoreError.swift` | `enum` (internal) | ⚠️ 重复 — Package 有 `public enum` |
| `Package/EMathicaPackageCodec.swift` | `enum` (internal) | ⚠️ 重复 — Package 有 `public enum` |
| `Package/EMathicaPackageLayout.swift` | `struct` (internal) | ⚠️ 重复 — Package 有 `public struct` |
| `GeometryDefinition.swift` | `enum`+`struct` (internal) | 🔴 严重 — 缺少 `.arc` case, 无 `Sendable` |
| `IO/LocalProjectStore.swift` | `struct` (唯一实现) | ✅ NOT 重复 — 唯一实现了 `ProjectStore` 协议 |

### 4.2 关键发现：LocalProjectStore 使用 EMathicaDocumentKit

`DocumentSystem/IO/LocalProjectStore.swift` 的开头：

```swift
import EMathicaDocumentKit  // ← 使用 Package 协议
import Foundation

struct LocalProjectStore: ProjectStore {  // ← 实现 Package 的 ProjectStore 协议
    // ...
    let previewRenderer: (EMathicaDocument) -> Data?  // ← 使用 Package 的类型
}
```

**22 个 App Target 文件** import `EMathicaDocumentKit`，说明实际运行时使用的是 Package 版本的类型。

### 4.3 GeometryDefinition Stale Copy 详细分析

**文件:** `DocumentSystem/GeometryDefinition.swift`

```swift
import EMathicaMathCore  // 导入 Package（有 public GeometryKind, GeometryAnchor, GeometryDefinition）
import Foundation

// 但在此文件中又定义了内部的同名类型：
enum GeometryKind: String, Codable, Equatable, Hashable {
    case point, segment, line, ray, circle,        // ← 缺少 .arc！
    case point3D, segment3D, line3D, plane3D
}

struct GeometryAnchor: Codable, Equatable, Hashable {
    // 与 Package 版本完全相同的内容
}

struct GeometryDefinition: Codable, Equatable, Hashable {
    var kind: GeometryKind       // ← 使用本地版本（缺少 .arc）
    var anchors: [GeometryAnchor] // ← 使用本地版本
    // 缺少 point3D, pointB3D, vector3D 等 Package 版本的新字段
}
```

**Package 版本对比:**
```swift
public enum GeometryKind: String, Codable, Equatable, Hashable, Sendable {
    case point, segment, line, ray, circle, arc,  // ← 有 .arc！
    case point3D, segment3D, line3D, plane3D
}

public struct GeometryDefinition: Codable, Equatable, Hashable, Sendable {
    public var kind: GeometryKind
    public var anchors: [GeometryAnchor]
    public var point3D: WorldPoint3D?    // ← DocumentSystem 版本没有
    public var pointB3D: WorldPoint3D?   // ← DocumentSystem 版本没有
    public var vector3D: Vector3D?       // ← DocumentSystem 版本没有
}
```

**差异总结:**
| 维度 | DocumentSystem 版本 | Package 版本 |
|------|---------------------|-------------|
| `GeometryKind` cases | 9 (缺少 `arc`) | 10 (有 `arc`) |
| `Sendable` 遵循 | 无 | 有 |
| `GeometryDefinition` 字段 | 2 (kind, anchors) | 5 (+point3D, +pointB3D, +vector3D) |
| Access level | internal | public |
| 是否最新 | ❌ 陈旧 | ✅ 权威 |

**引用分析:** `DocumentSystem/DocumentObjectPatch.swift` 中的 `geometryDefinition: GeometryDefinition?` 字段使用了本地版本。但由于同一编译单元同时导入了 `EMathicaMathCore`（提供 `public GeometryDefinition`），存在类型歧义风险。

### 4.4 去重优先级

| 优先级 | 文件 | 操作 | 风险 |
|--------|------|------|------|
| 🔴 P0-A | `GeometryDefinition.swift` | **删除** — 移除本地副本，确认所有引用走 Package | 中 — 需确认无引用本地 `GeometryKind` 的代码 |
| 🟡 P0-B | IO/重复文件 (`ProjectStore.swift`, `ProjectStoreError.swift`) | **删除** — 协议/错误类型从 Package 导入 | 低 — `LocalProjectStore` 已经 import EMathicaDocumentKit |
| 🟡 P0-C | Package/重复文件 (`EMathicaPackageCodec.swift`, `EMathicaPackageLayout.swift`) | **删除** — 编解码从 Package 导入 | 低 — 纯工具类，无状态 |
| 🟡 P0-D | 7 个数据模型重复 (`EMathicaDocument.swift`, `DocumentCommand.swift`, `DocumentObjectPatch.swift`, `ProjectMetadata.swift`, `RecentProject.swift`, `ProjectFileManagerPlaceholder.swift`, `ProjectPackageStructure.swift`) | **评估** — 确认仅 access modifier 差异后删除 | 中 — 需确认无 internal 特有逻辑 |

### 4.5 Stop Condition

**必须停止的情况:**
- 任何删除操作前，必须通过 `grep` 确认该文件中的类型未被其他 App Target 文件通过 `internal` 访问使用（而非通过 `import EMathicaDocumentKit` 使用 package 版本）
- 如果某个本地副本包含 package 版本没有的唯一逻辑，则不能删除
- 如果删除导致 Xcode 编译失败（由于 `fileSystemSynchronizedGroups` 自动发现），需要回滚

> ⚠️ **本轮不执行删除。** 本报告只提供方案。删除操作应在独立的低风险执行任务中完成。

---

## 5. P1: Object-First Design Freeze Plan

### 5.1 当前状态

当前 `MathObjectType` 是一个扁平枚举，在 `Packages/EMathicaMathCore/Sources/EMathicaMathCore/MathObjectType.swift`:

```swift
public enum MathObjectType: String, Codable, CaseIterable {
    case function, point, circle, segment, line, ray, parameter, parameterGroup, arc
}
```

这个枚举混合了几种不同的分类维度：
- 几何实体: `point`, `circle`, `segment`, `line`, `ray`, `arc`
- 函数/代数: `function`
- UI 交互: `parameter`, `parameterGroup`

它既不是 object-first（没有区分 2D/3D），也不是 calculator-first（没有 `plane.point`），而是一种过渡状态。

### 5.2 冻结内容

以下设计问题必须在进一步 package 化之前解答并冻结：

| 问题 | 影响 | 建议 |
|------|------|------|
| Object kind 命名规则 | 影响 GeometryCore、DocumentKit API | 采用 `domain.entity.dimension` 格式（如 `point.2d`） |
| 如何兼容当前 `MathObjectType` | 影响已有文档的向后兼容 | 新字段 `kind: String`，保留 `type: MathObjectType` 作为兼容，但标记 deprecated |
| `createdBy` / `preferredViews` / `enabledCalculators` / `primaryCalculator` 定义 | 影响跨计算器对象使用 | 冻结为 DocumentObjectKindProposal.md 中描述的 4 字段模型 |
| 当前 9 个 MathObjectType 到新 object kind 映射 | 影响版本迁移 | 冻结映射规则：`.point → point.2d`, `.function → curve.explicit2d` 等 |
| 何时开始使用新 kind 写入文档 | 影响 document.json 格式 | 建议 Plane v1.0 后，新文档使用新 kind，旧文档通过 version migration 升级 |

### 5.3 不立即做的事

- 不修改 `MathObjectType` 枚举
- 不重构所有引用 `MathObjectType` 的代码
- 不创建 EMathicaObjectKit

### 5.4 冻结后的文档

冻结后的设计应产生：
1. 一份 `AI/Design/ObjectKindSpec.md` — 最终的 kind 命名规范
2. 一份 `AI/Design/VersionMigrationSpec.md` — version migration 路径
3. `DocumentObjectKindProposal.md` 作为设计讨论的历史记录保留

---

## 6. P2: MathCore Split Candidate Plan

### 6.1 CASCore — ✅ 成熟度足够

**位置:** `Packages/EMathicaMathCore/Sources/EMathicaMathCore/CASCore/` + `AlgebraCore/`

**分析:**
- 10 个文件，全部为纯函数/纯类型
- 无 UI 依赖，无 Plane/Space 特定逻辑
- 唯一的跨文件引用是 `Expr`（在 `SemanticCore/` 中），作为输入/输出

**拆分可行性:** ✅ 高。仅需保留 MathCore 依赖（Expr, Symbol, Relation 等基础类型）。

### 6.2 GraphIntentCore — ✅ 成熟度足够

**位置:** `Packages/EMathicaMathCore/Sources/EMathicaMathCore/GraphCore/`

**分析:**
- 6 个文件：GraphClassifier, GraphIntent, ConicInfo, GraphClassificationResult, ParameterRange, DebugPrinter
- 无 UI 依赖，纯分类逻辑
- 输入 `Expr`（来自 SemanticCore），输出 `AlgebraClassification`

**拆分可行性:** ✅ 高。依赖 MathCore 的基础类型。

### 6.3 SamplingCore — ✅ 成熟度足够

**位置:** `Packages/EMathicaMathCore/Sources/EMathicaMathCore/SamplingCore/`

**分析:**
- 17 个文件，8 种采样器 + 质量策略 + 段缝合
- 无 UI 依赖，纯数学算法
- 输入 `Expr` + `ParameterRange`，输出 `[PlotSegment]`

**拆分可行性:** ✅ 高。但需等 Plane 端废弃 `PlaneLegacyExplicitSampling`，确保所有采样路径统一走 MathCore 采样器。

### 6.4 GeometryCore — ⚠️ 需等 P1 冻结

**位置:** `Packages/EMathicaMathCore/Sources/EMathicaMathCore/GeometryDefinition.swift` + `Coordinate/` + `SpaceMathCore/`

**分析:**
- `GeometryDefinition.swift` 定义了 `GeometryKind`, `GeometryAnchor`, `GeometryDefinition`, `GeometryDependency`, `GeometryDependencyKind`, `GeometryDefinitionStatus`, `DeletedObjectRecord` — 共 7 个类型
- 这些类型当前与 `MathObjectType`（`point`, `segment` 等）并行存在，没有明确的 kind 分发规则
- `Coordinate/` 定义了 `WorldPoint`, `WorldPoint3D` 等基本坐标类型
- `SpaceMathCore/SpaceMath3D.swift` 定义了 3D 几何类型

**拆分可行性:** ⚠️ 需要对象 kind 规范冻结后才能确定边界。当前 `GeometryKind` 与 `MathObjectType` 部分重叠。

### 6.5 不拆的内容

`SemanticCore/`（Expr, Symbol, Relation, Piecewise, Matrix）是 MathCore 的基础依赖，所有其他子包都依赖它。拆成独立包不合理 — 它们应该留在 EMathicaMathCore 作为核心类型定义。

---

## 7. P3: Normalize-First Package Candidates

### 7.1 FormulaRenderKit

**当前状态:** 渲染分散在三处，无统一入口。

| 位置 | 职责 | 行数 |
|------|------|------|
| `FeatureUtilities/Preview/LatexRenderService.swift` | LaTeX → Image，含降级策略 | 213行 |
| `SharedUI/Components/FormulaLabelPreviewView.swift` | Formula label 异步预览 View | 96行 |
| `WorkspaceKit/Keyboard/FormulaEditorView.swift` | 内联公式渲染 + 编辑 | 783行 (包含编辑逻辑) |

**Normalize First 步骤:**

1. 在 MathCore 或新建共享层定义 `FormulaRenderService` 协议：
   ```swift
   public protocol FormulaRenderService {
       func render(latex: String, fontSize: CGFloat) -> Image?
       func renderFallback(latex: String) -> String
   }
   ```

2. `LatexRenderService.swift` 的 `EMathicaMathRenderService` 作为实现
3. `FormulaLabelPreviewView` 和 `FormulaEditorView` 的渲染部分改为调用协议
4. 统一后评估是否值得拆成独立 Package

### 7.2 PreviewKit

**当前状态:** 两个 Preview 服务各自独立采样。

**Normalize First 步骤:**

1. 废弃 `PlaneLegacyExplicitSampling`
2. 在 `ProjectPreviewRenderer` 中移除 Legacy 回退路径，改为直接使用 MathCore 采样器
3. 提取公共的 `PreviewSamplingStrategy`：
   - Draft: `QualityProfile.draft` (低密度)
   - Project: `QualityProfile.preview` (中密度)
   - Export: `QualityProfile.precise` (高密度，future)
4. 统一后评估是否值得拆成独立 Package

### 7.3 MathInputKit

**当前状态:** 外部 Package 存在但未被 Xcode 正式采用。

**Normalize First 步骤:**

1. 审计 `/开发/eMathica/Packages/EMathicaMathInputKit/Sources/` 内容
2. 对比 WorkspaceKit 中的 `Keyboard/` + `Input/` + `StructuredInput/` 文件
3. 确认哪些 WorkspaceKit 文件应该迁移到 MathInputKit
4. 在 Xcode `packageProductDependencies` 中正式采用

---

## 8. P4: Future Inventory-Only Packages

以下 8 个包当前不应创建，仅作为能力登记：

| Package | 当前代码位置 | 体量 | 何时考虑 |
|---------|------------|------|---------|
| EMathicaObjectKit | MathObject.swift + MathObjectType.swift | ~300行 | Object-first kind 冻结后 |
| EMathicaDependencyKit | GeometryDefinition.swift 的 dependency 类型 | ~200行 | DependencyGraph 实现后 |
| EMathicaSelectionKit | PlaneHitTestService (476行) + SpaceHitTestService | ~600行 | 统一 hit-test 抽象后 |
| EMathicaInspectorKit | ObjectInspectorPanel (577行) + property presenters | ~700行 | Inspector 子系统稳定后 |
| EMathicaExportKit | 无 | 0行 | 首个 export 能力实现后 |
| EMathicaAnimationKit | AlgebraObjectPanelView 的 slider 播放部分 | ~50行 | Timeline/Keyframe 实现后 |
| EMathicaAssetKit | ProjectPackageStructure.assetsPath | ~1行 | Plugin asset 需求明确后 |
| EMathicaPluginKit | PluginSystem/ (5 files) | ~50行 | Capability Registry 启动后 |

---

## 9. Plane-Centric to Document-Centric Transition Plan

### 9.1 Current Reality

当前架构是 **Plane-centric**:
```
Plane Calculator (CalculatorModules/Plane/, ~35 files)
  ├── 直接调用 MathCore 的采样器/CAS/GraphIntent
  ├── 拥有自己的 PlaneGeometryResolver, PlaneHitTestService, PlaneDraftPreviewService
  └── 通过 PlaneWorkspaceModuleProvider 注册到 WorkspaceKit

Space Calculator (CalculatorModules/Space/, ~8 files)  
  └── 独立实现了 SpaceGeometryResolver, SpaceHitTestService, SpaceWireframeRenderer
```

### 9.2 Target Architecture

目标架构是 **document-centric**:
```
EMathicaDocument（统一文档）
  ├── objects: [MathObject]  ← object-first kind
  ├── primaryCalculator: "plane" | "space" | "music" ...
  └── enabledCalculators: ["plane", "space", "data"]

Calculator 作为 view/interaction adapter：
  PlaneCalculator
    ├── imports EMathicaDocumentKit（not the other way around）
    ├── adapter: PlaneGeometryAdapter（implements GeometryService protocol）
    ├── adapter: PlanePreviewAdapter（implements PreviewService protocol）
    └── adapter: PlaneHitTestAdapter（implements HitTestService protocol）

  SpaceCalculator
    ├── imports EMathicaDocumentKit
    └── adapter: SpaceGeometryAdapter, SpaceHitTestAdapter, SpacePreviewAdapter
```

### 9.3 Transition Steps

**Step 1: 识别 Plane 专属能力**

当前 Plane 专属的 35 个文件中有以下能力是通用候选：

| Plane 文件 | 可抽象为 |
|-----------|---------|
| `PlaneGeometryResolver.swift` | `GeometryService` 协议 |
| `PlaneHitTestService.swift` | `HitTestService` 协议 |
| `PlaneDraftPreviewService.swift` | `DraftPreviewService` 协议 |
| `PlaneIntersectionSolver.swift` | `IntersectionService` 协议 |
| `PlaneLineClipping.swift` | `LineClippingService` (通用 2D 裁剪) |
| `PlaneConstructionMode.swift` | 保留为 Plane adapter（构建模式是交互特有的） |

**Step 2: 协议定义位置**

通用协议定义在 Package 中，Plane/Space Adapter 保留在 CalculatorModules 中：

```
EMathicaDocumentKit (or EMathicaWorkspaceKit)
  └── Protocols/
      ├── GeometryService.swift         ← 通用几何求解协议
      ├── HitTestService.swift          ← 通用命中测试协议
      └── DraftPreviewService.swift     ← 通用草稿预览协议

CalculatorModules/Plane/Services/
  ├── PlaneGeometryResolver.swift       ← 实现 GeometryService
  ├── PlaneHitTestService.swift         ← 实现 HitTestService
  └── PlaneDraftPreviewService.swift    ← 实现 DraftPreviewService

CalculatorModules/Space/Services/
  ├── SpaceGeometryResolver.swift       ← 实现 GeometryService
  └── SpaceHitTestService.swift         ← 实现 HitTestService
```

**Step 3: 保持 Plane adapter 的内容**

以下能力是交互特有的，不应抽象：
- `PlaneConstructionMode`（21 个交互状态）— 构建模式是 Plane 特有的
- `PlaneToolIDs` / `SpaceToolIDs` — 工具 ID 是计算器特有的
- `PlaneCanvasView` / `SpaceCanvasView` — 画布渲染是计算器特有的
- `PlaneInteractionState` / `PlaneInteractionReducer` — 交互逻辑是计算器特有的

### 9.4 Space/Data/Music/Notes 未来如何复用

| Calculator | 复用能力 | 新能力 |
|-----------|---------|--------|
| Space | CAS, GraphIntent (3D 分类), Sampling (3D), Geometry (3D) | 3D hit-test, wireframe rendering, camera |
| Data | CAS, Sampling, Geometry | Table generation, statistics, chart rendering |
| Music | Sampling (high-density for audio) | Audio wave generation, playback |
| Notes | FormulaRender (LaTeX), MathInput (keyboard) | Rich text, markdown, LaTeX embedding |

---

## 10. Object Conversion and trans.json Strategy

### 10.1 Materialize Conversion 原则确认

ObjectConversionProposal.md 中描述的原则确认正确，无需修正：

- 用户编辑导致数学语义变化 → materialize conversion (kind 改变)
- 仅改变视图方式 → view adaptation (kind 不变)

### 10.2 trans.json ≠ DependencyGraph

重要澄清：

| | trans.json | DependencyGraph |
|---|-----------|----------------|
| 记录维度 | **时间** — 转换历史 | **空间** — 对象间依赖关系 |
| 数据来源 | 用户操作 | 对象创建时的依赖声明 |
| 用途 | 溯源、undo、跨计算器一致性 | 级联重算、删除策略、循环检测 |
| 当前状态 | planned | DependencyGraph 为空占位符 |

两者互补但不混淆。不要试图在 trans.json 中存储依赖图，反之亦然。

### 10.3 第一批 Conversion — 只做 point.2d ↔ point.3d

ObjectConversionProposal.md 建议了 6 种转换。校正后推荐第一批只实现最简单的一对：

| Conversion | 优先级 | 原因 |
|-----------|--------|------|
| `point.2d → point.3d` | P2 | 最简单、可验证材料化转换的完整 pipeline |
| `point.3d → point.2d` | P2 | 反向转换，可验证信息丢失警告 |
| `curve → wave` | P4 | 需要 Music calculator 存在才有意义 |
| `curve → table` | P4 | 需要 Data calculator 存在才有意义 |
| `surface → contour` | P4 | 需要完整的 Space 3D pipeline |
| `table → pointSet` | P4 | 需要 Data calculator |

### 10.4 trans.json 实现路径

1. 不立即修改 `EMathicaPackageLayout`
2. 先在 AI/ 中完成 trans.json schema 定稿
3. Plane v1.0 后在 `LocalProjectStore` 中添加 trans.json 读写
4. 实现后验证 `point.2d → point.3d` 的完整 pipeline

---

## 11. Plugin Capability Registry Strategy

### 11.1 CapabilityRegistryDraft.json 确认

CapabilityRegistryDraft.json 中的 68 个能力条目确认正确。主要结构（id, domain, status, currentLocations, futurePackage, pluginExposure, blockCandidate）均合理。

### 11.2 不立即实现 Scratch UI

PluginCapabilityExposurePolicy.md 中描述的 Scratch 式插件系统是长期愿景。当前优先级：
1. **Capability Registry 格式稳定** — 确保 id 命名、exposure 分类、input/output 描述规范
2. **Exposure 等级规则** — safe/restricted/internal/blocked 的边界需要更多讨论
3. **不实现 Plugin Block 编排** — 等 Capability Registry 达到 ~100 entry 规模再考虑
4. **不实现 Scratch UI** — 依赖整个 rendering pipeline 成熟

### 11.3 暴露规则确认

| 等级 | 判断标准 | 确认正确 |
|------|---------|---------|
| 🟢 safe | 纯计算，无副作用 | ✅ |
| 🟡 restricted | 修改文档状态或触发 IO | ✅ |
| 🔵 internal | 系统基础设施 | ✅ 但不建议在 PluginKit 中暴露这些能力 ID |
| 🔴 blocked | 绝对禁止 | ✅ |

---

## 12. Recommended Next Task Sequence

```
Phase 0 (当前已完成):
  ✅ Fine-Grained Capability Audit
  ✅ Post Capability Audit Architecture Correction Plan
  ✅ .gitignore

Phase 1 (P0 — 建议立即规划):
  📋 "DocumentSystem Dedup Execution"
     - 验证 GeometryDefinition.swift 本地副本无引用
     - 验证 IO/Package 重复文件可安全删除
     - 验证 7 个数据模型文件仅 access modifier 差异
     - 执行删除 + 构建验证
     - ⚠️ 此任务需要修改源文件，不属于 Architecture Freeze 禁改范围（Docs 文件，非 pbxproj/Package.swift）

Phase 2 (P1 — 建议作为下一个设计任务):
  📋 "Object-First Kind + EMathicaDocument Design Freeze"
     - 在 AI/Design/ 中冻结设计文档
     - 不修改源码

Phase 3 (P2 — Plane v1.0+):
  📋 "MathCore Split: CASCore + GraphIntentCore + SamplingCore"
     - 从 MathCore 提取三个子包
     - 更新 Package.swift
     - 更新所有 import 路径
     - ⚠️ 涉及 Package.swift 修改，Architecture Freeze 期间禁止

Phase 4 (P3 — Post-v1.0):
  📋 "FormulaRender + Preview + MathInput Normalize"
     - 统一渲染/预览服务入口
     - 废弃 Legacy sampling

Phase 5 (P4 — Long-term):
  📋 其余 8 个包，视需求逐渐创建
```

---

## 13. Stop Conditions

如果发现以下情况，**必须在报告中标注并停止提出执行级建议**:

| 情况 | 当前状态 | 处理 |
|------|---------|------|
| GeometryDefinition 本地副本被其他 App Target 文件通过 `internal` 访问而无法通过 `import EMathicaMathCore` 替代 | ⚠️ 需验证 — DocumentObjectPatch 引用了本地 `GeometryDefinition` | Phase 1 前必须 grep 确认 |
| 外部 Package 源码不在仓库中 | ⚠️ EMathicaMathInputKit 在 `/开发/eMathica/Packages/` 但未在 Xcode 中采用 | 标记为 Needs verification |
| 跨 package 依赖关系不清楚 | ⚠️ WorkspaceKit 有 6 个 App Target 类型依赖 | Phase 1 后需确认 |
| 需要修改 xcodeproj 或 Package.swift | 🔴 Architecture Freeze 期间禁止 | Phase 3-4 推迟至 v1.0+ |
| 需要运行构建但当前环境无法运行 | ⚠️ 已知 sandbox 权限问题 | 执行 Phase 1 时需确认构建环境 |

---

## 附录: 当前 Package 依赖关系图

```
EMathicaMathCore (zero deps)
  ↑
EMathicaDocumentKit
  ↑
EMathicaWorkspaceKit
  ↑
EMathicaThemeKit ──→ (zero deps)
  ↑
EMathicaMathInputKit ──→ (zero deps, external, not adopted)

App Target "eMathica"
  ├── imports EMathicaMathCore
  ├── imports EMathicaDocumentKit (22 files)
  ├── imports EMathicaWorkspaceKit
  ├── imports EMathicaThemeKit
  ├── DocumentSystem/ (⚠️ 重复了 EMathicaDocumentKit 的类型定义)
  └── CalculatorModules/ (Plane 35 + Space 8)
```
