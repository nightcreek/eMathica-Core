# PlaneVisualAudit-GlassSystem-1

## 1) Scope

- This pass is **audit-only**.
- No production visual parameter patch applied.
- No behavior/input/semantic/tool/model changes.
- Goal: map real glass/material ownership across preview/object panel/toolbar/keyboard and identify duplicate stacking risks.

---

## 2) Files Audited

- `eMathica/WorkspaceKit/WorkspaceView.swift`
- `eMathica/WorkspaceKit/Keyboard/MathKeyboardView.swift`
- `eMathica/WorkspaceKit/Keyboard/FormulaEditorView.swift`
- `eMathica/WorkspaceKit/Keyboard/FormulaInputState.swift`
- `eMathica/WorkspaceKit/ObjectPanel/AlgebraObjectPanelView.swift`
- `eMathica/WorkspaceKit/ObjectPanel/WorkspaceObjectRowView.swift`
- `eMathica/WorkspaceKit/Toolbar/ToolGroupCapsuleView.swift`
- `eMathica/WorkspaceKit/Shared/LiquidGlassPanel.swift`
- `eMathica/WorkspaceKit/Shared/GlassComponents.swift`
- `eMathica/WorkspaceKit/Shared/WorkspaceTheme.swift`
- `eMathica/WorkspaceKit/Shared/LiquidGlassIconButton.swift`

---

## 3) Real Layer Trees

## WorkspaceView

```text
WorkspaceView
├─ ObjectPanelContainer
│  └─ AlgebraObjectPanelView
│     └─ LiquidGlassPanel(theme: objectPanelTheme)  <-- panel glass owner
│        ├─ Header
│        ├─ EmptyState (extra rounded fill in empty state)
│        └─ Rows
│           ├─ WorkspaceObjectRowView (row fill+stroke)
│           └─ ParameterObjectRowView (row fill+stroke + play btn local fill)
├─ TopToolbar
│  └─ FloatingToolGroupsView
│     └─ ToolGroupCapsuleView
│        └─ LiquidGlassPanel(theme: capsuleTheme)   <-- capsule glass owner
│           └─ Menu label
│              └─ active Capsule fill overlay
├─ Top-left DocumentMenuButton
│  ├─ circle glass background (.glassEffect / .ultraThinMaterial fallback)
│  ├─ circle stroke
│  └─ shadow
├─ Top-right LiquidGlassIconButton
│  ├─ circle glass background (.glassEffect / .ultraThinMaterial fallback)
│  ├─ circle stroke
│  └─ shadow
└─ Bottom Input Dock (WorkspaceInlineInputDock)
   ├─ PreviewPanel (editorBar)
   │  ├─ GlassPanel -> LiquidGlassPanel(theme: inputBarTheme)
   │  ├─ extra top highlight overlay (WorkspaceView-level)
   │  ├─ FormulaEditorView content
   │  └─ icon buttons (borderless default, pressed circle fill)
   ├─ ParameterSuggestion panel (optional)
   │  └─ GlassPanel(theme: .sidePanel) + chips (.thinMaterial capsule)
   └─ KeyboardPanel (optional)
      ├─ keyboardPanel wrapper bg fill (dark 0.02 / light 0.03)
      ├─ top hairline
      └─ MathKeyboardView
         └─ KeyboardGlassPanel
            ├─ container fill + overlay + stroke + top highlight + shadow
            └─ content VStack
               ├─ KeyboardKeysBackplate (fill+material+stroke+highlight+shadow)
               ├─ CategoryRow tab keycaps (LiquidGlassKeyBackground)
               └─ KeyGrid keycaps (LiquidGlassKeyBackground)
```

---

## 4) Per-area Layer Audit

## A. PreviewPanel / editorBar

- Main glass owner: `GlassPanel(theme: inputBarTheme)` -> `LiquidGlassPanel`.
- Additional visual layer: explicit **top highlight overlay** in `WorkspaceView.editorBar`.
- Button style: icon-only, pressed-state circle fill.
- Repetition risk: **light duplicate** (panel glass + extra top highlight).
  - Usually acceptable, but this is one extra local accent layer beyond panel owner.

## B. Keyboard area

- Layers:
  1. `keyboardPanel` wrapper background fill + hairline (WorkspaceView)
  2. `KeyboardGlassPanel` container glass (MathKeyboardView)
  3. `KeyboardKeysBackplate` support glass (MathKeyboardView)
  4. keycaps (tab + keys)
- Repetition risk: **severe duplicate** (three container-level plate semantics before keycaps).
- This matches prior `KeyboardVisualLayerAudit` findings.

## C. ObjectPanel outer

- Main glass owner: `LiquidGlassPanel(theme: objectPanelTheme)` on whole panel.
- Extra local layer: empty-state card has its own rounded fill.
- Repetition risk: **light** (only in empty-state branch), normal list branch is clean.

## D. ObjectRow / selected row

- Rows are not `LiquidGlassPanel`; they use plain rounded fill + stroke.
- Selected row adds accent fill+stroke.
- Repetition risk: **none to light**.
  - This is acceptable because row is lightweight and subordinate to panel owner.

## E. ToolGroupCapsule

- Main owner: `LiquidGlassPanel(theme: capsuleTheme)`.
- Active state adds inner `Capsule` accent fill.
- Repetition risk: **light**.
  - Not severe; active accent is semantic state indication.

## F. Floating settings / folder buttons

- Each button is a self-contained circle glass component with stroke/shadow.
- They are independent controls, not nested in additional local panel wrappers at point of use.
- Repetition risk: **none** in local composition.

---

## 5) Visual Parameter Table (current code)

