# RFC-00: Formula Keyboard SharedLibraries Module Ownership

## Context

Phase 0 architecture audit confirmed that the current production formula keyboard is spread across:

- `EMathicaMathInputCore`
- `EMathicaMathInputUI`
- `EMathicaWorkspaceKit`
- `EMathicaThemeKit`
- `eMathica` app mounting code

The current split is workable for shipping the existing keyboard, but it is not a stable ownership model for the future Formula Keyboard Framework. The biggest risks are:

- definition authority is split between static layout data and runtime surface state
- rendering, behavior, and dispatch are owned by different packages without a single framework contract
- `WorkspaceKit` is at risk of becoming the de facto keyboard framework
- the app target could easily become a second source of truth if the new framework is implemented there

Phase 0.5 must freeze module ownership before Phase 1 introduces `FormulaKeyDefinition`, `FormulaKeyAction`, dispatcher, rendering, and accessibility reserve boundaries.

## Problem

We need one SharedLibraries-centered ownership decision that answers all of the following before implementation starts:

- Which package owns the framework core?
- Which targets own definition, builtin pages, rendering, and SwiftUI?
- Which package is allowed to host platform ingress and editor session coordination?
- Which dependencies are allowed?
- Which dependencies are forbidden?
- Why is the app target not allowed to own the framework?

## Decision

Create a new SharedLibraries package:

- `EMathicaFormulaKeyboardKit`

Recommended targets:

- `EMathicaFormulaKeyboardCore`
- `EMathicaFormulaKeyboardBuiltin`
- `EMathicaFormulaKeyboardRendering`
- `EMathicaFormulaKeyboardSwiftUI`

Ownership is frozen as follows.

### `EMathicaFormulaKeyboardCore`

Owns:

- `FormulaKeyboardDefinition`
- `FormulaKeyboardPageDefinition`
- `FormulaKeyboardLayoutVariant`
- `FormulaKeyDefinition`
- `FormulaKeyID`
- `FormulaKeyContent`
- `FormulaKeyPlacement`
- `FormulaKeySize`
- `FormulaKeyRole`
- `FormulaKeyBehavior`
- `FormulaKeyAction`
- `FormulaKeyActionResult`
- `FormulaKeyboardStateSnapshot`
- `FormulaKeySemanticDescriptor`
- `FormulaKeyboardEnvironment`
- `FormulaKeyboardMetrics`
- validators
- schema diagnostics
- serialization contracts
- accessibility integration boundary protocols
- dispatcher protocols

Must not depend on:

- `WorkspaceKit`
- `eMathica` app
- SwiftUI
- UIKit
- AppKit
- `FormulaDisplaySwiftUI`

### `EMathicaFormulaKeyboardBuiltin`

Owns:

- builtin keyboard page definitions
- builtin key IDs
- builtin resource identifiers
- builtin page grouping and variants

Must depend only on:

- `EMathicaFormulaKeyboardCore`

Must not depend on:

- `WorkspaceKit`
- `MathInputKit`
- app code

### `EMathicaFormulaKeyboardRendering`

Owns:

- prepared key-content boundary
- prepared formula-label rendering requests/results
- formula-key content caching
- rendering diagnostics for static key content
- FormulaDisplay adapters needed for keyboard content preparation

May depend on:

- `EMathicaFormulaKeyboardCore`
- `EMathicaFormulaDisplayCore`

Must not depend on:

- `WorkspaceKit`
- app code
- editor session types

### `EMathicaFormulaKeyboardSwiftUI`

Owns:

- keyboard SwiftUI surface
- key background/content/interaction layer composition
- press-session visual plumbing
- environment-to-view adaptation
- theme application at the keyboard UI boundary

May depend on:

- `EMathicaFormulaKeyboardCore`
- `EMathicaFormulaKeyboardRendering`
- `EMathicaThemeKit`
- `EMathicaFormulaDisplaySwiftUI` only if prepared keyboard content needs a SwiftUI display adapter

Must not depend on:

- `WorkspaceState`
- `MathInput` editor internals
- app-specific page containers

### `EMathicaWorkspaceKit`

Owns:

