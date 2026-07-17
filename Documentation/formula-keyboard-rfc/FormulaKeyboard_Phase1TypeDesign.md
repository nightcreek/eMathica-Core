# Formula Keyboard Phase 1 Type Design

## Scope

This document defines Phase 1 type ownership and placement only.

It does not implement any production type yet.

## Phase 1 Type Table

| Type | Recommended package | Recommended target | Visibility | Allowed dependencies | Protocols | Lifecycle | Version | App direct use |
|---|---|---|---|---|---|---|---|---|
| `FormulaKeyboardDefinition` | `EMathicaFormulaKeyboardKit` | `EMathicaFormulaKeyboardCore` | `public` | Foundation only | `Codable`, `Hashable`, `Sendable` | Static declaration | v1.0 required | No |
| `FormulaKeyboardPageDefinition` | `EMathicaFormulaKeyboardKit` | `EMathicaFormulaKeyboardCore` | `public` | Foundation only | `Codable`, `Hashable`, `Sendable`, `Identifiable` | Static declaration | v1.0 required | No |
| `FormulaKeyboardLayoutVariant` | `EMathicaFormulaKeyboardKit` | `EMathicaFormulaKeyboardCore` | `public` | Foundation only | `Codable`, `Hashable`, `Sendable` | Static declaration | v1.0 required | No |
| `FormulaKeyDefinition` | `EMathicaFormulaKeyboardKit` | `EMathicaFormulaKeyboardCore` | `public` | Foundation only | `Codable`, `Hashable`, `Sendable`, `Identifiable` | Static declaration | v1.0 required | No |
| `FormulaKeyID` | `EMathicaFormulaKeyboardKit` | `EMathicaFormulaKeyboardCore` | `public` | Foundation only | `Codable`, `Hashable`, `Sendable`, `RawRepresentable` | Static declaration | v1.0 required | Indirect only |
| `FormulaKeyContent` | `EMathicaFormulaKeyboardKit` | `EMathicaFormulaKeyboardCore` | `public` | Foundation only | `Codable`, `Hashable`, `Sendable` | Static declaration | v1.0 required | Indirect only |
| `FormulaKeyPlacement` | `EMathicaFormulaKeyboardKit` | `EMathicaFormulaKeyboardCore` | `public` | Foundation only | `Codable`, `Hashable`, `Sendable` | Static declaration | v1.0 required | No |
| `FormulaKeySize` | `EMathicaFormulaKeyboardKit` | `EMathicaFormulaKeyboardCore` | `public` | Foundation only | `Codable`, `Hashable`, `Sendable` | Static declaration | v1.0 required | No |
| `FormulaKeyRole` | `EMathicaFormulaKeyboardKit` | `EMathicaFormulaKeyboardCore` | `public` | Foundation only | `Codable`, `Hashable`, `Sendable` | Static declaration | v1.0 required | Indirect only |
| `FormulaKeyBehavior` | `EMathicaFormulaKeyboardKit` | `EMathicaFormulaKeyboardCore` | `public` | Foundation only | `Codable`, `Hashable`, `Sendable` | Static declaration | v1.0 required | No |
| `FormulaKeyAction` | `EMathicaFormulaKeyboardKit` | `EMathicaFormulaKeyboardCore` | `public` | Foundation only | `Codable`, `Hashable`, `Sendable` | Runtime event | v1.0 required | No |
| `FormulaKeyActionResult` | `EMathicaFormulaKeyboardKit` | `EMathicaFormulaKeyboardCore` | `public` | Foundation only | `Codable`, `Hashable`, `Sendable` | Runtime result | v1.0 required | Observable via host only |
| `FormulaKeyboardStateSnapshot` | `EMathicaFormulaKeyboardKit` | `EMathicaFormulaKeyboardCore` | `public` | Foundation only | `Hashable`, `Sendable` | Runtime state | v1.0 required | No |
| `FormulaKeySemanticDescriptor` | `EMathicaFormulaKeyboardKit` | `EMathicaFormulaKeyboardCore` | `public` | Foundation only | `Codable`, `Hashable`, `Sendable` | Static plus runtime-readable semantic metadata | v1.0 reserve, v1.1 expanded | No |
| `FormulaKeyboardEnvironment` | `EMathicaFormulaKeyboardKit` | `EMathicaFormulaKeyboardCore` | `public` | Foundation only | `Hashable`, `Sendable` where possible | Runtime host-injected environment | v1.0 required | App via Workspace config only |
| `FormulaKeyboardMetrics` | `EMathicaFormulaKeyboardKit` | `EMathicaFormulaKeyboardCore` | `public` | Foundation only | `Hashable`, `Sendable` | Runtime resolved metrics | v1.0 required | Indirect only |
| `FormulaKeyboardHost` | `EMathicaFormulaKeyboardKit` | `EMathicaFormulaKeyboardCore` | `public protocol` | no concrete host dependencies | `Sendable` where feasible | Runtime host boundary | v1.0 required | App should not implement production host |
| `FormulaKeyboardDispatcher` | `EMathicaFormulaKeyboardKit` | `EMathicaFormulaKeyboardCore` | `public protocol` | no concrete view/state dependencies | `Sendable` where feasible | Runtime dispatch boundary | v1.0 required | No |

