# WorkspaceKit Boundary Follow-up Audit

## 1. 本轮是否修改源码：否

本轮仅做只读复审并新增审计文档，没有修改任何业务源码、资源文件或工程行为。

## 2. 残留模块专属逻辑清单

| 位置 | 残留逻辑 | 属于 Plane/Space/通用 | 风险 | 建议处理 |
|---|---|---|---|---|
| `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceState.swift:224-234` | 直接处理 `.setSpaceCameraState` / `.setSpaceWorkPlane`，并把 `SpaceCameraState` / `SpaceWorkPlane` 写回工作区状态 | Space | WorkspaceKit 仍显式认识 Space 专属模型，边界未收干净 | 保持现状短期可用，后续再评估是否下沉到 moduleProvider 或 Space 专用状态桥接层 |
| `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceState.swift:331-345` | 在通用状态里按 `.point`、`.circle`、线类对象直接做几何 patch / 重算判断 | Plane | WorkspaceState 仍承担 Plane 几何规则与对象类型知识 | 可逐步迁移到 Plane 的命令/几何服务，但当前不建议一次性搬走 |
| `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceState.swift:1273-1280` | 编辑函数对象时，直接做显式函数名解析与重命名补位 | Plane | Plane 命名规则仍在 WorkspaceState 中落地，和模块边界不完全一致 | 继续收敛到统一命名服务的调用点，避免再写一套局部规则 |
| `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceState.swift:1295-1301` | `isFormulaEditableObject` 直接枚举 `.function/.point/.circle/.parameter` 等 Plane 对象类型 | Plane | 工作区通用层仍在决定哪些 Plane 对象可编辑 | 可保留为短期兼容逻辑，后续应考虑下放到模块层对象能力表 |
| `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceState.swift:1432-1474` | 提交函数输入时直接创建 `.function` 对象，并调用命名服务、表达式构建与样式初始化 | Plane | create/edit 提交路径仍由 WorkspaceState 主导，Plane 语义侵入较深 | 短期可接受，后续可把函数对象构造细节收敛到 Plane 命令处理层 |
| `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceState.swift:1664-1676` | `canonicalPlaneCommitInput(from:)` 根据 graph intent 改写提交文本 | Plane | 这是明显的 Plane 专属提交规范逻辑，属于边界残留/旧逻辑 | 建议后续迁移到 Plane 的输入构建服务；当前不要直接删，以免影响 MVP |
| `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceState.swift:1688-1698` | `currentLoweringContext()` 直接扫描 `.parameter` 对象，构造 lowering symbol table | Plane | 工作区层在了解 Plane 参数对象语义 | 可迁移到模块提供者，但要确认不会影响通用输入上下文 |
| `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift:236-246` | 构造 `WorkspaceCanvasContext` 时直接传入 `spaceCameraState` 与 `spaceWorkPlane` | Space | 通用 view 层仍暴露 Space 专属渲染上下文 | 可考虑改为模块提供者自行读取状态，但这类迁移需要谨慎，避免影响 Space 预览链路 |
| `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift:258-263` | `plane.function` 工具 ID 触发 `openInput(mode: .expression)` | Plane | 通用工具层对 Plane 工具有硬编码分支 | 可保留，属于现有 MVP 入口；若后续模块增多，再统一成模块命令映射 |
| `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceView.swift:278-279` | `moduleSpecific` 直接下发 `"TODO"` payload | 通用但带明显模块占位 | 占位 payload 会让模块扩展入口语义不完整，且不利于排查 | 建议尽快把 payload 结构化，或按模块提供者能力拆分；当前不要为了清理而大改入口协议 |
| `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/WorkspaceModuleProviding.swift:17-27` | `WorkspaceCanvasContext` 直接携带 `SpaceCameraState` / `SpaceWorkPlane` / `draftMathObject` / `dispatch` | 通用外壳但内含模块专属字段 | 这不是纯壳层，仍是“通用容器 + 模块专属插槽” | 短期可接受；若继续扩展模块，建议把模块专属字段拆到更明确的模块上下文中 |
| `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/Protocols/WorkspaceObjectNamingServiceProtocol.swift:39-69` | 显式函数命名补位与 `nextFunctionName` 等规则统一在 WorkspaceKit 内 | Plane | 命名服务本身是共享入口，但规则明显服务于 Plane 对象命名 | 这是合理的共享抽象，可继续保留；调用方应尽量只通过服务使用 |
| `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/Commands/WorkspaceCommand.swift:53-62` | `setSpaceCameraState`、`setSpaceWorkPlane`、`moduleSpecific(id:payload:)` 仍是通用命令枚举的一部分 | Space/通用 | 命令层已经被模块专属命令污染，边界语义不够纯 | 当前不建议拆命令枚举，先保持稳定，后续按模块逐步收口 |
| `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/History/DeletedObjectHistoryPresenter.swift:30-72` | 历史面板直接按 `.function/.point/.circle/.arc/.parameter` 做类型标签与摘要 | Plane | 历史 UI 已经知道 Plane 对象类型，但不一定是错误；只是边界偏厚 | 可先保留，因为它是 UI 展示层；后续若模块增多，可考虑抽象类型标签提供器 |
| `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/Inspector/SpaceGeometryInspectorPropertyPresenter.swift:4-42` | 直接读取 `.point3D/.segment3D/.line3D/.plane3D` 并生成空间属性文案 | Space | 非常明确的 Space 专属逻辑留在 WorkspaceKit 中 | 若 Space 继续推进，建议将该 presenter 下沉到 Space 模块或独立视图层 |
| `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/Shared/SpaceGeometryPropertyFormatter.swift:1-25` | 空间几何数值格式化工具放在 WorkspaceKit 共享目录 | Space | 这属于 Space 共享格式化工具，名称上看起来是通用但语义并不通用 | 若 Space 继续推进，可迁移到 Space 模块公共层；当前不必急删 |
| `/Users/night_creek/开发/eMathica/Packages/EMathicaWorkspaceKit/Sources/EMathicaWorkspaceKit/Shared/PlaneGeometryStubs.swift:4-14` | `PlaneGeometryResolver` 仅是空 stub，真实实现不在 WorkspaceKit | Plane | stub 的存在说明 WorkspaceKit 仍保留 Plane 的接口影子，但实现已下沉 | 这是合理过渡形态，可保留；后续可考虑把 stub 变成更清晰的协议注入说明 |

