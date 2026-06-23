# Workspace ↔ Plane Decoupling Plan

> **Date:** 2026-06-05
> **Scope:** Design only — no code modified.
> **Goal:** Eliminate WorkspaceKit's reverse dependency on CalculatorModules/Plane, enabling future WorkspaceKit Package extraction.
> **Prerequisite:** EMathicaMathCore Package extraction (completed).

---

## 1. Current Problem

### 1.1 Direct Plane Service Calls in WorkspaceState

`WorkspaceKit/WorkspaceState.swift` contains **25 references** to Plane-specific types and functions. These are NOT behind protocols — they are direct static method calls.

#### Category A: Geometry Dependency Recompute (4 call sites)

| Line | Call | Purpose |
|------|------|---------|
| 370 | `PlaneGeometryDependencyRecomputeService.dependencyPatches(objects:changedSourceIDs:)` | Recompute derived geometry positions when source objects change |
| 469 | `PlaneGeometryDependencyRecomputeService.dependencyCleanupPatchesForRemovedSources(objects:removedSourceIDs:)` | Clear geometry dependencies when source objects are deleted |
| 485 | `PlaneGeometryDependencyRecomputeService.directlyAffectedDerivedObjectIDs(objects:candidateSourceIDs:)` | Find objects directly affected by a change |
| 492 | `PlaneGeometryDependencyRecomputeService.downstreamAffectedDerivedObjectIDs(objects:candidateSourceIDs:)` | Find objects transitively affected by a change |

#### Category B: Semantic Graph Intent Adapter (6 call sites, 3 per commit path)

| Line | Call | Purpose |
|------|------|---------|
| 1229, 1271, 1460 | `PlaneSemanticGraphIntentAdapter.semanticGraphKind(from:)` | Convert `GraphIntent` → `SemanticGraphKind` |
| 1232, 1274, 1463 | `PlaneSemanticGraphIntentAdapter.parameterSymbol(from:)` | Extract parameter symbol from `GraphIntent` |
| 1235, 1277, 1466 | `PlaneSemanticGraphIntentAdapter.parameterRange(from:)` | Extract parameter range from `GraphIntent` |

#### Category C: Input Canonicalization (embedded method)

| Line | Method | Purpose |
|------|--------|---------|
| 1666 | `canonicalPlaneCommitInput(from:)` | Rewrite input like `y=x^2` → `y=x^2` based on graph classification |

### 1.2 Space Type Dependency in WorkspaceKit

`WorkspaceKit/WorkspaceModuleProviding.swift` line 18:
```swift
var spaceWorkPlane: SpaceWorkPlane?  // 🔴 Defined in CalculatorModules/Space/Models/
```

`WorkspaceKit/WorkspaceState.swift` line 32:
```swift
var activeSpaceWorkPlane: SpaceWorkPlane  // 🔴 Defined in CalculatorModules/Space/Models/
```

`SpaceWorkPlane` is a simple 3-case enum (`xy`, `yz`, `zx`) defined in `CalculatorModules/Space/Models/SpaceWorkPlane.swift`. By contrast, `SpaceCameraState` (used in the same context) is defined in `MathCore/Coordinate/SpaceMath3D.swift` — the correct location.

### 1.3 AppNavigationState Dependency in WorkspaceView

`WorkspaceKit/WorkspaceView.swift` line 4:
```swift
@Environment(AppNavigationState.self) private var navigation
```

Used at:
- Line 76: `navigation.closeWorkspaceSaving(state.document)`
- Line 178: `try navigation.renameProject(id: id, title: title)`

`AppNavigationState` is defined in `App/AppNavigationState.swift`. WorkspaceKit depends on the App module's concrete navigation type.

### 1.4 Why This Is a Reverse Dependency

```
CORRECT DIRECTION:
  App → CoreHome → CalculatorModules → WorkspaceKit → MathCore

ACTUAL (BROKEN):
  WorkspaceKit ──depends on──→ CalculatorModules/Plane/Services/*
  WorkspaceKit ──depends on──→ CalculatorModules/Space/Models/SpaceWorkPlane
  WorkspaceKit ──depends on──→ App/AppNavigationState
```

The framework layer (WorkspaceKit) depends on the implementation layer (Plane/Space). This means:
- WorkspaceKit **cannot** be a standalone Package
- Adding a new calculator module (e.g., Notes) would require modifying WorkspaceKit
- WorkspaceKit's `WorkspaceState` contains Plane-specific logic (`canonicalPlaneCommitInput`)
- Every calculator module that needs geometry dependency recompute or semantic graph adaptation must bake its logic into WorkspaceKit

---

## 2. Desired Architecture

### 2.1 Target Dependency Graph

