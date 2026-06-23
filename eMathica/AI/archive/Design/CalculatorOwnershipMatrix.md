# Calculator Ownership Matrix

> **日期:** 2026-06-17
> **模式:** 只读架构审计
> **输入:** CalculatorCapabilityMatrix.md, DocumentObjectKindProposal.md, 源码审计
> **原则:** Object First, 能力归属清晰, 冲突显式化

---

## 1. 所有权定义

| 角色 | 含义 | 判定标准 |
|------|------|----------|
| **Primary Owner** | 该 Object Kind 的主要创建者和编辑者 | 唯一可 Create 的 Calculator；或主要编辑入口 |
| **Secondary Owner** | 可参与编辑的 Calculator | 可以 Edit 但不是创建者 |
| **Viewer** | 仅可查看的 Calculator | 只能 View/Embed，不可 Edit |
| **Converter** | 可触发 Materialize Conversion 的 Calculator | 可执行 T（Convert）操作 |
| **Importer** | 可从外部格式导入该 kind 的 Calculator | 可执行 I（Import）操作 |
| **N/A** | 不参与该 kind 的 Calculator | 所有操作均为 — |

---

## 2. 所有权矩阵

### 2.1 2D 基本几何对象

| Object Kind | Primary Owner | Secondary Owner | Viewers | Converters | Importers |
|-------------|--------------|-----------------|---------|------------|-----------|
| **point.2d** | **Plane** | — | Space, Data, Notes, Modeling | Plane (→3d), Space (→3d) | Plane, Data |
| **segment.2d** | **Plane** | — | Space, Modeling | — | — |
| **line.2d** | **Plane** | — | Space, Modeling | — | — |
| **ray.2d** | **Plane** | — | Space, Modeling | — | — |
| **circle.2d** | **Plane** | — | Space, Modeling | — | — |
| **arc.2d** | **Plane** | — | Space, Modeling | — | — |

**判定依据:**
- Plane 通过 `PlaneToolProvider` 提供所有 2D 几何 Tool（point, segment, midpoint, line, ray, parallel, perpendicular, circle, arc, intersection）
- Space 的 `SpaceToolProvider` 不含 2D 几何 Tool
- 无其他 Calculator 注册 2D 几何创建工具

### 2.2 3D 几何对象

| Object Kind | Primary Owner | Secondary Owner | Viewers | Converters | Importers |
|-------------|--------------|-----------------|---------|------------|-----------|
| **point.3d** | **Space** | Modeling◎ | Plane, Data | Space (→2d), Plane (→2d) | Space, Data |
| **segment.3d** | **Space** | Modeling◎ | Plane | — | — |
| **line.3d** | **Space** | Modeling◎ | Plane | — | — |
| **plane.3d** | **Space** | Modeling◎ | Plane | — | — |

**判定依据:**
- `SpaceToolProvider` 注册 point3D, segment3D, line3D, plane3D 四个 3D 工具
- Modeling 当前是占位，未来可能成为 Secondary Owner（3D 曲面编辑场景中编辑控制点、法线等）
- Plane 通过 2D 投影可 View 所有 3D 对象
- Space 的点 Z 坐标编辑可触发 `point.3d → point.2d` materialize conversion

### 2.3 曲线对象

| Object Kind | Primary Owner | Secondary Owner | Viewers | Converters | Importers |
|-------------|--------------|-----------------|---------|------------|-----------|
| **curve.explicit2d** | **Plane** | Data◎ (table→curve) | Space, Notes | Plane (→table, →wave) | Plane |
| **curve.explicitX2d** | **Plane◎** | — | — | — | — |
| **curve.implicit2d** | **Plane◎** | — | — | — | — |
| **curve.parametric2d** | **Plane◎** | — | Space | Plane (→table) | — |
| **curve.polar2d** | **Plane◎** | — | — | — | — |
| **curve.parametric3d** | **Space◎** | Modeling◎ | Plane | — | — |

**判定依据:**
- Plane 当前完整实现 curve.explicit2d（`PlaneExpressionService` + `AlgebraCore.analyzePlaneLatex()` + 采样）
- explicitX2d, implicit2d, polar2d 在 `SemanticGraphKind` 中已有枚举值但创建流程未完成
- parametric2d 有 `PlaneSemanticGraphIntentAdapter` 支持识别但创建未实现
- parametric3d 当前通过 `MathObjectType.function` hack 实现在 Space 中（类型泄露）
- Data 通过 `table.function → curve.explicit2d` 回归/插值成为 Secondary Owner

