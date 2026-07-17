# Formula Keyboard Phase 0.5 Decision Summary

## Status

Phase 0.5 freezes the SharedLibraries ownership and contract direction for the future Formula Keyboard Framework.

This phase does not implement the framework.

## Final Ownership Decision

Recommended package:

- `EMathicaFormulaKeyboardKit`

Recommended targets:

- `EMathicaFormulaKeyboardCore`
- `EMathicaFormulaKeyboardBuiltin`
- `EMathicaFormulaKeyboardRendering`
- `EMathicaFormulaKeyboardSwiftUI`

## Why Not An App-Private Implementation

The app target is explicitly rejected as the framework owner because:

- it would destroy package-level reuse
- it would duplicate builtin definitions
- it would make testing dependent on one app scene
- it would force future accessibility work to target app-local view structure instead of shared contracts

## Final Boundary Freeze

### Core

Owned by:

- `EMathicaFormulaKeyboardCore`

### Builtin definitions

Owned by:

- `EMathicaFormulaKeyboardBuiltin`

### Prepared rendering

Owned by:

- `EMathicaFormulaKeyboardRendering`

with a required prepared-content boundary from:

- `EMathicaFormulaDisplayKit`

### SwiftUI keyboard surface

Owned by:

- `EMathicaFormulaKeyboardSwiftUI`

### Workspace host

Owned by:

- `EMathicaWorkspaceKit`

### App consumer

Owned by:

- `eMathica` app target

consumer only

## Final Action Decision

Authoritative keyboard action:

- `FormulaKeyAction`

Authoritative editor command:

- future `MathInputEditorCommand`

Transitional compatibility only:

- `MathKeyboardIntent`
- `MathInputToken`
- `KeyboardAction`

## Final Semantic Decision

Mathematical structural truth belongs to:

- `EMathicaMathInputKit`

Keyboard framework owns only the semantic consumption boundary, not semantic truth itself.

## Final Host Decision

`FormulaKeyboardHost` lives in:

- `EMathicaFormulaKeyboardCore`

and is implemented by:

- `EMathicaWorkspaceKit`

The app target must not implement the production host.

## Final Dependency Direction

Allowed high-level direction:

```text
EMathicaFormulaKeyboardBuiltin
        ↓
EMathicaFormulaKeyboardCore

EMathicaFormulaKeyboardRendering
        ↓
EMathicaFormulaKeyboardCore
        ↓
EMathicaFormulaDisplayCore

EMathicaFormulaKeyboardSwiftUI
        ↓
EMathicaFormulaKeyboardRendering
        ↓
EMathicaFormulaKeyboardCore
        ↓
EMathicaThemeKit

EMathicaWorkspaceKit
        ↓
EMathicaFormulaKeyboardCore
        ↓
EMathicaFormulaKeyboardBuiltin
        ↓
EMathicaFormulaKeyboardSwiftUI
        ↓
EMathicaMathInputCore
        ↓
EMathicaFormulaDisplayKit

eMathica App
        ↓
EMathicaWorkspaceKit
```

Forbidden:

- keyboard core -> WorkspaceKit
- keyboard core -> app
- MathInput core -> keyboard SwiftUI
- FormulaDisplay core -> keyboard SwiftUI

## Adapter Policy

Allowed temporary adapters:

- current static layout -> new builtin definition adapter
- current `KeyboardAction` bridge inside Workspace host
- current raw formula-label path behind rendering adapter

Every adapter must have a deletion phase and condition.

## Latest Removal Deadlines

- definition adapters: latest Phase 8
- dispatcher compatibility adapters: latest Phase 9
- legacy keyboard UI: latest Phase 9

No adapter may remain without a declared removal condition.

## Phase 1 Entry Criteria

Phase 1 may begin only with:

- framework package ownership frozen
- action authority frozen
- prepared render boundary frozen
- semantic snapshot ownership frozen
- workspace host boundary frozen

## Phase 1 Exit Expectation

After Phase 1, the project should have:

- authoritative definition types in SharedLibraries
- authoritative action types in SharedLibraries
- no new keyboard authority added to the app target

## Open Questions Kept Explicit

Must resolve before implementation if they block code shape:

- exact `MathInputEditorCommand` public surface
- exact FormulaDisplay prepared-content API shape

May wait until later implementation phases:

- final cache eviction policy
- exact larger-variant metrics tables

Must remain research-driven until v1.1:

- final VoiceOver wording
- final focus order strategy
- final structural speech/navigation behavior for assistive technologies
