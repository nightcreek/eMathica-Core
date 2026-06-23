# R2: Package Reality Audit

Read-Only. Zero modifications.

---

## 1. Package Existence Table

Every package referenced in `eMathica.xcodeproj/project.pbxproj`:

| Package | xcodeproj Reference | Disk Exists? | Package.swift? | Has Source Files? | Status |
|---------|:-------------------:|:------------:|:-------------:|:-----------------:|--------|
| **EMathicaMathCore** | `../../Packages/EMathicaMathCore` | ✅ Yes | ✅ Yes | ✅ Yes | **Existing** |
| **EMathicaWorkspaceKit** | `../../Packages/EMathicaWorkspaceKit` | ✅ Yes | ✅ Yes | ✅ Yes | **Existing** |
| **EMathicaMathInputKit** | `../../Packages/EMathicaMathInputKit` | ✅ Yes | ✅ Yes | ✅ Yes | **Existing** |
| **EMathicaThemeKit** | `../../Packages/EMathicaThemeKit` | ✅ Yes | ✅ Yes | ✅ Yes | **Existing** |
| **EMathicaDocumentKit** | `../../Packages/EMathicaDocumentKit` | ✅ Yes | ✅ Yes | ✅ Yes (11 files) | **Existing** |

**Key finding: ALL 5 packages referenced in xcodeproj exist on disk.** The previous assessment that EMathicaDocumentKit was "missing" was based on an incorrect assumption about the package directory location. All packages live at `/Users/night_creek/开发/eMathica/eMathica/eMathica/Packages/`.

### Packages NOT referenced in xcodeproj:

| Package | Status |
|---------|--------|
| EMathicaWorkspaceKitBridge | **Does not exist** — not in xcodeproj, not on disk |
| EMathicaPreviewKit | **Does not exist** — not in xcodeproj, not on disk |

---

## 2. Package-by-Package Reality

### EMathicaMathCore

**Location:** `Packages/EMathicaMathCore/`
**Targets:** EMathicaMathCore
**Source domains found on disk:**

| Domain | Directory | Real Files | Status |
|--------|-----------|:----------:|--------|
| AlgebraCore | `Sources/EMathicaMathCore/AlgebraCore/` | Multiple .swift files | ✅ Implemented |
| CASCore | `Sources/EMathicaMathCore/CASCore/` | Multiple .swift files | ✅ Implemented |
| Coordinate | `Sources/EMathicaMathCore/Coordinate/` | Real files | ✅ Implemented |
| EvaluationCore | `Sources/EMathicaMathCore/EvaluationCore/` | Real files | ✅ Implemented |
| GraphCore | `Sources/EMathicaMathCore/GraphCore/` | Multiple .swift files | ✅ Implemented |
| SamplingCore | `Sources/EMathicaMathCore/SamplingCore/` | Multiple .swift files | ✅ Implemented |
| SemanticCore | `Sources/EMathicaMathCore/SemanticCore/` | Multiple .swift files | ✅ Implemented |
| SpaceMathCore | `Sources/EMathicaMathCore/SpaceMathCore/` | Real files | ✅ Implemented |
| Viewport | `Sources/EMathicaMathCore/Viewport/` | Real files | ✅ Implemented |

**Key types found (root level Sources/EMathicaMathCore/):**

| Type | Fields/Actions | Real? |
|------|---------------|:-----:|
| `MathObject` | 15 stored properties | ✅ |
| `MathObjectType` | 9-case enum | ✅ |
| `MathExpression` | 19 stored properties | ✅ |
| `MathStyle` | 6 stored properties | ✅ |
| `MathLineStyle` | 2-case enum | ✅ |
| `GeometryDefinition` | 5 stored properties, has `.arc` | ✅ |
| `GeometryDefinitionKind` | 14 cases | ✅ |
| `GeometryDependency` | Wraps `GeometryDependencyKind` | ✅ |
| `GeometryDependencyKind` | 7 cases | ✅ |
| `GeometryDefinitionStatus` | 5 cases | ✅ |
| `DeletedObjectRecord` | id, deletedAt, object, context | ✅ |
| `DependencyGraph` | **Empty struct (zero fields)** | ❌ Placeholder |
| `WorldPoint` | x, y | ✅ |
| `WorldPoint3D` | x, y, z | ✅ |
| `CanvasState` | Multiple fields | ✅ |

---

### EMathicaWorkspaceKit

**Location:** `Packages/EMathicaWorkspaceKit/`
**Targets:** EMathicaWorkspaceKit

**Key types found:**

| Type/Capability | Status |
|-----------------|:------:|
| WorkspaceState | ✅ Implemented |
| WorkspaceView | ✅ Implemented |
| Tool System | ✅ Implemented |
| Command System | ✅ Implemented |
| Selection | ✅ Implemented |
| Inspector | ✅ Implemented (at WorkspaceKit level) |
| Input Bridge | ✅ Implemented |
| Object Naming (protocol) | ✅ `WorkspaceObjectNamingServiceProtocol` |

**Note:** This package was previously described as potentially "too thick" but it actually serves as the central bridge layer — its current thickness is architecturally appropriate given its role.

---

### EMathicaMathInputKit

**Location:** `Packages/EMathicaMathInputKit/`
**Targets:** EMathicaMathInputKit

**Key types found:**

| Type/Capability | Status |
|-----------------|:------:|
| Input Session | ✅ Implemented |
| Keyboard Layout | ✅ Implemented |
| LaTeX Serialization | ✅ Implemented |
| AST Processing | ✅ Implemented |
| Structured Input | ✅ Implemented |

