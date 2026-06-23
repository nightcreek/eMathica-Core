# Plane Dependency Deletion Policy Audit

## 1) Current Delete Behavior

## UI -> command path

- Object row delete entry lives in:
  - `WorkspaceKit/ObjectPanel/WorkspaceObjectRowView.swift` (`Label("删除", ...)`)
  - `WorkspaceKit/ObjectPanel/AlgebraObjectPanelView.swift` (`onDelete: { state.dispatch(.deleteObject(id: obj.id)) }`)
- Current path is direct dispatch, no pre-delete confirmation dialog.

## Workspace command layer

- `WorkspaceCommand` currently exposes:
  - `.deleteObject(id: UUID)`
  - `.deleteSelectedObjects`
- `WorkspaceCommand` does not currently carry a deletion policy mode.

## Module command -> document command

- `WorkspaceState.dispatch` passes command to module handler, receives `output.documentCommands`.
- Deletion is represented by:
  - `DocumentCommand.deleteObject(id:)`
  - `DocumentCommand.deleteObjects([UUID])`
- `EMathicaDocument.apply` removes objects immediately:
  - `objects.removeAll(where: ...)`

## Dependency cleanup trigger

- In `WorkspaceState.dispatch`:
  1. Compute `removedSourceIDs` from outgoing `DocumentCommand`s against pre-apply document snapshot.
  2. `document.apply(output.documentCommands)`
  3. If `removedSourceIDs` non-empty, call `applyGeometryDependencyCleanup(removedSourceIDs:)`.
- Cleanup implementation is centralized in:
  - `PlaneGeometryDependencyRecomputeService.dependencyCleanupPatchesForRemovedSources(...)`

---

## 2) Current Dependency Cleanup Behavior

- Cleanup scans all remaining objects.
- For each object with `geometryDependency`, if dependency references any removed source ID:
  - emits `DocumentObjectPatch(clearGeometryDependency: true, clearGeometryDefinitionStatus: true)`.
- Result: derived object is converted to independent/static object while preserving existing geometry/position/style/name/visibility/id.

This matches current v1 policy:
- source removed -> derived unlinked, not deleted.

---

## 3) How “Affected Objects” Are Determined Today

Current code supports identifying **direct references** only:
- `midpointOfPoints(pointAID, pointBID)`
- `parallelLine(referenceObjectID, throughPointID)`
- `perpendicularLine(referenceObjectID, throughPointID)`
- `intersectionOf(objectAID, objectBID, index)`
- `circleByCenterPoint(centerPointID, throughPointID)`
- `circleByCenterRadius(centerPointID, radius)`

There is no built-in recursive dependency graph traversal in delete path.

---

## 4) Terminology (recommended)

- **source object**: object referenced by a dependency.
- **derived object**: object carrying `geometryDependency`.
- **directly affected object**: derived object directly referencing removed source object(s).
- **downstream affected object**: recursive derived chain under directly affected objects.

---

## 5) Direct vs Downstream Scope

## Option A: direct-only (recommended for v1)

- Only directly affected derived objects are considered “related”.
- Pros:
  - predictable
  - safer blast radius
  - easier UI messaging
- Cons:
  - downstream chain may remain but become semantically loosened

## Option B: recursive downstream

- Include full dependency closure.
- Pros:
  - semantically complete cascade
- Cons:
  - high deletion risk
  - harder to explain and trust

## Recommendation

- v1 use **direct-only**.
- Defer recursive mode to advanced phase.

---

## 6) Recommended Deletion Strategies

## Strategy 1: unlink (keep derived)

User label:
- `仅删除所选对象`

Behavior:
1. Delete selected source object(s).
2. Convert directly affected derived objects to independent/static:
   - clear dependency + status.
3. Keep derived geometry/position/style/name/visibility/id.

Equivalent to current cleanup behavior, but user-selected.

## Strategy 2: delete affected

User label:
- `删除所选及相关对象`

Behavior:
1. Delete selected source object(s).
2. Delete directly affected derived objects.
3. No recursive downstream in v1.

---

## 7) Confirmation Dialog Design

## Trigger

Show dialog when:
- user deletion target has >=1 directly affected derived objects.

Skip dialog when:
- no directly affected objects, or
- preference says auto-apply policy without asking.

## Suggested copy

- Title: `删除关联对象？`
- Message: `该对象被 N 个动态对象引用。请选择如何处理相关对象。`
- Actions:
  - `仅删除所选对象`
  - `删除所选及相关对象`
  - `取消`
- Option:
  - `不再提示`

If `不再提示` checked, persist current action as default policy.

---

## 8) Preference Design

## Setting name

- `删除关联对象时`

## Values

1. `每次询问`
2. `默认仅删除所选对象`
3. `默认删除所选及相关对象`

## Storage scope

- Recommend app/workspace preference (not document content).
- Reason: avoid personal UX preference entering shared `.emathica` files.

## Existing storage seam

- `WorkspaceView` already uses `@AppStorage` for UI preference (`Workspace.objectPanelWidth`), so this is a viable persistence pattern for deletion policy preference.

---

## 9) Batch Deletion Behavior (v1)

When deleting multiple selected objects:

1. Build union of directly affected derived objects from all selected sources.
2. Deduplicate by ID.
3. Exclude already selected IDs from “affected extra” count.
4. Dialog count uses deduped extras.

Execution:
- unlink mode:
  - delete selected
  - clear dependency/status on deduped affected extras
- delete-affected mode:
  - delete selected + deduped affected extras

---

## 10) Risks and Decisions

1. Recursive deletion blast radius:
   - keep out of v1.
2. Double-count in batch delete:
   - require dedupe set by ID.
3. Status residue:
   - ensure unlink and source-removal paths both clear dependency + status.
4. “Never ask again” recovery:
   - must be reversible in settings.
5. No undo/history:
   - cascade deletion is riskier.
6. Default policy:
   - recommend `每次询问` as safest initial default.

---

## 11) Recommended Implementation Phases

## DependencyDeletionPolicy-1A

- Direct-only affected scope.
- Confirmation dialog always shown when affected count > 0.
- Two strategies implemented:
  - unlink
  - delete affected

## DependencyDeletionPolicy-1B

- Add `不再提示` and persistent preference setting.
- Add batch deletion UX polish:
  - affected count text
  - optional affected object preview list.

## DependencyDeletionPolicy-1C

- Integrate with Undo/Redo and future ObjectHistoryRecovery.
- Optional downstream-recursive advanced strategy.

---

## 12) Summary

Current behavior is deterministic and safe (unlink-on-source-delete), but policy is implicit and non-configurable. Product direction is achievable with minimal architectural change by adding a policy decision layer before issuing delete commands, while reusing existing dependency cleanup machinery for unlink mode.

