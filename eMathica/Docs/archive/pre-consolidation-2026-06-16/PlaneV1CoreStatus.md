# Plane Calculator v1 Core Status

## 1. Scope

This document consolidates current Plane Calculator v1 core status after:

- DynamicGeometry v1
- CircleCreationPolicy-1
- DependencyDeletionPolicy-1A/1B-1
- SessionUndoRedo-1A/1B
- PlaneSaveLoad-1

This is status-only documentation. No production behavior changes are included.

---

## 2. Completed Modules

## A) Input / Expression

### Completed

- Expression submit/commit flow integrated with document update.
- Parametric and piecewise core path stabilized with diagnostics.
- Inequality normalization for `>=`, `<=`, `≥`, `≤`, and LaTeX relation command path (`\geq`, `\leq`) stabilized.
- Implicit multiplication edge fixes for common plane contexts (`xy`, `2x`, `2t`, coefficient-before-trig forms).
- Layered diagnostics model landed:
  - serialization / parse / classification / fallback / sampling / rendering
- Draft diagnostics and committed geometry diagnostic status are exposed to row/presentation layer in v1 style.

### Still under observation

- Complex parametric/piecewise edge expressions under real-device editing cadence.
- Rare tokenization variants from IME / Unicode input paths.

### Known follow-ups

- Broader symbolic/boolean expression coverage is deferred.
- Accuracy-mode parser/sampler enhancements are deferred (outside v1 core freeze).

---

## B) Geometry Tools

| Tool | Shipped | Dynamic output | Writes dependency | Status-aware | Source-removal behavior | Convert-to-static |
|---|---|---|---|---|---|---|
| point | Yes | N/A | No | N/A | N/A | N/A |
| segment | Yes | Static | No | N/A | N/A | N/A |
| line | Yes | Static (tool line) / derived dynamic line | Derived only | Derived only | Derived only | Derived only |
| ray | Yes | Static | No | N/A | N/A | N/A |
| midpoint | Yes | two-point mode dynamic / segment mode static | midpointOfPoints (two-point only) | Yes | Yes | Yes |
| parallel | Yes | Dynamic derived line | parallelLine | Yes | Yes | Yes |
| perpendicular | Yes | Dynamic derived line | perpendicularLine | Yes | Yes | Yes |
| circle | Yes | Dynamic or static by creation path | circleByCenterPoint / circleByCenterRadius | Yes | Yes | Yes |
| intersection | Yes | Dynamic for supported pairs | intersectionOf | Yes | Yes | Yes |

Notes:

- Intersection dynamic support includes line-like × line-like, line-circle, circle-circle.
- Non-supported dynamic cases remain static by policy.

---

## C) Dynamic Geometry Matrix

| Dependency kind | Source objects | Derived type | Recompute | noSolution/status | Source removal | Convert-to-static | Save/load | Preview |
|---|---|---|---|---|---|---|---|---|
| midpointOfPoints | point A, point B | point | Yes | defined/invalid/missingSource as applicable | clear dependency, keep last geometry | Yes | Yes | non-defined skipped |
| parallelLine | reference line-like + through point | line | Yes | defined/noSolution/invalid/missingSource | clear dependency, keep line geometry | Yes | Yes | non-defined skipped |
| perpendicularLine | reference line-like + through point | line | Yes | defined/noSolution/invalid/missingSource | clear dependency, keep line geometry | Yes | Yes | non-defined skipped |
| intersectionOf | object A + object B (+ index) | point | Yes | defined/noSolution/missingSource/unsupported/invalid | clear dependency, keep last point | Yes | Yes | non-defined skipped |
| circleByCenterPoint | center point + through point | circle | Yes | defined/missingSource/invalid | clear dependency, keep circle | Yes | Yes | non-defined skipped |
| circleByCenterRadius | center point + radius scalar | circle | Yes | defined/missingSource/invalid | clear dependency, keep circle | Yes | Yes | non-defined skipped |

---

## D) Style / Object Panel

### Completed

- Style persistence and rendering chain for:
  - color
  - lineWidth
  - pointSize
  - opacity
  - lineStyle
- Style matcher/provider baseline stable.
- Object row source/status presentation landed for derived geometry.
- Object row height and object panel height mismatch issue fixed in prior passes.

### Still under observation

- Dense row content readability with long expressions + source/status line in smaller device contexts.

---

## E) Deletion Policy

### Completed

- Single delete confirmation for direct affected derived objects.
- Batch delete (`deleteSelectedObjects`) aligned to same policy.
- Two strategies:
  - unlink: delete selected sources, affected derived convert to independent/static
  - delete affected: delete selected + direct affected derived
- Scope is direct-only (no recursive downstream delete).
- Integrated with session Undo/Redo as single transaction steps.

### Explicitly not included in v1 core

- "Do not ask again" preference.
- Recursive downstream delete policy.
- Affected object preview list in dialog.

---

## F) Undo / Redo / Revert

### Completed

- Snapshot-based session history:
  - undoStack / redoStack
  - open baseline snapshot
  - session-memory only
