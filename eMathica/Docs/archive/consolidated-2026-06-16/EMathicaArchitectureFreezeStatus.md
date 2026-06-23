# eMathica Architecture Freeze Status

> **Date:** 2026-06-07  
> **Status:** Architecture baseline established. No further structural changes planned.  
> **This document supersedes all earlier audit and plan documents for current state.**

---

## 1. Current Architecture Summary

eMathica 已完成从单体 App 到 **4+1 Package 架构**的迁移。

```
┌──────────────────────────────────────────────────────────────┐
│  App Target "eMathica"                                        │
│  ┌────────────┬──────────────┬───────────────┬─────────────┐ │
│  │ App/ (5)   │ CoreHome/    │ CalculatorMod │ DocumentSys │ │
│  │            │ (30)         │ ules/ (54)    │ tem/ (13)   │ │
│  │ Entry pt   │ Home screen  │ Plane/Space/  │ IO + models │ │
│  │            │              │ Commands/etc  │             │ │
│  └────────────┴──────────────┴───────────────┴─────────────┘ │
│                          │ imports                            │
│         ┌────────────────┼────────────────┐                  │
│         ▼                ▼                 ▼                  │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────┐  │
│  │ ThemeKit     │ │ DocumentKit  │ │ WorkspaceKit         │  │
│  │ (10 files)   │ │ (12 files)   │ │ (68 files)           │  │
│  │ glass/color  │ │ doc model    │ │ tools/keyboard/input │  │
│  └──────────────┘ └──────┬───────┘ └──────────┬───────────┘  │
│                          │                     │              │
│                          ▼                     ▼              │
│                   ┌──────────────────────────────────────┐    │
│                   │ EMathicaMathCore (73 files)           │    │
│                   │ AST/CAS/Evaluation/Sampling/Algebra  │    │
│                   └──────────────────────────────────────┘    │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ EMathicaMathInputKit (8 files)                       │    │
│  │ AST/Engine/Serialization/Cursor/Template/Normalizer  │    │
│  │ ← used by WorkspaceKit via @_exported import         │    │
│  └──────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────┘
```

---

## 2. Active Packages

### 2.1 Package Inventory

| Package | Files | Lines (est.) | Tests | iOS | macOS | Status |
|---------|-------|-------------|-------|-----|-------|--------|
| **EMathicaMathCore** | 73 | ~8,000 | 334 | 16 | 13 | ✅ Active |
| **EMathicaDocumentKit** | 12 | ~1,500 | 1 | 16 | 13 | ✅ Active |
| **EMathicaThemeKit** | 10 | ~800 | 1 | 16 | 13 | ✅ Active |
| **EMathicaWorkspaceKit** | 68 | ~8,500 | 1 | 17 | 14 | ✅ Active |
| **EMathicaMathInputKit** | 8 | ~1,650 | 18 | 17 | 14 | ✅ Active |

### 2.2 Dependency Graph

```
EMathicaWorkspaceKit
├── EMathicaMathCore          (../../eMathica/eMathica/Packages/EMathicaMathCore)
├── EMathicaDocumentKit       (../EMathicaDocumentKit)
├── EMathicaThemeKit          (../EMathicaThemeKit)
└── EMathicaMathInputKit      (../EMathicaMathInputKit)

EMathicaDocumentKit
└── EMathicaMathCore          (../../eMathica/eMathica/Packages/EMathicaMathCore)

EMathicaMathInputKit
└── (zero dependencies — Foundation only)

EMathicaThemeKit
└── (zero dependencies — SwiftUI only)

EMathicaMathCore
└── (zero dependencies — Foundation + CoreGraphics)
```

### 2.3 Xcode Package References

| Package | pbxproj relativePath | Resolves From |
|---------|---------------------|---------------|
| EMathicaMathCore | `Packages/EMathicaMathCore` | Project root (L2) |
| EMathicaDocumentKit | `../../Packages/EMathicaDocumentKit` | xcodeproj dir |
| EMathicaThemeKit | `../../Packages/EMathicaThemeKit` | xcodeproj dir |
| EMathicaWorkspaceKit | `../../Packages/EMathicaWorkspaceKit` | xcodeproj dir |
| EMathicaMathInputKit | Not in pbxproj | Accessed via `@_exported import` in WorkspaceKit |

---

## 3. App Target Dependency Graph

### 3.1 What Gets Compiled

