# Package Adoption Audit

> **Date:** 2026-06-06  
> **Scope:** Read-only audit of Xcode target vs. Package consumption.  
> **Prerequisites:** All 4 packages build and test independently.

---

## 1. Current Package Adoption Status

### 1.1 Summary Matrix

| Package | In Xcode `packageProductDependencies`? | Tree copy compiled by `fileSystemSynchronizedGroups`? | Actual source of types at build time | Status |
|---------|---------------------------------------|------------------------------------------------------|-------------------------------------|--------|
| EMathicaMathCore | ✅ Yes | ✅ Yes (all files under `MathCore/`) | **In-tree copy** (same module, takes precedence) | 🔴 Dual compilation |
| EMathicaDocumentKit | ❌ No | ✅ Yes (all files under `DocumentSystem/`) | In-tree copy | 🟡 Not adopted |
| EMathicaThemeKit | ❌ No | ✅ Yes (all files under `WorkspaceKit/Shared/`) | In-tree copy | 🟡 Not adopted |
| EMathicaWorkspaceKit | ❌ No | ✅ Yes (all files under `WorkspaceKit/`) | In-tree copy | 🟡 Not adopted |

### 1.2 How We Know

The project uses `fileSystemSynchronizedGroups`:

```
fileSystemSynchronizedGroups = (
    3CD3F4A12FADE7C5001036FF /* eMathica */,
);
```

This auto-discovers ALL `.swift` files under the `eMathica/` directory, including:
- `MathCore/` (73 files)
- `WorkspaceKit/` (~66 files)
- `DocumentSystem/` (12 files)
- `CalculatorModules/` (~45 files)
- `CoreHome/`, `App/`, etc.

The target's `packageProductDependencies` only lists:

```
packageProductDependencies = (
    A1B2C3D4E5F6012345678900 /* EMathicaMathCore */,
);
```

Only **EMathicaMathCore** is referenced. DocumentKit, ThemeKit, and WorkspaceKit are NOT in the dependencies array.

### 1.3 The Dual Compilation Problem (MathCore)

EMathicaMathCore is in a dangerous state:

1. **Package**: Referenced via `XCLocalSwiftPackageReference "Packages/EMathicaMathCore"` → compiled as a separate module
2. **In-tree**: `MathCore/` directory files are auto-discovered by `fileSystemSynchronizedGroups` → compiled as part of the app module

This means:
- `MathObject`, `MathExpression`, `WorldPoint`, etc. exist in **two places** at compile time
- The app module's versions take precedence (same-module access beats imported module)
- `import EMathicaMathCore` statements in WorkspaceKit files resolve to the **package module**, but the types used at call sites may come from the **in-tree module** → potential type mismatch

**Evidence it works anyway**: `xcodebuild` passes. This is because Swift treats types from different modules with the same name as distinct, but when both modules are linked, only one implementation survives. This is fragile and can break with any refactoring.

### 1.4 The Non-Adopted Packages (DocumentKit, ThemeKit, WorkspaceKit)

These 3 packages build independently (`swift build` passes) but are NOT wired into the Xcode target. The app compiles their in-tree copies:
- `DocumentSystem/` → 12 files compiled as part of app module
- `WorkspaceKit/Shared/` → 9 ThemeKit files compiled as part of app module
- `WorkspaceKit/` → ~66 files compiled as part of app module

---

## 2. Per-Package Detail

### 2.1 EMathicaMathCore

| Attribute | Value |
|-----------|-------|
| Package location | `eMathica/eMathica/Packages/EMathicaMathCore/` |
| Xcode reference | `XCLocalSwiftPackageReference "Packages/EMathicaMathCore"` |
| In-tree location | `eMathica/eMathica/eMathica/MathCore/` |
| Tree compiled? | ✅ Yes (auto-discovered) |
| Dual compilation? | 🔴 **YES** — 73 files compiled twice |
| Risk | 🔴 HIGH — type identity conflicts possible |

### 2.2 EMathicaDocumentKit

| Attribute | Value |
|-----------|-------|
| Package location | `Packages/EMathicaDocumentKit/` |
| Xcode reference | ❌ Not in pbxproj |
| In-tree location | `eMathica/eMathica/eMathica/DocumentSystem/` |
| Tree compiled? | ✅ Yes (auto-discovered) |
| Dual compilation? | 🟡 No (package not connected) |
| Risk | 🟡 MEDIUM — needs package wiring |

### 2.3 EMathicaThemeKit

