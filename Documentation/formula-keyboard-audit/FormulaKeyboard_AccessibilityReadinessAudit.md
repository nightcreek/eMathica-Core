# FormulaKeyboard Accessibility Readiness Audit

## Scope And Non-Claims

This audit does not claim that the current keyboard is accessible.

It only answers one question:

Can v1.0 establish stable framework boundaries so that v1.1 can add real accessibility behavior, user research outcomes, and alternative input support without rewriting the keyboard core?

## 1. Readiness Summary

### Current strengths

- Stable key ids already exist.
- Keyboard actions are executable without direct AST mutation in views.
- AST structure, `TemplateKind`, `FieldID`, `EditorCursor`, and `FormulaInsertionID` already preserve strong structural semantics.
- FormulaDisplay already carries cursor, placeholder, insertion, source-path, and field-identity data.

### Current blockers

- Key semantics are mostly leaf-view labels, not framework-level descriptors.
- No keyboard semantic snapshot exists.
- No logical key-focus routing model exists.
- No feedback event model exists.
- No framework-level action result model exists.
- Touch, hardware, and plain text editing still enter the editor through different upstream paths.

## 2. By User-Need Category

### 2.1 Blind and screen-reader users

Current readiness:

- Partial

What exists:

- `MathKeyboardKey.accessibilityLabel`
- SwiftUI button accessibility labels on key views

What is missing:

- stable semantic role separate from spoken label
- current keyboard page/mode snapshot
- action meaning independent of visual glyph
- structural cursor context reporting
- action result / boundary feedback events
- logical focus order independent of view tree

Architectural conclusion:

- The current leaf-label approach is not enough.
- v1.0 must expose semantic metadata and focus routing boundaries at the definition / dispatcher layer, not just SwiftUI labels.

### 2.2 Low-vision, zoom, and high-contrast users

Current readiness:

- Limited foundation only

What exists:

- centralized style tokens in `MathKeyboardStyle`
- formula label rendering already separated from key backgrounds

What is missing:

- dynamic variant sizing
- larger hit-target layout variant
- content complexity aware scaling policy in data
- reduce transparency alternative visuals
- contrast-aware theme boundary
- overflow diagnostics for enlarged variants

Architectural conclusion:

- Style tokens are a start, but current fixed row layout and hardcoded formula metrics would make later large-variant support expensive.

### 2.3 Hearing-impaired users

Current readiness:

- Neutral

Observation:

- The current keyboard does not appear to rely on sound for core operation.
- However, it also lacks a semantic feedback event channel that could support non-audio confirmation strategies consistently.

Architectural conclusion:

- v1.0 should expose feedback events even if no audio behavior is implemented.

### 2.4 Motor-impaired users and imprecise touch

Current readiness:

- Weak

What exists:

- large-ish visual keys
- button-based activation

What is missing:

- configurable repeat thresholds
- non-touch activation path for the same key actions
- long-press alternatives decoupled from raw gestures
- focus-based activation route
- stable logical navigation between keys

Architectural conclusion:

- Current interaction is gesture-first.
- v1.0 must move to action-first behavior with interchangeable activators.

### 2.5 Switch Control and scan-based input

Current readiness:

- Not ready

Reasons:

- no logical focus graph for keys
- no framework-level selectable key ordering
- no action execution model decoupled from touch-driven button hierarchy

Architectural conclusion:

- This capability cannot be added safely from SwiftUI tree order alone.

### 2.6 Voice Control users

Current readiness:

- Not ready

Reasons:

- current labels are not normalized semantic commands
- duplicate or unstable textual labels may exist across pages
- no framework-level action catalog with stable naming

Architectural conclusion:

- v1.0 must preserve stable semantic ids and action identifiers separate from rendered label text.

### 2.7 External keyboard and alternative input device users

Current readiness:

- Better than other categories, but still incomplete

What exists:

- hardware ingress
- semantic mapper
- convergence with `WorkspaceState.handleKeyboardAction`

