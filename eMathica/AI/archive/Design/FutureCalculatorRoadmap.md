# Future Calculator Roadmap

> **日期:** 2026-06-17
> **模式:** 只读架构审计
> **输入:** 全部 AI/Audits/ + AI/Design/ 文档 + 源码审计
> **原则:** MVP 定义依赖优先于功能列表，Calculator 只是 View/Interaction Adapter

---

## 1. 总览

| Calculator | 当前成熟度 | 下一步 | 优先级 | 阻塞项 |
|-----------|-----------|--------|--------|--------|
| **Plane** | ●●●●● 高 (v1.0 ready) | 保持 + 逐渐解耦 | 持续 | P3 Normalize (废弃Legacy采样) |
| **Space** | ●●○○○ 低 | MVP (完整 3D 交互) | P2 后期 | P1 ObjectKind 冻结 |
| **Data** | ●○○○○ 极低 | MVP (表格 + 统计) | P4 | P2 MathCore Split + P3 采样 |
| **Music** | ●○○○○ 极低 | MVP (函数→音频) | P4 | P2 SamplingCore + P3 采样 |
| **Notes** | ●○○○○ 极低 | MVP (公式编辑 + 笔记) | P4 | P3 FormulaRender + MathInput |
| **Modeling** | ●○○○○ 极低 | MVP (3D 曲面) | P4 后期 | P2 Space MVP + GeometryCore |

---

## 2. Plane — 持续演进，不重构

### 2.1 未来保留的能力

Plane 是当前唯一主力 Calculator，v1.0 的成败绑定在 Plane 上。不应在此阶段进行大规模重构。

| 保留能力 | 理由 |
|---------|------|
| 2D 几何构造 (11 种 ConstructionMode) | Plane 核心交互 |
| 2D 函数曲线 (explicit/parametric/polar/implicit) | Plane 核心场景 |
| 2D Canvas 渲染 (坐标系、网格、轴、对象) | Plane 独有视图 |
| 滑块参数系统 (slider.parameter, slider.group) | Plane 核心交互 |
| 圆锥曲线分类 (conic.*) | Plane 场景 |
| 交点/中点/平行/垂直 构造工具 | Plane 独有工具 |

### 2.2 未来应解耦的能力

| 能力 | 当前在 Plane | 应迁移至 | 时机 |
|------|------------|---------|------|
| LaTeX 表达式解析 `AlgebraCore.analyzePlaneLatex()` | Plane 通过 `PlaneExpressionService` 调用 | 重命名为 `AlgebraCore.parseLatex()`，方法名去 Plane 前缀 | P2 |
| 2D 采样 `PlaneLegacyExplicitSampling` | Plane/Services/ | 废弃，统一使用 `ExplicitFunctionSampler2D` | P3 |
| Draft 预览 `PlaneDraftPreviewService` | Plane/Services/ | `PlanePreviewAdapter : DraftPreviewService` | P3 |
| 命中测试 `PlaneHitTestService` | Plane/Services/ | `PlaneHitTestAdapter : HitTestService` | P4 |
| 几何解析 `PlaneGeometryResolver` | Plane/Services/ | `PlaneGeometryAdapter : GeometryService` | P4 |
| 对象命名 `PlaneObjectNamingService` | Plane/Services/ | 保留在 Plane 但作为 `ObjectNamingService` 协议的 Plane 实现 | P4 |
| 语义意图适配 `PlaneSemanticIntentAdapter` | Plane/Services/ | 保留在 Plane，但协议在 MathCore | P4 |

### 2.3 Plane 依赖的 Object Kinds

```
Primary Owner (Create/Edit):
  point.2d, segment.2d, line.2d, ray.2d, circle.2d, arc.2d
  curve.explicit2d, curve.explicitX2d◎, curve.implicit2d◎, curve.parametric2d◎, curve.polar2d◎
  conic.ellipse2d◎, conic.parabola2d◎, conic.hyperbola2d◎
  slider.parameter, slider.group
  construction.midpoint, construction.parallel, construction.perpendicular, construction.intersection
  formula.symbolic ★ (未来转移至 Notes)

Viewer:
  point.3d (投影), segment.3d (投影), line.3d (投影)
  curve.parametric3d (投影)
  set.point2d (scatter plot)
  table.function (叠加到坐标系)
  text.block (Embed 标注), image.asset (Embed 参考)

Converter:
  point.2d → point.3d (Space 编辑 Z 触发)
  point.3d → point.2d (降至 2D 查看)
  curve.explicit2d → table.function (导出数据)
  curve.explicit2d → wave.audio (导出音频)
```