| Attribute | Value |
|-----------|-------|
| Package location | `Packages/EMathicaThemeKit/` |
| Xcode reference | ❌ Not in pbxproj |
| In-tree location | `eMathica/eMathica/eMathica/WorkspaceKit/Shared/` + `CoreHome/Background/` |
| Tree compiled? | ✅ Yes (auto-discovered) |
| Dual compilation? | 🟡 No (package not connected) |
| Risk | 🟡 MEDIUM — needs package wiring |

### 2.4 EMathicaWorkspaceKit

| Attribute | Value |
|-----------|-------|
| Package location | `Packages/EMathicaWorkspaceKit/` |
| Xcode reference | ❌ Not in pbxproj |
| In-tree location | `eMathica/eMathica/eMathica/WorkspaceKit/` |
| Tree compiled? | ✅ Yes (auto-discovered) |
| Dual compilation? | 🟡 No (package not connected) |
| Risk | 🔴 HIGH — complex adoption due to imports and access control |

---

## 3. Switch Risk Assessment

### 3.1 MathCore Switch (Phase 1)

**What to do**: Remove `MathCore/` from fileSystemSynchronizedGroups and rely solely on the package.

**Risks**:
- Files that DON'T import `EMathicaMathCore` will lose access to MathCore types (they currently get them via same-module access)
- All files using `MathObject`, `MathExpression`, `CanvasState`, etc. need `import EMathicaMathCore` added
- Types in MathCore package are now `public` — must verify all needed types are accessible

**Affected files**: All files in `WorkspaceKit/`, `DocumentSystem/`, `CalculatorModules/`, `CoreHome/`, `App/` that reference MathCore types without explicit import.

**Risk level**: 🟡 MEDIUM — mechanical import additions, no logic changes.

### 3.2 DocumentKit Switch (Phase 2)

**What to do**: Add `EMathicaDocumentKit` to `packageProductDependencies`, remove `DocumentSystem/` from tree compilation.

**Risks**:
- Files using `EMathicaDocument`, `DocumentCommand`, need `import EMathicaDocumentKit`
- `LocalProjectStore.swift` must stay in-tree (depends on FileManager + ProjectPreviewRenderer)
- `ProjectPreviewRenderer` in `CoreHome/Preview/` must stay in-tree

**Affected files**: `WorkspaceKit/`, `CalculatorModules/`, `CoreHome/`, `App/` files referencing document types.

**Risk level**: 🟡 MEDIUM — similar to MathCore, mechanical imports.

### 3.3 ThemeKit Switch (Phase 3)

**What to do**: Add `EMathicaThemeKit` to `packageProductDependencies`, remove `WorkspaceKit/Shared/` ThemeKit files from tree compilation.

**Risks**:
- Files using `ColorToken`, `LiquidGlassPanel`, etc. need `import EMathicaThemeKit`
- The 9 ThemeKit files must be excluded from tree compilation while keeping the 4 non-ThemeKit Shared files

**Affected files**: `WorkspaceKit/WorkspaceView`, `ObjectPanel/`, `Inspector/`, `Toolbar/`, `Keyboard/`, `Input/` files.

**Risk level**: 🟢 LOW — scope is limited to 9 files + import additions.

### 3.4 WorkspaceKit Switch (Phase 4)

**What to do**: Add `EMathicaWorkspaceKit` to `packageProductDependencies`, remove `WorkspaceKit/` from tree compilation.

**Risks**:
- This is the BIG one — `WorkspaceKit/` is ~66 files consumed by the entire app
- EVERY file that references `WorkspaceState`, `WorkspaceView`, `CalculatorModuleType`, tool types, etc. needs proper imports
- The package has `@Observable` and `@Bindable` — cross-module observation requires public properties
- Plane stub (`PlaneGeometryStubs`) must be replaced by real Plane module at runtime via DI

**Affected files**: ~50+ files across `CalculatorModules/`, `CoreHome/`, `App/`.

**Risk level**: 🔴 HIGH — largest scope, most affected files, access control cascade likely.

---

## 4. Minimal Switch Steps

### Step 1: MathCore Deduplication (30 min)

```
1. Remove MathCore/ from fileSystemSynchronizedGroups (or add to exclusions)
2. Add "import EMathicaMathCore" to all files that reference MathCore types
   without the import (WorkspaceKit/, DocumentSystem/, CalculatorModules/, etc.)
3. xcodebuild → verify
4. Delete in-tree MathCore/ directory (optional, safe to keep as backup)
```

### Step 2: DocumentKit Adoption (30 min)