```
┌──────────────────────────────────────────────────┐
│  App (entry point, DI composition root)          │
│  - Creates navigation state                      │
│  - Registers module providers                    │
│  - Injects protocols                             │
└──────────────┬───────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────┐
│  CoreHome                                        │
│  - Home screen UI                                │
└──────────────┬───────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────┐
│  CalculatorModules (per-module implementations)  │
│  Plane ──── implements GeometryDependencyService │
│  │          implements SemanticIntentAdapter     │
│  │          implements InputCanonicalizer        │
│  Space ─── implements GeometryDependencyService │
│  │          (3D version)                         │
│  Notes ─── may implement subset                  │
│  Data  ─── may implement subset                  │
│  Music ─── may implement subset                  │
└──────────────┬───────────────────────────────────┘
               │ conforms to
               ▼
┌──────────────────────────────────────────────────┐
│  WorkspaceKit (defines protocols, not impls)     │
│  - GeometryDependencyServiceProtocol             │
│  - SemanticIntentAdapterProtocol                 │
│  - InputCanonicalizerProtocol                    │
│  - WorkspaceNavigationDelegate                   │
│  - WorkspaceModuleProviding (extended)           │
└──────────────┬───────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────┐
│  EMathicaMathCore (pure math, no UI)             │
│  - SpaceMath3D, CanvasState, MathObject, etc.    │
│  - SpaceWorkPlane (relocated here)               │
└──────────────────────────────────────────────────┘
```

### 2.2 Protocol Injection Pattern

```
Module provider implements ALL workspace services:

  protocol WorkspaceModuleProviding {
      // existing
      var module: CalculatorModuleType { get }
      var toolGroups: [WorkspaceToolGroup] { get }
      var commandHandler: ModuleCommandHandler { get }
      func makeCanvasView(context:) -> AnyView
      func makeDraftMathObject(...) -> DraftMathObject?
      func buildExpression(from:fallbackToExplicitY:) -> Result<MathExpression, ...>

      // NEW — services previously called directly in WorkspaceState
      var geometryDependencyService: (any GeometryDependencyServiceProtocol)? { get }
      var semanticIntentAdapter: (any SemanticIntentAdapterProtocol)? { get }
      var inputCanonicalizer: (any InputCanonicalizerProtocol)? { get }
  }

Plane implements:

  struct PlaneWorkspaceModuleProvider: WorkspaceModuleProviding {
      var geometryDependencyService: (any GeometryDependencyServiceProtocol)? {
          PlaneGeometryDependencyService()  // wraps existing static methods
      }
      var semanticIntentAdapter: (any SemanticIntentAdapterProtocol)? {
          PlaneSemanticIntentAdapter()      // wraps existing static methods
      }
      var inputCanonicalizer: (any InputCanonicalizerProtocol)? {
          PlaneInputCanonicalizer()
      }
      // ...
  }

WorkspaceState uses protocols:

  private func applyGeometryDependencyRecompute(changedSourceIDs: Set<UUID>) {
      guard let service = moduleProvider.geometryDependencyService else { return }
      let patches = service.dependencyPatches(
          objects: document.objects,
          changedSourceIDs: changedSourceIDs
      )
      // ...
  }
```

---

## 3. Geometry Dependency Service

### 3.1 Current State

**Source:** `CalculatorModules/Plane/Services/PlaneGeometryDependencyRecomputeService.swift`

This is a static enum with ~460 lines. It resolves geometric constraints:
- Midpoint of two points
- Parallel line through a point
- Perpendicular line through a point
- Intersection of two objects (line/line, line/circle, circle/circle)
- Circle by center point and through point
- Circle by center and radius

It internally depends on:
- `PlaneGeometryResolver` (plane-specific geometry resolution)
- `PlaneIntersectionSolver` (plane-specific intersection computation)
- `DocumentObjectPatch` (from DocumentSystem)
- `MathObject`, `WorldPoint`, `GeometryDefinition`, `GeometryDependency` (from MathCore)

### 3.2 Protocol Design

```
Protocol location: WorkspaceKit/Protocols/GeometryDependencyServiceProtocol.swift
```

```swift
import Foundation

/// Resolves geometric dependency chains — recomputes derived objects when
/// their source objects change. Each calculator module (Plane/Space) provides
/// its own implementation.
protocol GeometryDependencyServiceProtocol: AnyObject, Sendable {

    /// Find objects that directly reference any of the candidate source IDs
    /// via their geometryDependency.
    func directlyAffectedDerivedObjectIDs(
        objects: [MathObject],
        candidateSourceIDs: Set<UUID>
    ) -> Set<UUID>

    /// Find all objects transitively affected (walk the dependency chain).
    func downstreamAffectedDerivedObjectIDs(
        objects: [MathObject],
        candidateSourceIDs: Set<UUID>
    ) -> Set<UUID>

    /// Produce DocumentObjectPatch values for derived objects whose source
    /// objects changed. Returns [(objectID, patch)].
    func dependencyPatches(
        objects: [MathObject],
        changedSourceIDs: Set<UUID>
    ) -> [(UUID, DocumentObjectPatch)]

    /// Produce patches that clear geometry state when source objects are
    /// deleted.
    func dependencyCleanupPatchesForRemovedSources(
        objects: [MathObject],
        removedSourceIDs: Set<UUID>
    ) -> [(UUID, DocumentObjectPatch)]
}
```

