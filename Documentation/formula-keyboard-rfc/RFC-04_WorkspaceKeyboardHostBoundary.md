# RFC-04: Workspace Keyboard Host Boundary

## Context

The future Formula Keyboard Framework must be shared infrastructure, but it still needs a production host that can provide:

- focus ownership
- visibility state
- hardware ingress
- editor session access
- action forwarding
- formula preview coordination

Today those responsibilities are concentrated in:

- `EMathicaWorkspaceKit`

That is appropriate for hosting, but not for owning the keyboard framework itself.

## Problem

We need a host boundary that makes `WorkspaceKit` the production consumer and coordinator without letting it become the keyboard framework's true owner.

Specifically we must freeze:

- where the host protocol lives
- which responsibilities belong to the host
- which responsibilities stay in keyboard core/rendering
- how hardware events enter the framework
- how actions leave the framework and reach the editor

## Decision

Define:

- `FormulaKeyboardHost`

inside:

- `EMathicaFormulaKeyboardCore`

Implement the protocol in:

- `EMathicaWorkspaceKit`

The host boundary is consumer-owned by the framework and implementation-owned by WorkspaceKit.

This keeps the dependency direction correct:

- framework defines what any host must provide
- WorkspaceKit provides the concrete production implementation
- the app target consumes WorkspaceKit

## Alternatives Considered

### Alternative A: keep host protocol in `WorkspaceKit`

Why rejected:

- the framework would then depend conceptually on Workspace
- non-workspace reuse would be awkward
- the host contract would be defined by the consumer instead of the framework

### Alternative B: let SwiftUI views talk to `WorkspaceState` directly

Why rejected:

- view-to-state coupling becomes the de facto host API
- impossible to test framework behavior without Workspace state
- violates the “dispatcher does not depend on concrete View” rule

### Alternative C: let the app target implement the host

Why rejected:

- would recreate app-private ownership
- duplicates would appear across app scenes or products
- breaks SharedLibraries reuse

## Rejected Alternatives

Rejected for Phase 1:

- direct `WorkspaceState` references inside keyboard framework views
- app-side host implementations
- a host contract that owns keyboard definitions or layout

## SharedLibraries Ownership

### `EMathicaFormulaKeyboardCore`

Owns:

- `FormulaKeyboardHost` protocol
- `FormulaKeyboardDispatcher` protocol
- host-facing environment value contracts
- host-facing action result contracts

### `EMathicaWorkspaceKit`

Owns:

- production host implementation
- formula editor session lifecycle
- visibility and focus coordination
- hardware event capture
- bridge from framework actions to MathInput editor commands
- feedback emission into workspace UI surfaces

### `eMathica` app target

Owns:

- mounting `WorkspaceView`
- app-level configuration that reaches WorkspaceKit

## Package / Target Placement

Host protocol:

- `EMathicaFormulaKeyboardCore`

Production host implementation:

- `EMathicaWorkspaceKit`

Hardware key capture views:

- stay in `EMathicaWorkspaceKit`

## Public API Surface

Public:

- host protocol
- dispatcher protocol
- keyboard environment and metrics injection entrypoints
- action result observation entrypoints

Internal to WorkspaceKit:

- concrete `WorkspaceState` adaptation
- focus scheduling details
- responder chain details
- preview synchronization details

## Dependency Direction

Allowed:

- WorkspaceKit depends on keyboard core / builtin / SwiftUI
- keyboard core depends on no Workspace types

Forbidden:

- keyboard framework views importing `WorkspaceState`
- core depending on hardware capture views

## App Boundary

The app target may:

- configure the workspace
- decide where the keyboard appears in app UI
- pass app-level themes or feature flags into WorkspaceKit

The app target may not:

- implement the host protocol itself as the production path
- own hardware ingress mapping
- directly dispatch framework actions into editor state

## Host Responsibilities

The production host must provide:

- keyboard visibility state
- active page/state snapshot injection
- focus state
- platform identity and environment inputs
- hardware event ingress normalization
- action dispatch entrypoint
- feedback sink
- access to current editor session snapshot

The production host must not provide:

- builtin key definitions
- layout engine
- renderer ownership
- semantic truth generation

## Hardware Ingress Ownership

Physical capture remains in WorkspaceKit because it is platform-specific.

Recommended split:

- WorkspaceKit captures `UIPress` / `NSEvent` / platform input
- WorkspaceKit normalizes raw events into a pure `HardwareKeyDescriptor`
- keyboard-core mapping logic turns normalized descriptors into `FormulaKeyAction`
- host dispatcher forwards resulting action through the standard framework path

This keeps physical event APIs out of keyboard core while still unifying semantic mapping.

## Focus, Visibility, Platform, And Preference Injection

These are host-supplied environment values.

The framework should receive them as data, not by reading `WorkspaceState` directly.

Examples:

- keyboard shown/hidden
- focused or inactive
- compact vs regular presentation
- system preference flags
- hardware keyboard presence if relevant to host layout

## Formula Preview And Keyboard Coordination

Decision:

- keyboard framework and formula preview must not depend on each other directly

Both are coordinated by WorkspaceKit through shared session state and host callbacks.

This prevents a new cycle between keyboard rendering and editor preview rendering.

## Testing Impact

The host boundary must allow:

- mock host implementations
- action dispatch tests without real responder chains
- focus/visibility tests without app scenes
- hardware descriptor tests without UIKit/AppKit event objects

## Accessibility Readiness Impact

This boundary is necessary so that future accessibility support can:

- trigger keyboard actions without touch gestures
- observe structured action results
- route logical focus independently from concrete SwiftUI button tree details

## Compatibility Window

Allowed temporary state:

- current WorkspaceKit host implementation may internally bridge to existing keyboard views during migration

Not allowed:

- a second app-only host path

## Removal Conditions

Temporary Workspace adapters can remain through migration, but must be deleted by latest Phase 9 once:

- all production keyboard surfaces use the new framework
- no `MathInputKeyboardView` legacy bridge remains in the production workspace path

## Open Questions

- Should the host protocol surface hardware keyboard attachment state explicitly in v1.0, or keep it inside host-local environment adaptation?
- Which action results need immediate workspace UI feedback in v1.0 versus later accessibility/event surfaces?
- Do macOS and iPadOS need separate host implementations or one shared implementation with platform-specific helpers?
