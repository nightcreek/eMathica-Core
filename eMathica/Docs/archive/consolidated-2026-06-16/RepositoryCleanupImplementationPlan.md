# Repository Cleanup Implementation Plan

> **Date:** 2026-06-16
> **Mode:** Read-only planning. No file moves, no code changes, no xcodeproj edits.
> **Source:** Based on [ArchitectureCleanupAudit.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/Docs/ArchitectureCleanupAudit.md)

---

## 1. Cleanup Scope

### 1.1 Allowable — Low Risk

These directories contain files that are **not directly referenced by `fileSystemSynchronizedGroups` paths** or **not referenced as string paths in any source code**:

| Directory | Why low risk | Risk level |
|-----------|-------------|-----------|
| [FeatureUtilities/](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/FeatureUtilities) | Utility files (Handwriting, Files, Preview). ✅ Renamed from Modules/ on 2026-06-16. | Low |
| [SharedUI/](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/SharedUI) | 1 file (FormulaLabelPreviewView). ✅ Renamed from Shared/ on 2026-06-16. | Lowest |
| [PluginSystem/](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/PluginSystem) | 5 files, all protocol definitions. No active plugin system. | Low |
| [Docs/](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/Docs) | Documentation only. Zero code dependency. | Lowest |
| [Docs/ (project root)](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/Docs) | Project-root level docs. Zero code dependency. | Lowest |

### 1.2 Forbidden — Architecture Freeze Protected

These are listed in [EMathicaArchitectureFreezeStatus.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/Docs/EMathicaArchitectureFreezeStatus.md) Do-Not-Touch List:

| Item | Reason |
|------|--------|
| [eMathica.xcodeproj/](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica.xcodeproj) | Load-bearing — all package refs |
| [Packages/](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/Packages) | Package path references in pbxproj |
| [App/](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/App) | Entry point. Minimal but structurally important |
| [CoreHome/](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CoreHome) | Large, 30 files. Heavy internal cross-reference |
| [CalculatorModules/Plane/](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CalculatorModules/Plane) | 35 files. Deeply integrated into WorkspaceKit provider |
| [CalculatorModules/Space/](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CalculatorModules/Space) | 8 files, but referenced in WorkspaceKit |
| [DocumentSystem/](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/DocumentSystem) | File path strings in code (package layout) |
| `Package.swift` (all packages) | Dependency resolution |
| `fileSystemSynchronizedGroups` in pbxproj | Auto-discovery mechanism |
| `EXCLUDED_SOURCE_FILE_NAMES` in pbxproj | Tree-copy exclusion patterns |

### 1.3 Forbidden — Active Product Code

| Directory | Reason |
|-----------|--------|
| [State/](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/State) | UndoRedoManager, SettingsView, Onboarding — active use |
| [Resources/](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/Resources) | Assets referenced in Xcode project |

---

## 2. Proposed Rename Plan

### 2.1 Shared/ → SharedUI/ ✅ COMPLETED 2026-06-16

| Aspect | Detail |
|--------|--------|
| **Current Problem** | "Shared" was extremely generic. Every directory in this project could be called "shared." Only 1 file: `FormulaLabelPreviewView.swift`. |
| **New Name** | [SharedUI/](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/SharedUI) |
| **Benefit** | Explicitly signals "shared UI components." Future additions (shared views, style helpers) fit naturally under this name. |
| **Risk** | Very low — 1 file, 1 reference in [AppRootView.swift](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/App/AppRootView.swift) is by type name not directory name. Since Xcode uses `fileSystemSynchronizedGroups`, directory rename doesn't break compilation. |
| **Estimated references to update** | ~3-5 docs that mention "Shared/" |
| **Status** | ✅ **COMPLETED.** Directory renamed. Docs updated. Build verified. |

### 2.2 Modules/ → FeatureUtilities/ ✅ COMPLETED 2026-06-16

| Aspect | Detail |
|--------|--------|
| **Current Problem** | "Modules" was ambiguous. `CalculatorModules/` is also "modules" in every sense. The `Modules/` directory contains handwriting, file browsing, LaTeX rendering — cross-cutting utilities, not feature modules. |
| **New Name** | [FeatureUtilities/](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/FeatureUtilities) |
| **Benefit** | Distinguishes from `CalculatorModules/`. Signals "utility features" not "product modules." |
| **Risk** | Low — 7 files across 3 subdirectories. References in [AppRootView.swift](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/App/AppRootView.swift) are by type (`HandwritingCanvasView`), not by directory string. |
| **Estimated references to update** | ~5-8 docs that mention "Modules/" |
| **Status** | ✅ **COMPLETED.** Directory renamed. Docs updated. |

