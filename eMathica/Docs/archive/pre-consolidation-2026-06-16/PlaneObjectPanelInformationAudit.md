# Plane Object Panel Information Audit

## 1. Scope

This audit reviews Plane object panel information structure only.

- No Swift production code changes
- No test changes
- No UI implementation changes

Focus:

1. Row information hierarchy
2. Source/status readability for dynamic geometry
3. Information density risks
4. v1.1 text structure proposal

---

## 2. Current Row Structure (Audit)

Based on:

- `WorkspaceObjectRowView`
- `AlgebraObjectPanelView`
- `GeometryDependencyPresentation`
- `WorkspaceView` + `AlgebraObjectPanelLayoutMetrics`

### 2.1 Primary line (row title)

Current first line is:

- `object.name`
- full-width formula display (`FormulaCompactReadOnlyView`) using:
  - `rawInput` / `displayText`
  - AST-backed read-only rendering when available

So primary line effectively is: `Name : Main expression/value`.

### 2.2 Secondary line block

`secondaryText` is composed in this order:

1. dependency source text (if any)
2. status text (if any and not defined)
3. simplified expression (if available and different)
4. metadata text (semantic summary)
5. fallback type raw value

These entries are joined with newline into one text block, then rendered with:

- font size 11
- `lineLimit(3)`
- truncation tail

### 2.3 Dependency source integration

From `GeometryDependencyPresentation.sourceText`:

- midpoint: `中点：A，B`
- parallel: `平行：过 P，参考 l`
- perpendicular: `垂线：过 P，参考 l`
- intersection: `交点：A × B`
- circleByCenterPoint: `圆：圆心 A，过 B`
- circleByCenterRadius: `圆：圆心 A，半径 r`

### 2.4 Status integration

From `GeometryDependencyPresentation.statusText`:

- `noSolution`: `状态：当前无交点`
- `missingSource`: `状态：源对象缺失`
- `unsupported`: `状态：当前关系暂不支持`
- `invalid`: `状态：未定义`

`defined` does not show status text.

### 2.5 Slider row

Parameter objects use separate `ParameterObjectRowView`:

- top line with colored dot + `name = value`
- playback button
- settings menu
- slider control

So slider row already diverges from normal object row.

### 2.6 noSolution row

For geometry noSolution:

- status text appears in secondary block
- object still has row
- renderer/hit-test policy for non-defined is handled elsewhere (not row layer)

### 2.7 Controls placement

Normal row controls:

- leading visibility dot (tap to show/hide, long press opens settings)
- trailing menu:
  - edit/copy/settings/style/delete
  - conditional `转为静态对象` for derived objects
- optional diagnostic icon (from formula diagnostics) near menu

### 2.8 Height model

- normal row: `88`
- slider row: `98`
- row spacing: `10`
- panel height = `min(contentHeight, objectPanelMaxHeight)` with internal `ScrollView`

Object panel content-height model distinguishes parameter row height vs normal row height.

### 2.9 Truncation/wrapping behavior

- Primary expression:
  - formula view allows multi-line only for piecewise-like cases
  - fallback text is single-line unless multiline mode is enabled
- Secondary block:
  - supports newlines but capped to 3 rendered lines
  - long source/status/metadata can be truncated

### 2.10 Device structure consistency

Row structure is shared across iPad landscape, iPad split view, iPhone.
Differences are mostly panel width/maxHeight in layout metrics, not row template divergence.

---

## 3. Object-Type Matrix

## 3.1 Base geometry and function-like objects

### point / segment / line / ray / circle

- Primary: `name + expression/value`
- Secondary:
  - source/status when derived
  - else simplified/metadata/type fallback
- Controls: visibility + menu + style options
- Risk:
  - derived geometry with long source text can compete with simplified/metadata lines

### function / parametric / piecewise

- Primary: expression formula (piecewise may be multi-line compact view)
- Secondary: simplified + metadata/type fallback
- Controls: visibility + menu + style (line style for function-like)
- Risk:
  - piecewise + metadata + diagnostics can feel dense in limited row height

