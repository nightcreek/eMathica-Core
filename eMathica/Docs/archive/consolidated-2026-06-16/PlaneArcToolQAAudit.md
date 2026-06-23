# Plane Arc Tool QA Audit

> **Date:** 2026-06-07
> **Scope:** Read-only quality audit of Arc Tool MVP.
> **Build Status:** ✅ BUILD SUCCEEDED, all tests pass.

---

## 1. Arc Math Correctness

### 1.1 Three-Point → Center Algorithm ✅

`arcFromThreePoints(A, B, C)` uses perpendicular bisector intersection. The implementation is mathematically sound:
- Computes perpendicular bisectors of AB and BC
- Solves the 2×2 linear system for the circle center
- Uses `det > 1e-12` guard against collinear points
- Radius computed from center-to-A distance

**Verdict:** ✅ Correct. Handles general case and rejects collinear points.

### 1.2 Angle Direction (CCW vs CW) ⚠️

`isCounterClockwise(start, mid, end)` determines the sweep direction:

```swift
private static func isCounterClockwise(start: Double, mid: Double, end: Double) -> Bool {
    var m = mid; var e = end
    if m < start { m += 2 * .pi }
    if e < start { e += 2 * .pi }
    return m < e
}
```

**Issue:** This uses angle comparison to determine CCW, which is **only valid when three points lie on the same circle**. Since `arcFromThreePoints` computes the circle first and THEN calls `isCounterClockwise` on the computed angles, the points are guaranteed to be on the same circle — so this is mathematically valid.

However, for nearly-collinear points (det just above 1e-12), the circle center is far away and the computed angles are very close together. The angle comparison may become numerically unstable, potentially selecting the wrong sweep direction (the major arc instead of the minor arc, or vice versa).

**Verdict:** ⚠️ Edge case risk. For nearly-collinear points with a very large radius, the angle ordering may be unreliable. The arc will still pass through B, but it may draw the major arc (~359°) instead of the minor arc (~1°), which is visually wrong.

### 1.3 Cross-0° Angle Handling ✅

The angle normalization in both `arcFromThreePoints` and `arcHits` properly handles the 0° boundary:

- `arcFromThreePoints`: Adds/subtracts 2π to ensure `endAngle` is on the correct side of `startAngle`
- `arcHits`: Normalizes both `sweepEnd` and hit `angle` to be ≥ `sweepStart` before comparison

**Verdict:** ✅ Correct.

### 1.4 Collinear Detection ✅

`guard abs(det) > 1e-12 else { return nil }` — returns nil. The user gets a toast "三点共线，无法创建圆弧".

**Verdict:** ✅ Correct.

---

## 2. Rendering Consistency

### 2.1 Normal Arc (45° sweep) ✅

`drawGeometryArc` correctly interpolates from `startAngle` to `endAngle` with linear interpolation `angle = startAngle + t * (endAngle - startAngle)`.

**Verdict:** ✅ Correct.

### 2.2 Cross-0° Arc ✅

When `endAngle < startAngle` (after normalization), `endAngle - startAngle` is negative. The loop `for index in 0...segments` with `t` from 0 to 1 produces `angle` values from `startAngle` going through the negative direction (CW sweep), which correctly draws the shorter arc.

**Verdict:** ✅ Correct.

### 2.3 Large Arc (>180° sweep) ✅

`max(20, Int(sweep / (2 * .pi) * 160))` — for a 270° sweep, this gives ~120 segments. Acceptable quality.

**Verdict:** ✅ Correct, though segment count could be adaptive for even better quality on large arcs.

### 2.4 Selection Highlight ✅

Selected arc uses `+4` line width with 20% opacity overlay, matching circle/segment behavior.

**Verdict:** ✅ Correct.

### 2.5 Line Style ✅

`.dashed` and `.solid` line styles are applied identically to circles.

**Verdict:** ✅ Correct.

---

## 3. Hit Test

### 3.1 Only Hits Arc Segment ⚠️

```swift
private static func arcHits(screen:, center:, radius:, startAngle:, endAngle:, ...)
```

The hit test checks:
1. Distance to circle center ≈ radius (within threshold) ✅
2. Hit angle within arc sweep range ✅

