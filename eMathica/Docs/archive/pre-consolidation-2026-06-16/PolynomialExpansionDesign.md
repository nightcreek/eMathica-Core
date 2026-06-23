# PolynomialExpansionDesign

## 1. Why we need finite polynomial expansion

Current conic recognition and quadratic extraction already handle many expanded forms, but still fail on common structured inputs such as:

- `(x+1)^2`
- `(x+1)(x-1)`
- `(x-1)^2 + (y-2)^2 - 9`

These are mathematically low-risk and bounded in degree/term count, but they are not currently expanded by CASCore.

The goal is **not** full CAS expansion.  
The goal is a **controlled finite expander** that helps quadratic/conic pipelines while preserving predictable complexity.

---

## 2. Current state audit

### 2.1 ExpressionNormalizer

`ExpressionNormalizer` currently does structural normalization only:

- recursively normalizes children
- flattens nested `add` / `multiply`
- removes single-element wrappers
- recurses through equation/relation/piecewise/tuple/vector/matrix/assignment/functionDefinition
- no distributive expansion

### 2.2 ExpressionSimplifier

`ExpressionSimplifier` currently does safe simplification:

- add/multiply identity removal and integer folding
- power rules (`x^1`, `x^0`)
- double-negation elimination
- integer divide -> rational reduce/sign normalization
- recursive simplification for containers
- no polynomial distribution/expansion

### 2.3 Why QuadraticFormExtractor rejects `(x+1)^2` and `(x+1)(x-1)`

`QuadraticFormExtractor` currently expects term-level monomials and numeric coefficients.  
At term parsing level:

- `add` inside a term is rejected (`unsupportedQuadraticTerm`, message: explicit expansion required)
- it supports `power(symbol,2)`, `multiply(...)`, `divide(...)` with variable-free denominator
- it does not perform distribution

So `(x+1)^2` and `(x+1)(x-1)` fail by design.

### 2.4 GraphClassifier conic paths today

GraphClassifier currently uses a hybrid strategy:

1. **Pattern-matching paths** (strict forms):
   - origin circle / translated circle
   - standard origin/translated ellipse-hyperbola forms
2. **Quadratic-form path**:
   - builds zero-form (`left-right`)
   - calls `QuadraticFormExtractor`
   - classifies non-rotated and rotated conics from numeric coefficients

This means finite expansion would mostly improve the quadratic-form path coverage.

### 2.5 Best placement in CASCore

`PolynomialExpander` should live in:

- `MathCore/CASCore/PolynomialExpander.swift`

Reason:

- same abstraction layer as Normalizer/Simplifier/Extractor
- no GraphCore coupling
- reusable by future coefficient extraction or bounded symbolic preprocessing

---

## 3. Proposed component

## 3.1 API

```swift
public struct PolynomialExpansionOptions: Sendable {
    public var maxDegree: Int
    public var maxTermCount: Int
    public var allowedVariables: Set<Symbol>
}

public struct PolynomialExpander {
    public init(
        normalizer: ExpressionNormalizer = .init(),
        simplifier: ExpressionSimplifier = .init()
    )

    public func expand(
        _ expr: Expr,
        options: PolynomialExpansionOptions
    ) -> Result<Expr, ExprDiagnosticList>
}
```

## 3.2 Intended behavior

- Accept `Expr`, never parse from string/LaTeX.
- Expand only whitelisted algebraic patterns under strict limits.
- Return expanded `Expr` (still Semantic AST), then optional simplifier pass.
- Refuse unsupported forms with explicit diagnostics.

---

## 4. Complexity and safety limits

Recommended defaults for first implementation:

- `maxDegree = 2`
- `maxTermCount = 16`
- `allowedVariables = {x, y}`

Hard-stop rules:

- any intermediate term degree > `maxDegree` => fail
- term count > `maxTermCount` => fail
- variable outside `allowedVariables` => fail

This keeps expansion bounded and predictable.

---

## 5. Supported scope (v1)

First release should support only finite, low-risk patterns:

- `(a+b)^2`
- `(a-b)^2`
- `(x+h)^2`
- `(y+k)^2`
- `(x+a)(x+b)`
- `(x+a)(y+b)`
- numeric coefficient `*` polynomial
- add/negate composition of polynomial terms
- divide by numeric scalar

Examples expected to work:

