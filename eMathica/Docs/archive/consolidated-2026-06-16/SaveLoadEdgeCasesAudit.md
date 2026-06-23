# SaveLoad Edge Cases Audit

## 1. 本轮是否修改源码

否。

本轮只新增审计文档：`Docs/SaveLoadEdgeCasesAudit.md`。

## 2. 审计范围

本轮按保存/重开一致性只读检查了以下模块与文件：

- `eMathica/DocumentSystem/IO/LocalProjectStore.swift`
- `eMathica/DocumentSystem/IO/ProjectStore.swift`
- `eMathica/DocumentSystem/IO/ProjectStoreError.swift`
- `eMathica/DocumentSystem/EMathicaDocument.swift`
- `eMathica/DocumentSystem/DocumentCommand.swift`
- `eMathica/DocumentSystem/DocumentObjectPatch.swift`
- `eMathica/DocumentSystem/ProjectMetadata.swift`
- `eMathica/DocumentSystem/ProjectPackageStructure.swift`
- `eMathica/DocumentSystem/Package/EMathicaPackageLayout.swift`
- `eMathica/DocumentSystem/Package/EMathicaPackageCodec.swift`
- `Packages/EMathicaMathCore/Sources/EMathicaMathCore/MathExpression.swift`
- `Packages/EMathicaMathCore/Sources/EMathicaMathCore/MathObject.swift`
- `eMathica/CoreHome/CoreHomeState.swift`
- `eMathica/CoreHome/ProjectThumbnailView.swift`
- `eMathica/CoreHome/Preview/ProjectPreviewRenderer.swift`
- `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceState.swift`
- `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/ObjectPanel/WorkspaceObjectRowView.swift`
- `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/Inspector/ObjectInspectorPanel.swift`
- `eMathica/CalculatorModules/Plane/Commands/PlaneCommandHandler.swift`
- `eMathica/CalculatorModules/Plane/Services/PlaneGeometryDependencyRecomputeService.swift`

本轮还检查了这些测试与回归证据：

- `eMathicaTests/PlaneSaveLoadTests.swift`
- `eMathicaTests/ProjectPreviewRendererTests.swift`
- `eMathicaTests/ProjectThumbnailLoadingTests.swift`
- `eMathicaTests/PlaneFunctionPreviewConsistencyTests.swift`
- `eMathicaTests/PlaneToolingTests.swift`
- `eMathicaTests/ObjectPanelFullscreenTests.swift`
- `eMathicaTests/PlaneGeometryDependencyTests.swift`

## 3. 当前保存/加载链路概览

```text
WorkspaceState / CoreHomeState
  -> DocumentCommand / DocumentObjectPatch
  -> EMathicaDocument (objects / metadata / canvasState / deletedObjectHistory)
  -> LocalProjectStore.saveProject(...)
      -> metadata.json
      -> document.json
      -> ProjectPreviewRenderer.renderPNGData(...)
      -> preview.png
  -> CoreHomeState.reloadProjects()
      -> LocalProjectStore.listProjects()
      -> metadata.json -> RecentProject
      -> previewURL(for:) -> preview.png
      -> ProjectThumbnailView async decode/cache
  -> LocalProjectStore.loadProject(...)
      -> document.json
      -> WorkspaceState reopen
```

当前 `.emathica` 包实际落盘位置：

- `Application Support/eMathica/Projects/<UUID>.emathica/`

当前实际写入文件：

- `metadata.json`
- `document.json`
- `preview.png`

## 4. 场景基线总表

