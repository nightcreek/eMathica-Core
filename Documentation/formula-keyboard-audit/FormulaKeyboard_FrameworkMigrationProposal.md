# FormulaKeyboard Framework Migration Proposal

## 1. Recommendation Summary

Recommended strategy:

- rapid vertical replacement with a short transitional bridge

Not recommended:

- long-lived dual architecture
- indefinite strangler pattern

Reason:

- the current keyboard scope is modest enough to replace
- definition, rendering, behavior, and dispatch are tightly coupled today
- keeping both systems alive would preserve exactly the technical debt that blocks v1.1 accessibility work

## 2. Target Architecture Restated

Target pipeline:

`Builtin Keyboard Definition`
-> `FormulaKeyDefinition`
-> `Validation`
-> `Layout Engine`
-> `Renderer`
-> `Interaction / Behavior`
-> `FormulaKeyAction`
-> `Dispatcher`
-> `MathInput Command Boundary`
-> `MathInput Editor / AST`

## 3. Gap Analysis

| Target layer | Current equivalent | Keep | Migrate | Rewrite | Missing |
|---|---|---|---|---|---|
| Definition | `MathKeyboardLayout`, `MathInputKeyboardSurfaceModel` | ids, basic content ideas | panels, keys, alphabet modes | split authority | yes |
| Validation | tests only | some invariants | key-id checks | add validator | yes |
| Layout | `MathInputKeyboardPanelView` row weights | weight concept | row data | view-driven layout | yes |
| Environment | `MathKeyboardStyle`, outer Workspace focus/platform state | style tokens | system prefs, platform flags | mixed ownership | yes |
| Metrics | `MathKeyboardStyle.spacing`, `MathInputKeyboardStyleBridge.formulaLayoutMetrics` | token families | formula/key metrics | role-heuristic metrics | yes |
| Rendering | `MathInputKeyboardLabelView`, `MathKeyboardFormulaLabelView` | content layering idea | formula/text/icon split | probe+render double parse | keyboard renderer abstraction |
| Interaction | `Button`, `DragGesture`, local toggles | activation basics | pressed state | ad hoc gestures | press session |
| Behavior | `WorkspaceState`, `InputController`, local surface toggles | action semantics | editor mutations | split behavior ownership | behavior state machine |
| Animation | local scaleEffect, disabled transactions | simple press affordance | animation tokens | implicit view animation | policy layer |
| Dispatcher | `WorkspaceState.handleKeyboardAction` | core editor dispatch point | bridge into new key actions | touch/hardware entry mismatch | framework dispatcher |
| Serialization | code-built layouts and keys | ids | schema concepts | non-Codable key model | versioned schema |
| Diagnostics | unit tests, debug fallback text | tests | runtime checks | ad hoc | dedicated diagnostics |
| Accessibility Boundary | leaf `accessibilityLabel` only | stable ids | AST/path/anchor metadata | label-only design | semantic snapshot, focus router, feedback provider |

## 4. Why Rapid Replacement Beats Long Parallel Migration

### Option A: short-term parallel migration

Benefits:

- lower immediate disruption
- easier side-by-side comparison

Costs:

- two definition systems
- two rendering systems
- two behavior systems
- two dispatcher paths
- delayed legacy deletion
- higher risk of accessibility-ready abstractions being postponed

### Option B: vertical replacement with short bridge

Benefits:

- one authoritative definition model early
- one dispatcher contract early
- one renderer boundary early
- fewer duplicate semantics
- accessibility hooks land in the real framework, not an adapter

Costs:

- requires a decisive migration plan
- forces schema/validation work earlier

### Recommendation

Choose Option B.

Use transitional adapters only for:

- existing `KeyboardAction` bridging
- temporary mapping from legacy built-in layout data into new schema during rollout

Delete those adapters by Phase 9 at the latest.

## 5. Proposed Framework Shape

Suggested package / target split:

- `FormulaKeyboardCore`
- `FormulaKeyboardRendering`
- `FormulaKeyboardSwiftUI`
- optional `FormulaKeyboardDiagnostics`

If package creation is deferred, the same boundaries should still be represented internally:

- Definition
- Validation
- Layout
- Environment
- Metrics
- Rendering
- Interaction
- Behavior
- Dispatcher
- Serialization
- Diagnostics
- Accessibility Boundary

## 6. Proposed Core Models

### 6.1 Definition layer

