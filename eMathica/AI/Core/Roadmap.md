# Roadmap

Single source of roadmap truth for eMathica.

## Current priority stack

```
P0 — Plane stabilization and regression safety
P1 — Documentation cleanup + commit slicing + package taxonomy alignment
P2 — MathCore / input / workspace follow-ups after freeze boundaries settle
P3 — Space and later feature growth
```

## Current phase status

| Phase | Status | Description |
|-------|--------|-------------|
| Phase 0 | Complete | Repository audit, capability audit, package audit, knowledge base |
| Phase 1 | Complete | HomeFeature package migration and app integration |
| Phase 2 | Active | Plane stabilization and regression coverage |
| Phase 3 | Designed | Post-freeze package follow-ups |

## Current engineering position

- HomeFeature package migration is complete.
- The next cross-cutting task is document governance and commit slicing.
- `SharedLibraries/` remains the current physical package root; final taxonomy remains a future target.
- Plane / Space / MathInput follow-up work should continue after documentation cleanup is settled.

## Next steps

1. Clean up long-lived documentation so only active truth remains
2. Keep `EMathicaHomeFeature` API and boundaries stable
3. Continue Plane / Space / MathInput follow-up work in small slices