**Who defines it:** WorkspaceKit (the framework layer).

**Who implements it:** Each calculator module that supports geometric constructions. Currently only `Plane`. Future: `Space` (3D geometry), potentially `Modeling`.

**How it is injected:** Via `WorkspaceModuleProviding.geometryDependencyService`. Plane module's provider returns a `PlaneGeometryDependencyService` instance. Modules without geometry support return `nil`.

**Existing implementation migration:** The current `PlaneGeometryDependencyRecomputeService` static methods become instance methods on `PlaneGeometryDependencyService: GeometryDependencyServiceProtocol`. No logic changes needed — just wrapping.

### 3.3 Call Site Migration in WorkspaceState

Before:
```swift
// line 370
let patches = PlaneGeometryDependencyRecomputeService.dependencyPatches(
    objects: document.objects,
    changedSourceIDs: changedSourceIDs
)
```

After:
```swift
let patches = moduleProvider.geometryDependencyService?.dependencyPatches(
    objects: document.objects,
    changedSourceIDs: changedSourceIDs
) ?? []
```

The same pattern applies to all 4 call sites. The protocol is optional (`?`) because modules without geometry support (Notes, Data, Music) don't need a geometry dependency service.

---

## 4. Semantic Graph Intent Adapter

### 4.1 Current State

**Source:** `CalculatorModules/Plane/Services/PlaneSemanticGraphIntentAdapter.swift`

This is a static enum (~204 lines) that:
1. Maps `GraphIntent` (from MathCore/GraphCore) → `SemanticGraphKind` (from MathCore/MathExpression)
2. Extracts `Symbol` and `ParameterRange` from `GraphIntent`
3. Provides human-readable display names for semantic graph kinds
4. Generates metadata text for the object panel

It depends on:
- `GraphIntent`, `GraphClassificationResult` (from MathCore/GraphCore)
- `SemanticGraphKind`, `Symbol`, `ParameterRange` (from MathCore)
- `AlgebraAnalysisResult` (from MathCore/AlgebraCore)
- `Expr`, `ExprDebugPrinter` (from MathCore/SemanticCore)

**Key insight:** The adapter is conceptually NOT Plane-specific. It's a bridge between `GraphIntent` (a generic math concept) and `SemanticGraphKind` (a generic document model concept). The name "Plane" in the class name is misleading — this adapter works for any 2D graph classification.

### 4.2 Protocol Design

```
Protocol location: WorkspaceKit/Protocols/SemanticIntentAdapterProtocol.swift
```

```swift
import Foundation
import EMathicaMathCore

/// Bridges between the math-level GraphIntent and document-level
/// SemanticGraphKind, Symbol, ParameterRange.
protocol SemanticIntentAdapterProtocol: AnyObject, Sendable {

    /// Map a GraphIntent to a SemanticGraphKind for document storage.
    func semanticGraphKind(from intent: GraphIntent?) -> SemanticGraphKind?

    /// Extract the parameter symbol (e.g., "t" for parametric, "θ" for polar).
    func parameterSymbol(from intent: GraphIntent?) -> Symbol?

    /// Extract the parameter range (lower/upper bounds).
    func parameterRange(from intent: GraphIntent?) -> ParameterRange?
}
```

**Who defines it:** WorkspaceKit.

**Who implements it:** Each module that uses graph classification. The existing `PlaneSemanticGraphIntentAdapter` logic moves to `PlaneSemanticIntentAdapter: SemanticIntentAdapterProtocol`.

**Why this protocol is optional:** Some modules (Notes, Data) may not use graph classification at all, so their providers would return `nil`.

**How it is injected:** Via `WorkspaceModuleProviding.semanticIntentAdapter`.

### 4.3 Call Site Migration in WorkspaceState

Before (example, lines 1228-1237):
```swift
expression.semanticGraphKind = PlaneSemanticGraphIntentAdapter.semanticGraphKind(
    from: formulaInputState.semanticState.graphClassification?.intent
)
expression.semanticParameterSymbol = PlaneSemanticGraphIntentAdapter.parameterSymbol(
    from: formulaInputState.semanticState.graphClassification?.intent
)
expression.semanticParameterRange = PlaneSemanticGraphIntentAdapter.parameterRange(
    from: formulaInputState.semanticState.graphClassification?.intent
)
```

After:
```swift
let adapter = moduleProvider.semanticIntentAdapter
let intent = formulaInputState.semanticState.graphClassification?.intent
expression.semanticGraphKind = adapter?.semanticGraphKind(from: intent)
expression.semanticParameterSymbol = adapter?.parameterSymbol(from: intent)
expression.semanticParameterRange = adapter?.parameterRange(from: intent)
```

This pattern repeats at 3 locations (lines 1229-1237, 1271-1277, 1460-1467). A convenience helper in WorkspaceState can DRY this:

```swift
private func applySemanticIntentMetadata(to expression: inout MathExpression) {
    guard let adapter = moduleProvider.semanticIntentAdapter else { return }
    let intent = formulaInputState.semanticState.graphClassification?.intent
    expression.semanticGraphKind = adapter.semanticGraphKind(from: intent)
    expression.semanticParameterSymbol = adapter.parameterSymbol(from: intent)
    expression.semanticParameterRange = adapter.parameterRange(from: intent)
}
```

This reduces 18 lines of duplicate code across 3 call sites to a single helper call.

---

## 5. Input Canonicalization

### 5.1 Current State

**Location:** `WorkspaceKit/WorkspaceState.swift` lines 1666–1678:

```swift
private func canonicalPlaneCommitInput(from trimmedSource: String) -> String {
    guard let intent = formulaInputState.semanticState.graphClassification?.intent else {
        return trimmedSource
    }
    switch intent {
    case .explicitY(let expression, _):
        return "y=\(ExprInfixSerializer().serialize(expression))"
    case .explicitX(let expression, _):
        return "x=\(ExprInfixSerializer().serialize(expression))"
    default:
        return trimmedSource
    }
}
```

### 5.2 Why It Should Not Be in WorkspaceState

1. **It's a Plane-2D-specific concept.** The method rewrites `y=x^2+1` as `y=x^2+1` by recognizing the graph intent `explicitY(expr)`. This logic assumes a 2D coordinate system with x/y variables. A Space module or Notes module would not use this.

2. **It's called from 2 commit paths** (new object creation at line 1254, editing at line 1443) — both are generic "commit formula input" flows that should work for any module.

3. **The method name contains "Plane".** It's a documented admission that Plane logic leaked into the framework.

4. **It references `ExprInfixSerializer`** which is a MathCore type — the serialization itself is fine, but the decision to do `"y=\(...)"` is a Plane convention.

### 5.3 Protocol Design

```
Protocol location: WorkspaceKit/Protocols/InputCanonicalizerProtocol.swift
```

```swift
import Foundation

/// Canonicalizes raw user input before it is parsed/built into a MathExpression.
/// Different modules have different canonical forms (e.g., Plane rewrites
/// explicit-y as "y=expr", Space may use 3D coordinate conventions).
protocol InputCanonicalizerProtocol: AnyObject, Sendable {

    /// Transform the trimmed user input into the module's canonical form.
    /// - Parameter source: Raw trimmed input string
    /// - Parameter semanticState: The current semantic analysis state
    /// - Returns: Canonicalized input string for the module's expression builder
    func canonicalize(
        source: String,
        semanticState: FormulaSemanticState
    ) -> String
}
```

**Who defines it:** WorkspaceKit.

**Who implements it:** Each module. `PlaneInputCanonicalizer` contains the existing `canonicalPlaneCommitInput` logic. `DefaultInputCanonicalizer` returns the source unchanged (identity transform).

**How it is injected:** Via `WorkspaceModuleProviding.inputCanonicalizer`.

### 5.4 Call Site Migration in WorkspaceState

Before:
```swift
let canonicalInput = canonicalPlaneCommitInput(from: text)
```

After:
```swift
let canonicalizer = moduleProvider.inputCanonicalizer ?? DefaultInputCanonicalizer()
let canonicalInput = canonicalizer.canonicalize(
    source: text,
    semanticState: formulaInputState.semanticState
)
```

### 5.5 Placement of Implementation

| File | Location |
|------|----------|
| `InputCanonicalizerProtocol` | `WorkspaceKit/Protocols/InputCanonicalizerProtocol.swift` |
| `DefaultInputCanonicalizer` | `WorkspaceKit/Protocols/DefaultInputCanonicalizer.swift` (identity transform) |
| `PlaneInputCanonicalizer` | `CalculatorModules/Plane/Services/PlaneInputCanonicalizer.swift` |

---

## 6. SpaceWorkPlane Relocation

### 6.1 Current State

**Source:** `CalculatorModules/Space/Models/SpaceWorkPlane.swift`

```swift
enum SpaceWorkPlane: String, CaseIterable, Hashable {
    case xy
    case yz
    case zx

    var label: String {
        switch self {
        case .xy: return "XY"
        case .yz: return "YZ"
        case .zx: return "ZX"
        }
    }
}
```

**Referenced by:**
- `WorkspaceKit/WorkspaceModuleProviding.swift` line 18: `var spaceWorkPlane: SpaceWorkPlane?`
- `WorkspaceKit/WorkspaceState.swift` line 32: `var activeSpaceWorkPlane: SpaceWorkPlane`
- `CalculatorModules/Space/` — various files

### 6.2 Why It Should Move

`SpaceCameraState` (the camera configuration for 3D view) is already in `MathCore/Coordinate/SpaceMath3D.swift`. It's used by `WorkspaceKit/WorkspaceModuleProviding` (line 17) without creating a reverse dependency because it's in MathCore.

