# Formula Keyboard Package Integration Plan

## Status

Phase 0.75 validates the engineering feasibility of introducing:

`SharedLibraries/EMathicaFormulaKeyboardKit`

without starting the real framework migration yet.

## Current SharedLibraries Baseline

Observed package baseline:

- `EMathicaMathInputKit`: `swift-tools-version: 5.10`
- `EMathicaFormulaDisplayKit`: `swift-tools-version: 6.0`
- `EMathicaWorkspaceKit`: `swift-tools-version: 6.0`
- `EMathicaThemeKit`: `swift-tools-version: 6.0`

Observed consumer baseline:

- eMathica Xcode project references SharedLibraries packages using `XCLocalSwiftPackageReference`
- App targets currently consume `EMathicaWorkspaceKit` directly
- `EMathicaWorkspaceKit` already depends on `EMathicaMathInputKit` and `EMathicaFormulaDisplayKit`

## Integration Decision

Recommended new package:

`SharedLibraries/EMathicaFormulaKeyboardKit`

Recommended tools version:

- `// swift-tools-version: 6.0`

Recommended platforms:

- `.iOS(.v17)`
- `.macOS(.v14)`

Reason:

- aligns with current WorkspaceKit and FormulaDisplayKit consumers
- allows package access control inside the new package
- avoids introducing a lower deployment target than its first consumers

## Recommended Products

Recommended explicit products:

- `EMathicaFormulaKeyboardCore`
- `EMathicaFormulaKeyboardBuiltin`
- `EMathicaFormulaKeyboardRendering`
- `EMathicaFormulaKeyboardSwiftUI`

Do not introduce an umbrella product in Phase 1.

Reason:

- explicit product consumption keeps dependency direction visible
- avoids accidental over-linking
- supports cleaner test-target scoping

## Recommended Package.swift Draft

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EMathicaFormulaKeyboardKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "EMathicaFormulaKeyboardCore", targets: ["EMathicaFormulaKeyboardCore"]),
        .library(name: "EMathicaFormulaKeyboardBuiltin", targets: ["EMathicaFormulaKeyboardBuiltin"]),
        .library(name: "EMathicaFormulaKeyboardRendering", targets: ["EMathicaFormulaKeyboardRendering"]),
        .library(name: "EMathicaFormulaKeyboardSwiftUI", targets: ["EMathicaFormulaKeyboardSwiftUI"])
    ],
    dependencies: [
        .package(path: "../EMathicaFormulaDisplayKit"),
        .package(path: "../EMathicaThemeKit")
    ],
    targets: [
        .target(
            name: "EMathicaFormulaKeyboardCore",
            dependencies: []
        ),
        .target(
            name: "EMathicaFormulaKeyboardBuiltin",
            dependencies: ["EMathicaFormulaKeyboardCore"]
        ),
        .target(
            name: "EMathicaFormulaKeyboardRendering",
            dependencies: [
                "EMathicaFormulaKeyboardCore",
                .product(name: "EMathicaFormulaDisplayCore", package: "EMathicaFormulaDisplayKit")
            ]
        ),
        .target(
            name: "EMathicaFormulaKeyboardSwiftUI",
            dependencies: [
                "EMathicaFormulaKeyboardCore",
                "EMathicaFormulaKeyboardRendering",
                .product(name: "EMathicaFormulaDisplaySwiftUI", package: "EMathicaFormulaDisplayKit"),
                "EMathicaThemeKit"
            ]
        ),
        .testTarget(
            name: "EMathicaFormulaKeyboardCoreTests",
            dependencies: ["EMathicaFormulaKeyboardCore"]
        ),
        .testTarget(
            name: "EMathicaFormulaKeyboardBuiltinTests",
            dependencies: ["EMathicaFormulaKeyboardBuiltin"]
        ),
        .testTarget(
            name: "EMathicaFormulaKeyboardRenderingTests",
            dependencies: [
                "EMathicaFormulaKeyboardRendering",
                .product(name: "EMathicaFormulaDisplayCore", package: "EMathicaFormulaDisplayKit")
            ]
        ),
        .testTarget(
            name: "EMathicaFormulaKeyboardSwiftUITests",
            dependencies: ["EMathicaFormulaKeyboardSwiftUI"]
        )
    ]
)
```

## Dependency Graph

```text
EMathicaFormulaKeyboardCore

EMathicaFormulaKeyboardBuiltin
    -> EMathicaFormulaKeyboardCore

