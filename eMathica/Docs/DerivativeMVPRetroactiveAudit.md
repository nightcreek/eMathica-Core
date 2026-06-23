# Derivative MVP Retroactive Architecture Audit

> **Date:** 2026-06-07  
> **Scope:** Read-only audit of already-implemented Derivative MVP.  
> **Principle:** Reusable math must live in MathCore. Plane only wraps UI.

---

## 1. MathCore Existing Structure

### 1.1 Module Map

| Module | Location | Role |
|--------|----------|------|
| **Expr (AST)** | `SemanticCore/Expr.swift` | Canonical semantic AST. `indirect enum` with ~25 cases including integer, real, symbol, add, multiply, power, divide, function, piecewise, etc. |
| **Simplifier** | `CASCore/ExpressionSimplifier.swift` | `simplify(Expr) -> Expr`. Reduce arithmetic, flatten nested adds/multiplies. |
| **Normalizer** | `CASCore/ExpressionNormalizer.swift` | `normalize(Expr) -> Expr`. Canonical form transformations. |
| **Canonicalizer** | `CASCore/Canonicalizer.swift` | `canonicalize(Expr) -> CanonicalExpr`. Deep structural canonicalization for CAS comparison. |
| **Evaluator** | `EvaluationCore/ExprEvaluator.swift` | `evaluate(Expr, environment:) -> EvaluationResult`. Numeric evaluation with variable binding. |
| **GraphIntent** | `GraphCore/GraphIntent.swift` | `enum GraphIntent` with cases for explicitY, parametric2D, polar, implicit, conic, piecewise. Classification of expression shapes for graphing. |
| **AlgebraExpression** | `AlgebraCore/AlgebraExpression.swift` | Simpler AST for LaTeX parsing input. `indirect enum` with 7 cases. Used by PlaneExpressionService. |
| **Arithmetic *AlgebraAnalysisResult** | `AlgebraCore/AlgebraAnalysisResult.swift` | Result of `AlgebraCore.analyzePlaneLatex`. Contains `relation: AlgebraRelation`, classification, plot strategy, diagnostics. |

### 1.2 AlgebraExpression vs Expr

| | AlgebraExpression | Expr |
|---|---|---|
| Purpose | LaTeX parser output | Semantic CAS AST |
| Cases | 7 (number, symbol, add, multiply, divide, power, function) | ~25 (includes piecewise, tuple, vector, matrix, equation, relation, assignment, etc.) |
| Function representation | `function(String, AlgebraExpression)` — string name | `function(MathFunction, [Expr])` — typed enum |
| Where used | PlaneExpressionService, AlgebraCore | GraphIntent, Evaluator, Simplifier, CASCore |

### 1.3 SymbolicDifferentiator Placement — Verdict

**✅ Correct.** `SemanticCore/SymbolicDifferentiator.swift` depends only on Foundation. No imports of Plane, WorkspaceKit, DocumentKit, AlgebraCore, or any other module. It operates purely on `Expr`/`MathFunction`/`Symbol` — all MathCore types. This is a pure MathCore capability and is architecturally clean.

---

## 2. SymbolicDifferentiator Architecture

### 2.1 Purity

| Check | Result |
|-------|--------|
| Depends on Plane? | ✅ No |
| Depends on WorkspaceKit? | ✅ No |
| Depends on DocumentKit? | ✅ No |
| Depends on AlgebraCore? | ✅ No |
| Imports only Foundation? | ✅ Yes |

### 2.2 API Generality

```swift
public static func differentiate(_ expr: Expr, withRespectTo variable: Symbol) -> Expr?
```

- Input: `Expr` + `Symbol` — both MathCore types ✅
- Output: `Expr?` — nil on unsupported ✅
- No side effects ✅
- Thread-safe (pure function) ✅

Future Space/Data/Notes modules can call this directly. No Plane-specific coupling.

### 2.3 Return Type: `Expr?` vs `Result<Expr, DerivativeError>`

**Current**: Returns `nil` for unsupported expressions.  
**Assessment**: 🟡 Acceptable for MVP. `nil` is ambiguous — does it mean "I don't support this" or "the derivative is 0"? Currently it means "unsupported." For production, a `Result` type with diagnostic messages would be better: the user should know WHY differentiation failed.

**Recommendation**: Convert to `Result<Expr, DerivativeDiagnostic>` in a future iteration.

