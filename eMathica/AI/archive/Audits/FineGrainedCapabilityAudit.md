# Fine-Grained Capability Audit

> **日期:** 2026-06-16
> **模式:** 只读审计
> **原则:** Package 按能力拆分，不按 UI 层级拆分

---

## 1. Capability Overview

审计发现的已存在能力总数：**~140 existing/partial**, **~45 planned**

### 能力域分布

| Domain | Existing | Partial | Planned | Total |
|--------|----------|---------|---------|-------|
| Math Expression | 8 | 2 | 3 | 13 |
| CAS / Algebra | 5 | 3 | 3 | 11 |
| Graph Intent | 7 | 0 | 2 | 9 |
| Sampling | 7 | 1 | 1 | 9 |
| Geometry | 7 | 1 | 3 | 11 |
| Object System | 6 | 1 | 3 | 10 |
| Dependency System | 3 | 2 | 2 | 7 |
| Document System | 5 | 2 | 3 | 10 |
| Math Input / Keyboard | 7 | 2 | 1 | 10 |
| Formula Rendering | 4 | 2 | 1 | 7 |
| Preview / Thumbnail | 4 | 0 | 1 | 5 |
| Workspace | 4 | 1 | 1 | 6 |
| Command System | 4 | 1 | 1 | 6 |
| Tool System | 5 | 0 | 1 | 6 |
| Selection / HitTest | 4 | 1 | 1 | 6 |
| Inspector | 3 | 1 | 1 | 5 |
| Style / Theme | 5 | 0 | 1 | 6 |
| Asset | 1 | 0 | 5 | 6 |
| Export | 0 | 0 | 7 | 7 |
| Animation | 1 | 0 | 4 | 5 |
| Plugin | 2 | 1 | 4 | 7 |
| Calculator Modules | 6 | 1 | 2 | 9 |

---

## 2. Per-Domain Detailed Audit

### 2.1 Math Expression

| Capability | Status | Location | Reuse Targets | Duplicate? | Future Package |
|------------|--------|----------|---------------|------------|----------------|
| `expr.ast.define` | existing | `Packages/EMathicaMathCore/SemanticCore/Expr.swift` | All | No | EMathicaMathCore |
| `expr.symbol.define` | existing | Same file | All | No | EMathicaMathCore |
| `expr.relation.define` | existing | Same file | CAS, Sampling | No | EMathicaMathCore |
| `expr.piecewise.define` | existing | Same file | GraphIntent, Sampling | No | EMathicaMathCore |
| `expr.matrix.define` | existing | MathCore root | — | No | EMathicaMathCore |
| `expr.serialize.json` | existing | Codable conformance across MathCore types | DocumentSystem, IO | No | EMathicaMathCore |
| `expr.parse.latex` | existing | WorkspaceKit/StructuredInput/ | Keyboard, Input | No | EMathicaMathInputKit |
| `expr.format.latex` | existing | WorkspaceKit/Keyboard/FormulaEditorView | Inspector, ObjectPanel | No | EMathicaFormulaRenderKit |
| `expr.parse.source` | partial | WorkspaceKit/Protocols/DefaultInputCanonicalizer | Input bar | No | EMathicaMathInputKit |
| `expr.format.source` | partial | WorkspaceKit/Keyboard/FormulaEditorView | Export | No | EMathicaMathInputKit |
| `expr.semantic.lower` | existing | WorkspaceKit/StructuredInput/MathNodeSemanticLowering | Draft, Preview | No | EMathicaMathInputKit |
| `expr.diagnostic.analyze` | existing | WorkspaceKit/StructuredInput/FormulaDiagnosticPresenter | Draft | No | EMathicaMathInputKit |
| `expr.semantic.state` | existing | WorkspaceKit/StructuredInput/FormulaSemanticState | Draft | No | EMathicaMathInputKit |

**高风险重复:** 无。SemanticCore 是唯一数学表达式的权威来源。

**缺失能力:**
- `expr.parse.mathml` (planned)
- `expr.format.mathml` (planned)
- `expr.symbolic.differentiate` (exists in CAS domain)

---

### 2.2 CAS / Algebra

| Capability | Status | Location | Reuse Targets | Duplicate? | Future Package |
|------------|--------|----------|---------------|------------|----------------|
| `cas.normalize` | existing | `Packages/EMathicaMathCore/CASCore/` | All evaluators | No | EMathicaCASCore |
| `cas.simplify` | existing | Same | Inspector, Export | No | EMathicaCASCore |
| `cas.canonicalize` | existing | `CASCore/Canonicalizer.swift` | GraphIntent, Sampling | No | EMathicaCASCore |
| `cas.expand.polynomial` | existing | `AlgebraCore/PolynomialExpander.swift` | Inspector, Export | No | EMathicaCASCore |
| `cas.differentiate` | existing | CASCore | PlaneCommandHandler, WorkspaceObjectRowView | No | EMathicaCASCore |
| `cas.solve.equation` | partial | CASCore/EquationSolver | Inspector, CAS panel | No | EMathicaCASCore |
| `cas.extract.quadratic` | existing | CASCore/Canonicalizer | GraphIntent | No | EMathicaCASCore |
| `cas.extract.conic` | existing | CASCore | GraphIntent, Sampling | No | EMathicaCASCore |
| `cas.factor` | planned | — | Inspector, Export | No | EMathicaCASCore |
| `cas.integrate` | planned | — | Inspector, Export | No | EMathicaCASCore |
| `cas.limit` | planned | — | Inspector | No | EMathicaCASCore |

