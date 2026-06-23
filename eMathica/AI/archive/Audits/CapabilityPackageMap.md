# Capability Package Map

> **日期:** 2026-06-16
> **原则:** Package 按能力拆分，不按 UI 层级拆分

---

## Status Legend

| Label | Meaning |
|-------|---------|
| **already packaged** | 已在独立 Swift Package 中 |
| **ready to package** | 代码已成熟，可直接拆分 |
| **migration candidate** | 代码存在但需要重组/去重 |
| **empty shell recommended** | 规划需要但代码未实现 |
| **inventory only** | 仅做能力登记，暂不拆分 |

---

## EMathicaMathCore (already packaged, future split)

**Current Package:** `Packages/EMathicaMathCore/` (73 files)

```
EMathicaMathCore
├── expr.ast.define                    already packaged
├── expr.symbol.define                 already packaged
├── expr.relation.define               already packaged
├── expr.piecewise.define              already packaged
├── expr.matrix.define                 already packaged
├── expr.serialize.json                already packaged
│
├── cas.normalize                      migration candidate → EMathicaCASCore
├── cas.simplify                       migration candidate → EMathicaCASCore
├── cas.canonicalize                   migration candidate → EMathicaCASCore
├── cas.expand.polynomial              migration candidate → EMathicaCASCore
├── cas.differentiate                  migration candidate → EMathicaCASCore
├── cas.solve.equation                 migration candidate → EMathicaCASCore
├── cas.extract.quadratic              migration candidate → EMathicaCASCore
├── cas.extract.conic                  migration candidate → EMathicaCASCore
│
├── graph.classify.explicitY           migration candidate → EMathicaGraphIntentCore
├── graph.classify.explicitX           migration candidate → EMathicaGraphIntentCore
├── graph.classify.implicit2D          migration candidate → EMathicaGraphIntentCore
├── graph.classify.parametric2D        migration candidate → EMathicaGraphIntentCore
├── graph.classify.polar2D             migration candidate → EMathicaGraphIntentCore
├── graph.classify.conic               migration candidate → EMathicaGraphIntentCore
├── graph.classify.piecewise           migration candidate → EMathicaGraphIntentCore
│
├── graph.sample.explicit2D            migration candidate → EMathicaSamplingCore
├── graph.sample.implicit2D            migration candidate → EMathicaSamplingCore
├── graph.sample.parametric2D          migration candidate → EMathicaSamplingCore
├── graph.sample.polar2D               migration candidate → EMathicaSamplingCore
├── graph.sample.conic                 migration candidate → EMathicaSamplingCore
├── graph.sample.stitch                migration candidate → EMathicaSamplingCore
├── graph.sample.detectDiscontinuity   migration candidate → EMathicaSamplingCore
├── graph.sample.qualityProfile        migration candidate → EMathicaSamplingCore
│
├── geometry.point.2d                  migration candidate → EMathicaGeometryCore
├── geometry.line.2d                   migration candidate → EMathicaGeometryCore
├── geometry.ray.2d                    migration candidate → EMathicaGeometryCore
├── geometry.segment.2d                migration candidate → EMathicaGeometryCore
├── geometry.circle.2d                 migration candidate → EMathicaGeometryCore
├── geometry.arc.2d                    migration candidate → EMathicaGeometryCore
├── geometry.point.3d                  migration candidate → EMathicaGeometryCore
├── geometry.intersection              migration candidate → EMathicaGeometryCore
├── geometry.distance                  migration candidate → EMathicaGeometryCore
│
├── object.identity.uuid               inventory only → EMathicaObjectKit
├── object.kind.define                 inventory only → EMathicaObjectKit
├── object.serialize.json              inventory only → EMathicaObjectKit
│
├── style.math.define                  inventory only → EMathicaThemeKit
├── style.color.token                  inventory only → EMathicaThemeKit
├── style.line.width                   inventory only → EMathicaThemeKit
├── style.dash.pattern                 inventory only → EMathicaThemeKit
│
├── dependency.edge.create             inventory only → EMathicaDependencyKit
├── dependency.graph.detectCycle       empty shell recommended → EMathicaDependencyKit
│
└── geometry.convert.2dTo3d            empty shell recommended → EMathicaGeometryCore
    geometry.convert.3dTo2d            empty shell recommended → EMathicaGeometryCore
    geometry.projection                empty shell recommended → EMathicaGeometryCore
    geometry.transform                 empty shell recommended → EMathicaGeometryCore
    cas.factor                         empty shell recommended → EMathicaCASCore
    cas.integrate                      empty shell recommended → EMathicaCASCore
    cas.limit                          empty shell recommended → EMathicaCASCore
    graph.classify.parametric3D        empty shell recommended → EMathicaGraphIntentCore
    graph.classify.implicit3D          empty shell recommended → EMathicaGraphIntentCore
    graph.sample.parametric3D          empty shell recommended → EMathicaSamplingCore
```

**Recommendation:** EMathicaMathCore should eventually split into 4 sub-packages:
1. **EMathicaCASCore** (CAS + Algebra)
2. **EMathicaGraphIntentCore** (Graph classification)
3. **EMathicaSamplingCore** (All sampling)
4. **EMathicaGeometryCore** (2D/3D geometry + conversion)

