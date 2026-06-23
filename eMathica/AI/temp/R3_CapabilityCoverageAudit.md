# R3: Capability Coverage Audit

Read-Only. Cross-reference of CapabilityRegistry.json entries against real code.

---

## 1. Verification Methodology

For each capability with `status: "existing"` in the Registry:
1. Located the corresponding source file on disk
2. Read file content to verify real implementation (not placeholder, not return nil)
3. Classified as Confirmed or Mismatch

For `status: "partial"` and `status: "planned"` entries:
1. Searched for any implementation code
2. Flagged if code found but Registry says planned (under-report)

---

## 2. Summary Counts

| Metric | Count |
|--------|:-----:|
| Total capabilities in Registry | 80 |
| Confirmed Existing | 48 |
| Confirmed Partial | 2 |
| Confirmed Planned | 18 |
| **MISMATCH: existing → no code found** | **11** |
| MISMATCH: existing → placeholder only | 1 |
| MISMATCH: planned → code exists | 0 |
| MISMATCH: partial → code exists | 0 |
| Needs Verification | 0 |

**Mismatch rate:** 12/80 = 15%

---

## 3. Per-Domain Summary

| Domain | Registry Existing | Confirmed | Partial | Planned | Mismatch |
|--------|:-----------------:|:---------:|:------:|:------:|:--------:|
| algebra | 14 | 14 | 0 | 0 | 0 |
| animation | 2 | 0 | 1 | 0 | 1 |
| cas | 5 | 5 | 0 | 0 | 0 |
| command | 2 | 0 | 0 | 0 | 2 |
| construction | 0 | 0 | 0 | 0 | 0 |
| coordinate | 2 | 2 | 0 | 0 | 0 |
| dependency | 3 | 0 | 1 | 1 | 1 |
| document | 3 | 0 | 0 | 0 | 3 |
| evaluation | 2 | 2 | 0 | 0 | 0 |
| export | 1 | 0 | 0 | 1 | 0 |
| expr | 2 | 2 | 0 | 0 | 0 |
| formula | 1 | 0 | 0 | 0 | 1 |
| geometry | 1 | 1 | 0 | 0 | 0 |
| graph | 4 | 4 | 0 | 0 | 0 |
| input | 2 | 0 | 0 | 0 | 2 |
| inspector | 1 | 0 | 0 | 0 | 1 |
| object | 16 | 14 | 0 | 2 | 0 |
| plugin | 0 | 0 | 0 | 16 | 0 |
| preview | 1 | 0 | 0 | 0 | 1 |
| sampling | 7 | 7 | 0 | 0 | 0 |
| selection | 1 | 0 | 0 | 0 | 1 |
| semantic | 7 | 7 | 0 | 0 | 0 |
| spacemath | 1 | 1 | 0 | 0 | 0 |
| style | 3 | 0 | 0 | 2 | 1 |
| workspace | 3 | 0 | 0 | 0 | 3 |

---

## 4. Complete Mismatch List (12 capabilities)

### Category A: Registry says existing — no code found (11 entries)

| # | Capability ID | Domain | Registry Status | Actual Code Status |
|---|--------------|--------|:---------------:|--------------------|
| 1 | `workspace.createNew` | workspace | existing | **No code found** — WorkspaceKit imported by App Target but its source files live outside scanned tree. Likely exists in WorkspaceKit Package |
| 2 | `workspace.manageProjects` | workspace | existing | **No code found** |
| 3 | `workspace.moduleNavigation` | workspace | existing | **No code found** |
| 4 | `input.mathInput` | input | existing | **No code found** — MathInputKit Package may not exist (see R2) |
| 5 | `input.structuredInput` | input | existing | **No code found** |
| 6 | `formula.render` | formula | existing | **No code found** — FormulaRenderKit Package may not exist |
| 7 | `command.undoRedo` | command | existing | **No code found** — Handled in PlaneCommandHandler (App Target), not in a Package |
| 8 | `command.objectOperations` | command | existing | **No code found** |
| 9 | `dependency.resolve` | dependency | existing | **No code found** — `DependencyGraph` struct is empty placeholder; per-object `GeometryDependency` exists but no graph resolver |
| 10 | `dependency.recompute` | dependency | existing | **No code found** |
| 11 | `dependency.cascadeDelete` | dependency | existing | **No code found** |

### Category B: Registry says existing — placeholder only (1 entry)