```
Target: eMathica (app)
├── 📁 Source Root (fileSystemSynchronizedGroups)
│   ├── App/                      5 .swift   ✅
│   ├── CoreHome/                30 .swift   ✅
│   ├── CalculatorModules/       54 .swift   ✅
│   │   ├── Plane/               35 files    (Services, Views, Commands, Tools, Interaction)
│   │   ├── Space/                8 files    (Services, Views, Commands, Tools)
│   │   ├── Commands/             2 files    (ModuleCommandHandlerRegistry)
│   │   ├── Data/                 1 file     (PlaceholderView)
│   │   ├── Music/                1 file     (PlaceholderView)
│   │   ├── Notes/                1 file     (PlaceholderView)
│   │   ├── Modeling/             1 file     (PlaceholderView)
│   │   └── root                  5 files    (CalculatorModule, Registry, DefaultProvider)
│   ├── DocumentSystem/          13 .swift   ✅
│   │   └── LocalProjectStore              (stays in-tree, references ProjectPreviewRenderer)
│   ├── PluginSystem/             5 .swift   ✅
│   └── Resources/                assets     ✅
│
├── 📦 packageProductDependencies
│   ├── EMathicaMathCore
│   ├── EMathicaDocumentKit
│   ├── EMathicaThemeKit
│   └── EMathicaWorkspaceKit      (also exports EMathicaMathInputKit)
│
├── Target: eMathicaTests          33 .swift   ✅
└── Target: eMathicaUITests         2 .swift   ✅
```

### 3.2 Deleted Tree Copies

| Directory | Status |
|-----------|--------|
| `MathCore/` | ❌ Deleted (was 73 files, excluded from compilation) |
| `WorkspaceKit/` | ❌ Deleted (was 75 files, excluded from compilation) |

---

## 4. Remaining App-Level Modules

### 4.1 App/ (5 files)

| File | Role |
|------|------|
| `EMathicaApp.swift` | `@main` entry point, DI setup |
| `AppRootView.swift` | Route switch (home / workspace) |
| `AppRoute.swift` | Navigation route enum |
| `AppNavigationState.swift` | Navigation state (conforms to `WorkspaceNavigationDelegate`) |
| `Infrastructure/PersistenceController.swift` | CoreData stack |

### 4.2 CoreHome/ (30 files)

Home screen UI — hero background, project gallery, new project picker, responsive layout.

### 4.3 CalculatorModules/ (54 files)

Per-module calculator implementations. Plane has 35 files (most complete), Space has 8 files (partial), 4 modules are placeholders (Data/Music/Notes/Modeling).

### 4.4 DocumentSystem/ (13 files)

Only `IO/LocalProjectStore.swift` remains actively compiled. The other 12 files were moved to EMathicaDocumentKit (excluded from compilation).

### 4.5 PluginSystem/ (5 files)

Plugin protocol infrastructure — zero dependencies, Foundation only.

---

## 5. Keyboard/Input Architecture

### 5.1 Final State

```
EMathicaMathInputKit (single source of truth)
├── AST/
│   ├── MathNode (indirect enum)           ← AST definition
│   ├── TemplateNode, TemplateField        ← template AST nodes
│   └── MathEditorTree utilities           ← tree traversal
├── State/
│   ├── EditorState, EditorCursor          ← editing state model
│   ├── KeyboardAction enum                ← action abstraction
│   └── MathInputSession                   ← ObservableObject wrapper
├── Engine/
│   ├── InputController                    ← keyboard→AST bridge
│   ├── TemplateDefinition                 ← template registry
│   └── EditorCursorNavigator              ← cursor/field navigation
├── Serialization/
│   ├── MathRenderer / LatexMathRenderer   ← AST→LaTeX
│   ├── MathParser / SimpleMathParser      ← LaTeX→AST
│   ├── SourceSerializer                   ← AST→source string
│   ├── ComputeSerializer                  ← AST→compute expression
│   └── MathInputCharacterNormalizer       ← Unicode normalizer

EMathicaWorkspaceKit (UI integration)
├── FormulaEditorView.swift                ← inline AST editor (SwiftUI)
├── FormulaInputState.swift                ← state bridge (AST↔display)
├── FormulaSemanticState.swift             ← semantic classification
├── FormulaInputState+Sync.swift           ← sync derived strings
├── MathNodeSemanticLowering.swift         ← AST→MathCore Expr
├── FormulaDiagnosticPresenter.swift       ← diagnostic formatting
├── FormulaPlotDiagnostic.swift            ← diagnostic model
├── MathKeyboardView.swift                 ← on-screen keyboard
├── HardwareKeyboardCaptureView.swift      ← physical keyboard (iOS)
└── DraftMathObject.swift                  ← preview samples
```

### 5.2 Removed Legacy

