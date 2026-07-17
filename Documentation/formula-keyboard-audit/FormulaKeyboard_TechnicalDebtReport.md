# FormulaKeyboard Technical Debt Report

## Classification Rules

- Critical: blocks the target framework architecture or future accessibility integration boundary.
- Major: causes duplicated semantics, inconsistent behavior, or migration drag.
- Minor: localized cleanup that can wait until after the core framework cutover.

## Critical

| ID | Title | Module / file | Current behavior | Root cause | v1.0 framework impact | v1.1 accessibility impact | Suggested phase | Temporary compatibility | Legacy delete condition |
|---|---|---|---|---|---|---|---|---|---|
| FK-C01 | Definition and runtime surface split | `MathKeyboardLayout.swift`, `MathInputKeyboardSurfaceModel.swift` | Keyboard pages are partly static, partly runtime-generated; alphabet panel rows are empty in the static schema | No single authoritative definition layer | Prevents a pure declarative `FormulaKeyDefinition` model | Focus order, semantics, and testing cannot rely on one stable source | Phase 1-3 | Short-lived adapter only | Remove when all panels come from one definition source |
| FK-C02 | Touch and hardware converge too late | `MathInputKeyboardView.swift`, `HardwareKeyboardCaptureView.swift`, `WorkspaceState.swift` | Touch path starts from key definitions, hardware path starts from UIKit ingress, both converge only at `KeyboardAction` | No unified keyboard dispatcher boundary | Blocks unified framework dispatcher and diagnostics | Alternative input cannot reuse a stable action pipeline without duplicating semantics | Phase 6 | No long-term compatibility | Remove when all keyboard ingress emits one `FormulaKeyAction` contract |
| FK-C03 | No validation layer | `MathKeyboardLayout.swift`, tests only | Invalid ids, overlaps, unsupported content, missing metadata are prevented only by tests and convention | No schema or validator target | Prevents trustworthy data-driven migration | Accessibility metadata cannot be guaranteed complete | Phase 2 | None | Remove when validator runs on every built-in definition |
| FK-C04 | Renderer parses static labels repeatedly | `MathKeyboardFormulaLabelView.swift`, `FormulaDisplayView.swift` | Formula labels are probed and then rendered again | Renderer boundary is view-driven rather than prepared-content-driven | Costs performance and couples rendering to SwiftUI lifecycle | Future semantic overlays or larger accessibility variants would amplify repeated parsing cost | Phase 4 | Short-lived adapter allowed | Remove when renderer consumes prepared content once per definition state |
| FK-C05 | Behavior tied to View gestures | `MathInputKeyboardKeyView.swift`, `MathInputKeyboardSurfaceModel.swift` | Press, toggle, submit, move, delete all rely on ad hoc Button / DragGesture behavior | No press-session state machine | Blocks unified behavior layer | VoiceOver, Switch Control, alternate activators cannot trigger identical behavior semantics | Phase 5-6 | None | Remove when all key activation paths go through behavior state machine |
| FK-C06 | Accessibility semantics are reduced to one label string | `MathKeyboardKey.swift`, keyboard view files | Only `accessibilityLabel` is stored per key; no role, page, state, feedback, or action result model | Accessibility was added at the leaf-view level | Framework cannot expose stable semantic snapshots | v1.1 would be forced to retrofit semantics into visual code | Phase 1 and Phase 7 | Default no-op semantic provider allowed | Remove when semantic metadata exists independently from SwiftUI labels |

## Major