### 2.4 Plane 依赖的 Capabilities (CapabilityRegistry)

```
已实现:
  - graph.classify.explicitY, graph.classify.implicit2D, graph.classify.parametric2D,
    graph.classify.polar2D, graph.classify.conic, graph.classify.piecewise
  - graph.sample.explicit2D, graph.sample.parametric2D, graph.sample.polar2D
  - cas.differentiate, cas.solve.equation
  - expr.parse.latex, expr.format.latex, expr.semantic.lower
  - geometry.point.2d, geometry.segment.2d, geometry.line.2d, geometry.ray.2d,
    geometry.circle.2d, geometry.arc.2d, geometry.intersection, geometry.distance,
    geometry.midpoint, geometry.parallel, geometry.perpendicular
  - preview.draft.generate
  - object.naming.auto (PlaneObjectNamingService)

待实现:
  - graph.sample.explicitX2D, graph.sample.implicit2D
  - geometry.present.point2d (已在 PlaneObjectRendererView 中，待归类)
  - preview.project.render (依赖 project→draft preview 统一)
```

### 2.5 Plane 依赖的 Future Packages

```
当前:
  EMathicaMathCore (CAS + Graph + Sampling + Geometry + Semantic)
  EMathicaDocumentKit
  EMathicaWorkspaceKit
  EMathicaThemeKit (仅在 PlaneCommandHandler 中使用)

未来:
  EMathicaCASCore          (替代 MathCore.CASCore/)
  EMathicaGraphIntentCore  (替代 MathCore.GraphCore/)
  EMathicaSamplingCore     (替代 MathCore.SamplingCore/)
  EMathicaGeometryCore     (替代 MathCore 几何部分)
  EMathicaPreviewKit       (替代 PlaneDraftPreviewService + ProjectPreviewRenderer)
```

---

## 3. Space — MVP 定义

### 3.1 MVP 范围

```
Space Calculator v1.0 MVP
  ├── 完整的 3D 几何创建 (point.3d, segment.3d, line.3d, plane.3d)
  ├── 3D 交互 (orbit camera, pan, zoom)
  ├── Wireframe 渲染 (基本几何)
  ├── 3D 几何依赖 (geometryDependencyService 返回非 nil)
  ├── 3D 命中测试 (SpaceHitTestService 完整实现)
  └── point.2d ↔ point.3d Materialize Conversion
```

### 3.2 不在 MVP 范围

```
❌ 曲面渲染 (surface.*) → 属于 Modeling MVP
❌ 3D 函数曲线 (curve.parametric3d) → 属于 Modeling MVP 后期
❌ 纹理/光照渲染 → 属于 Modeling MVP 后期
❌ 3D intersection (plane-plane, plane-line) → 后期增强
```

### 3.3 Space 依赖的 Object Kinds

```
Primary Owner:
  point.3d, segment.3d, line.3d, plane.3d

Viewer:
  point.2d, segment.2d, line.2d, ray.2d, circle.2d, arc.2d (投影到工作平面)
  curve.explicit2d, curve.parametric2d (投影)
  text.block (Embed 3D 标注)

Converter:
  point.2d → point.3d (Z 编辑触发)
  point.3d → point.2d (降至 2D)
```

### 3.4 Space 依赖的 Capabilities

```
已实现:
  - geometry.point3d, geometry.segment3d, geometry.line3d, geometry.plane3d (基础创建)
  - SpaceGeometryResolver (3D 射线投射, 工作平面相交)
  - SpaceHitTestService (基本命中测试)
  - SpaceWireframeRenderer (线框渲染)
  - SpaceCameraState (轨道相机)

待实现 (P2):
  - geometry.dependency.3d (GeometryDependencyService 3D 实现)
  - graph.classify.parametric3D (3D 曲线分类)
  - graph.sample.parametric3D (3D 曲线采样)
  - object.convert.point2d.toPoint3d (2D→3D 转换)
  - object.convert.point3d.toPoint2d (3D→2D 转换)
  - geometry.intersection.3d (3D 几何相交)

待实现 (P4):
  - geometry.present.surface (曲面渲染)
  - graph.sample.surface (曲面采样)
```