EMathicaFormulaKeyboardRendering
    -> EMathicaFormulaKeyboardCore
    -> EMathicaFormulaDisplayCore

EMathicaFormulaKeyboardSwiftUI
    -> EMathicaFormulaKeyboardCore
    -> EMathicaFormulaKeyboardRendering
    -> EMathicaFormulaDisplaySwiftUI
    -> EMathicaThemeKit

EMathicaWorkspaceKit
    -> EMathicaFormulaKeyboardCore
    -> EMathicaFormulaKeyboardBuiltin
    -> EMathicaFormulaKeyboardSwiftUI
    -> EMathicaMathInputCore

eMathica App
    -> EMathicaWorkspaceKit
```

## Why No Package Skeleton Is Created In Phase 0.75

Decision:

- do not create the package skeleton in this phase

Reason:

- `SharedLibraries` currently contains uncommitted production fixes that should become Commit A
- the RFC/document batch should become Commit B
- adding a new package skeleton now would create a third infrastructure diff in the same dirty worktree
- that would blur commit boundaries before the pre-existing fixes are isolated

Therefore Phase 0.75 only freezes the integration plan.

## WorkspaceKit Integration Plan

Phase 1 integration order:

1. create new package and empty targets
2. add local package dependency in `EMathicaWorkspaceKit/Package.swift`
3. start consuming only the minimal Core/Builtin/SwiftUI targets as needed
4. keep current production keyboard untouched until real migration slices begin

Recommended initial `WorkspaceKit` dependency additions:

- `.package(path: "../EMathicaFormulaKeyboardKit")`
- target dependencies on:
  - `.product(name: "EMathicaFormulaKeyboardCore", package: "EMathicaFormulaKeyboardKit")`
  - `.product(name: "EMathicaFormulaKeyboardBuiltin", package: "EMathicaFormulaKeyboardKit")`
  - `.product(name: "EMathicaFormulaKeyboardSwiftUI", package: "EMathicaFormulaKeyboardKit")`

Do not add `WorkspaceKit` as a dependency of the new package.

## Xcode Project Integration Plan

Observed current pattern:

- the app project directly carries local package references for SharedLibraries packages

Recommended strategy:

- Phase 1 skeleton may initially rely on WorkspaceKit's transitive package dependency
- add a direct `XCLocalSwiftPackageReference` in `eMathica.xcodeproj` only when:
  - app or app tests directly consume keyboard package products, or
  - Xcode package resolution proves unstable without an explicit reference

This keeps project churn lower in the first infrastructure commit.

## CI / Test Integration Plan

When the package skeleton is added:

- run `swift test` in `SharedLibraries/EMathicaFormulaKeyboardKit`
- keep existing package tests for:
  - `EMathicaFormulaDisplayKit`
  - `EMathicaMathInputKit`
  - `EMathicaWorkspaceKit`
- keep app-level Debug and Release build validation

Do not add framework-migration behavior tests in the skeleton commit.

Skeleton commit should only prove:

- package resolution
- target compilation
- test discovery

## Risk Assessment

### Low risk

- creating a new local package under `SharedLibraries`
- adding explicit products/targets
- adding isolated marker tests

### Medium risk

- adding the package to `WorkspaceKit` dependency graph while `SharedLibraries` still has unrelated dirty changes
- deciding whether Xcode project needs a direct local package reference immediately

### High risk

- creating the package skeleton before Commit A and Commit B are split
- migrating any existing keyboard file into the new package during the skeleton step

## Rollback Strategy

If skeleton creation in Phase 1 causes integration issues:

- remove the `EMathicaFormulaKeyboardKit` local package reference
- remove the dependency from `WorkspaceKit/Package.swift`
- keep RFC documents unchanged

Because Phase 0.75 does not modify production keyboard code, rollback remains straightforward.

## Recommendation For Phase 1 First Commit

Recommended:

- create package skeleton in a dedicated Commit C

Only after:

- Commit A scope is isolated
- Commit B scope is isolated

Commit C should contain:

- package directory
- `Package.swift`
- empty marker targets
- minimal marker tests

Commit C must not contain:

- real keyboard definitions
- host wiring
- renderer implementation
- builtin migration

## Final Freeze

Phase 0.75 freezes:

- the exact new package location
- the target split
- the dependency graph
- the integration order
- the decision not to create the skeleton in the current dirty worktree
