# Plane Current Status

> **Date:** 2026-06-16
> **Type:** Merged status report (consolidates 7 source documents)
> **Source Documents:**
> - [PlaneMVPRegressionReport.md](../../archive/consolidated-2026-06-16/PlaneMVPRegressionReport.md)
> - [PlaneUIPolishAudit.md](../../archive/consolidated-2026-06-16/PlaneUIPolishAudit.md)
> - [PlaneUIPolishRegressionReport.md](../../archive/consolidated-2026-06-16/PlaneUIPolishRegressionReport.md)
> - [PlaneCompactLayoutAudit.md](../../archive/consolidated-2026-06-16/PlaneCompactLayoutAudit.md)
> - [PlaneCalculatorGapAudit.md](../../archive/consolidated-2026-06-16/PlaneCalculatorGapAudit.md)
> - [FunctionNamingIsolatedAudit.md](../../archive/consolidated-2026-06-16/FunctionNamingIsolatedAudit.md)
> - [DeleteSourceObjectDependencyPolicy.md](../../archive/consolidated-2026-06-16/DeleteSourceObjectDependencyPolicy.md)

---

## Current Status

### MVP 主闭环 — ✅ Pass

Plane has a functional end-to-end loop:

1. New Plane project → workspace opens
2. Input expression → draft preview renders
3. Commit function → object created with name
4. Create geometry objects: point, segment, line, ray, circle, arc
5. Intersection / midpoint / parallel / perpendicular constructions
6. Select objects → drag edit → delete
7. Save project → `preview.png` generated
8. Home screen shows thumbnail
9. Reopen project → all objects restored

All automated tests pass: `PlaneFunctionPreviewConsistencyTests`, `PlaneObjectNamingServiceTests`, `ProjectPreviewRendererTests`, `PlaneToolingTests`, `eMathicaUITestsLaunchTests`.

### Feature Completion vs GeoGebra — ~50%

| Dimension | Completion |
|-----------|-----------|
| Geometry Objects | ~55% |
| Geometry Constructions | ~45% |
| Dynamic Geometry | ~60% |
| Function Graphing | ~70% |
| CAS / Algebra | ~30% |
| Input System | ~65% |
| Object Panel | ~35% |
| Export | ~25% |

---

## Key Findings

### UI / Interaction

- **Input bar** create/edit modes lack explicit UI distinction
- **Commit error feedback** weak — `lastErrorMessage` stays in state, no visible banner
- **Compact keyboard** default collapse implemented for short-height windows
- **Glass visual system** unified across workspace/keyboard/object panel, but keyboard has redundant glass layers
- **Multi-step construction** hints and cancel work correctly
- **Object panel expression display** uses `displayText → originalLatex → rawInput → name` fallback chain
- **macOS keyboard capture** missing — `HardwareKeyboardCaptureView` is `#if canImport(UIKit)` only

### Layout

- Workspace uses overlay-based layout (canvas fills screen, UI floats on top)
- Keyboard minimum height 216pt — dominant height consumer in compact windows
- Short-height windows risk: keyboard + input dock + error banner stack up fast
- Safe area handling correct for toolbar/input bar/object panel positioning

### Function Naming

- **Two naming paths exist:** Path 1 (WorkspaceState, 95% usage) uses `count + 1`, Path 2 (PlaneCommandHandler) uses `nextFunctionName`
- Path 1 counts ALL `.function` objects including derivatives → causes `f1, f_1'(x), f_1''(x), f4` skip
- Derivative naming partially fixed — depends on Path 1 being fixed first
- Naming cleanup applied to Path 2 but Path 1 drives most naming

### Delete Source Object Policy

Two strategies exist in code:
1. **unlink** — retain derived object, clear dependency, keep last valid geometry as static
2. **deleteAffected** — recursively delete downstream dependents

Three delete entry points exist (ObjectPanel, Batch, Tool), with slightly different behavior. Policy needs to be formally frozen before Plane v1.0.

---

## Known Issues

| Issue | Priority | Source |
|-------|----------|--------|
| Function naming Path 1 uses count-based logic, not sequential | P1 | FunctionNamingIsolatedAudit |
| Delete source object policy not formally frozen | P1 | DeleteSourceObjectDependencyPolicy |
| Input bar lacks create/edit mode distinction | P1 | PlaneUIPolishAudit |
| Commit failure feedback invisible to user | P1 | PlaneUIPolishAudit |
| Compact keyboard may still overwhelm short windows | P2 | PlaneCompactLayoutAudit |
| Redundant glass layers in keyboard area | P2 | PlaneUIPolishAudit |
| macOS hardware keyboard capture missing | P1 | PlaneUIPolishAudit |
| Geometry objects missing: ellipse, parabola, hyperbola, vector, polygon | P1 | PlaneCalculatorGapAudit |
| Export functionality missing | P2 | PlaneCalculatorGapAudit |

---

## Deferred Cleanup

| Item | Target |
|------|--------|
| Fix function naming Path 1 to use shared sequential logic | Plane v1.0 |
| Formalize delete source object dependency policy | Plane v1.0 |
| Add input bar mode indicator (create/edit chip) | Plane v1.0 |
| Add commit error visibility (banner/toast) | Plane v1.0 |
| Ellipse/parabola/hyperbola/vector/polygon tools | Plane v1.0+ |
| Full compact-height keyboard strategy | Plane v1.0+ |
| macOS keyboard capture layer | Post-v1.0 (macOS target) |

---

## Next Actions

1. Fix Path 1 function naming to be sequential
2. Freeze delete source object dependency policy (unlink vs deleteAffected)
3. Add UI polish: input bar mode chip, commit error visibility
4. Add missing geometry tools (ellipse, parabola, vector, polygon)