### 2.4 Function Support Matrix

| Function | Supported | Derivative | Notes |
|----------|-----------|------------|-------|
| sin | ✅ | cos(u)·u' | |
| cos | ✅ | -sin(u)·u' | |
| tan | ✅ | sec²(u)·u' | |
| exp | ✅ | exp(u)·u' | |
| ln | ✅ | u'/u | |
| lg | ✅ | u'/(u·ln(10)) | |
| log | ✅ | u'/u | Equivalent to ln |
| sqrt | ✅ | u'/(2·sqrt(u)) | |
| asin | ✅ | u'/√(1-u²) | |
| acos | ✅ | -u'/√(1-u²) | |
| atan | ✅ | u'/(1+u²) | |
| sinh | ✅ | cosh(u)·u' | |
| cosh | ✅ | sinh(u)·u' | |
| tanh | ✅ | sech²(u)·u' | |
| logBase | ✅ | u'/(u·ln(b)) | Requires 2 args |
| abs | ❌ | nil | Not differentiable |
| floor/ceil | ❌ | nil | Step functions |
| min/max | ❌ | nil | Not differentiable |
| custom | ❌ | nil | Unknown function |

**Verdict**: ✅ Coverage is solid for standard calculus. The nil return for non-differentiable functions is correct behavior.

### 2.5 Mathematical Edge Cases

| Case | Handling | Assessment |
|------|----------|------------|
| Power rule with variable exponent | Rewrites `u^v` as `exp(v·ln(u))` and differentiates | ✅ Correct but creates large expressions |
| Quotient rule | Standard `(u'v - uv') / v²` | ✅ Correct |
| Chain rule (nested functions) | Recursive `differentiate(arg)` call | ✅ Correct |
| log vs logBase ambiguity | `log` treated as `ln` (natural log) | ⚠️ Different from standard math notation where `log` = `log₁₀` |
| `log` in MathFunction is natural log based on MathCore convention | Duplicate of `ln` | ⚠️ See §4 |

---

## 3. AlgebraExpression.toExpr() Audit

### 3.1 Why It Exists

The Plane pipeline:
1. User enters LaTeX → `AlgebraLatexParser` → `AlgebraExpression`
2. `AlgebraCore.analyzePlaneLatex` → `AlgebraAnalysisResult`
3. `AlgebraAnalysisResult.relation` contains `AlgebraExpression`
4. SymbolicDifferentiator works on `Expr` (semantic AST), not `AlgebraExpression`

The bridge `AlgebraExpression.toExpr()` converts the parser output into the semantic AST so the differentiator can process it.

### 3.2 Bridge or Permanent API?

**Assessment**: 🟡 Temporary bridge. The two AST systems (AlgebraExpression for parsing, Expr for CAS) are redundant in the long term. The ideal architecture would parse directly into `Expr`. Until then, `toExpr()` is a necessary adapter.

### 3.3 Round-Trip Risk

```
LaTeX → AlgebraExpression → toExpr() → Expr → SymbolicDifferentiator → Expr
  → ExprDebugPrinter.print() → String → PlaneExpressionService.buildExpression
  → AlgebraLatexParser → AlgebraExpression → AlgebraAnalysisResult → MathExpression
```

This is a **5-step round trip**: Expr → String → LaTeX Parser → AlgebraExpression → MathExpression. Each step risks:
- Information loss (Expr is richer than AlgebraExpression)
- Parsing errors (debug printer output may not be valid LaTeX)
- Performance waste

**Severity**: 🟡 Medium. Works for simple expressions (`x^2`, `sin(x)`). May fail for exotic Expr forms that `ExprDebugPrinter` doesn't serialize correctly or that the LaTeX parser can't re-parse.

### 3.4 Naming

`toExpr()` is ambiguous — `Expr` is also a type for "expression" generically.  
**Recommendation**: Rename to `toSemanticExpr()` or document as `/// Converts AlgebraExpression (parser AST) → Expr (semantic AST)`.

### 3.5 Single-Source AST Principle

**⚠️ Violation**: The bridge creates a second code path from the parser to the semantic AST. The `AlgebraCore.analyzePlaneLatex` already produces an `AlgebraAnalysisResult` with classification — it should ideally produce the `Expr` representation directly. The bridge is a workaround for this gap.

**Not blocking for MVP**, but should be resolved when the parser is unified.

