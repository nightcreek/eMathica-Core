# Plane Dynamic Geometry v1 Status

## 1) Scope

This document defines the stabilized baseline for dynamic geometry in Plane.
It reflects v1 behavior after `GeometryDependency-1A/1B/1C` and status stabilization.

## 2) Supported dependency kinds

- `midpointOfPoints(pointAID, pointBID)` -> derived `point`
- `parallelLine(referenceObjectID, throughPointID)` -> derived `line`
- `perpendicularLine(referenceObjectID, throughPointID)` -> derived `line`
- `intersectionOf(objectAID, objectBID, index)` -> derived `point`
  - line-like × line-like
  - line-like × circle
  - circle × circle
- `circleByCenterPoint(centerPointID, throughPointID)` -> derived `circle`

## 3) Source/derived relation

- Relation is encoded on child side: `MathObject.geometryDependency`.
- No parent-side child list is persisted.
- Runtime recompute and cleanup derive parent/child from child dependency.

## 4) Definition status model

`MathObject.geometryDefinitionStatus` (optional):

- `defined`
- `noSolution`
- `missingSource`
- `unsupported`
- `invalid`

Static objects typically keep status as `nil`.

## 5) noSolution strategy

When dependency remains valid but current geometry has no solution:

- Keep dependency (do not auto-clear).
- Keep last valid geometry/position in object fields.
- Set status to `noSolution`.
- Object row must show status text.

When solution becomes available again:

- Recompute position/geometry.
- Restore status to `defined`.

## 6) Source-removal strategy

If any dependency source object is removed:

- Derived object is converted to static by cleanup:
  - clear `geometryDependency`
  - clear `geometryDefinitionStatus`
- Keep last valid geometry/position/style/name/visibility/id.
- Do not delete derived object.

## 7) Convert-to-static strategy

Explicit user action `"转为静态对象"`:

- clear `geometryDependency`
- clear `geometryDefinitionStatus`
- preserve geometry/position/style/name/visibility/id

## 8) Object row presentation strategy

Row secondary text includes dependency source description:

- midpoint: `中点：A，B`
- parallel: `平行：过 P，参考 l`
- perpendicular: `垂线：过 P，参考 l`
- circle: `圆：圆心 A，过 B`
- intersection: `交点：A × B`

When status is not defined:

- `noSolution` -> `状态：当前无交点`
- `missingSource` -> `状态：源对象缺失`
- `unsupported` -> `状态：当前关系暂不支持`
- `invalid` -> `状态：未定义`

## 9) Renderer / hit test policy

For derived objects (`geometryDependency != nil`):

- `defined` -> normal render + normal hit test
- non-defined (`noSolution/missingSource/unsupported/invalid`) ->
  - skip normal render
  - skip normal hit test

Project preview follows the same rule: non-defined derived objects are skipped.

## 10) Hidden behavior

- Source hidden does **not** auto-clear dependency.
- Source hidden does **not** force derived visibility.
- Derived visibility remains independent.

## 11) Known follow-up items (out of v1 scope)

- Row/preview status icon polish
- Inspector dependency detail panel
- Dynamic three-point circle
- Tangent tools
- Arc tools
- Polygon tools
- Better multi-root identity tracking for intersections