| ID | Title | Module / file | Current behavior | Root cause | v1.0 impact | v1.1 accessibility impact | Suggested phase | Temporary compatibility | Legacy delete condition |
|---|---|---|---|---|---|---|---|---|---|
| FK-M01 | Legacy keyboard remains structurally alive | `Legacy/Keyboard/*` | Deprecated views and adapters still exist and are regression-tested for presence | Transitional isolation chosen instead of immediate deletion | Adds migration drag and duplicate concepts | Confuses future focus/semantic routing ownership | Phase 8-9 | Yes, until replacement passes acceptance | Delete after new framework covers all builtin pages and no caller remains |
| FK-M02 | Direct-action template exceptions | `MathKeyboardLayout.swift` | Parametric and piecewise keys bypass token vocabulary with `.action(.insertTemplate(...))` | Token set is narrower than real keyboard needs | Prevents clean definition schema | Future semantics cannot classify all template keys uniformly | Phase 1 | Short-lived adapter okay | Delete when every template is represented by stable template IDs |
| FK-M03 | Role inference by label type and id suffix | `MathInputKeyboardStyleBridge.swift` | Visual role is guessed from `.formula/.symbol/.systemIcon` and key id suffix | No explicit key role model | Weakens theming and diagnostics | Makes semantics/focus hints fragile | Phase 1 and Phase 4 | None | Delete when role is an explicit field in definition |
| FK-M04 | No stable key-focus routing model | `MathInputKeyboardView.swift`, `MathInputKeyboardPanelView.swift` | Focus order is implicit in SwiftUI tree order and runtime alphabet mutations | No logical navigation graph | Blocks future keyboard focus router | VoiceOver/Switch Control/navigation ordering cannot be tested logically | Phase 7 | No | Delete when focus graph is definition-driven |
| FK-M05 | Plain text editing is a parallel mutation path | `MathPlainTextField.swift`, `WorkspaceState.dispatch(.updateInputText)` | Source text diffing can mutate editor state outside keyboard definition pipeline | Text-field compatibility path pre-dates unified action boundary | Harder to reason about one keyboard command model | Assistive input and external devices may diverge from touch semantics | RFC candidate after Phase 6 | Yes | Remove only if text path is re-based on same action boundary or intentionally isolated |
| FK-M06 | Package documentation no longer matches runtime | `EMathicaMathInputKit/README.md`, `Architecture.md` | Docs still say `EMathicaMathInputUI` is placeholder-only | Implementation outgrew package docs | Creates migration confusion | Accessibility planning can start from false ownership assumptions | Post-audit docs update | Yes | Delete debt when package docs reflect real ownership |
| FK-M07 | No keyboard diagnostics surface | Current keyboard has tests but no built-in runtime validation/inspection | Debugging requires source reading and ad hoc tests | No diagnostics module | Weakens migration safety | Makes accessibility readiness checks non-repeatable | Phase 2 | None | Delete when diagnostics can inspect definitions, layout, actions, and semantic metadata |
| FK-M08 | Local toggle state is not action-addressable | `MathInputKeyboardSurfaceModel.swift` | case/script toggles mutate local state and emit no framework action | UI-local state ownership | Prevents complete replay/automation | Voice Control and automated a11y tests cannot invoke the same toggle contract | Phase 1 and Phase 6 | None | Delete when toggle state is represented in keyboard environment/dispatcher |

## Minor

| ID | Title | Module / file | Current behavior | Root cause | Suggested phase |
|---|---|---|---|---|---|
| FK-N01 | Tab titles use plain `Text` directly | `MathInputKeyboardView.swift` | Page chrome bypasses a content descriptor model | UI built before full framework model | Phase 4 |
| FK-N02 | Legacy visual metrics duplicate ThemeKit extraction | `MathKeyboardVisualMetrics.swift` | Legacy layer re-wraps style tokens into CG values | Legacy surface isolation | Phase 9 |
| FK-N03 | Formula key sizing is weight-only | `MathInputKeyboardPanelView.swift` | Width variants are limited to weight multipliers | No explicit placement/span model | Phase 3 |
| FK-N04 | Accessibility labels mix product language and fallback glyph names | `MathKeyboardLayout.swift`, `MathInputKeyboardSurfaceModel.swift` | Labels are handwritten and inconsistent | No semantic provider boundary | Phase 7 |
| FK-N05 | Debug fallback rendering is embedded in view | `MathKeyboardFormulaLabelView.swift` | Release falls back to text, debug prints key/markup/message inside button | No diagnostics surface | Phase 2 / 4 |

## Legacy Removal Conditions

### Legacy keyboard files

- Latest removal phase: Phase 9
- Removal condition:
  - all builtin pages migrated into new definition framework
  - no production caller of `MathKeyboardView`
  - no production caller of `WorkspaceMathKeyboardAdapter`
  - workspace regression tests updated to assert absence rather than isolation

### Transitional key-intent bridges

- Latest removal phase: Phase 8
- Removal condition:
  - no key definition emits direct `.action(.insertTemplate(...))` for cases representable by schema
  - all touch and hardware inputs enter the same framework dispatcher contract

### View-local behavior logic

- Latest removal phase: Phase 6
- Removal condition:
  - repeat, long press, cancel, toggle, submit, delete all flow through behavior state machine
  - `MathInputKeyboardKeyView` no longer decides business behavior beyond reporting pointer state

## Top Debt Summary

### Highest-risk debt cluster

The highest-risk cluster is the combination of:

- split definition authority
- late convergence of touch and hardware input
- missing validation
- view-owned behavior
- missing semantic/action/focus boundary for accessibility

This cluster is exactly what would force a second framework rewrite during v1.1 if left in place.