---

## 4. MathFunction(string) Constructor

### 4.1 Location

Defined in `AlgebraCore/AlgebraExpression.swift` (line 68), not in `SemanticCore/MathFunction.swift`.

**Assessment**: 🟡 Misplaced. `MathFunction` is defined in `SemanticCore/MathFunction.swift`. The string constructor should live there (as an extension or as part of the type), not in AlgebraCore. This creates a hidden dependency: anyone importing `AlgebraExpression` gets a `MathFunction` constructor they didn't expect.

### 4.2 String Matching

```swift
init?(_ name: String) {
    switch name.lowercased() {
    case "sin": self = .sin
    ...
    default: return nil
    }
}
```

**Assessment**: 🟢 Correct behavior. Returns nil for unknown functions. Uses lowercase normalization. The mapping is explicit and exhaustive.

**Risk**: 🟡 `"log"` maps to `.log` (natural log in MathCore convention), not `.lg` (log₁₀). This is consistent with MathCore's convention but differs from standard mathematical notation.

### 4.3 Type Safety

The `failable init?` is correct — unknown strings return nil. No silent fallback. No risk of typos creating garbage functions.

**Verdict**: ✅ Safe. Move to `MathFunction.swift`.

---

## 5. Plane Function Object Pipeline

### 5.1 How Functions Store Expression Data

```
MathObject (type: .function)
  └── expression: MathExpression
        ├── displayText: String          ("f(x) = x²")
        ├── sourceExpression: String     (user's typed input)
        ├── computeExpression: String    (for CAS evaluation)
        ├── algebraAnalysis: AlgebraAnalysisResult?
        │     ├── relation: AlgebraRelation
        │     │     ├── .expression(AlgebraExpression)  // implicit y = ...
        │     │     └── .equation(AlgebraEquation)      // y = RHS
        │     ├── classification: AlgebraClassification
        │     └── plotStrategy: PlotStrategyKind?
        ├── semanticGraphKind: SemanticGraphKind?  (.explicitY, .polar, etc.)
        └── semanticParameterSymbol: Symbol?
```

### 5.2 handleCreateDerivative Flow

```
1. Decode payload → objectID
2. Find sourceObject by ID → verify type == .function
3. sourceObject.expression.algebraAnalysis?.relation
4. Extract AlgebraExpression (RHS of equation or expression)
5. AlgebraExpression.toExpr() → Expr
6. SymbolicDifferentiator.differentiate(expr, x) → Expr?
7. ExpressionSimplifier.simplify(derivative) → Expr
8. ExpressionNormalizer.normalize(simplified) → Expr
9. ExprDebugPrinter().print(normalized) → String
10. "y=\(infixStr)" → PlaneExpressionService.buildExpression → MathExpression
11. Create MathObject(name: "f'(x)", type: .function, expression: derivExpression)
```

### 5.3 Pipeline Assessment

| Step | Assessment |
|------|------------|
| 1-4 (Extract) | ✅ Clean — uses existing algebra analysis |
| 5 (toExpr) | 🟡 Bridge — see §3 |
| 6 (Differentiate) | ✅ Clean — pure MathCore |
| 7-8 (Simplify/Normalize) | ✅ Clean — pure MathCore |
| 9 (DebugPrinter) | 🔴 Problematic — see §5.4 |
| 10 (Re-parse) | 🟡 Wasteful — see §3.3 |
| 11 (Create) | ✅ Clean — standard MathObject creation |

### 5.4 ExprDebugPrinter as Source Serializer

**🔴 Architectural Issue**: `ExprDebugPrinter` is a DEBUG tool. It's not a production-grade serializer.

The `print()` function produces human-readable but not guaranteed-parseable output. Using it as the source serializer for a derivative function means:
- The derivative's `sourceExpression` is debug output, not user input
- Re-editing the derivative function may produce different results
- Future changes to the debug printer format would silently change derivative behavior

**Fix**: Use a dedicated `ExprSerializer` (or `ExprInfixSerializer`) that produces guaranteed-parseable output. This should live in `SemanticCore/` or `CASCore/`, not in the debug module.

### 5.5 Save/Reopen/Re-edit

**Save**: ✅ Derivative is a standard MathObject with type `.function`. Saved via DocumentCommand.addObject. Persisted in .emathica format.

