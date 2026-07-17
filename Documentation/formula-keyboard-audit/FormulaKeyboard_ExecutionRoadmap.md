# FormulaKeyboard Execution Roadmap

## Phase 0 - Audit And Baseline Freeze

### Add

- audit reports
- baseline file inventory
- behavior matrix
- legacy deletion targets

### Modify

- none

### Delete

- none

### Do not modify

- MathInput AST
- FormulaDisplay public APIs
- Workspace command semantics

### Tests

- capture current package tests and app build baseline

### Manual validation

- current touch keyboard pages
- current hardware key paths
- current formula preview behavior

### Risks

- incomplete production call graph

### Rollback

- not needed; docs only

### Exit condition

- baseline behavior and debt map are frozen

## Phase 1 - Core Definition And Action Contract

### Add

- `FormulaKeyDefinition`
- `FormulaKeyContent`
- `FormulaKeyPlacement`
- `FormulaKeySize`
- `FormulaKeyRole`
- `FormulaKeyBehavior`
- `FormulaKeyAction`
- stable ids
- semantic metadata placeholders

### Modify

- temporary adapters from current built-in definitions to new core models

### Delete

- no deletion yet

### Do not modify

- FormulaDisplay rendering internals
- MathInput AST mutation semantics

### Tests

- model construction
- stable ids
- action equality/hashability
- schema snapshot tests

### Manual validation

- inspect generated built-in definition dump

### Risks

- overfitting current UI instead of building a reusable schema

### Rollback

- keep adapter-only adoption behind feature boundary until Phase 4

### Exit condition

- one authoritative definition model exists for all builtin keys

## Phase 2 - Validation, Diagnostics, And Schema

### Add

- validator
- diagnostics result model
- schema version
- serialization boundary

### Modify

- built-in definitions to satisfy validator

### Delete

- none

### Do not modify

- editor mutation logic

### Tests

- duplicate ids
- invalid placement
- unsupported content
- missing pages
- missing semantic metadata required by schema

### Manual validation

- run diagnostics against full builtin definition

### Risks

- silent adapter bypass around validator

### Rollback

- validator can start as non-fatal in debug only, but must become required before Phase 8

### Exit condition

- framework definitions fail fast when structurally invalid

## Phase 3 - Layout, Environment, And Metrics

### Add

- logical grid / placement model
- layout variants
- metrics model
- environment injection

### Modify

- current row-weight layout into compatibility variant

### Delete

- no deletion yet

### Do not modify

- FormulaDisplay content semantics

### Tests

- variant layout snapshots
- spans
- compact/regular metrics
- large target variants

### Manual validation

- iPad landscape
- iPad split view
- smaller host widths

### Risks

- preserving current magic numbers as permanent model

### Rollback

- keep compatibility variant until all builtin pages match

### Exit condition

- layout is definition-driven rather than view-tree-driven

## Phase 4 - Renderer And Three-Layer FormulaKey

### Add

- background layer
- content layer
- interaction layer
- prepared-content formula label renderer

### Modify

- current label routing and FormulaDisplay integration

### Delete

- probe-and-render double parse path once replacement is stable

### Do not modify

- MathInput AST

### Tests

- formula label rendering
- icon rendering
- baseline and bounds
- pressed state does not reparse formula

### Manual validation

- numbers
- functions
- symbols
- alphabet

### Risks

- accidental FormulaDisplay coupling through live view state

### Rollback

- temporary renderer adapter until all label types match

### Exit condition

- key content rendering is isolated from business behavior and does not double parse

## Phase 5 - Interaction, Behavior, And Press Session

### Add

- press session model
- tap
- long press
- repeat
- cancel
- alternate action hooks

### Modify

- `MathInputKeyboardKeyView` interaction logic

### Delete

- ad hoc per-view gesture behavior

### Do not modify

- editor AST logic

### Tests

- tap
- repeat
- long press threshold
- cancel
- move-out behavior
- disabled state

### Manual validation

- delete hold
- arrow hold
- page switch touch behavior

### Risks

- hidden business logic still attached to view lifecycle

### Rollback

- keep one compatibility activator until new behavior state machine is stable

### Exit condition

- all key interaction emits only `FormulaKeyAction`

