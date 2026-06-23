# Calculator Capability Matrix

> **日期:** 2026-06-17
> **模式:** 只读架构审计
> **输入:** FineGrainedCapabilityAudit.md, DocumentObjectKindProposal.md, 源码审计
> **原则:** Object First, Unified Document, Materialize Conversion

---

## 1. 操作能力代码

| 代码 | 含义 | 判定标准 |
|------|------|----------|
| **C** | Create | Calculator 可通过 UI Tool 创建该 kind 的新对象 |
| **E** | Edit | Calculator 可修改该 kind 对象的属性（位置、表达式、参数等） |
| **V** | View | Calculator 可在 Canvas 中渲染/显示该 kind 对象 |
| **I** | Import | Calculator 可从外部格式导入该 kind 对象 |
| **X** | Export | Calculator 可将该 kind 对象导出为外部格式 |
| **T** | Convert | Calculator 可将该 kind 对象 materialize convert 为另一种 kind |
| **M** | Embed | Calculator 可将该 kind 对象作为另一个对象的子元素嵌入 |
| **—** | Unsupported | 当前不支持，无规划路径 |
| **◎** | Planned | 当前未实现，已有明确规划 |

---

## 2. Calculator 能力总览

| Calculator | 当前状态 | 文件数 | 成熟度 | 能力域 |
|-----------|---------|--------|--------|--------|
| **Plane** | 主力开发 (67 files) | 67 | ●●●●● 高 | 2D 函数、几何、构造 |
| **Space** | 早期开发 (9 files) | 9 | ●●○○○ 低 | 3D 几何、相机、渲染 |
| **Data** | 占位 (1 file) | 1 | ●○○○○ 极低 | 表格、统计、图表 |
| **Music** | 占位 (1 file) | 1 | ●○○○○ 极低 | 音频波形、播放 |
| **Notes** | 占位 (1 file) | 1 | ●○○○○ 极低 | 文本、LaTeX 公式 |
| **Modeling** | 占位 (1 file) | 1 | ●○○○○ 极低 | 3D 曲面建模 |

---

## 3. 详细能力矩阵

### 3.1 2D 基本几何对象

| Object Kind | Plane | Space | Data | Music | Notes | Modeling |
|-------------|-------|-------|------|-------|-------|----------|
| **point.2d** | C E V I X T→3d M | V T→3d — — — — | V — — I — — — | — | V — — — — M — | V — — — — — — |
| **segment.2d** | C E V — — — — | V — — — — — — | — | — | — | V — — — — — — |
| **line.2d** | C E V — — — — | V — — — — — — | — | — | — | V — — — — — — |
| **ray.2d** | C E V — — — — | V — — — — — — | — | — | — | V — — — — — — |
| **circle.2d** | C E V — — — — | V — — — — — — | — | — | — | V — — — — — — |
| **arc.2d** | C E V — — — — | V — — — — — — | — | — | — | V — — — — — — |

**说明:**
- Plane 当前通过 `PlaneConstructionMode` 支持 11 种构造模式（point, segment, midpoint, line, ray, parallel, perpendicular, circle, arc, intersection, function）
- Space 当前对 2D 对象仅支持 View（通过 3D 投影或 XY 工作平面）
- Space 的 `T→point.3d` 是指用户编辑 2D point 的 Z 坐标时触发 materialize conversion

### 3.2 3D 几何对象

| Object Kind | Plane | Space | Data | Music | Notes | Modeling |
|-------------|-------|-------|------|-------|-------|----------|
| **point.3d** | V T→2d — — — — — | C E V — — T→2d M | V — — I — — — | — | — | C◎ E◎ V — — — — |
| **segment.3d** | — | C E V — — — — | — | — | — | C◎ E◎ V — — — — |
| **line.3d** | — | C E V — — — — | — | — | — | C◎ E◎ V — — — — |
| **plane.3d** | — | C E V — — — — | — | — | — | C◎ E◎ V — — — — |

