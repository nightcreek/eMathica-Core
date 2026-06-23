# Architecture Cleanup Audit

> **Date:** 2026-06-16
> **Mode:** Read-only audit
> **Scope:** App, CoreHome, CalculatorModules, MathCore, DocumentSystem, PluginSystem, FeatureUtilities, SharedUI, Docs

---

## 1. Current Top-Level Directory Structure

```
eMathica/                           ← Source Root
├── App/                    (5 files)
├── CoreHome/              (30 files)
├── CalculatorModules/     (54 files)
├── DocumentSystem/        (13 files)
├── PluginSystem/          (5 files)
├── FeatureUtilities/       (7 files)
├── SharedUI/              (1 file)
├── State/                 (9 files)
├── Resources/             (assets)
├── Docs/                  (16 active + archive/)
├── eMathica.xcodeproj/
├── eMathicaTests/
├── eMathicaUITests/
└── Packages/
    └── EMathicaMathCore/  ← MathCore Package
```

**External Packages (at `/开发/eMathica/Packages/`):**
- EMathicaWorkspaceKit/  (68 files)
- EMathicaDocumentKit/    (12 files)
- EMathicaThemeKit/       (10 files)
- EMathicaMathInputKit/   (8 files)

---

## 2. Directory Actual Responsibilities

### 2.1 App/

**Files (5):**
- `EMathicaApp.swift` — @main entry point, DI setup
- `AppRootView.swift` — Route switch (home/workspace)
- `AppRoute.swift` — Navigation route enum
- `AppNavigationState.swift` — Navigation state
- `Infrastructure/PersistenceController.swift` — CoreData stack
- `OpenMathInkCollectorApp.swift` — Collector app entry

**Actual Responsibility:** Application entry point and root navigation routing.

**Verdict:** Naming is accurate.

---

### 2.2 CoreHome/

**Files (30):**
- Background/ (6 files) — Background rendering layers
- Layout/ (5 files) — Responsive layout profiles
- Mocks/ (1 file) — Mock project store for previews
- Preview/ (1 file) — ProjectPreviewRenderer
- Plus 17 view files

**Actual Responsibility:** Home screen UI — hero background, project gallery, new project picker, responsive layout.

**Verdict:** Naming is accurate.

---

### 2.3 CalculatorModules/

**Files (54):**
- Plane/ (35 files) — 2D calculator implementation
- Space/ (8 files) — 3D calculator implementation
- Commands/ (2 files) — Module command registry
- Data/ (1 file) — Placeholder
- Music/ (1 file) — Placeholder
- Notes/ (1 file) — Placeholder
- Modeling/ (1 file) — Placeholder
- Root (5 files) — CalculatorModule, Registry, DefaultProvider

**Actual Responsibility:** Per-module calculator implementations. Plane is production-ready, Space is v0.1 skeleton, 4 modules are placeholders.

**Verdict:** Naming is accurate.

---

### 2.4 DocumentSystem/

**Files (13):**
- IO/ (3 files) — LocalProjectStore, ProjectStore, ProjectStoreError
- Package/ (2 files) — EMathicaPackageCodec, EMathicaPackageLayout
- Root (8 files) — EMathicaDocument, DocumentCommand, ProjectMetadata, RecentProject, etc.

**Actual Responsibility:** Document persistence, package structure, project metadata.

**Verdict:** Naming is accurate.

---

### 2.5 PluginSystem/

**Files (5):**
- PluginError.swift
- PluginManifest.swift
- PluginPlaceholder.swift
- PluginProtocol.swift
- PluginResult.swift

**Actual Responsibility:** Plugin infrastructure (currently all placeholders).

**Verdict:** Naming is accurate but misleading — suggests active plugin system when it's just protocol definitions.

---

### 2.6 FeatureUtilities/ (formerly Modules/)

**Files (7):**
- Files/ (2 files) — DatasetFileBrowserView, StatisticsView
- Handwriting/ (4 files) — DrawingToolSettings, HandwritingCanvasView, HandwritingToolbarView, PencilDrawingRepresentable
- Preview/ (1 file) — LatexRenderService

