# Plugin Capability Exposure Policy

> **日期:** 2026-06-16
> **原则:** 为 Scratch 式插件系统准备 Capability Inventory

---

## 1. Exposure Levels

| Level | Icon | Description | Examples |
|-------|------|-------------|----------|
| **safe** | 🟢 | 无副作用，无需权限。纯计算/渲染。 | `formula.render.latex`, `cas.normalize`, `graph.classify.explicitY` |
| **restricted** | 🟡 | 会修改文档状态或触发 IO。需要用户权限/确认。 | `document.object.add`, `command.undo.execute`, `document.save` |
| **internal** | 🔵 | 仅系统内部使用。不开放给插件。 | `workspace.shell`, `document.package.codec`, `plugin.capability.expose` |
| **blocked** | 🔴 | 绝对不对外开放。 | `document.delete.all`, `plugin.safety.bypass` |

---

## 2. Safe Capabilities (可以开放给插件)

### Pure Math Computation
```
cas.normalize               🟢 safe
cas.simplify                🟢 safe
cas.canonicalize            🟢 safe
cas.expand.polynomial       🟢 safe
cas.differentiate           🟢 safe
cas.solve.equation          🟢 safe (no side effects)
cas.extract.quadratic       🟢 safe
cas.extract.conic           🟢 safe
geometry.intersection       🟢 safe
geometry.distance           🟢 safe
```

### Graph & Sampling
```
graph.classify.explicitY    🟢 safe
graph.classify.implicit2D   🟢 safe
graph.classify.parametric2D 🟢 safe
graph.classify.polar2D      🟢 safe
graph.classify.conic        🟢 safe
graph.classify.piecewise    🟢 safe
graph.sample.explicit2D     🟢 safe
graph.sample.implicit2D     🟢 safe
graph.sample.parametric2D   🟢 safe
graph.sample.polar2D        🟢 safe
graph.sample.conic          🟢 safe
```

### Formula Rendering
```
formula.render.latex        🟢 safe
formula.render.label        🟢 safe
formula.render.inline       🟢 safe
formula.render.thumbnail    🟢 safe
formula.render.fallback     🟢 safe
```

### Expression
```
expr.parse.latex            🟢 safe
expr.parse.source           🟢 safe
expr.format.latex           🟢 safe
expr.serialize.json         🟢 safe
```

### Style
```
style.math.define           🟢 safe
style.color.token           🟢 safe
style.glass                 🟢 safe
```

---

## 3. Restricted Capabilities (需要权限确认)

### Document Modification
```
document.object.add         🟡 restricted — 需要 "修改文档" 权限
document.object.delete      🟡 restricted — 需要 "修改文档" 权限
document.object.update      🟡 restricted — 需要 "修改文档" 权限
command.workspace.dispatch  🟡 restricted — 需要 "执行命令" 权限
command.document.apply      🟡 restricted — 需要 "修改文档" 权限
command.undo.execute        🟡 restricted — 需要 "修改文档" 权限
command.redo.execute        🟡 restricted — 需要 "修改文档" 权限
```

### Selection & State
```
selection.single            🟡 restricted — 需要 "改变选择" 权限
selection.multi             🟡 restricted — 需要 "改变选择" 权限
selection.hitTest.object    🟡 restricted — 需要 "读取画布状态" 权限
inspector.style.edit        🟡 restricted — 需要 "修改对象样式" 权限
animation.parameter.play    🟡 restricted — 需要 "控制动画" 权限
```

### IO
```
document.save               🟡 restricted — 需要 "文件访问" 权限
document.load               🟡 restricted — 需要 "文件访问" 权限
preview.project.render      🟡 restricted — 需要 "渲染" 权限
preview.thumbnail.generate  🟡 restricted — 需要 "渲染" 权限
```

### Object Conversion
```
object.convert.point2d.toPoint3d  🟡 restricted — 需要 "对象转换" 权限
object.convert.curve.toWave       🟡 restricted — 需要 "对象转换" 权限
object.convert.curve.toTable      🟡 restricted — 需要 "对象转换" 权限
```

---

## 4. Internal Capabilities (不开放)

```
workspace.shell             🔵 internal — 系统基础设施
workspace.module.register   🔵 internal — 系统注册
workspace.canvas.integrate  🔵 internal — 系统渲染
workspace.command.route     🔵 internal — 命令路由
workspace.tool.groups       🔵 internal — 工具栏管理
document.package.codec      🔵 internal — 文件格式
input.keyboard.layout       🔵 internal — 键盘 UI
input.session.edit          🔵 internal — 编辑会话
plugin.capability.expose    🔵 internal — 插件系统自身
plugin.safety.policy        🔵 internal — 安全策略
plugin.permission.model     🔵 internal — 权限模型
```

---

## 5. Capability → Plugin Block Mapping

### 5.1 Plugin Block 概念

一个 **Plugin Block** 是一个用户可组合的功能块，内部封装了 1-N 个 Capability。

类似 Scratch 的积木块，用户拖拽组合不同的 Block 来实现复杂功能。

### 5.2 Block 结构

```swift
public struct PluginBlock: Identifiable, Codable {
    public let id: String                    // "formula.render.latex.and.simplify"
    public let displayName: String           // "Render & Simplify"
    public let description: String           // "Render a LaTeX formula and display its simplified form"
    public let capabilities: [String]        // ["formula.render.latex", "cas.simplify"]
    public let parameters: [BlockParameter]  // user-adjustable settings
    public let exposureLevel: ExposureLevel  // derived from max(capabilities.exposure)
}

public struct BlockParameter: Codable {
    public let id: String        // "fontSize"
    public let displayName: String
    public let type: ParameterType  // .number, .string, .choice, .boolean, .color
    public let defaultValue: AnyCodable
    public let range: ParameterRange?  // for .number
    public let choices: [String]?      // for .choice
}
```

