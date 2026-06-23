# Plane Tooling History

> **Date:** 2026-06-16
> **Type:** Merged tool implementation history (consolidates 2 source documents)
> **Source Documents:**
> - [PlaneArcToolImplementationPlan.md](../../archive/consolidated-2026-06-16/PlaneArcToolImplementationPlan.md)
> - [PlaneArcToolQAAudit.md](../../archive/consolidated-2026-06-16/PlaneArcToolQAAudit.md)

---

## Current Tool Inventory

### Implemented Tools

| Tool | ToolID | MathObjectType | Construction Mode |
|------|--------|---------------|-------------------|
| Point | `plane.point` | `.point` | Free + dependent (intersection, midpoint) |
| Segment | `plane.segment` | `.segment` | Two-point |
| Line | `plane.line` | `.line` | Two-point |
| Ray | `plane.ray` | `.ray` | Start + through point |
| Circle | `plane.circle` | `.circle` | Center + point, or center + radius |
| Arc | `plane.arc` | `.arc` | Three-point (A=start, B=through, C=end) |
| Function | `plane.function` | `.function` | Expression input |

### Construction Tools

| Tool | GeometryDependencyKind |
|------|----------------------|
| Intersection | `intersectionOfTwo` |
| Midpoint | `midpointOfTwo` |
| Parallel Line | `parallelThroughPoint` |
| Perpendicular Line | `perpendicularThroughPoint` |
| Delete | — (removes object + dependents) |

---

## Arc Tool Implementation History

### Design (2026-06-07)

Arc tool modeled after the existing Circle tool implementation pattern:
- **Tool ID:** `plane.arc`
- **Construction:** Three-point flow (start → through → end)
- **Math:** Perpendicular bisector intersection for center, angle sweep direction detection
- **Rendering:** CGPath-based arc drawing with `startAngle`/`endAngle`
- **Hit test:** Angle-based hit detection with normalized angle handling
- **Data model:** `MathObject(type: .arc)` with `geometryDefinition.kind = .arc`, anchors for center + start + end

### QA Results (2026-06-07)

| Area | Result |
|------|--------|
| Three-point → center algorithm | ✅ Correct (perpendicular bisector intersection) |
| Collinear detection | ✅ Correct (det > 1e-12 guard) |
| Cross-0° angle handling | ✅ Correct (2π normalization) |
| Angle direction (CCW vs CW) | ⚠️ Edge case risk for near-collinear points |
| Build | ✅ BUILD SUCCEEDED |
| Tests | ✅ All pass |

### Known Arc Tool Issues

| Issue | Detail |
|-------|--------|
| Near-collinear angle direction | For det just above 1e-12, circle center is far, angles very close — `isCounterClockwise` may select wrong sweep (major arc ~359° instead of minor ~1°) |
| Arc through-point validation | Currently accepts any second point. Could validate it lies between start and end angles |

---

## Missing Tools

| Tool | Priority | Note |
|------|----------|------|
| Ellipse | P1 | Recognized by GraphClassifier but no construction tool |
| Parabola | P1 | Recognized by GraphClassifier but no construction tool |
| Hyperbola | P2 | Recognized by GraphClassifier but no construction tool |
| Vector | P1 | Direction + magnitude from two points |
| Polygon | P1 | Closed chain of segments |
| Regular Polygon | P2 | N-sided regular polygon |
| Locus | P2 | Trace of point as parameter varies |
| Text / Label | P2 | Free-form text annotation |
| Image | P2 | Embedded image with anchoring |

---

## Deferred Cleanup

| Item | Target |
|------|--------|
| Implement ellipse construction tool | Plane v1.0+ |
| Implement parabola construction tool | Plane v1.0+ |
| Implement vector construction tool | Plane v1.0+ |
| Implement polygon construction tool | Plane v1.0+ |
| Fix arc near-collinear angle edge case | Plane v1.0 |

---

## Next Actions

1. Implement P1 missing geometry tools (ellipse, parabola, vector, polygon)
2. Investigate arc near-collinear edge case for angle direction
3. Design unified tool implementation pattern for future tools