- `FormulaKeyboardHost` implementation
- formula editor session hosting
- keyboard visibility and focus ownership
- hardware event capture
- translation from host-level editor actions to MathInput command boundary
- preview/editor coordination

Must not own:

- core keyboard definitions
- builtin key definitions
- layout engine
- behavior state machine semantics
- rendering schema
- accessibility semantic model truth

### `eMathica` app target

Owns only:

- app screen mounting
- app-level workspace configuration
- app-level theme injection
- app feature flags
- app integration tests

Must not own:

- framework core types
- builtin keyboard definition copies
- dispatcher logic
- keyboard layout engine
- rendering contracts
- keyboard semantic providers

## Alternatives Considered

### Alternative A: keep the framework inside `EMathicaMathInputKit`

Possible split:

- `EMathicaFormulaKeyboardCore`
- `EMathicaFormulaKeyboardUI`

inside `EMathicaMathInputKit`.

Benefits:

- fewer new package files
- easy access to existing `MathKeyboardKey` and `MathInputToken`

Why rejected:

- `MathInputKit` owns editor semantics, AST, projection, serialization, and now some keyboard code only by history
- putting the new framework there would keep editor-domain and keyboard-framework ownership entangled
- renderer and accessibility boundaries would still look like “MathInput implementation details”
- `WorkspaceKit` would still need to reach into `MathInputKit` for UI framework types, increasing package pressure
- it would be harder to delete current `MathKeyboard*` transitional types cleanly

### Alternative B: scatter framework pieces across existing packages

Example:

- definitions in `MathInputKit`
- renderer in `FormulaDisplayKit`
- host logic in `WorkspaceKit`
- theme and metrics in `ThemeKit`

Benefits:

- reuses existing packages without adding a new one

Why rejected:

- no single framework authority
- definition ownership becomes ambiguous
- accessibility boundary gets fragmented
- diagnostics and validation cannot be tested in one place
- `WorkspaceKit` would still become the practical framework coordinator
- future reuse outside the current workspace host would be harder

### Alternative C: implement the framework in the app target

Benefits:

- fastest initial iteration

Why rejected:

- violates the shared-infrastructure requirement
- makes package testing and reuse impossible
- encourages app-private copies of builtin definitions
- guarantees future duplication across products or hosts

## Rejected Alternatives

The following are explicitly rejected for Phase 1:

- app-private framework implementation
- long-term definition ownership in `EMathicaWorkspaceKit`
- split authority between `MathInputKit` static layout and app-side page definitions
- any plan where `FormulaKeyboardCore` depends on `WorkspaceKit`

## SharedLibraries Ownership

Final ownership freeze:

- framework core: `EMathicaFormulaKeyboardCore`
- builtin definitions: `EMathicaFormulaKeyboardBuiltin`
- prepared rendering: `EMathicaFormulaKeyboardRendering`
- SwiftUI keyboard surface: `EMathicaFormulaKeyboardSwiftUI`
- host/session/platform ingress: `EMathicaWorkspaceKit`
- editor semantics and AST: `EMathicaMathInputKit`
- formula rendering engine: `EMathicaFormulaDisplayKit`
- theme tokens: `EMathicaThemeKit`

## Package / Target Placement

Recommended package:

- `SharedLibraries/EMathicaFormulaKeyboardKit`

Recommended targets:

- `Sources/EMathicaFormulaKeyboardCore`
- `Sources/EMathicaFormulaKeyboardBuiltin`
- `Sources/EMathicaFormulaKeyboardRendering`
- `Sources/EMathicaFormulaKeyboardSwiftUI`

Recommended test targets:

- `EMathicaFormulaKeyboardCoreTests`
- `EMathicaFormulaKeyboardRenderingTests`
- `EMathicaFormulaKeyboardSwiftUITests`

## Public API Surface

Public across package boundaries:

- definition models
- action models
- action result models
- validation entrypoints
- environment and metrics models
- host protocol
- dispatcher protocol
- semantic descriptor protocol/value models

Package or internal:

- rendering caches
- formula prepared-content cache implementation
- SwiftUI key view internals
- gesture plumbing
- diagnostics helpers that are not needed by other packages