## 3.2 slider parameter

- Primary: `a = value`
- Secondary-like controls are embedded in dedicated slider row UI
- Controls: playback + presets + custom settings + delete/settings
- Risk:
  - parameter rows are visually information-rich and may dominate panel density

## 3.3 dynamic geometry derived objects

### midpoint / parallel / perpendicular / intersection / dynamic circle

- Primary: current value/expression
- Secondary:
  - source relation line
  - non-defined status line (if any)
  - optionally additional simplified/metadata if space remains
- Controls: includes convert action (`转为静态对象`)
- Risk:
  - source + status + simplified/metadata compete for the same 3-line budget
  - status may be pushed/truncated under long source names

## 3.4 noSolution intersection

- Primary: object identity/current expression
- Secondary: includes `状态：当前无交点`
- Controls: same row actions
- Risk:
  - status is textual only; no dedicated visual prominence in row hierarchy

## 3.5 static converted object

- Primary/secondary become regular static object behavior
- `转为静态对象` action disappears once dependency removed
- Risk:
  - semantic change may be clear in behavior but not strongly signposted in history/context

---

## 4. Key Readability Findings

## 4.1 Dependency source text clarity

Current source sentences are understandable and domain-aligned.
Main issue is not semantics; it is vertical competition with other secondary content.

## 4.2 noSolution visibility

Text exists and is explicit, but prominence is moderate because it is merged into the same secondary block as other information.

## 4.3 Redundancy and mixing

Current secondary block can include:

- source relation
- status
- simplified expression
- semantic metadata/type fallback

This can produce mixed layers (relation + health + math detail) in one visual zone.

## 4.4 Slider density

Slider row is functionally complete but visually heavy; in mixed lists it increases scan cost.

## 4.5 Long expression / long relation stress

Potential row stress remains when long expression and long source names coexist.
Hard cap at 3 lines mitigates overflow but can hide status/detail under truncation.

## 4.6 Panel/row height mismatch risk

Core mismatch bug was previously addressed via metrics split and content-height modeling.
Current risk is readability under truncation, not direct clipping mismatch.

## 4.7 Convert action wording

Current menu action: `转为静态对象`.
For user mental model of dynamic dependency lifecycle, `转为独立对象` is clearer.

---

## 5. v1.1 Information Structure Proposal (Design Only)

Conservative proposal, no implementation in this pass:

## 5.1 Regular objects

Line 1:

- `name + main expression/value`

Line 2:

- concise expression/type summary or semantic metadata

## 5.2 Dynamic derived objects

Line 1:

- `name + current value`

Line 2:

- source relation (always when dependency exists)

Line 3 (only when status != defined):

- status text (`当前无交点 / 源对象缺失 / ...`)

Important:

- status line should have higher retention priority than simplified/metadata text.
- simplified/metadata can be suppressed first under tight space.

## 5.3 Slider rows

- keep current control model
- keep dedicated row type
- later audit compression behavior for split/phone widths

---

## 6. Copy Recommendations

## 6.1 Convert wording

Current: `转为静态对象`  
Recommended: `转为独立对象`

Suggested helper copy (future):

- `解除动态关系，保留当前几何`

## 6.2 Status wording

- noSolution: `当前无交点`
- missingSource: `源对象缺失`
- unsupported: `暂不支持该关系`
- invalid: `定义无效`

---

## 7. Should We Add Status Icons Now?

Recommendation for current phase: **No**.

Reason:

- v1 core is in stabilization/freeze mode.
- Text hierarchy cleanup should happen before icon polish.
- Icon layer is better as a dedicated follow-up (`StatusIconPolish-1`).

---

## 8. Recommended Follow-up Task Split

1. `RenameConvertToIndependent-1` (highest priority)
2. `ObjectPanelTextStructure-1`
3. `GeometryPropertyDisplayAudit-1`
4. `StatusIconPolish-1`

Priority rationale:

- wording clarity first (low risk, immediate user comprehension gain)
- then text hierarchy to reduce density confusion
- then property enrichment audit
- icon polish last

