# Plane Session Undo/Redo Audit

## 1. Scope

This audit defines a v1 session-level Undo/Redo/Revert system for Plane.

- Session-level only: track edits after current file open.
- Stack is in-memory only and is cleared on file close.
- Includes object/document edits and canvas viewport edits.
- Includes dynamic-geometry recompute and source-removal cleanup as part of the same user action transaction.
- This is design-only. No production code changes in this audit.

---

## 2. Current Mutation Pathways

### 2.1 Unified document mutation path

Current central path:

1. UI / canvas / panel dispatch `WorkspaceCommand`.
2. `WorkspaceState.dispatch(_:)` routes command.
3. Most commands go through `moduleProvider.commandHandler` (`PlaneCommandHandler` in Plane).
4. Handler returns `ModuleCommandOutput(documentCommands:, effects:)`.
5. `WorkspaceState.dispatch` calls `document.apply(output.documentCommands)`.
6. `WorkspaceState` then runs:
   - dependency cleanup for removed source IDs (`applyGeometryDependencyCleanup`)
   - dependency recompute for changed source IDs (`applyGeometryDependencyRecompute`)
7. Effects are applied.

`EMathicaDocument.apply(_:)` is the unified persistence mutation entry for:

- object add/update/delete
- visibility
- reorder
- canvasState update
- metadata update

### 2.2 Command mapping (current)

- Create geometry/function objects:
  - `createPoint/createSegment/createLine/createRay`
  - `moduleSpecific` for circle/intersection/midpoint/parallel/perpendicular
  - `submitInput` for expression-commit object creation
- Delete:
  - `deleteObject(id:)`
  - `deleteObjects(ids:)`
  - `deleteSelectedObjects`
- Move point:
  - `updateObjectPosition(id:position:)` (point only; derived objects blocked)
- Style:
  - `updateObjectStyle(...)`
- Visibility:
  - `toggleObjectVisibility(id:)`
- Rename:
  - `renameObject(id:newName:)`
- Convert derived -> static:
  - `convertObjectToStatic(id:)`
- Canvas viewport:
  - `setCanvasViewport(CanvasState)` -> `DocumentCommand.updateCanvasState`
- Slider:
  - `updateParameter(id:value:)` directly applies `DocumentCommand.updateObject`
  - `updateSliderSettings(id:settings:value:)` directly applies `DocumentCommand.updateObject`

### 2.3 Dynamic geometry follow-up

- Recompute trigger location:
  - `WorkspaceState.dispatch` after `document.apply(output.documentCommands)`.
- Source-removal cleanup trigger location:
  - same place, before recompute, based on removed IDs from commands.

### 2.4 Existing history support

- No command history stack currently.
- No undo/redo stack currently.
- No explicit document dirty-flag model found in this path.

---

## 3. Current Viewport Mutation Pathway

### 3.1 Pan/zoom flow

In `PlaneCanvasView`:

- Pan gesture `.onChanged`: repeatedly dispatches `setCanvasViewport`.
- Zoom gesture `.onChanged`: repeatedly dispatches `setCanvasViewport`.
- Gesture begin/end also dispatch `setCanvasInteracting(true/false)` (transient state).

### 3.2 Persistence behavior

- Viewport is stored in `document.canvasState`.
- Canvas mutation goes through `DocumentCommand.updateCanvasState`.
- Currently pan/zoom may write document at frame-rate during gesture.

### 3.3 Gesture boundaries available

- Start/end hooks exist for pan and zoom gestures.
- These can be used to coalesce many frame updates into one undo step.

### 3.4 Preview dependency

- Home/project preview is document-based and may be viewport-sensitive depending on renderer usage of `canvasState`; keep viewport in undo scope for consistency.

---

## 4. Undoable vs Non-Undoable Operations

## 4.1 Should enter undo stack

Object/document operations:

- create object(s)
- delete object(s)
- delete affected objects strategy
- move point
- expression commit/edit changes
- style updates
- visibility toggles
- slider value updates (manual)
- slider settings updates
- convert-to-static
- source-removal cleanup effects
- dynamic recompute effects
- rename/reorder (if user-facing)

Canvas operations:

- pan/zoom/reset viewport
- grid/axis visibility if persisted to `canvasState`

## 4.2 Should NOT enter undo stack

Transient UI/session states:

