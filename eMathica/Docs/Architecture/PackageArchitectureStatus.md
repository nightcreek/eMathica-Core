# Package Architecture Status

> **Date:** 2026-06-16
> **Type:** Merged status report (consolidates 3 source documents)
> **Source Documents:**
> - [PackageAdoptionAudit.md](../../archive/consolidated-2026-06-16/PackageAdoptionAudit.md)
> - [SwiftPackageSplitAudit.md](../../archive/consolidated-2026-06-16/SwiftPackageSplitAudit.md)
> - [WorkspaceKitPackageReadinessAudit.md](../../archive/consolidated-2026-06-16/WorkspaceKitPackageReadinessAudit.md)

---

## Current Status

eMathica 使用 **5个 Swift Package** + **1个 App Target**:

| Package | Files | Status | Xcode Dependency |
|---------|-------|--------|-----------------|
| EMathicaMathCore | 73 | ✅ Active | ✅ In `packageProductDependencies` |
| EMathicaDocumentKit | 12 | ✅ Active | ❌ Not adopted |
| EMathicaThemeKit | 10 | ✅ Active | ❌ Not adopted |
| EMathicaWorkspaceKit | 68 | ✅ Active | ❌ Not adopted |
| EMathicaMathInputKit | 8 | ✅ Active | ❌ Not adopted |

### Dependency Graph

```
EMathicaWorkspaceKit
├── EMathicaMathCore          (../../eMathica/eMathica/Packages/EMathicaMathCore)
├── EMathicaDocumentKit       (../EMathicaDocumentKit)
├── EMathicaThemeKit          (../EMathicaThemeKit)
└── EMathicaMathInputKit      (../EMathicaMathInputKit)

EMathicaDocumentKit
└── EMathicaMathCore

EMathicaMathInputKit           (zero deps)
EMathicaThemeKit               (zero deps)
EMathicaMathCore               (zero deps)
```

---

## Key Findings

### 1. Dual Compilation Problem (MathCore)

`EMathicaMathCore` is in a dangerous state:
- Referenced via `XCLocalSwiftPackageReference` → compiled as separate module
- In-tree `MathCore/` directory auto-discovered by `fileSystemSynchronizedGroups` → compiled as part of app module
- Types exist in two places at compile time. Works because Swift only links one implementation, but **fragile** — any refactoring could break

### 2. 3 of 4 Packages NOT Adopted

DocumentKit, ThemeKit, WorkspaceKit are NOT in Xcode's `packageProductDependencies`. Their in-tree copies compile via `fileSystemSynchronizedGroups` auto-discovery.

### 3. WorkspaceKit Not Ready for Independence

WorkspaceKit still has 6 unresolved type dependencies on App Target:
| Type | Defined In | Blocker |
|------|-----------|---------|
| `CalculatorModuleType` | CalculatorModules/ | 🔴 YES |
| `EMathicaDocument` | DocumentSystem/ | 🔴 YES |
| `DocumentCommand` | DocumentSystem/ | 🔴 YES |
| `DocumentObjectPatch` | DocumentSystem/ | 🔴 YES |
| `RecentProject` | DocumentSystem/ | 🔴 YES |
| `CalculatorModuleRegistry` | CalculatorModules/ | 🟡 Partial |

Zero remaining path references to `App/`, `CoreHome/`, `CalculatorModules/Plane/`, `Space/` — all migrated to protocols.

---

## Known Issues

| Issue | Severity | Status |
|-------|----------|--------|
| MathCore dual compilation | 🔴 P0 | Risk present but build passes |
| DocumentKit/ThemeKit/WorkspaceKit not in Xcode deps | 🟡 P2 | Package exists but unused by Xcode |
| WorkspaceKit depends on App Target types | 🔴 P1 | Blocks full package independence |
| In-tree copies may diverge from packages | 🟡 P2 | Manual sync risk |

---

## Deferred Cleanup

| Item | Target |
|------|--------|
| Remove in-tree MathCore copy, use Package-only | Post-v1.0 |
| Add DocumentKit/ThemeKit/WorkspaceKit to Xcode deps | Post-v1.0 |
| Resolve 6 WorkspaceKit type dependencies | Post-v1.0 |
| Full split: Plane Calculator app target + Space Calculator app target | Post-v1.0 |

---

## Next Actions

1. Plane v1.0 stabilization — do not touch Package config
2. Post-v1.0: Remove in-tree MathCore duplication
3. Post-v1.0: Complete WorkspaceKit decoupling (resolve 6 type deps)
4. Post-v1.0: Full Package adoption in Xcode project