**高风险重复:** 无。CAS 代码集中在 EMathicaMathCore 下。

**缺失能力:**
- `cas.factor` (planned)
- `cas.integrate` (planned)
- `cas.limit` (planned)

---

### 2.3 Graph Intent

| Capability | Status | Location | Reuse Targets | Duplicate? | Future Package |
|------------|--------|----------|---------------|------------|----------------|
| `graph.classify.explicitY` | existing | `MathCore/GraphCore/GraphClassifier` | Sampling, Preview | No | EMathicaGraphIntentCore |
| `graph.classify.explicitX` | existing | Same | Sampling | No | EMathicaGraphIntentCore |
| `graph.classify.implicit2D` | existing | Same | Sampling | No | EMathicaGraphIntentCore |
| `graph.classify.parametric2D` | existing | Same | Sampling | No | EMathicaGraphIntentCore |
| `graph.classify.polar2D` | existing | Same | Sampling | No | EMathicaGraphIntentCore |
| `graph.classify.conic` | existing | Same | Sampling, Geometry | No | EMathicaGraphIntentCore |
| `graph.classify.piecewise` | existing | Same | Sampling | No | EMathicaGraphIntentCore |
| `graph.classify.parametric3D` | planned | — | Space | No | EMathicaGraphIntentCore |
| `graph.classify.implicit3D` | planned | — | Space | No | EMathicaGraphIntentCore |

**高风险重复:** 无。GraphClassifier 是单点。PlaneDraftPreviewService 中的 `AlgebraClassification` 使用了 CAS 规范化结果，但不是 GraphIntent 的重复实现。

**缺失能力:**
- `graph.classify.parametric3D` (planned)
- `graph.classify.implicit3D` (planned)

---

### 2.4 Sampling

| Capability | Status | Location | Reuse Targets | Duplicate? | Future Package |
|------------|--------|----------|---------------|------------|----------------|
| `graph.sample.explicit2D` | existing | `MathCore/SamplingCore/ExplicitFunctionSampler2D` | Preview, Canvas, Draft | No | EMathicaSamplingCore |
| `graph.sample.implicit2D` | existing | `MathCore/SamplingCore/ImplicitCurveSampler2D` | Preview, Canvas | No | EMathicaSamplingCore |
| `graph.sample.parametric2D` | existing | `MathCore/SamplingCore/ParametricCurveSampler2D` | Preview, Canvas | No | EMathicaSamplingCore |
| `graph.sample.polar2D` | existing | `MathCore/SamplingCore/PolarCurveSampler2D` | Preview, Canvas | No | EMathicaSamplingCore |
| `graph.sample.conic` | existing | `MathCore/SamplingCore/ConicSampler2D` | Preview, Canvas | No | EMathicaSamplingCore |
| `graph.sample.stitch` | existing | `MathCore/SamplingCore/SegmentStitcher2D` | Preview, Canvas | No | EMathicaSamplingCore |
| `graph.sample.detectDiscontinuity` | existing | Samplers (maxAbsCoordinate guard) | Preview, Canvas | No | EMathicaSamplingCore |
| `graph.sample.qualityProfile` | existing | `Plane/Services/` (quality profiles) | Preview, Canvas, Draft | No | EMathicaSamplingCore |
| `graph.sample.parametric3D` | planned | — | Space | No | EMathicaSamplingCore |

**高风险重复:** ⚠️ `PlaneLegacyExplicitSampling` in Plane/Services vs `ExplicitFunctionSampler2D` in MathCore。Legacy sampler 使用简单的极简采样策略（700 samples for explicit），而 MathCore sampler 有更高级的 adaptive/discontinuity 逻辑。Legacy sampler 被用作 Draft Preview 的回退，被 PreviewRenderer 的代数回退策略使用。**建议:** 统一使用 MathCore sampler，废弃 Legacy sampler。

**缺失能力:**
- `graph.sample.parametric3D` (planned)

---

### 2.5 Geometry