| 编号 | 场景 | encode | decode | identity/dependency | preview/thumbnail | 状态 | 问题摘要 | 风险 |
|---|---|---|---|---|---|---|---|---|
| 1 | 空项目 | 基本可写入 | 基本可读取 | 无对象依赖 | 预期使用默认 preview / 首页 fallback | PARTIAL | 空项目链路简单，但没有 `LocalProjectStore` 级端到端测试；项目列表仍依赖 `metadata.json` | P2 |
| 2 | 单函数项目 | `MathExpression` 字段可编码 | 文档级可解码 | 名称与 expression 结构可保留 | preview 会更新，首页能读 preview | PARTIAL | `rawInput / originalLatex / editorASTData / semanticGraphKind` 结构上会保存，但没有完整文件级回归覆盖这些字段 | P1 |
| 3 | 复杂函数项目 | 结构上可编码 | 结构上可解码 | 语义字段可保留 | preview / commit / thumbnail 可能不一致 | PARTIAL | 复杂函数不太可能“丢字段”，但图形分类、采样与缩略图仍存在路径差异 | P1 |
| 4 | 几何基础对象 | 基本对象字段可编码 | 基本文档 round-trip 可解码 | `id / name / geometryDefinition` 基本稳定 | preview 能渲染点/线/圆/弧 | PARTIAL | 点/线/段/圆字段稳定，但缺少 `LocalProjectStore` 级真实包回归；圆弧文件级覆盖不足 | P1 |
| 5 | 几何依赖对象 | 依赖字段可编码 | reopen 后可恢复依赖关系 | 依赖 ID 与状态可保留 | preview 能忽略无解对象并渲染定义态对象 | PARTIAL | 依赖编码和 reopen 恢复已有证据，但文件级 save/load + 删除后再 reopen 的完整链路仍未闭合成一组 fixture | P1 |
| 6 | 删除与保存 | 删除后文档可写入 | 重开后删除对象不应再出现 | 删除/断链语义在状态机中明确 | preview 会基于当前对象集重绘 | PARTIAL | 删除后的文档状态本身稳定，但 `saveProject` 对 preview 写回是 best-effort，且无专门“删除后保存后重开”端到端测试 | P1 |
| 7 | 编辑与保存 | 更新后的 expression / geometry 可写入 | reopen 后应保持最后状态 | 更新对象 ID 不变 | preview 会在保存时重算 | PARTIAL | `WorkspaceState` 会写回 `sourceExpression / computeExpression / editorASTData / originalLatex`，但没有完整文件级编辑后重开回归 | P1 |
| 8 | 大项目（20+ 对象） | 可写入 | 可读取 | 结构上可保留 | preview 与首页读取都可能变慢 | UNKNOWN | 没有大项目 save/load/perf 专项测试；当前 I/O 和 preview 生成明显是同步路径 | P2 |
| 9 | `preview.png` 边缘场景 | 缺失时不阻塞项目保存 | 损坏时首页可 fallback | 不影响对象 identity | Home 异步 loader 有 fallback | PARTIAL | 缺失/损坏 fallback 已有，但“过旧 preview”与“preview 生成失败后静默保留旧图”仍未治理 | P2 |
| 10 | 包结构与版本化 | 当前 writer 可写最小三件套 | reader 只认固定路径 | metadata/document 双份 identity 存在漂移风险 | preview 名称与路径是硬编码 | FAIL | `version` 未启用，`unsupportedVersion` 未使用，`packageStructure` 只是数据字段，未真正驱动 writer/reader | P1 |

## 5. 函数对象保存/重开分析

### 当前可持久化字段

`MathExpression` 当前直接 `Codable` 持久化以下与函数对象相关的关键字段：

- `displayText`
- `rawInput`
- `originalLatex`
- `normalizedExpression`
- `simplifiedExpression`
- `simplifiedDisplayText`
- `algebraAnalysis`
- `semanticGraphKind`
- `semanticParameterSymbol`
- `semanticParameterRange`
- `editorASTData`
- `sourceExpression`
- `computeExpression`

这意味着：

- 当前函数对象不是“只保存一个原始字符串再靠重开时重算”。
- 如果这些字段在 commit 时已经写进对象，save/load 结构上是可以完整保留的。

### 当前 commit 写回路径

编辑中的函数对象在提交或选中对象同步 metadata 时，会额外写回：

- `sourceExpression`
- `computeExpression`
- `editorASTData`
- `originalLatex`
- semantic intent metadata

这条路径来自 `WorkspaceState.attachStructuredInputMetadataToSelectedObject(...)`。

### 当前对象区 / Inspector 读取优先级

对象区与 Inspector 的主显示字段优先级当前是：

