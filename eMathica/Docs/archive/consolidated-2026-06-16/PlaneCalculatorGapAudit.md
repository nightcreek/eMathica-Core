# Plane Calculator Gap Audit

> **Date:** 2026-06-07
> **Benchmarks:** GeoGebra Classic 6 (Plane mode), Desmos (function graphing)
> **Scope:** Feature gap analysis — what the user can do, not how code is organized.

---

## Overall Completion Estimate

| Dimension | Completion | Confidence |
|-----------|-----------|------------|
| Geometry Objects | ~55% | High |
| Geometry Constructions | ~45% | High |
| Dynamic Geometry | ~60% | High |
| Function Graphing | ~70% | High |
| CAS / Algebra | ~30% | Medium |
| Input System | ~65% | High |
| Object Panel | ~35% | Medium |
| Export | ~25% | High |
| **Overall** | **~50%** | |

---

## 1. Geometry Objects

### 1.1 Currently Supported

| Object | MathObjectType | GeometryKind | Tool Available | Notes |
|--------|---------------|--------------|----------------|-------|
| Point | ✅ `.point` | ✅ `.point` | ✅ `plane.point` | Free + dependent (intersection, midpoint) |
| Segment | ✅ `.segment` | ✅ `.segment` | ✅ `plane.segment` | Two-point construction |
| Line | ✅ `.line` | ✅ `.line` | ✅ `plane.line` | Infinite line, two-point |
| Ray | ✅ `.ray` | ✅ `.ray` | ✅ `plane.ray` | Start + through point |
| Circle | ✅ `.circle` | ✅ `.circle` | ✅ `plane.circle` | Center + point, or center + radius |
| Function | ✅ `.function` | — | ✅ `plane.function` | Expression input, sampled for rendering |

### 1.2 Missing Objects

| Object | Status | GeoGebra Reference | Priority |
|--------|--------|-------------------|----------|
| **Arc** | ❌ Not implemented | Circular arc by 3 points or center+2 points | P1 |
| **Ellipse** | ❌ No tool | Recognized by GraphClassifier but no construction tool | P1 |
| **Parabola** | ❌ No tool | Recognized by GraphClassifier but no construction tool | P1 |
| **Hyperbola** | ❌ No tool | Recognized by GraphClassifier but no construction tool | P2 |
| **Vector** | ❌ Not implemented | Direction + magnitude from two points | P1 |
| **Polygon** | ❌ Not implemented | Closed chain of segments | P1 |
| **Regular Polygon** | ❌ Not implemented | N-sided regular polygon | P2 |
| **Locus** | ❌ Not implemented | Trace of point as parameter varies | P2 |
| **Text / Label** | ❌ Not implemented | Free-form text annotation | P2 |
| **Image** | ❌ Not implemented | Embedded image with anchoring | P2 |

---

## 2. Geometry Constructions

### 2.1 Currently Implemented

| Construction | GeometryDependencyKind | Tool | Status |
|-------------|----------------------|------|--------|
| Midpoint | ✅ `midpointOfPoints` | ✅ `plane.midpoint` | Full — recomputes on source drag |
| Intersection | ✅ `intersectionOf` | ✅ `plane.intersection` | Supports line/line, line/circle, circle/circle |
| Parallel Line | ✅ `parallelLine` | ✅ `plane.parallel` | Through point, parallel to reference |
| Perpendicular Line | ✅ `perpendicularLine` | ✅ `plane.perpendicular` | Through point, perpendicular to reference |
| Circle by Center+Point | ✅ `circleByCenterPoint` | ✅ `plane.circle` | Radius = distance between points |
| Circle by Center+Radius | ✅ `circleByCenterRadius` | — | Fixed numeric radius |

### 2.2 Missing Constructions

| Construction | Status | GeoGebra Reference | Priority |
|-------------|--------|-------------------|----------|
| **Angle Bisector** | ❌ Not implemented | Bisector of angle formed by 3 points | P1 |
| **Tangent** | ❌ Not implemented | Tangent from point to circle, or at point on curve | P1 |
| **Normal Line** | ❌ Not implemented | Perpendicular to curve at point | P2 |
| **Reflection** | ❌ Not implemented | Mirror object across line/point | P1 |
| **Rotation** | ❌ Not implemented | Rotate object around point by angle | P1 |
| **Translation** | ❌ Not implemented | Translate object by vector | P1 |
| **Dilation** | ❌ Not implemented | Scale object from center by factor | P2 |
| **Locus** | ❌ Not implemented | Trace as parameter varies | P2 |

---

## 3. Dynamic Geometry

### 3.1 Currently Implemented