| Capability | Status | Location | Reuse Targets | Duplicate? | Future Package |
|------------|--------|----------|---------------|------------|----------------|
| `geometry.point.2d` | existing | `MathCore/GeometryDefinition.swift` | Plane | No | EMathicaGeometryCore |
| `geometry.line.2d` | existing | Same | Plane | No | EMathicaGeometryCore |
| `geometry.ray.2d` | existing | Same | Plane | No | EMathicaGeometryCore |
| `geometry.segment.2d` | existing | Same | Plane | No | EMathicaGeometryCore |
| `geometry.circle.2d` | existing | Same | Plane | No | EMathicaGeometryCore |
| `geometry.arc.2d` | existing | Same (MathCore version only) | Plane | No | EMathicaGeometryCore |
| `geometry.point.3d` | existing | `MathCore/SpaceMathCore/` | Space | No | EMathicaGeometryCore |
| `geometry.intersection` | existing | `PlaneGeometryResolver` + `GeometryDependencyKind.intersectionOf` | Plane, Space | No | EMathicaGeometryCore |
| `geometry.distance` | partial | HitTest uses point-segment/circle distance | Inspector, HitTest | No | EMathicaGeometryCore |
| `geometry.projection` | planned | — | Space | No | EMathicaGeometryCore |
| `geometry.transform` | planned | — | Plane, Space | No | EMathicaGeometryCore |
| `geometry.convert.2dTo3d` | planned | — | Space | No | EMathicaGeometryCore |
| `geometry.convert.3dTo2d` | planned | — | Plane | No | EMathicaGeometryCore |

**高风险重复:** ⚠️ `GeometryDefinition.swift` 存在于两个位置：
- `Packages/EMathicaMathCore/Sources/EMathicaMathCore/GeometryDefinition.swift` (权威版本，含 `arc`)
- `DocumentSystem/GeometryDefinition.swift` (旧副本，缺少 `arc`，internal)
DocumentSystem 导入 EMathicaMathCore，应删除其本地副本。

**缺失能力:**
- `geometry.projection` (planned)
- `geometry.transform` (planned)
- `geometry.convert.2dTo3d` (planned)
- `geometry.convert.3dTo2d` (planned)

---

### 2.6 Object System

| Capability | Status | Location | Reuse Targets | Duplicate? | Future Package |
|------------|--------|----------|---------------|------------|----------------|
| `object.identity.uuid` | existing | `MathObject.id: UUID` (let, immutable) | All | No | EMathicaObjectKit |
| `object.kind.define` | existing | `MathObjectType` enum | All | No | EMathicaObjectKit |
| `object.name.assign` | existing | `MathObject.name: String` | ObjectPanel, Inspector | No | EMathicaObjectKit |
| `object.style.apply` | existing | `MathStyle` on MathObject | Canvas, Inspector, ObjectPanel | No | EMathicaObjectKit |
| `object.metadata.store` | existing | MathObject fields | Inspector | No | EMathicaObjectKit |
| `object.dependency.attach` | existing | `MathObject.geometryDependency` | Plane, Space | No | EMathicaDependencyKit |
| `object.serialize.json` | existing | Codable on MathObject | DocumentSystem | No | EMathicaObjectKit |
| `object.convert.kind` | planned | — | Space, Modeling | No | EMathicaObjectKit |
| `object.thumbnail.contribute` | existing | ProjectPreviewRenderer.drawObjects | CoreHome | No | EMathicaObjectKit |
| `object.naming.sequential` | existing | `WorkspaceObjectNamingServiceProtocol` | PlaneCommandHandler | No | EMathicaObjectKit |

**高风险重复:** 无。MathObject 在 EMathicaMathCore 中是单一定义。但 Object Naming 存在 Path 1 (count-based in WorkspaceState) vs Path 2 (nextFunctionName in PlaneCommandHandler) 的双路径问题。

**缺失能力:**
- `object.convert.kind` (planned)
- `object.version.migrate` (planned)
- `object.validation.schema` (planned)

---

### 2.7 Dependency System

| Capability | Status | Location | Reuse Targets | Duplicate? | Future Package |
|------------|--------|----------|---------------|------------|----------------|
| `dependency.edge.create` | existing | `GeometryDependency` / `GeometryDependencyKind` | Plane, Space | No | EMathicaDependencyKit |
| `dependency.resolve` | partial | `PlaneGeometryResolver` resolves for Plane | Space, Inspector | No | EMathicaDependencyKit |
| `dependency.recompute` | partial | `PlaneObjectRendererView` re-renders on dependency change | Canvas | No | EMathicaDependencyKit |
| `dependency.graph.detectCycle` | planned | `DependencyGraph` (empty placeholder in MathCore) | All | No | EMathicaDependencyKit |
| `dependency.delete.sourcePolicy` | existing | `DeleteSourceObjectDependencyPolicy` (unlink vs deleteAffected) | All | No | EMathicaDependencyKit |
| `dependency.orphan.recover` | planned | — | All | No | EMathicaDependencyKit |
| `dependency.persistence` | existing | Codable on GeometryDependency, stored in document.json | DocumentSystem | No | EMathicaDependencyKit |

**高风险重复:** 无。但 `DependencyGraph` 是空占位符，循环检测未实现。删除源对象策略有两个路径（unlink/deleteAffected）但未正式冻结。

**缺失能力:**
- `dependency.graph.detectCycle` (planned — DependencyGraph 占位符)
- `dependency.orphan.recover` (planned)

---

### 2.8 Document System