- hover preview
- current selection
- active tool
- keyboard open/close
- inspector open/close
- menu/sheet open state
- cursor/slot focus
- toasts/ephemeral diagnostics banner state
- object panel scroll offset

---

## 5. Transaction Boundary Rules (Critical)

## 5.1 Dynamic recompute must be merged

A source edit + all dependency recomputes + status updates must be one undo step.

Example:

- user drags source point
- source point updates
- dynamic midpoint/circle/intersection updates
- noSolution/defined status updates

Undo must revert all of the above together.

## 5.2 Delete + cleanup must be merged

A delete action + dependency cleanup + any resulting status changes must be one undo step.

## 5.3 Slider playback policy

Recommended v1:

- manual slider drag/change: undoable
- autoplay ticks: not pushed per frame
- optional: at playback stop, either no undo entry or one coalesced step (prefer no-entry in v1 for stability and stack quality)

## 5.4 Pan/zoom coalescing

Recommended v1:

- on gesture begin: capture `before canvasState`
- during gesture: no per-frame stack push
- on gesture end: if delta above threshold, push one step (`before -> after`)

Threshold guidance:

- translation threshold in screen px
- scale threshold in relative ratio

---

## 6. Data Model Comparison

## 6.1 Option A: Snapshot-based (recommended v1)

Each undo step stores:

- before document snapshot
- after document snapshot
- operation title
- timestamp
- optional operation category

Because `canvasState` is inside `EMathicaDocument`, viewport is naturally included.

Pros:

- robust with dynamic recompute/cleanup chains
- minimal risk of missing side effects
- simple to reason/debug

Cons:

- memory heavier

v1 limits:

- in-memory only
- bounded depth (e.g. 50~100)
- drop oldest when overflow

## 6.2 Option B: Inverse-command

Pros:

- lower memory

Cons:

- high complexity and high miss-risk with dynamic geometry side effects
- every command path needs correct inverse including cleanup/recompute

Conclusion:

- v1 should use snapshot-based undo.

---

## 7. Revert-to-Open-State Design

At file open:

- capture `openBaselineSnapshot` (full `EMathicaDocument`).

Action: "恢复到打开时状态"

- replace current document with baseline snapshot.

Recommended v1 behavior:

- revert action itself is undoable as one step (`before current -> baseline after`)
- clear redo stack after revert (standard rule when new branch is created)

Fallback if implementation complexity is high:

- revert then clear both undo/redo stacks (acceptable but weaker UX)

---

## 8. UI Entry Design (Design Only)

Suggested entries:

- toolbar: Undo / Redo buttons
- menu/more: Undo / Redo / Revert to open-state
- hardware keyboard:
  - Cmd+Z
  - Shift+Cmd+Z (or Cmd+Y)

Revert wording:

- `恢复到打开时状态`
- detail: `放弃本次打开后的所有修改`

---

## 9. Save/Close Policy

- Undo stack is NOT serialized into `.emathica`.
- Saving document does NOT clear undo stack.
- Closing file clears undo/redo stack.
- Reopening starts new session baseline.
- Autosave should not reset session undo stack.

---

## 10. Directly Applicable v1 Architecture

1. Add `WorkspaceSessionHistory` owned by `WorkspaceState`:
   - `undoStack`, `redoStack`, `openBaseline`
2. Wrap document mutations in transactional API:
   - capture `before`
   - execute command + cleanup + recompute
   - capture `after`
   - push one step if meaningful delta
3. Add coalesced viewport transaction hooks:
   - pan/zoom begin/end
4. Add commands:
   - `undo`
   - `redo`
   - `revertToOpenBaseline`

---

## 11. Risks

- Memory pressure with large snapshots.
- Gesture-noise polluting stack if coalescing thresholds are weak.
- Missing transaction boundaries can fragment dynamic geometry into multiple undo steps.
- Mixed direct `document.apply` calls (outside handler path) must be routed through same transactional recorder, otherwise holes in history.

---

## 12. Implementation Test Plan (for next implementation pass)

- snapshot model roundtrip and stack bound
- redo clear on new branch
- object create/delete/move/style/slider/convert-to-static undo/redo
- dynamic recompute as single step
- delete+cleanup as single step
- noSolution transitions undo/redo
- pan/zoom coalesced single-step
- revert-to-open-state behavior

