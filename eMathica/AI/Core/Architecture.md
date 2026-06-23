# Architecture

Single source of architectural truth for eMathica.

Merged from: UnifiedCalculatorArchitecture.md, PostCapabilityAuditArchitectureCorrectionPlan.md

---

## Four-Layer Architecture

```
┌─────────────────────────────────────────────────┐
│               Calculator Layer                    │
│  Plane | Space | Music | CAS | Simulation | Text  │
│  (View Adapter + Interaction Adapter)             │
├─────────────────────────────────────────────────┤
│              WorkspaceKit Bridge                  │
│  WorkspaceState, ObjectPanel, StructuredInput     │
├─────────────────────────────────────────────────┤
│               Document Layer                      │
│  EMathicaDocumentKit, ObjectStore, trans.json     │
├─────────────────────────────────────────────────┤
│                Package Layer                      │
│  MathCore | CASCore | AlgebraCore | ...           │
└─────────────────────────────────────────────────┘
```

### Layer Responsibilities

| Layer | Responsibility | Key Types |
|-------|---------------|-----------|
| **Calculator Layer** | UI binding, interaction handling, tool orchestration | Calculator protocol, View adapters |
| **WorkspaceKit Bridge** | State management, selection, input routing | WorkspaceState, ObjectRowViewModel |
| **Document Layer** | Object persistence, conversion records, file I/O | EMathicaDocument, ObjectStore, trans.json |
| **Package Layer** | Pure math computation, CAS, rendering primitives | Expr, Canonicalizer, PolynomialExpander |

---

## Calculator Definition

A Calculator is formally defined as:

```
Calculator = View Adapter + Interaction Adapter + Tool Provider + Capability Consumer
```

| Component | Role |
|-----------|------|
| **View Adapter** | Renders objects of supported kinds using domain-specific visualization |
| **Interaction Adapter** | Handles gestures, drags, selections in domain-specific ways |
| **Tool Provider** | Exposes domain-specific tools (e.g., ruler in Plane, orbit controls in Space) |
| **Capability Consumer** | Calls capabilities from Package Layer (e.g., CAS for computation) |

### Six Planned Calculators

| Calculator | Supported Kinds | Status | Compliance |
|------------|----------------|--------|:----------:|
| **Plane** | point.2d, line, curve.*, formula.*, text, image, slider, table.*, set.*, construction.* | Partial | 85% |
| **Space** | point.3d, surface.*, curve.*, formula.*, construction.* | Partial | 45% |
| **Music** | wave.*, formula.*, curve.* | Planned | 0% |
| **CAS** | formula.*, relation.*, table.* | Planned | 0% |
| **Simulation** | relation.*, set.*, curve.*, formula.* | Planned | 0% |
| **Text** | text.*, image.*, formula.* | Planned | 0% |

---

## Plane-Centric → Document-Centric Transition

### Current State: Plane-Centric (~50%)

The Plane calculator currently contains logic that should be generic:

1. **ObjectPanel** — Object detail/inspector UI, tied to Plane
2. **WorkspaceObjectRowView** — Row rendering with CAS integration, tied to Plane
3. **PlaneWorkspaceState** — Document-level state bound to Plane calculator
4. **PlaneCommandHandler** — Undo/redo tied to Plane, not Workspace
5. **WorkspaceObjectSnapshot** — Intended to be generic but Plane-coupled in practice
6. **PlaneToolRegistry** — Tool registration bound to Plane
7. **DraftMathObject** — Draft editing state tied to Plane

### Target State: Document-Centric (97%)

Transition plan (A→B→C→D):

1. **Step A** — Extract generic protocols from Plane services
2. **Step B** — Move generic implementations to WorkspaceKit
3. **Step C** — Plane becomes thin Calculator that composes generic services
4. **Step D** — New Calculators (Space, Music, etc.) compose same generic services

Transition priority is dictated by P0–P4 roadmap. See [Roadmap.md](Roadmap.md).

---

## Package Layering

### Current (5 Packages)

```
EMathicaMathCore (混合: Expr + CAS + Algebra + Rendering)
EMathicaWorkspaceKit (混合: State + Input + Rendering)
EMathicaDocumentKit
EMathicaApp (App Target)
EMathicaPreviewKit
```

### Target (19 Packages)

See `AI/Audits/FuturePackageSplitProposal.md` for full blueprint.

Key splits:

