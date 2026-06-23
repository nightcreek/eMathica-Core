# Plane Circle Creation Policy Audit

## Scope

This audit inspects current circle creation semantics in Plane and proposes a safer v1.1 policy to avoid helper-point leakage, consistent with the recent parallel/perpendicular helper-point fix.

No production code or tests were changed in this audit.

---

## 1. Current chain (code-level)

### Tool + pending flow

- Active tool id: `plane.circle`
  - Defined in `CalculatorModules/Plane/Tools/PlaneToolIDs.swift`
  - Wired in `CalculatorModules/Plane/Tools/PlaneToolProvider.swift`
- Construction state:
  - `circleCenter`
  - `circleRadius(centerPointID: UUID?)`
  - Defined in `CalculatorModules/Plane/Interaction/PlaneConstructionMode.swift`

### Tap handling

`PlaneCanvasView.handleCircleTap(world:pointID:)`:

1. First tap (default path):
   - sets `activeConstruction = .circleRadius(centerPointID: pointID)`
   - stores first tap world point in `pendingWorldPoint`
2. Second tap (`.circleRadius` path):
   - dispatches `plane.createCircleWithOptionalCenter` with payload:
     - `centerPointID` (first tap point id if snapped)
     - `throughPointID` (second tap point id if snapped)
     - `centerWorldPoint` (first tap world)
     - `radiusWorldPoint` (second tap world)

### Command path

`PlaneCommandHandler.handleCreateCircleWithOptionalCenter(...)`:

- Resolves/creates center point:
  - if `centerPointID` exists and resolves to point -> reuse
  - else create a new point object at `centerWorldPoint`
- Resolves through point:
  - if `throughPointID` exists and resolves to point -> reuse
  - else `throughPoint = nil` (no point created)
- Circle object:
  - `type = .circle`
  - `points = [centerWorldPoint, radiusWorldPoint]`
  - `geometryDefinition.kind = .circle`
  - anchors:
    - with through point: `[.object(centerID), .object(throughID)]`
    - without through point: `[.fixedPoint(centerWorldPoint), .fixedPoint(radiusWorldPoint)]`
  - dependency:
    - with through point: `.circleByCenterPoint(centerPointID, throughPointID)`
    - without through point: `nil` (static)

---

## 2. Four scenario matrix (current behavior)

### A) First tap existing point, second tap existing point

- Added objects: circle only
- No helper point created
- Dependency: `circleByCenterPoint(centerPointID, throughPointID)`
- Status: dynamic circle

Result: matches expectation.

### B) First tap existing point, second tap blank

- Added objects: circle only
- No second helper point created
- Dependency: `nil` (static)
- Geometry anchors: currently fixed/fixed world points

Result: no helper-point leakage; but not center-following dynamic behavior.

### C) First tap blank, second tap existing point

- Added objects: one center point + circle
- Through point reused (existing point)
- Dependency: `circleByCenterPoint(newCenterPointID, throughPointID)`
- Status: dynamic circle

Result: aligns with user intent (first blank click explicitly creates center point).

### D) First tap blank, second tap blank

- Added objects: one center point + circle
- No through helper point created
- Dependency: `nil` (static)
- Anchors: fixed/fixed world points

Result: no helper-point leakage; but not dynamic center+fixed-radius behavior.

---

## 3. Risk assessment

### Helper-point leakage risk

- Current circle path **does not** create second-click blank helper through points.
- This is already safer than previous parallel/perpendicular old behavior.

### Semantic gap

- Current second-blank behavior is static circle (`dependency=nil`).
- User-requested behavior for second blank is:
  - center bound to a point (if first click produced/reused center point)
  - fixed radius value
  - moving center moves whole circle, radius unchanged

This is not fully expressible by current dependency kinds.

### Why current anchors are insufficient for fixed-radius dynamic circle

Using circle anchors as:
- `.object(centerID) + .fixedPoint(worldPoint)`

is not equivalent to fixed radius if center moves:
- radius becomes distance(center, fixedWorldPoint), which changes with center movement.

So a real fixed-radius dynamic circle needs explicit radius scalar semantics.

---

## 4. Recommended policy (v1.1)

## 4.1 Keep existing

- `circleByCenterPoint(centerPointID, throughPointID)` for point-point circles.

## 4.2 Add new dependency kind

- `circleByCenterRadius(centerPointID, radius)`

Use when second click is blank and center is point-backed.

Behavior:
- center point moves -> circle center updates
- radius remains fixed
- no through helper point object
- source removal: convert to static (existing policy)
- convert-to-static: clear dependency (existing policy)

## 4.3 Static circle

- Keep static circles for legacy/non-point-backed cases.

---

## 5. Representation recommendation

## Short-term safest

- Add `circleByCenterRadius(centerPointID, radius)` in dependency model.
- Recompute writes resolved circle geometry (center + through world point derived from radius in chosen direction convention).
- Do **not** model fixed-radius dynamic circle as object+fixedPoint anchor pair alone.

## GeometryDefinition options

- Current `GeometryDefinition(kind: .circle, anchors: [GeometryAnchor])` lacks radius scalar.
- Long-term cleaner option: circle-specific payload supporting center anchor + radius value.
- Minimal-change option: keep `GeometryDefinition.circle` as resolved draw anchors while dependency remains source of truth for dynamic fixed-radius semantics.

---

## 6. Intersection impact

With `circleByCenterRadius`:

- `line-circle` dynamic intersections can remain on `intersectionOf(objectAID, objectBID, index)`.
- `circle-circle` dynamic intersections likewise.
- As long as `PlaneGeometryResolver.circleGeometry(...)` can resolve current center/radius for the derived circle object, solver/recompute flow remains compatible.

No fundamental blocker for dynamic intersections with fixed-radius circles.

---

## 7. Object-row presentation recommendation

Current:
- `circleByCenterPoint` shows: `圆：圆心 A，过 B`

Recommended addition:
- `circleByCenterRadius` shows:
  - `圆：圆心 A，半径 r` (preferred), or
  - `圆：圆心 A，固定半径`

---

## 8. Implementation test checklist (for follow-up, not in this audit)

1. Existing point + blank second tap creates no helper point.
2. Blank + blank creates center point only (no through helper).
3. `circleByCenterRadius` creation writes dependency.
4. Center move updates circle center while radius stays constant.
5. Source removal converts to static and preserves last geometry.
6. Convert-to-static clears dependency and stops recompute.
7. line-circle / circle-circle intersections recompute correctly with `circleByCenterRadius`.

