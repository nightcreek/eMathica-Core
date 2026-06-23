# Roadmap

Single source of roadmap truth for eMathica.

Merged from: FutureCalculatorRoadmap.md, PostCapabilityAuditArchitectureCorrectionPlan.md

---

## Priority Stack

```
P0 — DocumentSystem Deduplication      ← P0-A DONE, P0-B BLOCKED (reclassified to P3)
P1 — Design Freeze                      ← NEXT
P2 — MathCore Split + point.2d↔3d
P3 — Normalize First                    ← Package split + EMathicaDocumentKit creation
P4 — Future Inventory
```

---

## Phase Status

| Phase | Status | Description |
|-------|:------:|-------------|
| **Phase 0** | Complete | Repository Audit, Capability Audit, Package Audit, AI Knowledge Base |
| **Phase 1** | P0-A done, P0-B blocked | P0 DocumentSystem Dedup (A1-A3 audits complete) |
| **Phase 2** | Designed, not started | P1 Design Freeze |
| **Phase 3** | Designed, not started | P2 MathCore Split |
| **Phase 4** | Designed, not started | P3 Normalize First |
| **Phase 5** | Designed, not started | P4 Future Inventory |

**Current engineering position:** Stage A audits complete. P0-A (GeometryDefinition deletion) DONE. P0-B (DocumentSystem type deduplication) BLOCKED — requires creating EMathicaDocumentKit Package, which violates Architecture Freeze. P0-B reclassified to P3.

---

## P0 — DocumentSystem Deduplication

**Goal:** Eliminate the stale `GeometryDefinition.swift` copy and verify DocumentSystem boundaries.

### P0-A: Delete GeometryDefinition.swift ✅ DONE

- **File:** `DocumentSystem/GeometryDefinition.swift` (stale App Target copy)
- **Problem:** Stale copy — missing `.arc` case, no `Sendable` conformance, missing `point3D`, `pointB3D`, `vector3D` fields
- **Action:** ~~Delete file~~ **DELETED.** Package version (`EMathicaMathCore/GeometryDefinition.swift`) is now resolved by `DocumentObjectPatch`.

### P0-B: Import Verification — BLOCKED (reclassified to P3)

**Discovery:** EMathicaDocumentKit Package does not exist on disk. xcodeproj references `../../Packages/EMathicaDocumentKit` but the directory is empty/missing.

**What this means:**
- DocumentSystem types (`EMathicaDocument`, `DocumentCommand`, `DocumentObjectPatch`, etc.) are **App Target definitions**, not duplicates
- `LocalProjectStore.swift` has `import EMathicaDocumentKit` but the package doesn't exist
- **P0-B is now "EMathicaDocumentKit Package Creation"** — requires modifying xcodeproj, violating Architecture Freeze

**P0-B execution requires (P3):**
1. Create `Packages/EMathicaDocumentKit/` directory
2. Move DocumentSystem types to the new Package
3. Update xcodeproj package references
4. Verify all `import EMathicaDocumentKit` statements work

### P0 Stop Condition

~~All tests pass. No App Target file imports DocumentKit internals. `GeometryDefinition.swift` is deleted.~~

**P0-A ✅ DONE.** P0-B deferred to P3. Stage A audits (A1-A3) complete. Ready to enter Stage B.

---

## P1 — Design Freeze

**Goal:** Freeze the object system design, conversion model, and Calculator architecture before writing implementation code.

### P1-A: ObjectKind Registry

- Finalize the 38 ObjectKind definitions
- Create `ObjectKind` type (string-backed enum or struct)
- Migrate all existing `MathObjectType` references to `ObjectKind`

### P1-B: Object Header Implementation

- Implement `ObjectHeader` struct with MUST/SHOULD/MAY fields
- Add `kind: ObjectKind` to all existing object types

### P1-C: Calculator Protocol

- Define `Calculator` protocol with four components (View Adapter, Interaction Adapter, Tool Provider, Capability Consumer)
- Refactor Plane to conform to Calculator protocol
- Verify Plane still works correctly after protocol extraction

### P1-D: Architecture Decision Records Ratification

- Formalize ADR-001 through ADR-005
- No new ADRs without audit process

### P1 Stop Condition

`ObjectKind` type exists and is used throughout the codebase. `Calculator` protocol exists and Plane conforms to it. All existing functionality preserved.

---

## P2 — MathCore Split + point.2d↔3d

**Goal:** Split EMathicaMathCore into domain packages and implement the first materialize conversion.

### P2-A: MathCore Package Split

Extract from `EMathicaMathCore`:
- `EMathicaCASCore` — CAS operations (normalize, simplify, canonicalize, solve, differentiate)
- `EMathicaAlgebraCore` — Algebra operations (polynomial expansion, factorization)
- `EMathicaSemanticCore` — Expr types, AST definitions
- `EMathicaMathCore` (remainder) — Rendering primitives, sampling

### P2-B: point.2d → point.3d Conversion

First materialize conversion:
- Implement `object.convert.point2d.toPoint3d` capability
- Create `trans.json` recording in `.emathica/`
- Default z=0 embedding
- UI: "Open in Space" action on Plane points

### P2-C: point.3d → point.2d Conversion

Reverse conversion:
- Implement `object.convert.point3d.toPoint2d` capability
- Drop z coordinate (xy projection)
- Safety level: Warning (information loss)

### P2 Stop Condition

MathCore split complete. Both point conversions work end-to-end. trans.json records each conversion.

---

## P3 — Normalize First

**Goal:** Normalize package structure before adding new features.

### P3-A: EMathicaDocumentKit Package Creation (moved from P0-B)