| Capability | Status | Location | Reuse Targets | Duplicate? | Future Package |
|------------|--------|----------|---------------|------------|----------------|
| `document.metadata` | existing | `ProjectMetadata` in EMathicaDocumentKit | All | No | EMathicaDocumentKit |
| `document.calculator.primary` | existing | `moduleID` on EMathicaDocument | All | No | EMathicaDocumentKit |
| `document.calculator.enabled` | planned | `ProjectPackageStructure`预留 | Future | No | EMathicaDocumentKit |
| `document.object.add` | existing | `EMathicaDocument.apply(.addObject)` | All | No | EMathicaDocumentKit |
| `document.object.delete` | existing | `EMathicaDocument.apply(.deleteObject)` | All | No | EMathicaDocumentKit |
| `document.object.update` | existing | `EMathicaDocument.apply(.updateObject)` | All | No | EMathicaDocumentKit |
| `document.save` | existing | `LocalProjectStore.saveProject` | App | No | EMathicaDocumentKit |
| `document.load` | existing | `LocalProjectStore.loadProject` | App | No | EMathicaDocumentKit |
| `document.package.codec` | existing | `EMathicaPackageCodec` + `EMathicaPackageLayout` | IO | No | EMathicaDocumentKit |
| `document.preview.generate` | existing | `ProjectPreviewRenderer.renderPNGData` | CoreHome, IO | No | EMathicaPreviewKit |
| `document.trans.record` | planned | — | All | No | EMathicaDocumentKit |
| `document.version.migrate` | planned | `ProjectMetadata.version` | Future | No | EMathicaDocumentKit |

**高风险重复:** ⚠️ 严重。多个类型在 EMathicaDocumentKit (package) 和 DocumentSystem/ (App) 中有 **完全复制**：
- `EMathicaDocument.swift` — App 版本是 internal，Package 版本是 public
- `DocumentCommand.swift` — 完全一致
- `DocumentObjectPatch.swift` — 仅 access modifier 差异
- `ProjectMetadata.swift` — 完全一致
- `RecentProject.swift` — 完全一致
- `ProjectFileManagerPlaceholder.swift` — 完全一致

**建议:** 移除 App 端所有重复文件，统一通过 EMathicaDocumentKit import 使用。

**缺失能力:**
- `document.calculator.enabled` (planned)
- `document.trans.record` (planned)
- `document.version.migrate` (planned)

---

### 2.9 Math Input / Keyboard

| Capability | Status | Location | Reuse Targets | Duplicate? | Future Package |
|------------|--------|----------|---------------|------------|----------------|
| `input.session.edit` | existing | `FormulaEditSession` in WorkspaceKit/Input | Plane, Draft | No | EMathicaMathInputKit |
| `input.ast.build` | existing | `DraftMathObject` | Plane, Space | No | EMathicaMathInputKit |
| `input.cursor.navigate` | existing | `EditorCursorNavigator` | Keyboard | No | EMathicaMathInputKit |
| `input.keyboard.layout` | existing | `MathKeyboardView` (4 tabs) | All calculators | No | EMathicaMathInputKit |
| `input.keyboard.keys` | existing | `MathKeyboardView` (text/symbol/operator/template/function) | All calculators | No | EMathicaMathInputKit |
| `input.keyboard.action` | existing | `KeyboardKey` actions | All | No | EMathicaMathInputKit |
| `input.latex.serialize` | existing | FormulaEditorView → LaTeX output | Inspector, ObjectPanel | No | EMathicaMathInputKit |
| `input.expr.bridge` | partial | `SemanticIntentAdapterProtocol` | Draft | No | EMathicaMathInputKit |
| `input.diagnostic.show` | existing | `FormulaDiagnosticPresenter` | Draft | No | EMathicaMathInputKit |
| `input.keyboard.hardware` | partial | `HardwareKeyboardCaptureView` (UIKit-only) | macOS | No | EMathicaMathInputKit |

**高风险重复:** 无。键盘和输入管道通过 WorkspaceKit 集中管理。

**缺失能力:**
- `input.keyboard.hardware` (partial — macOS 缺失)

---

### 2.10 Formula Rendering

| Capability | Status | Location | Reuse Targets | Duplicate? | Future Package |
|------------|--------|----------|---------------|------------|----------------|
| `formula.render.latex` | existing | `LatexRenderService` in FeatureUtilities/Preview | ObjectPanel, Inspector, Draft, Keyboard | No | EMathicaFormulaRenderKit |
| `formula.render.label` | existing | `FormulaLabelPreviewView` in SharedUI | ObjectPanel, Inspector | No | EMathicaFormulaRenderKit |
| `formula.render.inline` | existing | `FormulaEditorView` inline formula rendering | ObjectRow, Inspector | No | EMathicaFormulaRenderKit |
| `formula.render.thumbnail` | existing | `FormulaLabelPreviewView` small-size rendering | ProjectCard | No | EMathicaFormulaRenderKit |
| `formula.measure.baseline` | partial | Implicit in layout calculations | Layout | No | EMathicaFormulaRenderKit |
| `formula.render.fallback` | existing | `TextSubstitutionRenderService` (Unicode fallback) | All | No | EMathicaFormulaRenderKit |
| `formula.render.cache` | planned | — | All | No | EMathicaFormulaRenderKit |

