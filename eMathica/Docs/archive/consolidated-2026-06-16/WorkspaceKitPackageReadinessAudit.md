# WorkspaceKit Package Readiness Audit

> **Date:** 2026-06-05  
> **Scope:** Read-only audit — no code modified, no files moved.  
> **Prerequisites completed:**
> - EMathicaMathCore Package extraction (73 files, 334 tests passing)
> - WorkspaceState → Plane service protocol migration (25 call sites migrated)
> - WorkspaceView → AppNavigationState decoupling (2 call sites migrated)
> - SpaceWorkPlane relocation to MathCore

---

## 1. Current State Summary

### 1.1 File Inventory (71 files, ~10,000 lines)

| Directory | Files | SwiftUI? | UIKit/AppKit? | Foundation-only |
|-----------|-------|----------|---------------|-----------------|
| Commands/ | 2 | 0 | 0 | 2 |
| Tools/ | 6 | 1 | 0 | 5 |
| Input/ | 6 | 3 | 2 | 3 |
| Keyboard/ | 8 | 3 | 0 | 5 |
| StructuredInput/ | 13 | 0 | 0 | 13 |
| Inspector/ | 4 | 2 | 0 | 2 |
| ObjectPanel/ | 5 | 3 | 1 | 2 |
| Toolbar/ | 3 | 3 | 0 | 0 |
| History/ | 3 | 1 | 0 | 2 |
| Shared/ | 13 | 11 | 1 | 2 |
| Protocols/ | 6 | 0 | 0 | 6 |
| Root (5 files) | 5 | 3 | 0 | 2 |
| **Total** | **71** | **29** | **3** | **42** |

### 1.2 Dependency Scan Results

| Target | Result |
|--------|--------|
| `AppNavigationState` (code refs) | ✅ **ZERO** — only in doc comment |
| `CalculatorModules/` (path refs) | ✅ **ZERO** |
| `Plane*Service` / `PlaneSemantic*` | ✅ **ZERO** — all migrated to protocols |
| `Space/` (module path) | ✅ **ZERO** |
| `CoreHome/` | ✅ **ZERO** — only in doc comment |
| `DocumentSystem/` (path refs) | ✅ **ZERO** |
| `ProjectPreviewRenderer` | ✅ **ZERO** |
| `ProjectStore` / `LocalProjectStore` | ✅ **ZERO** |
| `canonicalPlaneCommitInput` (call sites) | ✅ **ZERO** — dead method only |

### 1.3 Remaining Type Dependencies (via type usage, not import paths)

These types are used in WorkspaceKit but defined outside it:

| Type | Defined In | Used In (WorkspaceKit files) | Blocker for Package? |
|------|-----------|------------------------------|---------------------|
| `CalculatorModuleType` | `CalculatorModules/CalculatorModuleType.swift` | WorkspaceState, WorkspaceView, WorkspaceConfiguration, WorkspaceModuleProviding, WorkspaceToolContext | 🔴 YES |
| `CalculatorModuleRegistry` | `CalculatorModules/CalculatorModuleRegistry.swift` | WorkspaceConfiguration (line 31: `.make()`) | 🟡 Partial |
| `EMathicaDocument` | `DocumentSystem/EMathicaDocument.swift` | WorkspaceState, WorkspaceView, WorkspaceModuleProviding, WorkspaceToolContext, Protocols | 🔴 YES |
| `DocumentCommand` | `DocumentSystem/DocumentCommand.swift` | WorkspaceState | 🔴 YES |
| `DocumentObjectPatch` | `DocumentSystem/DocumentObjectPatch.swift` | WorkspaceState, GeometryDependencyServiceProtocol | 🔴 YES |
| `RecentProject` | `DocumentSystem/RecentProject.swift` | WorkspaceState, WorkspaceNavigationDelegate | 🔴 YES |

---

## 2. Blocking Dependencies Analysis

### 2.1 🔴 CalculatorModuleType — MUST move into WorkspaceKit