`SpaceWorkPlane` is the SAME kind of type — a pure data enum representing a mathematical concept (the active coordinate plane in 3D space). It has no UI, no module-specific logic. Its current location in `CalculatorModules/Space/Models/` is wrong because:
1. It forces WorkspaceKit to depend on CalculatorModules
2. `SpaceCameraState` is already in MathCore — `SpaceWorkPlane` should be alongside it
3. It's just 3 cases + a label — zero module-specific logic

### 6.3 Recommended Location

**Move to:** `MathCore/Coordinate/SpaceMath3D.swift` (append to existing file)

`SpaceMath3D.swift` already contains:
- `WorldPoint3D`
- `Vector3D`
- `SpaceCameraState`

`SpaceWorkPlane` is their natural companion:

```swift
/// The active coordinate plane for 3D workspace construction.
enum SpaceWorkPlane: String, CaseIterable, Hashable, Codable, Sendable {
    case xy
    case yz
    case zx

    var label: String {
        switch self {
        case .xy: return "XY"
        case .yz: return "YZ"
        case .zx: return "ZX"
        }
    }
}
```

Adding `Codable` and `Sendable` brings it to parity with `SpaceCameraState`.

**Impact:**
- WorkspaceKit imports `EMathicaMathCore` (already does), so type resolution is automatic
- `CalculatorModules/Space/` continues to use it via `EMathicaMathCore` import
- The original file at `CalculatorModules/Space/Models/SpaceWorkPlane.swift` is deleted after migration
- Zero logic changes, pure relocation

---

## 7. WorkspaceView Navigation Decoupling

### 7.1 Current State

`WorkspaceKit/WorkspaceView.swift` depends on `App/AppNavigationState`:

```swift
@Environment(AppNavigationState.self) private var navigation
```

Used for:
1. **Close workspace** (line 76): `navigation.closeWorkspaceSaving(state.document)`
2. **Rename project** (line 178): `try navigation.renameProject(id: id, title: title)`

### 7.2 Why This Is a Problem

- `AppNavigationState` is owned by the `App` module, which is the TOP layer
- WorkspaceKit is a MIDDLE layer — it should not depend on the entry point
- If eMathica splits into separate apps (Plane Calculator, Space Calculator, etc.), each app has its own navigation model. WorkspaceKit shouldn't care WHICH app is hosting it.

### 7.3 Protocol Design

```
Protocol location: WorkspaceKit/Protocols/WorkspaceNavigationDelegate.swift
```

```swift
import Foundation

/// Navigation actions that the workspace can request from the hosting app.
/// The hosting app (or CoreHome) implements this and injects it via the
/// SwiftUI environment.
@MainActor
protocol WorkspaceNavigationDelegate: AnyObject {
    /// Called when the user wants to close the workspace and return home.
    /// The delegate is responsible for saving the document if needed.
    func workspaceDidRequestClose(document: EMathicaDocument)

    /// Called when the user renames the project.
    /// - Returns: The updated project metadata.
    func workspaceDidRenameProject(id: UUID, title: String) throws -> RecentProject
}
```

**Who defines it:** WorkspaceKit.

**Who implements it:** The hosting app module (currently `AppNavigationState`).

**How it is injected:** SwiftUI environment:

```swift
// In App or CoreHome
.environment(WorkspaceNavigationDelegate.self, navigation)

// In WorkspaceView
@Environment(\.workspaceNavigationDelegate) private var navigationDelegate
```

Or more simply, via a custom EnvironmentKey:

```swift
struct WorkspaceNavigationDelegateKey: EnvironmentKey {
    static let defaultValue: (any WorkspaceNavigationDelegate)? = nil
}

extension EnvironmentValues {
    var workspaceNavigationDelegate: (any WorkspaceNavigationDelegate)? {
        get { self[WorkspaceNavigationDelegateKey.self] }
        set { self[WorkspaceNavigationDelegateKey.self] = newValue }
    }
}
```

### 7.4 Migration Path

WorkspaceView changes:
```swift
// Before:
@Environment(AppNavigationState.self) private var navigation
navigation.closeWorkspaceSaving(state.document)

// After:
@Environment(\.workspaceNavigationDelegate) private var navigationDelegate
navigationDelegate?.workspaceDidRequestClose(document: state.document)
```

AppNavigationState conforms to the protocol:
```swift
extension AppNavigationState: WorkspaceNavigationDelegate {
    func workspaceDidRequestClose(document: EMathicaDocument) {
        closeWorkspaceSaving(document)
    }

    func workspaceDidRenameProject(id: UUID, title: String) throws -> RecentProject {
        try renameProject(id: id, title: title)
    }
}
```

---

## 8. Migration Strategy

### Phase 1: Define Protocols in WorkspaceKit (ZERO risk)

**Actions:**
1. Create `WorkspaceKit/Protocols/GeometryDependencyServiceProtocol.swift`
2. Create `WorkspaceKit/Protocols/SemanticIntentAdapterProtocol.swift`
3. Create `WorkspaceKit/Protocols/InputCanonicalizerProtocol.swift`
4. Create `WorkspaceKit/Protocols/DefaultInputCanonicalizer.swift`
5. Create `WorkspaceKit/Protocols/WorkspaceNavigationDelegate.swift`
6. Add protocol conformance fields to `WorkspaceModuleProviding` (with default `nil` returns)