What is missing:

- convergence before `KeyboardAction`
- unified dispatcher contract with touch keyboard
- shared action-result and feedback channel

Architectural conclusion:

- Good foundation, but not yet a unified accessibility-ready action pipeline.

### 2.8 Cognitive / learning support

Current readiness:

- Not architecturally prepared

Missing capabilities:

- semantic grouping metadata
- alternate presentation strategies
- progressive disclosure model
- explainable action result events

Architectural conclusion:

- Future support needs framework metadata, not just UI decoration.

### 2.9 Reduce Motion / Reduce Transparency / Differentiate Without Color

Current readiness:

- Weak

Reasons:

- press animation is implicit in view state
- material usage is direct
- color still carries category/accent meaning
- no environment-driven fallback policy

Architectural conclusion:

- v1.0 needs environment injection points even if visual adaptations are deferred.

## 3. Semantic Information Source Audit

### 3.1 What semantics currently exist

| Semantic fact | Current source | Stable enough for future reuse |
|---|---|---|
| Key id | `MathKeyboardKey.id` | Yes |
| Key display label | `MathKeyboardLabelDescriptor` | Partially |
| Editor action | `MathKeyboardIntent` / `KeyboardAction` | Yes, but split |
| Template structure | `TemplateKind`, `FieldID`, AST | Yes |
| Cursor structural position | `EditorCursor(path, offset)` | Yes |
| Display insertion semantics | `FormulaInsertionID` | Yes |
| Placeholder source/field | `FormulaDisplayPlaceholderToken` and anchor data | Yes |
| Keyboard page selection | `MathInputKeyboardSurfaceModel.selectedPanelID` | Runtime only |
| Alphabet mode | `alphabetScript`, `letterCase` | Runtime only |
| Key enabled/disabled state | Not modeled | No |
| Key selected/toggled state | Implicit/local only | No |
| Action result / rejection | Derived from editor mutation side effects | No |
| Feedback events | Not modeled | No |

### 3.2 Semantics that are trapped in views today

- pressed state
- tab selection visuals
- alphabet toggle local state transitions
- formula-label fallback rendering
- focus order
- mode restoration after page switches

### 3.3 Why this matters

If semantics remain view-local:

- VoiceOver cannot get stable action meaning from the framework
- Switch Control cannot scan by logical model
- tests cannot replay state transitions without SwiftUI hierarchy
- user research findings would force changes in view code instead of semantic providers

## 4. Mathematical Semantic Tree Readiness

### 4.1 Which layer should own a future math accessibility tree

Recommended owner:

- MathInput AST / editor semantic snapshot layer

Not recommended:

- LaTeX re-parsing
- FormulaDisplay rendered output reverse inference
- SwiftMath display-tree reverse inference

### 4.2 Why not derive from LaTeX or rendered output

- LaTeX export is compatibility/output text, not editing truth.
- FormulaDisplay is a rendering projection with display wrappers and markers.
- Rendered output loses editor-intent boundaries and business semantics such as command results or future selection meaning.

### 4.3 Current readiness in AST and display bridge

Current positive signals:

- `MathNode`
- `TemplateKind`
- `FieldID`
- `EditorCursor(path, offset)`
- `TemplateDefinitionRegistry`
- `FormulaDisplayBridge` preserving `sourcePath`, `fieldIdentity`, cursor and insertion identities

Current missing pieces:

- stable semantic node ids independent of display wrappers
- explicit accessibility snapshot protocol
- explicit cursor-context snapshot API for assistive consumers
- explicit selection-context API

### 4.4 v1.0 interfaces worth reserving

Minimal interface candidates:

- `FormulaKeyboardSemanticSnapshotProviding`
- `FormulaKeySemanticProviding`
- `FormulaKeyboardFocusRouting`
- `FormulaKeyboardFeedbackProviding`

Associated data concepts:

- `FormulaKeyboardStateSnapshot`
- `FormulaKeySemanticDescriptor`
- `FormulaKeyActionResult`
- `FormulaEditorStructuralContext`

These can remain default-empty in v1.0, but their responsibilities should be real:

- describe key identity and role
- describe keyboard page/mode state
- expose editor structural context
- expose action results and feedback events

## 5. Alternative Interaction Path Audit

### 5.1 Current actions that can already cross input methods

- insert character
- insert operator
- insert symbol
- insert function
- insert template
- move left/right/up/down
- tab / shift-tab
- delete backward / forward
- submit / cancel

### 5.2 Current actions that are not yet framework-addressable

- page switch
- alphabet case toggle
- alphabet script toggle
- any future long-press alternates
- repeat / hold acceleration

### 5.3 Architecture risk

Any operation that depends on:

- a specific gesture
- a specific view tree
- a specific screen location

is a structural accessibility risk.

Current risk items:

- page/mode toggles are local UI state
- no alternate activator contract for press-and-hold behaviors
- key focus traversal is not modeled

## 6. Focus And Navigation Readiness

### 6.1 Current focus reality

Current explicit focus model:

- `WorkspaceFocus.none`
- `WorkspaceFocus.formulaEditor`
- `WorkspaceFocus.canvas`

This is editor-level focus, not keyboard-key focus.

### 6.2 Missing focus concepts

- key focus graph
- logical next/previous focus order per page
- focus restoration after page switch
- focus ownership for alternate panels
- logical key grouping
- disabled-key focus policy

### 6.3 Consequence

v1.1 cannot safely define keyboard accessibility focus behavior unless v1.0 first preserves:

- stable page ids
- stable key ids
- logical order metadata
- focus-routing protocol boundary

## 7. Feedback Channel Readiness

### 7.1 Current feedback channels are mostly visual/stateful

Current user-visible feedback is mainly:

- key press animation
- formula preview updates
- cursor movement
- page content changes
- commit error banner at Workspace level

### 7.2 Missing framework events

- key activation acknowledged
- action rejected
- structure entry / exit
- repeat started / stopped
- page changed
- mode changed
- alternate menu opened / closed

### 7.3 Recommendation

Reserve a small framework event layer:

- `FormulaKeyboardFeedbackEvent`
- `FormulaKeyActionResult`
- `FormulaKeyboardStateSnapshot`

without claiming any final spoken/haptic/visual behavior yet.

## 8. System Preference And Visual Adaptation Readiness

### 8.1 Current foundation

- centralized style tokens
- formula/content/background separation

### 8.2 Current blockers

- fixed row height
- view-embedded fonts
- direct material usage
- no dynamic-type aware layout variants
- no explicit contrast policy
- no reduce-motion environment boundary

### 8.3 v1.0 reserve points

- keyboard environment values
- metrics variant selection
- renderer policy hooks
- interaction policy hooks

## 9. Accessibility Test Insertion Points

### 9.1 What the framework should support in v1.0

- stable state snapshots
- replayable key actions
- semantic provider replacement
- focus router replacement
- feedback provider replacement
- deterministic layout definitions

### 9.2 What should remain research-driven in v1.1

- spoken math phrasing
- screen-reader navigation granularity
- switch-control scan order policy
- voice-control naming policy
- low-vision variant tuning
- structural traversal wording

These should not be frozen in v1.0 code before real user validation.

## 10. Accessibility Readiness Verdict

### Ready enough to preserve now

- stable ids
- structural AST and cursor context
- action execution boundary potential
- display anchor/source-path infrastructure

### Must be added in v1.0 to avoid a re-architecture in v1.1

- semantic descriptor boundary
- keyboard state snapshot boundary
- focus routing boundary
- feedback event boundary
- environment / preference injection boundary
- one unified dispatcher contract for touch, hardware, and future assistive activators

### Cannot be claimed yet

- full screen-reader support
- full keyboard accessibility
- low-vision optimized layouts
- switch-control support
- final focus order
- final spoken math semantics
