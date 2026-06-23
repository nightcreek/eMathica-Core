# Testing Strategy Status

> **Date:** 2026-06-16
> **Type:** Merged status report (consolidates 4 source documents)
> **Source Documents:**
> - [P0RegressionAudit.md](../../archive/consolidated-2026-06-16/P0RegressionAudit.md)
> - [M0GoldenFixtureDesign.md](../../archive/consolidated-2026-06-16/M0GoldenFixtureDesign.md)
> - [GraphQualityBaselineReport.md](../../archive/consolidated-2026-06-16/GraphQualityBaselineReport.md)
> - [SaveLoadEdgeCasesAudit.md](../../archive/consolidated-2026-06-16/SaveLoadEdgeCasesAudit.md)

---

## Current Status

### Test Infrastructure

| Layer | Framework | Coverage |
|-------|-----------|----------|
| App Target Tests | Swift Testing (`@Test`) | Plane, Space, CoreHome, DocumentSystem, WorkspaceKit integration |
| Package Tests | Swift Testing | MathCore unit tests (CAS, Evaluation, Graph, Sampling, etc.) |
| UI Tests | XCTest UI | Launch smoke test |
| Golden Fixtures | Planned (M0 design complete) | Not yet implemented |

### Test File Inventory

**App Target (eMathicaTests/):** 46 Swift test files covering:
- Plane: Tooling, HitTest, Intersection, Sampling, Semantic, Naming, SaveLoad, GeometryDependency, UI Polish, Compact Layout, Construction, Function Preview, etc.
- Space: Tooling, Inspector, HitTest, Document, Canvas
- CoreHome: ProjectPreview, ThumbnailLoading, ObjectPanelLayout
- MathCore: CASCore, ConditionEvaluator, EvaluationCore, GraphCore, SamplingCore (duplicated with Package tests)
- Other: AlgebraObjectPanelLayout, QuadraticFormExtractor, SessionUndoRedo, etc.

**Package (EMathicaMathCoreTests/):** 9 test files covering:
- CASCore, ConditionEvaluator, EquationSolver, EvaluationCore, ExprSerializer, GraphCore, MathFunctionString, PolynomialExpander, SamplingCore, SpaceMathCore

**Duplicate test files (5):** CASCoreTests, ConditionEvaluatorTests, EvaluationCoreTests, GraphCoreTests, SamplingCoreTests — App version for integration testing, Package version for unit testing. Reasonable layering.

---

## Key Findings

### P0 Regression Audit (2026-06-08)

| Issue | Result |
|-------|--------|
| Arc second-point line rendering | ✅ Fix correct. Code analysis confirms `constructionPreview = nil` for all arc build steps |
| Function naming not sequential | ✅ Code correct. Fix in `nextFunctionName` extracts max numeric index. Stale build cache suspected |
| Second derivative naming `f_1(x)''(x)` | 🔴 Bug found. `baseName` retains `(x)` suffix |
| Derivative occupies ordinary number | 🔴 Root cause found. Path 1 counts all `.function` objects |

### Graph Quality Baseline (2026-06-07)

Graph rendering pipeline verified:
- **GraphClassifier:** Recognizes 8 function forms (explicit, implicit, parametric, polar, conic, piecewise, segment, primitive)
- **Sampling:** 7 sampler types implemented (ExplicitFunction, GraphIntent, ParametricCurve, ImplicitCurve, PolarCurve, Piecewise, Primitive)
- **Discontinuity detection:** `maxAbsCoordinate = 1.0e12` guard, `discontinuityThreshold = 1000`
- **Build:** ✅ Passes. Tests: ✅ Passes.

### Save/Load Edge Cases (2026-06-08)

Save/load pipeline verified end-to-end:
- Package structure: `metadata.json` + `document.json` + `preview.png`
- Preview generation: Off-screen render via `ProjectPreviewRenderer`
- Thumbnail loading: Async decode with caching in `ProjectThumbnailView`
- Geometry dependency save/load: `geometryDependency` + `geometryDefinitionStatus` serialized correctly
- **Identified gaps:** No save/load roundtrip tests for large projects; no package edge case tests

### M0 Golden Fixture Design

Fixture design complete (not yet implemented):

```
Tests/GoldenFixtures/
├── Plane/
│   ├── 2D_BasicGeometry/
│   ├── 2D_ConstructionDependency/
│   ├── 2D_Transform/
│   ├── 2D_Conic/
│   ├── FunctionCAS/
│   ├── DynamicGeometry/
│   ├── ObjectPanelAlgebraEdit/
│   └── UI_CompactAndGlass/
├── SaveLoad/
│   ├── EmptyProject/
│   ├── FunctionMetadata/
│   ├── GeometryDependency/
│   ├── PreviewThumbnail/
│   ├── LargeProject/
│   └── PackageEdgeCases/
└── Space/
    └── 3D_Primitives/
```

Each fixture should cover the full cycle: create → preview → commit → edit → drag → delete → save → reopen → thumbnail.

---

## Known Issues

| Issue | Priority | Status |
|-------|----------|--------|
| 11 `PlaneGeometryDependencyTests` failures (stub resolver) | P1 | Known root cause |
| No save/load roundtrip tests for large projects | P2 | Needs test implementation |
| No package edge case tests | P2 | Needs test implementation |
| Golden fixtures not yet created (design only) | P2 | Design complete, implementation deferred |
| `xcodebuild` sandbox permission issues on macOS | P3 | Local environment issue |

---

## Deferred Cleanup

| Item | Target |
|------|--------|
| Create M0 Golden Fixture data files | Plane v1.0 |
| Implement large project save/load roundtrip tests | Plane v1.0 |
| Implement package edge case tests | Plane v1.0 |
| Consider delegating App Target MathCore tests to Package tests | Post-v1.0 |

---

## Next Actions

1. Fix 11 `PlaneGeometryDependencyTests` failures (use real resolver, not stubs)
2. Create initial M0 Golden Fixture files for `2D_BasicGeometry` and `FunctionCAS`
3. Implement save/load edge case tests (large projects, package corruption)
4. Add graph quality visual regression tests