- `FormulaKeyboardDefinition`
- `FormulaKeyboardPageDefinition`
- `FormulaKeyDefinition`
- `FormulaKeyID`
- `FormulaKeyRole`
- `FormulaKeyContent`
- `FormulaKeyPlacement`
- `FormulaKeySize`
- `FormulaKeyBehavior`
- `FormulaKeyAction`

### 6.2 Content layer

- `.latex(String)`
- `.text(String)`
- `.symbol(String)`
- `.systemIcon(FormulaKeyIconID)`

### 6.3 Dispatcher layer

- `FormulaKeyboardDispatcher`
- `FormulaKeyAction`
- `FormulaKeyActionResult`

### 6.4 Accessibility boundary layer

- `FormulaKeySemanticDescriptor`
- `FormulaKeyboardStateSnapshot`
- `FormulaKeyboardSemanticSnapshotProviding`
- `FormulaKeyboardFocusRouting`
- `FormulaKeyboardFeedbackProviding`

## 7. What Must Stay Outside The Keyboard Framework

Do not let the new framework own:

- MathInput AST mutation logic
- FormulaDisplay rendering internals
- Workspace document commits
- semantic graph classification
- object panel business logic

The framework should stop at:

- definition
- action generation
- dispatch boundary
- keyboard-local rendering / behavior / diagnostics / semantics

## 8. Cross-Module RFC Candidates

### RFC-01: MathInput command boundary normalization

Problem:

- production touch and hardware paths converge at `KeyboardAction`, while public token APIs exist separately

Why keyboard alone cannot solve it:

- `InputController`, `MathInputSession`, and Workspace dispatch own the editor mutation contract

Smallest interface change:

- define one public editor command boundary that both keyboard framework and non-keyboard inputs can target

Affected modules:

- `EMathicaMathInputCore`
- `EMathicaWorkspaceKit`

Must for v1.0:

- yes, if the framework is to unify touch and hardware cleanly

### RFC-02: FormulaDisplay prepared label rendering boundary

Problem:

- keyboard formula labels are probed and reparsed in view lifecycle

Why keyboard alone cannot solve it:

- current parser/probe/snapshot ownership sits in FormulaDisplay

Smallest interface change:

- allow prepared/static key-content rendering input or caching boundary

Affected modules:

- `EMathicaFormulaDisplayKit`
- keyboard renderer layer

Must for v1.0:

- should, because it affects renderer architecture and performance

### RFC-03: Structural semantic snapshot boundary

Problem:

- accessibility-ready math semantics should come from AST/cursor/display bridge, not from key views

Why keyboard alone cannot solve it:

- keyboard needs editor structural context owned by MathInput / projection layers

Smallest interface change:

- read-only structural context snapshot API

Affected modules:

- `EMathicaMathInputCore`
- possibly `EMathicaFormulaDisplayKit`

Must for v1.0:

- boundary should be reserved in v1.0
- implementation depth can wait for v1.1 research

### RFC-04: Workspace input hosting boundary

Problem:

- hardware ingress, formula preview, interaction overlay, and editor focus are mounted in Workspace-specific view layers

Why keyboard alone cannot solve it:

- keyboard framework cannot own Workspace responder lifecycle

Smallest interface change:

- a host protocol or environment contract for focus, key forwarding, and keyboard visibility state

Affected modules:

- `EMathicaWorkspaceKit`

Must for v1.0:

- yes, for framework adoption without view-level leakage

## 9. Legacy Deletion Strategy

### Delete by latest Phase 9

- `Legacy/Keyboard/MathKeyboardView.swift`
- `Legacy/Keyboard/KeyboardKey.swift`
- `Legacy/Keyboard/WorkspaceMathKeyboardAdapter.swift`
- `Legacy/Keyboard/MathKeyboardLayout.swift`

### Delete earlier if possible

- id-suffix-based accent heuristics
- direct-action template exceptions
- empty static alphabet panel plus runtime replacement split

## 10. Recommended Migration Guardrails

- No long-term dual keyboard surfaces.
- No new production callers of legacy keyboard types.
- No new built-in keys added outside the new definition system once Phase 1 starts.
- No View should call AST mutation directly.
- No accessibility semantics should be hard-coded into one SwiftUI leaf view as the only source of truth.

## 11. Final Proposal

Build a new Formula Keyboard Framework around:

- pure definition data
- strict validation
- a real layout engine
- prepared-content rendering
- one dispatcher contract
- one behavior state machine
- one semantic/focus/feedback boundary for future accessibility

Adopt it quickly for the builtin keyboard, then delete legacy rather than preserving a long hybrid period.