- **Create** `Packages/EMathicaDocumentKit/` directory
- **Move** DocumentSystem types to the new Package:
  - `EMathicaDocument.swift` → Package
  - `DocumentCommand.swift` → Package
  - `DocumentObjectPatch.swift` → Package
  - `ProjectMetadata.swift` → Package
  - `IO/ProjectStore.swift` → Package
  - `IO/ProjectStoreError.swift` → Package
  - `Package/EMathicaPackageCodec.swift` → Package
  - `Package/EMathicaPackageLayout.swift` → Package
- **Update** `LocalProjectStore.swift` to use the new Package
- **Verify** all `import EMathicaDocumentKit` statements work

### P3-B: WorkspaceKit Split

Extract from `EMathicaWorkspaceKit`:
- `EMathicaMathInputKit` — LaTeX parsing, structured input, canonicalization, diagnostics
- `EMathicaFormulaRenderKit` — Formula rendering (currently in WorkspaceKit, should be standalone)
- `EMathicaWorkspaceKit` (remainder) — State management, command handling, object panel

### P3-C: ObjectKit Creation

New package `EMathicaObjectKit`:
- ObjectKind type and registry
- ObjectHeader struct
- DependencyGraph implementation
- Conversion Engine (capability routing)
- trans.json I/O

### P3-D: PreviewKit Normalization

`EMathicaPreviewKit` currently:
- Was initially considered "ready to package" by early audits
- Post-capability audit downgraded to P3: "Normalize First"
- Needs: clear API surface, documented plugin boundary, removal of WorkspaceKit coupling

### P3-E: 19-Package Blueprint

Execute the full 19-package split defined in `AI/Audits/FuturePackageSplitProposal.md`. This includes PluginKit packages for sandboxed plugin execution.

### P3 Stop Condition

EMathicaDocumentKit Package created and functional. All packages defined in the 19-package blueprint exist. No circular dependencies. All tests pass. Plugin sandboxing is in place.

---

## P4 — Future Inventory

**Goal:** Complete the remaining Calculator implementations and capability surface.

### P4-A: Remaining Conversions

8 remaining planned conversions beyond point.2d↔point.3d:
- `curve.explicit2d → wave.audio`
- `curve.explicit2d → table.data`
- `curve.parametric2d → table.data`
- `table.data → curve.explicit2d`
- `surface.explicit3d → curve.implicit2d`
- `table.data → set.pointSet2d`
- `set.pointSet2d → table.data`

### P4-B: New Calculator Implementations

| Calculator | Priority | Blocked By |
|------------|:--------:|------------|
| Space | High | P2 (MathCore split), P3 (WorkspaceKit split) |
| CAS | Medium | P2, P3 |
| Music | Low | P2, P4-A (curve→wave conversion) |
| Simulation | Low | P2, P3, P4-A |
| Text | Low | P3 (WorkspaceKit split) |

### P4-C: Plugin System

- Implement four-tier plugin exposure policy (safe, internal, restricted, sandboxed)
- Plugin marketplace / discovery
- Plugin sandbox runtime

### P4 Stop Condition

All 6 Calculators are implemented and compliant. All 9 conversion paths work. Plugin system is operational.

---

## Calculator MVP Summaries

(from FutureCalculatorRoadmap.md)

### Plane Calculator (85% compliant)
- **Current:** Works but owns too much DocumentSystem logic
- **Target:** Thin Calculator composing WorkspaceKit generic services
- **Blocking:** P1 (Calculator protocol), P3 (WorkspaceKit split)

### Space Calculator (45% compliant)
- **Current:** 3D rendering works but has no own Calculator identity
- **Target:** Full Calculator with orbit controls, 3D tool palette, point.3d/surface.* support
- **Blocking:** P1 (Calculator protocol), P2 (point.2d↔3d conversion)

### Music Calculator (0% compliant)
- **Target:** Audio waveform rendering from curve.* objects, playback, frequency analysis
- **Blocking:** P2, P3, P4-A (curve→wave conversion)

### CAS Calculator (0% compliant)
- **Target:** Standalone CAS workspace for formula.*, relation.*, table.* objects
- **Blocking:** P2 (CASCore extraction), P3 (WorkspaceKit split)

### Simulation Calculator (0% compliant)
- **Target:** Physics/ODE simulation from relation.* objects
- **Blocking:** P2, P3, P4-A

### Text Calculator (0% compliant)
- **Target:** Rich text document with embedded formula.* and image.* objects
- **Blocking:** P3 (WorkspaceKit split)

---

## Dependency Order

```
P0-A ✅ DONE
P0-B ⏸️ BLOCKED → P3
  └─► P1 (Design Freeze)
        └─► P2 (MathCore Split + point.2d↔3d)
              └─► P3 (Normalize First — package split + EMathicaDocumentKit creation)
                    └─► P4 (Future Inventory — calculators + plugins)
```

Each phase depends on the completion of the previous. No phase can be skipped.

**Note:** P0-B is blocked because it requires creating EMathicaDocumentKit Package, which violates Architecture Freeze. This does not block P1 — Stage B (Object System Design Freeze) can proceed.

---

## Long-Term Vision

1. **Document-Centric Architecture (97%)** — All 6 Calculators are thin composition layers over generic WorkspaceKit services
2. **38 ObjectKind Fully Supported** — Every kind has at least one Calculator that can create, edit, and render it
3. **Complete Conversion Network** — All 9 planned conversion paths implemented with trans.json audit trail
4. **Plugin Ecosystem** — Third-party plugins can extend Calculators, add ObjectKinds, and register new capabilities
5. **19-Package Architecture** — Fine-grained packages with clear dependency direction and no circular dependencies