**Issue:** The hit angle is computed in **screen coordinates** (`atan2(screen.y - centerScreen.y, ...)`) while `startAngle`/`endAngle` are computed in **world coordinates** (`atan2(a.y - center.y, ...)`). Since `worldToScreen` inverts Y, the world-space angle θ becomes -θ in screen space. This means the angle comparison may be **inverted** — the hit test might match the wrong side of the circle for some arc configurations.

**Example**: If world-space arc goes from 30° to 90°, the screen-space hit angle at 60° would be -60° in world space, which is outside the [30°, 90°] range. The normalization in `arcHits` adds 2π to make it ≥ sweepStart, so -60°+360°=300°, which is NOT in [30°, 90°].

**Impact**: 🔴 The hit test fails for arcs in certain positions. The arc may be unselectable by tapping on it.

**Verdict:** 🔴 **Must fix.** The hit angle should be computed in the same coordinate space as the arc angles. Either compute hit angle in world coordinates, or negate the world-space arc angles before passing to `arcHits`.

### 3.2 No Full-Circle False Positive ✅

The distance check + angle check prevents false positives on the full circle.

**Verdict:** ✅ Correct.

### 3.3 Endpoint Selection ✅

Since arcs have source points (A, B, C), tapping near those points selects the point, not the arc. This follows the same behavior as circles.

**Verdict:** ✅ Correct.

### 3.4 Very Short Arc Selection ✅

For a sweep of 0.01 radians, the angular tolerance of 0.01 should still catch hits near the arc. The pixel-distance check is independent of sweep length.

**Verdict:** ✅ Correct.

---

## 4. Dependency

### 4.1 Drag Source Point → Recompute ✅

`appendArcByThreePointsPatches` correctly:
1. Checks if any of the 3 source points changed
2. Retrieves current positions of all 3 points
3. Recomputes `arcFromThreePoints`
4. Sets `.missingSource` if any point is missing or recompute fails

**Verdict:** ✅ Correct.

### 4.2 Delete Source Point → missingSource ✅

`dependencyCleanupPatchesForRemovedSources` includes `arcByThreePoints` alongside other dependency kinds.

**Verdict:** ✅ Correct.

### 4.3 Transitive Propagation ✅

`referencesAny` includes all three arc point IDs, ensuring the dependency graph walker correctly traverses through arcs.

**Verdict:** ✅ Correct.

### 4.4 Undo/Redo ✅

Arc creation is wrapped in `DocumentCommand.addObject()` which is captured by `WorkspaceSessionHistory`. Delete and recreate are handled by the standard undo/redo infrastructure.

**Verdict:** ✅ Correct.

---

## 5. Persistence

### 5.1 Codable Compatibility ✅

- `MathObjectType.arc` — raw value `"arc"`. Decoding old documents without arc objects is unaffected. New documents with arc objects will fail on old versions (expected).
- `GeometryDependencyKind.arcByThreePoints` — uses `UUID` associated values (Codable). Adding a new enum case is backward-compatible for decoding.

**Verdict:** ✅ Correct. No migration needed.

### 5.2 Save/Reopen ✅

Arc objects are stored as `MathObject` with `type: .arc`, `points: [A, B, C]`, and `geometryDependency: .arcByThreePoints(...)`. On reopen, the dependency system recomputes the arc geometry from the stored source point IDs.

**Verdict:** ✅ Correct.

---

## 6. Preview / Export

### 6.1 ProjectPreviewRenderer 🟡

Arc objects return `nil` in the preview renderer:

```swift
case .function, .point, .parameter, .parameterGroup, .arc:
    return nil
```

This means arc objects do not appear in project thumbnails.

**Verdict:** 🟡 Acceptable for MVP. Should add arc preview support (P1) by sampling the arc as a series of WorldPoints similar to `sampleCircle`.

### 6.2 Export (PNG/SVG) 🟡

Arc is rendered on-canvas via `drawGeometryArc`, which uses CoreGraphics Path. If PNG export captures the canvas rendering, arcs will appear. SVG export would need explicit arc path support.

**Verdict:** 🟡 Acceptable for MVP. Canvas-based export works; dedicated SVG `<path d="M... A..."/>` would be needed for vector export.

---

## 7. UI / UX

### 7.1 Tool Icon ✅

