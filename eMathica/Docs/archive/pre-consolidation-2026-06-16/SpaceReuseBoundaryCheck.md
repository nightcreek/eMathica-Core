# Space Reuse Boundary Check

Date: 2026-05-26  
Scope: SpaceCalculator v0.1 pre-`SpaceCanvas-1` reuse boundary audit (documentation only)

## 0. Current baseline

Space route is already partially connected:

- `CalculatorModuleRegistry.moduleProvider(for: .space)` now routes to `SpaceWorkspaceModuleProvider`.
- `WorkspaceCanvasContext` already carries `spaceCameraState`.
- `WorkspaceCommand` already has `.setSpaceCameraState(SpaceCameraState)`.
- `DocumentCommand` / `EMathicaDocument` already support `updateSpaceCameraState` + `spaceCameraState`.
- Space wireframe stack exists (`SpaceCanvasView`, `SpaceWireframeRenderer`) and is isolated from Plane rendering services.

This means `SpaceCanvas-1` should be treated as **integration hardening + boundary enforcement**, not greenfield wiring.

---

## 1) 必须复用清单 (Must Reuse)

These are core shared systems Space should reuse directly:

1. **Workspace shell**
   - `WorkspaceView`
   - `WorkspaceState`
   - `WorkspaceConfiguration`
   - `WorkspaceModuleProviding` protocol

2. **Command pipeline**
   - `WorkspaceCommand` dispatch flow
   - `ModuleCommandHandler` / `ModuleCommandOutput`
   - `DocumentCommand` apply pipeline

3. **Document model and persistence**
   - `EMathicaDocument`
   - `EMathicaPackageCodec`
   - `LocalProjectStore`
   - `.emathica` save/load/recent plumbing

4. **History safety**
   - session `Undo/Redo/Revert` snapshot system
   - `ObjectHistoryRecovery` data layer (`deletedObjectHistory`)

5. **Panel/Inspector shell**
   - `AlgebraObjectPanelView` framework shell
   - `ObjectInspectorPanel` shell
   - document menu + deleted-history sheet entry path

6. **Toolbar framework**
   - `WorkspaceToolGroup` / `WorkspaceTool` / `FloatingToolGroupsView`
   - tool action dispatch convention

7. **Geometry container model**
   - shared `GeometryDefinition` + `MathObject`
   - shared `SpaceCameraState` persistence slot on `EMathicaDocument`

---

## 2) 禁止复用清单 (Do Not Reuse Plane-specific implementations)

Space must not reuse Plane concrete runtime services:

1. `PlaneCanvasView`
2. `PlaneGeometryResolver`
3. `PlaneHitTestService`
4. `PlaneToolProvider` (object-construction tools)
5. Plane 2D intersection/dependency recompute services
6. Plane 2D sampling/curve rendering stack
7. Plane 2D viewport semantics (`CanvasState` as 2D camera substitute)

Rule: reuse **framework contracts**, not Plane **algorithm bodies**.

---

## 3) 需要新建/保持 Space 专属模块清单

For `SpaceCanvas-1` and immediate follow-ups, Space-owned modules should be:

1. `CalculatorModules/Space/SpaceWorkspaceModuleProvider.swift`
2. `CalculatorModules/Space/Views/SpaceCanvasView.swift`
3. `CalculatorModules/Space/Services/SpaceWireframeRenderer.swift`
4. (next) `CalculatorModules/Space/Services/SpaceSceneResolver.swift` (if geometry extraction grows)
5. (next) `CalculatorModules/Space/Commands/SpaceCommandHandler.swift` (when tools/input are added)

Keep these separate from Plane folders to avoid accidental coupling.

---

## 4) SpaceCanvas-1 最小接入方案

Recommended minimal integration boundary:

1. **Canvas entry**
   - `WorkspaceView` -> module provider -> `SpaceCanvasView`
   - pass `objects + spaceCameraState + dispatch`

2. **Rendering**
   - `SpaceWireframeRenderer` maps 3D `GeometryDefinition` to projected 2D primitives
   - draw with SwiftUI `Canvas` only (no SceneKit/RealityKit/Metal)

3. **Camera state**
   - `SpaceCanvasView` updates via `.setSpaceCameraState`
   - persisted through `DocumentCommand.updateSpaceCameraState`

4. **Undo coalescing**
   - camera gestures must wrap with `.setCanvasInteracting(true/false)`
   - avoid per-frame undo entries

5. **Out of scope in SpaceCanvas-1**
   - no 3D object creation tools
   - no 3D hit test/selection
   - no 3D dependency recompute
   - no 3D preview renderer extension

---

## 5) 后续任务边界

### A. `SpaceTools-1`

Should include:
- Space tool definitions + creation commands (`point3D/segment3D/line3D/plane3D`)
- `SpaceCommandHandler` (module-specific creation flow)

Should not include:
- dependency graph
- advanced solids/surfaces
- custom history system

### B. `SpaceInputAudit-1`

Should include:
- assess Formula/Input framework reuse for 3D expressions
- decide which input templates are meaningful for Space v0.1

Should not include:
- parser core rewrite
- CAS architecture changes

### C. `SpacePreview-1`

Should include:
- project preview strategy for 3D docs (wireframe snapshot, camera-aware)

Should not include:
- full 3D renderer migration
- video/export system

---

## 6) 发现的当前可复用遗漏点

Potential reusable seams not fully formalized yet:

1. **Generic camera interaction coalescing API**
   - currently piggybacks on canvas interacting; good enough, but not explicit for multi-camera modules.

2. **Module-neutral scene primitive abstraction**
   - Space introduced wireframe primitives locally; future shared abstraction could help preview/export.

3. **Module-specific preview provider interface**
   - `ProjectPreviewRenderer` is still Plane-centric behavior + ignore fallback for unsupported; Space preview extension needs explicit provider seam.

These are not blockers for SpaceCanvas-1, but should be tracked.

---

## 7) 是否建议调整 SpaceCanvas-1 任务描述

Yes, minor wording adjustment is recommended:

1. Change "新增 Space module provider" to:
   - **"确认并收敛到 SpaceWorkspaceModuleProvider（若已存在则只做边界强化）"**

2. Explicitly require:
   - camera gesture updates must be undo-coalesced through existing session history path
   - no Plane service import in Space renderer path

3. Explicitly defer:
   - `ProjectPreviewRenderer` 3D draw support to `SpacePreview-1`
   - any 3D object selection/hit-test to `SpaceTools-2` or later

This keeps SpaceCanvas-1 tight and prevents scope creep.