### 2.4 曲面对象

| Object Kind | Primary Owner | Secondary Owner | Viewers | Converters | Importers |
|-------------|--------------|-----------------|---------|------------|-----------|
| **surface.explicit3d** | **Modeling◎** | — | — | Modeling (→contour) | — |
| **surface.parametric3d** | **Modeling◎** | — | — | Modeling (→contour) | — |

**判定依据:**
- 曲面完全未实现，规划归属 Modeling
- Space 不包含曲面能力（当前 Space 仅处理 wireframe 渲染）
- 等高线转换 `surface → curve.implicit2d` 是 Modeling 独有能力

### 2.5 圆锥曲线对象

| Object Kind | Primary Owner | Secondary Owner | Viewers | Converters | Importers |
|-------------|--------------|-----------------|---------|------------|-----------|
| **conic.ellipse2d** | **Plane◎** | — | — | — | — |
| **conic.parabola2d** | **Plane◎** | — | — | — | — |
| **conic.hyperbola2d** | **Plane◎** | — | — | — | — |

**判定依据:**
- `AlgebraClassification.Kind` 可分类，`SemanticGraphKind` 有对应枚举
- 当前 Plane 将圆锥曲线折叠为 `.circle` 或 `.function`（类型折叠）
- 未来应在 object-first kind 冻结后从 `.function` 中分离

### 2.6 公式与关系对象

| Object Kind | Primary Owner | Secondary Owner | Viewers | Converters | Importers |
|-------------|--------------|-----------------|---------|------------|-----------|
| **formula.symbolic** | **Plane** ★ → **Notes◎** | — | Space | — | Notes◎ |
| **relation.equality** | **Plane** ★ → **Notes◎** | — | — | — | — |
| **relation.inequality** | **Plane◎** ★ → **Notes◎** | — | — | — | — |

> ★ = 当前归属 / → = 未来迁移目标

**判定依据:**
- ★ 当前：Plane 通过 `PlaneExpressionService` 和 `PlaneInputCanonicalizer` 处理公式输入和表达式构建
- → 未来：Notes 是 formula.symbolic 的自然归属——公式笔记、整理、排版是 Notes 的核心场景
- 这是一个 **所有权转移** 案例：当前 Plane 占有了本应属于 Notes 的能力，因为 Notes 尚未开发

### 2.7 数据集合对象

| Object Kind | Primary Owner | Secondary Owner | Viewers | Converters | Importers |
|-------------|--------------|-----------------|---------|------------|-----------|
| **set.point2d** | **Data◎** | Plane (View only) | Space | Data (→table) | Plane, Space, Data◎ |
| **set.point3d** | **Data◎** | — | Space, Modeling | — | Data◎, Space |
| **table.data** | **Data◎** | — | — | Data (→set.point2d) | Data◎ |
| **table.function** | **Data◎** | Plane (View only) | — | Plane (→curve), Data◎ (→curve) | Data◎ |

**判定依据:**
- Data calculator 当前是占位，未实现任何能力
- Plane 通过 View 可见 set.point2d（scatter plot）和 table.function（表格叠加）
- 未来 Data 成为 table/set 的独家 Primary Owner

### 2.8 音频对象

| Object Kind | Primary Owner | Secondary Owner | Viewers | Converters | Importers |
|-------------|--------------|-----------------|---------|------------|-----------|
| **wave.audio** | **Music◎** | — | — | — | — |

**判定依据:**
- wave.audio 是 Music 的核心对象类型
- 依赖 `EMathicaSamplingCore` 的高密度采样
- 无其他 Calculator 的合理参与路径

### 2.9 文本与媒体对象

| Object Kind | Primary Owner | Secondary Owner | Viewers | Converters | Importers |
|-------------|--------------|-----------------|---------|------------|-----------|
| **text.block** | **Notes◎** | — | Plane, Space, Data, Music, Modeling | — | Notes◎ |
| **image.asset** | **Notes◎** | — | Plane, Space, Modeling | — | Plane, Space, Notes◎, Modeling |

**判定依据:**
- Notes 是 text.block 唯一 Creator/Editor
- 所有 Calculator 均可 Embed text.block（作为标注、说明）
- image.asset 跨所有 Calculator 可 View/Embed
- Notes 是 image.asset 的管理者（插入、替换、删除）

### 2.10 参数控制对象

| Object Kind | Primary Owner | Secondary Owner | Viewers | Converters | Importers |
|-------------|--------------|-----------------|---------|------------|-----------|
| **slider.parameter** | **Plane** | Data◎ | Space | — | — |
| **slider.group** | **Plane** | — | — | — | — |

