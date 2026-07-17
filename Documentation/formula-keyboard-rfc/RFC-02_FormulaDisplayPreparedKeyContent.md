# RFC-02: FormulaDisplay Prepared Key Content Boundary

## Context

The current math key label path is:

- keyboard label markup
- `FormulaReadOnlyRenderProbe.measure(...)`
- then `FormulaDisplayView(rawValue: ...)`

This means the same static key-cap formula is effectively parsed and resolved twice for successful rendering.

That is acceptable for the current keyboard, but it is the wrong contract for the new framework because:

- key content should not be reparsed when pressed state changes
- renderer state should not depend on ad hoc SwiftUI body rebuild timing
- diagnostics and fallback should be explicit runtime data, not just view branching

## Problem

We need a boundary where:

- static formula key content is prepared once
- preparation result can be cached
- the prepared result can be rendered repeatedly without reparsing
- key background/press state changes do not invalidate formula parsing
- the app target never touches FormulaDisplay internals

## Decision

Introduce a prepared-content runtime layer owned by:

- `EMathicaFormulaKeyboardRendering`

and require a supporting prepared-content boundary from:

- `EMathicaFormulaDisplayKit`

The long-term contract is:

- core model stores source content only
- rendering layer prepares reusable formula key content
- SwiftUI layer renders prepared content without reparsing

## Alternatives Considered

### Alternative A: keep using `FormulaDisplayView(rawValue:)` directly from key views

Why rejected:

- repeated parsing remains
- diagnostics remain view-local
- press state and view churn can still trigger repeated work
- prepared caching has no natural ownership

### Alternative B: store fully rendered SwiftUI views inside key definitions

Why rejected:

- not serializable
- not reusable across hosts
- impossible to validate as data
- invalid for SharedLibraries core ownership

### Alternative C: store pre-rendered PNG data in the core definition

Why rejected:

- core definitions must remain data-driven and platform-agnostic
- rendering result depends on metrics, theme, font role, scale, and locale/script choices
- this would over-freeze output too early

## Rejected Alternatives

Rejected permanently:

- direct `FormulaDisplayView` construction as the keyboard framework's prepared-content boundary
- prepared content living in the app target
- any prepared-content contract that stores SwiftUI `View` values

## SharedLibraries Ownership

### `EMathicaFormulaKeyboardCore`

Owns:

- source-level `FormulaKeyContent`
- stable content IDs
- fallback resource IDs

Does not own:

- prepared rendering caches
- display snapshots
- formula probe results

### `EMathicaFormulaKeyboardRendering`

Owns:

- `PreparedFormulaKeyContent`
- cache keys
- cache storage
- fallback/diagnostic conversion
- renderer request/result types

### `EMathicaFormulaDisplayKit`

Must provide:

- a shared prepared formula content boundary
- read-only preparation that can be reused by keyboard rendering
- diagnostics structured enough for keyboard fallbacks

## Package / Target Placement

Recommended placement:

- source descriptor types: `EMathicaFormulaKeyboardCore`
- prepared content runtime types: `EMathicaFormulaKeyboardRendering`
- SwiftUI display adapter for prepared content: `EMathicaFormulaKeyboardSwiftUI`
- FormulaDisplay prepared-content provider APIs: `EMathicaFormulaDisplayKit`

## Public API Surface

Public:

- `FormulaKeyContent`
- rendering request/response protocols that hide FormulaDisplay internals
- fallback and diagnostics enums needed by framework consumers

Package/internal:

- cache implementation
- formula renderer cache eviction policy
- internal FormulaDisplay resolver details

The framework should not publicly expose FormulaDisplay vendor internals.

## Dependency Direction

Allowed:

- keyboard rendering -> keyboard core
- keyboard rendering -> FormulaDisplayCore
- keyboard SwiftUI -> keyboard rendering

Forbidden:

- keyboard core -> FormulaDisplayCore
- app -> prepared renderer internals

## App Boundary

The app target must not:

- prepare formula key content
- cache formula key content
- decide parser fallback behavior for keys

The app may only:

- mount keyboard views that consume prepared content via `WorkspaceKit`

## Content Model Decision

`FormulaKeyContent` should store source descriptors, not prepared objects.

Recommended source forms:

- plain text resource ID or inline text
- symbol resource ID or inline symbol markup
- formula markup source
- system icon ID

Recommended runtime prepared object:

- `PreparedFormulaKeyContent`

which is:

- non-Codable
- runtime-only
- invalidated by environment and metrics changes

## Cache Key Dimensions

Prepared content cache keys must include at least:

- stable content identity
- formula markup source hash
- font role
- formula metrics identity
- size class / layout variant if it affects content fitting
- color or theme token only if rendering output is color-baked
- locale/script variant when the visible content changes
- display scale if raster output is cached

Pressed state must not be part of the cache key.

## Fallback And Diagnostics

Prepared content must be able to report:

- success
- unsupported content
- parser failure
- resource failure
- empty or invalid output

These diagnostics must be runtime data, not only debug text in SwiftUI buttons.

## Pressed State Rule

Pressed, highlighted, focused, disabled, and selected key states may change:

- background layer
- opacity
- scale
- shadow

They must not trigger formula reparsing.

Only content-affecting changes may invalidate prepared content.

## Serialization Decision

Prepared content is not serializable.

Serializable:

- source content descriptor
- stable content IDs
- fallback IDs

Non-serializable:

- cached prepared objects
- FormulaDisplay live view types
- platform images

## Accessibility Readiness Impact

This boundary helps v1.1 because:

- semantics can refer to stable content IDs instead of parsing ad hoc view strings
- diagnostics can become accessible feedback events
- enlarged or alternate variants can reuse prepared content rules consistently

## Testing Impact

Needed tests:

- preparation success/failure tests
- cache key invalidation tests
- no-reparse-on-pressed-state tests
- fallback classification tests
- content rendering regression tests

## Compatibility Window

Temporary adapter allowed:

- source content -> current `FormulaDisplayView(rawValue:)`

This adapter may exist through Phase 4 only.

## Removal Conditions

Delete the direct `FormulaReadOnlyRenderProbe + FormulaDisplayView(rawValue:)` key-view path by latest Phase 4 once:

- prepared content exists
- fallback diagnostics are structured
- keyboard key content no longer reparses on press/highlight updates

## Open Questions

- Should prepared content use vector-like retained display data from FormulaDisplayKit if that becomes available, or raster snapshot caching first?
- Should diagnostics be shared with object panel / inspector formula rendering, or remain keyboard-specific at first?
- How much of the current `FormulaReadOnlyRenderProbe` surface should remain public versus being superseded by prepared-content APIs?