| Removed | Replaced By |
|---------|-------------|
| `ExpressionInputBarView` | `FormulaEditorView` |
| `LatexTemplate` | `TemplateDefinition` |
| `LatexTemplateInsertion` | `InputController.insertTemplate` |
| `FormulaPlaceholderNavigator` | `EditorCursorNavigator` |
| `LegacyStringInputUsageTracker` | Not needed |
| `FormulaPlaceholder` / `FormulaPlaceholderKind` | `FieldID` + `EditorCursor` |
| `WorkspaceState.insertLatexTemplate` | `WorkspaceState.handleKeyboardAction(.insertTemplate(...))` |

### 5.3 Duplication Status

| Duplicate Pair | Status |
|----------------|--------|
| WK/MathEditorAST ↔ IK/MathEditorAST | ✅ Resolved — IK is single source |
| WK/MathEditorEngine ↔ IK/MathEditorEngine | ✅ Resolved — IK is single source |
| WK/MathEditorSerialization ↔ IK/MathEditorSerialization | ✅ Resolved — IK is single source |
| WK/MathEditorState ↔ IK/MathEditorState | ✅ Resolved — IK is single source |
| WK/TemplateDefinition ↔ IK/TemplateDefinition | ✅ Resolved — IK is single source |
| WK/MathInputCharacterNormalizer ↔ IK/MathInputCharacterNormalizer | ✅ Resolved — IK is single source |

---

## 6. Repository Layout Status

### 6.1 Directory Nesting (Unchanged)

```
开发/eMathica/                     ← Repo Root
├── eMathica/                      ← Git Root (.git)
│   └── eMathica/                  ← Xcode Project Root
│       ├── eMathica.xcodeproj/
│       ├── eMathica/              ← Source Root (107 .swift)
│       │   ├── App/
│       │   ├── CoreHome/
│       │   ├── CalculatorModules/
│       │   ├── DocumentSystem/
│       │   ├── PluginSystem/
│       │   ├── Resources/
│       │   └── Docs/              ← Active docs (7 files)
│       │       └── archive/       ← Historical docs (38 files)
│       ├── eMathicaTests/
│       ├── eMathicaUITests/
│       ├── Packages/              ← EMathicaMathCore
│       └── Scripts/               ← 2 active scripts
│
├── Packages/                      ← External Packages
│   ├── EMathicaDocumentKit/
│   ├── EMathicaThemeKit/
│   ├── EMathicaWorkspaceKit/
│   └── EMathicaMathInputKit/
│
├── icon design/                   ← Archived asset
├── ML models/                     ← Archived asset
└── OpenMathInk Collector/         ← Separate project
```

### 6.2 Cleanup Status

| Action | Status |
|--------|--------|
| Merge duplicate Docs directories | ✅ Done (into `Docs/archive/`) |
| Delete 10 empty directories | ✅ Done |
| Delete build caches (.build_derived, .build/) | ✅ Done |
| Archive obsolete scripts | ✅ Done |
| Delete MathCore tree copy | ✅ Done (73 files) |
| Delete WorkspaceKit tree copy | ✅ Done (75 files) |
| Flatten eMathica/eMathica/eMathica/eMathica | ⏸️ NOT recommended |

---

## 7. Removed / Archived Legacy Parts

### 7.1 Deleted Files (this session)

| Category | Files | Reason |
|----------|-------|--------|
| Legacy input | 5 | Replaced by InputKit AST pipeline |
| Legacy types | 2 structs + 1 enum | Replaced by InputKit types |
| Deprecated method | 1 | `insertLatexTemplate` — zero callers |
| Tree copy (MathCore) | 73 .swift | Excluded from compilation, Package provides |
| Tree copy (WorkspaceKit) | 75 .swift | Excluded from compilation, Package provides |
| Empty directories | 12 | No files, no purpose |
| Build caches | 6 .build dirs | Regenerated automatically |
| Duplicate Docs | 1 directory | Merged into archive/ |

### 7.2 Archived (Not Deleted)

| Item | Location | Reason |
|------|----------|--------|
| 36 historical docs | `Docs/archive/` | Reference only |
| 2 obsolete scripts | `Docs/archive/deprecated-scripts/` | No longer needed |
| `icon design/` | Repo root | Optional future use |
| `ML models/` | Repo root | Optional future use |
| `OpenMathInk Collector/` | Repo root | Separate project |

---

## 8. Build Verification Matrix

### 8.1 Package Builds