Object/Style/Dependency types that are currently in MathCore should move to their respective kits when those kits are created. Currently they're too small to justify a separate package.

---

## EMathicaDocumentKit (already packaged + migration candidate)

```
EMathicaDocumentKit
├── document.metadata                  already packaged
├── document.calculator.primary        already packaged
├── document.object.add                already packaged
├── document.object.delete             already packaged
├── document.object.update             already packaged
├── document.save                      already packaged
├── document.load                      already packaged
├── document.package.codec             already packaged
├── command.document.apply             already packaged
├── document.calculator.enabled        empty shell recommended
├── document.trans.record              empty shell recommended
└── document.version.migrate           empty shell recommended
```

**Recommendation:** Remove duplicate files in `DocumentSystem/` (6 files). Package is already well-formed.

---

## EMathicaWorkspaceKit (already packaged)

```
EMathicaWorkspaceKit
├── workspace.shell                    already packaged
├── workspace.module.register          already packaged
├── workspace.canvas.integrate         already packaged
├── workspace.tool.groups              already packaged
├── workspace.command.route            already packaged
├── command.workspace.dispatch         already packaged
├── command.module.handle              already packaged
├── command.undo.execute               already packaged
├── command.redo.execute               already packaged
├── command.history.track              already packaged
├── tool.group.define                  already packaged
├── tool.module.register               already packaged
├── tool.action.execute                already packaged
├── selection.single                   inventory only → EMathicaSelectionKit
├── selection.multi                    inventory only → EMathicaSelectionKit
├── inspector.section.render           inventory only → EMathicaInspectorKit
├── inspector.property.edit            inventory only → EMathicaInspectorKit
├── inspector.style.edit               inventory only → EMathicaInspectorKit
├── inspector.objectSpecific           inventory only → EMathicaInspectorKit
├── inspector.moduleSpecific           inventory only → EMathicaInspectorKit
├── workspace.inspector.shell          inventory only → EMathicaInspectorKit
├── workspace.objectPanel.shell        already packaged
├── input.session.edit                 migration candidate → EMathicaMathInputKit
├── input.ast.build                    migration candidate → EMathicaMathInputKit
├── input.cursor.navigate              migration candidate → EMathicaMathInputKit
├── input.keyboard.layout              migration candidate → EMathicaMathInputKit
├── input.keyboard.keys                migration candidate → EMathicaMathInputKit
├── input.keyboard.action              migration candidate → EMathicaMathInputKit
├── input.latex.serialize              migration candidate → EMathicaMathInputKit
├── input.expr.bridge                  migration candidate → EMathicaMathInputKit
├── input.diagnostic.show              migration candidate → EMathicaMathInputKit
├── expr.parse.latex                   migration candidate → EMathicaMathInputKit
├── expr.parse.source                  migration candidate → EMathicaMathInputKit
├── expr.semantic.lower                migration candidate → EMathicaMathInputKit
└── expr.diagnostic.analyze            migration candidate → EMathicaMathInputKit
```

**Recommendation:** WorkspaceKit is well-structured. The Input/Keyboard/StructuredInput modules (10+ files) are potential candidates for EMathicaMathInputKit extraction. Inspector subsystem could eventually move to EMathicaInspectorKit.

---

## EMathicaThemeKit (already packaged)

```
EMathicaThemeKit
├── style.glass                        already packaged
├── style.app.theme                    already packaged
├── style.color.token                  already packaged
└── style.math.define                  inventory only (currently in MathCore)
```

---

## EMathicaFormulaRenderKit (ready to package)

```
EMathicaFormulaRenderKit
├── formula.render.latex               ready to package (FeatureUtilities/Preview/)
├── formula.render.label               ready to package (SharedUI/)
├── formula.render.inline              ready to package (WorkspaceKit/Keyboard/)
├── formula.render.thumbnail           ready to package (SharedUI/)
├── formula.render.fallback            ready to package (FeatureUtilities/Preview/)
├── expr.format.latex                  ready to package (WorkspaceKit/Keyboard/)
├── formula.measure.baseline           ready to package (partial)
└── formula.render.cache               empty shell recommended
```

**Recommendation:** Extract from 3 locations (FeatureUtilities/Preview, SharedUI, WorkspaceKit/Keyboard) into a single package.

---

## EMathicaParentKit (ready to package)

```
EMathicaParentKit
├── parent.draft.generate              ready to package (CalculatorModules/Plane/Services/)
├── parent.project.render              ready to package (CoreHome/Preview/)
├── parent.thumbnail.generate          ready to package (CoreHome/Preview/)
├── document.preview.generate          ready to package (CoreHome/Preview/)
└── preview.cache                      empty shell recommended
```

---

## Future Packages (inventory only / empty shell)

### EMathicaObjectKit (inventory only)