**Actual Responsibility:** Cross-cutting utility modules — file browsing, handwriting input, LaTeX rendering.

**Verdict:** Renamed from Modules/ to FeatureUtilities/ on 2026-06-16 to distinguish from CalculatorModules/.

---

### 2.7 SharedUI/

**Files:** Contains `Components/FormulaLabelPreviewView.swift`

**Actual Responsibility:** Shared UI components.

**Verdict:** Naming is accurate. Renamed from Shared/ to SharedUI/ on 2026-06-16.

---

### 2.8 State/

**Files (9):**
- CollectorWorkspaceState.swift
- ConsentFlowView.swift
- ContributorConsentManager.swift
- KeyboardShortcutManager.swift
- LocalSampleStore.swift
- OnboardingManager.swift
- SettingsView.swift
- UndoRedoManager.swift

**Actual Responsibility:** Application-wide state management — onboarding, settings, consent, keyboard shortcuts, undo/redo.

**Verdict:** Naming is accurate.

---

### 2.9 MathCore (Package)

**Location:** `Packages/EMathicaMathCore/` (Source Root level)

**Files (73 in Package):**
- AlgebraCore/
- CASCore/
- Coordinate/
- GraphCore/
- SamplingCore/
- SemanticCore/
- SpaceMathCore/
- Viewport/
- Plus root-level math types

**Actual Responsibility:** Core math engine — AST, CAS, evaluation, graphing, sampling, geometry.

**Verdict:** Naming is accurate. Lives as a Package, not a directory.

---

### 2.10 WorkspaceKit (External Package)

**Location:** `/开发/eMathica/Packages/EMathicaWorkspaceKit/`

**Files (68 in Package):**
- WorkspaceView.swift
- WorkspaceState.swift
- WorkspaceConfiguration.swift
- WorkspaceLayout.swift
- Tools/, Input/, Shared/, Toolbar/

**Actual Responsibility:** Workspace shell, tool provider, keyboard/input integration.

**Verdict:** WorkspaceKit is NOT a directory in Source Root. It exists only as an external Package. Any Source Root references to "WorkspaceKit" are outdated.

---

## 3. Package vs Directory Consistency

| Directory | Is Package? | Expected Location | Actual Location | Consistent? |
|-----------|-------------|-------------------|----------------|-------------|
| MathCore | Yes (EMathicaMathCore) | `Packages/EMathicaMathCore/` | `Packages/EMathicaMathCore/` | ✅ |
| WorkspaceKit | Yes (EMathicaWorkspaceKit) | `/Packages/EMathicaWorkspaceKit/` | `/Packages/EMathicaWorkspaceKit/` | ✅ |
| DocumentKit | Yes (EMathicaDocumentKit) | `/Packages/EMathicaDocumentKit/` | `/Packages/EMathicaDocumentKit/` | ✅ |
| ThemeKit | Yes (EMathicaThemeKit) | `/Packages/EMathicaThemeKit/` | `/Packages/EMathicaThemeKit/` | ✅ |
| MathInputKit | Yes (EMathicaMathInputKit) | `/Packages/EMathicaMathInputKit/` | `/Packages/EMathicaMathInputKit/` | ✅ |
| App | No | — | `App/` | ✅ |
| CoreHome | No | — | `CoreHome/` | ✅ |
| CalculatorModules | No | — | `CalculatorModules/` | ✅ |
| DocumentSystem | No | — | `DocumentSystem/` | ✅ |
| PluginSystem | No | — | `PluginSystem/` | ✅ |
| FeatureUtilities | No | — | `FeatureUtilities/` | ✅ |
| SharedUI | No | — | `SharedUI/` | ✅ |
| State | No | — | `State/` | ✅ |

**Conclusion:** All packages are correctly located outside Source Root. All Source Root directories are correctly NOT packages.

---