`CalculatorModuleType` is a simple enum (6 cases, `String` RawRepresentable, `CaseIterable`, `Identifiable`, `Codable`):

```swift
enum CalculatorModuleType: String, CaseIterable, Identifiable, Codable {
    case plane, space, modeling, music, data, notes
    var id: String { rawValue }
}
```

**Why it must move:** WorkspaceKit's core abstractions (`WorkspaceModuleProviding`, `WorkspaceState`, `WorkspaceView`) all reference this type. Without it, WorkspaceKit has no concept of "which module is active."

**Recommendation:** Move `CalculatorModuleType.swift` from `CalculatorModules/` to `WorkspaceKit/`. It's a pure data type with zero dependencies. The `CalculatorModules/` code already imports nothing but Foundation — it will work unchanged.

### 2.2 🟡 CalculatorModuleRegistry — factory dependency

`WorkspaceConfiguration.make(for:)` at line 31 calls `CalculatorModuleRegistry.moduleProvider(for: module)`. This is the factory that creates `PlaneWorkspaceModuleProvider()` or `SpaceWorkspaceModuleProvider()`.

**Why it's only partial:** `WorkspaceConfiguration.make(for:)` is a *convenience* factory. WorkspaceView already accepts a `WorkspaceConfiguration` directly. The `CalculatorModuleRegistry` call is only in the convenience init path.

**Recommendation:** Remove the `.make(for:)` static method from `WorkspaceConfiguration`. Callers use `CalculatorModuleRegistry.moduleProvider(for:)` to create a `WorkspaceModuleProviding`, then pass tool groups directly to `WorkspaceConfiguration.init(module:moduleProvider:toolGroups:...)`. This is already how the non-convenience path works.

### 2.3 🔴 DocumentSystem types — require DocumentKit extraction

WorkspaceKit uses:
- `EMathicaDocument` — the document model
- `DocumentCommand` — command pattern for mutations
- `DocumentObjectPatch` — partial update descriptor
- `RecentProject` — project metadata

**Problem:** These are all in `DocumentSystem/`. WorkspaceKit cannot be a standalone package without access to these types.

**Options:**
1. **Extract EMathicaDocumentKit first** — include EMathicaDocument, DocumentCommand, DocumentObjectPatch, RecentProject, and GeometryDefinition (already in MathCore). WorkspaceKit then depends on DocumentKit.
2. **Move these types into MathCore** — they're pure data types with no UI dependencies. But this expands MathCore beyond "math."
3. **Duplicate the types** — bad practice, avoid.

**Recommendation:** Option 1. Extract a lean `EMathicaDocumentKit` package containing the 4 files above + `ProjectMetadata`, `ProjectPackageStructure`, `DocumentObjectPatch`, `GeometryDefinition`. This is ~8 files, all Foundation-only, no UI. Then WorkspaceKit depends on EMathicaDocumentKit.

---

## 3. StructuredInput — Overlap Analysis

### 3.1 Files with direct overlap with EMathicaMathInputKit

| App File (WorkspaceKit/StructuredInput/) | Package File (EMathicaMathInputKit) | Status |
|------------------------------------------|--------------------------------------|--------|
| `MathEditorAST.swift` | `Sources/.../AST/MathEditorAST.swift` | 🔴 Divergent copies |
| `MathEditorEngine.swift` | `Sources/.../Engine/MathEditorEngine.swift` | 🔴 Divergent copies |
| `MathEditorSerialization.swift` | `Sources/.../Serialization/MathEditorSerialization.swift` | 🔴 Divergent copies |
| `MathEditorState.swift` | `Sources/.../AST/MathEditorState.swift` | 🔴 Divergent copies |
| `TemplateDefinition.swift` | `Sources/.../Engine/TemplateDefinition.swift` | 🔴 Divergent copies |
| `MathInputCharacterNormalizer.swift` | `Sources/.../Serialization/MathInputCharacterNormalizer.swift` | 🔴 Divergent copies |