1. `displayText`
2. `originalLatex`
3. `rawInput`
4. `name`

但重新编辑函数时，`WorkspaceState.editableExpression(for:)` 采用的是另一套优先级：

1. `rawInput`
2. `sourceExpression`
3. `originalLatex`
4. `displayText`

### 当前结论

| 项 | 结论 |
|---|---|
| `rawInput` | 结构上会保存，但是否始终与重新编辑语义一致，当前缺少文件级回归 |
| `originalLatex` | 结构上会保存，ObjectPanel/Inspector 可直接使用 |
| `displayText` | 结构上会保存，当前对象区展示首先依赖它 |
| `editorASTData` | 结构上会保存，但没有专项 save/load 文件测试 |
| `GraphIntent / semantic metadata` | 结构上会保存，不完全依赖 reopen 后重算 |
| preview / commit / thumbnail 一致性 | 仍有风险，尤其复杂函数上三条链采样策略不同 |

### 主要风险

1. `displayText` 与 `rawInput/sourceExpression/originalLatex` 的职责并不完全相同。
2. 对象区显示优先级与 reopen 后再次编辑的优先级不同，字段漂移时会出现“看起来是一个表达式，点编辑又是另一个源文本”的风险。
3. 当前没有覆盖“显函数/隐函数/参数/极坐标/分段函数 metadata 全字段 round-trip”的真实文件级测试。

## 6. 几何对象保存/重开分析

### 基础几何对象

当前 `MathObject` 直接保存：

- `id`
- `name`
- `type`
- `position`
- `points`
- `geometryDefinition`
- `style`
- `isVisible`

对点、线、线段、射线、圆、圆弧这类对象来说，结构上已具备完整保存基础。

### 依赖对象

当前依赖几何对象通过 `geometryDependency` 保存源对象 ID 与依赖类型：

- `midpointOfPoints`
- `parallelLine`
- `perpendicularLine`
- `intersectionOf`
- `circleByCenterPoint`
- `circleByCenterRadius`
- `arcByThreePoints`

`geometryDefinitionStatus` 也会一起保存，例如：

- `.defined`
- `.noSolution`
- `.missingSource`
- `.unsupported`
- `.invalid`

### 删除源对象后的当前语义

当前运行时不是强制“删源对象就一定递归删除所有依赖对象”。

实际上有两套明确语义：

1. `unlink`
   - 删除选中的源对象
   - 幸存派生对象会被清掉 `geometryDependency` / `geometryDefinitionStatus`
   - 转为静态对象保留当前几何结果

2. `deleteAffected`
   - 删除源对象
   - 再递归删除 downstream 依赖对象
   - 删除记录进入 `deletedObjectHistory`

这意味着 save/reopen 后的行为取决于用户删除时走了哪条策略。

### 当前证据

- `PlaneSaveLoadTests` 已覆盖文档级 round-trip：
  - dependency
  - status
  - slider / canvas state
  - deleted history
- `PlaneGeometryDependencyTests` 已证明：
  - 依赖字段可编码解码
  - reopen 后 `noSolution` 交点可随源对象移动恢复为 `.defined`
  - 删除源对象时可转静态
  - `deleteAffected` 可递归删除 downstream

### 当前结论

| 项 | 结论 |
|---|---|
| `id / name` | 文档级 round-trip 稳定 |
| `geometryDefinition` | 基础对象结构上稳定 |
| `geometryDependency` | 结构上稳定，且 reopen 后仍可继续参与 recompute |
| 删除源对象后的保存语义 | 已有明确设计，但需更多文件级 fixture 覆盖 |
| 圆弧 / 更复杂几何 | 结构支持已在模型中存在，但 save/load 集成覆盖仍薄 |

## 7. `preview.png` 与 Home thumbnail 分析

### preview 生成时机

当前 `LocalProjectStore` 在以下时机尝试更新 preview：

- `createProject`
- `saveProject`

调用顺序是：

1. 写 `metadata.json`
2. 写 `document.json`
3. `ProjectPreviewRenderer.renderPNGData(...)`
4. 尝试写 `preview.png`

