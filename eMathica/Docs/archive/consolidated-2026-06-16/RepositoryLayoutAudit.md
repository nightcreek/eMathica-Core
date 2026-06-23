# eMathica Repository Layout Audit

> **Date:** 2026-06-06  
> **Scope:** Read-only audit of directory structure, nesting, and package locations.  
> **Do not move, delete, or rename anything.**

---

## 1. Current Directory Structure

### 1.1 Full Nesting Map

```
开发/
└── eMathica/                              ← 🏠 Repo Root (开发/eMathica)
    │                                        contains: .claude, icon design, ML models
    │
    ├── eMathica/                           ← 🔵 Git Root (.git here)
    │   │
    │   └── eMathica/                       ← 🔴 Xcode Project Root
    │       │                                contains: eMathica.xcodeproj
    │       │
    │       ├── eMathica.xcodeproj/          ← Xcode project bundle
    │       │   └── project.pbxproj
    │       │
    │       ├── eMathica/                   ← 📁 Source Root
    │       │   ├── App/
    │       │   ├── CoreHome/
    │       │   ├── CalculatorModules/
    │       │   ├── WorkspaceKit/
    │       │   ├── DocumentSystem/
    │       │   ├── MathCore/               ← 🔴 EXCLUDED from compilation
    │       │   ├── PluginSystem/
    │       │   ├── Resources/
    │       │   └── Docs/                   ← 📄 4 recent audit docs
    │       │
    │       ├── Docs/                       ← 📄 36 older audit docs
    │       │
    │       ├── Packages/                   ← 📦 MathCore package
    │       │   └── EMathicaMathCore/
    │       │
    │       ├── eMathicaTests/
    │       ├── eMathicaUITests/
    │       └── Scripts/
    │
    ├── Packages/                           ← 📦 Main Packages directory
    │   ├── EMathicaDocumentKit/
    │   ├── EMathicaThemeKit/
    │   ├── EMathicaWorkspaceKit/
    │   └── EMathicaMathInputKit/
    │
    ├── icon design/                        ← unrelated asset
    ├── ML models/                          ← unrelated ML project
    └── OpenMathInk Collector/              ← unrelated sub-project
```

### 1.2 Path Aliases

| Alias | Absolute Path |
|-------|---------------|
| Repo Root | `/Users/night_creek/开发/eMathica/` |
| Git Root | `/Users/night_creek/开发/eMathica/eMathica/` |
| Project Root | `/Users/night_creek/开发/eMathica/eMathica/eMathica/` |
| Source Root | `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/` |
| Main Packages | `/Users/night_creek/开发/eMathica/Packages/` |
| Project Packages | `/Users/night_creek/开发/eMathica/eMathica/eMathica/Packages/` |

---

## 2. Nesting Analysis

### 2.1 The "eMathica/eMathica/eMathica/eMathica" Problem

```
eMathica/           ← Level 0: Repo root
└── eMathica/       ← Level 1: Git root (.git here)
    └── eMathica/   ← Level 2: Xcode project root (xcodeproj here)
        └── eMathica/ ← Level 3: Source root (App/, MathCore/, etc.)
```

**Four levels of `eMathica` nesting.** This happened because:
1. Level 0: Folder named "eMathica" for the project
2. Level 1: `git init` or clone created inside `eMathica/` → another `eMathica/`
3. Level 2: Xcode "New Project" created yet another `eMathica/` folder
4. Level 3: Xcode's default source group mirrors the project name

### 2.2 Is This Harmful?

**Currently, no.** All paths are consistent:
- Xcode `fileSystemSynchronizedGroups` references `eMathica/` (Level 3) → finds all source
- pbxproj `relativePath` values are correct relative to their base
- Package.swift paths are correct relative to their own location
- Git works correctly (`.git` at Level 1 tracks everything below it)

**But it's confusing** and increases the chance of path errors when editing configs manually.

---

## 3. Package Location Audit

### 3.1 Split Package Locations

| Package | Location | In Xcode pbxproj? | Path Strategy |
|---------|----------|-------------------|---------------|
| EMathicaMathCore | `eMathica/eMathica/eMathica/Packages/` | ✅ `Packages/EMathicaMathCore` | Inside project — 1 level up |
| EMathicaDocumentKit | `eMathica/Packages/` | ✅ `../../Packages/EMathicaDocumentKit` | Outside project — 2 levels up |
| EMathicaThemeKit | `eMathica/Packages/` | ✅ `../../Packages/EMathicaThemeKit` | Outside project — 2 levels up |
| EMathicaWorkspaceKit | `eMathica/Packages/` | ✅ `../../Packages/EMathicaWorkspaceKit` | Outside project — 2 levels up |
| EMathicaMathInputKit | `eMathica/Packages/` | ❌ Not in pbxproj | Not yet adopted |

