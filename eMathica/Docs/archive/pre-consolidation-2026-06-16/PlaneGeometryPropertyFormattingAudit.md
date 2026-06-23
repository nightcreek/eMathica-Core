# Plane Geometry Property Formatting Audit

## 1. Scope

This pass is audit/design only.

- No Swift production code changes
- No test changes
- No UI implementation

Goal: audit numeric formatting usage for geometry properties and define a unified formatting strategy for a later implementation pass.

---

## 2. Current Formatting Usage Audit

Based on:

- `eMathica/WorkspaceKit/ObjectPanel/GeometryDependencyPresentation.swift`
- `eMathica/WorkspaceKit/ObjectPanel/WorkspaceObjectRowView.swift`
- `eMathica/WorkspaceKit/Inspector/GeometryInspectorPropertyPresenter.swift`
- `eMathica/WorkspaceKit/Inspector/ObjectInspectorPanel.swift`
- `eMathica/CalculatorModules/Plane/Services/PlaneGeometryResolver.swift`
- `eMathicaTests/PlaneGeometryDependencyTests.swift`

## 2.1 Object row (segment/circle)

Source: `GeometryDependencyPresentation.geometryPropertyText(...)`

- Segment length:
  - text: `长度 ...`
  - formatter: `formatMeasurement(_:)`
  - implementation: `String(format: "%.2f", value)`
- Circle radius:
  - text: `半径 ...`
  - same `formatMeasurement(_:)`
  - implementation: `String(format: "%.2f", value)`

Additionally, dependency source text for `circleByCenterRadius` uses:

- `format(_:)` (custom rounded + integer-shortening path), not `String(format:)`.

So row already has **two** numeric formatting paths (`formatMeasurement`, `format`).

## 2.2 Inspector (point/segment/circle/line/ray/intersection detail)

Source: `GeometryInspectorPropertyPresenter`

- Coordinate:
  - `(x, y)` with `format2`
  - `String(format: "%.2f", value)`
- Segment length:
  - `format2`
- Segment angle:
  - `format1` + `°`
  - `String(format: "%.1f", value)`
- Circle radius/diameter:
  - `format2`
- Line/Ray direction vector:
  - `format2` for `dx`, `dy`
- Slope:
  - `format2` for finite slope
  - special marker: `垂直` when `abs(dx) < 1e-9`
- Angle:
  - `format1` + `°`

## 2.3 Summary of current formatter distribution

Current formatting helpers are scattered:

1. `GeometryDependencyPresentation.formatMeasurement` (`%.2f`)
2. `GeometryDependencyPresentation.format` (rounded-to-2 with integer-shortening)
3. `GeometryInspectorPropertyPresenter.format2` (`%.2f`)
4. `GeometryInspectorPropertyPresenter.format1` (`%.1f`)

So there is clear duplication and slight inconsistency risk.

---

## 3. Audit Answers

1. Row segment length format:
   - `String(format: "%.2f", value)` via `formatMeasurement`.
2. Row circle radius format:
   - same as segment length.
3. Inspector point coordinates:
   - `(x, y)` with 2 decimals (`format2`).
4. Inspector segment length/angle:
   - length: 2 decimals (`format2`)
   - angle: 1 decimal + `°` (`format1`).
5. Inspector circle radius/diameter:
   - 2 decimals (`format2`).
6. Inspector line/ray direction vector:
   - `(dx, dy)` with 2 decimals (`format2`).
7. Inspector slope:
   - finite slope: 2 decimals
   - vertical: `垂直`.
8. Multiple local formatters:
   - yes (`formatMeasurement`, `format`, `format2`, `format1`, direct `String(format:)` patterns).
9. Row vs Inspector inconsistency risk:
   - yes, especially between `format` (integer-shortening) and fixed `%.2f`.
10. NaN/infinite risk:
   - partial guards exist in property calculation paths.
   - unified invalid-handling policy is not centralized yet.

---

## 4. Recommended Unified Formatting Standard

Use one shared geometry-format spec across row + Inspector.

## 4.1 Coordinate

- Shape: `(x, y)`
- Precision: 2 decimals each
- Example: `(1.23, -4.57)`

## 4.2 Length / Radius / Diameter

- Precision: 2 decimals
- Example: `长度 3.14`, `半径 2.00`, `直径 4.00`

## 4.3 Direction angle

- Precision: 1 decimal + `°`
- Example: `45.0°`

## 4.4 Direction vector

- Shape: `(dx, dy)`
- Precision: 2 decimals each
- Example: `(1.00, 0.00)`

## 4.5 Slope

- Finite slope: 2 decimals
- Vertical line: `垂直`
- Invalid numeric result: suppress or show `未定义` (must be consistent)

## 4.6 Status text

Status wording should stay outside numeric formatter and continue to be owned by:

- `GeometryDependencyPresentation.statusText(...)`

---

## 5. Formatter Design Recommendation

Recommend **Option A**: introduce a shared helper, e.g.:

- `GeometryPropertyFormatter`

Suggested API:

1. `formatCoordinate(_ point: WorldPoint) -> String`
2. `formatLength(_ value: Double) -> String?`
3. `formatRadius(_ value: Double) -> String?`
4. `formatDiameter(_ value: Double) -> String?`
5. `formatAngleRadians(_ radians: Double) -> String?`
6. `formatVector(dx: Double, dy: Double) -> String?`
7. `formatSlope(dx: Double, dy: Double) -> String`
8. `isFiniteValid(_ value: Double) -> Bool`

Benefits:

- row + Inspector share one policy
- one-place precision updates
- less drift and fewer edge-case mismatches
- formatter can be unit-tested independently

Option B (keep local helpers) is not recommended due to long-term divergence risk.

---

## 6. Row vs Inspector Policy

Both should use the same numeric formatter backend.

- Row still shows fewer attributes (compact surface).
- Inspector shows richer attributes (detail surface).
- Numeric text style remains consistent across both surfaces.

This preserves readability while avoiding user confusion from mismatched numbers.

---

## 7. Invalid / Non-finite Handling Strategy

Recommended unified rules:

1. If value is NaN/infinite, do not render a normal numeric property.
2. For slope specifically:
   - `dx` near zero -> `垂直`
   - non-finite -> `未定义` or omitted, consistently.
3. Non-defined geometry status remains status-driven; do not treat stale values as active geometry.

---

## 8. Suggested Follow-up Task

`GeometryPropertyFormatting-1` implementation scope:

1. add `GeometryPropertyFormatter`
2. replace local format helpers in row and Inspector
3. keep existing labels and property set unchanged
4. add focused formatter tests:
   - coordinate 2-decimal
   - length/radius/diameter 2-decimal
   - angle 1-decimal degree
   - vector 2-decimal
   - slope finite/vertical/invalid
   - row/Inspector output consistency

No layout or feature expansion needed in that pass.

---

## 9. Conclusion

Current formatting is functional but fragmented.  
A shared `GeometryPropertyFormatter` is the lowest-risk path to keep Plane row and Inspector numerics consistent, predictable, and testable without changing UI structure.