- `(x+1)^2 -> x^2 + 2x + 1`
- `(x-1)^2 -> x^2 - 2x + 1`
- `(x+1)(x-1) -> x^2 - 1`
- `(x-1)^2 + (y-2)^2 - 9 -> expanded quadratic`

---

## 6. Unsupported scope (v1)

Explicitly reject:

- degree > 2 targets
- symbolic coefficients (`a*x`, `b*(x+y)`)
- function-bearing terms (`sin`, `log`, `sqrt`, ...)
- non-polynomial powers
- variable denominator
- uncontrolled nested expansion (term explosion)
- variables beyond x/y
- matrix/vector/piecewise expansion

---

## 7. Integration options with QuadraticFormExtractor

## 7.1 Option A (recommended)

Flow:

- GraphClassifier (or caller) decides when to try expansion
- expand first
- pass expanded expr into existing `QuadraticFormExtractor`

Pros:

- extractor remains single-purpose and predictable
- expansion is explicit and opt-in at call sites
- easier debugging and staged rollout

Cons:

- caller has to coordinate two components

## 7.2 Option B

`QuadraticFormExtractor` internally performs optional expansion (`allowExpansion`).

Pros:

- convenient single API for callers

Cons:

- extractor responsibility grows (parse + expand + extract)
- harder to reason about failure source
- larger behavioral surface for one component

## 7.3 Recommendation

Prefer **Option A** for first release:

- keep extractor strict
- keep expansion as a standalone bounded preprocessor
- wire selectively in GraphClassifier conic path after dedicated tests pass

---

## 8. Diagnostic design

Suggested diagnostic codes:

- `expansionDegreeTooHigh`
- `expansionTermLimitExceeded`
- `unsupportedPolynomialFactor`
- `unsupportedPolynomialVariable`
- `nonNumericCoefficient`
- `variableDenominator`

Diagnostics should remain in `ExprDiagnostic`/`ExprDiagnosticList` flow.

---

## 9. Implementation status

### 已完成
- **PolynomialExpansion-2A**：`PolynomialExpander` 已实现
  - 支持 `x/y`、`degree <= 2`、`maxTermCount` 限制
  - 支持 `add / multiply / negate / divide by numeric scalar`
  - 支持 `(x±a)^2`、`(x+a)(x+b)`、`(x+a)(y+b)`
- **PolynomialExpansion-2B**：`QuadraticFormExtractor` 增加 options
  - 默认 `.strict`（行为不变）
  - `.expanded2D` 显式调用 `PolynomialExpander`
- **PolynomialExpansion-2C**：`GraphClassifier` 一般二次型路径接入 expanded fallback
  - strict 失败后才尝试 `expanded2D`
  - `expanded2D` 失败继续 fallback implicit

### 后续建议
- **PolynomialExpansion-2D**：继续补充边界测试与性能上限验证（不扩大到完整 CAS）
- **PolynomialExpansion-3A**：如有必要，再评估有限符号系数支持策略

## 10. 当前支持与不支持

### 当前支持
- `(x+1)^2`
- `(x-1)^2`
- `(x+1)(x-1)`
- `(x-1)^2 + (y-2)^2 - 9`
- `degree <= 2` 的有限 `x/y` 多项式展开
- 展开后进入 `QuadraticFormExtractor` / conic recognition

### 当前仍不支持
- `degree > 2`
- symbolic coefficients
- functions such as `sin/log/sqrt`
- variable denominator
- arbitrary nested expansion
- matrix/vector/piecewise expansion
- general CAS simplification

---

## 11. Test plan

Minimum coverage:

1. `(x+1)^2 -> x^2 + 2x + 1`
2. `(x-1)^2 -> x^2 - 2x + 1`
3. `(x+1)(x-1) -> x^2 - 1`
4. `(x-1)^2 + (y-2)^2 - 9` expands to quadratic form
5. `sin(x+1)^2` rejected
6. `x^3` rejected or left for extractor failure (must be deterministic)
7. `(x+y+1)^2` behavior explicit (support if under limits, else bounded failure)
8. denominator containing variable rejected
9. symbolic coefficient `a*x` rejected
10. term-count overflow rejected

---

## 12. Fallback principle

If expansion fails (unsupported/over-limit), downstream behavior should remain unchanged:

- keep existing strict extractor behavior
- keep current GraphClassifier fallback (`implicit`/unknown paths)
- no silent broadening of CAS behavior
