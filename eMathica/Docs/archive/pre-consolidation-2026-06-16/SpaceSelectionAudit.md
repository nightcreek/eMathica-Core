# Space Selection Audit (v0.1)

## 1) Current rendering / hit-test readiness

### Current primitives from `SpaceWireframeRenderer`
- `points: [SpaceWireframePoint]`
  - contains projected screen position + style
- `segments: [SpaceWireframeSegment]`
  - contains projected start/end + style
- `polygons: [SpaceWireframePolygon]`
  - currently used by `plane3D` fill
- `labels: [SpaceWireframeLabel]`
  - currently used by axis labels

### Gaps for selection/hit-test
- No primitive carries `sourceObjectID` (or any object identity).
- `ProjectedPoint2D` has `depth`, but segment/polygon primitives do not expose aggregated depth metadata.
- Canvas has tap location (`SpatialTapGesture`), so screen-space hit-test is feasible.
- Current tap pipeline is creation-only via `screenPointToWorkPlaneZ0`; no selection branch.
- There is pending state for creation (`pendingSegmentStart`, `pendingLineStart`), but no pending/hover selection state.
- No selected-object visual highlight inside Space canvas yet.

### Plane primitive suitability
- `plane3D` fill/grid/border are good visual primitives.
- For hit-test, fill should **not** be the default selection area in v0.1 (too easy to false-select).
- Plane wireframe edges are better as first selectable target.

---

## 2) Recommended minimal hit-test strategy (v0.1)

Use screen-space hit-test against projected primitives.

### Point3D
- Project object point to screen.
- Hit if distance to tap <= `pointThreshold` (recommend 12pt on touch).
- If multiple hits, choose smallest depth (nearest visible).

### Segment3D
- Hit against projected line segment.
- Hit if point-to-segment distance <= `segmentThreshold` (recommend 10pt).
- Tie-break by average endpoint depth (nearer first).

### Line3D
- v0.1 keep current finite render proxy.
- Hit same as projected finite segment.
- Documented limitation: this is a picking approximation, not infinite-line exact picking.

### Plane3D
- v0.1: edge-only hit-test (wireframe border / optional grid lines).
- Do not use fill polygon as broad hit area yet.

### Suggested priority
1. point3D
2. segment3D
3. line3D
4. plane3D edge

---

## 3) Selection strategy recommendation

### Tool behavior
- `space.select`: perform hit-test and set selection.
- `space.orbit` / `space.pan`: camera-only, no object selection.
- `space.point3D` / `space.segment3D` / `space.line3D`:
  - keep current create flow in v0.1
  - optional snapping path (see section 4)

### Multi-hit resolution
- Priority-first (point > segment > line > plane edge), then nearest depth.

### UX baseline for v0.1
- Single selection only.
- Tap empty area => clear selection (in select tool).
- No marquee/lasso in this stage.

---

## 4) Snapping strategy recommendation

### Minimal snapping (recommended before plane tool)
- During segment/line creation, first attempt point hit-test.
- If a point3D is within point snap threshold, use that existing point position.
- If no hit, fallback to `z=0` work-plane unprojection result.

### Important boundary
- Snapping in v0.1 is coordinate reuse only.
- No dependency graph is created.
- No parent/child dynamic relation is introduced.

### Why now
- Without snapping, multi-step 3D construction stays fragile and imprecise.
- Snapping is low-risk and immediately improves tool usability before plane creation.

---

## 5) Work-plane strategy recommendation

### Current
- Fixed work plane: `z = 0`.

### v0.1 (keep)
- point/segment/line creation continue on `z=0`.

### v0.1.5 (recommended next)
- Add basic plane switch: `XY / YZ / ZX`.
- Keep UI simple (small segmented control or tool menu option).

### v0.2
- Support arbitrary user work plane:
  - choose existing plane3D as active work plane
  - optional camera-facing temporary plane

---

## 6) Plane3D creation readiness and recommendation

### Candidate options
- A) Three-point plane
- B) Point + normal
- C) Default plane template

### Recommendation
- Do **not** implement plane3D creation immediately.
- First complete:
  1. Space hit-test/select baseline
  2. Point snapping
  3. At least basic work-plane switching (XY/YZ/ZX)

### Reason
- With only fixed `z=0`, three-point creation degenerates into mostly horizontal planes.
- Without snapping, selecting existing spatial anchors is unreliable.

---

## 7) Implementation roadmap

### SpaceHitTest-1A
- Add projected primitive-to-object mapping (`sourceObjectID`).
- Implement point/segment/line edge hit-test.
- Wire `space.select` tap path.
- Add selected highlight rendering (style-only, no model change).

### SpaceSnapping-1A
- Reuse point hit-test for segment/line creation.
- Snap-to-existing-point when within threshold.
- No dependency creation.

### SpaceWorkPlane-1A
- Add XY/YZ/ZX work-plane mode.
- Keep existing `z=0` as default.

### SpaceTools-1C
- Add plane3D creation tool after above foundations.

---

## 8) Scope guard (what this audit explicitly does not propose now)
- No hit-test implementation in this task.
- No snapping implementation in this task.
- No plane3D tool implementation in this task.
- No dependency/CAS pipeline changes.
- No Plane module behavior changes.

