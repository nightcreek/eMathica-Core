# Plane Calculator Stabilization Status (PlaneStabilization-1B)

## 1) Scope

This document summarizes the current stabilization status of the Plane calculator after:

- StructuredEditor-1 series
- PlaneVisualPolish / Glass ownership passes
- PlaneSampling-1 / 1B fallback sampling
- SliderSystem-2 / 2B / 2C
- PlaneTools-3A / 3B / 3C
- PlaneStyle-1 / 1B / 1C
- PlaneStabilization-1 / 1A audits and regression tests

This pass is status-only: no production behavior changes.

---

## 2) Module Status Table

| Module | Status | Evidence | Freeze? | Watch items | Next possible work |
|---|---|---|---|---|---|
| StructuredEditor-1 (1C/1D/1E/1G/1H/1I) | Mostly stable | Extensive `eMathicaTests.swift` coverage for AST sync, cursor navigation, hit-region fallback, keyboard mapping, existing-object edit session | Partial freeze (bugfix-only) | Complex selection, long-expression cursor ergonomics, matrix-like templates, drag-select | StructuredEditor-2 |
| Keyboard visual/glass ownership | Frozen | `PlaneVisualPolishTests.swift` token-level checks + ownership simplification already landed | Yes | Only visual regressions / clipping regressions | None in v1 |
| PlaneSampling-1 / 1B fallback | Mostly stable | `PlaneFallbackSamplingServiceTests.swift` + `SamplingCoreTests.swift` + GraphCore tests; fallback explicit/implicit + parameter env validated | Yes (policy freeze) | Performance under high-frequency implicit redraw and slider playback | PlaneSampling-2 |
| SliderSystem-2 / 2B / 2C | Mostly stable | `eMathicaTests.swift` slider settings defaults/sanitize/validator/preset matcher/playback/draft resample tests | Yes (feature freeze) | UI interaction combinations (menu/play/style/sheet) in real app flows | Minor UX follow-up only |
| PlaneTools-3A/3B/3C (line/ray/intersection) | Mostly stable | `PlaneToolingTests.swift`, `PlaneIntersectionSolverTests.swift`, `PlaneIntersectionPreviewResolverTests.swift`, `PlaneHitTestServiceTests.swift` | Yes (v1 freeze) | Edge geometry combinations and heavy overlap hit behavior | PlaneTools-4A midpoint |
| PlaneStyle-1 / 1B / 1C | Mostly stable | `eMathicaTests.swift` style defaults/sanitize/patch-preserve + matcher/provider tests | Yes (v1 freeze) | Richer style UI and inspector layering | PlaneStyle-2 |
| ObjectPanel layout/metrics | Mostly stable | `AlgebraObjectPanelLayoutMetricsTests.swift`, `WorkspaceObjectRowLayoutMetricsTests.swift` | Partial freeze | Large object counts + real scroll ergonomics + menu interaction density | PlaneSaveLoad-1 UX pass |
| Save/load end-to-end | Watch | Roundtrip tests added in PlaneStabilization-1A, but full app-level open/save flow still needs simulator build-for-testing + manual run | No | Runtime-ready full app validation pending | PlaneSaveLoad-1 |
| App build verification chain | Needs follow-up (environment) | `sync` + package tests pass; app build-for-testing blocked by simulator runtime availability | N/A | Xcode runtime/tooling environment | Re-run verify after runtime install |

Status legend:

- Frozen
- Mostly stable
- Watch
- Needs follow-up
- Future enhancement

---

## 3) Completed Modules (Summary)

1. Structured editor core interaction chain (AST-first).
2. Keyboard glass ownership simplification and backplate stabilization.
3. Fallback sampling for unknown/missing semantic classification.
4. Slider settings + playback + persistence + preview/commit resampling.
5. Geometry tools v1: point/segment/line/ray/circle/intersection + hover preview.
6. Object style v1 model + persistence + menu presets + renderer usage.
7. Stabilization audit plus regression test additions.

---

## 4) Frozen Modules (v1 policy)

### Frozen now (bugfix-only)

1. Keyboard visual/glass layer ownership.
2. SliderSystem-2 feature surface (settings model and playback behavior).
3. PlaneStyle-1 preset/menu behavior and style data model.
4. PlaneSampling-1/1B fallback policy and resolver priority.
5. PlaneTools-3A/3B/3C static intersection workflow.

Notes:

- Frozen does not mean no changes; only clear bug fixes with tests.
- No aesthetic-only tuning during stabilization window.

---

## 5) Watch Items

1. StructuredEditor advanced interactions:
   - partial token selection
   - drag selection
   - matrix/multi-column template scaling
2. Save/load app flow:
   - open/save/reopen from actual app UX
   - recent file integration behavior
3. ObjectPanel interaction density:
   - menu/play/style/custom-sheet coexistence in high object count scenarios
4. Sampling/runtime performance:
   - implicit fallback under frequent slider ticks
   - high-frequency or near-singular expressions

---

## 6) Out-of-Scope for Current v1 Stabilization

1. Dynamic geometry dependency graph
   - intersection points auto-updating with source objects
   - constraint system
2. Additional geometry tools
   - midpoint / parallel / perpendicular / polygon / arc
3. PlaneStyle-2
   - ColorPicker
   - full inspector workflow
   - layer ordering / label style
4. PlaneSampling-2
   - advanced discontinuity/singularity handling
   - stronger adaptive/high-frequency controls
5. StructuredEditor-2
   - matrix
   - drag selection
   - richer advanced display/navigation paths

---

## 7) Known Environment Blocker

Current blocker for full app build-for-testing verification:

- iOS Simulator runtime/toolchain environment mismatch (e.g. missing iOS 26.5 runtime in local Xcode environment).

Important:

- This is tracked as environment/tooling, not a confirmed Plane business-logic regression.

---

## 8) Next Recommended Roadmap

1. Wait for iOS runtime installation to complete.
2. Re-run `Scripts/verify_mathcore.sh`.
3. If verify passes, mark **Plane v1 core stabilization pass complete**.
4. Start `PlaneTools-4A` (midpoint tool).
5. Then `PlaneTools-4B` (parallel / perpendicular).
6. Then `PlaneSaveLoad-1` (open/save/recent UX acceptance).

Why midpoint first:

- small, well-bounded scope
- reuses existing point/segment/line primitives
- low integration risk
- meaningful geometric-creation value immediately

---

## 9) Verification Commands

Use the standard chain:

1. `Scripts/check_mathcore_package_sync.sh`
2. `cd Packages/EMathicaMathCore && swift test`
3. `Scripts/verify_mathcore.sh`

If Step 3 fails with simulator runtime/tooling errors, record as environment blocker and retry after runtime/toolchain is ready.