**说明:**
- Space 当前通过 `SpaceCommandHandler` 支持 point.3d, segment.3d, line.3d, plane.3d 创建
- Space `T→point.2d` 在降至 2D 查看时发生
- Plane 当前通过 2D 投影查看 3D 对象（`CanvasState` 无 Z 轴概念）
- **类型泄露:** 当前 `MathObjectType` 无 `plane3D` 枚举值，Space 的 plane.3d 使用 `MathObjectType.function` + `GeometryDefinition.kind == .plane3D` 的 hack 方式

### 3.3 曲线对象

| Object Kind | Plane | Space | Data | Music | Notes | Modeling |
|-------------|-------|-------|------|-------|-------|----------|
| **curve.explicit2d** (y=f(x)) | C E V — X T→table T→wave — | V — — — — — — | C◎ E◎ V I◎ X T→table — — | — | V — — — — M — | — |
| **curve.explicitX2d** (x=f(y)) | C◎ E◎ V — — — — | — | — | — | — | — |
| **curve.implicit2d** (f(x,y)=0) | C◎ V — — — — — | — | — | — | — | — |
| **curve.parametric2d** | C◎ E V — — T→table◎ — — | V — — — — — — | — | — | — | — |
| **curve.polar2d** | C◎ V — — — — — | — | — | — | — | — |
| **curve.parametric3d** | — | C◎ V — — — — — | — | — | — | C◎ E◎ V — — — — |

**说明:**
- Plane 当前主要实现 `curve.explicit2d`（`PlaneExpressionService.buildExpression()` + `AlgebraCore.analyzePlaneLatex()` 识别 explicitY）
- `PlaneSemanticGraphIntentAdapter` 已支持识别 parametric2D、polar、implicit 等 GraphIntent，但创建和编辑流程未完全实现
- `PlaneSamplingQualityPolicy` 和 `PlaneSamplingViewportResolver` 为显式函数采样提供完整支持
- Space 的 `curve.parametric3d` 当前通过 `PlaneCommandHandler` 的 `.function` 类型 hack 实现（type leakage）

### 3.4 曲面对象

| Object Kind | Plane | Space | Data | Music | Notes | Modeling |
|-------------|-------|-------|------|-------|-------|----------|
| **surface.explicit3d** (z=f(x,y)) | — | — | — | — | — | C◎ E◎ V — — T→contour◎ — |
| **surface.parametric3d** | — | — | — | — | — | C◎ E◎ V — — T→contour◎ — |

**说明:**
- 曲面完全属于未来 Modeling calculator 的领域
- `T→contour`（surface → curve.implicit2d 等高线）是长期规划能力
- 当前 `EMathicaMathCore` 中无曲面相关类型定义

### 3.5 圆锥曲线对象

| Object Kind | Plane | Space | Data | Music | Notes | Modeling |
|-------------|-------|-------|------|-------|-------|----------|
| **conic.ellipse2d** | C◎ V — — — — — | — | — | — | — | — |
| **conic.parabola2d** | C◎ V — — — — — | — | — | — | — | — |
| **conic.hyperbola2d** | C◎ V — — — — — | — | — | — | — | — |

**说明:**
- `AlgebraClassification.Kind` 已可分类 `.ellipse`, `.parabola`, `.hyperbola`
- `SemanticGraphKind` 已包含 `.ellipse`, `.parabola`, `.hyperbola`
- 当前 Plane 将所有圆锥曲线折叠为 `.circle` 或 `.function`（类型折叠）
- 需等 P1 object-first kind 冻结后分离

### 3.6 公式与关系对象

| Object Kind | Plane | Space | Data | Music | Notes | Modeling |
|-------------|-------|-------|------|-------|-------|----------|
| **formula.symbolic** | C E V — — — M | V — — — — — — | — | — | C◎ E◎ V I◎ X◎ — — | — |
| **relation.equality** | C E V — — — — | — | — | — | C◎ E◎ V — — — — | — |
| **relation.inequality** | C◎ V — — — — — | — | — | — | C◎ E◎ V — — — — | — |

**说明:**
- Plane 当前通过 `MathObjectType.function` + `MathExpression(displayText:)` 表达公式
- Notes 是 formula.symbolic 的自然主力 calculator（符号编辑、整理、排版）
- Plane 中 formula 的主要用途是作为曲线的表达式来源

### 3.7 数据集合对象

