# eMathica Swift Package Split Audit

> **Date:** 2026-06-05  
> **Scope:** Read-only audit — no code modified, no files moved, no Xcode config changed.  
> **Goal:** Assess readiness for splitting the monolithic eMathica app into multiple calculator app targets sharing Swift Packages.

---

## 1. Audit Scope

- **Project root:** `/Users/night_creek/开发/eMathica/`
- **Main source:** `eMathica/eMathica/eMathica/`
- **Existing packages:**  
  - `eMathica/eMathica/Packages/EMathicaMathCore/` (partial extraction, inside Xcode project)  
  - `Packages/EMathicaMathInputKit/` (standalone, at repo root)

### Audited directories

| Directory | Files | Role |
|-----------|-------|------|
| `MathCore/` | ~60 Swift files | Pure math: AST, CAS, evaluation, sampling, graphing, algebra, coordinate |
| `WorkspaceKit/` | ~60 Swift files | Workspace UI framework: canvas, tools, inspector, keyboard, structured input, commands |
| `DocumentSystem/` | 13 Swift files | Document model, project store, .emathica package codec, preview renderer |
| `PluginSystem/` | 5 Swift files | Plugin protocol, manifest, error types |
| `CalculatorModules/` | ~45 Swift files | Module registry + per-module code: Plane (rich), Space (partial), Notes/Data/Music/Modeling (placeholders) |
| `CoreHome/` | ~26 Swift files | Home screen UI: hero, gallery, project cards, responsive layout |
| `App/` | 5 Swift files | App entry point, navigation, route, CoreData persistence |
| `Packages/EMathicaMathCore/` | ~40 Swift files | Duplicate of MathCore/CASCore, EvaluationCore, GraphCore, Sampling2D, SemanticCore, SpaceMathCore |
| `Packages/EMathicaMathInputKit/` | 7 Swift files | Standalone math input AST, engine, serialization |

---

## 2. Current Project Structure

```
eMathica/
├── App/                          # Entry point: EMathicaApp, AppRootView, AppNavigationState, AppRoute
│   └── Infrastructure/           # PersistenceController (CoreData)
├── CoreHome/                     # Home screen (all SwiftUI): hero, gallery, projects, layout
│   ├── Background/               # Animated background layers
│   ├── Components/               # (empty)
│   ├── Layout/                   # Responsive layout: phone, pad, fluid metrics
│   └── Mocks/                    # Mock project store for previews
├── CalculatorModules/            # Module registry + per-calculator code
│   ├── Plane/                    # ★ Most developed: tools, views, services, interaction, rendering
│   ├── Space/                    # Partial: tools, views, services, models
│   ├── Notes/Views/             # Placeholder only
│   ├── Data/Views/              # Placeholder only
│   ├── Music/Views/             # Placeholder only
│   ├── Modeling/Views/          # Placeholder only
│   └── Commands/                # ModuleCommandHandling protocol + registry
├── WorkspaceKit/                 # Workspace UI framework
│   ├── Commands/                 # WorkspaceCommand, WorkspaceInputMode
│   ├── Tools/                    # WorkspaceTool, WorkspaceToolGroup, WorkspaceToolContext
│   ├── Input/                    # FormulaEditSession, DraftMathObject, MathPlainTextField
│   ├── Keyboard/                 # MathKeyboardView, FormulaEditorView, FormulaInputState
│   ├── StructuredInput/          # MathEditorAST, MathEditorEngine, MathEditorSerialization
│   ├── Inspector/                # ObjectInspectorPanel, GeometryInspectorPropertyPresenter
│   ├── ObjectPanel/              # AlgebraObjectPanelView, WorkspaceObjectRowView
│   ├── Toolbar/                  # FloatingToolGroupsView, ToolButtonView, ToolGroupCapsuleView
│   ├── History/                  # WorkspaceSessionHistory, DeletedObjectHistorySheet
│   └── Shared/                   # Glass components, ColorToken, WorkspaceTheme, formatters
├── DocumentSystem/               # Document model + IO
│   ├── IO/                       # LocalProjectStore, ProjectStore protocol
│   ├── Package/                  # EMathicaPackageCodec, EMathicaPackageLayout
│   └── Preview/                  # ProjectPreviewRenderer (renders thumbnails)
├── MathCore/                     # Pure math library
│   ├── AlgebraCore/              # Algebra expression, evaluator, LaTeX serialization, classifier
│   │   ├── Analysis/             # VariableAnalyzer, PlaneAlgebraClassifier, ConicParametricRewriter
│   │   ├── Parsing/              # LaTeX lexer + parser
│   │   └── Simplification/       # AlgebraSimplifier
│   ├── CASCore/                  # Canonical expression, normalizer, simplifier, polynomial expander
│   ├── EvaluationCore/           # ExprEvaluator, ConditionEvaluator, EvaluationEnvironment
│   ├── GraphCore/                # GraphClassifier, GraphIntent, ConicInfo, ParameterRange
│   ├── SamplingCore/Sampling2D/  # 14 sampling algorithm files (explicit, implicit, parametric, polar, conic, etc.)
│   ├── SemanticCore/             # Expr (AST), Symbol, MathFunction, MatrixExpr, PiecewiseExpr
│   ├── Coordinate/               # CoordinateTransform, MathTypes, SpaceMath3D
│   └── Viewport/                 # Viewport
├── PluginSystem/                 # Plugin protocol infrastructure
├── Packages/EMathicaMathCore/    # ★ Existing partial package extraction
└── Docs/                         # This document
```

---

## 3. Calculator Module Boundary Review

### 3.1 Plane