### 3.2 Integration-only files (no overlap)

| File | Purpose | Keep in WorkspaceKit? |
|------|---------|----------------------|
| `FormulaInputState+Sync.swift` | Bridges editor state ↔ WorkspaceKit formula state | ✅ Yes — WorkspaceKit integration |
| `FormulaSemanticState.swift` | Captures semantic analysis results | ✅ Yes — WorkspaceKit-specific |
| `FormulaSemanticState+Debug.swift` | Debug helpers | ✅ Yes |
| `FormulaDiagnosticPresenter.swift` | Presents formula diagnostics as UI data | ✅ Yes |
| `FormulaPlotDiagnostic.swift` | Plot-specific diagnostics | ✅ Yes |
| `MathNodeSemanticLowering.swift` | Lowers editor AST to MathCore Expr | ✅ Yes — bridges InputKit ↔ MathCore |
| `EditorCursorNavigator.swift` | Cursor navigation in editor | ✅ Yes |

### 3.3 Recommendation

**Do NOT attempt to reconcile InputKit during WorkspaceKit extraction.** The overlap is a separate concern. For WorkspaceKit package extraction:
- Keep ALL 13 StructuredInput files in WorkspaceKit
- After WorkspaceKit and InputKit are both packages, add `EMathicaMathInputKit` as a dependency of WorkspaceKit
- Then migrate the 6 overlapping files to use the package versions
- The 7 integration files stay in WorkspaceKit as the bridge layer

---

## 4. Shared — ThemeKit Candidate Analysis

### 4.1 Candidates for EMathicaThemeKit

| File | Lines | Dependencies | Move to ThemeKit? |
|------|-------|-------------|-------------------|
| `ColorToken.swift` | ~100 | UIKit/AppKit (conditional), SwiftUI | ✅ YES |
| `WorkspaceTheme.swift` | ~30 | SwiftUI | ✅ YES |
| `GlassComponents.swift` | ~80 | SwiftUI | ✅ YES |
| `LiquidGlassButton.swift` | ~60 | SwiftUI | ✅ YES |
| `LiquidGlassIconButton.swift` | ~40 | SwiftUI | ✅ YES |
| `LiquidGlassInputBar.swift` | ~50 | SwiftUI | ✅ YES |
| `LiquidGlassPanel.swift` | ~50 | SwiftUI | ✅ YES |
| `FloatingPanelModifier.swift` | ~40 | SwiftUI | ✅ YES |
| `AdaptiveWorkspaceMetrics.swift` | ~60 | SwiftUI | ✅ YES |

### 4.2 Files that should STAY in WorkspaceKit

| File | Reason |
|------|--------|
| `GeometryPropertyFormatter.swift` | Depends on `EMathicaMathCore` for `MathObject` formatting |
| `SpaceGeometryPropertyFormatter.swift` | Depends on `EMathicaMathCore` for 3D geometry |
| `ModuleIconView.swift` | Depends on `CalculatorModuleType` (WorkspaceKit type) |
| `ModuleAssetIconView.swift` | Depends on `CalculatorModuleType` (WorkspaceKit type) |

### 4.3 Dependency Direction

```
EMathicaThemeKit (zero deps besides SwiftUI)
        ↑
EMathicaWorkspaceKit (depends on ThemeKit for glass components)
```

This is the correct direction — ThemeKit is a leaf node, WorkspaceKit depends on it.

---

## 5. WorkspaceState Responsibility Audit

### 5.1 Size: 1,835 lines, 84 methods, 61 computed properties

### 5.2 Responsibilities identified

