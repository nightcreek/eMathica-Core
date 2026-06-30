# Architecture

Single source of architectural truth for eMathica.

## Current topology

```
App target (shell / composition)
├── AppRootView
├── AppNavigationState
├── LocalProjectStore
├── ProjectPreviewRenderer
└── App-private mocks / services

SharedLibraries/ (current physical package root)
├── EMathicaMathCore
├── EMathicaDocumentKit
├── EMathicaThemeKit
├── EMathicaMathInputKit
├── EMathicaWorkspaceKit
└── EMathicaHomeFeature
```

## Current boundary

- `AppRootView` is the composition point.
- `AppNavigationState` only handles shell navigation.
- `LocalProjectStore` remains the concrete `ProjectStore` implementation in the app layer.
- `ProjectPreviewRenderer` remains app-private preview service and is injected downward.
- `EMathicaHomeFeature` owns the Home UI, state, layout, hero/background shell, and action bridge.
- `SharedLibraries/` is the current physical package root; future taxonomy paths are target-only.

## Layering rule

eMathica now follows an app-as-shell / package-first boundary:

- shared and reusable logic should live in Swift packages
- emathica-only feature logic can live in `EMathicaHomeFeature`
- app-private concrete services stay in the app target
- `Packages/shared/`, `Packages/emathica-only/`, `Packages/openmathink-only/` are future targets only

## Current risk notes

- Keep package public API tight
- Keep preview rendering out of HomeFeature for now
- Keep `LocalProjectStore` and `ProjectPreviewRenderer` in the app shell