| Component | Layer | Fill | Material | Stroke | Highlight | Shadow | Notes |
|---|---|---|---|---|---|---|---|
| PreviewPanel | main panel | dark 0.20 / light 0.24 (`inputBarTheme`) | via `LiquidGlassPanel` background path | dark 0.10 / light 0.13 | yes (panel + extra top overlay) | dark 0.10 / light 0.04 | extra top overlay exists in `WorkspaceView` |
| Keyboard wrapper | `keyboardPanel` | dark 0.02 / light 0.03 | none | top hairline only | none | none | weak but additional plate |
| Keyboard container | `KeyboardGlassPanel` | dark 0.025 / light 0.05 + extra overlay | none explicit | dark 0.04 / light 0.08 | yes | dark 0.05 / light 0.03 | second plate |
| Keyboard backplate | `KeyboardKeysBackplate` | dark 0.28 / light 0.36 | `.thinMaterial` (dark 0.30 / light 0.26) | dark 0.18 / light 0.46 | yes | dark 0.26 / light 0.12 | intended primary support plate |
| Category tab inactive | keycap | dark 0.05 / light 0.28 | none | dark 0.13 / light 0.26 | yes | dark 0.08 / light 0.06 | per-key |
| Category tab active | keycap | accent dark/light 0.28 | none | dark 0.18 / light 0.34 | yes | dark 0.08 / light 0.06 | per-key |
| Normal key | keycap | dark 0.065 / light 0.30 | none | dark 0.14 / light 0.32 | yes | dark 0.08 / light 0.06 | per-key |
| Primary key | keycap | accent dark/light 0.32 | none | dark 0.19 / light 0.36 | yes | dark 0.08 / light 0.06 | per-key |
| ObjectPanel | panel | dark 0.18 / light 0.30 | via `LiquidGlassPanel` | dark/light 0.12 | yes | dark 0.08 / light 0.035 | clean owner model |
| ObjectRow unselected | row | dark 0.035 / light 0.12 | none | dark 0.07 / light 0.14 | none | none | lightweight row |
| ObjectRow selected | row | accent dark 0.22 / light 0.09 | none | accent dark 0.25 / light 0.16 | none | none | selected emphasis |
| ToolGroup capsule | panel | dark 0.18 / light 0.22 | via `LiquidGlassPanel` | dark 0.12 / light 0.10 | panel highlight | theme shadow | owner is panel + active accent capsule |
| ToolGroup active overlay | inner capsule | accent dark 0.28 / light 0.20 | none | none | none | none | state accent layer |

---

## 6) Duplicate-layer Findings

## Keyboard
- **Severe duplicate**:
  - `keyboardPanel wrapper` + `KeyboardGlassPanel` + `KeyboardKeysBackplate`.
- This is the primary instability source for “support unclear / double glass / key feel drift”.

## PreviewPanel
- **Light duplicate**:
  - `LiquidGlassPanel` plus extra top highlight overlay in `WorkspaceView`.
- Not catastrophic, but still an additional owner-like accent.

## ObjectPanel
- **Mostly clean**:
  - one clear panel owner.
  - rows are lightweight fills, not mini glass panels.

## ToolGroupCapsule
- **Light duplicate**:
  - panel owner + active capsule accent.
- Acceptable if active accent kept subtle.

---

## 7) Unified Glass Ownership Rule (recommended)

## PreviewPanel
- Single owner: `GlassPanel/LiquidGlassPanel`.
- Optional top accent should remain subtle and not act as second panel.

## ObjectPanel
- Single owner: panel `LiquidGlassPanel`.
- Rows only lightweight fill/stroke.
- Selected row accent is allowed, but row should not become another full glass panel.

## Toolbar Capsule
- Single owner: capsule `LiquidGlassPanel`.
- Active state uses inner accent fill only (not a second panel shell).

## Keyboard
- Single owner for support plate: `KeyboardKeysBackplate`.
- `keyboardPanel wrapper` and `KeyboardGlassPanel` should be downgraded to structural/light separators, not panel-level glass owners.
- Keycaps remain translucent and do not serve support-plate role.

---

## 8) Recommended Patch Plan (do not execute in this audit)

## Phase 1: Remove duplicate owners
1. Keyboard:
   - downgrade/remove visual weight of `keyboardPanel` wrapper fill.
   - downgrade `KeyboardGlassPanel` to structural wrapper (padding/clip only or near-zero panel visuals).
   - keep `KeyboardKeysBackplate` as sole support glass.
2. Preview:
   - keep `GlassPanel` as owner; weaken/remove extra top overlay only if needed after keyboard cleanup.
3. Toolbar:
   - keep current structure; ensure active accent does not look like second capsule shell.

## Phase 2: Token unification
Create centralized tokens (example):

```swift
struct PlaneGlassTokens {
    static let previewPanel: ...
    static let keyboardBackplate: ...
    static let keyboardKey: ...
    static let objectPanel: ...
    static let objectRow: ...
    static let objectRowSelected: ...
    static let toolbarCapsule: ...
    static let toolbarCapsuleActive: ...
}
```

## Phase 3: Visual tuning
- Tune dark/light opacity ranges with one-owner-per-component rule enforced.
- Prioritize contrast between:
  - preview panel
  - keyboard backplate
  - keycap

## Phase 4: Behavior regression
- keyboard input actions
- object panel height metrics
- row menu behavior
- tool group menu behavior
- canvas hit-testing
- build-for-testing

---

## 9) Bottom-line diagnosis

- Most components (ObjectPanel, ToolGroupCapsule, floating buttons) are relatively stable.
- The keyboard remains the outlier due to layered container ownership conflict.
- A unified patch should target **ownership simplification first**, not repeated local opacity nudges.
