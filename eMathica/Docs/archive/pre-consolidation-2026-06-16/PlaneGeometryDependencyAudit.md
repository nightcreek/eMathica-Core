# PlaneGeometryDependencyAudit

## 1. Scope

This audit focuses on Plane geometry construction dependency behavior in current v1:

- midpoint
- intersection
- parallel
- perpendicular

Goal of this document: explain current static behavior, identify existing partial dynamic capability, and propose a minimal dynamic dependency design without changing parser/sampling/UI architecture.

---

## 2. Current Static Construction Behavior

## 2.1 What `MathObject` currently stores

From `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/MathCore/MathObject.swift`, each object stores:

- `id`
- `name`
- `type`
- `expression`
- `position` (mainly point)
- `points` (line-like raw endpoints cache)
- `geometryDefinition` (anchors + kind)
- `style`
- slider/parameter fields (for parameter objects)
- `isVisible`

There is **no dependency field** (no parent IDs, no construction recipe, no derived relation metadata).

## 2.2 GeometryDefinition capability

From `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/DocumentSystem/GeometryDefinition.swift`:

- `GeometryKind`: `point / segment / line / ray`
- `GeometryAnchor`: `.object(UUID)` or `.fixedPoint(WorldPoint)`

This can express anchor references, but not higher-level relation intent like midpoint/intersection/parallel/perpendicular derivation.

## 2.3 Current tool outputs for derived constructions

From `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/CalculatorModules/Plane/Commands/PlaneCommandHandler.swift`:

- midpoint creates a new `MathObject(type: .point)` with computed position.
- intersection creates one or multiple `MathObject(type: .point)` with computed positions.
- parallel/perpendicular create `MathObject(type: .line)` using computed direction and through point.

All are currently **static snapshot outputs** at construction time.

---

## 3. Existing Update / Re-render Model

## 3.1 Drag/update command path

- Canvas drag dispatches `WorkspaceCommand.updateObjectPosition`.
- Handler only allows moving `.point` (guarded in PlaneCommandHandler).
- It emits `DocumentCommand.updateObject(id:patch:)` with new `position` and point display text.
- `EMathicaDocument.apply` mutates object fields directly.

No recompute hook exists after `updateObject`.

## 3.2 Existing partial dynamic capability (already present)

`PlaneGeometryResolver` resolves line-like endpoints from anchors:

- segment: `segmentEndpoints(...)`
- line: `linePoints(...)`
- ray: `rayPoints(...)`
- via `GeometryAnchor.object(id)` -> current point position

Renderer/hit-test path reads geometry each frame through resolver.  
Therefore:

- If a line/segment/ray anchors to points, moving those points updates rendered geometry.

This is already a **limited dynamic reference effect**, but only for direct anchor-based geometry, not for derived relationship objects.

## 3.3 Why midpoint/intersection/parallel/perpendicular do not stay constrained

Derived objects currently store solved result coordinates (point position or line direction points), but no derivation recipe.  
After source object changes, no system knows derived objects should recompute.

---

## 4. Current Patchability of Document/Object Update

From `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathica/DocumentSystem/DocumentObjectPatch.swift` and `EMathicaDocument.apply`:

- Patch supports expression/position/style/visibility/slider fields.
- Patch does **not** support `geometryDefinition` mutation.
- No post-update callback/hook in `EMathicaDocument.apply`.

So dynamic dependency will need:

1. new dependency metadata field on `MathObject` (or side table), and  
2. a recompute orchestrator invoked after object mutations.

---

## 5. Proposed Minimal Dependency Model

## 5.1 Data model proposal

Add optional dependency metadata on `MathObject`:

```swift
struct GeometryDependency: Codable, Hashable, Sendable {
    var kind: GeometryDependencyKind
}

enum GeometryDependencyKind: Codable, Hashable, Sendable {
    case midpointOfPoints(pointAID: UUID, pointBID: UUID)
    case midpointOfSegment(segmentID: UUID)
    case intersectionOf(objectAID: UUID, objectBID: UUID, index: Int)
    case parallelLine(referenceObjectID: UUID, throughPointID: UUID)
    case perpendicularLine(referenceObjectID: UUID, throughPointID: UUID)
}
```