**高风险重复:** 无。但渲染路径分散：
- `LatexRenderService` → FeatureUtilities
- `FormulaLabelPreviewView` → SharedUI
- `FormulaEditorView` → WorkspaceKit (承担渲染+编辑双重职责)
建议统一到 FormulaRenderKit。

**缺失能力:**
- `formula.measure.baseline` (partial)
- `formula.render.cache` (planned)

---

### 2.11 Preview / Thumbnail

| Capability | Status | Location | Reuse Targets | Duplicate? | Future Package |
|------------|--------|----------|---------------|------------|----------------|
| `preview.draft.generate` | existing | `PlaneDraftPreviewService` | Plane | No | EMathicaPreviewKit |
| `preview.object.render` | existing | `PlaneObjectRendererView` | Plane, Space | No | EMathicaPreviewKit |
| `preview.project.render` | existing | `ProjectPreviewRenderer` | CoreHome, IO | No | EMathicaPreviewKit |
| `preview.thumbnail.generate` | existing | `ProjectPreviewRenderer.renderPNGData` | RecentProjects, IO | No | EMathicaPreviewKit |
| `preview.cache` | planned | — | All | No | EMathicaPreviewKit |

**高风险重复:** ⚠️ 中等。Draft preview (`PlaneDraftPreviewService`) 使用了采样能力，而 Project preview (`ProjectPreviewRenderer`) 也实现了采样回退逻辑。两者存在采样策略重复。
- `PlaneDraftPreviewService`: explicit 700 samples, parametric 320 samples
- `ProjectPreviewRenderer`: 三级降级（Geometry→Semantic→Legacy）其中有 LegacyExplicitSampling
建议统一采样入口。

**缺失能力:**
- `preview.cache` (planned)

---

### 2.12 Workspace

| Capability | Status | Location | Reuse Targets | Duplicate? | Future Package |
|------------|--------|----------|---------------|------------|----------------|
| `workspace.shell` | existing | `WorkspaceView` (991行) | All | No | EMathicaWorkspaceKit |
| `workspace.module.register` | existing | `WorkspaceModuleProviding` | All calculators | No | EMathicaWorkspaceKit |
| `workspace.canvas.integrate` | existing | `WorkspaceView` canvasLayer | Plane, Space | No | EMathicaWorkspaceKit |
| `workspace.tool.groups` | existing | `FloatingToolGroupsView` | All | No | EMathicaWorkspaceKit |
| `workspace.command.route` | existing | `WorkspaceState.dispatch` | All | No | EMathicaWorkspaceKit |
| `workspace.inspector.shell` | existing | `ObjectInspectorPanel` (577行) | All | No | EMathicaInspectorKit |
| `workspace.objectPanel.shell` | existing | `AlgebraObjectPanelView` (722行) | All | No | EMathicaWorkspaceKit |

**高风险重复:** 无。Workspace 作为统一的 Shell 实现良好。

**缺失能力:**
- `workspace.layout.responsive` (existing — already well implemented)

---

### 2.13 Command System

| Capability | Status | Location | Reuse Targets | Duplicate? | Future Package |
|------------|--------|----------|---------------|------------|----------------|
| `command.document.apply` | existing | `DocumentCommand` + `EMathicaDocument.apply` | All | No | EMathicaDocumentKit |
| `command.workspace.dispatch` | existing | `WorkspaceCommand` (30+ cases) | All | No | EMathicaWorkspaceKit |
| `command.module.handle` | existing | `ModuleCommandHandler` protocol | Plane, Space | No | EMathicaWorkspaceKit |
| `command.undo.execute` | existing | `WorkspaceSessionHistory` (snapshot-based, max 100) | All | No | EMathicaWorkspaceKit |
| `command.redo.execute` | existing | Same | All | No | EMathicaWorkspaceKit |
| `command.history.track` | existing | `WorkspaceSessionHistory` | All | No | EMathicaWorkspaceKit |
| `command.mutation.safe` | existing | DocumentCommand applied atomically | All | No | EMathicaDocumentKit |

**高风险重复:** 无。命令系统通过 `WorkspaceCommand → DocumentCommand` 两层架构清晰分层。

**缺失能力:**
- `command.macro.batch` (planned) — 批量命令原子执行

---

### 2.14 Tool System

| Capability | Status | Location | Reuse Targets | Duplicate? | Future Package |
|------------|--------|----------|---------------|------------|----------------|
| `tool.id.define` | existing | `PlaneToolIDs` / `SpaceToolIDs` | Plane, Space | No | Per-calculator |
| `tool.group.define` | existing | `WorkspaceToolGroup` | All | No | EMathicaWorkspaceKit |
| `tool.provider.register` | existing | `PlaneToolProvider` / `SpaceToolProvider` | Plane, Space | No | Per-calculator |
| `tool.module.register` | existing | `WorkspaceModuleProviding.toolGroups` | All | No | EMathicaWorkspaceKit |
| `tool.construction.mode` | existing | `PlaneConstructionMode` (21 cases) | Plane | No | Per-calculator (Plane) |
| `tool.action.execute` | existing | `WorkspaceToolAction` enum | All | No | EMathicaWorkspaceKit |

