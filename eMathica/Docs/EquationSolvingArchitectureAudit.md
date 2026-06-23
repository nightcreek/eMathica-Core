# Equation Solving Architecture Audit

> **Date:** 2026-06-07
> **Scope:** Read-only audit — design only, no code modified.
> **Principle:** Equation Solving is a shared MathCore capability. Plane only wraps UI.

---

## 1. MathCore Existing Capabilities

### 1.1 Equation / Relation Representation

MathCore already has rich equation representation at two levels:

**SemanticCore (Expr)** — used by CAS and GraphIntent:
```swift
case equation(left: Expr, right: Expr)          // f(x) = g(x)
case relation(left: Expr, relation: RelationOperator, right: Expr)  // f(x) < g(x), etc.
case chainedRelation(expressions: [Expr], relations: [RelationOperator])  // a < b < c
```

**RelationOperator**: `.equal`, `.notEqual`, `.less`, `.lessOrEqual`, `.greater`, `.greaterOrEqual`, `.approximatelyEqual`

**AlgebraCore (AlgebraExpression)** — used by PlaneExpressionService:
```swift
enum AlgebraRelation { case expression(AlgebraExpression), case equation(AlgebraEquation) }
```

### 1.2 Existing Solving-Relevant Infrastructure

| Capability | Location | Status | Reusable? |
|-----------|----------|--------|-----------|
| **QuadraticFormExtractor** | CASCore | Extracts `Ax² + Bxy + Cy² + Dx + Ey + F` from Expr | ✅ Yes — for quadratic solving |
| **PolynomialExpander** | CASCore | Expands and normalizes 2D polynomials | ✅ Yes — pre-processing |
| **ExpressionSimplifier** | CASCore | `simplify(Expr) -> Expr` | ✅ Yes — post-processing |
| **ExpressionNormalizer** | CASCore | `normalize(Expr) -> Expr` | ✅ Yes — canonical form |
| **ExprEvaluator** | EvaluationCore | Numeric evaluation with variable substitution | ✅ Yes — numeric root finding |
| **ConditionEvaluator** | EvaluationCore | Evaluates relations (equal, less, etc.) | ✅ Yes — verify solutions |
| **SymbolicDifferentiator** | SemanticCore | `differentiate(Expr, variable) -> Expr?` | 🟡 Indirect — Newton's method |
| **ExprSerializer** | SemanticCore | Serialize Expr to parseable string | ✅ Yes — display solutions |
| **PlaneIntersectionSolver** | Plane | Line/line, line/circle, circle/circle intersections | 🟡 Geometric only, not symbolic |

### 1.3 What Does NOT Exist

| Missing | Needed For |
|---------|------------|
| **Symbolic equation solver** | Solving `ax + b = 0`, `ax² + bx + c = 0` exactly |
| **Numeric root finder** | Newton-Raphson, bisection for generic `f(x) = 0` |
| **Solution data model** | Structured result type with exact/numeric/no-solution variants |
| **Polynomial discriminant** | Quadratic formula needs `b² - 4ac` |
| **Solve diagnostics** | Why a solve failed |

---

## 2. Recommended Layer Assignment

### 2.1 MathCore Responsibilities

```
EMathicaMathCore/
├── SemanticCore/
│   └── EquationSolver.swift          ← NEW: symbolic + numeric solver
├── CASCore/
│   ├── ExpressionSimplifier.swift     ← reuse: simplify before/after solve
│   ├── ExpressionNormalizer.swift     ← reuse: canonical form
│   └── QuadraticFormExtractor.swift   ← reuse: extract quadratic coefficients
├── EvaluationCore/
│   └── ExprEvaluator.swift            ← reuse: numeric evaluation for Newton/bisection
```

