# Plane Arc Tool Implementation Plan

> **Date:** 2026-06-07
> **Based on:** Docs/PlaneCalculatorGapAudit.md (P0-3: Arc tool)
> **Scope:** Design only — no code modified.

---

## 1. Current Related Implementation Locations

### 1.1 Circle Tool (Reference Implementation)

| Component | File | Key Lines |
|-----------|------|-----------|
| Tool ID | `PlaneToolIDs.swift` | `static let circle = "plane.circle"` |
| Tool registration | `PlaneToolProvider.swift` | `.geometry(.circle)`, title "圆" |
| Construction modes | `PlaneConstructionMode.swift` | `case circleCenter`, `case circleRadius(centerPointID: UUID?)` |
| Command handler | `PlaneCommandHandler.swift` | `handleCreateCircleWithOptionalCenter` (~60 lines) |
| Payload | `PlaneCommandHandler.swift` | `struct CircleCreatePayload: Codable` |
| Dependency kind | `MathObject.swift` | `circleByCenterPoint`, `circleByCenterRadius` |
| Resolver | `PlaneGeometryResolver.swift` | `circleGeometry(for:in:) -> (center, radius)?` |
| Intersection solver | `PlaneIntersectionSolver.swift` | `.circle(center:radius:)` primitive |
| Hit test | `PlaneHitTestService.swift` | `circleHits(screen:center:radius:...)` |
| Renderer | `PlaneObjectRendererView.swift` | `drawGeometryCircle(center:radius:...)` |
| Construction preview | `PlaneConstructionPreview.swift` | `case temporaryCircle(center:currentRadiusPoint:)` |

### 1.2 Interaction States (Circle Flow)

```
1. User taps circle tool → activeToolID = "plane.circle"
2. Canvas tap gesture → PlaneInteractionReducer:
   → first tap: constructionMode = .circleCenter
   → Creates a free point at tap location (or snaps to existing point)
3. Construction preview: temporaryCircle(center, currentRadiusPoint)
4. Second tap: constructionMode = .circleRadius(centerPointID)
   → If tap near existing point: circleByCenterPoint
   → If tap on empty canvas: circleByCenterRadius (computed distance)
5. PlaneCommandHandler.handleCreateCircleWithOptionalCenter
   → Creates MathObject(type: .circle, ...)
   → Emits DocumentCommand.addObject(circle)
```

### 1.3 Circle Data Model

```
MathObject
├── type: .circle
├── points: [centerPoint, throughPoint]        ← 2 WorldPoints
├── geometryDefinition: GeometryDefinition(
│       kind: .circle,
│       anchors: [.object(centerID), .fixedPoint(throughPoint)]
│   )
├── geometryDependency: GeometryDependency(
│       kind: .circleByCenterPoint(centerID, throughID)
│       OR .circleByCenterRadius(centerID, radius)
│   )
└── expression: MathExpression(displayText: "c1: 圆")
```

---

## 2. Arc Data Model Design

### 2.1 Recommendation: Reuse `MathObjectType.circle` with Extended Fields

**Option A (Recommended):** Add `MathObjectType.arc` — a new dedicated type.

**Rationale:**
- Arc has different structural properties (start angle, end angle) from circle
- Different dependency kinds (e.g., `arcByThreePoints`, `arcByCenterAndPoints`)
- Different rendering (partial circumference, not full)
- Different hit test (arc segment, not full circle)
- Different construction tools in the toolbar

### 2.2 MathObject Extensions

```
MathObject {
    type: .arc                               // NEW enum case
    
    // Existing fields (reused):
    points: [WorldPoint]                     // Flexible storage:
    //   Mode A (3-point): [pointA, pointB, pointC]
    //   Mode B (center+2): [center, startPoint, endPoint]
    
    geometryDefinition: GeometryDefinition(
        kind: .arc,                          // NEW GeometryKind case
        anchors: [...]                       // Dependent on construction mode
    )
    
    geometryDependency: GeometryDependency(
        kind: .arcByThreePoints(...)         // NEW case
        OR .arcByCenterRadiusAngle(...)      // NEW case
    )
    
    expression: MathExpression(displayText: "a1: 圆弧")
}
```