| Feature | Status | Notes |
|---------|--------|-------|
| Point dragging | ✅ | `PlaneCanvasView.pointDragGesture` — Gesture recognizer for free points |
| Dependency recompute | ✅ | `PlaneGeometryDependencyRecomputeService` — Recomputes all derived objects when source changes |
| Transitive propagation | ✅ | `downstreamAffectedDerivedObjectIDs` — Walks full dependency chain |
| Cleanup on delete | ✅ | `dependencyCleanupPatchesForRemovedSources` — Clears references when source deleted |
| Undo/redo | ✅ | `WorkspaceSessionHistory` — Snapshot-based undo stack |
| Canvas pan/zoom | ✅ | Pan gesture + pinch zoom on canvas |
| Construction preview | ✅ | `PlaneConstructionPreview` — Ghost preview during tool placement |

### 3.2 Missing or Partial

| Feature | Status | Notes |
|---------|--------|-------|
| **Constraint-based dragging** | 🟡 Partial | Free points drag OK. Derived points (midpoints, intersections) are NOT draggable — they should move along their constraint curve |
| **Snap-to-grid** | ❌ | Grid is rendered but no snap behavior |
| **Snap-to-object** | ❌ | No snap to existing points/lines during construction |
| **Animation / Slider playback** | 🟡 Partial | Slider playback exists (`toggleSliderPlayback`) but no trace/locus animation |
| **Measurement display** | 🟡 Partial | Segment length, point coordinates shown in inspector but not on-canvas |
| **Conditional visibility** | 🟡 Partial | Toggle visibility exists; no conditional logic |

---

## 4. Function Graphing

### 4.1 Graph Intent Coverage (MathCore GraphClassifier)

| Form | GraphIntent Case | Status | Desmos Parity |
|------|-----------------|--------|---------------|
| **Explicit y=f(x)** | ✅ `.explicitY` | Full | ✅ Yes |
| **Explicit x=f(y)** | ✅ `.explicitX` | Full | ✅ Yes |
| **Parametric** | ✅ `.parametric2D` | Full — x(t), y(t) with range | ✅ Yes |
| **Polar** | ✅ `.polar` | Full — r(θ) with angle range | ✅ Yes |
| **Implicit** | ✅ `.implicit` | Sampled via marching squares | ✅ Yes |
| **Conic** | ✅ `.conic` | Circle, ellipse, hyperbola, parabola recognized | ✅ Yes |
| **Piecewise** | ✅ `.piecewise` | Multi-branch piecewise functions | ✅ Yes |
| **Point** | ✅ `.point` | Single (x,y) evaluation | ✅ Yes |

### 4.2 Sampling Quality

| Feature | Status |
|---------|--------|
| Adaptive sampling | ✅ `SamplingQualityProfile` (balanced, precise, draft) |
| Discontinuity detection | ✅ Sampling issues recorded (`SamplingIssue`) |
| Viewport-aware sampling | ✅ `SamplingViewport2D` |
| Implicit curve sampling | ✅ `ImplicitCurveSampler2D` |
| Segment stitching | ✅ `SegmentStitcher2D` |

### 4.3 Missing vs Desmos

| Feature | Status | Priority |
|---------|--------|----------|
| Inequality shading (y > f(x)) | ❌ | P2 |
| Domain/range restrictions on graph | ❌ | P1 |
| Table of values | ❌ | P1 |
| Slider auto-animation | 🟡 Partial | P2 |
| Regression / curve fitting | ❌ | P2 |
| Function composition visualization | ❌ | P2 |

---

## 5. CAS / Algebra

### 5.1 Currently Implemented

| Capability | Location | Status |
|-----------|----------|--------|
| Expression evaluation | `ExprEvaluator` | ✅ Numeric evaluation with variable substitution |
| Polynomial expansion | `PolynomialExpander` | ✅ 2D quadratic form expansion |
| Quadratic form extraction | `QuadraticFormExtractor` | ✅ Conic classification |
| Algebraic simplification | `AlgebraSimplifier` | ✅ Combine like terms, basic factoring |
| Expression normalization | `ExpressionNormalizer` | ✅ Canonical form |
| Canonicalization | `Canonicalizer` | ✅ Deep structural canonicalization |
| LaTeX parsing | `AlgebraLatexLexer` + `Parser` | ✅ Parse LaTeX to algebra expression |
| Conic recognition | `PlaneAlgebraClassifier` | ✅ Circle/ellipse/hyperbola/parabola |
| Trigonometric evaluation | `MathFunction` | ✅ sin, cos, tan + hyperbolic |
| Logarithmic evaluation | `MathFunction` | ✅ ln, lg, log, logBase |

### 5.2 Missing

