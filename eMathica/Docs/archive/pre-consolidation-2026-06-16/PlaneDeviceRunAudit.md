# PlaneDeviceRunAudit-1

## 1. Summary

本轮只做结构审计，不改生产代码。  
目标是把真机 iPad 反馈的 7 个问题定位到具体模块、状态源、数据流和风险点，避免继续猜测式 patch。

结论概览：

- **P0（交互阻断）**
  1. Inspector 按钮点不开（大概率是面板层级/位置与交互层冲突）
  2. 输入预览区可点击区域异常（点击 owner 与子视图 hit region 叠加导致）
- **P1（功能完整性）**
  3. 首页封面预览能力不足（封面 renderer 只覆盖函数/点/线段）
  4. 对象区高度偏小（`objectPanelMaxHeight` 在 iPad 上限偏保守）
  5. 复杂 parametric/piecewise 解析失败排障不足（缺少失败分层诊断暴露）
- **P2（系统优化/设计）**
  6. 画布 pan 卡顿（pan 过程高频触发重采样/重渲染）
  7. ABC 与 OpenMathInk 键盘词表统一（需要先抽 catalog，再改 UI）

---

## 2. User-Reported Issues Audit

## Issue 1: 首页文件封面仅能稳定显示简单对象

### Current structure

- 存储与读取：
  - `eMathica/DocumentSystem/IO/LocalProjectStore.swift`
  - 保存项目时调用 `updatePreviewIfPossible`，写 `preview.png`
- 封面渲染：
  - `eMathica/DocumentSystem/Preview/ProjectPreviewRenderer.swift`
  - Home 卡片：
    - `eMathica/CoreHome/ProjectCardView.swift`
    - `eMathica/CoreHome/ProjectThumbnailView.swift`
- `RecentProject.thumbnailKindRawValue` 当前固定为 `"formulaNotes"`（`makeRecentProject`）

### Likely root cause

`ProjectPreviewRenderer` 目前只明确绘制：

- `.function`（且仅 explicitX/explicitY 采样）
- `.point`
- `.segment`

未覆盖 line/ray/circle/intersection、implicit、parametric、piecewise 等对象；  
复杂对象在封面里要么被忽略，要么回退到默认缩略图逻辑。

### Affected files

- `eMathica/DocumentSystem/Preview/ProjectPreviewRenderer.swift`
- `eMathica/DocumentSystem/IO/LocalProjectStore.swift`
- `eMathica/CoreHome/ProjectThumbnailView.swift`

### Recommended patch strategy

1. **Phase 1（最小）**：扩展 `ProjectPreviewRenderer` 的 object 支持集合，优先复用已有 Plane 渲染数据路径（至少 line/ray/circle/intersection/parametric/piecewise/implicit 可见）。
2. **Phase 2**：保存时继续写 `preview.png`，打开列表直接读，不做卡片实时重采样。
3. **Phase 3**：失败降级（icon + object summary），避免空白封面。

### Tests to add

- 文档包含 line/ray/circle/implicit/parametric/piecewise 时 `preview.png` 非空。
- roundtrip 后 `previewURL` 可读且卡片优先使用图片。

---

## Issue 2: 画布移动/拖动时小卡顿

### Current structure

- 手势与视口更新：
  - `eMathica/CalculatorModules/Plane/Views/PlaneCanvasView.swift`
  - `DragGesture.onChanged` 高频 dispatch `.setCanvasViewport(...)`
- 渲染与采样：
  - `eMathica/CalculatorModules/Plane/Views/PlaneObjectRendererView.swift`
  - `eMathica/CalculatorModules/Plane/Services/PlaneFallbackSamplingService.swift`
- 命中测试：
  - `eMathica/CalculatorModules/Plane/Services/PlaneHitTestService.swift`

### Likely root cause

pan 中视口每帧更新会触发整层 SwiftUI invalidation；对象渲染和 hit test 路径中存在语义采样逻辑，导致“平移=可能重采样”。  
真机 GPU/CPU 下比模拟器更容易表现为细小卡顿。

### Affected files

- `eMathica/CalculatorModules/Plane/Views/PlaneCanvasView.swift`
- `eMathica/CalculatorModules/Plane/Views/PlaneObjectRendererView.swift`
- `eMathica/CalculatorModules/Plane/Services/PlaneHitTestService.swift`

### Recommended patch strategy

1. **Phase 1**：把 pan 期间的“视口变换”和“函数重采样”解耦（采样结果缓存 + 屏幕变换）。
2. **Phase 2**：`onEnded` 再做较重计算/持久化（如果需要）。
3. **Phase 3**：hit test 采样降频（只在需要时进行，避免拖动时重复）。

### Tests to add

- pan 期间不触发 document object mutation。
- 同一 expression + parameter env 命中缓存时不重复 sampler。

---

## Issue 3: 右上角 Inspector 按钮点不开

### Current structure

