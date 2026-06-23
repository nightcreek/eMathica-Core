# Document Object Kind Proposal

> **日期:** 2026-06-16
> **原则:** Document 内部对象使用 object-first kind，calculator 是 view/interaction adapter

---

## 1. Core Principle

**Document 内部对象的主类型由"它是什么数学实体"决定，不由"它在哪个计算器中被创建"决定。**

| ❌ Wrong (calculator-first) | ✅ Right (object-first) |
|---------------------------|-----------------------|
| `plane.point` | `point.2d` |
| `plane.segment` | `segment.2d` |
| `space.point3D` | `point.3d` |
| `music.wave` | `wave.audio` |
| `data.table` | `table.data` |

---

## 2. Why Object-First Kind

### 2.1 跨计算器使用

一个 `point.2d` 对象：
- 可以在 Plane 中显示为坐标点
- 可以在 Space 中导入为 z=0 的点
- 可以在 Data 中作为散点图的点
- 可以在 Modeling 中作为拟合数据点

如果对象类型是 `plane.point`，Space/Data/Modeling 必须知道 Plane 的存在才能使用这个对象。这违反了依赖反转原则。

### 2.2 对象所有权清晰

```
point.2d  ← createdBy: "plane" | preferredViews: ["plane.graph"] | enabledCalculators: ["plane", "space", "data"]
```

- `createdBy`: 记录创建此对象的计算器（元数据，不影响行为）
- `preferredViews`: 默认打开时的推荐视图
- `enabledCalculators`: 允许哪些计算器使用此对象

### 2.3 类型系统稳定性

Object-first kind 来自于数学概念，数学概念稳定。Calculator-first kind 来自于 App 功能设计，App 功能会变化。

---

## 3. Recommended Object Kind Hierarchy

```
object (抽象根)
├── point.2d                    ← 2D 点
├── point.3d                    ← 3D 点
│
├── segment.2d                  ← 2D 线段
├── segment.3d                  ← 3D 线段
│
├── line.2d                     ← 2D 直线
├── line.3d                     ← 3D 直线
│
├── ray.2d                      ← 2D 射线
│
├── circle.2d                   ← 2D 圆
├── arc.2d                      ← 2D 圆弧
│
├── plane.3d                    ← 3D 平面
│
├── curve.explicit2d            ← 2D 显式函数 y=f(x)
├── curve.explicitX2d           ← 2D 显式函数 x=f(y)
├── curve.implicit2d            ← 2D 隐式曲线 f(x,y)=0
├── curve.parametric2d          ← 2D 参数曲线 (x(t),y(t))
├── curve.polar2d               ← 2D 极坐标曲线 r(θ)
├── curve.parametric3d          ← 3D 参数曲线 (x(t),y(t),z(t))
│
├── surface.explicit3d          ← 3D 显式曲面 z=f(x,y)
├── surface.parametric3d        ← 3D 参数曲面
│
├── conic.ellipse2d             ← 椭圆
├── conic.parabola2d            ← 抛物线
├── conic.hyperbola2d           ← 双曲线
│
├── formula.symbolic            ← 符号表达式（非曲线）
├── relation.equality           ← 等式
├── relation.inequality         ← 不等式
│
├── set.point2d                 ← 2D 点集
├── set.point3d                 ← 3D 点集
│
├── table.data                  ← 数据表
├── table.function              ← 函数值表
│
├── wave.audio                  ← 音频波形
│
├── text.block                  ← 文本块（注释/标签）
├── image.asset                 ← 图片资源
│
├── slider.parameter            ← 参数滑块
├── slider.group                ← 参数组
│
├── construction.midpoint       ← 中点构造
├── construction.parallel       ← 平行线构造
├── construction.perpendicular  ← 垂线构造
├── construction.intersection   ← 交点构造
│
└── plugin.customObject         ← 插件自定义对象
```

### Mapping: Current MathObjectType → Proposed Object Kind