**Impact:** Zero. Protocols are additive — nothing calls them yet. Existing code compiles and runs unchanged.

**Files touched:** 6 new files, 1 modified (`WorkspaceModuleProviding.swift`).

### Phase 2: Implement Protocols in Plane Module (LOW risk)

**Actions:**
1. Create `CalculatorModules/Plane/Services/PlaneGeometryDependencyService.swift` — wraps existing `PlaneGeometryDependencyRecomputeService` static methods as instance methods conforming to the protocol
2. Create `CalculatorModules/Plane/Services/PlaneSemanticIntentAdapter.swift` — wraps existing `PlaneSemanticGraphIntentAdapter` static methods
3. Create `CalculatorModules/Plane/Services/PlaneInputCanonicalizer.swift` — moves `canonicalPlaneCommitInput` logic from WorkspaceState into an adapter
4. Update `PlaneWorkspaceModuleProvider` to return these implementations
5. Move `SpaceWorkPlane` from `CalculatorModules/Space/Models/` to `MathCore/Coordinate/SpaceMath3D.swift`
6. Update all `SpaceWorkPlane` references to use the MathCore definition

**Impact:** Low. New files are additive. Existing static methods remain in place (not deleted yet). The old static `PlaneGeometryDependencyRecomputeService` and `PlaneSemanticGraphIntentAdapter` continue to work.

**Files touched:** 4 new files, 3 modified (`PlaneWorkspaceModuleProvider`, `SpaceMath3D.swift`, all SpaceWorkPlane references).

### Phase 3: Migrate WorkspaceState to Protocols (MEDIUM risk)

**Actions:**
1. Replace 4 `PlaneGeometryDependencyRecomputeService.*` call sites with `moduleProvider.geometryDependencyService?.*`
2. Replace 6 `PlaneSemanticGraphIntentAdapter.*` call sites with `moduleProvider.semanticIntentAdapter?.*`
3. Delete `canonicalPlaneCommitInput()` method and replace 2 call sites with `moduleProvider.inputCanonicalizer?.canonicalize()`
4. Replace `AppNavigationState` @Environment in WorkspaceView with `WorkspaceNavigationDelegate`
5. Add `WorkspaceNavigationDelegate` conformance to `AppNavigationState`

**Impact:** Medium. This is the core migration. The `applySemanticIntentMetadata(to:)` helper reduces duplication. Each call site change is mechanical — the logic doesn't change, only the dispatch mechanism.

**Files touched:** 2 heavily modified (`WorkspaceState.swift`, `WorkspaceView.swift`), 1 modified (`AppNavigationState.swift`).

### Phase 4: Remove Old Static Services (LOW risk)

**Actions:**
1. Delete `PlaneGeometryDependencyRecomputeService.swift` (static enum) — logic now lives in `PlaneGeometryDependencyService`
2. Delete `PlaneSemanticGraphIntentAdapter.swift` (static enum) — logic now lives in `PlaneSemanticIntentAdapter`
3. Delete `CalculatorModules/Space/Models/SpaceWorkPlane.swift` — definition moved to MathCore
4. Verify zero remaining `import Plane*` or `import Space*` in WorkspaceKit

**Impact:** Low. Dead code removal after verifying Phase 3 works.

**Files touched:** 3 deleted.

---

## 9. Risk Assessment

### 🔴 High Risk

| Item | Why | Mitigation |
|------|-----|------------|
| **WorkspaceState migration (Phase 3)** | 25 call sites changed. WorkspaceState is the central state machine — errors here break all calculator modules. | Each call site is a mechanical 1:1 replacement. Protocol method signatures match existing static method signatures exactly. Test after each commit path (create new object, edit object, delete object, drag object). |
| **`dependencyPatches` type signature** | Returns `[(UUID, DocumentObjectPatch)]` — depends on DocumentSystem types. If DocumentKit is extracted later, this protocol needs updating. | Acceptable for now. When DocumentKit is extracted, `DocumentObjectPatch` moves with it. Protocol stays in WorkspaceKit which will depend on DocumentKit. |

### 🟡 Medium Risk

| Item | Why | Mitigation |
|------|-----|------------|
| **PlaneInputCanonicalizer depends on FormulaSemanticState** | The protocol's `canonicalize(source:semanticState:)` takes `FormulaSemanticState` as a parameter. This type is defined in WorkspaceKit. It's fine for Plane to depend on WorkspaceKit types (correct direction), but the protocol signature exposes WorkspaceKit internals. | Acceptable. `FormulaSemanticState` is a WorkspaceKit type that captures the result of formula analysis. It's a data struct, not logic. |
| **Sendable conformance** | Protocols mark as `Sendable` for Swift 6 safety. `PlaneGeometryDependencyService` internally calls `PlaneGeometryResolver` and `PlaneIntersectionSolver` — these must also be Sendable-safe (they are static methods on enums, which is fine). | Verify all implementation types are Sendable before marking protocol as Sendable. If issues arise, remove `Sendable` from protocol and mark as `@MainActor` instead. |
| **SpaceWorkPlane relocation** | Moving a type from one module to another changes its fully-qualified identity. | The type is simple (3-case enum, no stored properties, no extensions). Existing `import EMathicaMathCore` in Space module already resolves `SpaceCameraState` from the same file — adding `SpaceWorkPlane` is a seamless extension. |

