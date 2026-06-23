# eMathica Full Repository Reduction Audit

> **Date:** 2026-06-06  
> **Scope:** Complete repository scan, zero modifications.  
> **Goal:** Identify what can be archived, deleted, or consolidated.

---

## 1. Current Repository Map

### 1.1 Full Directory Nesting

```
开发/eMathica/                                    ← 🏠 Repo Root
│
├── eMathica/                                     ← 🔵 Git Root (.git)
│   └── eMathica/                                 ← 🔴 Xcode Project Root
│       ├── eMathica.xcodeproj/
│       ├── eMathica/                             ← 📁 Source Root (107 .swift)
│       │   ├── App/               (5 files)
│       │   ├── CalculatorModules/ (54 files)
│       │   ├── CoreHome/          (30 files)
│       │   ├── DocumentSystem/    (13 files)
│       │   ├── PluginSystem/      (5 files)
│       │   ├── Resources/         (assets only)
│       │   ├── Docs/              (5 active + 36 archive)
│       │   └── eMathica.xcdatamodeld/
│       ├── eMathicaTests/         (33 swift files)
│       ├── eMathicaUITests/       (2 swift files)
│       ├── Packages/              → EMathicaMathCore
│       ├── Scripts/               (4 shell scripts)
│       └── .build_derived/
│
├── Packages/                                     ← 📦 External Packages
│   ├── EMathicaDocumentKit/
│   ├── EMathicaThemeKit/
│   ├── EMathicaWorkspaceKit/
│   └── EMathicaMathInputKit/
│
├── icon design/                                  ← 🎨 Icons (19 files)
├── ML models/                                    ← 🤖 ML Training (5 files)
├── OpenMathInk Collector/                        ← 📱 Separate App (30 .swift)
└── .claude/                                      ← Claude Code config
```

### 1.2 Layer Definitions

| Layer | Path | Role | Xcode Relevance |
|-------|------|------|-----------------|
| L0 | `开发/eMathica/` | Human-organized project folder | None |
| L1 | `eMathica/` | Git root | None |
| L2 | `eMathica/eMathica/` | Xcode project root | **xcodeproj here** |
| L3 | `eMathica/eMathica/eMathica/` | Source root | **fileSystemSynchronizedGroups** |
| L4 | (none) | — | — |

---

## 2. Actual Build Graph

### 2.1 What Gets Compiled

```
App Target "eMathica"
├── 📁 Source Root (fileSystemSynchronizedGroups: eMathica/)
│   ├── App/                 5 .swift   ✅ compiled
│   ├── CalculatorModules/  54 .swift   ✅ compiled
│   ├── CoreHome/           30 .swift   ✅ compiled
│   ├── DocumentSystem/     13 .swift   ✅ compiled (only excludes)
│   ├── PluginSystem/        5 .swift   ✅ compiled
│   └── Resources/           assets     ✅ bundled
│
├── 📦 Package Dependencies
│   ├── EMathicaMathCore      73 .swift  ✅ package
│   ├── EMathicaDocumentKit   12 .swift  ✅ package
│   ├── EMathicaThemeKit      10 .swift  ✅ package
│   └── EMathicaWorkspaceKit  68 .swift  ✅ package
│
├── 📦 Tests Target "eMathicaTests"     33 .swift  ✅ compiled
├── 📦 UITests Target "eMathicaUITests"  2 .swift  ✅ compiled
│
└── ❌ EXCLUDED FROM COMPILATION
    ├── MathCore/             DELETED (was 73 files)
    └── WorkspaceKit/         DELETED (was 75 files)
```

### 2.2 Total Build Footprint

| Component | Swift Files | Status |
|-----------|------------|--------|
| App source (in-tree) | 107 | Compiled in target |
| App tests | 33 | Compiled in test target |
| App UITests | 2 | Compiled in UI test target |
| EMathicaMathCore | 73 | Package |
| EMathicaDocumentKit | 12 | Package |
| EMathicaThemeKit | 10 | Package |
| EMathicaWorkspaceKit | 68 | Package |
| **Total** | **305** | |

---

## 3. Active Project Assets

### 3.1 Must Retain — Build Required