| Responsibility | Methods | Lines (est.) | In correct place? |
|---------------|---------|-------------|-------------------|
| Document mutation | `performRecordedDocumentMutation`, `applyGeometryDependencyRecompute`, `applyGeometryDependencyCleanup`, `requestDeleteObjects*` | ~200 | ✅ Yes |
| Input/Formula state | `submitInput`, `submitEditingObject`, `attachStructuredInputMetadata`, `inputState`, `editableExpression`, `beginEditingObjectExpression`, `cancelFormulaEditing` | ~400 | ✅ Yes |
| Draft preview | `refreshDraftPreview`, draft preview task management | ~80 | ✅ Yes |
| Tool/Selection | `selectObject`, `clearSelection`, tool dispatch | ~80 | ✅ Yes |
| Undo/Redo | `undo`, `redo`, `revertToOpenState`, `pushUndoSnapshot` | ~150 | ✅ Yes |
| Geometry dependency | `directlyAffectedDerivedObjectIDs`, `downstreamAffectedDerivedObjectIDs`, `isLineLike` | ~60 | ✅ Yes |
| Slider/Parameter | `updateParameter`, `toggleSliderPlayback`, `isSliderPlaying`, slider playback task | ~150 | 🟡 Borderline — could be a sub-controller |
| Object style | `updateObjectStyle`, style dispatch | ~40 | ✅ Yes |
| Deletion history | `appendDeletedObjectRecords`, `restoreDeletedObject`, deletion context | ~100 | 🟡 Borderline |
| Semantic metadata | `applySemanticIntentMetadata` | ~15 | ✅ Yes (new helper) |
| Rename | `renameCurrentProject` | ~20 | ✅ Yes |
| Canvas state | `setCanvasViewport`, `setCanvasInteracting`, `canvasPixelSize` | ~40 | ✅ Yes |
| Space state | `setSpaceCameraState`, `setSpaceWorkPlane` | ~30 | ✅ Yes |

### 5.3 Verdict

WorkspaceState is large but not bloated. Most responsibilities are correctly placed. The two borderline areas (slider playback, deletion history) could be extracted into sub-controllers in a future refactor, but this is NOT a blocker for Package extraction. They're all WorkspaceKit-level concerns.

---

## 6. Import/Dependency Profile

### 6.1 All imports in WorkspaceKit (deduplicated)

```
Foundation          — 42 files
SwiftUI             — 29 files
EMathicaMathCore    — 12 files
CoreGraphics        —  5 files
Observation         —  2 files
UIKit (conditional) —  2 files
AppKit (conditional)—  1 file
```

### 6.2 Package.swift dependency requirements

```swift
dependencies: [
    .package(path: "../EMathicaMathCore"),
    .package(path: "../EMathicaThemeKit"),       // after ThemeKit extraction
    .package(path: "../EMathicaDocumentKit"),     // after DocumentKit extraction
]
```

UIKit/AppKit imports are conditional (`#if canImport(UIKit)`) — this is standard SwiftPM practice for cross-platform packages.

---

## 7. Recommended Split Plan

### Plan A: EMathicaThemeKit (10 files, ZERO blockers)

**Can be extracted NOW.** All files are self-contained SwiftUI views/styles with no dependencies on MathCore, DocumentSystem, or any app-specific type.

| File | Source |
|------|--------|
| `ColorToken.swift` | WorkspaceKit/Shared/ |
| `WorkspaceTheme.swift` | WorkspaceKit/Shared/ |
| `GlassComponents.swift` | WorkspaceKit/Shared/ |
| `LiquidGlassButton.swift` | WorkspaceKit/Shared/ |
| `LiquidGlassIconButton.swift` | WorkspaceKit/Shared/ |
| `LiquidGlassInputBar.swift` | WorkspaceKit/Shared/ |
| `LiquidGlassPanel.swift` | WorkspaceKit/Shared/ |
| `FloatingPanelModifier.swift` | WorkspaceKit/Shared/ |
| `AdaptiveWorkspaceMetrics.swift` | WorkspaceKit/Shared/ |
| `HomeBackgroundTheme.swift` | CoreHome/Background/ |

**Package.swift dependencies:** None (SwiftUI only). No MathCore, no DocumentSystem.

**Risk:** 🟢 Minimal. These are leaf-node visual components.

### Plan B: EMathicaDocumentKit (8 files, 1 blocker)