| # | Capability ID | Domain | Registry Status | Actual Code Status |
|---|--------------|--------|:---------------:|--------------------|
| 12 | `animation.objectAnimation` | animation | existing | **Placeholder only** — no animation engine found; `PlaneToolActions.swift` is a comment placeholder |

### Additional Package-Domain Risks (Capabilities whose futurePackage may block validation)

| # | Capability ID | Target Package | Package Status |
|---|--------------|----------------|----------------|
| 13 | `document.create` | EMathicaDocumentKit | **Package EXISTS** (11 files, 3 targets) — but DocumentSystem/ App Target duplicates all its types |
| 14 | `document.saveLoad` | EMathicaDocumentKit | Same as above |
| 15 | `document.projectMetadata` | EMathicaDocumentKit | Same as above |
| 16 | `inspector.objectInspector` | WorkspaceKit | Code not verified — likely exists in WorkspaceKit Package |
| 17 | `selection.objectSelection` | WorkspaceKit | Code not verified |
| 18 | `preview.draftPreview` | WorkspaceKit | Code not verified |
| 19 | `style.objectStyle` | WorkspaceKit | Code not verified |
| 20 | `export.documentExport` | WorkspaceKit | Code not verified |

---

## 5. High-Risk Mismatches (Top Priority)

| Rank | Capability ID | Severity | Why |
|:----:|--------------|:--------:|-----|
| 1 | `dependency.resolve` | 🔴 Critical | `DependencyGraph` struct is **completely empty** (zero fields). Registry says existing. |
| 2 | `dependency.recompute` | 🔴 Critical | Same — relies on empty DependencyGraph |
| 3 | `dependency.cascadeDelete` | 🔴 Critical | Same — relies on empty DependencyGraph |
| 4 | `input.mathInput` | 🔴 High | MathInputKit Package may not exist; input capabilities in DocumentSystem or Plane only |
| 5 | `input.structuredInput` | 🔴 High | Same as above |
| 6 | `formula.render` | 🔴 High | FormulaRenderKit Package may not exist on disk |
| 7 | `animation.objectAnimation` | 🟡 Medium | Placeholder only; no real animation engine |
| 8 | `command.undoRedo` | 🟡 Medium | Exists in App Target (PlaneCommandHandler), not in a Package where Registry expects it |
| 9 | `command.objectOperations` | 🟡 Medium | Same as above |
| 10 | `workspace.createNew` | 🟡 Low | Likely exists in WorkspaceKit Package (not in App Target) — needs Package-level verification |
| 11 | `workspace.manageProjects` | 🟡 Low | Same |
| 12 | `workspace.moduleNavigation` | 🟡 Low | Same |

---

## 6. Update Recommendations for CapabilityRegistry.json

### Entries to change from "existing" to "planned"

| Capability ID | Current | Recommended | Reason |
|--------------|:-------:|:-----------:|--------|
| `dependency.resolve` | existing | planned | DependencyGraph is empty placeholder |
| `dependency.recompute` | existing | planned | Same |
| `dependency.cascadeDelete` | existing | planned | Same |
| `animation.objectAnimation` | existing | planned | Placeholder only, no animation engine |

### Entries to change from "existing" to "needs_verification"

| Capability ID | Current | Recommended | Reason |
|--------------|:-------:|:-----------:|--------|
| `input.mathInput` | existing | needs_verification | MathInputKit Package existence unconfirmed |
| `input.structuredInput` | existing | needs_verification | Same |
| `formula.render` | existing | needs_verification | FormulaRenderKit Package existence unconfirmed |
| `workspace.createNew` | existing | needs_verification | Code in WorkspaceKit Package, not App Target |
| `workspace.manageProjects` | existing | needs_verification | Same |
| `workspace.moduleNavigation` | existing | needs_verification | Same |
| `command.undoRedo` | existing | needs_verification | In App Target, not Package |
| `command.objectOperations` | existing | needs_verification | Same |
| `inspector.objectInspector` | existing | needs_verification | Likely in WorkspaceKit Package |
| `selection.objectSelection` | existing | needs_verification | Same |
| `style.objectStyle` | existing | needs_verification | Same |
| `preview.draftPreview` | existing | needs_verification | Same |
| `export.documentExport` | existing | needs_verification | Same |

### Recommendation

Do NOT modify the Registry yet. First complete R2 (Package Reality Audit) to determine which packages actually exist. Then cross-reference: if a package directory exists with real code, mark those capabilities Confirmed. If the package directory does NOT exist, downgrade to "planned".