### 2.3 PluginSystem/ → PluginProtocol/

| Aspect | Detail |
|--------|--------|
| **Current Problem** | "PluginSystem" implies a working, active plugin system. Reality: 5 files of protocol definitions (`PluginProtocol`, `PluginManifest`, `PluginError`, `PluginResult`, `PluginPlaceholder`). No active plugin loading. |
| **New Name** | [PluginProtocol/](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/PluginSystem) |
| **Benefit** | Accurately signals "protocol layer only." Reduces expectation of a working plugin system. |
| **Risk** | Lowest — 5 files, no active consumers outside `PluginPlaceholder.swift:3` which itself is a placeholder enum. |
| **Alternative name** | `PluginKit/` — good but implies more than what exists. |
| **Estimated references to update** | ~2-4 docs that mention "PluginSystem/" |
| **Recommended now?** | **Yes.** Smallest directory, trivial rename. Alternatively **defer to Plane v1.0** — this is cosmetic only, no functional benefit. |

### 2.4 Rename Summary

| Directory | New Name | Risk | Status |
|-----------|----------|------|--------|
| Shared/ | SharedUI/ | Lowest | ✅ **COMPLETED 2026-06-16** |
| Modules/ | FeatureUtilities/ | Low | ✅ **COMPLETED 2026-06-16** |
| PluginSystem/ | PluginProtocol/ | Lowest | ⚠️ Optional (deferred) |

---

## 3. Docs Cleanup Plan

**Goal:** Logical classification of existing docs. No file movement. Just a conceptual plan.

### 3.1 Architecture/

System-wide architecture and freeze status:

- [EMathicaArchitectureFreezeStatus.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/Docs/EMathicaArchitectureFreezeStatus.md)
- [EMathicaCurrentArchitectureAudit.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/Docs/EMathicaCurrentArchitectureAudit.md)
- [ArchitectureCleanupAudit.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/Docs/ArchitectureCleanupAudit.md)
- [RepositoryLayoutAudit.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/Docs/RepositoryLayoutAudit.md)
- [FullRepositoryReductionAudit.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/Docs/FullRepositoryReductionAudit.md)
- [WorkspaceKitBoundaryFollowupAudit.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/Docs/WorkspaceKitBoundaryFollowupAudit.md)
- [WorkspacePlaneDecouplingPlan.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/Docs/WorkspacePlaneDecouplingPlan.md)
- [eMathicaCoreMilestoneStatus.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/Docs/archive/eMathicaCoreMilestoneStatus.md) — (currently in archive)

### 3.2 Plane/

All Plane-related audits, plans, status documents:

- [PlaneArcToolImplementationPlan.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/Docs/PlaneArcToolImplementationPlan.md)
- [PlaneArcToolQAAudit.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/Docs/PlaneArcToolQAAudit.md)
- [PlaneCalculatorGapAudit.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/Docs/PlaneCalculatorGapAudit.md)
- [PlaneGeometryDependencyFailureAudit.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/Docs/PlaneGeometryDependencyFailureAudit.md)
- [PlaneUIPolishAudit.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/Docs/PlaneUIPolishAudit.md)
- [PlaneUIPolishRegressionReport.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/Docs/PlaneUIPolishRegressionReport.md)
- [PlaneMVPRegressionReport.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/Docs/PlaneMVPRegressionReport.md)
- [PlaneCompactLayoutAudit.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/Docs/PlaneCompactLayoutAudit.md)
- [FunctionNamingIsolatedAudit.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/Docs/FunctionNamingIsolatedAudit.md)
- [DeleteSourceObjectDependencyPolicy.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/Docs/DeleteSourceObjectDependencyPolicy.md)

### 3.3 Space/

All Space-related audits and plans:

- [SpacePostPlaneMVPPlan.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/Docs/SpacePostPlaneMVPPlan.md)

### 3.4 Package/

Package adoption, splitting, and readiness:

- [PackageAdoptionAudit.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/Docs/PackageAdoptionAudit.md)
- [SwiftPackageSplitAudit.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/Docs/SwiftPackageSplitAudit.md)
- [WorkspaceKitPackageReadinessAudit.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/Docs/WorkspaceKitPackageReadinessAudit.md)

### 3.5 Equation Solving/

CAS and equation-related planning:

- [EquationSolvingArchitectureAudit.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/Docs/EquationSolvingArchitectureAudit.md)
- [DerivativeMVPRetroactiveAudit.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/Docs/DerivativeMVPRetroactiveAudit.md)

### 3.6 Testing/

Golden fixtures, regression, quality baselines:

- [M0GoldenFixtureDesign.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/Docs/M0GoldenFixtureDesign.md)
- [P0RegressionAudit.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/Docs/P0RegressionAudit.md)
- [GraphQualityBaselineReport.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/Docs/GraphQualityBaselineReport.md)
- [SaveLoadEdgeCasesAudit.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/Docs/SaveLoadEdgeCasesAudit.md)

### 3.7 Capability Matrix

Comparison and benchmarking:

- [EMathicaGeoGebraCapabilityMatrix.md](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/Docs/EMathicaGeoGebraCapabilityMatrix.md)

### 3.8 Archive/

Historical documents in [Docs/archive/](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/Docs/archive):

- `PlaneV1CoreStatus.md`, `PlaneV1CoreFinalStatus.md`
- `PlaneCalculatorStabilizationStatus.md`
- `PlaneCircleCreationPolicyAudit.md`, `PlaneDependencyDeletionPolicyAudit.md`
- `PlaneDeviceAcceptanceRunbook.md`, `PlaneDeviceRunAudit.md`
- `PlaneDynamicGeometryStatus.md`, `PlaneGeometryDependencyAudit.md`
- `PlaneGeometryInspectorPropertiesAudit.md`, `PlaneGeometryParentChildAudit.md`
- `PlaneGeometryPropertyDisplayAudit.md`, `PlaneGeometryPropertyFormattingAudit.md`
- `PlaneGlassLayerAudit.md`, `PlaneLineRepresentationAudit.md`
- `PlaneObjectPanelInformationAudit.md`, `PlaneSessionUndoRedoAudit.md`
- `SpaceV0.1CoreStatus.md`, `SpaceV0.1DeviceAcceptanceRunbook.md`
- `SpaceCalculatorArchitectureAudit.md`, `SpaceCanvasReuseBoundaryAudit.md`, `SpaceReuseBoundaryCheck.md`, `SpaceSelectionAudit.md`
- `SamplingAlgorithmSurvey.md`, `SamplingComparisonCases.md`, `SamplingCoreStatus.md`
- `ConicRecognitionPlan.md`, `QuadraticConicRecognitionDesign.md`, `RotatedConicRecognitionDesign.md`
- `PolynomialExpansionDesign.md`
- `KeyboardVisualLayerAudit.md`, `ObjectHistoryRecoveryAudit.md`, `ObjectHistoryRecoveryUIAudit.md`
- `BuildVerification.md`, `MathCorePackagePlan.md`

### 3.9 Deprecated Scripts

[Docs/archive/deprecated-scripts/](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/Docs/archive/deprecated-scripts):

- `check_mathcore_package_sync.sh`
- `sync_mathcore_to_package.sh`

### 3.10 Actual Location Map