**判定依据:**
- Plane 有完整 slider 实现（`PlaneToolIDs.slider` + `MathObjectType.parameter`）
- Data 未来可能使用 slider 作为数据筛选/范围控制参数
- slider.parameter 是跨域通用对象类型，不应严格绑定 Plane

### 2.11 构造关系对象

| Object Kind | Primary Owner | Secondary Owner | Viewers | Converters | Importers |
|-------------|--------------|-----------------|---------|------------|-----------|
| **construction.midpoint** | **Plane** | — | — | — | — |
| **construction.parallel** | **Plane** | — | — | — | — |
| **construction.perpendicular** | **Plane** | — | — | — | — |
| **construction.intersection** | **Plane** | Space◎ (3D intersection) | — | — | — |

**判定依据:**
- 构造关系对象是 Plane 几何工具链的核心（11 种 `PlaneConstructionMode`）
- Space 的 intersection 规划为 3D 线面/面面相交
- 构造关系对象是几何能力，不是计算器特定的

### 2.12 插件自定义对象

| Object Kind | Primary Owner | Secondary Owner | Viewers | Converters | Importers |
|-------------|--------------|-----------------|---------|------------|-----------|
| **plugin.customObject** | **Plugin System◎** | — | — | — | — |

**判定依据:**
- 不归属任何 Calculator
- 由 Plugin System 管理生命周期
- 这是 P4 Inventory-Only 的 PluginKit 规划

---

## 3. 所有权冲突分析

### 3.1 point.2d 的多 Calculator 编辑冲突

```
point.2d
  Primary Owner: Plane
  Viewers: Space, Data, Notes, Modeling
  Converters: Plane (T→3d), Space (T→3d via Z-edit)
```

**冲突场景:**
- Plane 编辑 point.2d 的 (x,y) 坐标
- Space 编辑 point.2d 的 Z 坐标 → 触发 `point.2d → point.3d` materialize conversion
- Data 以 scatter plot 方式查看 point.2d

**风险:** 如果 Space 编辑 point.2d 的 Z 坐标时，Plane 同时修改 (x,y)，可能导致 race condition 在 trans.json 中记录冲突。

**缓解:** Unified EMathicaDocument 的 `DocumentCommand` 队列序列化执行；materialize conversion 是原子操作。

### 3.2 formula.symbolic 的所有权转移

```
formula.symbolic
  当前 Primary Owner: Plane (通过 PlaneExpressionService)
  未来 Primary Owner: Notes
  当前 Secondary Owner: 无
  冲突: Plane 作为 Curves 的 Calculator 不应是公式的 Primary Owner
```

**冲突原因:**
- 当前架构中，唯一可处理 LaTeX 表达式输入的入口在 Plane
- `PlaneExpressionService.buildExpression()` → `AlgebraCore.analyzePlaneLatex()` 是唯一的表达式解析路径
- 这导致所有 `MathExpression` 创建都必须经过 Plane 的解析逻辑

**解法:**
- 将 `AlgebraCore.analyzePlaneLatex()` 重命名为 `AlgebraCore.parseLatex()`（通用化）
- 将 `MathExpression` 解析从 Plane 专属服务提升为 `EMathicaMathCore` 的通用能力
- Notes 调用同一解析能力，但提供不同的 UI 交互（无坐标系，纯文本/公式排版）

### 3.3 curve.explicit2d 的多 Calculator 创建冲突

```
curve.explicit2d
  Primary Owner: Plane
  Secondary Owner: Data◎ (table→curve)
  Converters: Plane (→table, →wave)
```

**冲突场景:**
- Plane 通过函数表达式创建 curve.explicit2d
- Data 通过 table.function→curve 回归/插值创建 curve.explicit2d
- 两个 calculator 创建的 curve 在 `createdBy` 字段上不同，但 kind 相同

**风险:** `createdBy` 字段的设计需要在 P1 设计冻结中确定：
- 方案 A: `createdBy` 是创建时 Calculator 的不可变记录
- 方案 B: `createdBy` 可随对象在不同 Calculator 之间转移而更新

**推荐:** 方案 A — `createdBy` 为不可变的历史记录；`preferredViews` 和 `enabledCalculators` 控制当前访问。

### 3.4 构造关系对象是否应归属 Calculator

```
construction.intersection
  Plane: 2D line-circle intersection, line-line intersection
  Space◎: 3D plane-line intersection, plane-plane intersection
```

