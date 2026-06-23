# PlaneVisualAudit-Keyboard-1

## Scope

- This audit is **read-only** for production Swift code.
- No behavior/semantic/layout logic changes were applied.
- Target: understand keyboard visual stacking and why repeated tuning still yields:
  - unclear backplate
  - keys not visually translucent enough
  - occasional double-glass feeling
  - weak refraction/frost separation

---

## Files Audited

- `eMathica/WorkspaceKit/Keyboard/MathKeyboardView.swift`
- `eMathica/WorkspaceKit/Keyboard/FormulaEditorView.swift`
- `eMathica/WorkspaceKit/Keyboard/FormulaInputState.swift`
- `eMathica/WorkspaceKit/WorkspaceView.swift`
- `eMathica/WorkspaceKit/Shared/LiquidGlassPanel.swift`
- `eMathica/WorkspaceKit/Shared/GlassComponents.swift`
- `eMathica/WorkspaceKit/Shared/WorkspaceTheme.swift`
- `eMathica/WorkspaceKit/ObjectPanel/AlgebraObjectPanelView.swift`
- `eMathica/WorkspaceKit/ObjectPanel/WorkspaceObjectRowView.swift`
- `eMathica/WorkspaceKit/Toolbar/ToolGroupCapsuleView.swift`

---

## Actual Layer Stack (Bottom -> Top)

### Layer 0: Plane canvas / graph
- Source: Plane canvas module beneath `WorkspaceInlineInputDock`.
- Visual role: graph/grid lines are visible through translucent UI.

### Layer 1: Keyboard dock panel wrapper (`WorkspaceView.keyboardPanel`)
- Source: `WorkspaceView.swift` `keyboardPanel`.
- Applies:
  - `.padding(10)`
  - `.frame(height: 236)`
  - `.background(keyboardBackplateFill)` where dark=0.02, light=0.03
  - `.overlay(top hairline)`
  - `.clipShape(RoundedRectangle(cornerRadius: 16))`
- Coverage:
  - Covers the whole keyboard panel area in dock.
  - Does **not** cover preview panel.
- Notes:
  - Weak but still an extra plate behind `MathKeyboardView`.

### Layer 2: Keyboard outer glass container (`KeyboardGlassPanel`)
- Source: `MathKeyboardView.swift` `KeyboardGlassPanel`.
- Applies:
  - `content.padding(8)`
  - `.background(containerFill)` dark=0.025, light=0.05
  - overlay fill (dark 0.01 / light 0.02)
  - stroke (dark 0.04 / light 0.08)
  - top highlight overlay
  - shadow (dark 0.05 / light 0.03)
  - clip shape radius 18
- Coverage:
  - Covers tab row + keys area.
- Notes:
  - This is a second container-like glass layer above dock wrapper.

### Layer 3: Keyboard keys backplate (`KeyboardKeysBackplate`)
- Source: `MathKeyboardView.swift` `KeyboardKeysBackplate`.
- Applies:
  - RoundedRectangle fill (dark=0.28, light=0.36)
  - material overlay `.fill(.thinMaterial).opacity(dark 0.30 / light 0.26)`
  - stroke (dark 0.18 / light 0.46)
  - top highlight gradient
  - shadow (dark 0.26 r16 y5 / light 0.12)
  - `allowsHitTesting(false)`
- Placement:
  - Added as `.background` of `VStack(spacing: 8)` that contains **tab row + keys rows**.
  - It is inside `KeyboardGlassPanel`.
- Notes:
  - Intended primary support plate.

### Layer 4: Category row keycaps
- Source: `KeyboardTabButton` -> `LiquidGlassKeyBackground(role: .category/.categoryActive)`.
- Applies per tab:
  - fill
  - top highlight overlay
  - stroke
  - shadow

### Layer 5: Normal keycaps
- Source: `GlassKeyButton` -> `LiquidGlassKeyBackground(role: .normal/.primary)`.
- Applies per key:
  - fill
  - top highlight overlay
  - stroke
  - shadow

### Layer 6: Key labels/icons
- Source: `Text(title)`, optional subtitle.
- No separate glass background.

---

## Preview Panel Stack (separate from keyboard)

### Preview panel (`WorkspaceInlineInputDock.editorBar`)
- Source: `WorkspaceView.swift` `editorBar` background.
- Uses:
  - `GlassPanel(cornerRadius: 18, theme: inputBarTheme)` -> `LiquidGlassPanel`
  - plus extra top highlight overlay in `WorkspaceView`
- `inputBarTheme` values:
  - dark panel opacity = 0.20
  - light panel opacity = 0.24
  - dark stroke opacity = 0.10
  - light stroke opacity = 0.13
  - dark shadow opacity = 0.10
  - light shadow opacity = 0.04

Result: preview panel is a distinct glass block, but composition differs from keyboard backplate logic.

---

## Object Panel / Toolbar (for consistency audit)

### Object panel container
- Source: `AlgebraObjectPanelView` with `LiquidGlassPanel(theme: objectPanelTheme)`.
- Current dark panel opacity: 0.18.

### Object row
- Source: `WorkspaceObjectRowView`.
- Unselected dark fill: 0.035.
- Selected dark fill: accent 0.22.

### Tool group capsule
- Source: `ToolGroupCapsuleView` + `LiquidGlassPanel`.
- Dark panel opacity: 0.18.
- Active accent capsule fill (dark): 0.28.

---

## Why visual issues persist

### 1) Backplate support can still feel ambiguous
Root causes:
- There are **two container plates** above canvas before keycaps:
  1. dock wrapper background (`keyboardPanel` in `WorkspaceView`)
  2. `KeyboardGlassPanel` container in `MathKeyboardView`