| Object Kind | Plane | Space | Data | Music | Notes | Modeling |
|-------------|-------|-------|------|-------|-------|----------|
| **set.point2d** | V — — I X — — | V — — I — — — | C◎ E◎ V I◎ X◎ — M | — | — | — |
| **set.point3d** | — | V — — I — — — | C◎ E◎ V I◎ X◎ — — | — | — | C◎ V — I — — — |
| **table.data** | — | — | C◎ E◎ V I◎ X◎ T→set◎ — | — | — | — |
| **table.function** | I V — — X T→curve◎ — | — | C◎ E◎ V I◎ X◎ T→curve◎ — | — | — | — |

**说明:**
- Data calculator 是 table/set 的自然归属
- Plane 当前可查看 set.point2d（作为 scatter plot 叠加到坐标系）
- `table.data → set.point2d` 转换：table 的 (x,y) 列提取为点集
- `table.function → curve.explicit2d` 转换：通过回归/插值从表格恢复函数（不可逆，有损）

### 3.8 音频对象

| Object Kind | Plane | Space | Data | Music | Notes | Modeling |
|-------------|-------|-------|------|-------|-------|----------|
| **wave.audio** | — | — | — | C◎ E V — X — — | — | — |

**说明:**
- wave.audio 完全属于 Music calculator
- `curve.explicit2d → wave.audio` 是未来转换：将函数通过采样生成音频（不可逆）
- 依赖 `EMathicaSamplingCore` 的高密度采样（音频需要 44100Hz+）

### 3.9 文本与媒体对象

| Object Kind | Plane | Space | Data | Music | Notes | Modeling |
|-------------|-------|-------|------|-------|-------|----------|
| **text.block** | V — — — — — M | V — — — — — M | V — — — — — M | V — — — — — M | C E V — X — M | V — — — — — M |
| **image.asset** | V — — I — — M | V — — I — — M | — | — | V — — I — — M | V — — I — — M |

**说明:**
- text.block 和 image.asset 是跨 calculator 的通用对象
- Notes 是 text.block 的唯一 Creator/Editor
- 所有 calculator 均可 Embed（如 Plane 中的标注文本框、Space 中的参考图像）

### 3.10 参数控制对象

| Object Kind | Plane | Space | Data | Music | Notes | Modeling |
|-------------|-------|-------|------|-------|-------|----------|
| **slider.parameter** | C E V — — — M | V — — — — — — | C◎ E V — — — M | — | — | — |
| **slider.group** | C E V — — — M | — | — | — | — | — |

**说明:**
- Plane 当前的 `MathObjectType.parameter` 和 `MathObjectType.parameterGroup` 是成熟的 slider 实现
- `PlaneToolIDs.slider = "plane.slider"` 已注册
- Space 可以 View slider 但不创建（3D 动画参数未来由 Modeling 管理）

### 3.11 构造关系对象

| Object Kind | Plane | Space | Data | Music | Notes | Modeling |
|-------------|-------|-------|------|-------|-------|----------|
| **construction.midpoint** | C E V — — — — | — | — | — | — | — |
| **construction.parallel** | C E V — — — — | — | — | — | — | — |
| **construction.perpendicular** | C E V — — — — | — | — | — | — | — |
| **construction.intersection** | C E V — — — — | C◎ E◎ V — — — — | — | — | — | — |

**说明:**
- 构造关系对象是 2D 几何的核心交互模式（PlaneConstructionMode 的 11 种状态）
- Space 的 intersection 是规划的（3D 线与面相交、面与面相交）
- 构造关系对象在 `GeometryDependency` 中记录依赖关系

### 3.12 插件自定义对象

| Object Kind | Plane | Space | Data | Music | Notes | Modeling |
|-------------|-------|-------|------|-------|-------|----------|
| **plugin.customObject** | — | — | — | — | — | — |

**说明:**
- 全 calculator 均为 Unsupported，无规划路径
- 这是 PluginKit 长期规划的一部分，依赖于 Scratch 式插件系统

---

## 4. 能力统计

### 4.1 按 Calculator 统计