| From | To | Reason |
|------|----|--------|
| EMathicaMathCore | CASCore, AlgebraCore, SemanticCore | Domain separation |
| EMathicaWorkspaceKit | MathInputKit, FormulaRenderKit, WorkspaceKit | Concern separation |
| New | EMathicaObjectKit | ObjectKind + Conversion + trans.json |
| New | PluginKit (multiple) | Plugin sandboxing per exposure tier |

### Architecture Freeze

Until v1.0+, the following are **frozen**:
- No modification to `xcodeproj`
- No modification to `Package.swift`
- No addition of new Package targets

Rationale: the current 5-package structure is functional. Splitting to 19 packages should be a single coordinated effort (P3), not incremental drift.

---

## Current Architecture Risks

| Risk | Severity | Description |
|------|:--------:|-------------|
| **GeometryDefinition Stale Copy** | ~~Critical~~ Resolved | ~~`EMathicaApp/GeometryDefinition.swift` is a stale copy missing `.arc` case, lacks `Sendable`, missing `point3D`/`pointB3D`/`vector3D` fields. Must be deleted (P0-A).~~ **Deleted.** |
| **EMathicaDocumentKit Package Missing** | High | xcodeproj references `../../Packages/EMathicaDocumentKit` but the Package directory does not exist on disk. `LocalProjectStore.swift` imports a non-existent package. |
| **DocumentSystem Types are App Target Definitions** | High | `EMathicaDocument`, `DocumentCommand`, `DocumentObjectPatch` are defined in App Target, not in a Package. These are **not duplicates** — they are the actual definitions. |
| **Plane owns DocumentSystem logic** | High | PlaneWorkspaceState, PlaneCommandHandler, and ObjectPanel contain logic that should live in WorkspaceKit. |
| **36 files import EMathicaDocumentKit directly** | High | App Target files import DocumentKit directly instead of going through WorkspaceKit bridge. |
| **DependencyGraph is empty placeholder** | Medium | `DependencyGraph` struct has zero fields. Current dependency system is per-object `GeometryDependency` (Plane-only, 7 geometry-construction cases). No `DirectedEdge`, `EdgeKind`, reverse index, or cycle detection exists. |
| **No ObjectKit** | Medium | 38 ObjectKind have no home package. Conversion logic is planned but has no target package. |
| **WorkspaceKit is too thick** | Medium | Contains Input, Rendering, State, and Command handling — should be split. |
| **No Plugin sandboxing** | Medium | Plugin capabilities have no runtime isolation. Four-tier exposure policy designed but not implemented. |
| **trans.json not implemented** | Low | Conversion log format designed but no code exists. |

---

## Architecture Decision Records

### ADR-001: Calculator as Composition, Not Inheritance

Calculators compose generic services from WorkspaceKit and Package Layer. They do not inherit from a base Calculator class.

### ADR-002: Document is the Source of Truth

All object state lives in the Document. Calculators are stateless views over document state. UI state belongs to WorkspaceKit, not to individual Calculators.

### ADR-003: ObjectKind Over MathObjectType

`MathObjectType` enum is legacy. Future code must use `ObjectKind` string identifiers (e.g., `point.2d`, `curve.explicit2d`). See [ObjectSystem.md](ObjectSystem.md).

### ADR-004: Conversion is Materialize, Not View

When a user converts `point.2d` → `point.3d`, a new object is created with its own UUID. This is a **materialize conversion**, not a view adaptation. All conversions are recorded in `trans.json`.

### ADR-005: Architecture Freeze Until v1.0+

No structural changes to packages, targets, or project files until core refactoring (P0–P2) is complete.

---

## Stage A — Architecture Blocking Audit Findings

### A1: DocumentSystem Dependency Audit

**GeometryDefinition Duplication:**
- Package version (`Packages/EMathicaMathCore/Sources/EMathicaMathCore/GeometryDefinition.swift`): `public`, has `.arc`, `Sendable`, 5 fields (kind, anchors, point3D, pointB3D, vector3D)
- App Target version (`eMathica/DocumentSystem/GeometryDefinition.swift`): `internal`, missing `.arc`, no `Sendable`, only 2 fields

**Type Ambiguity Risk:**
- `DocumentSystem/GeometryDefinition.swift` **imports EMathicaMathCore** but also defines local internal versions
- `DocumentObjectPatch.geometryDefinition` resolves to the **local stale version**
- 36 App Target files import `EMathicaDocumentKit` directly

**Conclusion:** Stale copy can be safely deleted (Package version is superset).

### A2: MathObjectType Usage Audit

**Current State:** 9-case enum (.function, .point, .circle, .segment, .line, .ray, .parameter, .parameterGroup, .arc) — all 2D-biased

