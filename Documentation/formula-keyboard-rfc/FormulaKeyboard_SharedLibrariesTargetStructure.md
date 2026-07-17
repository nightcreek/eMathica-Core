# Formula Keyboard SharedLibraries Target Structure

## Recommended Package Decision

Recommended new SharedLibraries package:

- `EMathicaFormulaKeyboardKit`

Recommended targets:

- `EMathicaFormulaKeyboardCore`
- `EMathicaFormulaKeyboardBuiltin`
- `EMathicaFormulaKeyboardRendering`
- `EMathicaFormulaKeyboardSwiftUI`

This is preferred over adding new targets to `EMathicaMathInputKit` because:

- keyboard framework ownership stays separate from editor semantics
- builtin definitions get a clean, non-app home
- rendering and SwiftUI can evolve without making MathInputKit the keyboard UI package forever
- WorkspaceKit remains a host/consumer instead of becoming the framework

## Recommended Directory Tree

```text
SharedLibraries/
└── EMathicaFormulaKeyboardKit/
    ├── Package.swift
    ├── Sources/
    │   ├── EMathicaFormulaKeyboardCore/
    │   │   ├── AccessibilityBoundary/
    │   │   ├── Action/
    │   │   ├── Definition/
    │   │   ├── Diagnostics/
    │   │   ├── Dispatcher/
    │   │   ├── Environment/
    │   │   ├── Layout/
    │   │   ├── Metrics/
    │   │   ├── Serialization/
    │   │   ├── State/
    │   │   └── Validation/
    │   ├── EMathicaFormulaKeyboardBuiltin/
    │   │   ├── Pages/
    │   │   ├── Variants/
    │   │   └── Resources/
    │   ├── EMathicaFormulaKeyboardRendering/
    │   │   ├── Cache/
    │   │   ├── Diagnostics/
    │   │   ├── FormulaDisplayAdapter/
    │   │   └── PreparedContent/
    │   └── EMathicaFormulaKeyboardSwiftUI/
    │       ├── Behavior/
    │       ├── HostAdapters/
    │       ├── Interaction/
    │       ├── ThemeAdapters/
    │       └── Views/
    └── Tests/
        ├── EMathicaFormulaKeyboardCoreTests/
        ├── EMathicaFormulaKeyboardRenderingTests/
        └── EMathicaFormulaKeyboardSwiftUITests/
```

## Ownership By Target

### `EMathicaFormulaKeyboardCore`

Owns:

- declaration models
- action models
- validators
- layout model and logical grid
- serialization
- diagnostics contracts
- accessibility reserve protocols
- host and dispatcher protocols

### `EMathicaFormulaKeyboardBuiltin`

Owns:

- the builtin number/function/alphabet/symbol page definitions
- static key IDs and resource bindings
- variant-specific builtin definitions

### `EMathicaFormulaKeyboardRendering`

Owns:

- prepared key content
- render cache
- FormulaDisplay integration adapter
- render diagnostics for key content

### `EMathicaFormulaKeyboardSwiftUI`

Owns:

- visual keyboard composition
- background/content/interaction layers
- press-session UI behavior
- ThemeKit adaptation

## Existing File Migration Targets

### From `EMathicaMathInputKit`

Move conceptually in later phases:

- `MathKeyboardKey.swift` -> `EMathicaFormulaKeyboardCore/Definition`
- `MathKeyboardLabel.swift` -> `EMathicaFormulaKeyboardCore/Definition`
- `MathKeyboardLayout.swift` -> split between `EMathicaFormulaKeyboardCore/Definition` and `EMathicaFormulaKeyboardBuiltin/Pages`
- `HardwareKeyboardSemanticMapper.swift` -> `EMathicaFormulaKeyboardCore/Action` once mapping is decoupled from raw UIKit ingress
- `MathInputKeyboardSurfaceModel.swift` -> split between core state model and SwiftUI host state adapter
- `MathInputKeyboardView.swift` -> `EMathicaFormulaKeyboardSwiftUI/Views`
- `MathInputKeyboardPanelView.swift` -> `EMathicaFormulaKeyboardSwiftUI/Views`
- `MathInputKeyboardKeyView.swift` -> `EMathicaFormulaKeyboardSwiftUI/Views`
- `MathInputKeyboardLabelView.swift` -> `EMathicaFormulaKeyboardSwiftUI/Views`
- `MathKeyboardFormulaLabelView.swift` -> split across rendering and SwiftUI
- `MathInputKeyboardStyleBridge.swift` -> mostly replaced by core role/metrics plus SwiftUI theme adapters

Stay in `EMathicaMathInputKit`:

- `MathInputToken.swift` until transitional bridges are deleted
- `MathEditorState.swift`
- `MathEditorAST.swift`
- `MathEditorEngine.swift`
- `TemplateDefinition.swift`
- `MathFormulaProjection.swift`
- `FormulaDisplayBridge.swift`

### From `EMathicaWorkspaceKit`

Stay in `WorkspaceKit`:

- `WorkspaceView.swift`
- `WorkspaceState.swift`
- `FormulaEditingDisplayView.swift`
- `FormulaDisplayPreviewView.swift`
- `HardwareKeyboardCaptureView.swift`
- `MathPlainTextField.swift`
- `FormulaInputState.swift`

Migrate or replace later:

- `FormulaEditorView.swift` only insofar as interaction overlay responsibilities are superseded by framework hosting contracts
- `MathKeyboardVisualMetrics.swift` should disappear with legacy removal

### From `EMathicaFormulaDisplayKit`

Stay in `FormulaDisplayKit`:

- formula document model
- parser/lowering/rendering
- read-only probe APIs

Add new boundary later:

- prepared keyboard content support for static formula labels

### From `eMathica` app

Stay in app:

- `AppRootView.swift`
- module-level workspace configuration
- app feature flags
- app integration tests

Must not appear in app:

- builtin keyboard definition copies
- keyboard action translator
- keyboard renderer core

## Package.swift Impact

### New package

Add:

- `SharedLibraries/EMathicaFormulaKeyboardKit/Package.swift`

### `EMathicaWorkspaceKit`

Will need new dependencies on:

- `EMathicaFormulaKeyboardCore`
- `EMathicaFormulaKeyboardBuiltin`
- `EMathicaFormulaKeyboardSwiftUI`

### `EMathicaMathInputKit`

May temporarily keep existing keyboard files during migration, but should not gain ownership of the new framework package.

### `EMathicaFormulaDisplayKit`

May need public or package-level prepared-content boundary additions, but should not depend on the new keyboard package.

## Xcode Project / Workspace Impact

Expected changes in later phases:

- add local package reference for `EMathicaFormulaKeyboardKit`
- update scheme/package dependency graph
- add package test targets to CI

No app-private workaround should replace this package wiring.

## Cycle Avoidance

This structure prevents the most important cycles:

- keyboard core -> workspace
- keyboard core -> app
- formula display -> keyboard SwiftUI
- MathInput core -> keyboard SwiftUI

## Legacy Retention Boundary

Legacy keyboard files may remain in `EMathicaWorkspaceKit/Legacy/Keyboard` until Phase 9.

They must not become a second migration destination.

## Final Structural Rule

After Phase 1 starts, all new framework code should land in:

- `SharedLibraries/EMathicaFormulaKeyboardKit`

or in explicit cross-module boundary extensions inside:

- `EMathicaMathInputKit`
- `EMathicaFormulaDisplayKit`
- `EMathicaWorkspaceKit`

but never as new authoritative keyboard infrastructure inside the app target.