**高风险重复:** 无。工具系统架构清晰，Plane 16 工具 / Space 7 工具。

---

### 2.15 Selection / HitTest

| Capability | Status | Location | Reuse Targets | Duplicate? | Future Package |
|------------|--------|----------|---------------|------------|----------------|
| `selection.hitTest.object` | existing | `PlaneHitTestService` (476行) | Plane | No | EMathicaSelectionKit |
| `selection.hitTest.handle` | partial | Implicit in drag handling | Plane | No | EMathicaSelectionKit |
| `selection.single` | existing | `WorkspaceState.selectedObjectIDs` | Plane, Space | No | EMathicaSelectionKit |
| `selection.multi` | existing | `clearSelection` / batch operations | Plane | No | EMathicaSelectionKit |
| `selection.objectPanel` | existing | `AlgebraObjectPanelView` row tap | Plane, Space | No | EMathicaSelectionKit |
| `selection.inspector` | existing | `ObjectInspectorPanel` binds to selected object | Plane, Space | No | EMathicaInspectorKit |

**高风险重复:** 无。HitTest 实现在 PlaneHitTestService 和 SpaceHitTestService 中是模块特定的，各实现各自的命中检测算法（2D vs 3D），这是合理的差异化。

**缺失能力:**
- `selection.hitTest.handle` (partial)

---

### 2.16 Inspector

| Capability | Status | Location | Reuse Targets | Duplicate? | Future Package |
|------------|--------|----------|---------------|------------|----------------|
| `inspector.section.render` | existing | `ObjectInspectorPanel` (3 tabs) | All | No | EMathicaInspectorKit |
| `inspector.property.edit` | existing | Inspector property editors | All | No | EMathicaInspectorKit |
| `inspector.style.edit` | existing | Color picker, opacity slider, line width etc. | All | No | EMathicaInspectorKit |
| `inspector.objectSpecific` | existing | `GeometryInspectorPropertyPresenter` / `SpaceGeometryInspectorPropertyPresenter` | Plane, Space | No | EMathicaInspectorKit |
| `inspector.moduleSpecific` | partial | Canvas/Caculator tabs | All | No | EMathicaInspectorKit |

**高风险重复:** 无。

---

### 2.17 Style / Theme

| Capability | Status | Location | Reuse Targets | Duplicate? | Future Package |
|------------|--------|----------|---------------|------------|----------------|
| `style.math.define` | existing | `MathStyle` in MathCore | Canvas, Inspector, Preview | No | EMathicaThemeKit |
| `style.color.token` | existing | `MathStyle.colorToken` → `ColorToken.resolvedColor` | Canvas, Inspector, ObjectPanel | No | EMathicaThemeKit |
| `style.line.width` | existing | `MathStyle.lineWidth` (0.5-8.0) | Canvas | No | EMathicaThemeKit |
| `style.dash.pattern` | existing | `MathStyle.lineStyle` (.solid/.dashed) | Canvas | No | EMathicaThemeKit |
| `style.glass` | existing | `LiquidGlassPanel`, `GlassPanel` in ThemeKit | Workspace, Keyboard, Inspector, ObjectPanel | No | EMathicaThemeKit |
| `style.app.theme` | existing | `HomeBackgroundTheme`, dark/light mode support | CoreHome, Workspace | No | EMathicaThemeKit |

**高风险重复:** 无。ThemeKit 是集中式主题管理。

---

### 2.18 Asset

| Capability | Status | Location | Reuse Targets | Duplicate? | Future Package |
|------------|--------|----------|---------------|------------|----------------|
| `asset.image.store` | existing | `ProjectPackageStructure.assetsPath` | DocumentSystem | No | EMathicaAssetKit |
| `asset.audio.store` | planned | — | Music | No | EMathicaAssetKit |
| `asset.plugin.store` | planned | `ProjectPackageStructure.pluginsPath` (reserved) | PluginSystem | No | EMathicaAssetKit |
| `asset.reference` | planned | — | All | No | EMathicaAssetKit |
| `asset.cache` | planned | — | All | No | EMathicaAssetKit |
| `asset.package.storage` | planned | — | DocumentSystem | No | EMathicaAssetKit |

**高风险重复:** 无。资产系统目前只有 image asset 的基础结构。

**缺失能力:**
- 大部分 asset 能力都是 planned

---

### 2.19 Export

全部能力均为 planned。

| Capability | Status | Location | Future Package |
|------------|--------|----------|----------------|
| `export.image.png` | planned | — | EMathicaExportKit |
| `export.vector.svg` | planned | — | EMathicaExportKit |
| `export.document.pdf` | planned | — | EMathicaExportKit |
| `export.animation.gif` | planned | — | EMathicaExportKit |
| `export.animation.video` | planned | — | EMathicaExportKit |
| `export.notebook` | planned | — | EMathicaExportKit |
| `export.package` | planned | — | EMathicaExportKit |