## 4. Responsibility Overlap Analysis

### 4.1 Project Preview/Thumbnail Rendering

| File | Location | Responsibility |
|------|----------|----------------|
| `ProjectPreviewRenderer.swift` | CoreHome/Preview/ | Offscreen PNG generation |
| `ProjectThumbnailView.swift` | CoreHome/ | Reads preview.png |
| `LocalProjectStore.swift` | DocumentSystem/IO/ | Writes preview.png |

**Overlap:** CoreHome handles both preview generation AND reading. DocumentSystem handles persistence only.

**Assessment:** Not a problem — different layers of the same pipeline.

---

### 4.2 Command Handling

| File | Location | Responsibility |
|------|----------|----------------|
| `ModuleCommandHandlerRegistry.swift` | CalculatorModules/Commands/ | Global command registry |
| `PlaneCommandHandler.swift` | CalculatorModules/Plane/Commands/ | Plane-specific commands |
| `SpaceCommandHandler.swift` | CalculatorModules/Space/Commands/ | Space-specific commands |

**Overlap:** Registry aggregates handlers; handlers implement specifics.

**Assessment:** Clean separation.

---

### 4.3 WorkspaceKit残留 (Historical)

The `EMathicaCurrentArchitectureAudit.md` documents that `WorkspaceState.swift` in the external WorkspaceKit Package still contains Plane-specific logic:
- `canonicalPlaneCommitInput` (dead code)
- `activeSpaceWorkPlane` (Space state in generic workspace)
- `isFormulaEditableObject` (Plane object types in workspace)

**Assessment:** This is a known, documented overlap being addressed in phases.

---

## 5. Inaccurate Naming Analysis

### 5.1 `FeatureUtilities/` Directory (formerly Modules/)

**Issue:** "Modules" was too generic and conflicted with CalculatorModules/.

**Current contents:**
- Files/ — File browser and statistics
- Handwriting/ — Drawing input
- Preview/ — LaTeX rendering

**Resolution:** Renamed to `FeatureUtilities/` on 2026-06-16 to distinguish from CalculatorModules/.

---

### 5.2 `SharedUI/` Directory (formerly Shared/)

**Issue:** "Shared" was too vague. Renamed to `SharedUI/` on 2026-06-16.

**Current contents:**
- `Components/FormulaLabelPreviewView.swift`

**Assessment:** Renamed to `SharedUI/` to explicitly signal "shared UI components." Future shared UI components can be added here.

---

### 5.3 `PluginSystem/` Directory

**Issue:** Implies an active plugin system exists. Currently only contains protocol definitions and placeholders.

**Assessment:** Not inaccurate per se, but could be named `PluginProtocol/` or `PluginKit/` to clarify it's infrastructure, not a working system.

---

## 6. Infrastructure Classification

**Infrastructure directories** provide cross-cutting services without domain knowledge:

| Directory | Infrastructure? | Reason |
|-----------|-----------------|--------|
| App/Infrastructure/ | ✅ Yes | PersistenceController is app-wide persistence |
| DocumentSystem/IO/ | ✅ Yes | ProjectStore is persistence abstraction |
| State/ | ⚠️ Partial | Some is infrastructure (UndoRedoManager), some is domain (CollectorWorkspaceState) |
| SharedUI/ | ⚠️ Partial | FormulaLabelPreviewView is shared UI component |
| MathCore (Package) | ✅ Yes | Pure engine, no domain knowledge |

**Non-infrastructure directories:**
- App/ — Application entry, not infrastructure
- CoreHome/ — Home screen domain
- CalculatorModules/ — Calculator domain
- DocumentSystem/ (non-IO) — Document model domain
- FeatureUtilities/ — Utility modules with domain characteristics
- PluginSystem/ — Protocol definitions (infrastructure-like)

---

## 7. Modules Classification

**CalculatorModules** are true modules (orthogonal product features):