### 3.5 Space 依赖的 Future Packages

```
当前:
  EMathicaMathCore (SpaceMath3D: WorldPoint3D, Vector3D, SpaceCameraState)
  EMathicaDocumentKit
  EMathicaWorkspaceKit

未来:
  EMathicaGeometryCore  (3D 几何能力)
  EMathicaGraphIntentCore (3D 曲线分类)
  EMathicaSamplingCore (3D 采样)
  EMathicaPreviewKit (3D 预览)
```

---

## 4. Data — MVP 定义

### 4.1 MVP 范围

```
Data Calculator v1.0 MVP
  ├── CSV/JSON 数据导入 (I → table.data)
  ├── 表格视图 (table.data Create/Edit/View)
  ├── 散点图视图 (set.point2d View)
  ├── 基本统计 (均值、中位数、标准差、回归)
  ├── table.data → set.point2d 转换
  ├── curve.explicit2d → table.function 转换
  └── 表格导出 (X → CSV)
```

### 4.2 不在 MVP 范围

```
❌ 高级统计 (假设检验、置信区间)
❌ 机器学习模型
❌ 多维数据可视化 (3D scatter)
❌ 实时数据流
❌ 数据库连接
```

### 4.3 Data 依赖的 Object Kinds

```
Primary Owner:
  table.data, table.function, set.point2d, set.point3d

Viewer:
  point.2d (叠加到散点图)
  curve.explicit2d (叠加到坐标系)
  slider.parameter (数据筛选参数)
  text.block (Embed 标题/标注)

Converter:
  table.data → set.point2d (列提取)
  set.point2d → table.data (点集→表格)
  table.function → curve.explicit2d (回归/插值)
  curve.explicit2d → table.function (函数采样)
```

### 4.4 Data 依赖的 Capabilities

```
依赖:
  - graph.sample.explicit2D (函数采样 → 表格)
  - graph.sample.parametric2D (参数曲线采样 → 表格)
  - cas.statistics (统计计算，待实现)
  - document.object.import.csv (CSV 导入，待实现)
  - document.export.csv (CSV 导出，待实现)
  - object.convert.curve.toTable
  - object.convert.table.toPointSet
  - object.convert.pointSet.toTable
  - style.color.token (图表颜色)
```

### 4.5 Data 依赖的 Future Packages

```
EMathicaCASCore      (统计函数: mean, median, stddev, regression)
EMathicaSamplingCore (高密度函数采样)
EMathicaGeometryCore  (散点图命中测试)
EMathicaPreviewKit    (表格预览渲染)
```

---

## 5. Music — MVP 定义

### 5.1 MVP 范围

```
Music Calculator v1.0 MVP
  ├── curve.explicit2d → wave.audio 转换
  ├── 音频波形可视化 (wave.audio View)
  ├── 基本播放控制 (Play/Pause/Stop)
  ├── 音频导出 (X → WAV/MP3)
  └── 频率/振幅参数调节
```

### 5.2 不在 MVP 范围

```
❌ 多轨道混音
❌ 乐器合成器
❌ MIDI 支持
❌ 实时音频效果器
❌ 乐谱渲染
```

### 5.3 Music 依赖的 Object Kinds

```
Primary Owner:
  wave.audio

Viewer:
  curve.explicit2d (作为音频源查看)
  slider.parameter (频率/振幅参数)

Converter:
  curve.explicit2d → wave.audio (函数采样为音频)
  (无反向转换 — 不可逆)
```

### 5.4 Music 依赖的 Capabilities

```
依赖:
  - graph.sample.explicit2D (高密度采样: 44100Hz)
  - object.convert.curve.toWave (函数→音频转换)
  - audio.playback (音频播放，待实现)
  - audio.export.wav (WAV 导出，待实现)
  - style.color.token (波形颜色)

关键依赖说明:
  curve → wave 转换的核心是高密度采样。
  当前 `PlaneDraftPreviewService` 的采样密度是 700 points (视口级别)。
  Music 需要 44100 points/second (音频级别) — 相差约 63 倍。
  这要求 EMathicaSamplingCore 支持可变采样密度（不仅是 viewport-adaptive）。
```

### 5.5 Music 依赖的 Future Packages

```
EMathicaSamplingCore  (高密度函数采样，音频级别)
EMathicaCASCore       (可选: 傅里叶分析)
```

---