| Capability | Status | GeoGebra CAS Reference | Priority |
|-----------|--------|----------------------|----------|
| **Derivative** | ❌ | `Derivative(f)` or `f'` | P0 |
| **Integral (indefinite)** | ❌ | `Integral(f)` | P1 |
| **Integral (definite)** | ❌ | `Integral(f, a, b)` | P1 |
| **Limit** | ❌ | `Limit(f, x→a)` | P2 |
| **Equation solving** | ❌ | `Solve(f=g)` or `Roots(f)` | P0 |
| **System of equations** | ❌ | `Solve({f=g, h=k}, {x,y})` | P2 |
| **Full factorization** | 🟡 Partial | `Factor(expr)` — only simple quadratics | P1 |
| **Taylor series** | ❌ | `TaylorPolynomial(f, x0, n)` | P2 |
| **Matrix operations** | 🟡 Partial | `MatrixExpr` exists but no determinant/inverse | P2 |
| **Sum/product notation** | ❌ | Σ, Π evaluation | P2 |

---

## 6. Input System

### 6.1 Current InputKit Capabilities

| Feature | Status | Notes |
|---------|--------|-------|
| AST-based editing | ✅ | `MathNode` indirect enum |
| Template insertion | ✅ | fraction, sqrt, nthRoot, superscript, subscript, abs, parentheses, cases, matrix, piecewise, sum, integral |
| Cursor navigation | ✅ | Arrow keys, tab/shiftTab for field hopping |
| LaTeX serialization | ✅ | AST→LaTeX round trip |
| Source serialization | ✅ | AST→compute expression |
| Character normalization | ✅ | Unicode→ASCII mapping |
| Codable state | ✅ | Full JSON import/export |
| Hardware keyboard | ✅ | iOS only (UIKey capture) |
| On-screen keyboard | ✅ | `MathKeyboardView` |

### 6.2 Gaps vs GeoGebra/Desmos Input

| Feature | Status | Priority |
|---------|--------|----------|
| **Auto-complete** | ❌ | P2 |
| **Syntax highlighting** | ❌ | P2 |
| **Inline error underlining** | 🟡 Partial | P1 |
| **Touch-drag to create objects** | ✅ | Point/segment/circle via tool |
| **Voice input** | ❌ | P3 |
| **Handwriting recognition** | 🟡 Partial | ML model exists but not integrated |
| **Multi-line piecewise editing** | ✅ | `TemplateKind.piecewise` |
| **Parameter slider from expression** | ✅ | `ParameterSuggestionAnalyzer` |

---

## 7. Object Panel

### 7.1 Currently Implemented

| Feature | Status |
|---------|--------|
| Object list with icons | ✅ |
| Rename (double-tap) | ✅ |
| Toggle visibility | ✅ |
| Delete with confirmation | ✅ |
| Edit expression | ✅ |
| Convert to static (break dependency) | ✅ |
| Color presets | ✅ |
| Opacity presets | ✅ |
| Line width presets | ✅ |
| Line style presets (solid/dashed) | ✅ |
| Point size presets | ✅ |
| Diagnostic indicators | ✅ |

### 7.2 Missing

| Feature | Status | GeoGebra Reference | Priority |
|---------|--------|-------------------|----------|
| **Group/Ungroup** | ❌ | Select multiple → right-click → Group | P2 |
| **Lock / Fix Object** | ❌ | Prevent accidental move | P1 |
| **Object order (z-index)** | ❌ | Bring to front / send to back | P2 |
| **Layers** | ❌ | Assign objects to named layers | P2 |
| **Conditional visibility** | ❌ | Show if condition is true | P2 |
| **Value table display** | ❌ | Tabular view of function values | P1 |
| **Copy/paste objects** | ❌ | Cut/copy/paste between documents | P2 |
| **Search/filter objects** | ❌ | Filter list by name or type | P2 |
| **Bulk selection** | ❌ | Shift-click / drag-select multiple | P1 |

---

## 8. Export

### 8.1 Currently Implemented

| Format | Status | Notes |
|--------|--------|-------|
| **PNG** | ✅ | `ProjectPreviewRenderer.renderPNGData` — thumbnail export |
| **.emathica** | ✅ | `EMathicaPackageCodec` — full project save/load |
| **JSON (AST state)** | ✅ | `MathInputSession.exportEditorStateJSON` |

### 8.2 Missing

| Format | Status | GeoGebra Reference | Priority |
|--------|--------|-------------------|----------|
| **SVG** | ❌ | Vector export for web/print | P1 |
| **PDF** | ❌ | Print-ready vector export | P2 |
| **LaTeX / TikZ** | ❌ | LaTeX figure export for academic papers | P1 |
| **GeoGebra .ggb** | ❌ | Interoperability with GeoGebra | P2 |
| **Desmos URL** | ❌ | Shareable web link | P2 |
| **Copy to clipboard (image)** | ❌ | Quick sharing | P1 |

---

## 9. Priority Matrix

### P0 — v1 Must-Have (Blockers for Plane Calculator App)