### 5.3 示例 Block

```
Block: "Render Formula with Derivative"
  Capabilities:
    - formula.render.latex      🟢 safe
    - cas.differentiate         🟢 safe
  Parameters:
    - fontSize: 14              (number: 8-48)
    - variable: "x"             (choice: ["x", "y", "t"])
    - showOriginal: true        (boolean)
  Exposure: 🟢 safe (all capabilities are safe)

Block: "Sample and Export to Table"
  Capabilities:
    - graph.sample.explicit2D   🟢 safe
    - object.convert.curve.toTable  🟡 restricted
  Parameters:
    - xMin: -10                 (number)
    - xMax: 10                  (number)
    - sampleCount: 100          (number: 10-10000)
  Exposure: 🟡 restricted (contains restricted capability)
```

---

## 6. Why Scratch-Style Plugin System on iOS?

### 6.1 iOS 限制

iOS **不允许** JIT 编译、不允许动态加载二进制代码。传统的"自由代码"插件（如 VSCode 扩展、Figma 插件）在 iOS 上不可行。

### 6.2 Scratch-Style 解决方案

Scratch 式插件系统通过 **预定义的 Capability Block 组合** 来替代自由代码：

| 传统插件 | Scratch 式插件 |
|---------|---------------|
| 用户写 JavaScript/Python 代码 | 用户拖拽 Block 组合 |
| 运行时动态加载代码 | 所有能力都在编译时确定 |
| 安全风险高（任意代码执行） | 安全风险极低（仅允许白名单能力） |
| 需要沙箱环境 | 不需要沙箱（Block 内部实现已受控） |
| iOS 不可行 | ✅ iOS 可行 |

### 6.3 Block 组合能力

用户可以将多个 Block 串联：

```
[Input Formula] → [Canonicalize] → [Extract Conic] → [Sample] → [Render Canvas] → [Export PNG]
  🟡 restricted      🟢 safe         🟢 safe         🟢 safe     🟡 restricted    🟡 restricted

→ 最终用户看到的是: "输入公式 → 识别为椭圆 → 绘制 → 导出 PNG"
→ 内部实现是: 5 个 Capability 的链式调用
```

---

## 7. Plugin Execution Safety Boundary

### 7.1 执行模型

```
User Canvas (Scratch-style UI)
  │
  ├── Drag Block A (capability: formula.render.latex)
  ├── Drag Block B (capability: cas.simplify)
  ├── Connect A → B pipeline
  └── Press "Run"
       │
       ▼
PluginExecutor (internal)
  │
  ├── Check: Block A exposure = 🟢 safe → OK
  ├── Check: Block B exposure = 🟢 safe → OK
  ├── Pipeline: Block A → Block B (both safe, no permission needed)
  └── Execute: formula.render.latex(input) → cas.simplify(result)
       │
       ▼
Result displayed in Canvas (read-only preview layer)
  │
  ├── User can: discard result
  └── User can: "Commit to Document" → now requires 🟡 restricted permission
```

### 7.2 安全规则

| Rule | Description |
|------|-------------|
| **Sandbox by default** | 所有 Block 在受控环境中执行，不能访问文件系统、网络、或系统 API |
| **Permission escalation** | 如果 Block 流水线包含任何 `restricted` capability，运行前必须获得用户确认 |
| **Read-only preview** | Block 执行结果先显示在预览层，用户确认后才写入 Document |
| **Resource limits** | CPU 时间限制（防止无限循环）、内存限制（防止 OOM） |
| **No network access** | Block 不能发起网络请求 |
| **No file system access** | Block 不能读写任意文件，只能通过 `document.save`/`document.load` |
| **Capability whitelist** | 只有显式标记为 `safe` 或 `restricted` 的能力可被 Block 使用 |
| **No capability chaining bypass** | Block 只能使用其声明的 capabilities，不能动态调用未声明的 |
| **User-visible capability disclosure** | 每个 Block 运行时显示正在使用的能力列表 |

### 7.3 Permission Model

```
Permission request dialog:
┌──────────────────────────────────────────┐
│  Plugin "Export Graph as Table" wants to: │
│                                           │
│  📊 Sample graph data    🟢 safe         │
│  📝 Create table object  🟡 restricted   │
│  💾 Save to document     🟡 restricted   │
│                                           │
│  [Allow Once]  [Always Allow]  [Deny]    │
└──────────────────────────────────────────┘
```

---

## 8. Implementation Phases

### Phase 1: Capability Registry (Post-v1.0)
- 从 [CapabilityRegistryDraft.json](./CapabilityRegistryDraft.json) 构建正式 Capability Registry
- 在 EMathicaPluginKit 中实现 Capability 注册和查询 API

### Phase 2: Plugin Block System (Future)
- 定义 PluginBlock 和 BlockParameter 类型
- 实现 Block 组合和流水线执行
- 实现权限检查和确认 UI

### Phase 3: Scratch-Style UI (Future)
- 可拖拽的 Block 编辑器
- Block 流水线可视化
- 预览层和 Commit 确认

### Phase 4: Block Marketplace (Long-term)
- 社区 Block 分享
- Block 包导入/导出
- Block 版本管理和兼容性检查