- 按钮：
  - `eMathica/WorkspaceKit/WorkspaceView.swift`
  - `LiquidGlassIconButton` -> `state.dispatch(.setInspectorVisible(...))`
- 状态源：
  - `eMathica/WorkspaceKit/WorkspaceState.swift` (`isInspectorPresented`)
- 面板：
  - `eMathica/WorkspaceKit/Inspector/ObjectInspectorPanel.swift`

### Likely root cause

代码上按钮 action 存在，但 Inspector 面板层级和定位可能与对象层/画布交互层冲突：

- 按钮 `zIndex` 在 controls 层；
- 面板 `zIndex` 目前落在 objects 层；
- 面板位置用固定 `inspectorPanelTop/maxHeight` 计算，在部分真机尺寸可能出现“状态切换了但视觉上像没打开”。

### Affected files

- `eMathica/WorkspaceKit/WorkspaceView.swift`
- `eMathica/WorkspaceKit/WorkspaceLayout.swift`

### Recommended patch strategy

1. **P0 最小修复**：先加状态与 frame debug 断言（按钮点击后 `isInspectorPresented` 是否变更）。
2. 面板层级提升到与 controls 同级或更高，避免被对象层遮挡。
3. iPad 尺寸下重新校验 `inspectorPanelTop/maxHeight`。

### Tests to add

- `setInspectorVisible(true/false)` 状态切换测试。
- `WorkspaceLayoutMetrics` 在 iPad 典型尺寸下 inspector frame 不越界。

---

## Issue 4: 复杂参数方程/分段函数仍解析失败

### Current structure

- 序列化：
  - `eMathica/WorkspaceKit/StructuredInput/MathEditorSerialization.swift`
  - parametric 输出 `x={...}, y={...}, range`
  - piecewise 输出 `piecewise(... if ...)`
- 语义与分类：
  - `eMathica/CalculatorModules/Plane/Services/PlaneSemanticIntentResolver.swift`
  - `eMathica/MathCore/GraphCore/GraphClassifier.swift`
  - `eMathica/CalculatorModules/Plane/Services/PlaneFallbackSamplingService.swift`

### Likely root cause

失败可能发生在以下任一层，但当前 UI 对失败原因暴露不足：

1. AST -> computeExpression 序列化边界条件
2. `GraphClassifier` 对复杂 parametric/piecewise 的分类条件
3. fallback intent 不适用于该表达式
4. sampler 可采样但结果被上层策略过滤

当前用户侧常见现象是“显示有表达式但图像空白”，诊断信号不够。

### Affected files

- `eMathica/WorkspaceKit/StructuredInput/MathEditorSerialization.swift`
- `eMathica/CalculatorModules/Plane/Services/PlaneSemanticIntentResolver.swift`
- `eMathica/MathCore/GraphCore/GraphClassifier.swift`
- `eMathica/CalculatorModules/Plane/Services/PlaneFallbackSamplingService.swift`

### Recommended patch strategy

1. **P1 先做诊断**：把失败分层信息暴露到 draft/object（serialize/classify/fallback/sample 哪一步失败）。
2. 补失败样例 fixture（复杂 range、不等式条件、多行 piecewise）。
3. 再按失败类别做小修，不直接扩 parser 大工程。

### Tests to add

- 复杂 parametric/piecewise fixture 的 intent 解析测试。
- 失败路径 diagnostics 非空且可归因。

---

## Issue 5: 输入预览区点击区域异常（只点最上方有效）

### Current structure

- Dock：
  - `WorkspaceInlineInputDock` in `eMathica/WorkspaceKit/WorkspaceView.swift`
- 打开输入 owner：
  - `editorBar` 外层 `.onTapGesture { state.startFormulaEditing(...) }`
- 公式内容：
  - `eMathica/WorkspaceKit/Keyboard/FormulaEditorView.swift`
  - 使用 `highPriorityGesture(DragGesture(minimumDistance: 0))` 接管内部点击定位
- 硬件键盘捕获：
  - `eMathica/WorkspaceKit/Input/HardwareKeyboardCaptureView.swift`（`allowsHitTesting(false)`）

### Likely root cause

预览区 tap ownership 分裂：

- 外层 editorBar 想“整块可点以打开输入”；
- 内层 FormulaEditorView 用高优先级手势处理 slot 点击；
- 再叠加 GlassPanel/overlay/contentShape，导致“只有顶部某块稳定命中外层 tap”。

### Affected files

- `eMathica/WorkspaceKit/WorkspaceView.swift`
- `eMathica/WorkspaceKit/Keyboard/FormulaEditorView.swift`
- `eMathica/WorkspaceKit/Shared/LiquidGlassPanel.swift`（只需确认 hit-test 行为）

### Recommended patch strategy

1. **P0 最小修复**：明确 closed/open 两种 tap owner：
   - closed：editorBar 整块 contentShape 统一开输入
   - open：FormulaEditorView 内部命中优先（slot/cursor）