**Reopen**: ✅ MathObject decoded from JSON. expression.algebraAnalysis will be nil initially (no analysis stored). On first render, the sampler may re-analyze via `AlgebraCore.analyzePlaneLatex(sourceExpression)`.

**Re-edit**: 🟡 The `sourceExpression` is debug printer output. If the user edits the derivative formula, the editor will show the debug string, not a clean formula. This may confuse the user.

---

## 6. Responsibility Boundaries

### 6.1 Current Assignment

| Layer | Responsibility | Current Files | Clean? |
|-------|---------------|---------------|--------|
| **MathCore** | Symbolic differentiation, simplification, normalization | `SymbolicDifferentiator.swift`, `ExpressionSimplifier.swift`, `ExpressionNormalizer.swift`, `AlgebraExpression.toExpr()` | ✅ Pure |
| **DocumentKit** | MathObject persistence | `MathObject.swift`, `MathExpression.swift` | ✅ Pure |
| **WorkspaceKit** | WorkspaceCommand infrastructure, ModuleCommandHandler protocol | `WorkspaceCommand.swift`, `ModuleCommandHandler.swift` | ✅ No derivative-specific code |
| **Plane** | Entry point, object creation, naming | `PlaneCommandHandler.handleCreateDerivative` | ✅ Only UI wrapping |

### 6.2 Leakage Check

| Leak | Status |
|------|--------|
| Derivative math in Plane? | ✅ No — all in MathCore |
| CAS rewrite in Plane? | ✅ No |
| Expression logic in Plane? | 🟡 `ExprDebugPrinter().print()` is NOT expression logic, but is a serializer in the debug module used in production |
| Plane-specific types in MathCore? | ✅ No |

### 6.3 Verdict

**✅ Architecture is clean.** The only architectural issue is `ExprDebugPrinter` being used as a production serializer, and `AlgebraExpression.toExpr()` being a temporary bridge.

---

## 7. Command Entry Point Audit

### 7.1 Current: `moduleSpecific(id: "plane.createDerivative", payload: objectID)`

| Criterion | Assessment |
|-----------|------------|
| Works for MVP? | ✅ Yes |
| Decoupled from WorkspaceKit? | ✅ Yes — moduleSpecific is generic |
| Reusable by Space? | 🟡 Needs a Space-specific handler for 3D functions |
| Reusable by Notes? | ✅ Can reuse the same MathCore pipeline |

### 7.2 Future: Generic `WorkspaceCommand.createDerivedObject`

A general pattern would be:

```swift
case createDerivedObject(
    sourceID: UUID,
    derivationKind: DerivationKind  // .derivative, .integral, .inverse, etc.
)
```

This would allow any module to trigger derivative/integral creation without knowing the specifics. The `ModuleCommandHandler` would handle the UI wrapping (naming, styling, etc.).

**Recommendation**: Keep `moduleSpecific` for MVP. Abstract to a generic command when a second module (Space) needs derivative support.

### 7.3 UI Entry Point

| Location | Suitability |
|----------|-------------|
| ObjectPanel | ✅ Best — context menu on function objects |
| Inspector | 🟡 Secondary — less discoverable |
| ContextMenu | ✅ Good — right-click on function |
| Toolbar | 🟡 Too prominent for a single operation |

**Recommendation**: Add "求导" to the ObjectPanel's context menu (where "编辑表达式" and "删除" already live). This is the natural place for per-object actions.

---

## 8. Test Audit

### 8.1 Covered (20 tests)

| Category | Tests |
|----------|-------|
| Basic rules | constant, variable, sum, difference |
| Power rule | x², x³, constant^constant |
| Product rule | x·x |
| Quotient rule | 1/x |
| Trig | sin(x), cos(x), tan(x) |
| Chain rule | sin(x²) |
| Exp/Log | exp(x), ln(x) |
| Sqrt | sqrt(x) |
| Negate | -x |
| Unsupported | abs(x), piecewise |

### 8.2 Missing