```
EMathicaObjectKit
├── object.identity.uuid               inventory only (in MathCore)
├── object.kind.define                 inventory only (in MathCore)
├── object.name.assign                 inventory only (in MathCore)
├── object.style.apply                 inventory only (in MathCore via MathStyle)
├── object.metadata.store              inventory only (in MathCore)
├── object.serialize.json              inventory only (in MathCore Codable)
├── object.thumbnail.contribute        inventory only (in Preview)
├── object.naming.sequential           inventory only (in WorkspaceKit)
├── object.convert.kind                empty shell recommended
├── object.convert.point2d.toPoint3d   empty shell recommended
├── object.convert.curve.toWave        empty shell recommended
└── object.convert.curve.toTable       empty shell recommended
```

### EMathicaDependencyKit (inventory only + empty shell)

```
EMathicaDependencyKit
├── dependency.edge.create             inventory only (in MathCore)
├── dependency.resolve                 inventory only (in Plane/Space)
├── dependency.recompute               inventory only (in Plane renderer)
├── dependency.delete.sourcePolicy     inventory only (in Plane)
├── dependency.persistence             inventory only (in MathCore)
├── dependency.graph.detectCycle       empty shell recommended
└── dependency.orphan.recover          empty shell recommended
```

### EMathicaSelectionKit (inventory only)

```
EMathicaSelectionKit
├── selection.hitTest.object           inventory only (in Plane/Space)
├── selection.hitTest.handle           inventory only (partial)
├── selection.single                   inventory only (in WorkspaceKit)
├── selection.multi                    inventory only (in WorkspaceKit)
├── selection.objectPanel              inventory only (in WorkspaceKit)
└── selection.inspector                inventory only (in WorkspaceKit/Inspector)
```

### EMathicaInspectorKit (inventory only)

```
EMathicaInspectorKit
├── inspector.section.render           inventory only (in WorkspaceKit)
├── inspector.property.edit            inventory only (in WorkspaceKit)
├── inspector.style.edit               inventory only (in WorkspaceKit)
├── inspector.objectSpecific           inventory only (in WorkspaceKit)
├── inspector.moduleSpecific           inventory only (in WorkspaceKit)
└── workspace.inspector.shell          inventory only (in WorkspaceKit)
```

### EMathicaExportKit (empty shell recommended)

```
EMathicaExportKit
├── export.image.png                   empty shell recommended
├── export.vector.svg                  empty shell recommended
├── export.document.pdf                empty shell recommended
├── export.animation.gif               empty shell recommended
├── export.animation.video             empty shell recommended
├── export.notebook                    empty shell recommended
└── export.package                     empty shell recommended
```

### EMathicaAnimationKit (inventory only + empty shell)

```
EMathicaAnimationKit
├── animation.parameter.play           inventory only (in WorkspaceKit/ObjectPanel)
├── animation.timeline                 empty shell recommended
├── animation.keyframe                 empty shell recommended
├── animation.object                   empty shell recommended
└── animation.construction.playback    empty shell recommended
```

### EMathicaAssetKit (empty shell recommended)

```
EMathicaAssetKit
├── asset.image.store                  inventory only (ProjectPackageStructure)
├── asset.audio.store                  empty shell recommended
├── asset.plugin.store                 empty shell recommended
├── asset.reference                    empty shell recommended
├── asset.cache                        empty shell recommended
└── asset.package.storage              empty shell recommended
```

### EMathicaPluginKit (inventory only + empty shell)

```
EMathicaPluginKit
├── plugin.manifest.define             inventory only (in PluginSystem/)
├── plugin.protocol.define             inventory only (in PluginSystem/)
├── plugin.capability.expose           empty shell recommended
├── plugin.block.compose               empty shell recommended
├── plugin.block.parameter             empty shell recommended
├── plugin.safety.policy               empty shell recommended
└── plugin.permission.model            empty shell recommended
```

---

## Summary

| Package | Status | Action Priority |
|---------|--------|----------------|
| EMathicaMathCore | already packaged, future split | Split Phase 1 |
| EMathicaCASCore | migration candidate | Split Phase 1 |
| EMathicaGraphIntentCore | migration candidate | Split Phase 1 |
| EMathicaSamplingCore | migration candidate | Split Phase 1 |
| EMathicaGeometryCore | migration candidate | Split Phase 1 |
| EMathicaDocumentKit | already packaged + needs dedup | Phase 1 cleanup |
| EMathicaWorkspaceKit | already packaged | Stable |
| EMathicaThemeKit | already packaged | Stable |
| EMathicaFormulaRenderKit | ready to package | Phase 2 |
| EMathicaMathInputKit | ready to package | Phase 2 |
| EMathicaPreviewKit | ready to package | Phase 2 |
| EMathicaObjectKit | inventory only | Phase 3 |
| EMathicaDependencyKit | inventory only + empty shell | Phase 3 |
| EMathicaSelectionKit | inventory only | Phase 3 |
| EMathicaInspectorKit | inventory only | Phase 3 |
| EMathicaPluginKit | inventory only + empty shell | Phase 3 |
| EMathicaExportKit | empty shell recommended | Long-term |
| EMathicaAnimationKit | inventory only + empty shell | Long-term |
| EMathicaAssetKit | empty shell recommended | Long-term |