## 3. 可立即迁移的小项

- `WorkspaceState.swift` 中的 `canonicalPlaneCommitInput(from:)` 是最清晰的 Plane 专属旧逻辑，适合后续单独迁移到 Plane 输入构建层。
- `WorkspaceState.swift` 中对 `.parameter` 对象构造 lowering symbol table 的逻辑，适合后续转给 moduleProvider 或 Plane 输入上下文服务。
- `WorkspaceView.swift` 中的 `moduleSpecific(id: payload: "TODO")` 可优先改成结构化 payload 或明确的模块转发接口。
- `WorkspaceState.swift` 中的显式函数名解析已经依赖命名服务，后续可继续减少本地对象类型判断，尽量只保留“调用服务”而不是“自己拼规则”。
- `DeletedObjectHistoryPresenter` 里对类型标签的映射如果未来有更多模块对象，可以考虑抽成对象元信息提供器，但这不是当前 P0/P1 必做项。

## 4. 不建议当前迁移的高风险项

- `WorkspaceState` 的 Undo/Redo、选择态、输入态、草稿预览态，不建议现在拆出，否则很容易影响 MVP 的输入闭环。
- `WorkspaceState` 中与 `setSpaceCameraState` / `setSpaceWorkPlane` 相关的状态更新，不建议现在强行改成完全模块化注入，因为 Space 仍在使用这条路径。
- `WorkspaceCanvasContext` 当前虽然带有 Space 字段，但已经是既有渲染接口的一部分，不建议为了“更纯”而重做上下文协议。
- `WorkspaceCommand` 的枚举结构不建议现在拆分；它是整个工作区命令总线，贸然分裂会影响大量调用点。
- `FormulaInputState` / `FormulaSemanticState` 仍建议暂留在 WorkspaceKit。它们虽然与 Plane 输入相关，但目前是整个工作区输入系统的公共基座，提前搬迁风险较高。
- `PlaneGeometryStubs.swift` 暂时不要删除。它是 WorkspaceKit 和 Plane 模块之间的过渡接口影子，删除前需要确认所有使用方已经完全替换。

## 5. 建议后续修复任务拆分

1. **任务 A：收口 Plane 输入提交旧逻辑**
   - 目标：把 `canonicalPlaneCommitInput(from:)` 的职责迁移到 Plane 输入构建层。
   - 影响范围：`WorkspaceState.swift`、Plane 的输入/构建服务。
   - 风险：中等，需保证函数创建与编辑提交不回退。

2. **任务 B：收口 Plane 参数上下文构造**
   - 目标：把 `currentLoweringContext()` 中对 `.parameter` 的扫描下沉到模块侧。
   - 影响范围：`WorkspaceState.swift`、`WorkspaceModuleProviding`、Plane 提供者。
   - 风险：中等，涉及函数输入、预览和参数对象联动。

3. **任务 C：清理 `moduleSpecific` 占位入口**
   - 目标：把 `WorkspaceView.swift` 的 `"TODO"` payload 替换为结构化或模块化转发。
   - 影响范围：`WorkspaceView.swift`、`WorkspaceCommand.swift`、各模块 command handler。
   - 风险：中等偏低，但要避免破坏现有工具栏入口。

4. **任务 D：Space 专属 presenter 下沉**
   - 目标：把 `SpaceGeometryInspectorPropertyPresenter` 与 `SpaceGeometryPropertyFormatter` 迁移到更贴近 Space 的层级。
   - 影响范围：`Inspector/SpaceGeometryInspectorPropertyPresenter.swift`、`Shared/SpaceGeometryPropertyFormatter.swift`。
   - 风险：低到中等，主要是路径和引用整理。

5. **任务 E：继续收窄 WorkspaceState 的 Plane 类型知识**
   - 目标：逐步减少 `WorkspaceState` 中对 `.function/.point/.circle/.parameter/.parameterGroup/.arc` 的直接枚举。
   - 影响范围：`WorkspaceState.swift`、Plane 的命令与对象服务。
   - 风险：较高，不建议一次性重构，适合拆成多个小步。