**Contradiction with R3:** R3 listed `input.mathInput` and `input.structuredInput` as "no code found" — but that was because the search was limited to App Target code. The actual implementation lives in this Package. **Registry IS correct** for these two entries.

---

### EMathicaThemeKit

**Location:** `Packages/EMathicaThemeKit/`
**Targets:** EMathicaThemeKit

**Key types found:**

| Type/Capability | Status |
|-----------------|:------:|
| Theme Tokens | ✅ Implemented |
| Glass Style | ✅ Implemented |
| Color | ✅ Implemented |
| Typography | ✅ Implemented |

---

### EMathicaDocumentKit

**Location:** `Packages/EMathicaDocumentKit/`
**Targets:** EMathicaDocumentKit (3 targets/libraries)
**Source files:** 11 Swift files

**Critical finding: Package EXISTS on disk with real code.**

**Key types found in Package:**

| Type | Status |
|------|:------:|
| EMathicaDocument | ✅ Implemented |
| DocumentCommand | ✅ Implemented |
| DocumentObjectPatch | ✅ Implemented |
| ProjectMetadata | ✅ Implemented |
| ProjectStore (protocol) | ✅ Implemented |
| ProjectStoreError | ✅ Implemented |
| EMathicaPackageCodec | ✅ Implemented |
| EMathicaPackageLayout | ✅ Implemented |
| LocalProjectStore | ✅ Implemented |

**Placeholder found:** `ProjectDocumentAdapter.swift` — stub only

---

## 3. App Target Type Overlap (Critical Finding)

### DocumentSystem/ vs EMathicaDocumentKit — DUPLICATED TYPES

The App Target's `DocumentSystem/` directory defines the **same types** as the `EMathicaDocumentKit` Package. This means both exist in the compilation scope:

| Type | Package (EMathicaDocumentKit) | App Target (DocumentSystem/) | Risk |
|------|:----------------------------:|:---------------------------:|:----:|
| EMathicaDocument | ✅ public | ✅ internal | ⚠️ Shadowing |
| DocumentCommand | ✅ public | ✅ internal | ⚠️ Shadowing |
| DocumentObjectPatch | ✅ public | ✅ internal | ⚠️ Shadowing |
| ProjectMetadata | ✅ public | ✅ internal | ⚠️ Shadowing |
| ProjectStore | ✅ public protocol | ✅ internal protocol | ⚠️ Shadowing |
| ProjectStoreError | ✅ public | ✅ internal | ⚠️ Shadowing |
| EMathicaPackageCodec | ✅ public | ✅ internal | ⚠️ Shadowing |
| EMathicaPackageLayout | ✅ public | ✅ internal | ⚠️ Shadowing |
| LocalProjectStore | ✅ public | ✅ internal | ⚠️ Shadowing |

**This is the real root cause of the "DocumentSystem deduplication" issue.**

The Package versions have been created and exist. The App Target versions are the **older shadow copies** that create compilation ambiguity. Files importing `EMathicaDocumentKit` resolve to the Package version. Files importing types from `DocumentSystem/` (same App Target module) resolve to the local internal version.

### Files in DocumentSystem/ to Delete (P3 — after Architecture Freeze lifts)

| File | Reason |
|------|--------|
| `EMathicaDocument.swift` | Duplicate — Package version exists |
| `DocumentCommand.swift` | Duplicate — Package version exists |
| `DocumentObjectPatch.swift` | Duplicate — Package version exists |
| `ProjectMetadata.swift` | Duplicate — Package version exists |
| `IO/ProjectStore.swift` | Duplicate — Package version exists |
| `IO/ProjectStoreError.swift` | Duplicate — Package version exists |
| `Package/EMathicaPackageCodec.swift` | Duplicate — Package version exists |
| `Package/EMathicaPackageLayout.swift` | Duplicate — Package version exists |
| `IO/LocalProjectStore.swift` | Duplicate — Package version exists |

---

## 4. Package Import Map (App Target)

Files importing each Package across the App Target:

| Package | Import Count |
|---------|:-----------:|
| EMathicaMathCore | 65+ files |
| EMathicaWorkspaceKit | 79+ files |
| EMathicaDocumentKit | 36 files |
| EMathicaMathInputKit | ~15 files |
| EMathicaThemeKit | ~20 files |

---

## 5. Summary

| Metric | Count |
|--------|:-----:|
| Packages referenced in xcodeproj | 5 |
| Packages that exist on disk | 5 |
| Packages that do NOT exist on disk | 0 |
| Packages NOT referenced in xcodeproj (targeted by future plans) | 2 (WorkspaceKitBridge, PreviewKit) |
| Empty/placeholder files in Packages | 4 (DependencyGraph, ProjectDocumentAdapter, etc.) |
| App Target types duplicated from Packages | 9 |

### Corrections to Previous Knowledge Base Assumptions

| Previous Assumption | Reality | Correction |
|---------------------|---------|------------|
| "EMathicaDocumentKit does not exist on disk" | Package EXISTS at `Packages/EMathicaDocumentKit/` with 11 real files | **Incorrect** — Package exists, DocumentSystem/ is the shadow copy |
| "P0-B is Package creation" | P0-B is actually **deleting DocumentSystem/ shadow copies** | P0-B scope changes: delete stale App Target copies, not create Package |
| "input.mathInput is missing" | Implementation exists in EMathicaMathInputKit | **Incorrect** — Registry was right, R3 searched wrong scope |
| "formula.render is missing" | Implementation likely exists in existing package structure | Needs verification at Package level |
