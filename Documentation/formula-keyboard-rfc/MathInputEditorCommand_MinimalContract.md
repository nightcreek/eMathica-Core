# MathInputEditorCommand Minimal Contract

## Status

Phase 0.75 freezes the minimum editor-command boundary that the future Formula Keyboard host will target.

This document does not introduce production implementation yet.

## Context

Current editor-facing mutation entry points are split across:

- `KeyboardAction` in `EMathicaMathInputCore`
- `MathInputToken` in `EMathicaMathInputCore`
- `InputController.handle(_:state:)`
- `MathInputSession.apply(_:)`
- `MathInputSession.input(_:)`

Observed current behavior:

- `KeyboardAction` already expresses most low-level editor mutations.
- `KeyboardAction` also still carries legacy aliases such as `.backspace`, `.delete`, and `.enter`.
- `MathInputToken` is a public incremental-input facade, not a good long-term keyboard authority.
- `submit` and `cancel` currently terminate or commit editing in `WorkspaceState`, not in `InputController`.
- `undo` and `redo` currently live at the session/history layer in `MathInputSession`, not in `InputController`.

Phase 1 needs a clean command boundary that:

- belongs to `EMathicaMathInputCore`
- does not depend on `FormulaKeyAction`
- is stable enough for `EMathicaWorkspaceKit` to target
- does not encode keyboard-local UI state

## Final Recommended Declaration

```swift
public enum MathInputEditorCommand: Hashable, Sendable {
    case insertText(MathInputTextInsertion)
    case insertTemplate(TemplateKind)
    case insertFunction(MathInputFunctionInsertion)
    case moveCursor(MathInputCursorMovement)
    case delete(MathInputDeletionDirection)
}

public struct MathInputTextInsertion: Hashable, Sendable {
    public var text: String
    public var role: MathInputTextRole
}

public enum MathInputTextRole: Hashable, Sendable {
    case character
    case symbol
    case `operator`
}

public struct MathInputFunctionInsertion: Hashable, Sendable {
    public var name: String
}

public enum MathInputCursorMovement: Hashable, Sendable {
    case left
    case right
    case up
    case down
    case nextField
    case previousField
}

public enum MathInputDeletionDirection: Hashable, Sendable {
    case backward
    case forward
}
```

## Why This Shape

### Why not reuse `KeyboardAction` as-is

Rejected for the long-term boundary because `KeyboardAction` currently mixes:

- canonical editor mutations
- legacy aliases
- host-level actions such as submit/cancel semantics
- historical naming tied to keyboard entry paths

Phase 1 should not rename `KeyboardAction` and call that complete.

### Why `insertText` uses a payload instead of many top-level cases

Current engine behavior still distinguishes:

- character insertion
- symbol insertion
- operator insertion

That distinction should be preserved semantically, but it does not need separate top-level command cases.

Numbers do not need their own editor command family in v1.0 because current editor behavior already inserts them through the same sequence path as ordinary characters.

### Why functions are separate from templates

Current `InputController` routes `.insertFunction(name)` into `insertTemplate(functionKind(for: name))`.

That adapter can remain internal, but the command boundary should keep function intent explicit because:

- keyboard definitions need semantic function identity
- future accessibility and feedback should distinguish `sin` from a generic template
- later function families may carry metadata that plain `TemplateKind` should not own

### Why movement is grouped

Current move actions are structurally one command family:

- left
- right
- up
- down
- tab / shift-tab as major-slot movement

That maps cleanly to `moveCursor(MathInputCursorMovement)`.

## Explicit Decisions

### Included in the minimum command contract

- text insertion
- template insertion
- function insertion
- cursor movement
- backward delete
- forward delete

### Explicitly excluded from `MathInputEditorCommand`

- keyboard page switching
- script-case toggles
- alphabet/Greek mode switching
- keyboard visibility
- submit
- cancel
- undo
- redo
- host focus changes

These are not editor-core mutations.

## Submit And Cancel Classification

`submit` and `cancel` remain host actions, not editor commands.

Reason:

- they change editing session lifecycle in `WorkspaceState`
- they may commit/cancel document mutations
- they are not AST-local mutations
- they may remain meaningful even when no command is dispatched to `InputController`

Therefore:

- `FormulaKeyAction.submit` may exist at keyboard/host level later
- `MathInputEditorCommand.submit` must not exist in the minimal contract

## Undo / Redo Classification

`undo` and `redo` are excluded from the Phase 0.75 minimal command contract.

Reason:

- current ownership is in `MathInputSession`
- they operate on history/session policy, not only on the current AST mutation
- the keyboard framework can expose host-level action intents before editor-core command ownership is expanded

This can be revisited after the Phase 1 command boundary is stable.

## Codable / Hashable / Sendable

Recommended:

- `MathInputEditorCommand`: `Hashable`, `Sendable`
- support payloads/enums: `Hashable`, `Sendable`
- `Codable`: not required in Phase 1

Reason:

- Hashability is useful for tests, diagnostics, and action comparisons.
- Sendability is useful for future structured dispatch and testing.
- Codable would prematurely freeze persistence and IPC assumptions that are not yet needed.

## Execution Model

Execution should remain synchronous in Phase 1.

Recommended executor shape:

```swift
package protocol MathInputEditorCommandHandling {
    mutating func apply(_ command: MathInputEditorCommand) -> MathInputEditorCommandResult
}
```

`MathInputEditorCommandResult` should initially remain package/internal, not public.

Recommended minimal result model:

```swift
package enum MathInputEditorCommandResult: Equatable, Sendable {
    case applied
    case ignored(MathInputEditorCommandIgnoreReason)
}
```

This avoids freezing a public result shape before the host/action-result boundary is finalized.

## Mapping To Current Editor Operations

| New command | Current adapter target |
| --- | --- |
| `.insertText(role: .character, text: value)` | `InputController.handle(.insertCharacter(value), ...)` |
| `.insertText(role: .symbol, text: value)` | `InputController.handle(.insertSymbol(value), ...)` |
| `.insertText(role: .operator, text: value)` | `InputController.handle(.insertOperator(value), ...)` |
| `.insertTemplate(kind)` | `InputController.handle(.insertTemplate(kind), ...)` |
| `.insertFunction(name)` | `InputController.handle(.insertFunction(name), ...)` |
| `.moveCursor(.left)` | `InputController.handle(.moveLeft, ...)` |
| `.moveCursor(.right)` | `InputController.handle(.moveRight, ...)` |
| `.moveCursor(.up)` | `InputController.handle(.moveUp, ...)` |
| `.moveCursor(.down)` | `InputController.handle(.moveDown, ...)` |
| `.moveCursor(.nextField)` | `InputController.handle(.tab, ...)` |
| `.moveCursor(.previousField)` | `InputController.handle(.shiftTab, ...)` |
| `.delete(.backward)` | `InputController.handle(.deleteBackward, ...)` |
| `.delete(.forward)` | `InputController.handle(.deleteForward, ...)` |

## KeyboardAction Migration Strategy

`KeyboardAction` becomes a transitional adapter type.

Phase policy:

- Phase 1: keep `KeyboardAction` in production
- Phase 1-2: add translator between `KeyboardAction` and `MathInputEditorCommand`
- Phase 6: `WorkspaceKit` and hardware/touch keyboard ingress stop using `KeyboardAction` as the authority
- Latest removal target for keyboard authority role: Phase 6

`KeyboardAction` may remain temporarily only where legacy editor internals still need it.

## MathInputToken Migration Strategy

`MathInputToken` is not the future keyboard authority.

It remains a compatibility facade for public incremental input, but keyboard infrastructure should stop depending on it.

Phase policy:

- Phase 1: keep `MathInputToken`
- Phase 1-4: `MathInputSession.input(_:)` may translate `MathInputToken` to `MathInputEditorCommand`
- Phase 8: built-in keyboard definitions and keyboard dispatcher must no longer emit `MathInputToken`

Latest removal target for keyboard-internal dependency on `MathInputToken`: Phase 8

This does not require deleting the public `MathInputToken` API if it still provides value outside keyboard infrastructure.

## Plain-Text Path Boundary

Plain-text ingress is explicitly not unified in this phase.

Phase 0.75 decision:

- formula editor command boundary: in scope
- general plain-text field behavior: out of scope

`MathInputEditorCommand` should not absorb generic text-field session policy.

## Compatibility Adapter

Phase 1 needs two temporary adapters:

1. `FormulaKeyAction -> host-local dispatch -> MathInputEditorCommand`
2. `KeyboardAction / MathInputToken -> MathInputEditorCommand`

Both adapters are transitional and must not become authority.

## Deletion Plan

| Temporary adapter | Latest removal phase |
| --- | --- |
| `FormulaKeyAction -> KeyboardAction` shortcut | Phase 6 |
| `KeyboardAction` as the primary keyboard authority | Phase 6 |
| Built-in keyboard emitting `MathInputToken` as authority | Phase 8 |

## Testing Plan

Minimum tests to add when implementation begins:

- command translation tests from `FormulaKeyAction`
- command translation tests from `KeyboardAction`
- command translation tests from `MathInputToken`
- `InputController` command execution tests
- unsupported/ignored result tests
- host-level submit/cancel tests proving they do not enter the editor command layer

## Impact On Phase 1 FormulaKeyAction

This decision means `FormulaKeyAction` should distinguish:

- editor-facing actions that translate to `MathInputEditorCommand`
- host-local keyboard actions that do not

That split is required before Phase 1 implementation starts.

## Final Freeze

Frozen for Phase 1:

- `MathInputEditorCommand` belongs to `EMathicaMathInputCore`
- it is independent from `FormulaKeyAction`
- it is editor-mutation focused only
- submit/cancel stay outside it
- undo/redo stay outside the minimal v1.0 shape
- `KeyboardAction` and `MathInputToken` become compatibility layers, not future authorities
