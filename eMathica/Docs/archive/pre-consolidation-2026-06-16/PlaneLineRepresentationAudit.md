# Plane Line Representation Audit

## 1) Current line / ray / segment representation

### line
- `GeometryDefinition.kind == .line`
- Anchors are two `GeometryAnchor.object` point ids.
- `MathObject.points` also stores two world points (snapshot-like cache).

### ray
- `GeometryDefinition.kind == .ray`
- Anchors are two `GeometryAnchor.object` point ids (start + through).
- `MathObject.points` stores two world points.

### segment
- `GeometryDefinition.kind == .segment`
- Anchors are two `GeometryAnchor.object` point ids (or fallback fixed points in legacy/static cases).
- `MathObject.points` stores two world points.

## 2) Current parallel / perpendicular construction representation

## Observed command path
- Tool creates derived line through `plane.createParallelLine` / `plane.createPerpendicularLine`.
- Handler computes `targetPoint = throughPoint + direction`.
- Then calls `createLine(pointA: throughPoint, pointB: targetPoint, pointAID: throughPointID, pointBID: nil, geometryDependency: ...)`.

## Consequence
- `pointAID` resolves to existing through point.
- `pointBID == nil` causes `resolveConstructionPoint(...)` to create a **new point object** in `document.objects`.
- Derived line geometry anchors become:
  - anchor[0] = through point object id
  - anchor[1] = generated direction point object id

## Recompute behavior
- Recompute service updates:
  - derived line `points`
  - generated direction point `position` and display text
- So the generated direction point is an active data node, not just an internal ephemeral cache.

## 3) Whether generated helper points exist

Yes. For dynamic parallel/perpendicular:
- A helper direction point is created and persisted as regular `MathObject(type: .point)`.
- It is not hidden by default.
- It appears in object list flow as a normal point row.

## 4) User interaction risk assessment

Generated helper point currently behaves like normal point:
- Selectable
- Visible
- Deletable
- Listed in object panel
- Potentially draggable if static (and if dependency constraints do not intercept that specific point)

This creates semantic leakage:
- Users can interact with what should be internal construction state.
- Geometry relation can be indirectly disturbed or confusing.
- Object panel noise increases (extra points not authored by user intent).

## 5) Renderer / hit-test dependency on two points

Current renderer + hit-test pipeline resolves line/ray via two points:
- `PlaneGeometryResolver.linePoints` / `rayPoints`
- `PlaneLineClipping` uses two endpoints (for infinite line/ray clipping)

So implementation is currently endpoint-driven, not explicit point+direction form.

## 6) Classification of current implementation shape

Matches **D** from requested taxonomy:
- line geometry anchors through-point + generated target point object.
- Generated target point is software-created object in document graph.

This is more than internal two-point math; it is exposed object graph state.

## 7) Recommended short-term fix (v1.1)

Adopt two-point representation with non-user helper endpoint (**requested Plan A**):

1. For derived parallel/perpendicular creation:
   - Keep anchor[0] as `.object(throughPointID)`.
   - Store anchor[1] as `.fixedPoint(targetPoint)` instead of creating point object.
2. Recompute updates:
   - line `points`
   - line geometryDefinition anchor[1].fixedPoint
   - no separate point object patching.
3. Migration compatibility:
   - If old derived lines still reference object anchor[1], convert to fixedPoint on first recompute pass.

Benefits:
- Minimal renderer/hit-test changes.
- Removes user-operable helper point leakage.
- Preserves existing dependency semantics and v1 policy.

## 8) Recommended long-term representation

Introduce explicit line-by-direction form (**Plan B**):

- New geometry representation for line/ray:
  - through point anchor
  - direction vector (or normalized direction + optional magnitude)

Why:
- Matches analytic geometry semantics directly.
- Removes endpoint ambiguity for infinite objects.
- Cleaner dynamic relation expressions for parallel/perpendicular.

Expected impact:
- Resolver
- Renderer clipping entrypoints
- Hit-test geometric distance routines
- Document codable compatibility strategy

## 9) Why not dependency-only virtual geometry (Plan C)

Not recommended for this codebase baseline:
- Current system persists concrete geometry for rendering/hit-test/preview symmetry.
- Virtual-only dependency geometry risks divergence between runtime render and document state.
- Harder save/load determinism and debugging.

## 10) Tests required before implementation

If short-term fix (Plan A) is implemented:
- parallel/perpendicular creation should not add extra point objects.
- object count delta expectations for derived line creation.
- object panel should not gain helper point rows.
- recompute should update derived line without point-object side effects.
- source removal / convert-to-static should remain unchanged.
- renderer/hit-test for derived lines still pass.

If long-term fix (Plan B) is implemented:
- codable roundtrip for new line/ray representation.
- fallback decode for old two-anchor representation.
- clipping/hit-test regression coverage for line/ray.
- dynamic dependency recompute correctness for all line-like derived relations.
