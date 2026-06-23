# Function Naming Isolated Audit

> **Date:** 2026-06-08
> **Scope:** Read-only root cause audit. Zero code modified.
> **Status:** Root causes identified for all 4 naming issues.

---

## A. Ordinary Function Naming — ROOT CAUSE

### Where functions are REALLY named

There are **two** function creation paths, not one:

| Path | File | Line | Code | User Trigger |
|------|------|------|------|-------------|
| **Path 1 (PRIMARY)** | `WorkspaceState.swift` | 1455 | `"f\(document.objects.filter { $0.type == .function }.count + 1)"` | Inline formula editor commit (↵) |
| Path 2 | `PlaneCommandHandler.swift` | ~300 | `nextFunctionName(existing:)` | Toolbar "function" button |

**Path 1 is what users actually use 95% of the time.** It counts ALL `.function` objects including derivatives. It does NOT call `nextFunctionName`. My previous fixes to `PlaneCommandHandler.nextFunctionName` had ZERO effect on this path.

### Why previous fixes failed

| Round | What was changed | Why it didn't work |
|-------|-----------------|-------------------|
| Naming Cleanup | `PlaneCommandHandler.nextFunctionName` → `f_1, f_2` | Path 1 uses its own logic, not nextFunctionName |
| P0 Fix | Added derivative filtering to nextFunctionName | Same reason — Path 1 unaffected |

### Required fix

Replace Path 1's hardcoded naming with a call to a shared naming function that:
1. Only counts non-derivative `.function` objects
2. Produces sequential `f_1, f_2, f_3`

---

## B. Derivative Naming — PARTIALLY FIXED

### Current state

Derivative creation goes through `PlaneCommandHandler.handleCreateDerivative` (dispatched from ObjectPanel → state.dispatch(.moduleSpecific)). My prime-counting + `^(n)` formatting fix IS in the right place.

### Remaining issue

The naming fix in `handleCreateDerivative` should work for `f_1'(x)`, `f_1''(x)`, `f_1^(3)(x)`. But the **base name** comes from the source function's `name` field. If the source function was created by Path 1 (WorkspaceState), its name will be the old format (`f1`, `f2`). My derivative code strips primes and `(x)` and `^(n)`, so it should still work.

**Verdict**: Derivative naming fix is PROBABLY correct but depends on Path 1 being fixed first.

---

## C. Derivative Occupies Ordinary Function Number — ROOT CAUSE

### Root cause

Path 1 in WorkspaceState counts `document.objects.filter { $0.type == .function }.count + 1`. This includes ALL function objects — ordinary AND derivative. So if there are 3 function objects total (1 ordinary + 2 derivatives), the next ordinary function gets number 4.

```
Objects: [f1, f1'(x), f1''(x)]
count = 3
name = "f4"  ← WRONG, should be "f2"
```

### Required fix

Change the filter to exclude derivatives: `document.objects.filter { $0.type == .function && !$0.name.contains("'") && !$0.name.contains("^(") }.count + 1`.

Or better: extract a shared `nextOrdinaryFunctionIndex(existing:)` helper used by BOTH Path 1 and Path 2.

---

## D. Raw LaTeX / Source Display — ROOT CAUSE

### What the ObjectPanel actually displays

```swift
// WorkspaceObjectRowView.swift:288-292
private var primaryExpressionText: String {
    if let raw = object.expression.rawInput, !raw.isEmpty {
        return raw          // ← raw user input (may contain LaTeX)
    }
    return object.expression.displayText  // ← from parser
}
```

The `rawInput` field is the user's original typed text. If the user typed LaTeX like `\frac{x}{2}`, the object panel shows that raw LaTeX, not the plain text function name.

### The MathObject.name field

The `object.name` field IS correctly set (e.g., `"f_1"`). But the ObjectPanel's main row shows `primaryExpressionText` (the expression), NOT `object.name`. The `object.name` is displayed in a small text above the expression:

```swift
Text(object.name)           // This shows "f_1"  ← CORRECT
Text(primaryExpressionText)  // This shows raw input ← THE PROBLEM
```

### Why user sees LaTeX

The `primaryExpressionText` falls back to `rawInput` first, which preserves the user's original LaTeX. The fallback to `displayText` only happens when `rawInput` is empty. For functions created via the inline editor, `rawInput` may be populated with the LaTeX source.

### Required fix

Either:
- Don't set `rawInput` to raw LaTeX (set it to a cleaned display string instead)
- OR add a `displayName` field that takes priority over `rawInput`
- OR post-process the display to strip LaTeX markup

---

## E. Next Round Minimum Fix Plan

### Fix 1: Unify function naming (WorkspaceState.swift:1455)

```swift
// Before:
let name = "f\(document.objects.filter { $0.type == .function }.count + 1)"

// After:
let ordinaryCount = document.objects.filter {
    $0.type == .function && !$0.name.contains("'") && !$0.name.contains("^(")
}.count
let name = "f_\(ordinaryCount + 1)"
```

### Fix 2: Align PlaneCommandHandler.nextFunctionName

Make it match the same logic (already filtering derivatives, but should produce identical format).

### Fix 3: Display name cleanup (optional, P1)

Either clear `rawInput` after creating a function, or add a `displayName` override.

### Tests to add

- WorkspaceState creates `f_1`, `f_2` (not `f1`, `f4`)
- Derivative of `f_1` → `f_1'(x)` (WorkspaceState path)
- `f_1'(x)` does not advance ordinary counter

### Post-fix manual QA

| # | Test | Expected |
|---|------|----------|
| 1 | Type `y=x^2` → ↵ (inline editor) | Named `f_1(x)` |
| 2 | Type `y=sin(x)` → ↵ | Named `f_2(x)` |
| 3 | `f_1` → ObjectPanel → 求导 | `f_1'(x)` |
| 4 | `f_1'(x)` → 求导 | `f_1''(x)` |
| 5 | Type `y=x^3` → ↵ | Named `f_2(x)` NOT `f_4(x)` |
| 6 | Three derivatives of `f_1` | `f_1^(3)(x)` |
