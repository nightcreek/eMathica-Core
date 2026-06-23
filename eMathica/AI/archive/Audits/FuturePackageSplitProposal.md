# Future Package Split Proposal

> **日期:** 2026-06-16
> **原则:** Package 按能力拆分，不按 UI 层级拆分
> **触发条件:** Plane v1.0 稳定后

---

## 1. Current vs Future

### Current (5 packages)

```
Packages/
├── EMathicaMathCore/          (73 files — monolithic)
├── EMathicaDocumentKit/       (12 files — partially duplicated)
├── EMathicaWorkspaceKit/      (68 files — Input/Inspector/Selection embedded)
├── EMathicaThemeKit/          (10 files — well-scoped)
└── EMathicaMathInputKit/      (8 files — external, not adopted)
```

### Future (15-19 packages)

```
Packages/
│
├── Core Math Layer
│   ├── EMathicaMathCore/              ← Expr, Symbol, Relation, Matrix, Piecewise
│   ├── EMathicaCASCore/               ← normalize, simplify, canonicalize, expand, differentiate, solve, extract
│   ├── EMathicaGraphIntentCore/       ← classify explicit/implicit/parametric/polar/conic/piecewise/3D
│   ├── EMathicaSamplingCore/          ← all samplers, stitch, discontinuity, quality profiles
│   └── EMathicaGeometryCore/          ← 2D/3D geometry, intersection, distance, projection, transform, conversion
│
├── Object & Dependency Layer
│   ├── EMathicaObjectKit/             ← object identity, kind, naming, style, serialization, conversion
│   ├── EMathicaDependencyKit/         ← edge create, resolve, recompute, cycle detect, delete policy, orphan recover
│   └── EMathicaDocumentKit/           ← document metadata, CRUD, save/load, codec, trans.json, version migration
│
├── Input & Rendering Layer
│   ├── EMathicaMathInputKit/          ← edit session, AST build, keyboard layout/keys/action, LaTeX parse/format, semantic lower, diagnostic
│   ├── EMathicaFormulaRenderKit/      ← LaTeX render, formula label/inline/thumbnail, fallback, baseline measure, cache
│   └── EMathicaPreviewKit/            ← draft preview, object preview, project preview, thumbnail, cache
│
├── UI Layer
│   ├── EMathicaThemeKit/              ← MathStyle, color token, glass style, app theme
│   ├── EMathicaWorkspaceKit/          ← workspace shell, module provider, canvas integration, tool system, command routing, object panel
│   ├── EMathicaSelectionKit/          ← hit test, handle test, single/multi selection
│   └── EMathicaInspectorKit/          ← inspector sections, property/style editors, object/module-specific inspectors
│
├── Extension Layer
│   ├── EMathicaExportKit/             ← PNG, SVG, PDF, GIF, video, notebook, package export
│   ├── EMathicaAnimationKit/          ← parameter animation, timeline, keyframe, object, construction playback
│   ├── EMathicaAssetKit/              ← image/audio/plugin asset storage, reference, cache
│   └── EMathicaPluginKit/             ← manifest, protocol, capability exposure, block compose, safety policy, permission
│
└── (Per-calculator stay in App Target)
```

---

## 2. Dependency Direction

```
Layer 0 (zero-dependency):
  EMathicaMathCore

Layer 1 (depends on Layer 0):
  EMathicaCASCore          → EMathicaMathCore
  EMathicaGraphIntentCore  → EMathicaMathCore
  EMathicaSamplingCore     → EMathicaMathCore + EMathicaGraphIntentCore
  EMathicaGeometryCore     → EMathicaMathCore

Layer 2 (depends on Layer 0-1):
  EMathicaObjectKit        → EMathicaMathCore + EMathicaGeometryCore
  EMathicaDependencyKit    → EMathicaObjectKit
  EMathicaDocumentKit      → EMathicaObjectKit + EMathicaDependencyKit + EMathicaMathCore

Layer 3 (depends on Layer 0-2):
  EMathicaMathInputKit     → EMathicaMathCore
  EMathicaFormulaRenderKit → EMathicaMathCore
  EMathicaPreviewKit       → EMathicaMathCore + EMathicaObjectKit
  EMathicaThemeKit         → (zero-dependency)

Layer 4 (depends on Layer 0-3):
  EMathicaWorkspaceKit     → EMathicaDocumentKit + EMathicaThemeKit + EMathicaMathInputKit + EMathicaObjectKit + EMathicaDependencyKit
  EMathicaSelectionKit     → EMathicaObjectKit
  EMathicaInspectorKit     → EMathicaObjectKit + EMathicaThemeKit

Layer 5 (depends on Layer 0-4):
  EMathicaPluginKit        → EMathicaWorkspaceKit + EMathicaObjectKit + EMathicaDocumentKit
  EMathicaAnimationKit     → EMathicaObjectKit
  EMathicaExportKit        → EMathicaDocumentKit + EMathicaPreviewKit
  EMathicaAssetKit         → EMathicaDocumentKit

App Target (Calculator Modules):
  Plane → all above
  Space → all above
  CoreHome → EMathicaDocumentKit + EMathicaPreviewKit + EMathicaThemeKit
```