### 2.3 New Enum Values Required

| Enum | New Case | Purpose |
|------|----------|---------|
| `MathObjectType` | `case arc` | Object identity |
| `GeometryKind` | `case arc` | Geometry classification |
| `GeometryDependencyKind` | `arcByThreePoints(pointA:pointB:pointC:)` | 3-point construction |
| `GeometryDependencyKind` | `arcByCenterRadiusAngle(center:start:angle:)` | Center + start + angle |
| `WorkspaceToolIcon.GeometryToolGlyph` | `case arc` | Toolbar icon |

### 2.4 Payload Struct

```swift
struct ArcCreatePayload: Codable {
    // Mode A: 3-point arc
    let pointAID: UUID?
    let pointAWorldPoint: WorldPoint
    let pointBID: UUID?
    let pointBWorldPoint: WorldPoint
    let pointCID: UUID?
    let pointCWorldPoint: WorldPoint

    // Mode B: center + start + angle (future)
    let centerPointID: UUID?
    let startPointID: UUID?
    let angleDegrees: Double?
}
```

---

## 3. Interaction Design

### 3.1 Three-Point Arc (Recommended First Implementation)

This is the most intuitive arc construction, matching GeoGebra's "Arc through 3 Points."

```
Construction Mode: .arcFirstPoint → .arcSecondPoint → .arcThirdPoint

Step 1: User taps first point
  → Snap to existing point OR create free point at tap location
  → state: .arcSecondPoint(pointAWorldPoint, pointAID)

Step 2: User taps second point
  → Snap to existing point OR create free point at tap location
  → state: .arcThirdPoint(pointAWorldPoint, pointAID, pointBWorldPoint, pointBID)

Step 3: User taps third point
  → Snap to existing point OR create free point at tap location
  → Compute arc passing through A, B, C
  → Create MathObject(type: .arc, points: [A, B, C])
  → Compute center + radius from three points
  → Store geometryDefinition
```

### 3.2 Construction Preview

```swift
case temporaryArc(pointA: WorldPoint, pointB: WorldPoint, current: WorldPoint)
```

Renders a live-updating arc during the third tap drag. Shows the arc passing through A, B, and the current finger position.

### 3.3 Arc by Center + Points (Future P1)

```
Step 1: Tap center point
Step 2: Tap start point (determines radius)
Step 3: Tap end point (determines sweep angle)
```

This is less intuitive than 3-point. Implement 3-point first.

### 3.4 New Construction Modes

```swift
enum PlaneConstructionMode {
    // ... existing ...
    case arcFirstPoint
    case arcSecondPoint(pointAWorldPoint: WorldPoint, pointAID: UUID?)
    case arcThirdPoint(
        pointAWorldPoint: WorldPoint, pointAID: UUID?,
        pointBWorldPoint: WorldPoint, pointBID: UUID?
    )
}
```

---

## 4. Rendering Plan

### 4.1 Render Function

```swift
private func drawGeometryArc(
    center: WorldPoint,
    radius: Double,
    startAngle: Double,   // radians
    endAngle: Double,      // radians
    context: inout GraphicsContext,
    toScreen: (Double, Double) -> CGPoint,
    color: Color,
    style: MathStyle,
    opacity: Double,
    selected: Bool
)
```

Similar to `drawGeometryCircle` (160-segment polygon), but:
- Only draw from `startAngle` to `endAngle`
- Adaptive segment count based on angular span
- ~80 segments for a full semicircle, fewer for smaller arcs

### 4.2 Arc Computation from Three Points

```swift
static func arcFromThreePoints(
    _ a: WorldPoint, _ b: WorldPoint, _ c: WorldPoint
) -> (center: WorldPoint, radius: Double,
      startAngle: Double, endAngle: Double)?
```