| # | Test | Priority |
|---|------|----------|
| 1 | `AlgebraExpression.toExpr()` conversion tests | 🔴 P0 |
| 2 | `MathFunction(string)` known functions (all 18) | 🔴 P0 |
| 3 | `MathFunction(string)` unknown function returns nil | 🔴 P0 |
| 4 | Plane `createDerivative` command (integration test) | 🟡 P1 |
| 5 | Derivative source reparse round-trip (`DebugPrinter → Parser → Expr`) | 🟡 P1 |
| 6 | `handleCreateDerivative` with non-function object → error toast | 🟡 P1 |
| 7 | `handleCreateDerivative` with missing algebraAnalysis → error toast | 🟡 P1 |
| 8 | LogBase derivative with 2 args | 🟡 P1 |
| 9 | Arctrig derivatives (asin, acos, atan) | 🟢 P2 |
| 10 | Hyperbolic derivatives (sinh, cosh, tanh) | 🟢 P2 |
| 11 | Power rule with variable exponent | 🟢 P2 |
| 12 | Derivative of `(x²+1)/x` full round trip | 🟡 P1 |

---

## 9. Risk Assessment

### 🔴 High Risk (0 issues)

None. The architecture does not have critical flaws.

### 🟡 Medium Risk (4 issues)

| # | Risk | Reason | Fix Now? | Fix |
|---|------|--------|----------|-----|
| R1 | **ExprDebugPrinter as serializer** | Debug tool used in production derivative pipeline. Output format not guaranteed stable. | Yes — before shipping | Replace with dedicated `ExprSerializer` in SemanticCore/CASCore |
| R2 | **AlgebraExpression.toExpr() bridge** | Two-AST dance: LaTeX→AlgebraExpr→Expr→print→LaTeX→AlgebraExpr. Redundant and fragile. | No — MVP acceptable | Document as temporary. Plan parser unification. |
| R3 | **MathFunction(string) location** | Constructor in AlgebraCore, type in SemanticCore. Cross-module hidden dependency. | Yes — before shipping | Move to MathFunction.swift |
| R4 | **log ambiguity** | `.log` is natural log in MathCore but log₁₀ in standard math. Differentiator treats them identically. | No — document | Document convention. Add `log10` alias if needed. |

### 🟢 Low Risk (3 issues)

| # | Risk | Reason |
|---|------|--------|
| R5 | `toExpr()` naming ambiguous | `Expr` could mean "expression" generically |
| R6 | No integration test for Plane createDerivative | Unit tests pass, but full flow untested |
| R7 | `lg` and `log` both map to natural log in MathFunction | Redundant aliases |

---

## 10. Next Round Minimum Fix Tasks

### Task 1: Rename and Document `AlgebraExpression.toExpr()`

```diff
- public func toExpr() -> Expr {
+ /// Converts AlgebraExpression (parser AST) → Expr (semantic CAS AST).
+ /// This is a temporary bridge. Long-term: parser should produce Expr directly.
+ public func toSemanticExpr() -> Expr {
```

Update call site in `PlaneCommandHandler.swift`.

### Task 2: Move `MathFunction(string)` to `MathFunction.swift`

Move the `init?(_ name: String)` from `AlgebraCore/AlgebraExpression.swift` to `SemanticCore/MathFunction.swift` as a public extension. Add documentation about the `log` convention.

### Task 3: Replace `ExprDebugPrinter` with Production Serializer

Add `ExprSerializer` in `CASCore/` or `SemanticCore/` that produces guaranteed-parseable output. Replace the `ExprDebugPrinter().print()` call in `handleCreateDerivative` with this serializer.

### Task 4: Add Missing Tests

- `AlgebraExpression.toSemanticExpr()` conversion tests (5 basic cases)
- `MathFunction(string)` known/unknown tests (3 cases)
- Plane `createDerivative` error handling tests (non-function, missing analysis)

### Tasks NOT for this round:
- NO higher-order derivatives
- NO implicit differentiation
- NO parametric curve differentiation
- NO Equation Solving
- NO Expr → LaTeX round-trip without parser

---

## Appendix: File Inventory Summary

| File | Status | Action Needed |
|------|--------|---------------|
| `SemanticCore/SymbolicDifferentiator.swift` | ✅ Clean | None |
| `AlgebraCore/AlgebraExpression.swift` (toExpr) | 🟡 Bridge | Rename, document |
| `AlgebraCore/AlgebraExpression.swift` (MathFunction init) | 🟡 Misplaced | Move to MathFunction.swift |
| `Plane/Commands/PlaneCommandHandler.swift` (handleCreateDerivative) | 🟡 Uses DebugPrinter | Replace serializer |
| `Tests/.../SymbolicDifferentiatorTests.swift` | 🟡 Incomplete | Add missing tests |