| Criterion | Assessment |
|-----------|------------|
| **Clear boundary?** | ✅ YES — `PlaneModule.swift`, `PlaneWorkspaceModuleProvider`, `PlaneWorkspaceConfig` define clear entry points |
| **Wrong dependencies?** | ⚠️ Module depends on `EMathicaMathCore` (correct) and Foundation/CoreGraphics (correct). No wrong deps *outward*. |
| **Mixed concerns?** | ⚠️ Services mix math logic with viewport/CG concerns. `PlaneSamplingViewportResolver`, `PlaneHitTestService`, `PlaneLineClipping` are math+screen hybrid. `PlaneObjectRendererView` mixes sampling logic into SwiftUI views. |
| **Ready for app target?** | 🟡 PARTIALLY — The module boundary is well-defined (provider pattern), but the services are referenced directly by `WorkspaceKit/WorkspaceState.swift` and `DocumentSystem/Preview/ProjectPreviewRenderer.swift`. An independent app target would work IF those references are moved behind a protocol. |
| **Pre-split issues:** | 1. `PlaneGeometryDependencyRecomputeService` is called directly from `WorkspaceKit/WorkspaceState.swift` (lines 370, 469, 485, 492) — must move behind protocol. 2. `PlaneSemanticGraphIntentAdapter` is called directly from `WorkspaceKit/WorkspaceState.swift` (lines 1229-1236, 1271-1277) — must move behind protocol. 3. `PlaneGeometryResolver`, `PlaneLineClipping`, `PlaneSemanticIntentResolver`, `PlaneFallbackSamplingService`, `PlaneSampleSetAdapter` are called from `DocumentSystem/Preview/ProjectPreviewRenderer.swift` — must decouple. |

### 3.2 Space

| Criterion | Assessment |
|-----------|------------|
| **Clear boundary?** | 🟡 PARTIAL — Has `SpaceWorkspaceModuleProvider`, `SpaceToolProvider`, `SpaceToolIDs`. Boundary exists but is sparse. |
| **Wrong dependencies?** | ⚠️ `SpaceWorkPlane` enum is defined INSIDE `CalculatorModules/Space/Models/` but is referenced by `WorkspaceKit/WorkspaceModuleProviding.swift` (line 18) and `WorkspaceKit/WorkspaceState.swift` (line 32). This type should be in a shared location. |
| **Mixed concerns?** | ⚠️ `SpaceCanvasView` mixes SwiftUI view code with hit testing and interaction logic. `SpaceGeometryResolver` mixes math with CG coordinate conversion. |
| **Ready for app target?** | 🔴 NOT YET — The module has too little implementation (placeholder view still exists alongside canvas view). `SpaceWorkPlane` type is in the wrong location. `SpaceCameraState` is correctly in MathCore, which is good. |
| **Pre-split issues:** | 1. `SpaceWorkPlane` enum must move to MathCore or a shared types module. 2. Module needs completion (many features are placeholder). 3. `SpaceGeometryResolver` and `SpaceHitTestService` should be cleaned of CG screen-coordinate logic. |

### 3.3 Notes

| Criterion | Assessment |
|-----------|------------|
| **Clear boundary?** | 🔴 NO — Only `CalculatorModules/Notes/Views/NotesPlaceholderView.swift` exists. No module definition, no provider, no tools. |
| **Wrong dependencies?** | N/A — too minimal to assess. |
| **Mixed concerns?** | N/A |
| **Ready for app target?** | 🔴 NO — Placeholder only. Requires full implementation before splitting. |
| **Pre-split issues:** | 1. Must implement `NotesModule`, `NotesWorkspaceModuleProvider`, and all supporting services. |

### 3.4 Data

| Criterion | Assessment |
|-----------|------------|
| **Clear boundary?** | 🔴 NO — Only `CalculatorModules/Data/Views/DataPlaceholderView.swift` exists. |
| **Ready for app target?** | 🔴 NO — Placeholder only. |

### 3.5 Music

| Criterion | Assessment |
|-----------|------------|
| **Clear boundary?** | 🔴 NO — Only `CalculatorModules/Music/Views/MusicPlaceholderView.swift` exists. |
| **Ready for app target?** | 🔴 NO — Placeholder only. |

### 3.6 Modeling

| Criterion | Assessment |
|-----------|------------|
| **Clear boundary?** | 🔴 NO — Only `CalculatorModules/Modeling/Views/ModelingPlaceholderView.swift` exists. |
| **Ready for app target?** | 🔴 NO — Placeholder only. |

### 3.7 Commands

| Criterion | Assessment |
|-----------|------------|
| **Clear boundary?** | ✅ YES — `ModuleCommandHandling` protocol + `ModuleCommandHandlerRegistry` define a clean abstraction. |
| **Wrong dependencies?** | ✅ None — depends only on Foundation. |
| **Ready for independent use?** | ✅ YES — Can be lifted into WorkspaceKit or a shared module immediately. |

### 3.8 Shared Core (MathCore)

| Criterion | Assessment |
|-----------|------------|
| **Clear boundary?** | ✅ YES — Pure math, no UI framework imports. Only Foundation + CoreGraphics. |
| **Wrong dependencies?** | ⚠️ Minor: `CanvasState` uses `CGPoint`/`CGSize` (CoreGraphics). `MathTypes` imports CoreGraphics. `CoordinateTransform` imports CoreGraphics. These are acceptable for 2D coordinate work but should be clearly separated into a "math types with CG bridge" sub-module if targeting non-Apple platforms. |
| **Mixed concerns?** | ⚠️ `PlaneAlgebraClassifier` lives in MathCore/AlgebraCore/Analysis/ — the name suggests Plane-specific logic, but it's actually generic algebra classification. Naming is misleading but content is correctly placed. |
| **Ready for package?** | 🟡 Partial extraction already started. See Section 4A. |

---

## 4. Shared Package Candidate Review

### 4A. EMathicaMathCore

**Status:** Partial extraction already exists at `eMathica/eMathica/Packages/EMathicaMathCore/`

**Currently extracted (in Package):**
- `CASCore/` — CanonicalExpr, Canonicalizer, ExpressionNormalizer, ExpressionSimplifier, PolynomialExpander, QuadraticFormExtractor
- `EvaluationCore/` — ConditionEvaluationResult, ConditionEvaluator, EvaluationEnvironment, EvaluationResult, ExprEvaluator
- `GraphCore/` — ConicInfo, GraphClassificationResult, GraphClassifier, GraphIntent, GraphIntentDebugPrinter, ParameterRange
- `SamplingCore/Sampling2D/` — All 14 sampler files
- `SemanticCore/` — Expr, ExprDebugPrinter, ExprDiagnostic, MathExpressionLowering, MathFunction, MatrixExpr, PiecewiseExpr, RelationOperator, Symbol
- `SpaceMathCore/` — SpaceMath3D (WorldPoint3D, Vector3D, SpaceCameraState, etc.)