**Space Type Leaking:**
- Space uses `MathObjectType` + `GeometryDefinition.kind` to express 3D objects
- `.function` + `.plane3D` for plane.3d (type leaking!)
- `.point` + `.point3D` for point.3d
- `.segment` + `.segment3D` for segment.3d
- `.line` + `.line3D` for line.3d

**Usage Distribution:**
- 26 Plane files, 7 Space files, 15+ test files reference MathObjectType
- Plane uses `Set<MathObjectType>` for hit testing filtering

**Migration Strategy:** Add `kind: ObjectKind` string field to MathObject while keeping `type: MathObjectType` for backward compatibility.

### A3: Plane Capability Isolation Audit

| Service | Classification | Future Home |
|---------|:-------------:|-------------|
| PlaneExpressionService | B (generic) | WorkspaceKit / MathInputKit |
| PlaneGeometryResolver | A (Plane-specific) | Plane Calculator |
| PlaneHitTestService | A (Plane-specific) | Plane Calculator |
| PlaneObjectNamingService | B (generic) | WorkspaceKit (default) |
| PlaneDraftPreviewService | A (Plane-specific) | Plane Calculator |

**Key Finding:** Only 2 of 5 Plane services contain generic logic that should be abstracted. The other 3 are inherently 2D-specific (geometry, hit testing, preview).

---

## Recommended Next Steps (Stage A → Stage B)

1. ~~Delete GeometryDefinition.swift stale copy~~ — **P0-A ✅ DONE**
2. ~~DocumentSystem type deduplication~~ — **P0-B ❌ BLOCKED** (EMathicaDocumentKit Package does not exist; reclassified to P3)
3. **Add ObjectKind field to MathObject** — P1-A
4. **Abstract PlaneObjectNamingService to WorkspaceKit** — P1-B
5. **Abstract PlaneExpressionService to ExpressionBuilder** — P2

See [Roadmap.md](Roadmap.md) for full P0–P4 priority stack.

---

## EMathicaDocumentKit Package Analysis

### Discovery: Package Does Not Exist on Disk

xcodeproj references:
```
relativePath = ../../Packages/EMathicaDocumentKit
```

However, the directory `Packages/EMathicaDocumentKit/` **does not exist** on disk.

### What This Means

1. **EMathicaDocumentKit is referenced but not implemented** — The package was planned but never created
2. **DocumentSystem types are App Target definitions** — `EMathicaDocument`, `DocumentCommand`, `DocumentObjectPatch`, `ProjectMetadata`, `ProjectStore`, `ProjectStoreError`, `EMathicaPackageCodec`, `EMathicaPackageLayout` are all defined in the App Target's `DocumentSystem/` directory
3. **LocalProjectStore depends on non-existent package** — `DocumentSystem/IO/LocalProjectStore.swift` has `import EMathicaDocumentKit` but the package doesn't exist

### DocumentSystem File Classification

| File | Type | Defined In | Status |
|------|------|-----------|--------|
| `EMathicaDocument.swift` | `struct EMathicaDocument` | App Target | ✅ App Target definition |
| `DocumentCommand.swift` | `enum DocumentCommand` | App Target | ✅ App Target definition |
| `DocumentObjectPatch.swift` | `struct DocumentObjectPatch` | App Target | ✅ App Target definition |
| `ProjectMetadata.swift` | `struct ProjectMetadata` | App Target | ✅ App Target definition |
| `IO/ProjectStore.swift` | `protocol ProjectStore` | App Target | ✅ App Target definition |
| `IO/ProjectStoreError.swift` | `enum ProjectStoreError` | App Target | ✅ App Target definition |
| `IO/LocalProjectStore.swift` | `struct LocalProjectStore` | App Target | ⚠️ Imports non-existent package |
| `Package/EMathicaPackageCodec.swift` | `enum EMathicaPackageCodec` | App Target | ✅ App Target definition |
| `Package/EMathicaPackageLayout.swift` | `struct EMathicaPackageLayout` | App Target | ✅ App Target definition |

### Implication for P0-B

**P0-B is not "type deduplication"** — it's "package creation". The types in DocumentSystem/ are the **authoritative definitions**, not duplicates.

**P0-B execution requires:**
1. Create `Packages/EMathicaDocumentKit/` directory
2. Move DocumentSystem types to the new Package
3. Update xcodeproj package references
4. Verify all `import EMathicaDocumentKit` statements work

**This violates Architecture Freeze** — P0-B is reclassified to **P3 (after Architecture Freeze lifts)**.