## 6. Notes — MVP 定义

### 6.1 MVP 范围

```
Notes Calculator v1.0 MVP
  ├── formula.symbolic Create/Edit (LaTeX 编辑)
  ├── text.block Create/Edit (富文本)
  ├── image.asset Import/Embed (图片插入)
  ├── LaTeX 公式渲染 (formula.render.latex)
  ├── MathInput 键盘集成
  ├── formula.symbolic ↔ text.block 转换
  └── 笔记导出 (X → PDF/Markdown)
```

### 6.2 不在 MVP 范围

```
❌ 手写公式识别
❌ 协作编辑
❌ Markdown 编辑器
❌ 代码块 (代码着色)
❌ 表格 (属于 Data Calculator)
```

### 6.3 Notes 依赖的 Object Kinds

```
Primary Owner:
  formula.symbolic (从 Plane 接收所有权转移)
  text.block, image.asset
  relation.equality, relation.inequality

Viewer:
  所有其他 kind (Embed 显示)

Embed:
  text.block (嵌入到所有 Calculator)
  image.asset (嵌入到所有 Calculator)
  formula.symbolic (嵌入到 Plane 作为公式来源)
```

### 6.4 Notes 依赖的 Capabilities

```
依赖:
  - formula.render.latex
  - formula.render.inline
  - formula.render.label
  - formula.render.thumbnail
  - formula.render.fallback
  - expr.parse.latex
  - expr.format.latex
  - expr.serialize.json
  - input.keyboard.layout (MathInput 键盘)
  - input.session.edit (公式输入会话)
  - object.convert.text.toFormula
  - object.convert.formula.toText
  - style.math.define
  - style.color.token

关键依赖说明:
  formula.render.* 当前分散在三处:
    1. EMathicaFormulaRenderer (独立 Swift Package，LaTeX→UIImage)
    2. eMathicaFormulaRenderingService (App Target，SwiftUI 视图层封装)
    3. EMathicaMathRenderer (App Target，公式标签渲染)
  Notes 依赖的是统一的 formula.render 能力入口，不是其中某个具体实现。
  P3 Normalize 阶段必须统一这三个入口。
```

### 6.5 Notes 依赖的 Future Packages

```
EMathicaFormulaRenderKit (统一公式渲染)
EMathicaMathInputKit     (公式键盘输入)
```

---

## 7. Modeling — MVP 定义

### 7.1 MVP 范围

```
Modeling Calculator v1.0 MVP
  ├── surface.explicit3d Create/Edit (z=f(x,y) 曲面)
  ├── surface.parametric3d Create/Edit (参数曲面)
  ├── 3D 曲面渲染 (面片/线框)
  ├── 轨道相机控制 (继承 Space 的相机模型)
  ├── surface.explicit3d → curve.implicit2d (等高线提取)
  ├── 3D 几何依赖 (geometryDependencyService 3D)
  └── 基本导出 (OBJ/STL)
```

### 7.2 不在 MVP 范围

```
❌ NURBS/Bezier 曲面编辑
❌ 布尔运算
❌ 纹理映射
❌ 光线追踪渲染
❌ 动画
```

### 7.3 Modeling 依赖的 Object Kinds

```
Primary Owner:
  surface.explicit3d, surface.parametric3d

Secondary Owner:
  point.3d, segment.3d, line.3d, plane.3d (3D 几何控制点编辑)
  curve.parametric3d (3D 空间曲线，作为曲面边界)

Viewer:
  curve.explicit2d (投影)
  text.block (3D 标注)

Converter:
  surface.* → curve.implicit2d (等高线)
```

### 7.4 Modeling 依赖的 Capabilities

```
依赖:
  - graph.classify.parametric3D
  - graph.classify.explicit3D
  - graph.sample.parametric3D
  - graph.sample.surface (曲面采样，待实现)
  - geometry.present.surface (曲面渲染)
  - geometry.intersection.3d (线/面相交)
  - geometry.dependency.3d
  - object.convert.surface.toContour (等高线)
  - document.export.obj (OBJ 导出，待实现)
  - document.export.stl (STL 导出，待实现)
```

### 7.5 Modeling 依赖的 Future Packages

```
EMathicaGeometryCore   (3D 几何能力)
EMathicaGraphIntentCore (3D 分类)
EMathicaSamplingCore   (曲面采样)
EMathicaPreviewKit     (3D 预览)
EMathicaExportKit      (OBJ/STL 导出)
```