| Asset | Path | Reason |
|-------|------|--------|
| `eMathica.xcodeproj/` | L2 | Xcode project — essential for build |
| `App/` | L3 | Entry point (EMathicaApp, AppNavigationState, AppRoute, AppRootView) |
| `CoreHome/` | L3 | Home screen UI (30 files) |
| `CalculatorModules/` | L3 | Module implementations (Plane 35, Space 8, Commands 2, placeholders 4) |
| `DocumentSystem/` | L3 | LocalProjectStore + remaining tree copies |
| `PluginSystem/` | L3 | Plugin protocol definitions (5 files) |
| `Resources/` | L3 | App icons, module icons, asset catalog |
| `eMathica.xcdatamodeld/` | L3 | Core Data model |
| `eMathicaTests/` | L2 | Test target source (33 files) |
| `eMathicaUITests/` | L2 | UI test target source (2 files) |
| `Packages/EMathicaMathCore/` | L2 | Math package (73 files, 334 tests) |
| `Packages/EMathicaDocumentKit/` | L0 | Document package (12 files) |
| `Packages/EMathicaThemeKit/` | L0 | Theme package (10 files) |
| `Packages/EMathicaWorkspaceKit/` | L0 | Workspace package (68 files) |

### 3.2 Must Retain — Non-Build but Important

| Asset | Reason |
|-------|--------|
| `.git/` (at L1) | Version control history |
| `.claude/` | Claude Code session data |
| `Docs/` (5 active files at L3) | Current architecture documentation |
| `Docs/archive/` (36 files at L3) | Historical reference documentation |

---

## 4. Package Assets

### 4.1 Package Adoption Status

| Package | In Xcode pbxproj | Tree Copy | Builds | Tests |
|---------|-----------------|-----------|--------|-------|
| EMathicaMathCore | ✅ `Packages/EMathicaMathCore` | ❌ Deleted | ✅ | 334 |
| EMathicaDocumentKit | ✅ `../../Packages/EMathicaDocumentKit` | ❌ Excluded | ✅ | 1 |
| EMathicaThemeKit | ✅ `../../Packages/EMathicaThemeKit` | ❌ Excluded | ✅ | 1 |
| EMathicaWorkspaceKit | ✅ `../../Packages/EMathicaWorkspaceKit` | ❌ Deleted | ✅ | 1 |
| EMathicaMathInputKit | ❌ Not in pbxproj | ❌ Not adopted | ✅ | 17 |

### 4.2 Package Path Consistency

| Reference | Path | Resolves? |
|-----------|------|-----------|
| pbxproj → MathCore | `Packages/EMathicaMathCore` | ✅ |
| pbxproj → DocumentKit | `../../Packages/EMathicaDocumentKit` | ✅ |
| pbxproj → ThemeKit | `../../Packages/EMathicaThemeKit` | ✅ |
| pbxproj → WorkspaceKit | `../../Packages/EMathicaWorkspaceKit` | ✅ |
| WorkspaceKit → MathCore | `../../eMathica/eMathica/Packages/EMathicaMathCore` | ✅ |
| DocumentKit → MathCore | `../../eMathica/eMathica/Packages/EMathicaMathCore` | ✅ |

---

## 5. Historical / Archive Assets

### 5.1 Not Needed for Current Build

| Asset | Files | Assessment |
|-------|-------|------------|
| `icon design/` | 19 | Icon design source files. Not needed for build (icons are in Resources/Assets.xcassets). **Archive.** |
| `ML models/` | 5 | Handwriting recognition ML model project. Not part of app build. **Archive.** |
| `OpenMathInk Collector/` | 30 .swift | Separate iOS app for collecting handwriting data. Has its own xcodeproj. **Keep as separate project.** |

### 5.2 Scripts — Unclear Status

| File | Lines | Assessment |
|------|-------|------------|
| `Scripts/check_mathcore_app_target_exclusion.sh` | — | Verifies MathCore exclusion from compilation. **Keep — useful for CI.** |
| `Scripts/check_mathcore_package_sync.sh` | — | Checks MathCore package vs tree copy sync. **Archive — tree copy deleted.** |
| `Scripts/sync_mathcore_to_package.sh` | — | Syncs MathCore tree to package. **Archive — no longer needed.** |
| `Scripts/verify_mathcore.sh` | — | Verifies MathCore package. **Keep — useful for CI.** |

---

## 6. Duplicate or Redundant Directories

### 6.1 Empty Directories (10 found)

| Directory | Status |
|-----------|--------|
| `CoreHome/Components/` | Empty — safe to delete |
| `CoreHome/Previews/` | Empty — safe to delete |
| `CalculatorModules/Plane/Mock/` | Empty — safe to delete |
| `CalculatorModules/Plane/Algorithms/` | Empty — safe to delete |
| `CalculatorModules/Plane/Models/` | Empty — safe to delete |
| `CalculatorModules/Plane/Components/` | Empty — safe to delete |
| `CalculatorModules/Space/Mock/` | Empty — safe to delete |
| `CalculatorModules/Space/Algorithms/` | Empty — safe to delete |
| `CalculatorModules/Space/Models/` | Empty (SpaceWorkPlane.swift was deleted) |
| `CalculatorModules/Space/Components/` | Empty — safe to delete |