**当前状态:** 只有 `preview.png` 生成可视为 `export.image.png` 的基础。其余全部为 planned。

---

### 2.20 Animation

| Capability | Status | Location | Future Package |
|------------|--------|----------|----------------|
| `animation.parameter.play` | existing | `ParameterObjectRowView` inline slider playback | EMathicaAnimationKit |
| `animation.timeline` | planned | — | EMathicaAnimationKit |
| `animation.keyframe` | planned | — | EMathicaAnimationKit |
| `animation.object` | planned | — | EMathicaAnimationKit |
| `animation.construction.playback` | planned | — | EMathicaAnimationKit |

---

### 2.21 Plugin

| Capability | Status | Location | Reuse Targets | Duplicate? | Future Package |
|------------|--------|----------|---------------|------------|----------------|
| `plugin.manifest.define` | existing | `PluginManifest` struct | PluginSystem | No | EMathicaPluginKit |
| `plugin.protocol.define` | existing | `EMathicaPlugin` protocol | PluginSystem | No | EMathicaPluginKit |
| `plugin.capability.expose` | planned | — | All | No | EMathicaPluginKit |
| `plugin.block.compose` | planned | — | PluginSystem | No | EMathicaPluginKit |
| `plugin.block.parameter` | planned | — | PluginSystem | No | EMathicaPluginKit |
| `plugin.safety.policy` | planned | — | PluginSystem | No | EMathicaPluginKit |
| `plugin.permission.model` | planned | — | PluginSystem | No | EMathicaPluginKit |

**高风险重复:** 无。插件系统目前仅定义了协议和清单，核心执行管线未实现。

---

### 2.22 Calculator Modules

#### Plane Calculator
| Dimension | Status |
|-----------|--------|
| 当前已有功能 | 16 tools, hit-test, canvas rendering, draft preview, geometry resolver, construction modes, object panel, inspector, undo/redo |
| 当前依赖 capability | MathCore (Expr/CAS/Sampling/Geometry), DocumentKit, WorkspaceKit, ThemeKit |
| 未来需要 capability | `geometry.transform`, `animation.construction.playback`, `export.*` |
| 重复实现风险 | `PlaneLegacyExplicitSampling` vs `ExplicitFunctionSampler2D` |

#### Space Calculator
| Dimension | Status |
|-----------|--------|
| 当前已有功能 | 7 tools, wireframe rendering, hit-test, space geometry resolver, work plane selection |
| 当前依赖 capability | MathCore (SpaceMathCore/Geometry), WorkspaceKit, ThemeKit |
| 未来需要 capability | `geometry.convert.3dTo2d`, `graph.sample.parametric3D`, `animation.object` |
| 重复实现风险 | 无 |

#### Notes / Data / Modeling / Music
**所有四个计算器均为 skeleton/placeholder 状态。** 它们存在于 `CalculatorModuleType` 枚举中，但在 `CalculatorModules/` 下没有实质性实现代码。它们的模块图标存在于 `emathica_module_icons/` 中。

| Calculator | Status | 代码位置 |
|------------|--------|----------|
| Notes | planned | CalculatorModuleType entry only |
| Data | planned | CalculatorModuleType entry only |
| Modeling | planned | CalculatorModuleType entry only |
| Music | planned | CalculatorModuleType entry only |

---

## 3. High-Risk Duplicate Implementation Areas

| 风险等级 | 区域 | 详情 |
|---------|------|------|
| 🔴 **HIGH** | DocumentSystem ↔ EMathicaDocumentKit | 6 个文件完全复制（EMathicaDocument, DocumentCommand, DocumentObjectPatch, ProjectMetadata, RecentProject, ProjectFileManagerPlaceholder） |
| 🔴 **HIGH** | DocumentSystem/GeometryDefinition ↔ MathCore/GeometryDefinition | DocumentSystem 版本缺少 `.arc` case，不包含 `Sendable` |
| 🟡 **MEDIUM** | PlaneLegacyExplicitSampling ↔ MathCore Samplers | Draft preview 和 Project preview 有独立采样路径 |
| 🟡 **MEDIUM** | Object Naming Path 1 ↔ Path 2 | WorkspaceState count-based vs PlaneCommandHandler.nextFunctionName |
| 🟢 **LOW** | LatexRenderService → FeatureUtilities + FormulaLabelPreviewView → SharedUI + FormulaEditorView → WorkspaceKit | 渲染能力分散在三处，但并非重复实现 |

---

## 4. Missing Capability Summary

### Critical (P0 — Block Plane v1.0)
- `dependency.graph.detectCycle` — DependencyGraph 占位符为空
- `dependency.resolve` (full) — Space 的 dependency resolution 未实现

### High (P1 — After v1.0)
- `document.trans.record` — 跨计算器转换历史
- `document.version.migrate` — 文档格式升级
- `geometry.convert.2dTo3d` / `geometry.convert.3dTo2d` — 跨计算器对象转换
- `export.image.png` — 基础的 PNG 导出
- `export.vector.svg` — SVG 导出

