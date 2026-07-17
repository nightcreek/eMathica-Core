# FormulaDisplay Prepared Content Minimal Contract

## Status

Phase 0.75 freezes the minimum prepared-content boundary needed before Formula Keyboard Phase 4 rendering work starts.

This document does not implement the API yet.

## Context

Current keyboard formula labels use:

1. `FormulaReadOnlyRenderProbe.measure(...)`
2. then `FormulaDisplayView(rawValue: markup, ...)`

That means the same static keycap formula is effectively resolved more than once.

The target architecture requires:

- source markup
- prepare once
- render repeatedly across normal / pressed / highlighted / selected states
- no reparse on visual-state changes

## Ownership Decision

Prepared-content preparation belongs to:

- `EMathicaFormulaDisplayCore` for request/result types and preparation entry point
- `EMathicaFormulaDisplaySwiftUI` for rendering a prepared object into SwiftUI

It does not belong to:

- `EMathicaFormulaKeyboardCore`
- `EMathicaFormulaKeyboardBuiltin`
- eMathica App target

## Minimum Type Set

Recommended minimum types:

```swift
public struct FormulaPreparedContentRequest: Hashable, Sendable
public struct FormulaPreparedContentEnvironmentKey: Hashable, Sendable
public struct FormulaPreparedContent: Sendable
public enum FormulaPreparedContentResult: Sendable
public struct FormulaPreparedContentDiagnostics: Equatable, Sendable
public enum FormulaPreparedContentFailureReason: String, Equatable, Sendable
```

## Recommended API Sketch

```swift
public struct FormulaPreparedContentRequest: Hashable, Sendable {
    public var source: FormulaDisplayMarkup
    public var environment: FormulaPreparedContentEnvironmentKey
}

public struct FormulaPreparedContentEnvironmentKey: Hashable, Sendable {
    public var fontRole: FormulaFontRole
    public var metrics: FormulaLayoutMetrics
}

public struct FormulaPreparedContent: Sendable {
    package var storage: Storage
}

public enum FormulaPreparedContentResult: Sendable {
    case success(FormulaPreparedContent)
    case failure(FormulaPreparedContentDiagnostics)
}

public struct FormulaPreparedContentDiagnostics: Equatable, Sendable {
    public var reason: FormulaPreparedContentFailureReason
    public var message: String
}

public enum FormulaPreparedContentFailureReason: String, Equatable, Sendable {
    case emptySource
    case parserError
    case unsupportedCommand
    case invalidIntrinsicSize
    case renderFailure
}

public enum FormulaPreparedContentFactory {
    public static func prepare(
        _ request: FormulaPreparedContentRequest
    ) -> FormulaPreparedContentResult
}
```

## Why Core Owns Preparation

Preparation should be in `FormulaDisplayCore` because it is:

- non-View logic
- a rendering contract that may be reused outside keyboard
- the correct place to hide vendor-specific representation
- already close to current `FormulaDisplayContentResolver`

`FormulaDisplaySwiftUI` should only consume the prepared object.

## Prepared Object Rules

### Prepared object is opaque

The public handle must not expose vendor types directly.

The storage may internally wrap:

- SwiftMath layout/output objects
- display snapshots
- other immutable render resources

But that must remain package/internal.

### Prepared object is runtime-only

`FormulaPreparedContent`:

- is not `Codable`
- does not enter `FormulaKeyDefinition`
- is not stored in app documents
- is not persisted in schema

### Prepared object Sendability

Recommended:

- `FormulaPreparedContent`: `Sendable`
- not `Hashable`

Reason:

- it should be safe to move through rendering pipelines
- identity should be keyed by request/environment, not by value equality

Hashability is not required and would overconstrain internal storage.

## Color And Visual State Decision

Color is not part of the prepared-content identity.

Pressed/highlighted/selected state must not cause reparsing.

That means:

- prepared identity depends on structure/layout-affecting inputs
- view-state color changes are render-time concerns
- if recoloring needs rerasterization later, it must happen from prepared resources, not from raw markup reparsing

Pressed state is therefore explicitly excluded from the prepare key.

## Cache Identity

The minimum cache identity should include:

- source markup
- `FormulaFontRole`
- `FormulaLayoutMetrics`

It should not include:

- pressed / highlighted / selected
- cursorVisible for keyboard labels
- debug frame settings
- app-level theme tint

Possible later extensions:

- locale/script direction if layout semantics ever depend on them
- platform font variant if `FormulaFontRole` becomes insufficient

## Preparation Model

Phase 4 minimum should start synchronous.

Reason:

- current resolver path is synchronous
- keyboard labels need deterministic local rendering
- async preparation can be added later without changing ownership

If an async path is added later, it should be additive.

## Keyboard Rendering Responsibility

Keyboard Rendering should:

- request prepared content
- cache prepared content by request key
- choose fallback UI using diagnostics
- render the prepared object repeatedly

FormulaDisplay should:

- prepare immutable content
- expose structured diagnostics
- expose SwiftUI rendering of the prepared object

Fallback policy does not belong to FormulaDisplayCore.

## Recommended SwiftUI Rendering Boundary

Recommended future SwiftUI entry point:

```swift
public struct FormulaPreparedContentView: View {
    public init(
        content: FormulaPreparedContent,
        style: FormulaDisplayStyle = .default
    )
}
```

This keeps:

- preparation in Core
- View rendering in SwiftUI
- app code away from internal representation

## Diagnostics Decision

Diagnostics must not be only a DEBUG string.

Minimum structured categories:

- empty source
- parser error
- unsupported command
- invalid intrinsic size
- render failure

Message text can remain supplementary human-readable detail.

## Relationship To Existing APIs

### `FormulaReadOnlyRenderProbe`

Keep in Phase 0.75.

Role after prepared-content introduction:

- measurement tests
- diagnostics tests
- non-keyboard read-only probing

It should not remain the primary keyboard rendering path.

### `FormulaDisplayView(rawValue:)`

Keep for general formula display.

But keyboard rendering should migrate away from repeatedly calling `rawValue` initializers once prepared content is available.

## Reuse Scope Beyond Keyboard

Prepared content should be defined as a general FormulaDisplay capability, not keyboard-only.

Potential later consumers:

- keyboard labels
- object panel read-only labels
- inspector summaries
- export previews that reuse immutable label content

Keyboard is only the first required consumer.

## Fallback Boundary

If preparation fails:

- `FormulaDisplayCore` returns `FormulaPreparedContentDiagnostics`
- `EMathicaFormulaKeyboardRendering` decides fallback label policy

This keeps fallback behavior product-aware without making `FormulaDisplayKit` depend on the keyboard framework.

## Minimal Public API Change

Phase 4 should add:

- new prepared-content request/result types in `EMathicaFormulaDisplayCore`
- one prepared-content rendering view in `EMathicaFormulaDisplaySwiftUI`

No App-target API should be required.

## Phase 4 Implementation Boundary

Phase 0.75 freezes the contract only.

Phase 4 implementation may:

- extend `FormulaDisplayContentResolver`
- reuse or generalize `FormulaSwiftMathSnapshot`
- add prepared-content caching in `EMathicaFormulaKeyboardRendering`

Phase 4 must not:

- put prepared content into core keyboard definitions
- store SwiftUI views in caches
- treat PNG caching as the only long-term architecture

## Final Freeze

Frozen for Phase 4 planning:

- prepare in `EMathicaFormulaDisplayCore`
- render prepared handles in `EMathicaFormulaDisplaySwiftUI`
- prepared object is opaque and runtime-only
- cache key excludes pressed/highlighted/selected state
- diagnostics are structured
- keyboard rendering owns fallback policy
