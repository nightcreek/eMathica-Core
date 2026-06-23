# Keyboard Legacy Cleanup Audit

> **Date:** 2026-06-07  
> **Scope:** Read-only audit — identify which legacy files can be safely deleted.  
> **Prerequisite:** Phase 2 complete (WorkspaceKit depends on InputKit).  

---

## 1. Audit Scope

### 1.1 Candidate Legacy Files (5)

| # | File | Location | Lines | Header Comment |
|---|------|----------|-------|----------------|
| 1 | `LatexTemplate.swift` | Keyboard/Legacy/ | ~120 | "LEGACY STRING INPUT PATH" |
| 2 | `LatexTemplateInsertion.swift` | Keyboard/Legacy/ | ~75 | "LEGACY STRING INPUT PATH" |
| 3 | `FormulaPlaceholderNavigator.swift` | Keyboard/Legacy/ | ~90 | "LEGACY STRING INPUT PATH" |
| 4 | `ExpressionInputBarView.swift` | Input/Legacy/ | ~35 | "LEGACY INPUT ENTRY VIEW" |
| 5 | `LegacyStringInputUsageTracker.swift` | Keyboard/ | ~20 | Tracks legacy call frequency |

### 1.2 Deprecated Method (1)

| # | Method | Location | Status |
|---|--------|----------|--------|
| 6 | `WorkspaceState.insertLatexTemplate(_:)` | WorkspaceState.swift:782 | `@available(*, deprecated)` |

---

## 2. Legacy File Reference Map

### 2.1 Call Graph

```
WorkspaceState.insertLatexTemplate (deprecated, 0 callers)
    └── (no callers — standalone dead code)

LatexTemplate.swift (struct)
    ├── LatexTemplateInsertion.swift (reference from legacy)
    └── FormulaPlaceholderNavigator.swift (reference from legacy)

LatexTemplateInsertion.swift (struct + enum)
    └── FormulaPlaceholderNavigator.swift (reference from legacy)

FormulaPlaceholderNavigator.swift (enum)
    ├── LatexTemplate (reference to legacy)
    ├── LatexTemplateInsertion (reference to legacy)
    ├── LegacyStringInputUsageTracker (reference to legacy)
    └── FormulaInputState (reference to active type — see §2.2)

LegacyStringInputUsageTracker.swift (enum)
    ├── FormulaPlaceholderNavigator.swift (reference from legacy)
    └── LatexTemplateInsertion.swift (reference from legacy)

ExpressionInputBarView.swift (View)
    └── ZERO callers — completely dead
```

### 2.2 Active-Type Contamination

`FormulaInputState` (active file) defines types used ONLY by legacy code:

| Type | Used By | Can Remove? |
|------|---------|-------------|
| `FormulaPlaceholder` (struct) | `FormulaPlaceholderNavigator` (legacy) | Yes — after legacy deletion |
| `FormulaPlaceholderKind` (enum) | `LatexTemplateInsertion` (legacy) | Yes — after legacy deletion |
| `activePlaceholders: [FormulaPlaceholder]` | Only set to `[]` in WorkspaceState | Yes — after legacy deletion |

### 2.3 App Module References

ZERO references from CalculatorModules, CoreHome, App, or DocumentSystem to any legacy file.

### 2.4 InputKit References

ZERO. The InputKit package provides the AST-based replacement (InputController, TemplateDefinition, MathEditorEngine) but has no dependency on any legacy file.

---

## 3. Replacement Mapping

| Legacy Type/Method | Replacement | Where |
|--------------------|-------------|-------|
| `LatexTemplate` (struct) | `TemplateDefinition` + `TemplateKind` | InputKit `TemplateDefinition.swift` |
| `LatexTemplateInsertion` (struct) | `InputController.insertTemplate()` | InputKit `MathEditorEngine.swift` |
| `LatexTemplateInserter` (enum) | `InputController.handle(.insertTemplate(_:))` | InputKit |
| `FormulaPlaceholderNavigator` (enum) | `EditorCursorNavigator` | InputKit `EditorCursorNavigator.swift` |
| `ExpressionInputBarView` (View) | `FormulaEditorView` | WorkspaceKit `Keyboard/FormulaEditorView.swift` |
| `LegacyStringInputUsageTracker` (enum) | Not needed — legacy tracking | — |
| `WorkspaceState.insertLatexTemplate(_:)` | `WorkspaceState.handleKeyboardAction(.insertTemplate(...))` | WorkspaceState.swift |
| `FormulaPlaceholder` (struct) | `EditorCursor` + template field navigation | InputKit |
| `FormulaPlaceholderKind` (enum) | `TemplateKind` + `FieldID` | InputKit |

---

## 4. Safe-to-Delete Files

### 4.1 Delete Immediately (Zero Caller Migration Needed)

These files have **zero external callers** — all references are internal to the legacy cluster:

| File | External Callers | Risk | 
|------|-----------------|------|
| `ExpressionInputBarView.swift` | 0 | 🟢 None |
| `LegacyStringInputUsageTracker.swift` | 0 (only called by other legacy files) | 🟢 None |