### 当前优点

- 首页不会重算函数。
- 首页只读取磁盘 `preview.png`。
- `ProjectThumbnailView` 现在是异步读取 + 内存缓存，不会在 SwiftUI `body` 中同步解码磁盘图片。
- `preview.png` 缺失时：
  - `previewURL(for:)` 返回 `nil`
  - 首页使用 fallback shape
- `preview.png` 损坏时：
  - `ProjectThumbnailImageLoader` 解码失败返回 `nil`
  - 首页继续使用 fallback shape

### 当前风险

1. preview 生成失败是静默的  
   `updatePreviewIfPossible` 中写入失败不会抛错，也不会清理旧 preview。

2. preview 过旧没有检测  
   当前没有比较 `document.json` 与 `preview.png` 的时间戳、版本号、hash 或 generation marker。

3. `previewImageName` 未参与实际读取  
   元数据里有 `previewImageName`，但实际读取路径硬编码为 `layout.previewURL`。

4. 打开项目会触发保存  
   `CoreHomeState.openProject(...)` 会更新 `updatedAt` 并调用 `saveProject(document)`，这会连带再次渲染 preview。

### 当前结论

| 场景 | 结果 |
|---|---|
| preview 缺失 | fallback 安全 |
| preview 损坏 | fallback 安全 |
| preview 过旧 | 当前无主动检测 |
| preview 与 document 不一致 | 当前无主动检测 |
| preview 生成失败 | 项目仍可保存，但缩略图可能停留在旧状态或缺失 |

## 8. 包结构与版本化风险

### 当前已存在的版本化元素

- `ProjectMetadata.version`，默认值 `"0.1"`
- `ProjectStoreError.unsupportedVersion`

### 当前实际问题

1. `version` 目前只是字段，没有真实校验逻辑。
2. `unsupportedVersion` 目前未见实际使用路径。
3. `EMathicaDocument.packageStructure` 声明了：
   - `project.json`
   - `assets/`
   - `preview.png`
   - `notebook.json`
   - `graphs/`
   - `plugins/`
4. 但当前真正的 writer / reader 只使用：
   - `metadata.json`
   - `document.json`
   - `preview.png`

### 这意味着

- 当前“声明的包结构”与“实际落盘结构”并不一致。
- 如果未来 Plane / Space 扩对象或补 assets/graphs/plugins，当前 writer/reader 没有清晰迁移入口。
- metadata 在两个地方重复存在：
  - `metadata.json`
  - `document.json` 内的 `document.metadata`
- 但当前没有一致性校验。

### 当前版本化结论

| 项 | 结论 |
|---|---|
| schema version 字段 | 有 |
| schema version 校验 | 无 |
| migration 策略 | 未见 |
| packageStructure 驱动真实读写 | 无 |
| metadata/document 一致性校验 | 无 |
| 旧文件兼容策略 | 未见 |

## 9. 性能风险

### 当前同步路径

以下操作当前都是同步执行：

- `listProjects()` 中逐个读 `metadata.json`
- `loadProject()` 中 `Data(contentsOf: documentURL)`
- `saveProject()` 中：
  - `encode(metadata)`
  - `write(metadata.json)`
  - `encode(document)`
  - `write(document.json)`
  - `renderPNGData`
  - `write(preview.png)`

### 当前主线程风险

`CoreHomeState` 是 `@MainActor`，其以下路径直接调用 store：

- `reloadProjects()`
- `createProject(...)`
- `openProject(...)`
- `saveProject(...)`
- `renameProject(...)`
- `deleteSelectedProjects()`

这意味着：

- 大项目保存时，可能把 document 编码、preview 渲染、PNG 写盘都压在主线程触发链上。
- 打开项目时仅更新时间戳，也会引发一次保存和 preview 重渲染。
- 最近项目较多时，首页刷新会同步读多个 `metadata.json`。

### 当前相对安全的部分

- 首页缩略图解码已改成异步 + 内存 cache。
- 缺失 / 损坏 preview 不会直接卡住 UI 逻辑。

## 10. P0/P1/P2/P3 问题清单

