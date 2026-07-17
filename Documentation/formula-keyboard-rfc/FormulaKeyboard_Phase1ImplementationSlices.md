# Formula Keyboard Phase 1 Implementation Slices

## Status

Phase 0.75 defines Phase 1 as a set of independent, reversible slices.

Phase 1 remains limited to definition and action-contract work.

It does not include:

- renderer migration
- press-session behavior
- legacy removal
- production keyboard replacement

## Slice Policy

Each slice must:

- have a clean commit boundary
- compile independently
- keep rollback local
- avoid mixing with Commit A and Commit B
- declare any temporary adapter and its removal phase

## P1-A — New Package Skeleton

- Package modified:
  - `SharedLibraries/EMathicaFormulaKeyboardKit`
- New files:
  - `Package.swift`
  - empty marker files in each target
  - minimal marker tests
- Existing code modified:
  - `EMathicaWorkspaceKit/Package.swift` only if dependency wiring is required immediately
- Dependencies:
  - `EMathicaFormulaDisplayKit`
  - `EMathicaThemeKit`
- Tests:
  - `swift test` in the new package
- Manual validation:
  - package resolves in Xcode
- Commit boundary:
  - dedicated Commit C only
- Rollback:
  - remove package folder and package references
- Completion condition:
  - package compiles with empty targets
- Temporary adapter:
  - none
- Adapter removal phase:
  - n/a

## P1-B — Stable ID And Primitive Models

- Package modified:
  - `EMathicaFormulaKeyboardCore`
- New files:
  - `FormulaKeyID`
  - page ID
  - layout variant ID
  - primitive resource IDs
- Existing code modified:
  - none
- Dependencies:
  - Foundation only
- Tests:
  - Hashable / Sendable / stability tests
- Manual validation:
  - none beyond tests
- Commit boundary:
  - one isolated core-model commit
- Rollback:
  - revert new core model files only
- Completion condition:
  - IDs compile and are test-covered
- Temporary adapter:
  - none
- Adapter removal phase:
  - n/a

## P1-C — Content / Role / Placement / Size

- Package modified:
  - `EMathicaFormulaKeyboardCore`
- New files:
  - `FormulaKeyContent`
  - `FormulaKeyPlacement`
  - `FormulaKeySize`
  - `FormulaKeyRole`
- Existing code modified:
  - none
- Dependencies:
  - Foundation only
- Tests:
  - Codable policy tests where applicable
  - role/content invariants
- Manual validation:
  - none beyond tests
- Commit boundary:
  - isolated core-definition commit
- Rollback:
  - revert added type files
- Completion condition:
  - no View/closure/AST leakage into core models
- Temporary adapter:
  - none
- Adapter removal phase:
  - n/a

## P1-D — Action And Result Models

- Package modified:
  - `EMathicaFormulaKeyboardCore`
- New files:
  - `FormulaKeyAction`
  - `FormulaKeyActionResult`
  - keyboard-local action families
- Existing code modified:
  - none in production host yet
- Dependencies:
  - Foundation only
- Tests:
  - action classification
  - result equality and diagnostics
- Manual validation:
  - none beyond tests
- Commit boundary:
  - isolated action-model commit
- Rollback:
  - revert action files
- Completion condition:
  - actions can represent editor, host, and local keyboard intents separately
- Temporary adapter:
  - none yet
- Adapter removal phase:
  - n/a

## P1-E — Keyboard Definition And Page Definition

- Package modified:
  - `EMathicaFormulaKeyboardCore`
- New files:
  - `FormulaKeyboardDefinition`
  - `FormulaKeyboardPageDefinition`
  - definition container types
- Existing code modified:
  - none
- Dependencies:
  - prior Phase 1 core slices only
- Tests:
  - definition construction invariants
  - page uniqueness tests
- Manual validation:
  - none beyond tests
- Commit boundary:
  - isolated definition commit
- Rollback:
  - revert definition files
- Completion condition:
  - page/definition model exists without SwiftUI
- Temporary adapter:
  - none
- Adapter removal phase:
  - n/a

## P1-F — Semantic Reserve Models

- Package modified:
  - `EMathicaFormulaKeyboardCore`
- New files:
  - `FormulaKeyboardStateSnapshot`
  - `FormulaKeySemanticDescriptor`
  - focus/feedback reserve protocol placeholders
- Existing code modified:
  - none
- Dependencies:
  - Foundation only
- Tests:
  - placeholder protocol conformance and no-op snapshot tests
- Manual validation:
  - none
- Commit boundary:
  - isolated semantic-reserve commit
- Rollback:
  - revert reserve-model files
- Completion condition:
  - accessibility boundary placeholders exist without user-experience claims
- Temporary adapter:
  - default no-op providers allowed
- Adapter removal phase:
  - replace by v1.1 real providers; no-op placeholders remain only if still useful

## P1-G — Builtin Definition Adapter

- Package modified:
  - `EMathicaFormulaKeyboardBuiltin`
  - possibly read-only references in existing keyboard definition files
- New files:
  - builtin-definition scaffolding
  - adapter layer from current sources to new declaration model
- Existing code modified:
  - minimal read-only extraction points only
- Dependencies:
  - `EMathicaFormulaKeyboardCore`
- Tests:
  - built-in definition snapshot tests
  - duplicate ID detection
- Manual validation:
  - confirm no production UI migration yet
- Commit boundary:
  - builtin-definition-only commit
- Rollback:
  - revert builtin adapter files
- Completion condition:
  - builtin definitions exist in SharedLibraries, but production keyboard still consumes legacy UI path
- Temporary adapter:
  - current static/runtime keyboard definition bridge
- Adapter removal phase:
  - Phase 8

## P1-H — Validation Baseline

- Package modified:
  - `EMathicaFormulaKeyboardCore`
  - maybe `EMathicaFormulaKeyboardBuiltin`
- New files:
  - minimal validators for Phase 1
- Existing code modified:
  - none
- Dependencies:
  - core and builtin only
- Tests:
  - duplicate key ID
  - missing page
  - illegal placement primitive checks
- Manual validation:
  - none beyond tests
- Commit boundary:
  - isolated validation-baseline commit
- Rollback:
  - revert validation files
- Completion condition:
  - Phase 1 has only structural validation required to keep definitions sane
- Temporary adapter:
  - none
- Adapter removal phase:
  - n/a

## Recommended Commit Order

1. `P1-A` New Package Skeleton
2. `P1-B` Stable ID And Primitive Models
3. `P1-C` Content / Role / Placement / Size
4. `P1-D` Action And Result Models
5. `P1-E` Keyboard Definition And Page Definition
6. `P1-F` Semantic Reserve Models
7. `P1-G` Builtin Definition Adapter
8. `P1-H` Validation Baseline

## What Phase 1 Must Not Do

- no renderer migration
- no prepared-content implementation
- no touch/hardware dispatcher replacement
- no keyboard host rewiring
- no legacy deletion
- no App-private duplicate definitions

## Exit Condition For Phase 1

Phase 1 is complete only when:

- the new package exists
- authoritative definition types live in SharedLibraries
- authoritative action types live in SharedLibraries
- builtin definitions have a declared home in SharedLibraries
- minimum semantic reserve types exist
- baseline validation exists

But production keyboard behavior may still remain on the old rendering/interaction stack until later phases.