**MathCore provides**:
- `EquationSolver.solve(equation:variable:) -> EquationSolutionSet`
- `EquationSolver.solveLinear(expr:variable:) -> EquationSolution?`
- `EquationSolver.solveQuadratic(expr:variable:) -> EquationSolutionSet`
- `EquationSolver.findRoots(expr:variable:range:) -> [Double]` (numeric fallback)

**MathCore does NOT provide**:
- Object creation (DocumentKit's job)
- UI commands (Plane's job)
- Graph intent mapping (already exists in GraphCore)

### 2.2 DocumentKit Responsibility

- `MathObject(type: .point, position: WorldPoint(...))` for root points
- `GeometryDependencyKind` for "root of function" dependency (future)
- Persistence of root point objects

### 2.3 WorkspaceKit Responsibility

- `WorkspaceCommand` for root-finding operations (future generic command)
- `ModuleCommandHandler` protocol — Plane/Space modules implement

### 2.4 Plane Calculator Responsibility

- `PlaneCommandHandler` handles `moduleSpecific(id: "plane.findRoots", ...)`
- Creates `MathObject(type: .point)` at each root location
- Names root points (`f_root_1`, etc.)
- Passes function expression to MathCore solver
- UI: button/menu item → select function → find roots

---

## 3. MVP Scope

### 3.1 What to Include

| Feature | Priority | Rationale |
|---------|----------|-----------|
| **Linear equation solving** (`ax + b = 0`) | P0 | Simplest case, symbolic exact solution |
| **Quadratic equation solving** (`ax² + bx + c = 0`) | P0 | High school math baseline, discriminant formula |
| **Solve explicitY functions for y=0** | P0 | "Find x-intercepts" — most common Plane use case |
| **Numeric Newton-Raphson fallback** | P1 | For equations too complex for symbolic solve |
| **Generate root points on canvas** | P0 | Plane integration — create MathObject.point at each root |
| **Multi-solution result (array)** | P0 | Quadratic has 0, 1, or 2 real solutions |
| **Solution type tagging** (exact / numeric / approximate) | P1 | Distinguish exact vs numeric solutions |
| **No-solution / infinite-solution diagnostics** | P1 | User feedback |

### 3.2 What to Exclude from MVP

| Feature | Reason |
|---------|--------|
| Cubic/quartic solving | Complexity; defer to numeric |
| Systems of equations | Requires matrix/List infrastructure |
| Inequalities | Requires region shading |
| Complex solutions | Plane is real-valued canvas |
| Parametric equation roots | Defer |
| Implicit equation roots | Defer (needs contour tracing) |
| Step-by-step solution display | Educational feature, not MVP |
| Equation rewriting/simplification before solve | Use existing simplifier |

---

## 4. Result Type Design

### 4.1 Recommended Types (in MathCore/SemanticCore/)

```swift
/// The complete result of an equation solving attempt.
public struct EquationSolutionSet {
    public let solutions: [EquationSolution]
    public let diagnostics: [SolveDiagnostic]
    public var hasExactSolutions: Bool
    public var hasNumericSolutions: Bool
}

/// A single solution to an equation.
public enum EquationSolution {
    /// Exact symbolic solution, e.g., x = 2, x = -b/(2a)
    case exact(value: Expr)
    /// Numeric approximation, e.g., x ≈ 1.414
    case numeric(value: Double, tolerance: Double)
    /// Parameterized solution, e.g., x = 2kπ for trig equations
    case parametric(base: Expr, parameter: Symbol, period: Expr)
}

/// Why a solve attempt produced no useful result.
public enum SolveDiagnostic {
    case noRealSolution
    case infiniteSolutions
    case unsupported(String)
    case numericDidNotConverge
    case equationNotRecognized
}
```

### 4.2 Why Not Just `[Double]`

| Problem | Solution |
|---------|----------|
| Can't distinguish exact from numeric | `EquationSolution` enum tags each |
| Can't express "no solution" vs "solve failed" | `SolveDiagnostic` captures reason |
| Can't express parameterized solutions (e.g., `x = πk`) | `parametric` case |
| Can't tell if result is `x²+1=0` (no real) vs `x²-2=0` (numeric approx) | Diagnostics |

---

## 5. List Core Dependency Analysis

### 5.1 Can MVP Work Without List Core?

✅ **Yes.** The MVP returns `[EquationSolution]` (a plain Swift array). This is a local result type, not a persistent MathList.

### 5.2 Future List Core Integration

When `MathList` / `ListValue` is implemented:
- `EquationSolutionSet.solutions` can be converted to `MathList`
- Root points on canvas are individual `MathObject.point` instances anyway
- No coupling needed at MVP stage

### 5.3 Recommendation

Use plain Swift array for MVP. Add `asMathList() -> MathList` method later when List Core exists.

---

## 6. Plane Integration Design

### 6.1 User Flow

```
1. User taps function object → selects it
2. User invokes "Find Roots" from ObjectPanel context menu
3. PlaneCommandHandler:
   a. Gets function's AlgebraAnalysis
   b. Converts to Expr (via toSemanticExpr)
   c. Sets equation: f(x) = 0
   d. Calls EquationSolver.solve(equation, x)
   e. For each solution, creates MathObject.point at (root, 0)
   f. Names points: "f_root_1", "f_root_2", etc.
4. Root points appear on canvas
   - Static points for MVP (no dependency on function)
   - Future: GeometryDependency for dynamic update
```

### 6.2 Command Entry Point

Same pattern as Derivative MVP:
```swift
moduleSpecific(id: "plane.findRoots", payload: objectID)
```

### 6.3 Point Type Decision: Static vs Dependent

**MVP**: Static points (no dependency). If the function changes, roots are NOT recomputed.

**Rationale**: Dependency on a function's roots is a graph-intersection problem, not a simple `GeometryDependency`. This requires a new dependency kind (like `rootOfFunction`) that the MVP doesn't need.

**Future**: Add `GeometryDependencyKind.rootOfFunction(functionID:index:)` for dynamic root points.

---

## 7. Relationship with Derivative MVP

### 7.1 Shared Infrastructure

| Component | Derivative | Equation Solving | Shared? |
|-----------|-----------|-----------------|---------|
| `ExprSerializer` | Serialize derivative result | Serialize solution values | ✅ Yes |
| `ExpressionSimplifier` | Post-processing | Pre/post-processing | ✅ Yes |
| `ExpressionNormalizer` | Canonical form | Canonical form | ✅ Yes |
| `toSemanticExpr()` | Bridge to Expr | Bridge to Expr | ✅ Yes |

### 7.2 Future Feature: Critical Points via Derivative + Solver

```
f'(x) = 0  →  EquationSolver.solve(f'(x) = 0, x)  →  critical points
```

This naturally composes: `SymbolicDifferentiator` → `EquationSolver` → root points.

### 7.3 Future Feature: Tangent Line via Derivative + Point

```
Tangent at x₀: y = f(x₀) + f'(x₀)(x - x₀)
```

Uses `SymbolicDifferentiator` for slope, `ExprEvaluator` for `f(x₀)`.

No new architecture needed — composition of existing MathCore capabilities.

---

## 8. Test Plan

### 8.1 MathCore Tests (`EquationSolverTests.swift`)

| # | Test | Priority |
|---|------|----------|
| 1 | `solveLinear(2x + 3 = 0, x)` → exact: x = -3/2 | P0 |
| 2 | `solveLinear(0x + 5 = 0, x)` → no solution | P0 |
| 3 | `solveLinear(0x + 0 = 0, x)` → infinite solutions | P0 |
| 4 | `solveQuadratic(x² - 4 = 0, x)` → exact: x = ±2 | P0 |
| 5 | `solveQuadratic(x² + 1 = 0, x)` → no real solution | P0 |
| 6 | `solveQuadratic(x² - 2x + 1 = 0, x)` → exact: x = 1 (double root) | P0 |
| 7 | `solveQuadratic(x² - 2 = 0, x)` → numeric: x ≈ ±1.414 | P1 |
| 8 | `solve(sin(x) = 0, x)` → unsupported diagnostic | P1 |
| 9 | Newton `findRoot(x³ - x - 2, 1...2)` → numeric | P1 |
| 10 | Newton non-convergent → diagnostic | P1 |

### 8.2 Serializer Reparse Tests

| # | Test | Priority |
|---|------|----------|
| 11 | Serialize solution `x = -3/2` → parseable by AlgebraLatexParser | P1 |
| 12 | Serialize solution `x = 2` → parseable | P1 |

### 8.3 Plane Integration Tests (Manual QA)

| # | Test | Priority |
|---|------|----------|
| 13 | Select `y = x² - 4` → Find Roots → points at (-2,0) and (2,0) | P0 |
| 14 | Select `y = x² + 1` → Find Roots → "no real solution" toast | P0 |
| 15 | Select circle → Find Roots → "unsupported" or disabled | P1 |
| 16 | Non-function object → safety check | P1 |

---

## 9. Risk Assessment

### 🔴 High Risk

None identified at audit stage.

### 🟡 Medium Risk

| # | Risk | Reason | Mitigation |
|---|------|--------|------------|
| R1 | **Numeric convergence** | Newton-Raphson may diverge for certain functions | Use bisection as safety fallback; cap iterations at 100 |
| R2 | **Quadratic discriminant near-zero** | `b² ≈ 4ac` causes floating-point instability in exact/approx decision | Threshold at 1e-9; classify as "double root" |
| R3 | **AlgebraExpression ↔ Expr bridge** | Same two-AST issue as Derivative MVP | Accept for MVP; document bridge usage |
| R4 | **Multi-root detection** | Newton finds one root at a time; must find all in range | Sample intervals and run from multiple starting points |

### 🟢 Low Risk

| # | Risk | Reason |
|---|------|--------|
| R5 | Linear with zero coefficient → special case | Simple edge case to detect |
| R6 | Equation not in standard form | Simplifier handles before solve |
| R7 | Solution display format | ExprSerializer already handles |
| R8 | Root points vs existing point names | Name collision with existing points |

---

## 10. Next Round Coding Prompt

```
IMPLEMENT: Equation Solving MVP

SCOPE:
1. Create MathCore/SemanticCore/EquationSolver.swift:
   - solveLinear(coefficients:variable:) -> EquationSolution?
   - solveQuadratic(coefficients:variable:) -> EquationSolutionSet
   - solve(expr:variable:) -> EquationSolutionSet (dispatcher)
   - findRootNewton(expr:variable:range:maxIterations:) -> Double? (P1)
   - Result types: EquationSolutionSet, EquationSolution, SolveDiagnostic

2. Plane Integration in PlaneCommandHandler:
   - Handle moduleSpecific(id: "plane.findRoots", payload: objectID)
   - For explicitY functions: set y=0, solve for x
   - Create MathObject.point at each root
   - Name: "f_root_1", "f_root_2", etc.

3. Tests:
   - EquationSolverTests: linear, quadratic, no-solution, infinite, discriminant edge cases
   - ExprSerializer re-parse tests for solution values

DO NOT:
- Solve cubic/quartic equations
- Solve systems of equations  
- Implement dynamic root dependency
- Create List/Vector/MathList types
- Change Derivative or Arc tool code
```

---

## Appendix: File Placement Summary

| File | Location | Role |
|------|----------|------|
| `EquationSolver.swift` | `SemanticCore/` | Symbolic + numeric solver |
| (modified) `PlaneCommandHandler.swift` | `Plane/Commands/` | `handleFindRoots` command |
| `EquationSolverTests.swift` | `Tests/EMathicaMathCoreTests/` | Unit tests |