本轮未确认新的 P0。

| 优先级 | 问题 | 影响场景 | 涉及模块 | 建议后续任务 |
|---|---|---|---|---|
| P1 | `metadata.json` 与 `document.json` 双份 metadata 没有一致性校验，Home 列表与 reopen 可能看到不同状态 | 项目标题、模块、更新时间、列表显示 | `LocalProjectStore`, `ProjectMetadata`, `EMathicaDocument` | Function/Project Metadata SaveLoad Consistency Audit/Fix |
| P1 | `version` 字段存在但未启用，`unsupportedVersion` 未接线，当前没有真实 schema gate | 版本升级、旧文件兼容 | `ProjectMetadata`, `ProjectStoreError`, `LocalProjectStore` | Package Schema Version Design |
| P1 | 函数对象显示链与重新编辑链依赖的字段优先级不同，字段漂移时可能 reopen 后“看见的表达式”和“再编辑的源表达式”不一致 | 单函数项目、复杂函数项目、编辑后保存 | `MathExpression`, `WorkspaceState`, `WorkspaceObjectRowView`, `ObjectInspectorPanel` | Function Metadata SaveLoad Consistency Audit/Fix |
| P1 | 删除后保存的 preview 更新没有专门端到端回归，且 preview 写回失败静默 | 删除函数/点/依赖对象后保存 | `LocalProjectStore`, `ProjectPreviewRenderer` | Save After Delete Regression Audit/Fix |
| P1 | 依赖对象 save/load 主线有模型级与 reopen 级测试，但缺少真实 package fixture 覆盖 | 中点、交点、平行线、垂线、动态圆 | `MathObject`, `PlaneGeometryDependencyRecomputeService`, `LocalProjectStore` | Geometry Dependency SaveLoad Audit/Fix |
| P2 | `preview.png` 过旧 / 与 `document.json` 不一致时当前没有检测 | 首页缩略图、打开旧项目 | `LocalProjectStore`, `ProjectThumbnailView`, `ProjectPreviewRenderer` | Preview PNG Missing/Corrupt/Stale Fallback Fix |
| P2 | `previewImageName` 和 `packageStructure` 是数据字段，但不控制真实读写路径 | 未来扩展包结构、旧版本兼容 | `ProjectMetadata`, `ProjectPackageStructure`, `EMathicaPackageLayout` | Package Schema Version Design |
| P2 | 大项目保存、打开项目更新时间、首页项目列表刷新都走同步 I/O | 20+ 对象项目、最近项目较多 | `CoreHomeState`, `LocalProjectStore` | Large Project SaveLoad Performance Audit |
| P3 | `listProjects()` 对坏 metadata 包采用静默跳过，项目可能“从首页消失”但磁盘仍在 | metadata 损坏、部分写入失败 | `LocalProjectStore` | Project Package Corruption Handling Audit |
| P3 | `ProjectFileManagerPlaceholder` 仍在，说明更完整的包管理入口尚未正式收口 | 长尾文件管理能力 | `ProjectFileManagerPlaceholder` | Project Package IO Surface Cleanup Audit |

## 11. 下一轮建议

建议只选 3 到 5 个最小后续任务，不做大重构：

1. `Preview PNG Missing/Corrupt/Stale Fallback Fix`
   - 先只修 preview 缺失、损坏、过旧检测与 fallback，不碰 graph 算法。

2. `Function Metadata SaveLoad Consistency Audit/Fix`
   - 先对齐对象区显示字段、重新编辑字段与保存字段，不碰输入逻辑本身。

3. `Geometry Dependency SaveLoad Audit/Fix`
   - 先为中点 / 交点 / 平行线 / 垂线 / 动态圆补真实 package fixture，不先改依赖图架构。

4. `Package Schema Version Design`
   - 先做只读设计文档，明确 `metadata.json/document.json/preview.png` 与未来 `project.json/assets/graphs` 的边界，不直接改 writer/reader。

5. `Large Project SaveLoad Performance Audit`
   - 先量化主线程 I/O 与 preview 生成成本，再决定是否需要异步保存策略。
