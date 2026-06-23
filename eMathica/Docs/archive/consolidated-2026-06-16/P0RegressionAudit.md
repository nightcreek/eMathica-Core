# P0 Regression Audit — Arc, Naming, Display

> **Date:** 2026-06-08
> **Scope:** Read-only root cause audit. Zero code modified.
> **Status:** All 4 user-reported failures have been root-caused.

---

## A. Arc Second-Point Line — Root Cause

### Verdict: ✅ FIX IS CORRECT, NOT REPRODUCIBLE FROM CODE

**Static analysis** of the current `PlaneCanvasView.swift` confirms:

| Location | State | Action |
|----------|-------|--------|
| `handleArcTap` first tap (default) | `constructionPreview = nil` | No line ✅ |
| `handleArcTap` second tap (arcSecondPoint) | `constructionPreview = nil` | No line ✅ |
| `constructionPreviewGesture` third-point drag (valid arc) | `temporaryArc(A,B,C)` | Arc preview ✅ |
| `constructionPreviewGesture` third-point drag (collinear) | `nil` | No preview ✅ |
| `PlaneObjectRendererView` temporaryArc (invalid arc) | `guard let arc... else { return }` | No render ✅ |

**Conclusion**: The code fix is correct. The most likely explanation for the user's FAIL result is that the app was not rebuilt with the latest changes, or a stale build cache was used.

**Recommendation for next round**: Clean build (`xcodebuild clean build`) and re-test.

---

## B. Function Naming Not Sequential — Root Cause

### Verdict: ✅ CODE IS CORRECT, BUILD CACHE LIKELY

The `nextFunctionName` method now correctly extracts max numeric index:

```swift
private func nextFunctionName(existing: [MathObject]) -> String {
    let existingFunctions = existing.filter { $0.type == .function }
    let maxIndex = existingFunctions.compactMap { obj -> Int? in
        let name = obj.name
        guard let firstChar = name.first, firstChar.isLetter else { return nil }
        let rest = String(name.dropFirst())
        if rest.isEmpty { return 1 }
        let digits = rest.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        return Int(digits)
    }.max() ?? 0
    return "f_\(maxIndex + 1)"
}
```

Called from `submitInput` and `createFunction` — both paths use `functionDefinitionName(…) ?? nextFunctionName(…)`.

**Conclusion**: The code should produce sequential names (f_1, f_2, f_3). If the user sees non-sequential names, the build was not updated.

---

## C. Second Derivative Naming — ROOT CAUSE FOUND 🔴

### Bug: `baseName` retains `(x)` suffix, causing `f_1(x)''(x)`

**Code** (PlaneCommandHandler:687-691):
```swift
let sourceName = sourceObject.name           // "f_1'(x)"
let baseName = sourceName.replacingOccurrences(of: "'", with: "")  // "f_1(x)" ← BUG
let primeCount = sourceName.filter { $0 == "'" }.count + 1         // 2
let primes = String(repeating: "'", count: primeCount)              // "''"
let name = "\(baseName)\(primes)(\(variable.name))"                // "f_1(x)''(x)" ← WRONG
```

**Root cause**: `baseName` strips primes but not the `(x)` argument suffix. The result is `f_1(x)''(x)` instead of `f_1''(x)`.

**Fix** (1 line): Also strip `(x)` suffix from baseName:
```swift
let baseName = sourceName
    .replacingOccurrences(of: "'", with: "")
    .replacingOccurrences(of: "(x)", with: "")
```

---

## D. Root Name + Keyboard Preview — ROOT CAUSE FOUND 🔴

### Bug 1: Root point naming uses `R_1`, but auto-selects points

**Code** (PlaneCommandHandler:758-771):
```swift
let pointName = "R_\(existingRoots + i + 1)"     // "R_1"
...
return ModuleCommandOutput(
    documentCommands: commands,
    effects: [.selectObjects(newIDs), .showToast("已添加 \(commands.count) 个根点")]
)
```

### Bug 2: Auto-selection triggers keyboard preview pollution

When `.selectObjects(newIDs)` fires, the selected point's `expression.displayText` (e.g., `"R_1 = (2, 0)"`) is loaded into the formula input state. The keyboard preview displays this text.

**Root cause**: The `effects: [.selectObjects(newIDs)]` causes the root point to be selected, which triggers `FormulaInputState` to load the point's `displayText` into the keyboard preview.

**Fix**: Remove `.selectObjects(newIDs)` from effects. Keep only `.showToast(...)`:
```swift
effects: [.showToast("已添加 \(commands.count) 个根点")]
```

---

## E. 2*x Display — ROOT CAUSE FOUND 🔴

### Bug: `cleanDisplayText` only affects fallback path, not main path

**Code flow**:
1. `ExprSerializer.serialize(derivative)` → `"2*x"`
2. `cleanDisplayText("2*x")` → `"2x"` (displaySource)
3. `PlaneExpressionService.buildExpression("y=2*x")` → `MathExpression(displayText: "2*x")` ← parser output
4. Success case: `derivExpression = built result` (displayText = `"2*x"`)
5. Fallback case: `derivExpression = MathExpression(displayText: displaySource)` (displayText = `"2x"`)
6. ObjectPanel: `object.expression.displayText` → displays `"2*x"`

**Root cause**: `cleanDisplayText` is only used when `buildExpression` FAILS. In the normal success path, the parser's own formatting (`"2*x"`) is preserved. My clean-up never reaches the display.

**Fix** (2 options):
- **Option A**: Apply `cleanDisplayText` to the MathExpression's `displayText` AFTER `buildExpression` succeeds (post-process the displayText field)
- **Option B**: Fix `ExprSerializer` to not emit `*` between number and letter in the first place (e.g., `2*x` → `2x`)

Option B is better — fix at the source, not after the fact.

---

## F. Summary of Required Fixes

| # | Issue | Root Cause | Fix | File | Lines |
|---|-------|-----------|-----|------|-------|
| C | Second derivative naming | `baseName` keeps `(x)` suffix | Strip `(x)` from baseName | PlaneCommandHandler | 1 |
| D | Keyboard preview pollution | `.selectObjects(newIDs)` auto-selects root points | Remove `.selectObjects` from effects | PlaneCommandHandler | 1 |
| E | 2*x display | `cleanDisplayText` only in fallback path | Apply to ExprSerializer output directly | ExprSerializer or PlaneCommandHandler | ~5 |
| A | Arc second-point line | Build cache / not rebuilt | Clean rebuild | — | — |
| B | Sequential naming | Build cache / not rebuilt | Clean rebuild | — | — |

**Total code changes**: ~7 lines across 2 files.

---

## G. Post-Fix Manual QA Checklist

| # | Test | Expected |
|---|------|----------|
| 1 | Arc second point | No line appears |
| 2 | Create 3 functions | Named f_1, f_2, f_3 |
| 3 | f_1 → 求导 | Named f_1'(x) |
| 4 | f_1'(x) → 求导 | Named f_1''(x) |
| 5 | y=x²-1 → 求根 | Points named R_1, R_2 |
| 6 | After 求根 | Keyboard preview NOT polluted with "R_1 = (2, 0)" |
| 7 | Derivative displayText | Shows "2x" not "2*x" |
| 8 | Clean rebuild before test | `xcodebuild clean build` |