```
1. Add EMathicaDocumentKit to packageProductDependencies
2. Exclude DocumentSystem/ files from tree compilation
   (except LocalProjectStore.swift)
3. Add "import EMathicaDocumentKit" where needed
4. xcodebuild → verify
```

### Step 3: ThemeKit Adoption (20 min)

```
1. Add EMathicaThemeKit to packageProductDependencies
2. Exclude 9 ThemeKit files from tree compilation
3. Add "import EMathicaThemeKit" where needed
4. xcodebuild → verify
```

### Step 4: WorkspaceKit Adoption (1-2 hours)

```
1. Add EMathicaWorkspaceKit to packageProductDependencies
2. Exclude WorkspaceKit/ files from tree compilation
3. Add "import EMathicaWorkspaceKit" to CalculatorModules/, CoreHome/, App/
4. Handle @Observable cross-module access (public properties)
5. Handle PlaneGeometryStubs → real Plane module DI
6. xcodebuild → verify
```

---

## 5. Recommended Switch Order

```
Phase 1: MathCore deduplication       🟡 MEDIUM risk — 30 min
Phase 2: DocumentKit adoption          🟡 MEDIUM risk — 30 min
Phase 3: ThemeKit adoption             🟢 LOW risk    — 20 min
Phase 4: WorkspaceKit adoption         🔴 HIGH risk   — 1-2 hours
```

**Rationale**: MathCore is already partially connected (package reference exists), so fixing the dual compilation is the logical first step. DocumentKit and ThemeKit are small and self-contained. WorkspaceKit is the largest and most complex — it benefits from the experience gained in the earlier phases.

---

## 6. fileSystemSynchronizedGroups Strategy

The modern Xcode `fileSystemSynchronizedGroups` auto-discovers all `.swift` files under the directory. To exclude specific directories, add them to the `EXCLUDED_SOURCE_FILE_NAMES` build setting or restructure the file layout.

### Option A: Build Setting Exclusion

Add to target build settings:
```
EXCLUDED_SOURCE_FILE_NAMES = $(EXCLUDED_SOURCE_FILE_NAMES) MathCore/* WorkspaceKit/Shared/ColorToken.swift ...
```

### Option B: Directory Restructuring

Move files that should NOT be compiled into a directory excluded from the synchronized group. For example, move tree copies to `_Archived/` or delete them once package adoption is verified.

### Option C: Switch to Explicit File List

Replace `fileSystemSynchronizedGroups` with explicit file references in the pbxproj. This gives full control but is labor-intensive and fragile.

**Recommendation**: Option A (build setting exclusion) is the simplest and least invasive for Phase 1-3. Option B (delete tree copies) after verification.

---

## 7. Pre-Switch Verification Checklist

Before starting any switch, verify:

- [ ] `swift build` passes for the package being switched
- [ ] `swift test` passes
- [ ] `xcodebuild` passes (current state as baseline)
- [ ] All types needed by app are `public` in the package
- [ ] No type name collisions between package and tree copies
- [ ] Git working tree is clean (for easy rollback)

---

## 8. Post-Switch Verification

After each phase:

- [ ] `xcodebuild` passes with zero errors
- [ ] App launches in simulator
- [ ] Each calculator module loads correctly
- [ ] No duplicate symbol warnings
- [ ] No runtime crashes from type mismatches

---

## 9. Current File Count Comparison

| Directory | In-tree files | Package files | Overlap |
|-----------|-------------|---------------|---------|
| MathCore/ | 73 | 73 | 100% (all duplicated) |
| DocumentSystem/ | 12 | 12 (minus LocalProjectStore) | 92% |
| WorkspaceKit/Shared/ (ThemeKit) | 9 | 10 | 90% |
| WorkspaceKit/ (non-Shared) | ~57 | ~58 | ~98% |

---

## Appendix A: packageProductDependencies Current State

```
eMathica target:
  ✅ EMathicaMathCore
  ❌ EMathicaDocumentKit
  ❌ EMathicaThemeKit
  ❌ EMathicaWorkspaceKit

eMathicaTests target:
  ✅ EMathicaMathCore
  ❌ (others)

eMathicaUITests target:
  ❌ (none)
```

## Appendix B: FileSystemSynchronizedGroups Coverage

The group `3CD3F4A12FADE7C5001036FF /* eMathica */` references the directory:
```
eMathica/eMathica/eMathica/
```

Which contains ALL app source code:
```
App/
CoreHome/
CalculatorModules/
WorkspaceKit/
DocumentSystem/
MathCore/
PluginSystem/
Resources/
```

All `.swift` files under this tree are automatically compiled into the `eMathica` target.