Algorithm:
1. Compute perpendicular bisector of AB → line1
2. Compute perpendicular bisector of BC → line2
3. Intersection of line1 and line2 → center O
4. radius = distance(O, A)
5. startAngle = atan2(A.y - O.y, A.x - O.x)
6. endAngle = atan2(C.y - O.y, C.x - O.x)
7. Verify B lies on the arc (distance ≈ radius) — discard if collinear points

---

## 5. Hit Test Plan

### 5.1 Arc Hit Test

```swift
private static func arcHits(
    screen: CGPoint,
    center: WorldPoint,
    radius: Double,
    startAngle: Double,
    endAngle: Double,
    canvasState: CanvasState,
    canvasSize: CGSize,
    threshold: CGFloat
) -> Bool
```

Algorithm:
1. Convert screen point to world coordinates
2. Check if distance to center is within `radius ± threshold`
3. Compute angle of the hit point relative to center
4. Check if angle is within `[startAngle, endAngle]` (handling wrap-around)
5. Also check proximity to start/end point for selection

### 5.2 Hit Test Registration in PlaneHitTestService

Add a case for `.arc` that calls `arcHits(...)` alongside the existing `circleHits(...)`.

---

## 6. Dependency Update Plan

### 6.1 New Dependency Kind: `arcByThreePoints`

```swift
case arcByThreePoints(pointAID: UUID, pointBID: UUID, pointCID: UUID)
```

### 6.2 Recompute Logic

When any of the three source points moves:
1. Look up current positions of A, B, C
2. Recompute `arcFromThreePoints(A, B, C)`
3. Update the arc's `points`, `geometryDefinition`, `geometryDefinitionStatus`

### 6.3 Cleanup on Delete

When any source point is deleted:
- The arc's `geometryDefinitionStatus` becomes `.missingSource`
- The arc remains visible at its last computed position (greyed out)

---

## 7. Inspector Display Fields

For an arc object, the inspector should show:

| Field | Value | Source |
|-------|-------|--------|
| **Name** | `a1` | `object.name` |
| **Type** | "圆弧" | `object.type == .arc` |
| **Center** | `(1.23, 4.56)` | Computed from three points |
| **Radius** | `3.21` | `sqrt(...)` |
| **Start Angle** | `45°` | `startAngle * 180/π` |
| **End Angle** | `135°` | `endAngle * 180/π` |
| **Arc Length** | `5.03` | `radius * abs(endAngle - startAngle)` |
| **Points** | `A(0,0) B(2,3) C(5,1)` | Source points |

All values are read-only for a dependent arc (derived from points). If the arc has no dependency (free arc), center and radius could be editable.

---

## 8. DocumentCommand Changes

### 8.1 No New Commands Needed

Arc creation uses the existing `DocumentCommand.addObject(MathObject)` pattern. The `MathObject` carries all arc data via:
- `type: .arc`
- `points: [A, B, C]`
- `geometryDefinition: GeometryDefinition(kind: .arc, anchors: [...])`
- `geometryDependency: GeometryDependency(kind: .arcByThreePoints(...))`

Arc deletion uses `DocumentCommand.deleteObject(id:)`.

### 8.2 No New WorkspaceCommand Needed

The existing `WorkspaceCommand.createPoint(at:)` + `setActiveTool(...)` + generic tool flow handles arc creation. Or add a convenience command:

```swift
// Optional convenience:
case createArc(pointA: WorldPoint, pointB: WorldPoint, pointC: WorldPoint)
```

But this is not required — the PlaneCommandHandler can intercept the tool flow directly.

---

## 9. Test Checklist

### 9.1 Unit Tests (MathCore)

- [ ] `arcFromThreePoints` returns correct center for (0,0), (1,1), (2,0) — expect center (1,0)
- [ ] `arcFromThreePoints` returns nil for collinear points (0,0), (1,1), (2,2)
- [ ] `arcFromThreePoints` returns nil for duplicate points
- [ ] Arc midpoint (point B) lies on computed arc within tolerance
- [ ] Angular span is correct for clockwise vs counter-clockwise points