**Blocker:** `ProjectPreviewRenderer.swift` imports UIKit and calls Plane services. Must be moved out of DocumentSystem first (or left behind in the app).

**Files to include:**

| File | Ready? |
|------|--------|
| `EMathicaDocument.swift` | ✅ |
| `DocumentCommand.swift` | ✅ |
| `DocumentObjectPatch.swift` | ✅ |
| `RecentProject.swift` | ✅ |
| `ProjectMetadata.swift` | ✅ |
| `ProjectPackageStructure.swift` | ✅ |
| `GeometryDefinition.swift` | ✅ (already in MathCore too) |
| `ProjectStore.swift` (protocol) | ✅ |
| `ProjectStoreError.swift` | ✅ |
| `LocalProjectStore.swift` | 🟡 (FileManager dependency, but no UI) |
| `EMathicaPackageCodec.swift` | ✅ |
| `EMathicaPackageLayout.swift` | ✅ |
| `ProjectFileManagerPlaceholder.swift` | ✅ |
| `ProjectPreviewRenderer.swift` | 🔴 MUST leave behind |

**Package.swift dependencies:**
```swift
dependencies: [
    .package(path: "../EMathicaMathCore"),
]
```

### Plan C: EMathicaWorkspaceKit (remaining ~55 files, 2 blockers)

**Blocker 1:** `CalculatorModuleType` must move INTO WorkspaceKit (or be in a shared types package).

**Blocker 2:** `WorkspaceConfiguration.make(for:)` references `CalculatorModuleRegistry` — remove this convenience method or inject the registry via a protocol.

**Files to include (after blockers resolved):**

| Group | Files | Status |
|-------|-------|--------|
| Protocols/ | 6 files | ✅ Ready |
| Commands/ | 2 files | ✅ Ready |
| Tools/ | 6 files | ✅ Ready (except GeometryToolIconView needs ThemeKit or local icon) |
| Input/ | 6 files | ✅ Ready |
| Keyboard/ | 8 files | ✅ Ready |
| StructuredInput/ | 13 files | ✅ Ready (keep all, reconcile with InputKit later) |
| Inspector/ | 4 files | ✅ Ready |
| ObjectPanel/ | 5 files | ✅ Ready |
| Toolbar/ | 3 files | ✅ Ready |
| History/ | 3 files | ✅ Ready |
| Shared/ (remaining) | 4 files | ✅ Ready: GeometryPropertyFormatter, SpaceGeometryPropertyFormatter, ModuleIconView, ModuleAssetIconView |
| WorkspaceState.swift | 1 file | ✅ Ready |
| WorkspaceView.swift | 1 file | ✅ Ready |
| WorkspaceLayout.swift | 1 file | ✅ Ready |
| WorkspaceConfiguration.swift | 1 file | 🟡 Remove `.make(for:)` |
| WorkspaceModuleProviding.swift | 1 file | ✅ Ready |

**Package.swift dependencies (after all extractions):**
```swift
dependencies: [
    .package(path: "../EMathicaMathCore"),
    .package(path: "../EMathicaThemeKit"),
    .package(path: "../EMathicaDocumentKit"),
    // Future:
    // .package(path: "../EMathicaMathInputKit"),
]
```

---

## 8. Recommended Extraction Order (revised)

```
Phase 1: EMathicaMathCore       ✅ DONE (73 files, 334 tests)
Phase 2: EMathicaThemeKit       🟢 READY NOW (10 files, zero blockers)
Phase 3: EMathicaDocumentKit    🟡 NEEDS 1 fix (move ProjectPreviewRenderer out)
Phase 4: EMathicaWorkspaceKit   🟡 NEEDS 2 fixes (CalculatorModuleType move + registry decouple)
Phase 5: EMathicaInputKit       ⏸️ reconcile with WorkspaceKit/StructuredInput
```

---

## 9. Items NOT Ready for Package Extraction