The arc tool icon uses `Path.addArc` with a curved line from 160° to 20° (clockwise), with endpoint dots. Visually distinct from the circle icon (full circle with center dot).

**Verdict:** ✅ Clear and distinguishable.

### 7.2 Three-Click Flow ✅

The interaction follows the established circle/segment pattern:
- First click: construction mode changes, preview line appears
- Second click: preview updates to show both clicked points
- Third click: arc created

**Verdict:** ✅ Matches existing tool UX.

### 7.3 Error Toast ✅

Collinear points produce a toast: "三点共线，无法创建圆弧".

**Verdict:** ✅ User-visible feedback.

### 7.4 Missing: Intermediate State Feedback 🟡

Unlike the circle tool (which shows a live-updating circle preview during the second tap drag), the arc tool only shows a line preview between the first two points and between the second point and the cursor. The arc itself is not previewed until creation.

**Verdict:** 🟡 Enhancement opportunity. A live arc preview during the third-point drag would improve UX.

---

## 8. Issues Summary

### 🔴 Must Fix (P0)

| # | Issue | Severity | Fix |
|---|-------|----------|-----|
| 1 | **Hit test Y-axis inversion** — `arcHits` uses screen-space `atan2` but starts/end angles are in world space. Arc may be unselectable. | Critical | Pass world-space hit point to `arcHits`, or negate arc angles before passing. |

### 🟡 Should Fix (P1)

| # | Issue | Severity | Fix |
|---|-------|----------|-----|
| 2 | **Nearly-collinear point ordering** — For very large radii, angle comparison may pick wrong sweep direction. | Medium | Use geometric cross product test instead of angle comparison for CCW determination. |
| 3 | **No arc preview during construction** — Only a line preview, not the actual arc shape. | Low | Add `temporaryArc` preview rendering in `PlaneConstructionPreview` and canvas gesture handler. |
| 4 | **No thumbnail preview** — `ProjectPreviewRenderer` returns nil for arc. | Low | Add arc sampling to preview renderer. |

### 🟢 Can Defer (P2)

| # | Issue | Severity | Fix |
|---|-------|----------|-----|
| 5 | **Inspector shows minimal info** — Only "三点圆弧" label in dependency presenter. Should show center, radius, arc length. | Low | Add dedicated arc inspector rows. |
| 6 | **Tool icon endpoints are fixed** — The endpoint dots in the icon are at fixed positions, not reflecting the actual arc endpoints. | Cosmetic | Current icon is clear enough. |
| 7 | **Arc color is always orange** — No color customization option in the initial creation flow. | Low | Arc supports `MathStyle` updates through the object panel (existing feature). |
| 8 | **No arc-specific keyboard shortcut or context menu** | Cosmetic | Standard geometry workflows work via toolbar. |

---

## 9. Verdict

### Can Arc MVP be considered stable?

**🟡 Conditionally.** The core math, rendering, dependency, and persistence are solid. The hit test bug (Issue #1) is a critical user-facing issue — if users can create an arc but can't select it by tapping, the tool is effectively broken. This must be fixed before shipping.

### Recommended Minimum Fix (30 min)

```
Fix Issue #1: Hit test Y-axis inversion
- Pass world-space hit coordinates to arcHits
  OR negate startAngle/endAngle before passing to match screen space
- Verify: tap on arc → selects arc
```

### Recommended Next (1 hour, after hit test fix)

```
Fix Issue #2: Replace isCounterClockwise with cross product test
- More robust for nearly-collinear points
- Fix Issue #3: Add temporaryArc preview during 3rd-point drag
```

---

## 10. Test Recommendations

### Manual QA Script

1. **Creation**: Tap 3 non-collinear points → arc appears ✅
2. **Collinear**: Tap 3 collinear points → "三点共线" toast ✅
3. **Selection**: Tap arc → selects arc (🔴 verify after hit test fix)
4. **Drag A**: Drag point A → arc updates ✅
5. **Delete A**: Delete point A → arc goes missingSource ✅
6. **Undo**: Create arc, undo → arc removed ✅
7. **Save/Reopen**: Save document, reopen → arc intact ✅
8. **Cross-0°**: Create arc spanning the 0° boundary → renders correctly ✅
9. **Large arc**: Create arc >180° → renders correctly ✅
10. **Style**: Change arc color/line width → applies correctly ✅
