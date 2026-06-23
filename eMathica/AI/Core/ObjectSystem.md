# Object System

Single source of object system truth for eMathica.

Merged from: DocumentObjectKindProposal.md, ObjectConversionProposal.md

Note: ObjectSystemFreeze.md (planned output of Task 15) was not found on disk. This document reconstructs the object system from the Proposal documents and Calculator matrices.

---

## ObjectKind Tree

38 ObjectKind across 12 domains. Kind identifiers use dot-notation: `domain.subtype`.

### Complete Kind Hierarchy

| Domain | Kind | Status | Current MathObjectType |
|--------|------|:------:|------------------------|
| **point** | `point.2d` | existing | `.point` |
| | `point.3d` | existing | `.point3D` |
| **line** | `line.segment2d` | existing | `.line` / `.segment` |
| | `line.segment3d` | planned | — |
| | `line.ray2d` | existing | `.ray` |
| | `line.infinite2d` | existing | `.infiniteLine` |
| **curve** | `curve.explicit2d` | existing | `.explicit2D` |
| | `curve.parametric2d` | existing | `.parametric2D` |
| | `curve.implicit2d` | existing | `.implicit2D` |
| | `curve.polar2d` | planned | — |
| | `curve.parametric3d` | planned | — |
| **surface** | `surface.explicit3d` | existing | `.explicit3D` |
| | `surface.parametric3d` | existing | `.parametric3D` |
| | `surface.implicit3d` | existing | `.implicit3D` |
| **formula** | `formula.algebraic` | existing | `.formula` |
| | `formula.differential` | planned | — |
| | `formula.integral` | planned | — |
| | `formula.recursive` | planned | — |
| **relation** | `relation.equation2d` | existing | `.equation2D` |
| | `relation.inequality2d` | planned | — |
| | `relation.equation3d` | planned | — |
| | `relation.system` | planned | — |
| **table** | `table.data` | existing | `.table` |
| | `table.function` | planned | — |
| **set** | `set.pointSet2d` | existing | `.pointSet2D` |
| | `set.interval` | planned | — |
| | `set.region2d` | planned | — |
| **wave** | `wave.audio` | planned | — |
| | `wave.visual` | planned | — |
| **text** | `text.plain` | existing | `.text` |
| | `text.rich` | planned | — |
| **image** | `image.bitmap` | existing | `.image` |
| | `image.vector` | planned | — |
| **slider** | `slider.continuous` | existing | `.slider` |
| | `slider.discrete` | planned | — |
| **construction** | `construction.intersection` | existing | `.intersection` |
| | `construction.locus` | planned | — |
| **plugin** | `plugin.custom` | planned | — |

### Current MathObjectType → ObjectKind Migration

The legacy `MathObjectType` enum (9 cases) must be replaced by `ObjectKind` strings:

**Direct Mapping (MathObjectType → ObjectKind)**

```
.function       → curve.explicit2d   (primary; also formula.algebraic, surface.explicit3d via GeometryDefinition.kind)
.point          → point.2d            (primary; also point.3d via GeometryDefinition.kind)
.circle         → curve.explicit2d   (domain: circle)
.segment        → line.segment2d      (primary; also line.segment3d via GeometryDefinition.kind)
.line           → line.infinite2d     (primary; also line.infinite3d via GeometryDefinition.kind)
.ray            → line.ray2d
.parameter      → slider.continuous
.parameterGroup → slider.discrete
.arc            → curve.explicit2d   (domain: arc)
```

**3D Variants (resolved via GeometryDefinition.kind, not MathObjectType)**

These types are expressed by combining `MathObjectType` with `GeometryDefinition.kind`:

```
MathObjectType.point    + GeometryKind.point3D    → point.3d
MathObjectType.segment  + GeometryKind.segment3D  → line.segment3d
MathObjectType.line     + GeometryKind.line3D     → line.infinite3d
MathObjectType.function + GeometryKind.plane3D    → surface.explicit3d  (type leaking)
```

**Note:** The current `MathObjectType` has only 9 cases. 3D objects are expressed via the `type + geometryDefinition.kind` combination, not via additional enum cases. See Architecture.md Stage A2 for the Space Type Leaking analysis.

---

## Unified Object Header

Every object in the system carries a unified header. Fields are categorized by requirement level.

### MUST Fields (always present)

| Field | Type | Description |
|-------|------|-------------|
| `uuid` | UUID | Immutable unique identifier |
| `kind` | ObjectKind | Dot-notation kind identifier (`point.2d`, `curve.explicit2d`, etc.) |
| `createdAt` | Date | Object creation timestamp |
| `updatedAt` | Date | Last modification timestamp |
| `version` | Int | Monotonic version counter |

### SHOULD Fields (present for most objects)

| Field | Type | Description |
|-------|------|-------------|
| `displayName` | String? | User-visible name; auto-generated if nil |
| `createdBy` | CalculatorID | Which Calculator created this object |
| `parentDocumentID` | UUID | Owning document |

### MAY Fields (present for specific objects)

| Field | Type | Description |
|-------|------|-------------|
| `preferredViews` | [CalculatorID] | Calculators that can render this object (ordered by preference) |
| `enabledCalculators` | [CalculatorID] | Calculators currently active for this object |
| `primaryCalculator` | CalculatorID | Default Calculator for interaction |
| `dependencyGraph` | DependencyGraph? | Cached dependency snapshot |
| `transHistory` | [ConversionID] | References to trans.json entries |

---

## Object Lifecycle

Eight states, forming two cycles:

```
                    ┌──────────┐
                    │  Created  │
                    └────┬─────┘
                         │
              ┌──────────┼──────────┐
              ▼          ▼          ▼
        ┌─────────┐ ┌──────┐ ┌──────────┐
        │ Edited  │ │Viewed│ │ Converted │
        └────┬────┘ └──┬───┘ └────┬─────┘
             │         │          │
             └────┬────┘          │
                  ▼               ▼
            ┌──────────┐   ┌──────────┐
            │  Active   │◄──│ Exported │
            └────┬─────┘   └──────────┘
                 │
        ┌────────┼────────┐
        ▼        ▼        ▼
  ┌──────────┐ ┌────────┐ ┌──────────┐
  │ Archived │ │Deleted │ │ Restored │
  └──────────┘ └────────┘ └────┬─────┘
                               │
                               ▼
                         ┌──────────┐
                         │ Imported │
                         └──────────┘
```

| State | Description | Entry Condition |
|-------|-------------|-----------------|
| **Created** | Object instantiated, not yet displayed | New UUID assigned |
| **Active** | Object displayed and interactive in at least one Calculator | First render |
| **Edited** | User is actively modifying the object | Input focus or gesture start |
| **Viewed** | Object is visible but not being edited | Render without interaction |
| **Converted** | A new object has been materialized from this one | Conversion operation |
| **Exported** | Object data has been written to external format | Export operation |
| **Archived** | Object removed from active document but preserved | User archive action |
| **Deleted** | Object marked for removal | User delete action |
| **Restored** | Object recovered from archive/trash | User restore action |
| **Imported** | Object created from external data | Import operation |

---

## DependencyGraph

The DependencyGraph tracks relationships between objects *in space* — which objects depend on which other objects within a document.

### Formal Structure

```
DependencyGraph {
    nodes: [ObjectUUID]
    edges: [DirectedEdge]
}

DirectedEdge {
    from: ObjectUUID    // dependent
    to: ObjectUUID      // dependency
    kind: EdgeKind      // type of dependency
}

EdgeKind ∈ {
    .definition     // object B is defined in terms of A (e.g., f(x) = sin(x))
    .construction   // object B is geometrically constructed from A (e.g., intersection)
    .reference      // object B references A's value (e.g., slider → formula)
    .parent         // object A contains B (e.g., table → data point)
}
```

### Key Properties

1. **DAG (Directed Acyclic Graph)** — No circular dependencies allowed
2. **Cascade on change** — Changing object A invalidates all objects that depend on A
3. **Recomputed lazily** — DependencyGraph is rebuilt on document open or explicit recalculation
4. **Separate from trans.json** — DependencyGraph tracks spatial relationships (what depends on what now); trans.json tracks temporal relationships (what was converted from what)

---

## Conversion Engine

### Materialize Conversion

When a user converts an object from one Kind to another, a **new object** is created with a new UUID. The original object is preserved. This is a **materialize conversion**, not a view adaptation.

```
Conversion = origin (UUID, Kind) → target (UUID, Kind) via Capability
```

### trans.json

All conversions are recorded in `{document}.emathica/trans.json`:

```json
{
  "version": 1,
  "conversions": [
    {
      "conversionID": "uuid-string",
      "objectUUID": "origin-object-uuid",
      "fromKind": "point.2d",
      "toKind": "point.3d",
      "capability": "object.convert.point2d.toPoint3d",
      "timestamp": "2026-06-17T10:30:00Z",
      "triggeredBy": "calculator.space",
      "metadata": {
        "z": 0,
        "description": "Imported 2D point into Space calculator"
      }
    }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `conversionID` | UUID | Unique identifier for this conversion event |
| `objectUUID` | UUID | Origin object |
| `fromKind` | ObjectKind | Origin kind |
| `toKind` | ObjectKind | Target kind |
| `capability` | CapabilityID | Capability used for conversion |
| `timestamp` | ISO8601 | When the conversion happened |
| `triggeredBy` | CalculatorID | Which Calculator initiated the conversion |
| `metadata` | JSON | Conversion-specific parameters (e.g., z=0 for 2D→3D) |

### Conversion Safety Levels

| Level | Color | Meaning | Example |
|:-----:|:-----:|---------|---------|
| **Safe** | Green | Lossless, fully reversible | `point.2d → point.3d` (z=0 preserved) |
| **Warning** | Yellow | Lossy but semantically preserved | `curve.explicit2d → table.data` (sampled) |
| **Caution** | Orange | Significant information loss | `surface.explicit3d → curve.implicit2d` (projection) |
| **Danger** | Red | Destructive, not recommended | `formula.differential → formula.algebraic` (loses derivative info) |

### Planned Conversion Paths

| From | To | Safety | Status |
|------|----|:------:|:------:|
| `point.2d` | `point.3d` | Safe | planned |
| `point.3d` | `point.2d` | Warning | planned |
| `curve.explicit2d` | `wave.audio` | Warning | planned |
| `curve.explicit2d` | `table.data` | Warning | planned |
| `curve.parametric2d` | `table.data` | Warning | planned |
| `table.data` | `curve.explicit2d` | Warning | planned |
| `surface.explicit3d` | `curve.implicit2d` | Caution | planned |
| `table.data` | `set.pointSet2d` | Warning | planned |
| `set.pointSet2d` | `table.data` | Safe | planned |

### DependencyGraph ≠ trans.json

| Aspect | DependencyGraph | trans.json |
|--------|:---------------:|:----------:|
| **Axis** | Space (current state) | Time (history) |
| **Content** | Who depends on whom now | What was created from what |
| **Rebuilt** | On document open / recalculation | Append-only |
| **Purpose** | Invalidation cascades | Audit trail, undo conversion |
| **Storage** | In-memory / cache | On-disk (`.emathica/trans.json`) |

These two systems must remain separate. Conflating them would couple history with current state, making both fragile.