### 6.2 Redundant Content

| Item | Status |
|------|--------|
| `BuildVerification.md` (in archive) | Duplicate concept with newer docs — keep for history |
| `MathCorePackagePlan.md` (in archive) | Superseded by `SwiftPackageSplitAudit.md` |
| `SamplingComparisonCases.md` (in archive) | Engineering notes — keep in archive |
| `SpaceV0.1CoreStatus.md` (in archive) | Status report — keep in archive |
| `.build_derived/` (L2) | Xcode build cache — can be safely deleted (Xcode regenerates) |

---

## 7. Directories Safe to Delete

### 7.1 Zero Risk — Recreatable

| Directory | Why Safe |
|-----------|----------|
| `.build_derived/` | Xcode build cache, regenerated on next build |
| All `.build/` inside packages | SwiftPM build cache, regenerated |
| All `.swiftpm/` inside packages | SwiftPM cache, regenerated |

### 7.2 Zero Risk — Empty Directories

All 10 empty directories listed in Section 6.1.

### 7.3 Low Risk — Excluded Tree Copies (Already Deleted)

| Directory | Previously |
|-----------|-----------|
| `MathCore/` | ✅ Already deleted (73 files) |
| `WorkspaceKit/` | ✅ Already deleted (75 files) |

---

## 8. Directories Safe to Archive

### 8.1 Move to External Storage

| Asset | Reason | Suggested Location |
|-------|--------|--------------------|
| `icon design/` (19 files) | Icon source files (Figma exports likely). Icons are already in `Resources/Assets.xcassets/`. | `~/Archive/eMathica/icons/` |
| `ML models/` (5 files) | Handwriting recognition training project. Not part of app build. | `~/Archive/eMathica/ml-models/` |

### 8.2 Keep in-Repo but Mark as Archived

| Asset | Reason |
|-------|--------|
| `Docs/archive/` (36 files) | Historical documentation — already in archive/ |
| `Scripts/check_mathcore_package_sync.sh` | No longer needed (tree copy deleted) |
| `Scripts/sync_mathcore_to_package.sh` | No longer needed |

---

## 9. Directories Must Not Touch

### 9.1 Absolutely Cannot Be Moved

| Directory | Consequence of Moving |
|-----------|----------------------|
| `eMathica.xcodeproj/` | Breaks all pbxproj relative paths. Xcode won't open. |
| `.git/` (at L1) | Loses all version history. |
| `Packages/EMathicaMathCore/` (at L2) | pbxproj `relativePath = Packages/EMathicaMathCore` breaks. |
| `Packages/EMathicaDocumentKit/` (at L0) | pbxproj `relativePath = ../../Packages/EMathicaDocumentKit` breaks. |
| Source root `eMathica/` (at L3) | Xcode `fileSystemSynchronizedGroups` breaks. |

### 9.2 Should Not Be Flattened

The `eMathica/eMathica/eMathica/eMathica` nesting looks redundant but is load-bearing:
- L2 (`eMathica/`) is the Xcode project root — moving it breaks ALL relative paths
- L3 (`eMathica/` inside L2) is the source root — Xcode expects it here
- Flattening would require rewriting every path in `project.pbxproj`, every `Package.swift`, every `EXCLUDED_SOURCE_FILE_NAMES` pattern

**Recommendation: Accept the nesting. Do not flatten now.**

---

## 10. Recommended Final Layout

### 10.1 After Minimal Cleanup

```
eMathica/                                    ← Repo Root (unchanged)
├── eMathica/                                ← Git Root (unchanged)
│   └── eMathica/                            ← Xcode Project Root (unchanged)
│       ├── eMathica.xcodeproj/
│       ├── eMathica/                        ← Source Root
│       │   ├── App/
│       │   ├── CalculatorModules/
│       │   ├── CoreHome/
│       │   ├── DocumentSystem/
│       │   ├── PluginSystem/
│       │   ├── Resources/
│       │   ├── Docs/
│       │   │   ├── (5 active docs)
│       │   │   └── archive/ (36 historical)
│       │   └── eMathica.xcdatamodeld/
│       ├── eMathicaTests/
│       ├── eMathicaUITests/
│       ├── Packages/ → EMathicaMathCore
│       └── Scripts/ (2 active scripts)
│
├── Packages/                                ← External Packages (unchanged)
│   ├── EMathicaDocumentKit/
│   ├── EMathicaThemeKit/
│   ├── EMathicaWorkspaceKit/
│   └── EMathicaMathInputKit/
│
├── OpenMathInk Collector/                   ← Separate App (keep)
├── icon design/                             ← Optional: move to archive
├── ML models/                               ← Optional: move to archive
└── .claude/
```