### 4.2 Delete After Removing Last External Reference

These files have 1 trivial external reference:

| File | External Reference | Fix |
|------|-------------------|-----|
| `LatexTemplate.swift` | `WorkspaceState:782` — `insertLatexTemplate(_:)` method (deprecated, 0 callers) | Delete the `insertLatexTemplate` method along with the file |
| `LatexTemplateInsertion.swift` | 0 external callers | None |
| `FormulaPlaceholderNavigator.swift` | 0 external callers | None |

### 4.3 Cleanup in Active Files After Legacy Deletion

| File | What to Remove | Lines Affected |
|------|---------------|----------------|
| `FormulaInputState.swift` | `FormulaPlaceholder` struct (lines 45-62) | ~18 |
| `FormulaInputState.swift` | `FormulaPlaceholderKind` enum (lines 64-69) | ~6 |
| `FormulaInputState.swift` | `activePlaceholders` property (line 12) | 1 |
| `FormulaInputState.swift` | `activePlaceholders` in init (line 25, 37) | 2 |
| `WorkspaceState.swift` | `insertLatexTemplate(_:)` method (lines 782-786) | 5 |
| `WorkspaceState.swift` | `activePlaceholders: []` in session init (line 910) | 1 |

**Total cleanup in active files: ~33 lines across 2 files.**

---

## 5. Files Requiring Call-Site Migration

### 5.1 No Migration Needed

**All 5 legacy files can be deleted without any call-site migration.** The "references" from active code (WorkspaceState, FormulaInputState) are to internal helper types and methods that exist ONLY to support the legacy flow. They are all dead code.

The call graph is:

```
Active Code (WorkspaceState, FormulaEditorView, MathKeyboardView)
  └── ZERO references to Legacy files

Legacy Cluster (5 files + 2 types in FormulaInputState)
  └── References only to other legacy files
```

### 5.2 Verification Command

```bash
# Confirm zero callers from active code before deletion:
grep -rn "LatexTemplate\|ExpressionInputBarView\|FormulaPlaceholderNavigator\|LegacyStringInputUsageTracker\|LatexTemplateInsertion" \
  Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/ \
  --include="*.swift" | grep -v "Legacy/"
# Expected output: only WorkspaceState:782 (insertLatexTemplate, deprecated)
```

---

## 6. Recommended Phase 3B Execution Plan

### Step 1: Delete 5 Legacy Files (1 minute, 0 risk)

```bash
rm Keyboard/Legacy/LatexTemplate.swift
rm Keyboard/Legacy/LatexTemplateInsertion.swift
rm Keyboard/Legacy/FormulaPlaceholderNavigator.swift
rm Input/Legacy/ExpressionInputBarView.swift
rm Keyboard/LegacyStringInputUsageTracker.swift
```

### Step 2: Clean FormulaInputState (2 minutes, 0 risk)

Remove:
- `FormulaPlaceholder` struct (18 lines)
- `FormulaPlaceholderKind` enum (6 lines)
- `activePlaceholders` property (1 line)
- `activePlaceholders` init parameter and assignment (2 lines)

### Step 3: Remove insertLatexTemplate (1 minute, 0 risk)

Remove `WorkspaceState.insertLatexTemplate(_:)` method (5 lines) and its `@available(*, deprecated)` annotation.

### Step 4: Remove activePlaceholders usage in WorkspaceState (1 minute)

The `activePlaceholders: []` initialization at line ~910.

### Step 5: Build Verification (2 minutes)

```bash
cd Packages/EMathicaWorkspaceKit && swift build
xcodebuild -project eMathica.xcodeproj -scheme eMathica build
```

### Total: ~7 minutes, zero call-site migration.

---

## 7. Risks

| Risk | Level | Mitigation |
|------|-------|------------|
| Runtime code path still uses legacy | 🟢 LOW | `LegacyStringInputUsageTracker` would log calls — confirms zero usage |
| `FormulaPlaceholder` type used in serialization | 🟢 LOW | Not in any Codable path — it's only used in in-memory state |
| `activePlaceholders` accessed by external code | 🟢 LOW | Only initialized as `[]` — never read from outside legacy |
| `LatexTemplate` Sendable issue cascade | 🟢 LOW | Already marked Sendable; removal unblocks other fixes |
| `ExpressionInputBarView` referenced in SwiftUI previews | 🟢 LOW | Not in any preview provider |

---

## 8. Pre-Deletion Verification

Run these checks before deleting:

```bash
# 1. Confirm app builds
xcodebuild -project eMathica.xcodeproj -scheme eMathica build

# 2. Confirm zero active callers
grep -rn "LatexTemplate\|ExpressionInputBarView\|FormulaPlaceholderNavigator\|LegacyStringInputUsageTracker\|LatexTemplateInsertion" \
  Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/ \
  --include="*.swift" | grep -v "Legacy/" | grep -v "\.build"

# 3. Confirm InputKit tests pass
cd Packages/EMathicaMathInputKit && swift test

# Expected: app builds, 0 active callers, 18 tests pass
```