- Then a third intended support layer (`KeyboardKeysBackplate`) is inside.
- This multi-container stacking softens edge contrast and can make the “real support plate” visually unclear.

### 2) “Double glass” risk source
The following layers all contribute plate-like glass:
- `WorkspaceView.keyboardPanel` background + clip
- `KeyboardGlassPanel` background + stroke + highlight + shadow
- `KeyboardKeysBackplate` full glass treatment

Even if each is mild, together they can read as duplicated structure.

### 3) Key quality instability perception
Keycaps themselves are structurally simple and translucent, but perception varies because:
- they sit on top of multiple semi-dark plates,
- background contrast is shaped more by container stacking than by keycaps alone.

### 4) Preview vs keyboard imbalance
- Preview panel uses dedicated `GlassPanel/LiquidGlassPanel` theme with stronger coherent panel identity.
- Keyboard area currently mixes wrapper fill + container glass + backplate glass.
- Different style systems make them feel mismatched.

---

## Tree Diagram

```text
WorkspaceInlineInputDock
├─ editorBar (PreviewPanel)
│  ├─ GlassPanel(theme: inputBarTheme)
│  │  ├─ LiquidGlassPanel.panelBackground (glass/material path)
│  │  ├─ stroke
│  │  ├─ highlight overlay
│  │  └─ shadow
│  └─ icon-only buttons (press circle only)
└─ keyboardPanel
   ├─ panel background fill (keyboardBackplateFill in WorkspaceView)
   ├─ top hairline overlay
   └─ MathKeyboardView
      └─ KeyboardGlassPanel
         ├─ container fill
         ├─ stroke
         ├─ top highlight
         ├─ shadow
         └─ content VStack(tab + rows)
            ├─ KeyboardKeysBackplate
            │  ├─ fill
            │  ├─ thinMaterial overlay
            │  ├─ stroke
            │  ├─ top highlight
            │  └─ shadow
            ├─ CategoryRow (tab keycaps)
            │  └─ LiquidGlassKeyBackground(category)
            └─ KeyGrid
               └─ KeyCell
                  ├─ LiquidGlassKeyBackground(normal/primary)
                  └─ key label/icon
```

---

## Current Visual Parameter Table

| Component | Fill | Material | Stroke | Shadow | Notes |
|---|---|---|---|---|---|
| PreviewPanel | dark 0.20 / light 0.24 (`inputBarTheme`) | via `LiquidGlassPanel` background path | dark 0.10 / light 0.13 | dark 0.10 / light 0.04 | plus extra top highlight overlay in `WorkspaceView` |
| Keyboard dock wrapper (`keyboardPanel`) | dark 0.02 / light 0.03 | none | top hairline only | none explicit | extra base plate under keyboard |
| KeyboardGlassPanel | dark 0.025 / light 0.05 + overlay 0.01/0.02 | none explicit | dark 0.04 / light 0.08 | dark 0.05 / light 0.03 | another container plate |
| KeyboardKeysBackplate | dark 0.28 / light 0.36 | `.thinMaterial` overlay (dark 0.30 / light 0.26) | dark 0.18 / light 0.46 | dark 0.26 / light 0.12 | intended main support |
| CategoryTab inactive key | dark 0.05 / light 0.28 | none | dark 0.13 / light 0.26 | dark 0.08 / light 0.06 | per-keycap |
| CategoryTab active key | accent dark 0.28 / light 0.28 | none | dark 0.18 / light 0.34 | dark 0.08 / light 0.06 | per-keycap |
| NormalKey | dark 0.065 / light 0.30 | none | dark 0.14 / light 0.32 | dark 0.08 / light 0.06 | per-keycap |
| PrimaryKey | accent dark 0.32 / light 0.32 | none | dark 0.19 / light 0.36 | dark 0.08 / light 0.06 | per-keycap |
| ObjectPanel | dark 0.18 / light 0.30 (`objectPanelTheme`) | via `LiquidGlassPanel` | dark 0.12 / light 0.12 | dark 0.08 / light 0.035 | independent glass system |

---

## Recommended Target Structure (do not execute in this audit)

Keep only three major visual layers for keyboard:

1. `PreviewPanel glass` (independent)
2. `KeyboardBackplate glass` (single clear support for tab+rows)
3. `Key translucent keycaps` (category + normal + primary)

Remove/reduce duplicates:
- drop or near-zero one of:
  - `WorkspaceView.keyboardPanel` base fill
  - `KeyboardGlassPanel` container plate
- keep only one true keyboard support plate (`KeyboardKeysBackplate`).

---

## Recommended Patch Plan (next step, not applied)

1. **Reduce duplicate container layer**
   - Make `WorkspaceView.keyboardPanel` background fully clear (or near 0).
   - Keep only structural clip if needed.

2. **Keep `KeyboardKeysBackplate` as the single support plate**
   - Maintain its full glass definition and coverage for tab + rows.

3. **Convert `KeyboardGlassPanel` to lightweight wrapper**
   - Keep padding only; remove/near-zero fill/stroke/shadow to avoid second plate identity.

4. **Unify tokens**
   - Move keyboard panel values to one token group:
     - `keyboardSupport*`
     - `keyboardKey*`
     - `previewPanel*`
   - Prevent drift and repeated conflicting tweaks.

5. **Regression checks**
   - Keyboard actions unchanged.
   - Hit areas unchanged.
   - Preview panel remains independent.
   - No layout changes.

---

## Audit conclusion

- The main root cause is **not a single opacity value**, but **overlapping container-level glass layers** around the keyboard.
- Backplate clarity and key translucency are being judged through multiple stacked plates, causing unstable perception.
- Next patch should simplify layer ownership first, then fine-tune opacities.