2. 按钮区域（keyboard/xmark/submit）保持独立优先级，不冒泡误触发开输入。
3. 玻璃层只做视觉，不承担点击逻辑。

### Tests to add

- closed 状态：点击 editorBar 任意空白区都能 openInput。
- open 状态：点击 slot 走 cursor，不重入 openInput。

---

## Issue 6: 对象区范围偏小，希望对象少时自动变高，达上限再滚动

### Current structure

- 高度计算：
  - `resolvedObjectPanelHeight` in `eMathica/WorkspaceKit/WorkspaceView.swift`
  - `AlgebraObjectPanelLayoutMetrics.contentHeight(...)` in `eMathica/WorkspaceKit/ObjectPanel/AlgebraObjectPanelView.swift`
- 当前上限：
  - `WorkspaceLayoutMetrics.objectPanelMaxHeight = max(220, size.height * 0.58)`

### Likely root cause

“先自适应后滚动”的模型已经有，但 iPad 真机下 `maxHeight` 比例和顶部/底部占用叠加后体感仍偏小。  
问题更可能是 maxHeight 策略偏保守，而不是 row 计算错误。

### Affected files

- `eMathica/WorkspaceKit/WorkspaceView.swift`
- `eMathica/WorkspaceKit/WorkspaceLayout.swift`
- `eMathica/WorkspaceKit/ObjectPanel/AlgebraObjectPanelView.swift`

### Recommended patch strategy

1. **P1**：按设备上下文细化 maxHeight（iPad landscape 可提升到 0.62~0.68 区间再验证）。
2. 保持“contentHeight clamp 到 maxHeight + ScrollView”结构不变。
3. 不动对象区 row 高度与间距算法（除非测试证明必要）。

### Tests to add

- 给定 iPad 尺寸下 `resolvedObjectPanelHeight` 达到新上限策略。
- objectCount 少量时高度随行数增长，多量时触发滚动。

---

## Issue 7: ABC 与 OpenMathInk 字母键盘方案统一

### Current structure

- 键盘页定义：
  - `eMathica/WorkspaceKit/Keyboard/MathKeyboardView.swift`
  - `MathKeyboardTab.rows` 目前是硬编码二维数组
- ABC 页当前并非完整字母表，Greek 在符号页第三行部分提供。

### Likely root cause

当前键位数据直接写在 View 枚举里，不是共享词表模型；  
未来 OpenMathInk 需要复用 vocabulary 时会重复维护。

### Affected files

- `eMathica/WorkspaceKit/Keyboard/MathKeyboardView.swift`
- （后续新增）`WorkspaceKit/Keyboard/MathSymbolCatalog.swift` / `KeyboardSymbolProvider.swift`

### Recommended patch strategy

1. **P2 设计先行**：先抽 `MathSymbolCatalog`（latin lower/upper, greek lower/upper, operators, functions, templates）。
2. 再让 eMathica 键盘和 OpenMathInk 输入页共同消费 provider。
3. 最后再改 ABC/Greek 页展示策略（同页二级切换或独立 Greek 页）。

### Tests to add

- catalog 完整性测试（A-Z、a-z、常用 Greek 是否齐全）。
- provider 到 keyboard page 的映射测试。

---

## 3. Priority Ranking

- **P0**
  1. Inspector 按钮点不开
  2. 预览区点击区域异常
- **P1**
  1. 封面 renderer 能力不足
  2. 对象区高度上限偏小
  3. parametric/piecewise 失败诊断不足
- **P2**
  1. pan 性能优化（缓存与重采样解耦）
  2. ABC/OpenMathInk 词表统一设计

---

## 4. Proposed Next Steps (small, staged)

1. **Patch-P0A**：修 Inspector 打开链路（层级/位置/状态验证）。
2. **Patch-P0B**：修 preview tap owner（closed/open 分层点击责任）。
3. **Patch-P1A**：扩封面 renderer 类型支持（先复用已支持 Plane 对象）。
4. **Patch-P1B**：对象区 maxHeight 策略按 iPad 场景微调。
5. **Patch-P1C**：补 parametric/piecewise 分层 diagnostics 与 fixture。
6. **Design-P2A**：pan 性能解耦方案设计与 profiling 点位。
7. **Design-P2B**：MathSymbolCatalog 设计稿，后续统一 eMathica + OpenMathInk。

---

## 5. Verification focus for next patch rounds

- Inspector/button：
  - state toggle
  - panel frame visibility
  - zIndex/hit-testing
- Preview tap：
  - closed 整块可点
  - open slot 命中不回退
  - action buttons 不冲突
- Home cover：
  - complex object preview non-empty
  - preview.png save/read stability
- Object panel：
  - small object count auto-grow
  - max height reached then scroll
- Parametric/piecewise：
  - diagnostics surfaced
  - known failing fixtures tracked