| File / Group | Reason |
|-------------|--------|
| `DocumentSystem/Preview/ProjectPreviewRenderer.swift` | Imports UIKit, calls Plane services directly (PlaneGeometryResolver, PlaneLineClipping, PlaneSemanticIntentResolver, PlaneFallbackSamplingService, PlaneSampleSetAdapter) |
| `CalculatorModules/CalculatorModuleRegistry.swift` | Hardcodes Plane/Space provider instantiation. Must be refactored to registration pattern OR left in app layer. |
| `WorkspaceKit/StructuredInput/*` (6 overlapping files) | Divergent from EMathicaMathInputKit package. Reconciliation needed before either can be the single source of truth. |

---

## 10. Next Minimal Code Tasks

### Task A: EMathicaThemeKit extraction (recommended first)

**Scope:** Move 10 files into a new Swift Package.

**Files to move:**
- `WorkspaceKit/Shared/ColorToken.swift`
- `WorkspaceKit/Shared/WorkspaceTheme.swift`
- `WorkspaceKit/Shared/GlassComponents.swift`
- `WorkspaceKit/Shared/LiquidGlassButton.swift`
- `WorkspaceKit/Shared/LiquidGlassIconButton.swift`
- `WorkspaceKit/Shared/LiquidGlassInputBar.swift`
- `WorkspaceKit/Shared/LiquidGlassPanel.swift`
- `WorkspaceKit/Shared/FloatingPanelModifier.swift`
- `WorkspaceKit/Shared/AdaptiveWorkspaceMetrics.swift`
- `CoreHome/Background/HomeBackgroundTheme.swift`

**Blocker count:** 0.  
**Risk:** 🟢 Low.  
**Estimated effort:** 30 minutes.

### Task B: CalculatorModuleType relocation (unblocks WorkspaceKit)

**Scope:** Move `CalculatorModules/CalculatorModuleType.swift` → `WorkspaceKit/CalculatorModuleType.swift`.

**Blocker count:** 0 (all references are already in WorkspaceKit or modules that access it through WorkspaceKit).  
**Risk:** 🟢 Low.  
**Estimated effort:** 10 minutes.

### Task C: WorkspaceConfiguration decoupling (unblocks WorkspaceKit)

**Scope:** Remove `WorkspaceConfiguration.make(for:)` static method. Update callers to use direct init + `CalculatorModuleRegistry`.

**Blocker count:** 0.  
**Risk:** 🟢 Low.  
**Estimated effort:** 15 minutes.

### Task D: DocumentKit extraction (unblocks WorkspaceKit)

**Scope:** Extract DocumentSystem minus ProjectPreviewRenderer into `EMathicaDocumentKit` package.

**Blocker count:** 1 (ProjectPreviewRenderer).  
**Risk:** 🟡 Medium.  
**Estimated effort:** 1 hour.

---

## 11. Dependency Map After All Extractions

```
┌─────────────────────────────────────────────────────┐
│  App Target (entry point, DI composition)            │
│  - EMathicaApp, AppNavigationState, AppRootView      │
│  - CoreHome (home screen UI)                         │
│  - CalculatorModules (Plane, Space, etc.)            │
│  - DocumentSystem/Preview/ProjectPreviewRenderer     │
│  - CalculatorModuleRegistry (provider registration)  │
└──────────┬──────────┬──────────┬────────────────────┘
           │          │          │
           ▼          ▼          ▼
┌──────────────┐ ┌──────────┐ ┌──────────────────────┐
│ ThemeKit     │ │DocumentKit│ │ WorkspaceKit         │
│ (SwiftUI)    │ │(Foundation│ │ (SwiftUI + Foundation│
│              │ │ +MathCore)│ │  +ThemeKit+DocumentKit│
│ glass, color │ │ document, │ │ tools, input,        │
│ theme tokens │ │ commands, │ │ keyboard, inspector, │
│              │ │ codec     │ │ object panel, history│
└──────────────┘ └────┬──────┘ └──────────┬───────────┘
                      │                  │
                      ▼                  ▼
              ┌──────────────────────────────────┐
              │  EMathicaMathCore (Foundation)    │
              │  AST, CAS, Evaluation, Sampling,  │
              │  Algebra, Graph, SpaceMath3D      │
              └──────────────────────────────────┘

Future:
  EMathicaInputKit ←── WorkspaceKit (after reconciliation)
```

