# SpaceCanvasReuseBoundaryAudit-1

Date: 2026-05-26  
Scope: Post-implementation boundary review for `SpaceCanvas-1` (documentation only)

## 1. Reuse mainline audit (复用主干复核)

### 1.1 Module-provider based integration
- Status: **PASS**
- Evidence:
  - `CalculatorModuleRegistry` routes `.space` to `SpaceWorkspaceModuleProvider`.
  - `WorkspaceView` still uses `configuration.moduleProvider.makeCanvasView(...)`.
- Conclusion: Space is integrated through the same module-provider seam as Plane, not hardcoded into `WorkspaceView`.

### 1.2 Space canvas isolation from Plane canvas
- Status: **PASS**
- Evidence:
  - New `SpaceCanvasView` is rendered by `SpaceWorkspaceModuleProvider`.
  - `SpaceCanvasView` has no dependency on `PlaneCanvasView`.

### 1.3 Space wireframe isolation from Plane renderers
- Status: **PASS**
- Evidence:
  - `SpaceWireframeRenderer` only uses `SpaceCameraState` projection + `GeometryDefinition` 3D kinds.
  - No usage of `PlaneObjectRendererView` or Plane semantic/sampling render path.

### 1.4 Camera state persistence path
- Status: **PASS**
- Evidence:
  - `WorkspaceView` passes `spaceCameraState: state.document.spaceCameraState` in `WorkspaceCanvasContext`.
  - `WorkspaceCommand.setSpaceCameraState` -> `WorkspaceState` -> `DocumentCommand.updateSpaceCameraState` -> `EMathicaDocument.spaceCameraState`.
- Conclusion: camera state is document-backed and correctly separated from 2D `canvasState`.

### 1.5 Undo coalescing reuse
- Status: **PASS**
- Evidence:
  - `SpaceCanvasView` wraps gestures with `.setCanvasInteracting(true/false)`.
  - `WorkspaceState.shouldRecordUndo(for: .setSpaceCameraState)` returns `!isCanvasInteracting`.
  - Existing canvas transaction system coalesces to one undo step.
- Test:
  - `SpaceCanvasTests.spaceCameraInteractionCoalescesUndoIntoSingleStep`.

### 1.6 Save/load and history safety
- Status: **PASS**
- Evidence:
  - Space camera is on `EMathicaDocument` and persisted through existing document codec path.
  - `ObjectHistoryRecovery` model untouched; no Space-specific bypass was introduced.

### 1.7 Preview safety
- Status: **PASS**
- Evidence:
  - Current preview pipeline remains Plane-oriented and safely ignores unsupported 3D geometry objects (existing test coverage for ignore behavior).

### 1.8 Out-of-scope guard compliance
- Status: **PASS**
- No hit test, creation tools, dependency, surfaces, SceneKit/Metal integration added.

---

## 2. Plane-specific reuse audit (不该复用的 Plane 实现)

Checked modules:
- `PlaneCanvasView`: **not reused**
- `PlaneGeometryResolver`: **not reused**
- `PlaneHitTestService`: **not reused**
- `PlaneObjectRendererView`: **not reused**
- `PlaneIntersectionSolver`: **not reused**
- Plane sampling pipeline: **not reused**
- `PlaneToolProvider` creation flow: **not reused**

Conclusion: SpaceCanvas-1 keeps correct isolation from Plane concrete implementations.

---

## 3. PlaneCommandHandler risk analysis

`PlaneCommandHandler` now has an explicit no-op branch for `.setSpaceCameraState`.

### Why it exists
- `WorkspaceCommand` is shared globally and Plane command switch must stay exhaustive.
- This branch is compile-compatibility and behavioral no-op.

### Risk assessment
- Immediate risk: **Low**
- Architectural debt: **Low-to-medium** (shared command enum growth pushes each module handler to add unrelated no-op branches).

### Key clarification
- Space camera write path is handled in `WorkspaceState` before module handlers.
- Space does **not** depend on `PlaneCommandHandler` for camera updates.

### Recommendation
Before/within `SpaceTools-1`, introduce `SpaceCommandHandler` for Space-specific module commands and keep global commands centralized in `WorkspaceState` where possible.

---

## 4. v0.1 boundary compliance (SpaceCanvas-1 是否越界)

Confirmed not implemented in this phase:
1. hit test
2. object creation tools
3. 3D dependency recompute
4. `z=f(x,y)` surfaces
5. SceneKit / Metal / RealityKit path
6. 3D preview renderer feature
7. Space keyboard/input specialization
8. 3D inspector extension

Conclusion: stays within v0.1 wireframe validation boundary.

---

## 5. SpaceTools-1 readiness and gaps

### What is ready
- Module-provider wiring
- Canvas interaction loop
- Camera persistence + undo coalescing
- 3D geometry storage and wireframe projection

### What is still missing before practical tool authoring
1. `SpaceCommandHandler` (module-local object creation command boundary)
2. `SpaceToolProvider` (tool IDs and creation action mapping)
3. Optional `SpaceGeometryResolver` (to avoid bloating wireframe renderer as tools grow)
4. Minimal selection/hit-test policy decision

### Scope recommendation for `SpaceTools-1`
- Preferred first slice:
  - `point3D`, `segment3D` creation only
  - minimal select-state integration
- Next slice:
  - `line3D`, `plane3D`
- Defer:
  - depth-aware picking sophistication
  - multi-object 3D construction chains

---

## 6. Suggested next task sequence

1. `SpaceTools-1A`  
   - Add `SpaceCommandHandler` + `SpaceToolProvider`  
   - Implement `point3D/segment3D` creation

2. `SpaceSelectionAudit-1`  
   - Define minimal 3D selection/hit strategy (screen-space threshold + depth tie-break policy)

3. `SpaceTools-1B`  
   - Add `line3D/plane3D` creation

4. `SpacePreview-1`  
   - Add Space-aware project preview rendering strategy

---

## 7. Final verdict

SpaceCanvas-1 correctly reuses shared Workspace/Document/Undo infrastructure, keeps Plane implementation isolation, preserves 2D/3D state separation (`canvasState` vs `spaceCameraState`), and remains within v0.1 wireframe scope.

