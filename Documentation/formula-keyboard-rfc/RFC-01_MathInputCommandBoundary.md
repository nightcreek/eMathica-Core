# RFC-01: MathInput Command Boundary Normalization

## Context

Today the production touch keyboard and hardware keyboard eventually converge inside:

- `WorkspaceState.handleKeyboardAction(_:)`

But the contracts above that point are still mixed:

- `MathKeyboardIntent`
- `MathInputToken`
- `KeyboardAction`
- hardware descriptors mapped directly to `MathKeyboardIntent`
- local keyboard page/case/script state that does not produce editor actions

This is enough for the current keyboard, but it is not a stable long-term boundary for a framework that must unify touch, hardware, tests, and future assistive activation paths.

## Problem

We need to freeze:

- the authoritative keyboard action type
- the authoritative editor command type
- where their conversion happens
- how keyboard-local actions are separated from editor mutations
- how results and feedback flow back out

## Decision

The authoritative keyboard contract will be:

- `FormulaKeyAction`

owned by:

- `EMathicaFormulaKeyboardCore`

The authoritative editor mutation contract will be a future MathInput-side type:

- `MathInputEditorCommand`

owned by:

- `EMathicaMathInputCore`

`KeyboardAction` and `MathInputToken` are transitional compatibility types, not the long-term authority.

Conversion from `FormulaKeyAction` to `MathInputEditorCommand` is owned by:

- `EMathicaWorkspaceKit`

specifically by the keyboard host / dispatcher implementation layer, not by keyboard core and not by the app target.

## Alternatives Considered

### Alternative A: treat `KeyboardAction` as the final unified action type

Why rejected:

- it is already editor-biased
- it mixes keyboard-local concerns and editor mutation concerns
- it is not designed as a reusable framework action vocabulary
- it would keep the new framework logically inside `WorkspaceKit` and `MathInputKit`

### Alternative B: keep `MathInputToken` as the main authority

Why rejected:

- tokens do not cover the full keyboard domain
- direction navigation, submit, cancel, toggle/page actions, and host-level outcomes do not fit naturally
- it conflates textual input vocabulary with keyboard framework behavior

### Alternative C: convert `FormulaKeyAction` directly to AST mutation in views

Why rejected:

- breaks the dispatcher boundary
- prevents replay/testing through one shared action pipeline
- would repeat current coupling under a new name

## Rejected Alternatives

Explicitly rejected:

- `FormulaKeyAction -> KeyboardAction` as the permanent architecture
- app-side translators from touch/hardware events directly into editor mutations
- a keyboard core that knows about `WorkspaceState`

## SharedLibraries Ownership

### `EMathicaFormulaKeyboardCore`

Owns:

- `FormulaKeyAction`
- `FormulaKeyActionResult`
- keyboard-local action categories
- action metadata and diagnostics

### `EMathicaMathInputCore`

Owns:

- `MathInputEditorCommand`
- editor mutation semantics
- AST and cursor mutation rules

### `EMathicaWorkspaceKit`

Owns:

- host dispatcher implementation
- conversion from keyboard actions to editor commands
- delivery into current editing session
- host-origin action result and feedback propagation

## Package / Target Placement

- `FormulaKeyAction`: `EMathicaFormulaKeyboardCore`
- `FormulaKeyActionResult`: `EMathicaFormulaKeyboardCore`
- `MathInputEditorCommand`: future addition in `EMathicaMathInputCore`
- translator / dispatcher implementation: `EMathicaWorkspaceKit`

## Public API Surface

Public:

- `FormulaKeyAction`
- `FormulaKeyActionResult`
- `FormulaKeyboardDispatcher` protocol
- `FormulaKeyboardHost` dispatch entrypoint
- `MathInputEditorCommand` once introduced

Package/internal:

- transitional bridge from `FormulaKeyAction` to current `KeyboardAction`
- local normalization helpers
- Workspace session writeback details

## Dependency Direction

Allowed:

- `EMathicaWorkspaceKit` depends on both keyboard core and MathInput core
- keyboard core depends on neither workspace nor MathInput
- app depends on workspace only

Forbidden:

- keyboard core depending on editor command implementation
- MathInput core depending on keyboard SwiftUI or host logic

## App Boundary

The app target must never directly emit editor commands.

The app may:

- trigger app-level flows that mount a keyboard
- observe action results surfaced by `WorkspaceKit`

The app may not:

- translate touch or hardware gestures into `MathInputEditorCommand`
- own the keyboard-to-editor command translator

## Detailed Action Split

### Keyboard-domain actions

Examples:

- select page
- toggle alphabet script
- toggle uppercase/lowercase
- request alternate panel
- invoke long-press alternate chooser

These are handled inside keyboard state / host layers and do not become editor commands.

### Editor-domain actions

Examples:

- insert symbol
- insert operator
- insert template
- move cursor
- delete backward
- delete forward
- submit
- cancel editing session if the product defines it as editor-related

These must pass through the translator into `MathInputEditorCommand`.

### Host-domain actions

Examples:

- dismiss keyboard chrome
- restore focus
- trigger haptic/audio/feedback surface
- report rejected action or boundary hit

These are resolved by the host and may produce `FormulaKeyActionResult` without mutating AST.

## Plain-Text Editing Path

Decision:

- do not make plain-text editing the authority for the framework

In v1.0:

- plain-text editing remains an explicitly isolated ingress
- it may adapt into the same editor-command boundary later
- it must not force the keyboard framework to reuse `MathInputToken` as its permanent action type

This path should be reviewed again in Phase 6, not before.

## Action Result Model

`FormulaKeyActionResult` must represent at least:

- performed
- no-op
- rejected
- state-only change
- host feedback event emission

Recommended shape:

- synchronous result in v1.0
- `Sendable`
- optionally future-extendable to async dispatch without changing the action contract

This avoids over-committing to async behavior before a real need exists.

## Accessibility Readiness Impact

This decision is required so that:

- VoiceOver activation
- Switch Control
- hardware keyboard
- test drivers
- future alternative input devices

can all emit the same `FormulaKeyAction` contract.

Without this separation, accessibility work would be forced to target multiple upstream action vocabularies.

## Testing Impact

Tests should be layered as:

- keyboard-core action tests
- translator tests in `WorkspaceKit`
- MathInput editor command tests in `MathInputKit`
- integration tests from action to resulting editor state

This is a cleaner split than current tests that mix `MathKeyboardIntent`, `KeyboardAction`, and session state.

## Compatibility Window

Temporary adapters allowed:

- `MathKeyboardIntent` -> `FormulaKeyAction`
- `FormulaKeyAction` -> current `KeyboardAction`
- `KeyboardAction` -> future `MathInputEditorCommand` bridge if needed during intermediate migration

## Removal Conditions

- `MathKeyboardIntent` no longer used by production surfaces by latest Phase 8
- `KeyboardAction` reduced to compatibility-only or removed by latest Phase 9
- `MathInputToken` no longer treated as keyboard authority by latest Phase 6

## Open Questions

- Should `submit` and `cancel` remain editor commands or be reclassified partly as host actions depending on input mode?
- Should undo/redo become keyboard-framework actions or stay outside the first migration slice?
- Does Phase 6 need a dedicated adapter target between keyboard core and MathInput core, or is `WorkspaceKit` enough for v1.0?
