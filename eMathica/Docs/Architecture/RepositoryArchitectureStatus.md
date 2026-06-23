# Repository Architecture Status

> **Date:** 2026-06-16
> **Type:** Merged status report (consolidates 5 source documents)
> **Source Documents:**
> - [EMathicaCurrentArchitectureAudit.md](../../archive/consolidated-2026-06-16/EMathicaCurrentArchitectureAudit.md)
> - [EMathicaArchitectureFreezeStatus.md](../../archive/consolidated-2026-06-16/EMathicaArchitectureFreezeStatus.md)
> - [ArchitectureCleanupAudit.md](../../archive/consolidated-2026-06-16/ArchitectureCleanupAudit.md)
> - [RepositoryLayoutAudit.md](../../archive/consolidated-2026-06-16/RepositoryLayoutAudit.md)
> - [FullRepositoryReductionAudit.md](../../archive/consolidated-2026-06-16/FullRepositoryReductionAudit.md)

---

## Current Status

eMathica 已完成从单体 App 到 **5个 Package + App Target** 架构的迁移。

```
App Target "eMathica"
├── App/ (5)                    — Entry point & navigation routing
├── CoreHome/ (30)              — Home screen: hero, gallery, project cards
├── CalculatorModules/ (54)     — Plane (35), Space (8), Commands + placeholders
├── DocumentSystem/ (13)        — Persistence, package codec, metadata
├── FeatureUtilities/ (7)       — Handwriting, files, LaTeX preview (renamed from Modules/)
├── SharedUI/ (1)               — FormulaLabelPreviewView (renamed from Shared/)
├── PluginSystem/ (5)           — Protocol definitions (no active plugin system)
├── State/ (9)                  — UndoRedoManager, Settings, Onboarding
└── Resources/                  — Assets.xcassets

External Packages (at /开发/eMathica/Packages/):
├── EMathicaMathCore/    (73 files) — AST, CAS, Evaluation, Sampling, Algebra
├── EMathicaDocumentKit/  (12 files)
├── EMathicaThemeKit/     (10 files)
├── EMathicaWorkspaceKit/ (68 files)
└── EMathicaMathInputKit/ (8 files)

In-repo Package:
└── eMathica/Packages/EMathicaMathCore/  — Dual-compiled (in-tree copy + Package module)
```

### Architecture Freeze Status

**Effective:** 2026-06-07. No further structural changes planned.

**Do-Not-Touch List:**
| Item | Reason |
|------|--------|
| `eMathica.xcodeproj/` | Load-bearing — all package refs |
| `Packages/` (all) | Package path references in pbxproj |
| `App/`, `CoreHome/`, `CalculatorModules/` | Active product code |
| `DocumentSystem/` | File path strings in code |
| `Package.swift` (all) | Dependency resolution |
| `fileSystemSynchronizedGroups` | Auto-discovery mechanism |
| `EXCLUDED_SOURCE_FILE_NAMES` | Tree-copy exclusion patterns |
| 5-level `eMathica/eMathica/eMathica/eMathica/eMathica/` nesting | Xcode project structure |

---

## Key Findings

### 1. Plane MVP Is Functional
Plane's main loop is operational: open workspace → input → draft preview → commit → create points/segments/lines/circles/arcs → select → drag edit → delete → save → preview.png → reopen.

### 2. Package Adoption Is Incomplete
- `EMathicaMathCore` is dual-compiled (in-tree copy exists alongside Package module) — risky but currently passes build
- `DocumentKit`, `ThemeKit`, `WorkspaceKit` are NOT in Xcode `packageProductDependencies` — their in-tree copies compile via `fileSystemSynchronizedGroups`
- WorkspaceKit still has 6 unresolved type dependencies on App Target types (`CalculatorModuleType`, `EMathicaDocument`, `DocumentCommand`, etc.)

### 3. Space Is Skeleton-Only
Space has a runnable skeleton (WorkspaceModuleProvider, CommandHandler, CanvasView, GeometryResolver, HitTestService, WireframeRenderer) but no complete product loop. Missing: document model, Inspector, Snapping, Preview.

### 4. Directory Renames Completed
- `Shared/` → `SharedUI/` ✅ (2026-06-16)
- `Modules/` → `FeatureUtilities/` ✅ (2026-06-16)
- `PluginSystem/` → `PluginProtocol/` ⏳ (deferred to Plane v1.0+)

### 5. Repository Cleanup Status
- Phase A (Shared→SharedUI): ✅ Completed
- Phase B (Modules→FeatureUtilities): ✅ Completed
- Phase C (PluginSystem→PluginProtocol): ⏳ Deferred
- `.gitignore` created ✅

---

## Known Issues

| Issue | Severity | Status |
|-------|----------|--------|
| DocumentSystem has stale `GeometryDefinition.swift` copy (missing `arc` case) | P2 | Plane v1.0+ cleanup |
| `emathica_module_icons/` contains unused SVG duplicates of PNG assets | P2 | Plane v1.0+ cleanup |
| `Packages/EMathicaMathCore/.build/` build artifacts not gitignored | P2 | `.gitignore` created, needs git re-init |
| `WorkspaceKitBoundaryFollowupAudit.md` reported missing from disk | P1 | Needs manual verification |
| 5-level nested `eMathica/eMathica/eMathica/eMathica/eMathica/` not ideal but frozen | — | Architecture Freeze |

---

## Deferred Cleanup

| Item | Target | Reason deferred |
|------|--------|----------------|
| PluginSystem/ → PluginProtocol/ rename | Plane v1.0+ | Architecture Freeze |
| Delete `DocumentSystem/GeometryDefinition.swift` internal copy | Plane v1.0+ | Needs code reference audit |
| Remove `emathica_module_icons/` SVG files | Plane v1.0+ | Needs Xcode Asset Catalog verification |
| Full Package adoption (remove in-tree copies) | Post-v1.0 | Requires WorkspaceKit decoupling |

---

## Next Actions

1. Complete Plane v1.0 stabilization
2. After v1.0: execute deferred directory cleanup
3. After v1.0: full Package adoption — remove in-tree MathCore copy
4. After v1.0: WorkspaceKit → fully independent package (resolve 6 type dependencies)