## Phase 6 - Dispatcher And Unified Input Command Path

### Add

- `FormulaKeyboardDispatcher`
- one ingress contract for touch, hardware, and test drivers

### Modify

- built-in touch path
- hardware path
- workspace action forwarding

### Delete

- duplicate upstream action conversions once unified

### Do not modify

- legacy FormulaDisplay rendering unrelated to keyboard

### Tests

- same action via touch/hardware/test driver yields same editor mutation
- dispatcher integration tests

### Manual validation

- touch insertions
- hardware insertions
- delete
- movement
- submit

### Risks

- hidden third path through plain text diffing

### Rollback

- keep text-field compatibility path explicitly isolated until an RFC handles it

### Exit condition

- touch and hardware no longer diverge before the shared dispatcher boundary

## Phase 7 - Accessibility Integration Boundary

### Add

- semantic descriptor boundary
- keyboard state snapshot
- focus routing boundary
- feedback provider boundary
- system preference injection boundary
- test replacement hooks

### Modify

- none beyond integration points

### Delete

- no production behavior deletion required

### Do not modify

- do not hard-code final spoken math UX
- do not claim final a11y support

### Tests

- every key has stable semantic id
- actions are executable off-view
- semantic providers are swappable
- focus routing is model-driven
- no-op default providers do not change behavior

### Manual validation

- enable VoiceOver / Reduce Motion / Increase Contrast only as non-regression smoke tests

### Risks

- pretending placeholder interfaces equal full accessibility support

### Rollback

- keep providers default-empty while preserving real boundaries

### Exit condition

- v1.1 can start real accessibility work without keyboard-core re-architecture

## Phase 8 - Builtin Keyboard Full Migration

### Add

- final builtin definitions in framework schema

### Modify

- Workspace mounting to use new framework surface only

### Delete

- old builtin keyboard implementations that are no longer called

### Do not modify

- MathInput AST public semantics without RFC

### Tests

- page coverage
- action coverage
- rendering coverage
- dispatcher convergence

### Manual validation

- digits/operators
- templates
- functions
- cursor movement
- delete
- page switching

### Risks

- silently preserving one legacy page

### Rollback

- limited feature flag during cutover only

### Exit condition

- all builtin pages are definition-driven and no new key is added to legacy paths

## Phase 9 - Legacy Deletion And Dependency Closure

### Add

- none

### Modify

- tests updated to assert deletion of legacy paths

### Delete

- legacy keyboard view
- legacy key model
- legacy adapter
- legacy layout abstractions

### Do not modify

- unrelated editor modules

### Tests

- no production caller of legacy paths
- no filesystem presence if deletion is complete

### Manual validation

- smoke check after deletion

### Risks

- hidden test or preview dependency on legacy files

### Rollback

- revert deletion commit only if a real caller remains

### Exit condition

- only one keyboard architecture remains

## Phase 10 - Device Validation And Cleanup

### Add

- final acceptance checklist

### Modify

- cleanup of temporary migration adapters and debug-only migration scaffolding

### Delete

- any migration-only bridge that has satisfied its removal condition

### Do not modify

- unrelated product features

### Tests

- package tests
- app build
- renderer regression
- dispatcher regression

### Manual validation

- iPad landscape
- iPad split view
- formula preview
- touch keyboard
- hardware keyboard
- system preference smoke tests

### Risks

- leaving transitional adapters indefinitely

### Rollback

- revert latest migration slice if acceptance fails

### Exit condition

- production uses one framework
- legacy is removed
- temporary migration debt is zero or explicitly ticketed with a removal version

## Legacy Latest Deletion Targets

| Legacy item | Latest deletion phase |
|---|---|
| `MathKeyboardView` | Phase 9 |
| `KeyboardKey` | Phase 9 |
| `WorkspaceMathKeyboardAdapter` | Phase 9 |
| `MathKeyboardTab` legacy layer | Phase 9 |
| direct-action template exceptions | Phase 8 |
| split alphabet authority | Phase 8 |

## Roadmap Verdict

The migration should move quickly from:

- one mixed keyboard implementation

to:

- one declarative framework with validation, renderer isolation, one dispatcher, and reserved accessibility boundaries

before any large v1.1 accessibility behavior work begins.