**NOT yet extracted (still in app MathCore/):**
- `AlgebraCore/` — AlgebraExpression, AlgebraEvaluator, AlgebraLatexFormatter, AlgebraDisplayFormatter, Analysis/*, Parsing/*, Simplification/*
- `Coordinate/` — CoordinateTransform, MathTypes
- `Viewport/` — Viewport
- Root-level files — `CanvasState.swift`, `CoordinateSystem.swift`, `DependencyGraph.swift`, `MathExpression.swift`, `MathObject.swift`, `MathObjectType.swift`, `MathPoint.swift`, `MathStyle.swift`

**Dependencies:** Foundation, CoreGraphics. No SwiftUI. No dependency on any other eMathica module.

**Can be extracted immediately?** 🟡 Partial — The already-extracted files work as a package. Remaining files need:
1. `CanvasState.swift` — uses CoreGraphics heavily (CGPoint, CGSize). Should be extracted but tagged as "2D coordinate bridge."
2. `AlgebraCore/` — pure Foundation math, no blockers.
3. `Coordinate/` — uses CoreGraphics for transforms, acceptable.
4. Root-level model files (`MathObject`, `MathExpression`, etc.) — needed by DocumentSystem; coordinate extraction carefully.

**Risk level:** 🟢 LOW for already-extracted files. 🟡 MEDIUM for AlgebraCore (depends on CASCore types). 🟢 LOW for remaining files once CASCore dependency is satisfied.

**Circular dependency risk:** None. MathCore is a leaf node.

**Pre-extraction decoupling needed:**
- `MathExpression.swift` (line 2) already imports `EMathicaMathCore` — this is a circular reference if the file itself is added to the package. Solution: keep `MathExpression` inside the package, remove the self-import.
- `PlaneAlgebraClassifier` naming is misleading — consider renaming to `AlgebraClassifier` (cosmetic, not blocking).

**Recommendation:** Continue extraction by adding AlgebraCore, Coordinate, Viewport, and root model files into the existing package.

---

### 4B. EMathicaInputKit

**Status:** Standalone package already exists at `/Users/night_creek/开发/eMathica/Packages/EMathicaMathInputKit/`

**Current structure:**
- `EMathicaMathInputCore` target — `MathEditorAST`, `MathEditorState`, `MathEditorEngine`, `TemplateDefinition`, `MathEditorSerialization`, `MathInputCharacterNormalizer`, `MathInputSession` — **No UI dependencies.**
- `EMathicaMathInputUI` target — Placeholder only.
- `EMathicaMathInputKit` umbrella — combines both targets.

**Overlap with app code:**
- `WorkspaceKit/StructuredInput/MathEditorAST.swift` — similar AST but likely divergent from package version.
- `WorkspaceKit/StructuredInput/MathEditorEngine.swift` — similar engine.
- `WorkspaceKit/StructuredInput/MathEditorSerialization.swift` — similar serialization.
- `WorkspaceKit/StructuredInput/MathEditorState.swift` — similar state.
- `WorkspaceKit/StructuredInput/TemplateDefinition.swift` — similar templates.
- `WorkspaceKit/StructuredInput/MathInputCharacterNormalizer.swift` — similar normalizer.

**Dependencies (package):** None (Core target). EMathicaMathInputUI depends on EMathicaMathInputCore.

**Can be extracted immediately?** 🟡 PARTIAL — The Core target is already a clean package with no dependencies. However, the app's `WorkspaceKit/StructuredInput/` has divergent copies that need reconciliation:
- The package version is newer/cleaner (standalone, tested).
- The app version is integrated with `FormulaInputState`, `FormulaSemanticState`, `MathNodeSemanticLowering`, `EditorCursorNavigator`, `FormulaDiagnosticPresenter`, `FormulaPlotDiagnostic` — these are the integration layer.
- The app's StructuredInput also imports `EMathicaMathCore` for semantic lowering.

**Risk level:** 🟡 MEDIUM — The package is clean but integrating it back into the app requires replacing the app's StructuredInput with the package version, which touches `FormulaInputState+Sync`, `FormulaSemanticState`, `MathNodeSemanticLowering`, and `WorkspaceState`.

**Circular dependency risk:** None currently. The package has zero dependencies.

**Pre-extraction decoupling needed:**
- App's `WorkspaceKit/StructuredInput/` needs to be migrated to USE the package instead of having its own copies.
- The integration layer files (`FormulaInputState+Sync`, `FormulaSemanticState`, `MathNodeSemanticLowering`) should remain in WorkspaceKit and bridge between the package and EMathicaMathCore.
- `MathEditorAST` in the package must gain the `Codable` support needed by `FormulaInputState+Sync` (which encodes `editorState` as JSON).

---

### 4C. EMathicaDocumentKit

**Proposed contents:** All of `DocumentSystem/` minus the Plane/Space-specific preview rendering.

**Files suitable for inclusion:**
| File | Ready? | Notes |
|------|--------|-------|
| `EMathicaDocument.swift` | ✅ Yes | Core document model, depends on MathObject (in MathCore) |
| `DocumentCommand.swift` | ✅ Yes | Command enum, depends on MathObject, CanvasState, SpaceCameraState (all in MathCore) |
| `DocumentObjectPatch.swift` | ✅ Yes | Patch struct for MathObject fields |
| `GeometryDefinition.swift` | ✅ Yes | Geometry definition types |
| `ProjectMetadata.swift` | ✅ Yes | Project metadata struct |
| `ProjectPackageStructure.swift` | ✅ Yes | Package structure |
| `RecentProject.swift` | ✅ Yes | Recent project model |
| `ProjectFileManagerPlaceholder.swift` | ✅ Yes | Placeholder for file manager |
| `IO/ProjectStore.swift` | ✅ Yes | Protocol definition |
| `IO/ProjectStoreError.swift` | ✅ Yes | Error types |
| `IO/LocalProjectStore.swift` | ✅ Yes | Local file implementation |
| `Package/EMathicaPackageCodec.swift` | ✅ Yes | .emathica file codec |
| `Package/EMathicaPackageLayout.swift` | ✅ Yes | Package layout definition |
| `Preview/ProjectPreviewRenderer.swift` | 🔴 NO | **Imports UIKit. Calls Plane services directly.** Must be refactored or moved to a higher-level module. |

**Dependencies:**
- Foundation
- CoreGraphics (for `EMathicaPackageLayout` and `ProjectPreviewRenderer`)
- `EMathicaMathCore` (for `MathObject`, `MathExpression`, `CanvasState`, `SpaceCameraState`)
- `UIKit` (only `ProjectPreviewRenderer`)

**Can be extracted immediately?** 🔴 NO — `ProjectPreviewRenderer.swift` is heavily contaminated with:
1. Direct calls to `PlaneGeometryResolver` (lines 376, 425, 428-429, 436-437, 444)
2. Direct calls to `PlaneLineClipping` (lines 429, 437)
3. Direct calls to `PlaneSemanticIntentResolver` (line 481)
4. Direct calls to `PlaneFallbackSamplingService` (lines 488, 495)
5. Direct calls to `PlaneSampleSetAdapter` (line 496)
6. UIKit imports

**Risk level:** 🔴 HIGH — The preview renderer must be decoupled before DocumentKit can be a clean package.

**Circular dependency risk:** DocumentSystem → Plane (CalculatorModules). This is a reverse dependency that must be broken.

**Pre-extraction decoupling needed:**
1. Move `ProjectPreviewRenderer` out of DocumentSystem into a higher-level module (e.g., a new `EMathicaPreviewKit` or into `CoreHome`).
2. OR: Define a `PreviewRenderable` protocol in DocumentKit that Plane objects conform to, inverting the dependency.
3. Remove UIKit dependency from DocumentSystem — CoreGraphics is acceptable, UIKit is not for a document model package.

---

### 4D. EMathicaWorkspaceKit

**Proposed contents:** Protocol and type definitions from `WorkspaceKit/` that are module-agnostic.

**Files suitable for inclusion:**
| File | Ready? | Notes |
|------|--------|-------|
| `WorkspaceConfiguration.swift` | 🟡 Partial | Depends on CalculatorModuleRegistry (via `.make()`) — needs protocol injection |
| `WorkspaceLayout.swift` | ✅ Yes | SwiftUI layout types, module-agnostic |
| `WorkspaceModuleProviding.swift` | 🟡 Partial | References `SpaceCameraState` (✅ MathCore) and `SpaceWorkPlane` (🔴 CalculatorModules/Space). `SpaceWorkPlane` must move. |
| `Commands/WorkspaceCommand.swift` | ✅ Yes | Foundation only |
| `Commands/WorkspaceInputMode.swift` | ✅ Yes | Foundation only |
| `Tools/WorkspaceTool.swift` | ✅ Yes | Foundation only |
| `Tools/WorkspaceToolAction.swift` | ✅ Yes | Foundation only |
| `Tools/WorkspaceToolContext.swift` | ✅ Yes | Foundation + CoreGraphics |
| `Tools/WorkspaceToolGroup.swift` | ✅ Yes | Foundation only |
| `Tools/WorkspaceToolIcon.swift` | ✅ Yes | Foundation only |
| `Shared/ColorToken.swift` | 🟡 Partial | Imports SwiftUI, UIKit, AppKit — acceptable for a UI kit package, but needs platform conditionals |
| `Shared/WorkspaceTheme.swift` | ✅ Yes | SwiftUI |
| `Shared/GlassComponents.swift` | ✅ Yes | SwiftUI |
| `Shared/LiquidGlassButton.swift` | ✅ Yes | SwiftUI |
| `Shared/LiquidGlassIconButton.swift` | ✅ Yes | SwiftUI |
| `Shared/LiquidGlassInputBar.swift` | ✅ Yes | SwiftUI |
| `Shared/LiquidGlassPanel.swift` | ✅ Yes | SwiftUI |
| `Shared/FloatingPanelModifier.swift` | ✅ Yes | SwiftUI |
| `Shared/ModuleIconView.swift` | ✅ Yes | SwiftUI |
| `Shared/ModuleAssetIconView.swift` | ✅ Yes | SwiftUI |
| `Shared/AdaptiveWorkspaceMetrics.swift` | ✅ Yes | SwiftUI |
| `Shared/GeometryPropertyFormatter.swift` | ✅ Yes | Foundation + EMathicaMathCore |
| `Shared/SpaceGeometryPropertyFormatter.swift` | ✅ Yes | Foundation + EMathicaMathCore |
| `WorkspaceState.swift` | 🔴 NO | **Heavily contaminated.** Directly calls Plane services, references SpaceWorkPlane, has `canonicalPlaneCommitInput` method. Core workspace state logic is entangled with Plane-specific logic. |
| `WorkspaceView.swift` | 🔴 NO | References `AppNavigationState` (App module). Contains Plane-specific preview logic. |
| `Inspector/ObjectInspectorPanel.swift` | ✅ Yes | SwiftUI |
| `Inspector/ObjectInspectorButton.swift` | ✅ Yes | SwiftUI |
| `Inspector/GeometryInspectorPropertyPresenter.swift` | ✅ Yes | Foundation + EMathicaMathCore |
| `Inspector/SpaceGeometryInspectorPropertyPresenter.swift` | ✅ Yes | Foundation + EMathicaMathCore |
| `ObjectPanel/*` | ✅ Yes | SwiftUI views, module-agnostic |
| `Toolbar/*` | ✅ Yes | SwiftUI views, module-agnostic |
| `Keyboard/*` | ✅ Yes | SwiftUI views + Foundation state |
| `Input/*` | 🟡 Partial | `DraftMathObject`, `FormulaEditSession`, `ParameterSuggestionAnalyzer` are clean. `ExpressionInputBarView`, `MathPlainTextField`, `HardwareKeyboardCaptureView` import UIKit — acceptable for a UI kit but needs review. |
| `StructuredInput/*` | 🔴 NO | See 4B — should use the EMathicaInputKit package instead. |
| `History/*` | ✅ Yes | SwiftUI views + Foundation presenter |
| `Tools/GeometryToolIconView.swift` | ✅ Yes | SwiftUI |

**Dependencies (ideal):** Foundation, SwiftUI, CoreGraphics, EMathicaMathCore, EMathicaInputKit

**Can be extracted immediately?** 🔴 NO — Major contamination in `WorkspaceState.swift` (25 references to Plane services) and `WorkspaceView.swift` (App module dependency).

**Risk level:** 🔴 HIGH — WorkspaceState is the central state manager and it's deeply entangled with Plane-specific logic.

**Circular dependency risk:**
- `WorkspaceKit` → `CalculatorModules/Plane/Services/*` (PlaneGeometryDependencyRecomputeService, PlaneSemanticGraphIntentAdapter) — **REVERSE DEPENDENCY EXISTS**
- `WorkspaceKit` → `CalculatorModules/Space/Models/SpaceWorkPlane` — **REVERSE DEPENDENCY EXISTS**
- `WorkspaceKit/WorkspaceView` → `App/AppNavigationState` — **DEPENDS ON HIGHER LAYER**

**Pre-extraction decoupling needed (critical):**
1. **PlaneGeometryDependencyRecomputeService references** (WorkspaceState lines 370, 469, 485, 492): Define a `GeometryDependencyServiceProtocol` in WorkspaceKit. Move the four call sites behind this protocol. The Plane module registers its implementation.
2. **PlaneSemanticGraphIntentAdapter references** (WorkspaceState lines 1229-1236, 1271-1277): Define a `SemanticGraphIntentAdapterProtocol` in WorkspaceKit. Move call sites behind protocol.
3. **SpaceWorkPlane** (WorkspaceState line 32, WorkspaceModuleProviding line 18): Move enum from `CalculatorModules/Space/Models/` to `MathCore/Coordinate/` (next to `SpaceCameraState` which is already there).
4. **AppNavigationState** (WorkspaceView line 4): Use `@Environment(\.dismiss)` or a navigation protocol instead of directly depending on the App module's navigation type.
5. **canonicalPlaneCommitInput** method (WorkspaceState line 1666): Move to Plane module, invoke via protocol.

---

### 4E. EMathicaThemeKit

**Proposed contents:** Design tokens and shared visual components.

**Files suitable for inclusion:**
| Source | File | Ready? |
|--------|------|--------|
| WorkspaceKit/Shared | `ColorToken.swift` | 🟡 Needs platform conditional cleanup |
| WorkspaceKit/Shared | `WorkspaceTheme.swift` | ✅ Yes |
| WorkspaceKit/Shared | `GlassComponents.swift` | ✅ Yes |
| WorkspaceKit/Shared | `LiquidGlassButton.swift` | ✅ Yes |
| WorkspaceKit/Shared | `LiquidGlassIconButton.swift` | ✅ Yes |
| WorkspaceKit/Shared | `LiquidGlassInputBar.swift` | ✅ Yes |
| WorkspaceKit/Shared | `LiquidGlassPanel.swift` | ✅ Yes |
| WorkspaceKit/Shared | `FloatingPanelModifier.swift` | ✅ Yes |
| WorkspaceKit/Shared | `AdaptiveWorkspaceMetrics.swift` | ✅ Yes |
| CoreHome/Background | `HomeBackgroundTheme.swift` | ✅ Yes |
| CoreHome/Background | `HomeBackgroundLayout.swift` | ✅ Yes |

**Dependencies:** SwiftUI, CoreGraphics. No dependency on MathCore or any other eMathica module.

**Can be extracted immediately?** 🟡 MOSTLY — The visual components are self-contained. The main question is whether `ColorToken` should stay in WorkspaceKit or move to ThemeKit (it currently imports UIKit/AppKit for cross-platform color support).

**Risk level:** 🟢 LOW — ThemeKit is a leaf node with no math/logic dependencies.

**Circular dependency risk:** None. ThemeKit is purely visual.

**Pre-extraction decoupling needed:** Minimal. Clean up `ColorToken` platform conditionals. Decide whether `WorkspaceTheme` stays with ThemeKit or WorkspaceKit.

---

## 5. Dependency Risk Map

```
┌─────────────────────────────────────────────────────────────────────┐
│  Layer 4: App Entry Point                                            │
│  App/ (EMathicaApp, AppRootView, AppNavigationState, AppRoute)       │
│  DEPENDS ON: CoreHome, WorkspaceKit, DocumentSystem, CalculatorModules│
├─────────────────────────────────────────────────────────────────────┤
│  Layer 3: UI Shells                                                  │
│  CoreHome/ — Home screen UI                                          │
│  DEPENDS ON: DocumentSystem, CalculatorModules, AppNavigationState   │
│  ⚠️ AppNavigationState is in App/ — creates App→CoreHome→App cycle   │
│     (mitigated by @Environment injection, but type dependency exists) │
├─────────────────────────────────────────────────────────────────────┤
│  Layer 2: Module Layer (HIGHEST RISK)                                 │
│  CalculatorModules/ — Module registry + per-module code               │
│  WorkspaceKit/ — Workspace UI framework                               │
│  DocumentSystem/ — Document model + IO                                │
│                                                                       │
│  🔴 CRITICAL: WorkspaceKit/WorkspaceState directly depends on:        │
│     - CalculatorModules/Plane/Services/PlaneGeometryDependencyRecomputeService
│     - CalculatorModules/Plane/Services/PlaneSemanticGraphIntentAdapter│
│     - CalculatorModules/Space/Models/SpaceWorkPlane                   │
│  🔴 CRITICAL: DocumentSystem/Preview/ProjectPreviewRenderer depends on│
│     - CalculatorModules/Plane/Services/PlaneGeometryResolver          │
│     - CalculatorModules/Plane/Services/PlaneLineClipping              │
│     - CalculatorModules/Plane/Services/PlaneSemanticIntentResolver    │
│     - CalculatorModules/Plane/Services/PlaneFallbackSamplingService   │
│     - CalculatorModules/Plane/Services/PlaneSampleSetAdapter          │
│  ⚠️ CalculatorModuleRegistry directly instantiates Plane/Space providers│
├─────────────────────────────────────────────────────────────────────┤
│  Layer 1: Core Libraries (CLEAN)                                      │
│  MathCore/ — Pure math, no UI deps                                   │
│  PluginSystem/ — Pure protocol definitions, no deps                  │
│  DEPENDS ON: Foundation, CoreGraphics only                           │
└─────────────────────────────────────────────────────────────────────┘
```

### Dependency direction (ideal vs actual)

```
IDEAL:
  App → CoreHome → WorkspaceKit → CalculatorModules → MathCore
  App → CoreHome → DocumentSystem → MathCore

ACTUAL (problems marked with 🔴):
  App → CoreHome → WorkspaceKit ──🔴──→ CalculatorModules/Plane/Services
                    WorkspaceKit ──🔴──→ CalculatorModules/Space/Models
  App → DocumentSystem ──🔴──→ CalculatorModules/Plane/Services
  CalculatorModules/CalculatorModuleRegistry ──🔴──→ Plane module
  CalculatorModules/CalculatorModuleRegistry ──🔴──→ Space module
```

---

## 6. Circular Dependency Findings

### Finding 1: WorkspaceKit → Plane Services (CRITICAL)

**Files involved:**
- `WorkspaceKit/WorkspaceState.swift` calls:
  - `PlaneGeometryDependencyRecomputeService.dependencyPatches()` (line 370)
  - `PlaneGeometryDependencyRecomputeService.dependencyCleanupPatchesForRemovedSources()` (line 469)
  - `PlaneGeometryDependencyRecomputeService.directlyAffectedDerivedObjectIDs()` (line 485)
  - `PlaneGeometryDependencyRecomputeService.downstreamAffectedDerivedObjectIDs()` (line 492)
  - `PlaneSemanticGraphIntentAdapter.semanticGraphKind()` (lines 1229, 1271)
  - `PlaneSemanticGraphIntentAdapter.parameterSymbol()` (lines 1232, 1274)
  - `PlaneSemanticGraphIntentAdapter.parameterRange()` (lines 1235, 1277)
  - `canonicalPlaneCommitInput()` method (line 1666) — Plane-specific logic embedded in WorkspaceState

**Impact:** WorkspaceKit cannot be a standalone package. It is tightly coupled to Plane calculator module internals.

**Fix strategy (to document, not execute):**
1. Define `GeometryDependencyServiceProtocol` in WorkspaceKit with methods `dependencyPatches`, `dependencyCleanupPatchesForRemovedSources`, `directlyAffectedDerivedObjectIDs`, `downstreamAffectedDerivedObjectIDs`.
2. Define `SemanticIntentAdapterProtocol` in WorkspaceKit with methods `semanticGraphKind`, `parameterSymbol`, `parameterRange`.
3. Define `InputCanonicalizationProtocol` for the `canonicalPlaneCommitInput` logic.
4. Have `WorkspaceModuleProviding` return implementations of these protocols.
5. Plane module conforms to these protocols, registers via the module provider.

### Finding 2: DocumentSystem → Plane Services (HIGH)

**File involved:** `DocumentSystem/Preview/ProjectPreviewRenderer.swift`

Direct calls to:
- `PlaneGeometryResolver.pointPosition()`, `.segmentEndpoints()`, `.linePoints()`, `.rayPoints()`, `.circleGeometry()`, `.lineLikePoints()`
- `PlaneLineClipping.clipInfiniteLine()`, `.clipRay()`
- `PlaneSemanticIntentResolver.resolveIntentResult()`
- `PlaneFallbackSamplingService.sampler()`, `.limitSegmentsIfNeeded()`
- `PlaneSampleSetAdapter.adaptToPlotSegments()`

**Impact:** DocumentSystem cannot be a standalone package. Preview rendering depends on Plane-specific geometry resolution.

**Fix strategy:**
1. Move `ProjectPreviewRenderer` to a new module (e.g., `EMathicaPreviewKit` or `CoreHome/Preview/`).
2. OR: Define a `GeometryPreviewProvider` protocol in DocumentSystem, implemented by calculator modules.

### Finding 3: WorkspaceKit ↔ CalculatorModules type entanglement (MEDIUM)

**File involved:** `WorkspaceKit/WorkspaceModuleProviding.swift` (lines 17-18)

```swift
var spaceCameraState: SpaceCameraState?   // ✅ Defined in MathCore
var spaceWorkPlane: SpaceWorkPlane?       // 🔴 Defined in CalculatorModules/Space/Models/
```

**Impact:** `SpaceWorkPlane` enum is defined in the wrong layer. `SpaceCameraState` (correctly in MathCore) shows the right pattern.

**Fix strategy:** Move `SpaceWorkPlane` enum from `CalculatorModules/Space/Models/SpaceWorkPlane.swift` to `MathCore/Coordinate/SpaceMath3D.swift` (alongside `SpaceCameraState`).

### Finding 4: CalculatorModuleRegistry hardcodes module providers (MEDIUM)

**File involved:** `CalculatorModules/CalculatorModuleRegistry.swift` (lines 22-29)

```swift
static func moduleProvider(for id: CalculatorModuleType) -> WorkspaceModuleProviding {
    switch id {
    case .plane: return PlaneWorkspaceModuleProvider()
    case .space: return SpaceWorkspaceModuleProvider()
    case .modeling, .music, .data, .notes: return DefaultWorkspaceModuleProvider(...)
    }
}
```

**Impact:** The base CalculatorModules registry directly instantiates Plane and Space providers. This is a dependency from the abstract registry to concrete modules.

**Fix strategy:** Use a registration pattern — each module registers its provider at app startup. The registry only stores a dictionary `[CalculatorModuleType: WorkspaceModuleProviding]`.

### Finding 5: WorkspaceView depends on AppNavigationState (MEDIUM)

**File involved:** `WorkspaceKit/WorkspaceView.swift` (line 4)

```swift
@Environment(AppNavigationState.self) private var navigation
```

**Impact:** WorkspaceKit depends on the App module's navigation type. This prevents WorkspaceKit from being used in other app targets without the specific App module.

**Fix strategy:** Define a `WorkspaceNavigationDelegate` protocol in WorkspaceKit. App module implements it. Inject via environment or configuration.

### Finding 6: MathCore does NOT depend on SwiftUI ✅ (NO ISSUE)

MathCore only imports Foundation and CoreGraphics. No SwiftUI, UIKit, or AppKit imports. This is clean.

### Finding 7: MathCore does NOT depend on WorkspaceKit ✅ (NO ISSUE)

No cross-references from MathCore to WorkspaceKit. Clean separation.

### Finding 8: InputKit (package) does NOT depend on Plane ✅ (NO ISSUE)

The standalone `EMathicaMathInputKit` package has no dependencies on any calculator module. Clean.

### Finding 9: CalculatorModules does NOT pollute MathCore ✅ (NO ISSUE)

CalculatorModules files import `EMathicaMathCore` (correct direction). No reverse imports found.

### Finding 10: App/CoreHome is NOT depended on by lower layers ⚠️ (PARTIAL ISSUE)

- `AppNavigationState` is referenced by `CoreHome` and `WorkspaceKit` — type dependency on App layer exists.
- `EMathicaDocument` is used by `WorkspaceState` — correct direction (DocumentSystem is lower layer).
- No lower-layer code imports App module directly (only via `@Environment` which is a runtime injection, but the type reference still creates a compile-time dependency).

---

## 7. Files Suitable for Immediate Package Extraction

These files have no cross-module contamination and can be moved to packages today:

### To EMathicaMathCore (add to existing package):

| Source file | Reason |
|-------------|--------|
| `MathCore/AlgebraCore/AlgebraAnalysisResult.swift` | Pure Foundation |
| `MathCore/AlgebraCore/AlgebraCore.swift` | Pure Foundation |
| `MathCore/AlgebraCore/AlgebraDisplayFormatter.swift` | Pure Foundation |
| `MathCore/AlgebraCore/AlgebraEvaluator.swift` | Pure Foundation |
| `MathCore/AlgebraCore/AlgebraExpression.swift` | Pure Foundation |
| `MathCore/AlgebraCore/AlgebraLatexFormatter.swift` | Pure Foundation |
| `MathCore/AlgebraCore/Analysis/AlgebraVariableAnalyzer.swift` | Pure Foundation |
| `MathCore/AlgebraCore/Analysis/ConicParametricRewriter.swift` | Pure Foundation |
| `MathCore/AlgebraCore/Analysis/PlaneAlgebraClassifier.swift` | Pure Foundation (misleading name, correct location) |
| `MathCore/AlgebraCore/Analysis/SuperellipseRecognizer.swift` | Pure Foundation |
| `MathCore/AlgebraCore/Parsing/AlgebraLatexLexer.swift` | Pure Foundation |
| `MathCore/AlgebraCore/Parsing/AlgebraLatexParser.swift` | Pure Foundation |
| `MathCore/AlgebraCore/Simplification/AlgebraSimplifier.swift` | Pure Foundation |
| `MathCore/Coordinate/CoordinateTransform.swift` | Foundation + CoreGraphics |
| `MathCore/Coordinate/MathTypes.swift` | Foundation + CoreGraphics |
| `MathCore/Coordinate/SpaceMath3D.swift` | Foundation (already partially in package) |
| `MathCore/Viewport/Viewport.swift` | Foundation |
| `MathCore/CoordinateSystem.swift` | Foundation |
| `MathCore/DependencyGraph.swift` | Foundation |
| `MathCore/MathPoint.swift` | Foundation |
| `MathCore/MathObject.swift` | Foundation (depends on MathExpression, MathStyle, MathPoint) |
| `MathCore/MathObjectType.swift` | Foundation |
| `MathCore/MathExpression.swift` | Foundation (currently imports EMathicaMathCore — remove self-import) |
| `MathCore/MathStyle.swift` | Foundation |
| `MathCore/CanvasState.swift` | Foundation + CoreGraphics (requires CG types) |
| `MathCore/SamplingCore/SamplingIssue.swift` | Foundation (already in package? verify) |
| `MathCore/SamplingCore/SamplingProfileResolver.swift` | Foundation |
| `MathCore/SamplingCore/SamplingQualityProfile.swift` | Foundation |
| `MathCore/SamplingCore/SamplingRange.swift` | Foundation |

### To EMathicaThemeKit (new package):

| Source file | Reason |
|-------------|--------|
| `WorkspaceKit/Shared/ColorToken.swift` | Design tokens (needs platform conditional cleanup) |
| `WorkspaceKit/Shared/WorkspaceTheme.swift` | Theme definition |
| `WorkspaceKit/Shared/GlassComponents.swift` | Glass-morphism UI components |
| `WorkspaceKit/Shared/LiquidGlassButton.swift` | Glass button style |
| `WorkspaceKit/Shared/LiquidGlassIconButton.swift` | Glass icon button |
| `WorkspaceKit/Shared/LiquidGlassInputBar.swift` | Glass input bar |
| `WorkspaceKit/Shared/LiquidGlassPanel.swift` | Glass panel |
| `WorkspaceKit/Shared/FloatingPanelModifier.swift` | Panel modifier |
| `CoreHome/Background/HomeBackgroundTheme.swift` | Background theme tokens |

### To PluginSystem (could be a package, low priority):

| Source file | Reason |
|-------------|--------|
| All 5 PluginSystem files | Pure Foundation, no dependencies |

---

## 8. Files Not Suitable for Immediate Extraction

| File | Blocker | Severity |
|------|---------|----------|
| `WorkspaceKit/WorkspaceState.swift` | 25 references to Plane services. `SpaceWorkPlane` type dependency. `canonicalPlaneCommitInput` method. | 🔴 CRITICAL |
| `WorkspaceKit/WorkspaceView.swift` | `AppNavigationState` environment dependency. | 🔴 HIGH |
| `WorkspaceKit/WorkspaceModuleProviding.swift` | `SpaceWorkPlane` type dependency (defined in CalculatorModules/Space). | 🟡 MEDIUM |
| `WorkspaceKit/WorkspaceConfiguration.swift` | `.make()` calls `CalculatorModuleRegistry.moduleProvider()` which hardcodes Plane/Space providers. | 🟡 MEDIUM |
| `DocumentSystem/Preview/ProjectPreviewRenderer.swift` | Imports UIKit. Calls 5 different Plane services. | 🔴 HIGH |
| `CalculatorModules/CalculatorModuleRegistry.swift` | Hardcodes Plane/Space provider instantiation. | 🟡 MEDIUM |
| `CalculatorModules/Space/Models/SpaceWorkPlane.swift` | Defined in wrong layer (should be in MathCore). | 🟡 MEDIUM |
| `WorkspaceKit/StructuredInput/*` (all files) | Duplicated with EMathicaInputKit package. Integration layer entangled with WorkspaceState. | 🟡 MEDIUM |

---

## 9. Recommended Extraction Order

Based on dependency analysis, the recommended order is:

### Step 1: EMathicaMathCore ✅ COMPLETED (2026-06-05)

**Current status:** All 73 MathCore files now in the package. Package builds and all 334 tests pass.

**Completed actions:**
- Added AlgebraCore/ (13 files), Coordinate/ (2 files, skip SpaceMath3D duplicate), Viewport/ (1 file), 8 root-level model files
- Copied `GeometryDefinition.swift` from DocumentSystem into package (needed by MathObject)
- Removed `import EMathicaMathCore` self-reference from MathExpression.swift
- Added `Sendable` conformance to WorldPoint, WorldVector, WorldRect, GeometryAnchor, GeometryDefinition
- Removed `Sendable` from DeletedObjectRecord (until MathObject gains full Sendable support)
- `swift build` passes. `swift test` passes (334 tests, 8 suites).

**Remaining:** App's MathCore/ directory still contains duplicate copies (used by app's Xcode target). When app adopts package, these duplicates should be removed. `Coordinate/SpaceMath3D.swift` exists as `SpaceMathCore/SpaceMath3D.swift` in the package — identical, no action needed.

### Step 2: EMathicaThemeKit ✅ CAN PROCEED (after Step 1)

**Current status:** No package exists yet.

**Blockers:** None. ThemeKit has no dependencies on MathCore or other modules.

**Action:** Create new package. Move glass components, color tokens, theme from WorkspaceKit/Shared. These are pure SwiftUI with no math dependencies.

### Step 3: EMathicaInputKit (reconciliation) ⏸️ BLOCKED by app integration

**Current status:** Standalone package exists but is NOT integrated into the main app. App has duplicate code in `WorkspaceKit/StructuredInput/`.

**Blockers:**
- App's `WorkspaceKit/StructuredInput/` needs migration to use the package.
- Package's `MathEditorAST` needs `Codable` conformance (used by `FormulaInputState+Sync`).
- `MathNodeSemanticLowering` bridges between the input AST and EMathicaMathCore — this integration layer must stay in WorkspaceKit.

**Recommendation:** Do this AFTER WorkspaceKit is decoupled from Plane (Step 4), because the StructuredInput integration is entangled with WorkspaceState.

### Step 4: EMathicaWorkspaceKit 🔴 BLOCKED — requires significant decoupling

**Must resolve before extraction:**
1. Remove all Plane service references from WorkspaceState (protocol-ify)
2. Move SpaceWorkPlane enum to MathCore
3. Remove AppNavigationState dependency from WorkspaceView
4. Decouple WorkspaceConfiguration from CalculatorModuleRegistry

**This is the hardest step and should NOT be attempted first.**

### Step 5: EMathicaDocumentKit 🔴 BLOCKED — requires decoupling ProjectPreviewRenderer

**Must resolve before extraction:**
1. Move or refactor `ProjectPreviewRenderer.swift` to remove Plane service calls
2. Remove UIKit dependency from DocumentSystem

### Recommended actual order (revised from ideal):

```
Step 1: EMathicaMathCore (complete the extraction)     ← 🟢 READY NOW
Step 2: EMathicaThemeKit (create new package)          ← 🟢 READY NOW
Step 3: Decouple WorkspaceKit from Plane/Space         ← 🔴 PREREQUISITE WORK
Step 4: EMathicaInputKit reconciliation                ← 🟡 AFTER Step 3
Step 5: EMathicaWorkspaceKit                           ← 🔴 AFTER Step 3
Step 6: EMathicaDocumentKit                            ← 🔴 AFTER Step 3
```

---

## 10. Minimal Next Step

The smallest, highest-value next action is:

**Complete the EMathicaMathCore package extraction.**

This involves:
1. Add all files listed in Section 7 "To EMathicaMathCore" to the existing package at `eMathica/eMathica/Packages/EMathicaMathCore/`.
2. Fix `MathExpression.swift` — it currently imports `EMathicaMathCore` (self). Remove that import once the file is inside the package.
3. Verify the package builds independently with `swift build` in the package directory.
4. Update the main app target to use the package for all MathCore types instead of the in-tree copies.

**Estimated effort:** Low. Most files are drop-in additions to an already-working package.

**Risk:** Minimal. The existing package already has tests. Adding more files doesn't break existing functionality.

---

## 11. Do-Not-Touch List

Per audit constraints, the following must NOT be modified during this phase:

| Item | Reason |
|------|--------|
| Any `.swift` source file | Audit constraint |
| `eMathica.xcodeproj` | Xcode project config |
| `Package.swift` files | Package config |
| File locations / directory structure | No file moves |
| `CalculatorModules/Plane/Services/*` | Business logic — decoupling must be planned before execution |
| `WorkspaceKit/WorkspaceState.swift` | Central state — refactoring requires careful planning |
| `DocumentSystem/Preview/ProjectPreviewRenderer.swift` | Preview logic — refactoring requires careful planning |

**Only this document (`Docs/SwiftPackageSplitAudit.md`) is new.**

---

## Appendix A: File Count Summary

| Module | Swift Files | Lines (est.) | Has Tests? |
|--------|------------|--------------|------------|
| MathCore | ~60 | ~8000 | Yes (in package) |
| WorkspaceKit | ~60 | ~10000 | No |
| DocumentSystem | 13 | ~2000 | No |
| PluginSystem | 5 | ~100 | No |
| CalculatorModules/Plane | 30 | ~5000 | No |
| CalculatorModules/Space | 10 | ~1500 | No |
| CalculatorModules/Other | 5 | ~100 | No |
| CoreHome | 26 | ~3000 | No |
| App | 5 | ~200 | No |
| **Total** | **~204** | **~30000** | |

## Appendix B: Existing Package Coverage vs App Code

| Package | Files in Package | Duplicate files in App? | Integrated into App? |
|---------|-----------------|------------------------|---------------------|
| EMathicaMathCore | ~40 | Yes (app has same files in MathCore/) | ⚠️ Partial — `WorkspaceState` imports it, but app also compiles MathCore/ directory |
| EMathicaMathInputKit | 7 | Yes (app has similar files in WorkspaceKit/StructuredInput/) | 🔴 No — package exists but app uses its own copies |