### Medium (P2 — Future)
- `cas.factor` / `cas.integrate` / `cas.limit`
- `graph.classify.parametric3D` / `graph.classify.implicit3D`
- `graph.sample.parametric3D`
- `geometry.projection` / `geometry.transform`
- `animation.*` (timeline, keyframe, object, construction)
- `plugin.capability.expose` / `plugin.block.*` / `plugin.safety.*`

### Low (P3)
- `asset.audio.store` / `asset.cache`
- `formula.render.cache` / `formula.measure.baseline`
- `preview.cache`
- Notes/Data/Modeling/Music calculator implementations

---

## 5. Plugin Exposure Suitability

### Safe (most capability is read-only / pure computation)
- `formula.render.*` — 纯渲染，无副作用
- `expr.serialize.*` / `expr.parse.*` — 纯计算
- `cas.*` — 纯代数运算
- `graph.classify.*` — 纯分类
- `graph.sample.*` — 纯采样
- `geometry.intersection` / `geometry.distance` — 纯几何计算
- `style.math.define` — 纯数据定义

### Restricted (modifies document state)
- `document.object.*` — 修改文档
- `command.*` — 执行命令
- `dependency.*` — 修改依赖关系
- `selection.*` — 改变选择状态
- `animation.*` — 可能触发重渲染

### Internal (system infrastructure)
- `workspace.*` — Shell 基础设施
- `document.save` / `document.load` — IO 操作
- `document.package.codec` — 编解码

---

## 6. Current Implementation Location Map

```
Packages/EMathicaMathCore/Sources/EMathicaMathCore/
├── SemanticCore/            → expr.ast, expr.symbol, expr.relation, expr.piecewise
├── CASCore/                 → cas.normalize, cas.simplify, cas.canonicalize, cas.differentiate, cas.solve, cas.extract
├── AlgebraCore/             → cas.expand.polynomial
├── GraphCore/               → graph.classify.* (7 types)
├── SamplingCore/            → graph.sample.* (8 types)
├── Coordinate/              → geometry.*.2d coordinates
├── SpaceMathCore/           → geometry.*.3d
├── GeometryDefinition.swift → geometry.* definitions, dependency types
├── MathObject.swift         → object.identity, object.kind, object.style, object.metadata
├── MathStyle.swift          → style.math, style.color, style.line, style.dash
└── DependencyGraph.swift    → (empty placeholder)

Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/
├── Commands/                → command.workspace, command.module
├── Tools/                   → tool.*
├── Toolbar/                 → workspace.tool.groups
├── Input/                   → input.session, input.ast
├── Keyboard/                → input.keyboard.*
├── StructuredInput/         → input.diagnostic, expr.semantic, expr.parse
├── Inspector/               → inspector.*
├── ObjectPanel/             → workspace.objectPanel, selection.objectPanel
├── History/                 → command.undo, command.redo, command.history
├── Protocols/               → input.expr.bridge, input.canonicalize
└── WorkspaceState.swift     → workspace.shell (core state)
    WorkspaceView.swift      → workspace.shell (UI)

Packages/EMathicaDocumentKit/Sources/EMathicaDocumentKit/
├── EMathicaDocument.swift   → document.object.*, command.document
├── DocumentCommand.swift    → command.document
├── ProjectMetadata.swift    → document.metadata
├── IO/ProjectStore.swift    → document.save, document.load
└── Package/                 → document.package.codec

eMathica/  (App Target)
├── CalculatorModules/Plane/
│   ├── Views/               → preview.object, canvas.plane
│   ├── Services/            → preview.draft, geometry.intersection, selection.hitTest
│   ├── Interaction/         → tool.construction
│   └── Tools/               → tool.id, tool.provider
├── CalculatorModules/Space/
│   ├── Views/               → canvas.space
│   └── Services/            → geometry.space, selection.hitTest.3d
├── CoreHome/Preview/        → preview.project, preview.thumbnail
├── DocumentSystem/          → ⚠️ DUPLICATES of EMathicaDocumentKit
├── FeatureUtilities/Preview/ → formula.render.latex
├── SharedUI/                → formula.render.label
└── PluginSystem/            → plugin.manifest, plugin.protocol
```

---

## 7. Next Steps

1. **Immediate (Plane v1.0):** 不重构任何能力包
2. **Post-v1.0 Priority:**
   - 移除 DocumentSystem 中的 EMathicaDocumentKit 重复
   - 移除 DocumentSystem/GeometryDefinition.swift 旧副本
   - 统一采样路径（废弃 PlaneLegacyExplicitSampling）
3. **Package Split Phase 1:** EMathicaMathCore 拆分 → EMathicaCASCore + EMathicaGraphIntentCore + EMathicaSamplingCore + EMathicaGeometryCore
4. **Package Split Phase 2:** EMathicaFormulaRenderKit + EMathicaMathInputKit + EMathicaPreviewKit
5. **Package Split Phase 3:** EMathicaObjectKit + EMathicaDependencyKit + EMathicaPluginKit
6. **Long-term:** EMathicaExportKit + EMathicaAnimationKit + EMathicaAssetKit