---

## 11. Minimal Safe Cleanup Plan

### Phase A: Delete Empty Directories (0 risk, 1 minute)

```bash
# 10 empty directories
rm -rf eMathica/eMathica/eMathica/eMathica/CoreHome/Components
rm -rf eMathica/eMathica/eMathica/eMathica/CoreHome/Previews
rm -rf eMathica/eMathica/eMathica/eMathica/CalculatorModules/Plane/{Mock,Algorithms,Models,Components}
rm -rf eMathica/eMathica/eMathica/eMathica/CalculatorModules/Space/{Mock,Algorithms,Models,Components}
```

### Phase B: Archive Obsolete Scripts (0 risk, 1 minute)

```bash
# Mark as not executable or move to archive
chmod -x Scripts/check_mathcore_package_sync.sh
chmod -x Scripts/sync_mathcore_to_package.sh
# Or: mv to Docs/archive/
```

### Phase C: Remove Build Caches (0 risk, 1 minute)

```bash
rm -rf eMathica/eMathica/eMathica/.build_derived
rm -rf Packages/*/.build
```

### Phase D: Move icon design and ML models (optional, medium risk)

These can be moved to `~/Archive/eMathica/` since they're not part of the build. However, they may be useful for future reference.

### Total: ~3 minutes, 0 build risk.

---

## 12. High-Risk Operations to Avoid

| Operation | Risk | Why |
|-----------|------|-----|
| Flatten `eMathica/eMathica/eMathica/eMathica` | 🔴 CRITICAL | Breaks all pbxproj relative paths |
| Move `eMathica.xcodeproj` | 🔴 CRITICAL | Xcode won't open the project |
| Move `Packages/EMathicaMathCore` | 🔴 CRITICAL | xcodeproj relativePath breaks |
| Move other Packages | 🟡 HIGH | pbxproj ../../Packages relativePath breaks |
| Rename any `eMathica/` directory | 🔴 CRITICAL | Cascading path breakage |
| Move `.git/` | 🔴 CRITICAL | Loses version history |
| Delete `Docs/archive/` | 🟢 LOW | Only documentation, no build impact |
| Delete `CalculatorModules/` tree | 🔴 CRITICAL | Plane/Space/Commands still compiled from here |
| Delete `DocumentSystem/` | 🔴 CRITICAL | LocalProjectStore still compiled from here |
| Delete `OpenMathInk Collector/` | 🟡 MEDIUM | Separate project, but may be valuable |

---

## Appendix A: File Count by Module

| Module | .swift Files | In Build? | Package? |
|--------|-------------|-----------|----------|
| App/ | 5 | ✅ Target | ❌ |
| CoreHome/ | 30 | ✅ Target | ❌ |
| CalculatorModules/Plane/ | 35 | ✅ Target | ❌ |
| CalculatorModules/Space/ | 8 | ✅ Target | ❌ |
| CalculatorModules/Commands/ | 2 | ✅ Target | ❌ |
| CalculatorModules/Other/ | 4 | ✅ Target | ❌ |
| CalculatorModules/ Root | 5 | ✅ Target | ❌ |
| DocumentSystem/ | 13 | ✅ Target | ❌ |
| PluginSystem/ | 5 | ✅ Target | ❌ |
| EMathicaMathCore | 73 | ✅ Package | ✅ |
| EMathicaDocumentKit | 12 | ✅ Package | ✅ |
| EMathicaThemeKit | 10 | ✅ Package | ✅ |
| EMathicaWorkspaceKit | 68 | ✅ Package | ✅ |
| EMathicaMathInputKit | 8 | ❌ Not adopted | ⏳ |
| eMathicaTests | 33 | ✅ Tests | ❌ |
| eMathicaUITests | 2 | ✅ UITests | ❌ |

## Appendix B: Build Verification Commands

```bash
# Verify app build
xcodebuild -project eMathica.xcodeproj -scheme eMathica \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

# Verify packages
cd Packages/EMathicaMathCore && swift test     # 334 tests
cd Packages/EMathicaDocumentKit && swift build  # 1 test
cd Packages/EMathicaThemeKit && swift build     # 1 test
cd Packages/EMathicaWorkspaceKit && swift build # 1 test
cd Packages/EMathicaMathInputKit && swift test  # 17 tests
```