### 🟢 Low Risk

| Item | Why | Mitigation |
|------|-----|------------|
| **Protocol definitions (Phase 1)** | Pure additive — new files, no existing code changed. | Standard practice. |
| **Plane adapter implementations (Phase 2)** | Wraps existing static methods without changing logic. | Run existing tests after wrapping. |
| **DefaultInputCanonicalizer** | Identity transform — returns input unchanged. | Trivial implementation, zero risk. |
| **WorkspaceNavigationDelegate** | Simple 2-method protocol. Existing AppNavigationState methods map 1:1. | Standard delegation pattern. |
| **Deleting old static services (Phase 4)** | Dead code after Phase 3 verification. | Verify zero callers via grep before deleting. |
| **Default protocol implementations** | Modules without geometry/graph support return `nil`. WorkspaceState already guards with `?? []` or `guard let`. | Nil-safe by design. |

---

## 10. Recommended Execution Order

### Step 0: Prerequisite (Done)
- [x] EMathicaMathCore Package extraction

### Step 1: SpaceWorkPlane Relocation (1 file move)
Move `SpaceWorkPlane` from `CalculatorModules/Space/Models/SpaceWorkPlane.swift` to `MathCore/Coordinate/SpaceMath3D.swift`. This is the simplest change with the highest architectural payoff — it eliminates one entire category of reverse dependency in a single move.

**Risk:** 🟢 Low. **Est. effort:** 10 minutes.

### Step 2: Define All Protocols (new files only)
Create the 5 protocol files in `WorkspaceKit/Protocols/`. Add conformance fields to `WorkspaceModuleProviding` with default `nil` returns.

**Risk:** 🟢 Low. **Est. effort:** 30 minutes.

### Step 3: Implement Plane Adapters (new files, wrapping existing logic)
Create `PlaneGeometryDependencyService`, `PlaneSemanticIntentAdapter`, `PlaneInputCanonicalizer`. Wire them into `PlaneWorkspaceModuleProvider`.

**Risk:** 🟢 Low. **Est. effort:** 45 minutes.

### Step 4: Migrate WorkspaceState Call Sites
The main event. Replace all 25 direct Plane references with protocol calls. Add the `applySemanticIntentMetadata(to:)` helper. Delete `canonicalPlaneCommitInput`.

**Risk:** 🟡 Medium. **Est. effort:** 2 hours + testing.

### Step 5: Migrate WorkspaceView Navigation
Replace `@Environment(AppNavigationState.self)` with `@Environment(\.workspaceNavigationDelegate)`. Add conformance to `AppNavigationState`.

**Risk:** 🟢 Low. **Est. effort:** 30 minutes.

### Step 6: Verify and Clean Up
- `grep -rn "PlaneGeometryDependencyRecomputeService\|PlaneSemanticGraphIntentAdapter\|canonicalPlaneCommitInput\|SpaceWorkPlane" WorkspaceKit/` → expect ZERO results
- Run app, test: create/edit/delete plane objects, verify geometry dependency recompute works
- Delete old static service files

**Risk:** 🟢 Low. **Est. effort:** 30 minutes.

### Total estimated effort: ~4.5 hours for the complete decoupling.

---

## Appendix A: Call Site Mapping

### WorkspaceState.swift — all 25 references and their replacements

