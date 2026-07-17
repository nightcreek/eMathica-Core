# RFC-03: Structural Semantic Snapshot Boundary

## Context

The keyboard audit and accessibility readiness audit both reached the same conclusion:

- future mathematical semantics must come from structural editor truth
- they cannot be reconstructed reliably from LaTeX strings
- they cannot be reconstructed reliably from rendered SwiftUI views
- they cannot be reconstructed reliably from FormulaDisplay wrapper paths alone

Today the strongest structural truth already exists in:

- `EMathicaMathInputCore` AST
- `TemplateKind`
- `FieldID`
- `EditorCursor(path, offset)`
- `TemplateDefinition`

FormulaDisplay and projection layers are essential downstream consumers, but they are not the right place to invent semantic truth.

## Problem

The Formula Keyboard Framework needs future access to read-only structural context such as:

- current editable structure
- current cursor context
- future selection context
- current field identity
- whether the cursor is in numerator, denominator, exponent, radicand, matrix cell, and so on

That information must be available through a stable SharedLibraries boundary without making keyboard core depend on rendering trees or app-local state.

## Decision

Structural semantic truth will belong to:

- `EMathicaMathInputKit`

More specifically, the long-term concrete provider should live in:

- `EMathicaMathInputCore`

or, if extracted later for clarity:

- a new MathInput-side semantics target within `EMathicaMathInputKit`

The Formula Keyboard Framework will not own mathematical truth. It will only define the abstract consumption boundary.

That means:

- keyboard core defines semantic consumer protocols and value contracts
- MathInput core provides concrete semantic snapshots
- WorkspaceKit forwards current session state to the keyboard host
- the app target never invents math semantics

## Alternatives Considered

### Alternative A: derive semantics from FormulaDisplay or rendered output

Why rejected:

- display wrappers are not AST truth
- rendered output loses editor-only structural distinctions
- accessibility needs stable structure identity, not inferred layout guesses
- this would repeat the same mistake as deriving edit semantics from LaTeX

### Alternative B: let the keyboard framework own the math semantic tree

Why rejected:

- would duplicate knowledge already owned by MathInput AST
- would create reverse pressure from keyboard framework back into editor semantics
- would make keyboard migration artificially larger than necessary

### Alternative C: let WorkspaceKit build semantic snapshots

Why rejected:

- WorkspaceKit is a host, not the owner of AST truth
- would make semantic truth contingent on one host implementation
- would block reuse in non-workspace contexts

## Rejected Alternatives

Rejected permanently:

- LaTeX-derived accessibility semantics as the authoritative source
- render-tree-derived accessibility semantics as the authoritative source
- app-generated mathematical semantic trees

## SharedLibraries Ownership

### `EMathicaMathInputCore`

Owns:

- structural semantic truth
- AST node/field/cursor relationships
- semantic snapshot generation from current editor state

### `EMathicaFormulaKeyboardCore`

Owns:

- abstract semantic consumer boundary
- semantic descriptor protocols needed by the framework
- no-op/default placeholders for v1.0

### `EMathicaWorkspaceKit`

Owns:

- forwarding current edit session into the keyboard host
- no semantic truth of its own

## Package / Target Placement

Concrete provider:

- `EMathicaMathInputCore`

Abstract consumption boundary:

- `EMathicaFormulaKeyboardCore`

Optional future extraction if the surface grows:

- `EMathicaMathInputSemantics` target inside `EMathicaMathInputKit`

## Public API Surface

Public or package-visible eventually needed from MathInput:

- structural semantic snapshot value
- stable semantic node IDs
- current cursor structural context
- future selection context placeholder
- read-only field and node descriptors

Keyboard core public API:

- semantic provider protocol
- semantic descriptor models consumed by keyboard features and future accessibility adapters

## Dependency Direction

Allowed:

- `WorkspaceKit` depends on both keyboard core and MathInput core
- keyboard core depends only on semantic abstractions, not MathInput concrete types

Forbidden:

- MathInput core depending on FormulaKeyboard core for semantic truth
- semantic snapshot APIs depending on FormulaDisplay SwiftUI or app code

## App Boundary

The app target must never generate mathematical semantics.

The app may:

- observe app-level feedback surfaced through Workspace or future accessibility adapters

The app may not:

- synthesize numerator/denominator/exponent/radicand semantics from its own views
- build VoiceOver math trees from LaTeX strings

## Stable Semantic IDs

Recommended long-term semantic node identity source:

- editor-meaningful structural IDs derived from AST position and field identity

They must not be based on:

- display wrapper `sequence[0]` nodes
- SwiftUI view identity
- rendered image positions
- raw LaTeX token indices

At minimum, semantic IDs must be able to distinguish:

- node kind
- field identity
- structural path
- insertion context where relevant

## Relationship Between AST Path, FieldID, FormulaInsertionID, And Display Wrappers

### AST path

- source of edit truth
- owned by MathInput

### `FieldID`

- structural slot identity
- source of field semantics

### `FormulaInsertionID`

- display/navigation identity for insertion positions
- useful to bridge visual positions back to editor positions
- not sufficient alone to express all semantic hierarchy

### display wrappers

- implementation details of projection/display structure
- must not leak into the long-term semantic truth boundary

This is especially important because Phase 2C already found bugs caused by display-only wrapper path contamination.

## Cursor Structural Context

The semantic snapshot must eventually expose read-only cursor context such as:

- current semantic node path
- current field kind
- current structural role
- whether the cursor is at a field boundary or inside content

This must be read-only and host-consumable.

It must not require the keyboard framework to inspect AST directly.

## Selection Context

v1.0 only needs a reserve boundary.

It does not need to implement full selection semantics yet.

But the semantic snapshot contract must leave room for:

- anchor
- focus
- selected structural region
- collapsed vs ranged selection

## Minimum Information The Keyboard Framework Needs

For v1.0 reserve only, the framework needs to be able to ask for:

- current page-safe structural context
- whether current action is semantically valid in context
- current focus/cursor structure label IDs
- future feedback context such as “inside denominator” or “at structure boundary”

The framework does not need to own full spoken output logic in v1.0.

## Why LaTeX And Render Trees Are Not Enough

LaTeX is insufficient because:

- it is a serialization form
- it loses editor-only distinctions
- equivalent math can serialize in multiple ways

Render trees are insufficient because:

- they are layout products
- they can contain wrappers with no AST meaning
- they are host and backend dependent

## Accessibility Readiness Impact

This decision protects v1.1 from a major re-architecture:

- semantic consumers can evolve without changing keyboard core ownership
- real user-tested speech/focus behavior can be layered on top of stable structural providers
- keyboard framework does not need to guess mathematical meaning from visuals

## Testing Impact

Future tests should cover:

- semantic snapshot stability under cursor movement
- semantic node ID stability under projection refresh
- field-role exposure for representative templates
- no leakage of display-only wrapper paths into semantic IDs

## Compatibility Window

Allowed transitional state:

- v1.0 may ship with no-op or minimal semantic provider implementations

Not allowed:

- baking final VoiceOver math narration policy into the framework before user research

## Removal Conditions

Any temporary adapter that maps rendered output back into semantic data must be deleted before v1.1 accessibility implementation begins.

## Open Questions

- Should semantic snapshots be emitted directly from `EditorState`, or from a read-only adapter that also knows `TemplateDefinition` navigation hints?
- Do we need a distinct `MathSemanticNodeID` type, or can an existing structural path type be wrapped safely?
- Which parts of selection context should become public in v1.0 versus remaining internal until Phase 2C selection work exists?