- Undo/Redo/Revert commands and availability state (`canUndo`, `canRedo`, `canRevert`).
- Dynamic recompute and source-removal cleanup merged into initiating transaction.
- Canvas pan/zoom updates coalesced to avoid per-frame stack pollution.
- Minimal UI entry + keyboard shortcuts integrated.

### Policies

- Undo stack is not serialized into `.emathica`.
- Save/autosave does not implicitly wipe session history.
- Reopen creates a fresh session baseline for that new open session.

---

## G) Save / Load / Preview / Recent

### Completed baseline

- `.emathica` roundtrip for:
  - all current geometry dependency kinds
  - geometryDefinitionStatus states
  - GeometryKind.circle
  - canvasState
  - style/slider core fields
- Reopen behavior:
  - dynamic geometry continues recompute
  - noSolution remains noSolution and can recover to defined when geometry becomes solvable
- Project preview:
  - skips non-defined derived objects
  - circle aspect ratio preserved (no ellipse distortion regression)
  - point thumbnail sizing kept bounded
- Recent usage:
  - open path updates `updatedAt` and refreshes ordering.

### Known gap notes (watch-only)

- Home-level file-management edge flows (rename/delete/update timing under heavy operations) still need broader device acceptance coverage.

---

## H) Performance / Sampling

### Current v1 core status

- Implicit fallback and diagnostics chain is functional and stabilized.
- Sampling diagnostics path exists and is usable for troubleshooting.

### Still under observation

- Pan/zoom stress performance on real devices with dense dynamic dependency scenes.
- Tangent/asymptote edge accuracy in difficult expressions remains a follow-up topic.

### Deferred by policy

- Viewport reactive sampling art mode (future direction, not v1 core).

---

## 3. Freeze Candidates (Bugfix-only)

Recommended freeze set:

1. SliderSystem
2. PlaneStyle
3. DynamicGeometry v1 dependency semantics
4. DependencyDeletionPolicy direct-only
5. SessionUndoRedo v1
6. PlaneSaveLoad baseline
7. Geometry tool v1 surface

Reason:

- Core functionality already closed-loop and cross-module coupled.
- New feature churn here has high regression risk across save/load, delete policy, and undo transaction semantics.

Still-required device acceptance checkpoints:

- Dynamic geometry noSolution transitions
- Delete dialog strategy correctness in real workflows
- Undo/redo/revert consistency after mixed operations
- Save/reopen correctness on recent list + preview refresh

---

## 4. Device Acceptance Checklist (Priority)

## P0 Dynamic Geometry

1. Dynamic midpoint update
2. Dynamic parallel/perpendicular update
3. Dynamic circle (center + fixed radius)
4. line-circle / circle-circle dynamic intersection update
5. noSolution disappear/recover behavior
6. Source deletion behaviors: unlink vs delete affected

## P0 Undo/Redo

1. Source move -> undo/redo
2. Source delete -> undo/redo
3. Batch delete -> undo/redo
4. Pan/zoom undo
5. Revert-to-open-state behavior

## P0 Save/Load

1. Save and reopen roundtrip
2. Dynamic geometry recompute after reopen
3. noSolution persistence and recovery
4. Preview correctness
5. Recent ordering correctness

## P1 UI/Interaction

1. Delete dialog path
2. Undo/redo button usability
3. Keyboard shortcuts in workspace flows
4. Object row source/status text readability
5. Object panel height/scroll behavior in dense lists

---

## 5. Known Risks

## P0

- Any save/load dependency loss.
- Undo/revert snapshot corruption of document state.
- Delete strategy deleting wrong object set.
- noSolution objects shown as valid points.
- Reintroduction of helper-point leakage in derived geometry.

## P1

- Object row information density in small vertical space.
- Delete dialog wording clarity and action confidence.
- "Convert to static" wording may be better as "转为独立对象".
- Pan/zoom performance variability in complex scenes.
- Expression-circle and geometry-circle coexistence UX consistency.
- Legacy helper-point cleanup for old documents (if present) remains a bounded cleanup topic.

## P2

- Status icon polish.
- Tool icon polish.
- Geometry property detail display.
- Three-point circle, tangent, arc, polygon.
- Intersection root identity tracking upgrades.
- Sampling art mode.
- Dedicated tangent/asymptote accuracy mode.

---

## 6. Recommended Next Task Order

1. PlaneV1CoreStatus-1 (this status consolidation)
2. Execute full real-device acceptance checklist
3. ObjectPanelInformationAudit-1
4. RenameConvertToIndependent-1
5. LegacyGeometryCleanupAudit-1
6. SamplingAccuracy-Tangent-1
7. ViewportReactiveSamplingArt-Audit-1

Not recommended now:

- "Do not ask again" deletion preference
- three-point circle / tangent / arc feature expansion
- tool icon micro-polish
- low-version iOS/Android adaptation work

---

## 7. Out of Scope (Current Freeze Window)

- New geometry tools
- Dynamic geometry semantic expansion
- Dependency graph UI
- Object panel layout redesign
- Parser/SamplingCore major algorithmic changes
- Platform adaptation expansions