| Module | Status | Files |
|--------|--------|-------|
| Plane | Production | 35 |
| Space | v0.1 Skeleton | 8 |
| Data | Placeholder | 1 |
| Music | Placeholder | 1 |
| Notes | Placeholder | 1 |
| Modeling | Placeholder | 1 |

**FeatureUtilities/** directory contains utilities, not standalone product modules:

| Subdirectory | Files | Assessment |
|--------------|-------|-------------|
| Files/ | 2 | Utility — file browsing |
| Handwriting/ | 4 | Utility — drawing input |
| Preview/ | 1 | Utility — LaTeX rendering |

---

## 8. Plane Internal Structure Analysis

```
CalculatorModules/Plane/
├── Commands/
│   └── PlaneCommandHandler.swift          ← Object creation/editing
├── Interaction/
│   ├── PlaneConstructionMode.swift
│   ├── PlaneConstructionPreview.swift
│   ├── PlaneInteractionReducer.swift
│   └── PlaneInteractionState.swift
├── Rendering/
│   └── ParametricCurveSampler.swift
├── Services/
│   ├── PlaneDraftPreviewService.swift
│   ├── PlaneExpressionService.swift
│   ├── PlaneFallbackSamplingService.swift
│   ├── PlaneGeometryDependencyService.swift
│   ├── PlaneGeometryPresentationResolver.swift
│   ├── PlaneGeometryResolver.swift
│   ├── PlaneHitTestService.swift
│   ├── PlaneInputCanonicalizer.swift
│   ├── PlaneIntersectionPreviewResolver.swift
│   ├── PlaneIntersectionSolver.swift
│   ├── PlaneLegacyExplicitSampling.swift
│   ├── PlaneLineClipping.swift
│   ├── PlaneObjectNamingService.swift
│   ├── PlaneSampleSetAdapter.swift
│   ├── PlaneSamplingComparisonDebug.swift
│   ├── PlaneSamplingQualityPolicy.swift
│   ├── PlaneSamplingViewportResolver.swift
│   ├── PlaneSemanticGraphIntentAdapter.swift
│   ├── PlaneSemanticIntentAdapter.swift
│   ├── PlaneSemanticIntentResolver.swift
│   └── PlaneSemanticPreviewPolicy.swift
├── Tools/
│   ├── PlaneToolActions.swift
│   ├── PlaneToolIDs.swift
│   └── PlaneToolProvider.swift
├── Views/
│   ├── PlaneAxisRendererView.swift
│   ├── PlaneCanvasView.swift
│   ├── PlaneGridRendererView.swift
│   └── PlaneObjectRendererView.swift
├── PlaneModule.swift
├── PlaneWorkspaceConfig.swift
└── PlaneWorkspaceModuleProvider.swift
```

**Analysis:**
- **Services layer is overloaded** — 21 service files covering geometry, sampling, hit-testing, semantics, naming, preview
- **Commands** only has 1 handler file — single responsibility but large
- **Views** is thin — 4 view files
- **Tools** is thin — 3 tool files

**Structural issues:**
1. `PlaneSemanticIntentAdapter.swift` and `PlaneSemanticIntentResolver.swift` have overlapping responsibilities
2. `PlaneGeometryResolver.swift` and `PlaneGeometryPresentationResolver.swift` may overlap
3. `PlaneLegacyExplicitSampling.swift` is explicitly marked legacy
4. Multiple "Debug" files: `PlaneSamplingComparisonDebug.swift`, `PlaneSemanticSamplingDebug.swift`

---

## 9. Space Internal Structure Analysis

```
CalculatorModules/Space/
├── Commands/
│   └── SpaceCommandHandler.swift
├── Services/
│   ├── SpaceGeometryResolver.swift
│   ├── SpaceHitTestService.swift
│   └── SpaceWireframeRenderer.swift
├── Tools/
│   ├── SpaceToolIDs.swift
│   └── SpaceToolProvider.swift
├── Views/
│   ├── SpaceCalculatorPlaceholderView.swift
│   └── SpaceCanvasView.swift
└── SpaceWorkspaceModuleProvider.swift
```

**Analysis:**
- **Minimal implementation** — only 8 files vs Plane's 35
- **Missing modules identified in prior audits:**
  - SpaceDocumentModel
  - SpaceInspector
  - SpaceSnapping (only in resolver)
  - SpacePreview (uses ProjectPreviewRenderer)
  - SpaceSemanticIntentAdapter (returns nil)
  - SpaceDraftMathObject (returns nil)

**Structural assessment:** Space is intentionally a skeleton. All structural concerns are documented.

---

## 10. CoreHome Responsibility Analysis

```
CoreHome/
├── Background/
│   ├── BaseGradientLayer.swift
│   ├── FlowingLightRibbonLayer.swift
│   ├── HomeBackgroundLayout.swift
│   ├── HomeBackgroundTheme.swift
│   ├── HomeBackgroundView.swift
│   ├── MathDecorationLayer.swift
│   └── TouchAestheticBackground.swift
├── Layout/
│   ├── CoreHomeLayoutProfile.swift
│   ├── CoreHomeResponsiveContainer.swift
│   ├── FluidCoreHomeMetrics.swift
│   ├── PadCoreHomeLayout.swift
│   └── PhoneCoreHomeLayout.swift
├── Mocks/
│   └── HomeMockProjectStore.swift
├── Preview/
│   └── ProjectPreviewRenderer.swift
└── Root view files (17)
```

**Analysis:**
- **Strong separation** — Background/, Layout/, Preview/ are distinct responsibilities
- **Mocks/** is properly separated for testing
- **Layout has device-specific variants** — PadCoreHomeLayout, PhoneCoreHomeLayout
- **Background has multiple rendering layers** — suggests decorative complexity

**CoreHome concerns from prior audits:**
- ProjectPreviewRenderer uses fixed WorldBounds for thumbnails (not content-adaptive)
- `makeRecentProject` defaults thumbnailKind to "formulaNotes" regardless of actual type

---

## 11. Docs Document Classification Analysis

### 11.1 Active Docs (16 files at Docs/)

| Category | Files | Count |
|----------|-------|-------|
| Architecture Audit | EMathicaCurrentArchitectureAudit.md, EMathicaArchitectureFreezeStatus.md | 2 |
| Plane Audit | PlaneCompactLayoutAudit.md, PlaneGeometryDependencyFailureAudit.md, PlaneMVPRegressionReport.md, PlaneUIPolishAudit.md, PlaneUIPolishRegressionReport.md, PlaneArcToolImplementationPlan.md, PlaneArcToolQAAudit.md | 7 |
| Space Audit | SpacePostPlaneMVPPlan.md | 1 |
| Workspace Audit | WorkspaceKitBoundaryFollowupAudit.md (missing), WorkspacePlaneDecouplingPlan.md | 1 (1 missing) |
| Package Audit | PackageAdoptionAudit.md, SwiftPackageSplitAudit.md, WorkspaceKitPackageReadinessAudit.md | 3 |
| Equation Solving | EquationSolvingArchitectureAudit.md, DerivativeMVPRetroactiveAudit.md | 2 |
| Legacy Cleanup | KeyboardLegacyCleanupAudit.md, FullRepositoryReductionAudit.md, RepositoryLayoutAudit.md, FunctionNamingIsolatedAudit.md, DeleteSourceObjectDependencyPolicy.md | 5 |
| Capability | EMathicaGeoGebraCapabilityMatrix.md | 1 |
| Testing | M0GoldenFixtureDesign.md, GraphQualityBaselineReport.md, SaveLoadEdgeCasesAudit.md, P0RegressionAudit.md | 4 |
| **Total** | | 26 |

### 11.2 Archive Docs (38 files at Docs/archive/)

Historical audits organized by topic:
- Plane* (multiple versions)
- Space* (architecture, canvas, selection, status)
- Sampling* (algorithm, comparison cases, status)
- Conic Recognition designs
- Build verification
- Object history recovery

### 11.3 Documentation Issues

1. **WorkspaceKitBoundaryFollowupAudit.md is missing** — Referenced in EMathicaArchitectureFreezeStatus.md but file doesn't exist
2. **Duplicate docs** — PlaneCalculatorStabilizationStatus.md appears in both root and archive
3. **Naming inconsistency** — Some docs say "Audit", others say "Status", others say "Plan"
4. **Scope confusion** — Docs/RepositoryLayoutAudit.md was written when WorkspaceKit was in Source Root (now moved)

---

## 12. Historical Legacy Structure Analysis

### 12.1 Previous Structure (Pre-Architecture Freeze)

| Directory | Status | Notes |
|-----------|--------|-------|
| MathCore/ | ❌ Deleted from Source Root | Moved to Package EMathicaMathCore |
| WorkspaceKit/ | ❌ Deleted from Source Root | Moved to Package EMathicaWorkspaceKit |
| DocumentKit files | ❌ Excluded from Source Root | Now in Package EMathicaDocumentKit |
| ThemeKit files (Shared/) | ❌ Excluded | Now in Package EMathicaThemeKit |

### 12.2 What Remains as Legacy

| Item | Location | Status |
|------|----------|--------|
| MathCore tree copy | None | ✅ Cleanly deleted |
| WorkspaceKit tree copy | None | ✅ Cleanly deleted |
| Legacy input files (5) | None | ✅ Deleted |
| Duplicate AST types | None | ✅ Unified in MathInputKit |
| Tree copies | None | ✅ All excluded from compilation |

### 12.3 Still-Active Legacy Code Within Source

| File | Legacy Indicator |
|------|------------------|
| `PlaneLegacyExplicitSampling.swift` | File name explicitly says "Legacy" |
| `PlaneSemanticPreviewPolicy.swift` | Contains legacy `explicitY`/`explicitX` comment |
| `ProjectFileManagerPlaceholder.swift` | Name says "Placeholder" |
| `SpaceCalculatorPlaceholderView.swift` | Name says "Placeholder" |
| `PluginPlaceholder.swift` | Name says "Placeholder" |
| `DataPlaceholderView.swift` | Name says "Placeholder" |
| `ModelingPlaceholderView.swift` | Name says "Placeholder" |
| `MusicPlaceholderView.swift` | Name says "Placeholder" |
| `NotesPlaceholderView.swift` | Name says "Placeholder" |

**Assessment:** Legacy indicators are clearly named. No mystery legacy files.

---

## 13. Architecture Freeze Impact Analysis

### 13.1 What Architecture Freeze Protects

From `EMathicaArchitectureFreezeStatus.md`:

**Do-Not-Touch List:**
1. `eMathica.xcodeproj/project.pbxproj` relativePath values
2. `packageReferences` in pbxproj
3. `EXCLUDED_SOURCE_FILE_NAMES` patterns
4. `fileSystemSynchronizedGroups`
5. 4-level `eMathica/` nesting
6. `.git/` at L1
7. Package.swift cross-references

### 13.2 Frozen Structures

| Structure | Status | Concern |
|-----------|--------|---------|
| 4-level nesting | Frozen | `eMathica/eMathica/eMathica/eMathica/eMathica/` |
| Package locations | Frozen | All 5 packages have fixed paths |
| MathCore in Source Root Packages/ | Frozen | `Packages/EMathicaMathCore/` |
| External Packages | Frozen | `/Packages/` at repo root |

### 13.3 Unfrozen (Can Still Change)

| Structure | Concern Level | Notes |
|-----------|---------------|-------|
| Source Root directory names | Low | App, CoreHome, etc. can be renamed |
| CalculatorModules internal | Medium | Adding new modules is safe |
| State/ organization | Low | Can be reorganized |
| FeatureUtilities/ organization | Low | ✅ Renamed from Modules/ on 2026-06-16 |
| SharedUI/ organization | Low | Renamed from Shared/ on 2026-06-16 |

### 13.4 Known Issues Not Fixed by Freeze

1. **WorkspaceKit still knows Plane/Space types** — documented but not yet resolved
2. **Naming dual paths** — function naming rules still duplicated
3. **Space skeleton** — v0.1 status unchanged
4. **Home thumbnail fixed viewport** — ProjectPreviewRenderer still uses fixed bounds

---

## 14. Recommended Future Structure

**Note:** This is a suggested directory tree only. No implementation, no file moves, no code changes.

```
eMathica/                           ← Source Root (frozen)
├── App/                            ← Entry point
│   └── Infrastructure/             ← Persistence, platform setup
├── CoreHome/                       ← Home screen
│   ├── Background/
│   ├── Layout/
│   └── Preview/
├── CalculatorModules/              ← Calculator features
│   ├── Plane/                      ← 2D calculator (production)
│   ├── Space/                      ← 3D calculator (v0.1)
│   ├── Data/                       ← placeholder
│   ├── Music/                      ← placeholder
│   ├── Notes/                      ← placeholder
│   ├── Modeling/                   ← placeholder
│   └── Commands/
├── DocumentSystem/                 ← Document persistence
│   ├── IO/
│   └── Package/
├── FeatureUtilities/              ← ✅ RENAMED from Modules/ on 2026-06-16
│   ├── Files/
│   ├── Handwriting/
│   └── Preview/
├── SharedUI/                      ← ✅ RENAMED from Shared/ on 2026-06-16
│   └── FormulaLabelPreviewView.swift
├── StateManagement/                ← RENAME: State/ (more descriptive, deferred)
├── PluginProtocol/                 ← ← RENAME: PluginSystem/ (clarify intent)
├── Resources/
├── Docs/
└── Packages/
    └── EMathicaMathCore/           ← Math engine Package
```

**Package Location (unchanged, frozen):**
```
/开发/eMathica/Packages/
├── EMathicaWorkspaceKit/
├── EMathicaDocumentKit/
├── EMathicaThemeKit/
└── EMathicaMathInputKit/
```

---

## 15. Summary Findings

### 15.1 Directory Naming Issues
- `FeatureUtilities/` — ✅ renamed from Modules/ on 2026-06-16
- `SharedUI/` — ✅ renamed from Shared/ on 2026-06-16
- `PluginSystem/` — implies active system (it's not)

### 15.2 Responsibility Overlaps
- Plane services layer is overloaded (21 files)
- Some semantic/intent adapters have overlapping responsibilities
- WorkspaceKit Package still contains Plane-specific logic (documented)

### 15.3 Infrastructure vs Domain
- **Infrastructure:** App/Infrastructure/, DocumentSystem/IO/, MathCore Package, State/UndoRedoManager
- **Domain:** App/, CoreHome/, CalculatorModules/, DocumentSystem/model/

### 15.4 Modules vs Utilities
- **True Modules:** CalculatorModules/Plane, CalculatorModules/Space
- **Utilities:** FeatureUtilities/ (Files, Handwriting, Preview)

### 15.5 Legacy Status
- ✅ No mystery legacy files
- ✅ Clear naming (Legacy, Placeholder, Archive)
- ⚠️ PlaneSemanticIntentAdapter may need review

### 15.6 Architecture Freeze Impact
- ✅ 4-level nesting is frozen
- ✅ Package paths are frozen
- ⚠️ Source Root directory names remain unfrozen
- ⚠️ Known issues (naming dual paths, Space skeleton) not addressed by freeze

---

## Appendix: Document Cross-References

| Referenced File | Status |
|-----------------|--------|
| WorkspaceKitBoundaryFollowupAudit.md | ❌ Missing (archived?) |
| PlaneCalculatorStabilizationStatus.md | ⚠️ Exists in both root and archive |
| EMathicaCurrentArchitectureAudit.md | ✅ Present |
| EMathicaArchitectureFreezeStatus.md | ✅ Present |

---

*End of Audit*