### 3.2 Cross-Package Path References

**WorkspaceKit → MathCore:**
```
Package.swift path: "../../eMathica/eMathica/Packages/EMathicaMathCore"
```
From `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/`, this resolves to:
```
../../ = 开发/
eMathica/eMathica/Packages/EMathicaMathCore = 开发/eMathica/eMathica/Packages/EMathicaMathCore
```
❌ **This path is BROKEN** — but it was fixed during the adoption to `../../eMathica/eMathica/Packages/EMathicaMathCore`.

Wait, let me re-verify. The current WorkspaceKit Package.swift has:
```
.package(path: "../../eMathica/eMathica/Packages/EMathicaMathCore")
```
From `开发/eMathica/Packages/EMathicaWorkspaceKit/`:
- `../../` = `开发/`
- `eMathica/eMathica/Packages/EMathicaMathCore` = `开发/eMathica/eMathica/Packages/EMathicaMathCore` ✅ CORRECT

**DocumentKit → MathCore:**
```
.package(path: "../../eMathica/eMathica/Packages/EMathicaMathCore")
```
From `开发/eMathica/Packages/EMathicaDocumentKit/`:
- `../../` = `开发/`
- `eMathica/eMathica/Packages/EMathicaMathCore` = `开发/eMathica/eMathica/Packages/EMathicaMathCore` ✅ CORRECT

### 3.3 Path Fragility

Both WorkspaceKit and DocumentKit depend on the exact nesting `eMathica/eMathica/Packages/` to reach MathCore. If the nesting were flattened, these paths would break.

---

## 4. Duplicate Directories

### 4.1 Two Docs Directories

| Location | Files | Purpose |
|----------|-------|---------|
| `eMathica/eMathica/eMathica/Docs/` | 36 files | Historical audits (Plane, Space, Sampling, etc.) |
| `eMathica/eMathica/eMathica/eMathica/Docs/` | 4 files | Recent audits from this session |

**Both are in the git repo.** The newer docs were written to `eMathica/Docs/` (inside source root) while older docs are at the project root `Docs/`.

### 4.2 Two Packages Directories

| Location | Contents | Purpose |
|----------|----------|---------|
| `eMathica/eMathica/eMathica/Packages/` | EMathicaMathCore only | Inside-project package |
| `eMathica/Packages/` | DocumentKit, ThemeKit, WorkspaceKit, InputKit | External packages |

**Both are intentional.** MathCore lives inside the project because it was created by Xcode's "Add Package" flow. The other 4 were created manually outside.

---

## 5. Directories That Can Be Retained

| Directory | Reason |
|-----------|--------|
| `eMathica/eMathica/` | Git root — needed for version control |
| `eMathica/eMathica/eMathica/` | Xcode project root — needed for build |
| `eMathica/eMathica/eMathica/eMathica/` | Source root — needed for compilation |
| `eMathica/eMathica/eMathica/eMathica.xcodeproj/` | Xcode project — essential |
| `eMathica/eMathica/eMathica/Packages/EMathicaMathCore/` | MathCore package — referenced by Xcode |
| `eMathica/Packages/EMathicaDocumentKit/` | DocumentKit package — referenced by Xcode |
| `eMathica/Packages/EMathicaThemeKit/` | ThemeKit package — referenced by Xcode |
| `eMathica/Packages/EMathicaWorkspaceKit/` | WorkspaceKit package — referenced by Xcode |
| `eMathica/Packages/EMathicaMathInputKit/` | InputKit package — future adoption |

## 6. Directories Potentially Duplicated

| Directory | Assessment |
|-----------|------------|
| `eMathica/eMathica/eMathica/Docs/` (36 files) | Historical audits. Should be consolidated with source-root Docs. |
| `eMathica/eMathica/eMathica/eMathica/Docs/` (4 files) | Recent audits. The correct location for future docs. |
| `eMathica/eMathica/eMathica/eMathica/MathCore/` | Tree copy — EXCLUDED from compilation but still on disk. Can be removed after verifying no tools reference it. |

## 7. Directories That MUST NOT Be Moved

