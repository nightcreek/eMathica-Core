# R1: Calculator Reality Audit

Read-Only. Zero modifications.

---

## 1. CalculatorModules/ Directory Tree

```
CalculatorModules/
├── CalculatorModule.swift
├── CalculatorModuleRegistry.swift
├── DefaultWorkspaceModuleProvider.swift
├── Commands/
│   ├── ModuleCommandHandlerRegistry.swift
│   └── ModuleCommandHandling.swift
├── Data/          Views/DataPlaceholderView.swift
├── Modeling/      Views/ModelingPlaceholderView.swift
├── Music/         Views/MusicPlaceholderView.swift
├── Notes/         Views/NotesPlaceholderView.swift
├── Plane/         (28 files — see below)
└── Space/         (9 files — see below)
```

**Total: 51 files in CalculatorModules/**

---

## 2. Feature Matrix — Calculator × Capability

| Feature | Plane | Space | Data | Music | Notes | Modeling |
|---------|:-----:|:-----:|:----:|:-----:|:-----:|:--------:|
| Module Provider | Implemented | Implemented | Placeholder | Placeholder | Placeholder | Placeholder |
| Canvas View | Implemented | Implemented | Placeholder | Placeholder | Placeholder | Placeholder |
| CommandHandler | Implemented | Implemented | Placeholder | Placeholder | Placeholder | Placeholder |
| ToolProvider | Implemented | Implemented | Placeholder | Placeholder | Placeholder | Placeholder |
| ToolIDs | 17 tools | 7 tools | Missing | Missing | Missing | Missing |
| Services | 22 files | 3 files | Missing | Missing | Missing | Missing |
| Renderer | Multi-file | Wireframe | Missing | Missing | Missing | Missing |
| HitTest | Implemented | Implemented | Missing | Missing | Missing | Missing |
| Preview/Draft | Implemented | Stub (returns nil) | Missing | Missing | Missing | Missing |
| Inspector | Missing* | Missing* | Missing | Missing | Missing | Missing |
| Semantic | Multi-file | Missing | Missing | Missing | Missing | Missing |

> \* Inspector is handled at WorkspaceKit level, not per-module. No `*Inspector*.swift` in any module.

---

## 3. Placeholder / Noop / Empty Implementation List

### Files with "Placeholder" in Name (5)

| File | Content | Used By |
|------|---------|---------|
| `Data/Views/DataPlaceholderView.swift` | `ContentUnavailableView` | `DefaultWorkspaceModuleProvider` |
| `Modeling/Views/ModelingPlaceholderView.swift` | `ContentUnavailableView` | `DefaultWorkspaceModuleProvider` |
| `Music/Views/MusicPlaceholderView.swift` | `ContentUnavailableView` | `DefaultWorkspaceModuleProvider` |
| `Notes/Views/NotesPlaceholderView.swift` | `ContentUnavailableView` | `DefaultWorkspaceModuleProvider` |
| `Space/Views/SpaceCalculatorPlaceholderView.swift` | `ContentUnavailableView` | **Dead code** — Space uses its own real provider |

### Noop/Stub Implementations (7)

| File | Issue |
|------|-------|
| `DefaultWorkspaceModuleProvider.swift` | `makeDraftMathObject` returns `nil`; all service protocols return `nil`; used by Data/Music/Notes/Modeling |
| `Plane/Services/PlaneObjectNamingService.swift` | **Empty struct body** — naming logic is inline in `PlaneCommandHandler` |
| `Plane/Interaction/PlaneInteractionReducer.swift` | Only handles `.reset`; all other transitions unimplemented |
| `Plane/Tools/PlaneToolActions.swift` | Comment-only placeholder: `"Reserved for Plane-specific tool gesture..."`
| `Plane/Services/PlaneInputCanonicalizer.swift` | Identity transform; `canonicalize` returns `source` unchanged with a TODO |
| `Space/SpaceWorkspaceModuleProvider.swift` | `makeDraftMathObject` returns `nil` |
| `Commands/ModuleCommandHandlerRegistry.swift` | `NoopCommandHandler()` for Data/Music/Notes/Modeling |

### TODO / FIXME Count

| Calculator | Count | Detail |
|------------|:-----:|--------|
| Plane | 1 | `PlaneInputCanonicalizer.swift:L15` — canonicalize TODO |
| Space | 1 | `SpaceWorkspaceModuleProvider.swift:L45` — 3D GeometryDependencyService TODO |
| Data/Music/Notes/Modeling | 0 | — |

---

## 4. Plane Reality

### 2D Objects Actually Implemented

| MathObjectType | Create | Render | HitTest | Dependency | Dynamic |
|:---------------|:------:|:------:|:------:|:----------:|:------:|
| `.point` | ✅ | ✅ | ✅ | ✅ (midpoint child) | ✅ Draggable |
| `.function` | ✅ | ✅ | ✅ | ❌ | ✅ Expression editable |
| `.circle` | ✅ | ✅ | ✅ | ✅ (center+radius, center+through) | ✅ Expression editable |
| `.segment` | ✅ | ✅ | ✅ | ✅ (anchored to points) | ❌ Read-only |
| `.line` | ✅ | ✅ | ✅ | ✅ (parallel/perpendicular) | ❌ Read-only |
| `.ray` | ✅ | ✅ | ✅ | ❌ | ❌ Read-only |
| `.arc` | ✅ | ✅ | ✅ | ✅ (by 3 points) | ❌ Read-only |
| `.parameter` | ✅ | ✅ | ❌ (excluded from hit) | ❌ | N/A |
| `.parameterGroup` | Stub | ❌ | ❌ (excluded from hit) | ❌ | N/A |

### Tools (17 declared, 15 in toolbar)

```
plane.select, plane.pan, plane.boxSelect, plane.delete,
plane.point, plane.segment, plane.midpoint, plane.line, plane.ray,
plane.parallel, plane.perpendicular, plane.circle, plane.arc,
plane.intersection, plane.function, plane.curve, plane.slider
```

`plane.boxSelect` and `plane.curve` declared in IDs but not in ToolProvider groups.

### Services (22 files — ALL real implementations)

| Category | Files |
|----------|-------|
| Core Geometry | `PlaneGeometryResolver`, `PlaneGeometryPresentationResolver`, `PlaneLineClipping` |
| Expression | `PlaneExpressionService` (calls `AlgebraCore.analyzePlaneLatex`) |
| HitTest | `PlaneHitTestService` (handles all object types including semantic-plot) |
| Dependency | `PlaneGeometryDependencyService`, `PlaneGeometryDependencyRecomputeService` |
| Draft/Preview | `PlaneDraftPreviewService` (legacy + semantic paths) |
| Intersection | `PlaneIntersectionSolver`, `PlaneIntersectionPreviewResolver` |
| Sampling | `PlaneLegacyExplicitSampling`, `PlaneFallbackSamplingService`, `PlaneSampleSetAdapter`, `PlaneSamplingViewportResolver`, `PlaneSamplingQualityPolicy` |
| Semantic | `PlaneSemanticIntentResolver`, `PlaneSemanticIntentAdapter`, `PlaneSemanticGraphIntentAdapter`, `PlaneSemanticPreviewPolicy` |
| Debug | `PlaneSamplingComparisonDebug`, `PlaneSemanticSamplingDebug` (#if DEBUG) |
| Naming | `PlaneObjectNamingService` (empty struct — naming inline in CommandHandler) |
| Input | `PlaneInputCanonicalizer` (identity transform, TODO) |

### Legacy MathObjectType Usage in Plane

Plane dispatches on `MathObjectType` extensively — NOT on `GeometryDefinition.kind`:

- **`PlaneWorkspaceModuleProvider`**: `canEditExpression` switches on type (`.function, .point, .circle, .parameter` vs read-only types)
- **`PlaneCommandHandler`**: Creates objects by type; guards move operations by type
- **`PlaneHitTestService`**: Type-switch dispatch for rendering+hit test
- **`PlaneGeometryResolver`**: `lineLikePoints` dispatches on type
- **`PlaneModule`**: Demo objects use type directly

---

## 5. Space Reality

### 3D Objects Actually Implemented (4 types)

| Object | Create | Render | HitTest |
|--------|:------:|:------:|:------:|
| point3D | ✅ `space.createPoint3D` | ✅ Projected dots | ✅ Point snap + hit |
| segment3D | ✅ `space.createSegment3D` (2-tap) | ✅ Wireframe segment | ✅ Segment hit |
| line3D | ✅ `space.createLine3D` (2-tap) | ✅ Clipped infinite line | ✅ Line hit |
| plane3D | ✅ `space.createPlane3D` (3-tap) | ✅ Filled quad + grid | ✅ Plane edge hit |

### MathObjectType + GeometryDefinition.kind Hack

Space uses a **dual-type hack**. Objects are created with "false" `MathObjectType` but carry the real 3D identity in `GeometryDefinition.kind`:

| 3D Object | MathObjectType | GeometryDefinition.kind | GeometryDefinition fields |
|-----------|---------------|------------------------|---------------------------|
| point3D | `.point` | `.point3D` | `point3D` |
| segment3D | `.segment` | `.segment3D` | `point3D`, `pointB3D` |
| line3D | `.line` | `.line3D` | `point3D`, `vector3D` |
| plane3D | `.function` (!!!) | `.plane3D` | `point3D`, `vector3D` |

The renderer (`SpaceWireframeRenderer`) switches on `definition.kind` (not `.type`) for rendering dispatch. 2D kinds (`.point`, `.segment`, `.line`, `.ray`, `.circle`, `.arc`) are explicitly skipped.

### Space Services (3 files — ALL real)

| Service | Content |
|---------|---------|
| `SpaceWireframeRenderer` | Full 3D wireframe scene builder: perspective/orthographic projection, near-plane clipping, axis rendering, plane grid |
| `SpaceHitTestService` | Point and segment hit testing against projected wireframe scene, priority-based selection |
| `SpaceGeometryResolver` | Ray-casting onto work planes (XY/YZ/ZX), point snapping, plane normal computation |

### Space Tools (7)

```
space.point3D, space.segment3D, space.line3D, space.plane3D,
space.orbit, space.pan, space.select
```

### Space Capability Gaps

| Feature | Status |
|---------|:------:|
| Has own CanvasView | ✅ `SpaceCanvasView` |
| Has own CommandHandler | ✅ `SpaceCommandHandler` |
| Has own HitTest | ✅ `SpaceHitTestService` |
| Has own Renderer | ✅ `SpaceWireframeRenderer` |
| Has Preview/Draft | ❌ `makeDraftMathObject` returns nil |
| Has Semantic Layer | ❌ No semantic files |
| Has Inspector | ❌ None |
| Has 3D DependencyService | ❌ TODO only |
| Uses MathObjectType hack | ⚠️ Yes — 4 object types all use dual-type pattern |

---

## 6. Data / Music / Notes / Modeling — Verdict

### ALL FOUR ARE PLACEHOLDER-ONLY

Shared architecture:
1. **No dedicated ModuleProvider** — all use `DefaultWorkspaceModuleProvider(module:id:toolGroups:)`
2. **No dedicated CommandHandler** — all use `NoopCommandHandler()`
3. **No dedicated Tools** — all use `defaultToolGroups()` (only `common.select` + `common.pan`)
4. **No Services/** — no services directory
5. **Placeholder Views** — exactly ONE file each: a `*PlaceholderView.swift` showing `ContentUnavailableView`
6. **`makeDraftMathObject` returns `nil`** — no formula preview for any of them
7. **`buildExpression` is passthrough** — returns `.success(MathExpression(displayText: source))`
8. **All service protocols return `nil`** — no geometry dependency, no semantic, no hit test

### Module Registration

| Module | Title | Icon |
|--------|-------|------|
| `.data` | 数据分析 | `data_analysis` |
| `.music` | 音乐 | `music` |
| `.notes` | 笔记与公式 | `notes_formula` |
| `.modeling` | 建模 | `modeling` |

**Conclusion:** These 4 modules are pure UI placeholder scaffolding. Zero functional code.

---

## 7. Summary Statistics

| Metric | Count |
|--------|:-----:|
| Total files in CalculatorModules/ | 51 |
| Real modules (Implemented or Partial) | 2 (Plane, Space) |
| Placeholder-only modules | 4 (Data, Music, Notes, Modeling) |
| Implemented files | ~45 |
| Placeholder/stub files | ~10 |
| Plane services | 22 |
| Space services | 3 |
| Plane tools | 17 declared, 15 in toolbar |
| Space tools | 7 |
| TODO occurrences | 2 |
| Dead code | 1 (`SpaceCalculatorPlaceholderView.swift`) |
| Debug-only files | 2 |