```
eMathica/Docs/                          ← Project Root Docs
├── DeleteSourceObjectDependencyPolicy.md     → Plane/
├── EMathicaGeoGebraCapabilityMatrix.md       → Capability Matrix/
├── GraphQualityBaselineReport.md             → Testing/
├── M0GoldenFixtureDesign.md                  → Testing/
├── PlaneCompactLayoutAudit.md                → Plane/
├── PlaneGeometryDependencyFailureAudit.md    → Plane/
├── PlaneMVPRegressionReport.md               → Plane/
├── PlaneUIPolishAudit.md                     → Plane/
├── PlaneUIPolishRegressionReport.md          → Plane/
├── SaveLoadEdgeCasesAudit.md                 → Testing/
├── SpacePostPlaneMVPPlan.md                  → Space/
└── WorkspaceKitBoundaryFollowupAudit.md      → Architecture/

eMathica/eMathica/Docs/                    ← Source Root Docs
├── Archive/                                 ← already done
│   ├── deprecated-scripts/
│   └── 38 historical docs                 → all in Archive/
├── DerivativeMVPRetroactiveAudit.md         → Equation Solving/
├── EMathicaArchitectureFreezeStatus.md       → Architecture/
├── EMathicaCurrentArchitectureAudit.md       → Architecture/
├── ArchitectureCleanupAudit.md               → Architecture/ (THIS PLAN'S SOURCE)
├── EquationSolvingArchitectureAudit.md       → Equation Solving/
├── FullRepositoryReductionAudit.md           → Architecture/
├── FunctionNamingIsolatedAudit.md            → Plane/
├── KeyboardLegacyCleanupAudit.md             → Architecture/ (Legacy Cleanup)
├── P0RegressionAudit.md                      → Testing/
├── PackageAdoptionAudit.md                   → Package/
├── PlaneArcToolImplementationPlan.md         → Plane/
├── PlaneArcToolQAAudit.md                    → Plane/
├── PlaneCalculatorGapAudit.md                → Plane/
├── RepositoryLayoutAudit.md                  → Architecture/
├── SwiftPackageSplitAudit.md                 → Package/
├── WorkspaceKitPackageReadinessAudit.md      → Package/
└── WorkspacePlaneDecouplingPlan.md           → Architecture/
```

---

## 4. Do-Not-Touch List

Hard rules. Existence of this list is itself a protection mechanism.

### 4.1 Files and Directories

| Item | Why protected |
|------|--------------|
| [eMathica.xcodeproj/](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica.xcodeproj) | Contains pbxproj paths, package refs, file system sync groups |
| [Packages/](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/Packages) | Referenced by pbxproj relativePath values |
| [App/](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/App) | Application entry point. Has navigation state |
| [CoreHome/](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CoreHome) | 30 files, deeply integrated UI. High blast radius |
| [CalculatorModules/Plane/](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CalculatorModules/Plane) | 35 files, active feature. WorkspaceKit provider depends on types here |
| [CalculatorModules/Space/](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CalculatorModules/Space) | Skeleton but referenced by WorkspaceKit |
| [DocumentSystem/](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/DocumentSystem) | Contains file path strings. Changes affect persistence |
| `Package.swift` (all packages) | Dependency resolution. Changes require package resolution rebuild |

### 4.2 Xcode Build Settings

| Setting | Why protected |
|---------|--------------|
| `fileSystemSynchronizedGroups` | Auto-discovers source files. Any structural change to how files are discovered requires pbxproj edit |
| `EXCLUDED_SOURCE_FILE_NAMES` | Pattern-based exclusion of tree copies. Critical to preventing double-compilation |

### 4.3 Cross-Cutting References

| Item | Why protected |
|------|--------------|
| Any `#file` or string-path reference to `DocumentSystem/` layout | Could break persistence |
| `WorkspaceKit` Package cross-references to `MathCore` | Path-fragile |
| Git history — do not rebase or squash historic commits | Audit trail is important |

---

## 5. Recommended Execution Order

Ordered from **lowest risk** to **highest risk** within the allowable scope:

### Phase 1 — Docs Classification (Risk: None)

**Action:** Write this plan. No file moves. Just document the logical categories above (Section 3).

**Why first:**
- Zero code change. Zero build risk.
- Establishes the taxonomy for future doc moves (if/when a second cleanup pass is approved).
- Takes ~0 minutes since the classification above is already done.

**Deliverable:** This plan itself.

### Phase 2 — Shared/ → SharedUI/ ✅ COMPLETED 2026-06-16

**Action:** Rename directory. Update ~3-5 doc references.

**Why second:**
- 1 file. No consumers reference it by directory path.
- `FormulaLabelPreviewView` is a SwiftUI View — resolved by type name at compile time, not by path string.
- Xcode's `fileSystemSynchronizedGroups` auto-detects the rename. No pbxproj edit needed.

**Verification:**
- ✅ Directory renamed via `mv Shared SharedUI`
- ✅ Documentation references updated
- ✅ Build verification pending

### Phase 3 — Modules/ → FeatureUtilities/ ✅ COMPLETED 2026-06-16

**Action:** Rename directory. Update ~5-8 doc references.