| Command | Expected | Current |
|---------|----------|---------|
| `cd EMathicaMathCore && swift test` | 334 tests pass | ✅ |
| `cd EMathicaDocumentKit && swift build` | Build succeeds | ✅ |
| `cd EMathicaThemeKit && swift build` | Build succeeds | ✅ |
| `cd EMathicaWorkspaceKit && swift build` | Build succeeds | ✅ |
| `cd EMathicaWorkspaceKit && swift test` | Tests pass | ✅ |
| `cd EMathicaMathInputKit && swift test` | 18 tests pass | ✅ |

### 8.2 App Build

| Command | Expected | Current |
|---------|----------|---------|
| `xcodebuild -scheme eMathica build` | BUILD SUCCEEDED | ✅ |
| App source files compiled | 107 .swift in-tree | ✅ |
| Package files compiled | 171 .swift across 5 packages | ✅ |
| MathCore tree copy compiled | 0 (excluded) | ✅ |
| WorkspaceKit tree copy compiled | 0 (deleted) | ✅ |

---

## 9. Do-Not-Touch List

### 9.1 Structure (Never Modify)

| Item | Reason |
|------|--------|
| `eMathica.xcodeproj/project.pbxproj` relativePath values | Load-bearing — all 4 package refs |
| `packageReferences` in pbxproj | Load-bearing |
| `EXCLUDED_SOURCE_FILE_NAMES` patterns | Load-bearing — prevents tree copy compilation |
| `fileSystemSynchronizedGroups` | Load-bearing — auto-discovers source files |
| 4-level `eMathica/` nesting | Load-bearing — flattening breaks all paths |
| `.git/` at L1 | Version control |
| Package.swift cross-references | Load-bearing — dependency resolution |

### 9.2 Code (Do Not Delete or Restore)

| Item | Reason |
|------|--------|
| 5 legacy input files | Deleted — do not restore |
| MathCore tree copy | Deleted — Package provides |
| WorkspaceKit tree copy | Deleted — Package provides |
| `@_exported import EMathicaMathInputCore` in WorkspaceKit | Required for app target access |
| `PlaneGeometryStubs.swift` in WorkspaceKit | Required for standalone build |

### 9.3 Architecture (Do Not Reverse)

| Decision | Reason |
|----------|--------|
| InputKit as single AST source | 6 duplicates resolved, 18 tests |
| WorkspaceKit as UI integration layer | Clean separation from engine |
| App target uses Packages via pbxproj refs | Eliminates dual compilation |
| Legacy string input removed | AST pipeline is replacement |

---

## 10. Recommended Next Development Options

### 10.1 High Value, Low Risk

| Option | Effort | Impact |
|--------|--------|--------|
| Add InputKit tests for edge cases (nested templates, undo/redo) | 2h | Improves InputKit reliability |
| Move `MathNodeSemanticLowering` from WK to InputKit | 1h | Consolidates AST→Expr lowering |
| Add `MathInputSession` integration to `FormulaEditorView` | 2h | Separates editing session from display state |
| Run SwiftLint / SwiftFormat across packages | 30min | Consistency |

### 10.2 Medium Value, Medium Risk

| Option | Effort | Impact |
|--------|--------|--------|
| Implement Notes Calculator module | 4h | Unlocks Notes app target |
| Complete Space Calculator module | 8h | Unlocks Space app target |
| Move `MathNodeSemanticLowering` to InputKit | 1h | Consolidation |
| InputKit iOS keyboard integration tests | 3h | UI test coverage |

### 10.3 Structural (Requires Planning)

| Option | Effort | Impact |
|--------|--------|--------|
| Move MathCore to `Packages/` (consolidate with other 4) | 1h | Simplify paths |
| Create Plane Calculator app target | 4h | First independent calculator app |
| Flatten `eMathica/` nesting | 4h | Simplify repo layout (high risk — not recommended) |
| Extract CalculatorModules into per-module packages | 8h | Full modularization |

---

## Appendix: Document Index

| Document | Content |
|----------|---------|
| `SwiftPackageSplitAudit.md` | Original package split audit |
| `WorkspacePlaneDecouplingPlan.md` | WorkspaceKit ↔ Plane decoupling design |
| `WorkspaceKitPackageReadinessAudit.md` | WorkspaceKit package extraction readiness |
| `PackageAdoptionAudit.md` | App target package adoption audit |
| `RepositoryLayoutAudit.md` | Repository layout audit |
| `FullRepositoryReductionAudit.md` | Full repository reduction audit |
| `KeyboardLegacyCleanupAudit.md` | Legacy input file cleanup audit |
| **`EMathicaArchitectureFreezeStatus.md`** | **This document — architecture baseline** |
