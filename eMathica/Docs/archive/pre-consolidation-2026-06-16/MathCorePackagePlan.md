# MathCorePackagePlan

## 1. Why split MathCore into Swift Package

GraphCore / CASCore / EvaluationCore / SamplingCore are pure logic layers.  
Keeping their tests on app-host targets couples verification to iOS build/runtime/signing constraints.  
Swift Package gives a stable `swift test` lane for fast logic regression checks.

---

## 2. Current verification bottleneck recap

- App-host tests are sensitive to simulator runtime availability.
- App-host build path includes non-logic steps (assets, app packaging).
- Signing/runtime/toolchain environment can block logic validation even when MathCore code is correct.

---

## 3. Audit: movable vs non-movable code

### 3.1 Movable (pure logic, package candidates)

- `eMathica/MathCore/SemanticCore`
- `eMathica/MathCore/CASCore`
- `eMathica/MathCore/EvaluationCore`
- `eMathica/MathCore/GraphCore`
- `eMathica/MathCore/SamplingCore`

### 3.2 Non-movable in current phase

- `WorkspaceKit/StructuredInput/MathNodeSemanticLowering.swift` (depends on editor AST / WorkspaceKit context)
- `WorkspaceKit/StructuredInput/MathInputCharacterNormalizer.swift` (stays with input pipeline for now)
- `CalculatorModules/Plane/*`, `WorkspaceKit/*`, `DocumentSystem/*`, `MathCore/AlgebraCore/*`

---

## 4. Test audit

### 4.1 Tests suitable for package test target

- `GraphCoreTests.swift`
- `SamplingCoreTests.swift`
- `QuadraticFormExtractorTests.swift`
- `ConditionEvaluatorTests.swift`
- `CASCoreTests.swift`
- `EvaluationCoreTests.swift`

### 4.2 Tests that remain app-host integration tests

- `eMathicaTests.swift` (StructuredInput/MathNode path)
- `PiecewiseSemanticFlowTests.swift`
- `PlaneSampleSetAdapterTests.swift`
- `PlaneSamplingComparisonDebugTests.swift`
- `PlaneSemanticGraphIntentAdapterTests.swift`
- `PlaneSemanticPreviewPolicyTests.swift`

---

## 5. Target package structure

```text
Packages/EMathicaMathCore/
  Package.swift
  Sources/EMathicaMathCore/
    SemanticCore/
    CASCore/
    EvaluationCore/
    GraphCore/
    SamplingCore/
  Tests/EMathicaMathCoreTests/
    GraphCoreTests.swift
    SamplingCoreTests.swift
    QuadraticFormExtractorTests.swift
    ConditionEvaluatorTests.swift
    CASCoreTests.swift
    EvaluationCoreTests.swift
```

- library target: `EMathicaMathCore`
- test target: `EMathicaMathCoreTests`
- no app/UI module dependencies

---

## 6. Dependency boundary notes

1. Package must stay independent of SwiftUI/UIKit/AppKit/WorkspaceKit/Plane/DocumentSystem.
2. `MathNodeSemanticLowering` stays in WorkspaceKit and imports package semantic types.
3. SamplingCore stays independent from Plane render types (`PlotSegment`, `WorldPoint`).
4. Adapter layers remain app-side.

---

## 7. Migration phases

- **Phase 0**: Audit only.
- **Phase 1**: Create package + copy pure logic code/tests.
- **Phase 2A**: Add sync guard scripts for dual-source period.
- **Phase 2B**: App integration audit/plan.
- **Phase 2D**: Atomic app switch to package compile source.
- **Phase 2E**: Stabilization + anti-regression checks.
- **Future**: remove duplicate local pure-logic copy after stabilization.

---

## 8. Risks and rollback strategy

### 8.1 Main risks

- Duplicate type definitions if package + old local sources compile together.
- Access control mismatch (`public`/`internal`) across module boundary.
- Target membership drift in `.xcodeproj`.
- Drift between duplicate source trees during transition.

### 8.2 Rollback

1. Remove package linkage from app/test targets.
2. Restore local MathCore compilation in app target.
3. Revert package-specific imports.
4. Keep package lane independent for verification.

---

## 9. CI recommendations

1. Mandatory fast lane: `swift test` in `Packages/EMathicaMathCore`.
2. Integration lane: `xcodebuild build` + `build-for-testing` for app scheme.
3. Keep sync/exclusion guards active while duplicate source trees still exist.

---

## 10. Decision summary

- Package split is feasible and already functioning.
- Pure MathCore logic is package-ready.
- App-host integration tests remain in app target.
- Atomic switch is safer than partial dual-compile transition.

---

## 11. Phase 1 completed

- `Packages/EMathicaMathCore` created.
- Pure logic MathCore directories copied to package `Sources`.
- Pure logic tests copied to package `Tests`.
- `swift test` passed.

---

## 12. Phase 2A sync guard completed

- Added `Scripts/check_mathcore_package_sync.sh`.
- Added optional `Scripts/sync_mathcore_to_package.sh`.
- Established duplicate-source period workflow with explicit sync check.

---

## 13. Phase 2B app integration audit

- Confirmed app-side files requiring explicit `import EMathicaMathCore`.
- Confirmed one-shot atomic switch is preferred over partial dual compile.
- Identified duplicate-definition risk if old local MathCore remains compiled.

---

## 14. Phase 2D atomic app switch completed

- App/test targets linked to package product `EMathicaMathCore`.
- Old local pure-logic MathCore compile participation excluded via `EXCLUDED_SOURCE_FILE_NAMES`:
  - `SemanticCore`
  - `CASCore`
  - `EvaluationCore`
  - `GraphCore`
  - `SamplingCore`
- App compile source for MathCore logic is now the package.
- Old local source files are intentionally retained for transition/rollback.
- Rollback path remains documented and feasible.

---

## 15. Phase 2E stabilization completed

Current verification order is:

1. `Scripts/check_mathcore_package_sync.sh`
2. `Scripts/check_mathcore_app_target_exclusion.sh`
3. `cd Packages/EMathicaMathCore && swift test`
4. `xcodebuild ... build`
5. `xcodebuild ... build-for-testing`

`check_mathcore_app_target_exclusion.sh` verifies:
- package linkage exists in `project.pbxproj`
- exclusion guard for old local pure-logic MathCore directories remains present

---

## 16. Remaining risks

- Duplicate source tree maintenance cost remains until cleanup phase.
- Exclusion rules in project file can drift and must stay guarded by scripts.
- Package/app API boundary may still expose edge `public` visibility gaps in future features.

---

## 17. Next cleanup options

1. **Short-term**: keep old local copy + keep sync/exclusion checks mandatory.
2. **Mid-term**: remove/archive old `eMathica/MathCore` pure-logic duplicate after stable window.
3. **Long-term**: CI permanently enforces package `swift test` + app `build/build-for-testing`.