---

## 8. Calculator 依赖关系图

```
                      EMathicaMathCore
                     (CAS + Graph + Sampling + Geometry + Semantic)
                            │
          ┌─────────────────┼─────────────────┐
          │                 │                 │
     EMathicaCASCore  EMathicaGraphIntentCore  EMathicaSamplingCore
          │                 │                 │
          └─────────────────┼─────────────────┘
                            │
              ┌─────────────┼─────────────┐
              │             │             │
       EMathicaDocumentKit  │   EMathicaWorkspaceKit
              │             │             │
              └─────────────┼─────────────┘
                            │
    ┌───────────┬───────────┼───────────┬───────────┬───────────┐
    │           │           │           │           │           │
  Plane       Space       Data        Music       Notes     Modeling
  (67 files)  (9 files)   (1 file)    (1 file)    (1 file)   (1 file)
    │           │           │           │           │           │
    │    EMathicaGeometryCore  │      EMathicaSamplingCore      │
    │           │           │           │           │           │
    └───────────┴───────────┴───────────┴───────────┴───────────┘
                            │
              EMathicaFormulaRenderKit
              EMathicaMathInputKit
              EMathicaPreviewKit
```

---

## 9. 开发依赖顺序

```
Phase 1 (P0): DocumentSystem Dedup
  → 不影响 Calculator 开发

Phase 2 (P1): Design Freeze
  → ObjectKind 规范 + Unified Document 结构
  → 所有 Calculator 的 Object Kind 引用依据

Phase 3 (P2): MathCore Split
  → CASCore + GraphIntentCore + SamplingCore 独立
  → point.2d ↔ point.3d Materialize Conversion
  → Space Calculator 可使用独立 Package 的 3D 能力

Phase 4 (P3): Normalize
  → FormulaRenderKit 统一渲染入口
  → PreviewKit 消除 Draft/Project Preview 重复
  → MathInputKit 正式采用
  → Notes Calculator 可开始开发

Phase 5 (P4): Future Calculators
  → Data Calculator MVP (依赖 SamplingCore + CASCore)
  → Music Calculator MVP (依赖 SamplingCore 高密度采样)
  → Notes Calculator MVP (依赖 FormulaRenderKit + MathInputKit)
  → Modeling Calculator MVP (依赖 Space MVP + GeometryCore)
```

### 关键路径

```
关键路径 (影响最多 Calculator 的开发):
  P1 ObjectKind Freeze
    → P2 MathCore Split
      → P3 FormulaRender Normalize
        → Notes MVP
      → P3 Sampling Normalize
        → Data MVP, Music MVP
    → P2 Space MVP
      → Modeling MVP

非关键路径 (独立于其他 Calculator):
  P0 DocumentSystem Dedup (独立任务)
  P4 ExportKit, AnimationKit, AssetKit (不阻塞任何 Calculator)
  Plugin System (不阻塞任何 Calculator，但依赖所有 Calculator 成熟)
```

---

## 10. 当前阻塞项清单

| 阻塞项 | 影响范围 | 解除时机 | 替代方案 |
|--------|---------|---------|---------|
| Architecture Freeze (禁止修改 Package.swift) | P2 MathCore Split 完全阻塞 | v1.0+ | 无替代，等待解冻 |
| MathObjectType 无 3D 专属枚举 | Space 的类型泄露无法根除 | P1 ObjectKind 冻结 | 继续使用 `GeometryDefinition.kind` 区分 |
| DocumentSystem/GeometryDefinition 陈旧副本 | .arc 和其他新字段在使用不一致 | P0 Dedup 执行 | 确保所有代码引用 Package 版本 |
| PlaneLegacyExplicitSampling 未废弃 | curve→table 采样可能不正确 | P3 | 使用 `ExplicitFunctionSampler2D` |
| 无统一的 formula.render 入口 | Notes 依赖的公式渲染能力分散 | P3 | 等待 Normalize |
| 无 Curve → Wave 高密度采样 | Music MVP 阻塞 | P2 SamplingCore + P4 | 无替代 |
| 无 3D 曲面分类/采样 | Modeling MVP 阻塞 | P2 后 | 无替代 |
| trans.json 格式未定义 | 所有 Materialize Conversion 的历史记录无法实现 | P1 | 先实现内存转换，后补持久化 |