| # | Feature | Domain | Effort |
|---|---------|--------|--------|
| P0-1 | **Derivative** (`f'(x)` evaluation) | CAS | 3d |
| P0-2 | **Equation solving** (roots, intersections symbolically) | CAS | 5d |
| P0-3 | **Arc** (circular arc tool) | Geometry | 2d |
| P0-4 | **Transform tools** (Reflect, Rotate, Translate) | Construction | 5d |

### P1 — GeoGebra Parity (Competitive Baseline)

| # | Feature | Domain | Effort |
|---|---------|--------|--------|
| P1-1 | **Vector** object | Geometry | 1d |
| P1-2 | **Polygon** object | Geometry | 2d |
| P1-3 | **Ellipse / Parabola tools** | Geometry | 2d |
| P1-4 | **Angle Bisector** | Construction | 1d |
| P1-5 | **Tangent** | Construction | 2d |
| P1-6 | **Domain/range restrictions** on graphs | Function | 2d |
| P1-7 | **Table of values** | Function | 1d |
| P1-8 | **Definite integral** | CAS | 3d |
| P1-9 | **Full factorization** | CAS | 3d |
| P1-10 | **SVG export** | Export | 2d |
| P1-11 | **LaTeX/TikZ export** | Export | 1d |
| P1-12 | **Copy to clipboard** | Export | 0.5d |
| P1-13 | **Lock/fix object** | Object Panel | 0.5d |
| P1-14 | **Bulk selection** | Object Panel | 1d |

### P2 — Power User (Differentiation)

| # | Feature | Domain |
|---|---------|--------|
| P2-1 | Hyperbola tool | Geometry |
| P2-2 | Regular polygon tool | Geometry |
| P2-3 | Locus / trace | Geometry |
| P2-4 | Normal line | Construction |
| P2-5 | Dilation | Construction |
| P2-6 | Inequality shading | Function |
| P2-7 | Regression / curve fitting | Function |
| P2-8 | Indefinite integral | CAS |
| P2-9 | Taylor series | CAS |
| P2-10 | System of equations | CAS |
| P2-11 | Matrix operations | CAS |
| P2-12 | PDF export | Export |
| P2-13 | Group / Ungroup | Object Panel |
| P2-14 | Layers | Object Panel |
| P2-15 | Conditional visibility | Object Panel |
| P2-16 | Snap-to-grid / Snap-to-object | Interaction |

---

## 10. Recommended Development Order

### Month 1: Core Completeness (P0)

```
Week 1: Derivative evaluation in CAS
        → ExprEvaluator gains d/dx support
        → Tangent line tool (uses derivative for slope)

Week 2: Equation solving in CAS
        → Solve(f(x)=g(x)) via Newton-Raphson + algebraic methods
        → Roots tool on graph

Week 3: Arc + basic transforms
        → Arc by 3 points tool
        → Reflect across line/point

Week 4: Rotate + Translate tools
        → Dependency graph extended for transform nodes
```

### Month 2: GeoGebra Parity (P1)

```
Week 5-6: Vector + Polygon + Ellipse/Parabola tools
          Angle Bisector, Tangent construction
          Domain/range restrictions on graphs

Week 7-8: Table of values, Definite integral, Full factorization
          SVG + LaTeX/TikZ export, Copy to clipboard
          Lock/fix object, Bulk selection
```

### Month 3: Polish (P1 remaining + P2 start)

```
Week 9-10: Snap-to behaviors, conditional visibility
           Locus/trace, Inequality shading
           Group/Ungroup, Layers

Week 11-12: Regression, Taylor series, Matrix operations
            PDF export, System of equations
```

---

## Appendix: Data Sources for This Audit

| Capability | Files Audited |
|-----------|---------------|
| Geometry Objects | `MathObjectType.swift`, `GeometryDefinition.swift`, `PlaneToolIDs.swift`, `PlaneToolProvider.swift` |
| Geometry Constructions | `GeometryDependencyKind` (MathObject.swift), `PlaneGeometryDependencyRecomputeService.swift`, `PlaneIntersectionSolver.swift` |
| Dynamic Geometry | `PlaneCanvasView.swift`, `PlaneInteractionState.swift`, `WorkspaceSessionHistory.swift` |
| Function Graphing | `GraphIntent.swift`, `GraphClassifier.swift`, `SamplingCore/` directory |
| CAS | `ExprEvaluator.swift`, `AlgebraSimplifier.swift`, `PolynomialExpander.swift`, `MathFunction.swift` |
| Input System | `EMathicaMathInputKit` (8 files), `FormulaEditorView.swift`, `MathKeyboardView.swift` |
| Object Panel | `WorkspaceObjectRowView.swift`, `AlgebraObjectPanelView.swift`, `MathStylePresetProvider.swift` |
| Export | `ProjectPreviewRenderer.swift`, `EMathicaPackageLayout.swift`, `MathInputSession.swift` |