### Forbidden Reverse Dependencies

| From | Must NOT depend on |
|------|--------------------|
| EMathicaMathCore | Any other package |
| EMathicaCASCore | Plane/Space calculators |
| EMathicaGeometryCore | WorkspaceKit |
| EMathicaObjectKit | DocumentKit (objects don't need documents) |
| EMathicaThemeKit | Any business logic package |

---

## 3. Public API Scope per Package

### EMathicaCASCore

```swift
// Public API
public func normalize(_ expr: Expr) -> Expr
public func simplify(_ expr: Expr) -> Expr
public func canonicalize(_ expr: Expr) -> CanonicalExpr
public func expandPolynomial(_ expr: Expr) -> Expr
public func differentiate(_ expr: Expr, variable: Symbol) -> Expr
public func solveEquation(_ expr: Expr, variable: Symbol) -> [Expr]
public func extractQuadratic(_ expr: Expr) -> QuadraticInfo?
public func extractConic(_ expr: Expr) -> ConicInfo?
// Planned:
public func factor(_ expr: Expr) -> Expr
public func integrate(_ expr: Expr, variable: Symbol) -> Expr
public func limit(_ expr: Expr, variable: Symbol, at: Double) -> Expr

// Internal
// - Expression tree walking
// - Pattern matching
// - CAS rule engine
```

### EMathicaSamplingCore

```swift
// Public API
public protocol PlotSegment { ... }
public protocol Sampler2D {
    func sample(_ expr: Expr, range: ParameterRange, quality: QualityProfile) -> [PlotSegment]
}
public struct ExplicitFunctionSampler2D: Sampler2D { ... }
public struct ImplicitCurveSampler2D: Sampler2D { ... }
// ... all 7 samplers

public enum SamplingQuality: String { case draft, balanced, precise }
public func stitchSegments(_ segments: [PlotSegment]) -> [PlotSegment]

// Internal
// - Discontinuity detection
// - Adaptive refinement
```

### EMathicaGeometryCore

```swift
// Public API
public enum GeometryKind { case point, segment, line, ray, circle, arc, point3D, segment3D, line3D, plane3D }
public struct GeometryDefinition { ... }
public struct GeometryAnchor { ... }
public struct GeometryDependency { ... }
public enum GeometryDependencyKind { ... }

public protocol GeometryResolver {
    func resolve(_ dependency: GeometryDependency, in objects: [MathObject]) -> GeometryDefinitionStatus
}

public func intersection(_ a: GeometryDefinition, _ b: GeometryDefinition, index: Int) -> WorldPoint?
public func distance(_ p: WorldPoint, to segment: (WorldPoint, WorldPoint)) -> Double

// Planned:
public enum GeometryTransform { case translate, rotate, scale, reflect }
public func project(_ point3D: WorldPoint3D, ontoPlane: ...) -> WorldPoint
public func convert2DTo3D(_ point2D: WorldPoint, z: Double) -> WorldPoint3D
public func convert3DTo2D(_ point3D: WorldPoint3D) -> WorldPoint
```

### EMathicaObjectKit

```swift
// Public API
public struct MathObject: Identifiable, Hashable, Codable {
    public let id: UUID
    public var name: String
    public var type: MathObjectType
    public var expression: MathExpression?
    public var style: MathStyle
    public var geometryDefinition: GeometryDefinition?
    public var geometryDependency: GeometryDependency?
    public var geometryDefinitionStatus: GeometryDefinitionStatus?
    // ...
}

// Planned:
public protocol ObjectConverter {
    func canConvert(from: ObjectKind, to: ObjectKind) -> Bool
    func convert(_ object: MathObject, to kind: ObjectKind) -> MathObject
}
```

### EMathicaMathInputKit

```swift
// Public API
public struct FormulaEditSession { ... }
public enum FormulaEditMode { case createNew, editExisting(UUID) }
public struct DraftMathObject { ... }
public struct MathKeyboardView: View { ... }
public struct FormulaEditorView: View { ... }

// Internal
// - EditorCursorNavigator
// - FormulaDiagnosticPresenter
// - MathNodeSemanticLowering
// - InputCanonicalizer
// - SemanticIntentAdapter
```

---

## 4. Migration Phases

### Phase 1: Cleanup (Plane v1.0+)
- Remove `DocumentSystem/` duplicates of EMathicaDocumentKit types
- Remove `DocumentSystem/GeometryDefinition.swift` stale copy
- Deprecate `PlaneLegacyExplicitSampling`, unify on MathCore samplers

**Risk:** Low. Only removing duplicates that import the same types from packages.
**Build impact:** May need to update some import paths. `fileSystemSynchronizedGroups` handles file changes.

### Phase 2: MathCore Split (Post-v1.0)
- Create `EMathicaCASCore` package from MathCore/CASCore + MathCore/AlgebraCore
- Create `EMathicaGraphIntentCore` package from MathCore/GraphCore
- Create `EMathicaSamplingCore` package from MathCore/SamplingCore
- Create `EMathicaGeometryCore` package from MathCore/GeometryDefinition + Coordinate + SpaceMathCore
- Keep `EMathicaMathCore` with SemanticCore + Expr + Symbol + MathObject + MathStyle

**Risk:** Medium. Many consumers depend on `import EMathicaMathCore`. All imports must be updated.
**Build impact:** Tests in both App target and Package target must be updated.

### Phase 3: Rendering & Input Extraction (Post-v1.0)
- Create `EMathicaFormulaRenderKit` from FeatureUtilities/Preview + SharedUI + WorkspaceKit/Keyboard (render parts)
- Create `EMathicaPreviewKit` from CoreHome/Preview + Plane/Services (draft preview)
- Extract MathInputKit parts from WorkspaceKit into `EMathicaMathInputKit` package (already exists)

**Risk:** Medium. Formula rendering is used across ObjectPanel, Inspector, Draft, Keyboard. Must ensure no regressions.
**Build impact:** Multiple modules affected.

### Phase 4: Object & Dependency & Selection & Inspector (Post-v1.0)
- Create `EMathicaObjectKit` for object identity/kind/naming/style/serialization
- Create `EMathicaDependencyKit` for dependency graph operations
- Create `EMathicaSelectionKit` for hit test and selection state
- Create `EMathicaInspectorKit` for inspector UI

**Risk:** Medium-High. These extract from MathCore and WorkspaceKit, which are large files.
**Build impact:** Many consumers, extensive import updates.

### Phase 5: Extension Packages (Long-term)
- `EMathicaExportKit`, `EMathicaAnimationKit`, `EMathicaAssetKit`, `EMathicaPluginKit`

**Risk:** Low. These are new packages, not extractions.

---

## 5. Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Compile-time performance | Medium | More packages = more modules to compile. SwiftPM handles parallelism |
| Import complexity | Medium | Developers need to know which package has which type |
| Circular dependencies | Medium | Strict dependency layering enforced |
| FileSystemSynchronizedGroups autodiscovery | Low | Already proven with SharedUI/ FeatureUtilities renames |
| Package.swift dependency resolution | Medium | Need to update all Package.swift files |
| Test splitting | Low | Move test files to matching package Test targets |
| API stability | High for Post-v1.0 | All current `public` types become API commitments |

---

## 6. Adaptor / Bridge Patterns

Where types need to cross package boundaries without creating reverse dependencies:

```
App Target (PlaneCalculator)
  │
  ├── PlaneGeometryResolver (implements EMathicaGeometryCore.GeometryResolver)
  ├── PlaneHitTestService (implements EMathicaSelectionKit.HitTestService)
  └── PlaneDraftPreviewService (uses EMathicaSamplingCore + EMathicaPreviewKit)

App Target (SpaceCalculator)
  │
  ├── SpaceGeometryResolver (implements EMathicaGeometryCore.GeometryResolver)
  ├── SpaceHitTestService (implements EMathicaSelectionKit.HitTestService)
  └── SpaceWireframeRenderer (uses EMathicaGeometryCore)

CoreHome
  │
  └── ProjectPreviewRenderer (uses EMathicaPreviewKit + EMathicaSamplingCore)
```

Calculators implement protocols from packages, packages never depend on calculators.