Design notes:

- Optional field on object; static objects keep `nil`.
- Codable-safe and backward compatible (old docs decode as nil).
- Uses stable source IDs.
- `intersection index` identifies which root among multi-solution results.

## 5.2 Where dependency should live

Recommended: store on `MathObject` itself (`geometryDependency: GeometryDependency?`).

Why:

- persistence is straightforward;
- export/import stays self-contained;
- no parallel side-table consistency problem.

---

## 6. Recompute Trigger Strategy Comparison

## A) Recompute inside `EMathicaDocument.apply(...)` after mutation

Pros:

- strongest consistency guarantee;
- save/load and replay of command logs produce same final geometry;
- module-independent correctness.

Cons:

- `DocumentSystem` would need geometry knowledge unless injected;
- risk of bloating document layer.

## B) Recompute in `WorkspaceState.dispatch(...)` after document commands

Pros:

- easy to integrate with current UI command flow;
- keeps document model simpler.

Cons:

- non-UI mutation paths may skip recompute;
- persistence replay/headless paths may diverge.

## C) Renderer-time virtual recompute only

Pros:

- minimal persistence change.

Cons:

- hit-test, selection, serialization, and object list can desync;
- not suitable for robust editing workflows.

## Recommended

Hybrid: **Document-level deterministic recompute service called by app layer immediately after apply, then persisted back**.

Practical v1 path:

1. keep `EMathicaDocument` pure value mutation (no heavy geometry logic inside),  
2. after `document.apply(commands)` in `WorkspaceState`, call `GeometryDependencyRecomputeService.recompute(document:changedIDs:)`,  
3. service returns object patches for derived objects, then apply patches.

This keeps current architecture stable while preserving deterministic behavior in normal app flow.

---

## 7. First Implementation Phasing

## GeometryDependency-1A (recommended first)

- Add dependency model.
- Add recompute service skeleton.
- Support only `midpointOfPoints` dynamic update.
- Trigger on point move.
- Persist dependency through document save/load.
- Tests:
  - moving source point updates midpoint position,
  - deleting source point degrades safely.

Reason: minimal geometry complexity, high user-visible value, lowest risk.

## GeometryDependency-1B

- Add dynamic `parallelLine` and `perpendicularLine`.
- Trigger on reference line-like endpoint changes and through-point moves.

## GeometryDependency-1C

- Add dynamic `intersectionOf`.
- Recompute with solver + stable index handling.

Out of scope for these phases:

- full constraint solver,
- circular dependency solving,
- generic dependency graph UI,
- dynamic circle-by-three-points, polygon constraints, etc.

---

## 8. Risks and Required Decisions

1. **Cycle prevention**
   - Disallow derived objects as sources in v1 (or detect and reject cycles).

2. **Source deletion behavior**
   - Preferred v1: keep derived object but mark invalid diagnostic + freeze last geometry.

3. **Visibility propagation**
   - v1 option: derived visibility independent from source visibility (simpler).

4. **Editing/dragging derived object**
   - v1 recommended: dragging derived object clears dependency and converts to static.

5. **Intersection multi-root stability**
   - Keep `index` plus deterministic ordering rule in solver output.

6. **No-solution transitions**
   - Keep object with diagnostic and hide render primitive instead of deleting automatically.

7. **Performance**
   - Recompute only impacted derived objects via source-id reverse index.

---

## 9. Tests Required for Implementation Phase

Minimum for 1A:

- dependency codable roundtrip
- old document compatibility (missing dependency decodes nil)
- point move recomputes midpoint
- source deletion marks derived invalid or degrades by policy
- derived style remains unchanged after recompute
- no infinite recompute loop

For later phases:

- parallel/perpendicular direction invariants after source movement
- intersection index stability and no-solution diagnostics
- regression on existing tool creation and hit test