## Additional Placement Notes

### Builtin definitions

Builtin pages should not live in the app target.

They should live in:

- `EMathicaFormulaKeyboardBuiltin`

using `FormulaKeyboardDefinition` and `FormulaKeyDefinition` from core.

### Prepared formula content

Prepared formula content should not be a Phase 1 core type.

It is a runtime rendering concern and belongs in:

- `EMathicaFormulaKeyboardRendering`

### Theme application

Theme values should remain in:

- `EMathicaThemeKit`

but `FormulaKeyboardEnvironment` and `FormulaKeyboardMetrics` must remain framework-owned abstractions that can be resolved from theme and system preferences.

## Core Model Rules

The following are forbidden inside Codable core models:

- closures
- SwiftUI `View`
- `WorkspaceState`
- `InputController`
- AST object references
- FormulaDisplay live view objects
- UIKit/AppKit responder objects
- singletons

## Recommended Type Semantics

### `FormulaKeyboardDefinition`

Should represent one whole keyboard family definition, including:

- stable keyboard ID
- pages
- variants
- builtin semantic metadata references

### `FormulaKeyboardPageDefinition`

Should represent:

- page ID
- display title resource ID
- ordered key definitions
- optional page-level role

### `FormulaKeyboardLayoutVariant`

Should capture:

- logical grid dimensions
- variant applicability
- optional platform/size-class selectors

### `FormulaKeyContent`

Should represent source content only, such as:

- `.text(...)`
- `.symbol(...)`
- `.formula(markupSourceID, fallbackTextID?)`
- `.systemIcon(...)`

It must not store prepared content.

### `FormulaKeyPlacement`

Should represent logical placement only:

- row
- column
- row span
- column span
- layer/section if needed

### `FormulaKeyBehavior`

Should describe behavior declaratively:

- activation style
- repeat policy
- long-press alternate policy
- disabled handling

### `FormulaKeyAction`

Should be framework authority for all activators:

- editor actions
- keyboard-local state actions
- host actions

### `FormulaKeyActionResult`

Should capture:

- performed
- rejected
- no change
- keyboard state changed
- feedback events

### `FormulaKeyboardStateSnapshot`

Should represent runtime keyboard state such as:

- selected page
- active modifiers
- enabled/disabled status
- alternate presentation state

### `FormulaKeySemanticDescriptor`

Should reserve at least:

- stable semantic ID
- role
- action meaning ID
- state flags
- future accessibility hint IDs

It must not hardcode final VoiceOver copy.

### `FormulaKeyboardEnvironment`

Should carry host-injected runtime inputs such as:

- platform
- size class
- color scheme
- system preference flags
- focus state

without referencing SwiftUI directly in the core contract.

### `FormulaKeyboardMetrics`

Should be resolved data, not hardcoded view constants.

It should support:

- key sizing
- spacing
- content padding
- variant changes
- larger-accessibility layouts later

### `FormulaKeyboardHost`

Must define the smallest stable host contract needed by the framework:

- observe state snapshot
- dispatch action
- receive action result / feedback
- inject environment

### `FormulaKeyboardDispatcher`

Must be independent of SwiftUI and specific views.

It should accept:

- `FormulaKeyAction`

and return:

- `FormulaKeyActionResult`

through a host-controlled implementation path.

## App Usage Rules

The app target may directly reference:

- `WorkspaceView`
- app-level workspace configuration

The app target should not directly construct:

- `FormulaKeyboardDefinition`
- `FormulaKeyboardDispatcher`
- `FormulaKeyboardHost`

for the production path.

## v1.0 vs v1.1 Boundary

v1.0 required:

- all definition/action/layout/environment/host types above

v1.0 reserve only:

- richer semantic descriptors
- action feedback expansion
- selection-aware keyboard state snapshot

v1.1 extension:

- full accessibility semantic and focus routing strategies based on the reserved boundaries
