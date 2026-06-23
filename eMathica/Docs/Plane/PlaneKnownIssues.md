# Plane Known Issues

> **Date:** 2026-06-16
> **Type:** Merged issue tracker (consolidates from Plane audit documents)
> **Source Documents:**
> - [PlaneGeometryDependencyFailureAudit.md](../../archive/consolidated-2026-06-16/PlaneGeometryDependencyFailureAudit.md)
> - [PlaneUIPolishAudit.md](../../archive/consolidated-2026-06-16/PlaneUIPolishAudit.md)
> - [PlaneCompactLayoutAudit.md](../../archive/consolidated-2026-06-16/PlaneCompactLayoutAudit.md)
> - [FunctionNamingIsolatedAudit.md](../../archive/consolidated-2026-06-16/FunctionNamingIsolatedAudit.md)

---

## P0 — Blockers

None currently.

---

## P1 — Must Fix Before v1.0

### Function Naming

| Issue | Detail |
|-------|--------|
| Path 1 naming uses count-based logic | `WorkspaceState.swift:1455` counts ALL `.function` objects → causes `f1, f_1'..., f4` skip instead of `f1, f2` |
| Derivative occupies ordinary number | `document.objects.filter { $0.type == .function }.count + 1` includes derivatives in count |
| Two naming paths diverge | Path 1 (WorkspaceState, 95% usage) vs Path 2 (PlaneCommandHandler.nextFunctionName) |

### Geometry Dependency

| Issue | Detail |
|-------|--------|
| Inspector presenter hits stub resolver | `PlaneGeometryStubs` empty resolver used in WorkspaceKit context → `IMPLEMENTATION_REGRESSION` |
| `staticSegmentSecondaryTextIncludesLengthProperty` fails | Resolver cannot resolve length property |
| `inspectorVerticalLineSlopeDisplaysVerticalMarker` fails | Stub resolver in test context |
| `inspectorSegmentPropertiesIncludeEndpointsLengthAndAngle` fails | Display layer can't get real geometry results |
| `inspectorIntersectionPropertiesIncludeSourceIndexAndCoordinateWhenDefined` fails | Resolver fork, source index/coordinate unstable |
| `movingLineCircleSourcesRecomputesDynamicIntersectionPoints` fails | Dynamic recompute not triggered in test |
| `intersectionNoSolutionTransitionKeepsLastPosition` fails | Edge case handling inconsistent |

11 failing test cases total in `PlaneGeometryDependencyTests` — all `IMPLEMENTATION_REGRESSION` type caused by WorkspaceKit using `PlaneGeometryStubs` empty resolver instead of `PlaneGeometryResolver`.

### UI / Interaction

| Issue | Detail |
|-------|--------|
| Input bar create/edit modes indistinguishable | Same `f(x)` chip, same button layout for both modes |
| Commit error invisible | `lastErrorMessage` stays in state, no banner/toast in workspace root |
| Bottom input dock overlays canvas | Overlay-based layout, no reserved space for content area |
| Compact window: keyboard 216pt dominates | `keyboardPanelMinHeight = 216` in compact-height windows |
| macOS keyboard capture absent | `HardwareKeyboardCaptureView` is UIKit-only (`#if canImport(UIKit)`) |

---

## P2 — Nice to Have

| Issue | Detail |
|-------|--------|
| Redundant glass layers in keyboard | Input dock shell + keyboard container + keyboard backplate all glow |
| Key density uniform across sizes | No explicit size class breakpoints for different window sizes |
| Diagnostic text small and low | Draft diagnostics at bottom in small font |
| Long expressions hard to read | ScrollView for input, but object row scales and truncates |
| `isCounterClockwise` numerical instability | Near-collinear arc points may select wrong sweep direction (major vs minor arc) |

---

## Known Test Failures

| Test | Status | Root Cause |
|------|--------|------------|
| `staticSegmentSecondaryTextIncludesLengthProperty` | FAIL | Stub resolver |
| `inspectorVerticalLineSlopeDisplaysVerticalMarker` | FAIL | Stub resolver |
| `inspectorSegmentPropertiesIncludeEndpointsLengthAndAngle` | FAIL | Stub resolver |
| `inspectorIntersectionPropertiesIncludeSourceIndexAndCoordinateWhenDefined` | FAIL | Resolver fork |
| `movingLineCircleSourcesRecomputesDynamicIntersectionPoints` | FAIL | Stub resolver |
| `intersectionNoSolutionTransitionKeepsLastPosition` | FAIL | Edge case handling |
| `inspectorRayPropertiesIncludeStartDirectionAndAngle` | FAIL | Stub resolver |
| `inspectorLinePropertiesIncludeDirectionVectorSlopeAndAngle` | FAIL | Stub resolver |
| `inspectorCirclePropertiesIncludeCenterRadiusAndDiameter` | FAIL | Stub resolver |
| `staticCircleSecondaryTextIncludesRadiusProperty` | FAIL | Stub resolver |
| `inspectorPointPropertiesIncludeCoordinate` | FAIL | Stub resolver |

All 11 failures share the same root cause: WorkspaceKit uses `PlaneGeometryStubs` empty resolver in test context instead of `PlaneGeometryResolver`.

---

## Deferred Cleanup

| Item | Target |
|------|--------|
| Fix 11 PlaneGeometryDependencyTests failures | Plane v1.0 |
| Unify function naming Path 1 and Path 2 | Plane v1.0 |
| Add input bar create/edit mode indicator | Plane v1.0 |
| Add commit error visibility | Plane v1.0 |
| Compact-height keyboard strategy | Plane v1.0+ |
| macOS keyboard capture | Post-v1.0 |

---

## Next Actions

1. Fix WorkspaceKit test context to use real `PlaneGeometryResolver` instead of stubs
2. Fix function naming Path 1 to use shared `nextFunctionName` logic
3. Add input bar mode chip and commit error banner
4. Consider compact-height keyboard collapse refinements