| Current MathObjectType | Proposed Object Kind |
|----------------------|---------------------|
| `.function` | `curve.explicit2d` (most common) / `curve.parametric2d` / etc. — determined by classifier |
| `.point` | `point.2d` |
| `.circle` | `circle.2d` |
| `.segment` | `segment.2d` |
| `.line` | `line.2d` |
| `.ray` | `ray.2d` |
| `.parameter` | `slider.parameter` |
| `.parameterGroup` | `slider.group` |
| `.arc` | `arc.2d` |

Note: Current `MathObjectType` is a flat enum. The proposed system is a hierarchical namespace. Migration needs to preserve backward compatibility (e.g. `MathObjectType.function.rawValue` → `"function"` should still decode from old documents).

---

## 4. Calculator Metadata Fields

The following fields on `MathObject` (or `EMathicaDocument`) should handle calculator-relation:

```swift
struct MathObject {
    let id: UUID
    var kind: ObjectKind                    // e.g., "point.2d"
    var name: String
    var createdBy: CalculatorID             // "plane", "space", "modeling"...
    var preferredViews: [ViewDescriptor]    // ["plane.graph", "space.3d"]
    var enabledCalculators: [CalculatorID]  // ["plane", "space", "data"]
    // ...
}
```

```swift
struct EMathicaDocument {
    var primaryCalculator: CalculatorID     // 默认打开时使用的计算器
    var enabledCalculators: [CalculatorID]  // 此文档允许的计算器列表
    var objects: [MathObject]
    // ...
}
```

---

## 5. Why NOT `plane.point` / `space.point3d`

### 5.1 Code Smell: Type Enumeration Explosion

```
// Calculator-first (bad):
case planePoint, planeSegment, planeLine, planeRay, planeCircle, planeArc,
     spacePoint3D, spaceSegment3D, spaceLine3D, spacePlane3D,
     musicWave, musicNote,
     dataTable, dataBar, dataScatter,
     modelingFit, modelingRegression,
     notesText, notesImage
// 20+ types, many semantically identical

// Object-first (good):
case point.2d, point.3d,
     segment.2d, segment.3d,
     line.2d, line.3d,
     // ...
// Types are mathematical, not UI-related
```

### 5.2 Dependency Inversion

```
calculator-first:
  SpaceCalculator → knows about "space.point3D"
  DataCalculator → needs "data.scatterPlot" from points
  DataCalculator → must import SpaceCalculator's type system! ❌

object-first:
  SpaceCalculator → adapts "point.3d" → "space.camera + wireframe"
  DataCalculator → adapts "point.2d" → "scatter plot"
  No cross-calculator dependency needed ✅
```

### 5.3 Unified Conversion Pipeline

```
point.2d (kind: "point.2d")
  ↓ SpaceCalculator imports it
  ↓ User edits z coordinate
  ↓ materialize conversion
point.3d (kind: "point.3d")
  ↓ records in .emathica/trans.json

With calculator-first:
  "plane.point" → ??? → "space.point3D" requires explicit conversion mapping for every pair
```

---

## 6. Relationship with Unified EMathicaDocument

A single `EMathicaDocument` can hold objects of any kind. The `primaryCalculator` and `enabledCalculators` fields determine which calculators can open/view the document.

```
Document A:
  primaryCalculator: "plane"
  enabledCalculators: ["plane", "space"]
  objects: [point.2d, curve.explicit2d, circle.2d]
  → Opens in Plane by default. Space can import/view the 2D objects.

Document B:
  primaryCalculator: "space"
  enabledCalculators: ["space"]
  objects: [point.3d, segment.3d, plane.3d, curve.parametric3d]
  → Opens in Space only.

Document C:
  primaryCalculator: "plane"
  enabledCalculators: ["plane", "music", "data"]
  objects: [curve.explicit2d, curve.parametric2d]
  → Plane opens it. Music can play it as wave. Data can sample it to table.
```

This is the power of object-first kind: the same curve object serves Plane calculus, Music audio, and Data tabulation **without changing its identity**.