**冲突:** 同一个 `construction.intersection` kind 在不同 Calculator 中含义不同。

**解法:**
- 方案 A: 拆分为 `construction.intersection2d` 和 `construction.intersection3d`
- 方案 B: 保留统一 kind，通过 `GeometryDefinition` 中的 `GeometryKind` 区分维度
- 方案 C: 不将 construction 拆分为独立 object kind，仅作为 `geometryDependency` 记录

**推荐:** 方案 B — 保留统一 kind，在 `GeometryDefinition` 中区分 2D/3D；因为 intersection 的数学语义相同（集合求交），只是作用域不同。

---

## 4. 所有权统计

### 4.1 总览

| Calculator | Primary Owner 数 | Secondary Owner 数 | Viewer | 角色总结 |
|-----------|-----------------|-------------------|--------|----------|
| **Plane** | 13 (4★待转移) | 2 (Data table→curve, Data slider) | 0 | 2D 几何+曲线 的唯一主力 |
| **Space** | 5 (1★类型泄露) | — | 0 | 3D 几何的唯一拥有者 |
| **Data◎** | 4 | 3 | 0 | 数据集合的未来独占 |
| **Music◎** | 1 | — | 0 | 音频独占 |
| **Notes◎** | 4 (含接收 3★转移) | — | 0 | 文本+公式的未来独占 |
| **Modeling◎** | 2 | 4 (3D几何Secondary) | 0 | 曲面+高级3D的未来独占 |
| **Plugin System◎** | 1 | — | 0 | 插件对象独占 |

### 4.2 当前 vs 未来所有权变化

```
当前架构:
  Plane: ★★★★★★★★★★★★★★ (14 kinds, 含 4 个未来应转移的)
  Space: ★★★★ (4 kinds, 1 个类型泄露)
  Data/Music/Notes/Modeling: 0 kinds

目标架构 (P1 设计冻结后):
  Plane: ★★★★★★★★★ (9 kinds: 2D几何 + 曲线 + 圆锥曲线 + 构造关系)
  Space: ★★★★ (4 kinds: 3D几何)
  Data: ★★★★ (4 kinds: 数据集合)
  Notes: ★★★★ (4 kinds: 公式 + 文本 + 媒体)
  Music: ★ (1 kind: 音频)
  Modeling: ★★★ (3 kinds: 曲面 + 3D几何Secondary + 构造关系3D)
```

---

## 5. 设计建议

### 5.1 `createdBy` 是不可变的

对象的 `createdBy: CalculatorID` 应记录创建历史，不应因后续转换而改变。理由：
- 审计追溯：知道哪个 Calculator 最初创建了该对象
- 转换记录：trans.json 记录后续变化，不覆盖创建记录
- 版本迁移兼容性：旧文档中的对象保留原始 `createdBy`

### 5.2 `enabledCalculators` 决定可见性

Unified EMathicaDocument 中：
- `enabledCalculators: [CalculatorID]` 控制哪些 Calculator 可以访问该文档
- 例如：包含 point.3d 的文档可启用 Space，但 Notes 仍可访问（因为 text.block 属于 Notes 但可 Embedded）

### 5.3 避免多重 Primary Owner

如 `formula.symbolic` 的案例所示，一个 kind 同时被两个 Calculator 作为 Primary Owner 会导致：
- 编辑冲突
- `createdBy` 歧义
- 能力注册表中归属不清

因此 P1 设计冻结应明确：**每个 Object Kind 在稳定状态下有且仅有一个 Primary Owner**。

### 5.4 Secondary Owner 限定场景

| Secondary Owner | 限定条件 |
|-----------------|---------|
| Data (curve) | 仅通过 `table.function → curve` 转换成为 Secondary；不能直接创建 curve |
| Data (slider) | 仅作为数据筛选参数使用；不能创建几何参数组 |
| Plane (text.block) | 仅 Embed 使用；不能编辑文本内容 |
| Plane (image.asset) | 仅 Embed 使用；不能管理图片资源 |

---

## 6. 与 Capability Registry 的对应

| 所有权概念 | Capability Registry 对应 |
|-----------|------------------------|
| Primary Owner | `object.kind.define` capability 的 calculator 归属 |
| Secondary Owner | `object.kind.edit` capability 的 calculator 归属 |
| Viewer | `geometry.present.*` + `graph.render.*` capability 的 consumer |
| Converter | `object.convert.*.to*` capability 的 calculator 归属 |
| Ownership Conflict | 同一 capability 被多个 calculator 注册时的优先级规则 |