| # | Line | Current | Replacement |
|---|------|---------|-------------|
| 1 | 32 | `var activeSpaceWorkPlane: SpaceWorkPlane` | (unchanged — type now resolves from MathCore) |
| 2 | 78 | `self.activeSpaceWorkPlane = .xy` | (unchanged) |
| 3 | 231 | `activeSpaceWorkPlane = workPlane` | (unchanged) |
| 4 | 370 | `PlaneGeometryDependencyRecomputeService.dependencyPatches(...)` | `moduleProvider.geometryDependencyService?.dependencyPatches(...) ?? []` |
| 5 | 469 | `PlaneGeometryDependencyRecomputeService.dependencyCleanupPatchesForRemovedSources(...)` | `moduleProvider.geometryDependencyService?.dependencyCleanupPatchesForRemovedSources(...) ?? []` |
| 6 | 485 | `PlaneGeometryDependencyRecomputeService.directlyAffectedDerivedObjectIDs(...)` | `moduleProvider.geometryDependencyService?.directlyAffectedDerivedObjectIDs(...) ?? []` |
| 7 | 492 | `PlaneGeometryDependencyRecomputeService.downstreamAffectedDerivedObjectIDs(...)` | `moduleProvider.geometryDependencyService?.downstreamAffectedDerivedObjectIDs(...) ?? []` |
| 8-10 | 1229-1235 | `PlaneSemanticGraphIntentAdapter.semanticGraphKind/parameterSymbol/parameterRange(...)` | `moduleProvider.semanticIntentAdapter?.semanticGraphKind/parameterSymbol/parameterRange(...)` |
| 11 | 1254 | `canonicalPlaneCommitInput(from: text)` | `moduleProvider.inputCanonicalizer?.canonicalize(source: text, semanticState: ...)` |
| 12-14 | 1271-1277 | `PlaneSemanticGraphIntentAdapter.semanticGraphKind/parameterSymbol/parameterRange(...)` | `moduleProvider.semanticIntentAdapter?.semanticGraphKind/parameterSymbol/parameterRange(...)` |
| 15 | 1443 | `canonicalPlaneCommitInput(from: trimmed)` | `moduleProvider.inputCanonicalizer?.canonicalize(source: trimmed, semanticState: ...)` |
| 16-18 | 1460-1466 | `PlaneSemanticGraphIntentAdapter.semanticGraphKind/parameterSymbol/parameterRange(...)` | `moduleProvider.semanticIntentAdapter?.semanticGraphKind/parameterSymbol/parameterRange(...)` |
| 19 | 1666 | `canonicalPlaneCommitInput` method definition | **DELETE** — logic moved to `PlaneInputCanonicalizer` |
| 20 | 1680 | `shouldFallbackToExplicitYForCommit` | **DELETE** — logic moved to `PlaneInputCanonicalizer` |
| 21-22 | 566, 616 | `.setSpaceWorkPlane` case in switch | (unchanged — enum case from MathCore) |
| 23-25 | 1177, 1188, 1190 | `print("[PlanePreview][WorkspaceState]...")` | Rename to `"[Preview][WorkspaceState]..."` (cosmetic — remove "Plane" branding from framework logs) |

### WorkspaceView.swift — 2 navigation references

| # | Line | Current | Replacement |
|---|------|---------|-------------|
| 1 | 4 | `@Environment(AppNavigationState.self) private var navigation` | `@Environment(\.workspaceNavigationDelegate) private var navigationDelegate` |
| 2 | 76 | `navigation.closeWorkspaceSaving(state.document)` | `navigationDelegate?.workspaceDidRequestClose(document: state.document)` |
| 3 | 178 | `try navigation.renameProject(id: id, title: title)` | `try navigationDelegate?.workspaceDidRenameProject(id: id, title: title)` |

### WorkspaceModuleProviding.swift — 1 type reference

| # | Line | Current | Replacement |
|---|------|---------|-------------|
| 1 | 18 | `var spaceWorkPlane: SpaceWorkPlane?` | (unchanged — type now resolves from MathCore) |

---

## Appendix B: New File Inventory

| File | Module | Purpose |
|------|--------|---------|
| `WorkspaceKit/Protocols/GeometryDependencyServiceProtocol.swift` | WorkspaceKit | Protocol for geometry recompute |
| `WorkspaceKit/Protocols/SemanticIntentAdapterProtocol.swift` | WorkspaceKit | Protocol for intent → semantic mapping |
| `WorkspaceKit/Protocols/InputCanonicalizerProtocol.swift` | WorkspaceKit | Protocol for input canonicalization |
| `WorkspaceKit/Protocols/DefaultInputCanonicalizer.swift` | WorkspaceKit | Identity canonicalizer |
| `WorkspaceKit/Protocols/WorkspaceNavigationDelegate.swift` | WorkspaceKit | Protocol for nav actions |
| `CalculatorModules/Plane/Services/PlaneGeometryDependencyService.swift` | Plane | Implements GeometryDependencyServiceProtocol |
| `CalculatorModules/Plane/Services/PlaneSemanticIntentAdapter.swift` | Plane | Implements SemanticIntentAdapterProtocol |
| `CalculatorModules/Plane/Services/PlaneInputCanonicalizer.swift` | Plane | Implements InputCanonicalizerProtocol |

---

## Appendix C: Pre-Package Checklist for WorkspaceKit

After decoupling is complete, verify these conditions before extracting WorkspaceKit as a Package:

- [ ] Zero imports of `CalculatorModules/Plane/*` in any WorkspaceKit file
- [ ] Zero imports of `CalculatorModules/Space/*` in any WorkspaceKit file
- [ ] Zero references to `AppNavigationState` in any WorkspaceKit file
- [ ] `SpaceWorkPlane` type resolves from `EMathicaMathCore`
- [ ] `WorkspaceModuleProviding` has no module-specific types in its interface
- [ ] All 4 protocol types are defined within WorkspaceKit
- [ ] WorkspaceKit depends only on: Foundation, SwiftUI, CoreGraphics, EMathicaMathCore, (optionally) EMathicaInputKit
- [ ] `swift build` passes on WorkspaceKit as a standalone Package