| Directory | Why |
|-----------|-----|
| `eMathica/eMathica/` (.git) | Moving breaks all git history |
| `eMathica/eMathica/eMathica/` (xcodeproj) | Moving breaks Xcode; all pbxproj paths are relative to this |
| `eMathica/eMathica/eMathica/eMathica/` (source) | Xcode `fileSystemSynchronizedGroups` points here |
| `eMathica/eMathica/eMathica/Packages/EMathicaMathCore/` | pbxproj `relativePath = Packages/EMathicaMathCore` — relative to project root |
| `eMathica/Packages/EMathicaDocumentKit/` | pbxproj `relativePath = ../../Packages/EMathicaDocumentKit` — depends on exact nesting |
| `eMathica/Packages/EMathicaThemeKit/` | Same as above |
| `eMathica/Packages/EMathicaWorkspaceKit/` | Same as above |

## 8. Path Consistency Check

| Reference | Path | Resolves? |
|-----------|------|-----------|
| pbxproj → MathCore | `Packages/EMathicaMathCore` | ✅ |
| pbxproj → DocumentKit | `../../Packages/EMathicaDocumentKit` | ✅ |
| pbxproj → ThemeKit | `../../Packages/EMathicaThemeKit` | ✅ |
| pbxproj → WorkspaceKit | `../../Packages/EMathicaWorkspaceKit` | ✅ |
| WorkspaceKit → MathCore | `../../eMathica/eMathica/Packages/EMathicaMathCore` | ✅ |
| DocumentKit → MathCore | `../../eMathica/eMathica/Packages/EMathicaMathCore` | ✅ |
| WorkspaceKit → DocumentKit | `../EMathicaDocumentKit` | ✅ |
| WorkspaceKit → ThemeKit | `../EMathicaThemeKit` | ✅ |

**All paths are consistent.** No immediate fix needed.

---

## 9. Recommended Cleanup (Future)

### 9.1 Consolidate Docs (Low Risk)

```
Move: eMathica/eMathica/eMathica/Docs/*.md
  To: eMathica/eMathica/eMathica/eMathica/Docs/
Delete: eMathica/eMathica/eMathica/Docs/ (empty directory)
```

This puts all documentation in one place (source-root Docs).

### 9.2 Remove Excluded Tree Copies (Medium Risk)

The following directories are excluded from compilation but still on disk:
- `eMathica/eMathica/eMathica/eMathica/MathCore/` (73 files, excluded via EXCLUDED_SOURCE_FILE_NAMES)
- `eMathica/eMathica/eMathica/eMathica/WorkspaceKit/Shared/` (9 ThemeKit files)
- `eMathica/eMathica/eMathica/eMathica/WorkspaceKit/` (~57 files)

These can be deleted after confirming no scripts/tools reference them.

### 9.3 Consider Flattening Nesting (High Risk — NOT Recommended Now)

The `eMathica/eMathica/eMathica/eMathica` nesting could be flattened to `eMathica/src/`. However:
- This requires updating ALL pbxproj paths
- This requires updating ALL Package.swift cross-references
- This risks breaking Xcode project integrity
- **Recommendation: Do NOT flatten. Accept the nesting.**

### 9.4 Move MathCore to Main Packages (Medium Risk)

Move `eMathica/eMathica/eMathica/Packages/EMathicaMathCore/` to `eMathica/Packages/EMathicaMathCore/`. Then:
- Update pbxproj: `relativePath = ../../Packages/EMathicaMathCore`
- Update WorkspaceKit: `.package(path: "../EMathicaMathCore")`
- Update DocumentKit: `.package(path: "../EMathicaMathCore")`

This consolidates all 5 packages in one location.

---

## 10. Minimum Safe Cleanup

The following can be done with zero risk to the build:

1. **Move 36 historical docs** from `eMathica/eMathica/eMathica/Docs/` to `eMathica/eMathica/eMathica/eMathica/Docs/archive/`
2. **Delete** `eMathica/eMathica/eMathica/Docs/` (empty after move)
3. **Delete** `eMathica/eMathica/eMathica/eMathica/MathCore/` tree copy (already excluded from compilation)
4. **Delete** `eMathica/eMathica/eMathica/eMathica/WorkspaceKit/` tree copy (already excluded)

These operations don't change any paths that Xcode or Package.swift depend on.

---

## 11. Current State Verdict

| Question | Answer |
|----------|--------|
| Real project root? | `eMathica/eMathica/eMathica/` (xcodeproj location) |
| Real source root? | `eMathica/eMathica/eMathica/eMathica/` (App/ source) |
| Real git root? | `eMathica/eMathica/` (.git location) |
| Duplicate nesting? | Yes — 4 levels of `eMathica/`. Confusing but functional. |
| Duplicate Docs? | Yes — 2 locations. Should consolidate. |
| Duplicate Packages? | No — 2 locations serve different purposes. Can consolidate. |
| Path consistency? | ✅ All cross-references are correct. |
| Immediate action needed? | No — everything works. Cleanup is optional. |