| Calculator | Create | Edit | View | Import | Export | Convert | Embed |
|-----------|--------|------|------|--------|--------|---------|-------|
| **Plane** | 15 | 15 | 27 | 5 | 3 | 4 | 8 |
| **Space** | 4 | 4 | 22 | 3 | 0 | 2 | 4 |
| **Data** | 6◎ | 6◎ | 14 | 7◎ | 4◎ | 4◎ | 2 |
| **Music** | 1◎ | 1 | 1 | 0 | 1◎ | 0 | 0 |
| **Notes** | 2◎ | 2◎ | 13 | 2◎ | 2◎ | 0 | 12 |
| **Modeling** | 7◎ | 7◎ | 14 | 1 | 0 | 2◎ | 2 |

> ◎ 标记表示当前未实现但已规划

### 4.2 按 Object Kind 统计

| 域 | Object Kind 数 | 已实现 C/E 的 Calculator | 可 View 的 Calculator |
|----|---------------|------------------------|---------------------|
| 2D 几何 | 6 | Plane 独有 | Plane + Space View |
| 3D 几何 | 4 | Space 独有 | Space + Plane View (投影) |
| 曲线 | 6 | Plane 主要 | Plane + Space View |
| 曲面 | 2 | 无 (Modeling◎) | 无 |
| 圆锥曲线 | 3 | 无 (Plane◎) | Plane View |
| 公式/关系 | 3 | Plane partial | Plane + Notes◎ + Space View |
| 数据集合 | 4 | 无 (Data◎) | Plane View + Space View |
| 音频 | 1 | 无 (Music◎) | 无 |
| 文本/媒体 | 2 | Notes◎ (text) / Notes◎ View (image) | 所有 |
| 参数控制 | 2 | Plane 独有 | Plane + Space View + Data◎ View |
| 构造关系 | 4 | Plane 独有 | Plane |
| 插件 | 1 | 无 | 无 |
| **总计** | **38** | | |

---

## 5. 关键发现

### 5.1 能力集中度过高

Plane calculator 占有了 Object Kind 总数中 39% (15/38) 的 Create/Edit 能力，远高于其他 calculator。这不是因为 Plane "应该"拥有这些能力，而是因为其他 calculator 尚未开发。

### 5.2 Space calculator 的类型泄露

Space 当前通过以下 hack 绕过 `MathObjectType` 的 2D 偏向：

| 3D Kind | 当前使用的 MathObjectType | 问题 |
|---------|--------------------------|------|
| plane.3d | `.function` | 语义错误：plane 不是 function |
| point.3d | `.point` | 歧义：无法区分 2D/3D point |
| segment.3d | `.segment` | 歧义：无法区分 2D/3D segment |

这需要在 P1 object-first kind 冻结中解决。

### 5.3 View 能力跨 Calculator 共享

所有 calculator 均可 View 2D 和 3D 基本几何对象。这意味着 View 渲染不应是 calculator-specific 的，而应是 kind-specific 的共享能力。

### 5.4 Convert 能力需要 Calculator 合作

大多数 Convert 能力需要两个 Calculator 同时具备：
- `point.2d → point.3d`：Plane 创建 + Space 编辑 Z → 触发 materialize
- `curve → table`：Plane 创建 + Data 采样 → 生成 table
- `curve → wave`：Plane 创建 + Music 采样 → 生成音频

这说明 Convert 需要跨 Calculator 协调机制。

### 5.5 Embed 是通用能力

text.block 和 image.asset 可被所有 calculator Embed。这是 `Unified EMathicaDocument` 的核心价值：任何 calculator 都可以在文档中嵌入文本标注或参考图像。

---

## 6. 与 Capability Registry 的对应

本矩阵中每个操作对应 CapabilityRegistryDraft.json 中的一组 capability：

| 操作 | Capability ID 模式 | 示例 |
|------|-------------------|------|
| Create | `document.object.add` + `object.kind.define` | `document.object.add` (通过 DocumentCommand) |
| Edit | `document.object.update` | 通过 `DocumentObjectPatch` |
| View | `geometry.present.*` + `graph.render.*` | `geometry.present.point2d` (PlaneObjectRendererView) |
| Import | `document.object.import.*` | 待实现 |
| Export | `document.export.*` | 待实现 |
| Convert | `object.convert.*.to*` | `object.convert.point2d.toPoint3d` |
| Embed | `object.embed.*` | 待实现 |