---

## Appendix A: File-by-File Readiness Matrix

### WorkspaceKit files — Ready for Package NOW

| File | Reason |
|------|--------|
| Protocols/ (all 6) | Pure protocols, Foundation-only |
| Commands/ (both) | Foundation-only, no app deps |
| Tools/ (5 of 6) | Foundation-only tool definitions |
| Input/ (3 Foundation-only) | FormulaEditSession, DraftMathObject, ParameterSuggestionAnalyzer |
| Input/ (3 SwiftUI) | MathPlainTextField, HardwareKeyboardCaptureView, ExpressionInputBarView |
| Keyboard/ (all 8) | Formula input state + views |
| StructuredInput/ (all 13) | Keep all for now, reconcile with InputKit later |
| Inspector/ (all 4) | Inspector panel + property presenters |
| ObjectPanel/ (all 5) | Object list views |
| Toolbar/ (all 3) | Toolbar views |
| History/ (all 3) | Undo/redo history |
| Shared/GeometryPropertyFormatter.swift | MathCore-dependent formatter |
| Shared/SpaceGeometryPropertyFormatter.swift | MathCore-dependent 3D formatter |
| Shared/ModuleIconView.swift | Icon views (depends on CalculatorModuleType) |
| Shared/ModuleAssetIconView.swift | Icon views (depends on CalculatorModuleType) |
| WorkspaceState.swift | Core state (Foundation + Observation + EMathicaMathCore) |
| WorkspaceView.swift | Main workspace view |
| WorkspaceLayout.swift | Layout metrics |
| WorkspaceConfiguration.swift | 🟡 Remove `.make(for:)` first |
| WorkspaceModuleProviding.swift | Protocol + context types |

### WorkspaceKit files — Move to ThemeKit

| File | Reason |
|------|--------|
| Shared/ColorToken.swift | Design token, no math deps |
| Shared/WorkspaceTheme.swift | Theme, no math deps |
| Shared/GlassComponents.swift | Glass style, no math deps |
| Shared/LiquidGlassButton.swift | Glass button, no math deps |
| Shared/LiquidGlassIconButton.swift | Glass icon, no math deps |
| Shared/LiquidGlassInputBar.swift | Glass input, no math deps |
| Shared/LiquidGlassPanel.swift | Glass panel, no math deps |
| Shared/FloatingPanelModifier.swift | Panel modifier, no math deps |
| Shared/AdaptiveWorkspaceMetrics.swift | Metrics, no math deps |

### Files to leave in App (NOT for Package)

| File | Reason |
|------|--------|
| DocumentSystem/Preview/ProjectPreviewRenderer.swift | UIKit + Plane service calls |
| CalculatorModules/CalculatorModuleRegistry.swift | DI wiring — belongs in app layer |
| CoreHome/ (all files) | App-specific home screen |
| App/ (all files) | App entry point |

---

## Appendix B: Quick-Start Commands for Phase 2 (ThemeKit)

```bash
# Create package structure
mkdir -p Packages/EMathicaThemeKit/Sources/EMathicaThemeKit
mkdir -p Packages/EMathicaThemeKit/Tests/EMathicaThemeKitTests

# Package.swift — zero dependencies
# targets: [.target(name: "EMathicaThemeKit", dependencies: [])]

# Copy files (10 files)
cp WorkspaceKit/Shared/ColorToken.swift Packages/EMathicaThemeKit/Sources/EMathicaThemeKit/
cp WorkspaceKit/Shared/WorkspaceTheme.swift Packages/EMathicaThemeKit/Sources/EMathicaThemeKit/
# ... etc.

# Build
cd Packages/EMathicaThemeKit && swift build
```