### 9.2 Integration Tests (Plane Module)

- [ ] Create arc via 3 free points → arc appears on canvas
- [ ] Create arc via 3 existing points → arc links to dependencies
- [ ] Drag middle point B → arc recomputes
- [ ] Delete point A → arc shows `.missingSource` status
- [ ] Hit test: tap on arc → selects it
- [ ] Hit test: tap near arc (within threshold) → selects it
- [ ] Hit test: tap far from arc → does not select
- [ ] Undo arc creation → arc disappears
- [ ] Redo → arc reappears
- [ ] Construction preview renders during third-point drag

### 9.3 Rendering Tests

- [ ] Arc renders as smooth curve (not full circle)
- [ ] Arc line width respects MathStyle
- [ ] Arc line style (.solid, .dashed) renders correctly
- [ ] Selected arc shows selection highlight
- [ ] Arc with `.missingSource` renders greyed out

---

## 10. Minimum Implementation Steps

### Step 1: Data Model (15 min, 3 files)

1. Add `case arc` to `MathObjectType` (MathCore)
2. Add `case arc` to `GeometryKind` (MathCore)
3. Add `arcByThreePoints(pointAID:pointBID:pointCID:)` to `GeometryDependencyKind` (MathCore)
4. Add `case arc` to `WorkspaceToolIcon.GeometryToolGlyph`
5. `swift build` MathCore + WorkspaceKit

### Step 2: Math Utility (30 min, 1 file)

1. Implement `arcFromThreePoints(_:_:_:)` → `(center, radius, startAngle, endAngle)?` in `PlaneGeometryResolver`
2. Unit tests for the math function

### Step 3: Construction Flow (1 hour, 3 files)

1. Add `case arc` to `PlaneToolIDs`
2. Register arc tool in `PlaneToolProvider`
3. Add `case arcFirstPoint`, `arcSecondPoint`, `arcThirdPoint` to `PlaneConstructionMode`
4. Implement interaction flow in `PlaneInteractionReducer`
5. Add `case temporaryArc(...)` to `PlaneConstructionPreview`
6. Implement `handleCreateArc` in `PlaneCommandHandler`

### Step 4: Rendering (30 min, 1 file)

1. Implement `drawGeometryArc(...)` in `PlaneObjectRendererView`
2. Call from `case .arc` in the render loop
3. Compute center/radius/angles from `PlaneGeometryResolver`

### Step 5: Hit Test (15 min, 1 file)

1. Implement `arcHits(...)` in `PlaneHitTestService`
2. Add `case .arc` to objectHitTest switch

### Step 6: Dependency Recompute (30 min, 1 file)

1. Add `arcByThreePoints` handling to `PlaneGeometryDependencyRecomputeService`
2. Add cleanup handling for arc source deletion

### Step 7: Inspector (15 min, 1 file)

1. Add `case .arc` to `GeometryInspectorPropertyPresenter`
2. Show center, radius, start/end angle, arc length

### Step 8: Integration Test & Polish (30 min)

1. Manual test: create arc with 3 taps
2. Manual test: drag source points
3. Manual test: undo/redo
4. Manual test: hit test selection

### Total: ~4 hours

---

## 11. Risk Assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| Collinear points produce degenerate arc | 🟡 Medium | `arcFromThreePoints` returns nil → show error toast "三点共线，无法创建圆弧" |
| Angular wrap-around for arcs crossing 0° | 🟡 Medium | Handle `endAngle < startAngle` with `+ 2π` normalization |
| 3-point dependency creates complex recompute chain | 🟢 Low | Follows existing circle/intersection pattern |
| Hit test threshold differs for small vs large arcs | 🟢 Low | Use angular threshold proportional to 1/radius |
| Arc rendering performance for large arcs | 🟢 Low | 80-160 segments, same as circle |
| Undo/redo with 3 dependent points | 🟢 Low | Existing WorkspaceSessionHistory handles this |