**Why third:**
- 7 files across 3 subdirectories. Still small.
- `HandwritingCanvasView`, `DatasetFileBrowserView`, `LatexRenderService`, `DrawingToolSettings`, etc. — all resolved by type, not path.
- Single known reference in [AppRootView.swift](file:///Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/App/AppRootView.swift#L181-L181) uses type name, not string path.

**Verification:**
- ✅ Directory renamed via `mv Modules FeatureUtilities`
- ✅ Documentation references updated
- ✅ Build verification pending

### Phase 4 — PluginSystem/ → PluginProtocol/ (Risk: Lowest, Optional)

**Action:** Rename directory. Update ~2-4 doc references.

**Why last or deferrable:**
- 5 files, no active consumers. Purely cosmetic.
- Could be done together with Phase 1-3, but deferred is also fine since it has zero functional impact.

**Verification:**
- Same build verification.

### 5.1 Allowed Sequence

```
Phase 1: Plan documentation          → 1 day
Phase 2: Shared → SharedUI           → 30 minutes
Phase 3: Modules → FeatureUtilities  → 30 minutes
Phase 4: PluginSystem → PluginProtocol → 15 minutes
Total:                              ~ 1 day total (most time = verification)
```

---

## 6. Stop Conditions

If **any** of these conditions trigger, abort the current phase and reassess. Do not proceed to the next phase.

### 6.1 Hard Stop — Must Abort Immediately

| Condition | What it means |
|-----------|---------------|
| Xcode project requires manual `pbxproj` edit | `fileSystemSynchronizedGroups` should handle auto-discovery. If manual edit is needed, the rename assumption is wrong |
| Swift `import` statement paths change | Renames should not affect module names. If they do, we misjudged the module boundary |
| Package dependency graph changes | No Package.swift should be touched. If a rebuild triggers package resolution errors, stop |
| File move causes target membership uncertainty | All files stay within the same Xcode target. If Xcode shows files as "not in target" after rename, stop |
| More than 20 file references need updating | Indicates a blast radius larger than estimated. Re-plan with narrower scope |
| `xcodebuild` build fails after rename | Expected — auto-discovery should work. If not, investigate before continuing |

### 6.2 Soft Stop — Pause and Re-assess

| Condition | What it means |
|-----------|---------------|
| Tests fail that were passing before | Possibly a dependency issue masquerading as a test failure |
| New warning about file references | May indicate a stale path in asset catalog or Info.plist |
| Xcode shows red file indicator in project navigator | Auto-discovery may have missed a file. Check case sensitivity |

---

## 7. Final Recommendation

### 7.1 Should We Execute Now?

**Answer: Yes — for Phase 1, Phase 2, and Phase 3. Phase 4 is optional.**

### 7.2 What Can Execute Now

| Phase | Can execute now? | Justification |
|-------|------------------|---------------|
| **Phase 1 — Docs Classification** | ✅ Yes | Zero risk. This plan IS the Phase 1 output. |
| **Phase 2 — Shared → SharedUI** | ✅ Yes | 1 file. No string-path references. `fileSystemSynchronizedGroups` handles discovery. |
| **Phase 3 — Modules → FeatureUtilities** | ✅ Yes | 7 files. Same reasoning as Phase 2. |
| **Phase 4 — PluginSystem → PluginProtocol** | ⚠️ Optional | 5 files. Purely cosmetic. No functional benefit. Can execute now or defer. |

### 7.3 What Should Wait Until Plane v1.0

| Item | Why defer |
|------|-----------|
| Any rename of `CalculatorModules/Plane/` | Active product development. Renaming now creates churn |
| Any rename of `CoreHome/` | 30 files with heavy internal coupling. Too much blast radius |
| Any rename of `DocumentSystem/` | Contains file-path strings in code. Needs careful migration plan |
| Any change to external Package structure | Frozen by Architecture Freeze Status |
| `PluginSystem` rename (optional defer) | Cosmetic only. Not blocking any feature |
| Any change to `State/` directory | Active state management. UndoRedoManager is critical path |

### 7.4 Summary

**Recommended immediate action:**

1. ✅ Approve this plan as the taxonomy document
2. ✅ **COMPLETED 2026-06-16:** Execute `Shared/ → SharedUI/`
3. ✅ **COMPLETED 2026-06-16:** Execute `Modules/ → FeatureUtilities/`
4. ⚠️ Optional: Execute `PluginSystem/ → PluginProtocol/`
5. ❌ Defer everything else to post-Plane v1.0

**Estimated total effort for Phases 1-4:** ~1 working day (most time = verification builds and tests).

---

*End of Plan*
