# PlaneGeometryParentChildAudit

## 1. Current behavior

Current GeometryDependency-1A status:

- `MathObject` now supports optional `geometryDependency`.
- Dynamic dependency is implemented only for `midpointOfPoints(pointAID, pointBID)`.
- Two-point midpoint creation writes dependency metadata.
- Source point moves trigger midpoint recompute in `WorkspaceState` through `PlaneGeometryDependencyRecomputeService`.

Important current UX behavior:

- Dragging a derived midpoint currently clears its dependency and converts it to a static point.

---

## 2. Where auto-static conversion happens today

Auto-clearing dependency on drag is implemented in:

- `eMathica/CalculatorModules/Plane/Commands/PlaneCommandHandler.swift`
  - `WorkspaceCommand.updateObjectPosition`
  - builds `DocumentObjectPatch(..., clearGeometryDependency: object.geometryDependency == nil ? nil : true)`

Dependency clearing is applied by:

- `eMathica/DocumentSystem/EMathicaDocument.swift`
  - in `.updateObject` handling:
    - `if patch.clearGeometryDependency == true { updated.geometryDependency = nil }`

So the behavior is command-level policy, persisted via document patch application.

---

## 3. Current parent/child management capability audit

### 3.1 What exists

- Child-side dependency metadata exists: `MathObject.geometryDependency`.
- Recompute service can find dependents by scanning all objects and matching source IDs.
- Dependency persistence works via Codable.

### 3.2 What does not exist yet

- No explicit `parentIDs` / `childIDs` fields.
- No reverse index cache manager.
- No object-row dependency badge/subtitle.
- No menu action for explicit unbind (convert to static).
- Delete/hide flows do not include dedicated dependency policy.

### 3.3 Implication

Current system has dependency storage and recompute capability, but no full parent/child lifecycle policy surface.

---

## 4. Parent/child semantic model (v1 recommendation)

Use dependency as the single source of truth:

- **Parent**: source objects referenced by a child dependency.
- **Child / derived object**: any object with `geometryDependency != nil`.

Rules:

1. Parent/child relation is inferred from `child.geometryDependency`.
2. Do not store `childIDs` on parent in document schema.
3. Add helper queries:
   - `parents(of child)`
   - `children(of parent)`
4. Persistence stores only child dependency.
5. Runtime reverse index is optional optimization; v1 can keep full scan.

This keeps schema minimal and avoids parent-child consistency drift.

---

## 5. Derived-object drag policy

Compared strategies:

- A) Drag derived => auto convert to static (current)
  - Simple, but surprising and easy to break geometry unintentionally.
- B) Derived object is not directly draggable
  - Stable geometry semantics and predictable behavior.
- C) Drag prompts confirmation to unbind
  - Explicit but UI-heavy for v1.

### Recommended v1

Adopt **B**:

- Derived objects are not directly draggable by default.
- Unbinding should be explicit via menu action.

Reason:

- Matches dynamic-geometry expectations.
- Avoids silent relationship breakage.
- Keeps behavior consistent for future dynamic midpoint/intersection/parallel/perpendicular.

---

## 6. Explicit unbind action design

Add row/menu action for derived objects:

- Label: `转为静态对象`
- Visible only when `object.geometryDependency != nil`

Action behavior:

1. Clear dependency only (`geometryDependency = nil`).
2. Preserve:
   - id
   - name
   - style
   - visibility
   - current geometry/position/expression text
3. No object recreation.
4. Source object movement no longer affects this object.

This should be the only standard user-facing unbind path in v1.

---

## 7. Parent deletion strategy

When parent is deleted, child dependency becomes unresolved.

Two options:

- A) Auto convert child to static (freeze last valid geometry)
- B) Keep dependency and mark invalid diagnostic

### Recommended v1

Use **A** (auto static conversion on source deletion):

- Minimal UX complexity.
- No dangling unresolved behavior requiring extra panel UX.
- Compatible with current lightweight dependency model.

Future upgrade path:

- Switch to invalid-diagnostic mode when dependency UI matures.

---

## 8. Parent hidden strategy

Options:

- Parent hidden implies child hidden.
- Child remains independently visible.

### Recommended v1

Keep **visibility independent**:

- Hiding parent does not force child hidden.
- Avoids coupled visibility surprises.
- Keeps implementation simple.

Potential future enhancement:

- optional visibility-link toggle in inspector.

---

## 9. Object row / inspector future display

Not required for immediate fix, but recommended:

- Derived badge/subtitle, e.g.:
  - `中点：A, B`
  - `平行：过 P，参考 l`
  - `交点：对象 A × 对象 B`
- Keep row compact; avoid changing panel height model abruptly.
- Inspector can later show parent references and one-click “转为静态对象”.

---

## 10. Unified policy for future dynamic tools

Apply the same rules to future dynamic:

- parallel
- perpendicular
- intersection

Unified behavior:

1. Creation writes dependency metadata.
2. Derived object is not directly draggable.
3. Explicit menu action converts to static.
4. Parent move triggers recompute.
5. Parent delete follows v1 auto-static policy.

---

## 11. Recommended implementation phases

### GeometryDependency-1A-fix

- Remove auto-clear-on-drag behavior for derived midpoint.
- Make derived midpoint drag no-op (or lightweight toast).
- Add `转为静态对象` command/menu action.
- Add tests:
  - dragging derived midpoint does not clear dependency
  - explicit convert-to-static clears dependency

### GeometryDependency-1B

- Add dynamic parallel/perpendicular with same parent-child policy.

### GeometryDependency-1C

- Add dynamic intersection with same policy.
- Define no-solution and multi-root stability handling.

---

## 12. Key risk

Largest near-term risk:

- Inconsistent behavior if some derived object types use auto-clear-on-drag while others use explicit unbind.

Mitigation:

- Lock one unified policy early (recommended: non-draggable derived + explicit convert-to-static).