## Dependency Direction

Allowed:

- `EMathicaFormulaKeyboardBuiltin` -> `EMathicaFormulaKeyboardCore`
- `EMathicaFormulaKeyboardRendering` -> `EMathicaFormulaKeyboardCore`
- `EMathicaFormulaKeyboardRendering` -> `EMathicaFormulaDisplayCore`
- `EMathicaFormulaKeyboardSwiftUI` -> `EMathicaFormulaKeyboardCore`
- `EMathicaFormulaKeyboardSwiftUI` -> `EMathicaFormulaKeyboardRendering`
- `EMathicaFormulaKeyboardSwiftUI` -> `EMathicaThemeKit`
- `EMathicaWorkspaceKit` -> `EMathicaFormulaKeyboardCore`
- `EMathicaWorkspaceKit` -> `EMathicaFormulaKeyboardBuiltin`
- `EMathicaWorkspaceKit` -> `EMathicaFormulaKeyboardSwiftUI`
- `EMathicaWorkspaceKit` -> `EMathicaMathInputCore`
- `EMathicaWorkspaceKit` -> `EMathicaFormulaDisplayCore` and `SwiftUI` only as host consumer
- `eMathica` app -> `EMathicaWorkspaceKit`

Forbidden:

- `EMathicaFormulaKeyboardCore` -> `EMathicaWorkspaceKit`
- `EMathicaFormulaKeyboardCore` -> `eMathica` app
- `EMathicaFormulaKeyboardCore` -> SwiftUI
- `EMathicaMathInputCore` -> `EMathicaFormulaKeyboardSwiftUI`
- `EMathicaFormulaDisplayCore` -> `EMathicaFormulaKeyboardSwiftUI`
- `eMathica` app -> app-private formula keyboard core

## App Boundary

The app target is frozen as:

- consumer only
- no builtin definition authority
- no renderer authority
- no dispatcher authority

The app may:

- choose which builtin keyboard definition set to mount
- inject theme/environment values through workspace configuration
- observe action results exposed by `WorkspaceKit`

The app may not:

- redefine builtin keyboard pages
- create a second action contract
- directly translate taps into AST mutations

## Migration Impact

Package work required in Phase 1 planning:

- add a new `Package.swift` under `SharedLibraries/EMathicaFormulaKeyboardKit`
- add the package as a local dependency where needed
- update `EMathicaWorkspaceKit/Package.swift`
- likely update `eMathica.xcodeproj` package references

Migration pressure reduced by this decision:

- `MathInputKit` can shed keyboard-framework concerns gradually
- `WorkspaceKit` can stay a host instead of a second framework
- app code does not become a shortcut destination

## Accessibility Readiness Impact

This decision is the minimum required to keep accessibility boundaries stable:

- semantic IDs live in framework core, not in leaf SwiftUI buttons
- focus routing can be framework-driven instead of view-order-driven
- feedback events can be emitted from dispatcher/host boundaries
- future VoiceOver/Switch Control work can target shared interfaces instead of app-specific views

## Testing Impact

This enables:

- core definition tests without SwiftUI
- validation tests without editor sessions
- renderer cache tests without workspace host
- host integration tests inside `WorkspaceKit`
- app integration tests that consume, rather than redefine, the framework

## Compatibility Window

Allowed temporary adapters:

- current `MathKeyboardLayout` -> new builtin definition adapter
- current `KeyboardAction` bridge inside `WorkspaceKit`
- current FormulaDisplay static markup path behind rendering adapter

These adapters are transitional only.

## Removal Conditions

- transitional definition adapter deleted by latest Phase 8
- legacy keyboard UI deleted by latest Phase 9
- any app-private keyboard helper introduced during migration is forbidden and therefore has no compatibility window

## Open Questions

- Should builtin definitions be stored as code-only in v1.0 or support external JSON fixtures immediately?
- Should rendering diagnostics remain in `EMathicaFormulaKeyboardRendering` or move to a dedicated diagnostics target if the surface grows?
- Do we need a tiny adapter target for `FormulaKeyboard <-> MathInput` later, or is `WorkspaceKit` hosting sufficient for v1.0?
