# ObjectKind 产品定义

> 本文档从产品视角描述每种数学对象。
> 技术视角（Object Header 字段、转换引擎）见 `AI/Core/ObjectSystem.md`。

---

## 什么是 ObjectKind

ObjectKind 是 eMathica 中所有数学对象的**类型标识符**。每个对象（一个点、一条曲线、一个公式……）都有一个 ObjectKind。

格式：`域名.子类型`，例如 `point.2d` 表示 2D 点，`curve.explicit2d` 表示显式 2D 曲线 y=f(x)。

---

## ObjectKind 完整列表

### point（点）

| Kind | 用户术语 | 当前可用 |
|------|---------|:------:|
| `point.2d` | 平面上的点 | ✅ Plane |
| `point.3d` | 空间中的点 | ✅ Space |

### line（线）

| Kind | 用户术语 | 当前可用 |
|------|---------|:------:|
| `line.segment2d` | 线段 | ✅ Plane |
| `line.segment3d` | 空间线段 | ✅ Space |
| `line.ray2d` | 射线 | ✅ Plane |
| `line.infinite2d` | 直线 | ✅ Plane |
| `line.infinite3d` | 空间直线 | ✅ Space |

> 注：当前代码中线段和直线用 MathObjectType + GeometryDefinition.kind 组合表示,尚未迁移为 ObjectKind 字符串。

### curve（曲线）

| Kind | 用户术语 | 当前可用 |
|------|---------|:------:|
| `curve.explicit2d` | 显式曲线 y = f(x) | ✅ Plane |
| `curve.parametric2d` | 参数曲线 (x(t), y(t)) | ✅ Plane |
| `curve.implicit2d` | 隐式曲线 f(x,y) = 0 | ✅ Plane |
| `curve.polar2d` | 极坐标曲线 r = f(θ) | ❌ 计划中 |
| `curve.parametric3d` | 空间参数曲线 | ❌ 计划中 |

### surface（曲面）

| Kind | 用户术语 | 当前可用 |
|------|---------|:------:|
| `surface.explicit3d` | 显式曲面 z = f(x,y) | ✅ Space (plane3D) |
| `surface.parametric3d` | 参数曲面 | ❌ 计划中 |
| `surface.implicit3d` | 隐式曲面 f(x,y,z) = 0 | ❌ 计划中 |

### formula（公式）

| Kind | 用户术语 | 当前可用 |
|------|---------|:------:|
| `formula.algebraic` | 代数公式 | ✅ Plane (作为 .function) |
| `formula.differential` | 微分表达式 | ❌ 计划中 |
| `formula.integral` | 积分表达式 | ❌ 计划中 |
| `formula.recursive` | 递归定义 | ❌ 计划中 |

### relation（关系）

| Kind | 用户术语 | 当前可用 |
|------|---------|:------:|
| `relation.equation2d` | 2D 方程 | ✅ Plane |
| `relation.inequality2d` | 2D 不等式 | ❌ 计划中 |
| `relation.equation3d` | 3D 方程 | ❌ 计划中 |
| `relation.system` | 方程组 | ❌ 计划中 |

### table（表格）

| Kind | 用户术语 | 当前可用 |
|------|---------|:------:|
| `table.data` | 数据表 | ✅ Plane |
| `table.function` | 函数值表 | ❌ 计划中 |

### set（集合）

| Kind | 用户术语 | 当前可用 |
|------|---------|:------:|
| `set.pointSet2d` | 2D 点集 | ✅ Plane |
| `set.interval` | 区间 | ❌ 计划中 |
| `set.region2d` | 2D 区域 | ❌ 计划中 |

### wave（波形）

| Kind | 用户术语 | 当前可用 |
|------|---------|:------:|
| `wave.audio` | 音频波形 | ❌ 计划中 |
| `wave.visual` | 可视化波形 | ❌ 计划中 |

### text（文本）

| Kind | 用户术语 | 当前可用 |
|------|---------|:------:|
| `text.plain` | 纯文本 | ✅ Plane |
| `text.rich` | 富文本 | ❌ 计划中 |

### image（图像）

| Kind | 用户术语 | 当前可用 |
|------|---------|:------:|
| `image.bitmap` | 位图图像 | ✅ Plane |
| `image.vector` | 矢量图像 | ❌ 计划中 |

### slider（滑块）

| Kind | 用户术语 | 当前可用 |
|------|---------|:------:|
| `slider.continuous` | 连续滑块 | ✅ Plane |
| `slider.discrete` | 离散滑块 | ❌ 计划中 |

### construction（构造）

| Kind | 用户术语 | 当前可用 |
|------|---------|:------:|
| `construction.intersection` | 交点 | ✅ Plane |
| `construction.locus` | 轨迹 | ❌ 计划中 |

### plugin（插件）

| Kind | 用户术语 | 当前可用 |
|------|---------|:------:|
| `plugin.custom` | 自定义插件对象 | ❌ 计划中 |

---

## 对象之间的转换

用户可以将一种类型的对象转换为另一种。例如：

| 从 | 到 | 含义 | 可用性 |
|----|----|------|:------:|
| `point.2d` | `point.3d` | 将平面点嵌入空间（z=0） | ❌ 计划中 |
| `point.3d` | `point.2d` | 将空间点投影到平面（丢弃 z） | ❌ 计划中 |
| `curve.explicit2d` | `table.data` | 从函数采样生成数据表 | ❌ 计划中 |
| `table.data` | `curve.explicit2d` | 从数据表插值生成函数 | ❌ 计划中 |
| `table.data` | `set.pointSet2d` | 从表格提取 (x, y) 为点集 | ❌ 计划中 |
| `set.pointSet2d` | `table.data` | 将点集转为数据表 | ❌ 计划中 |
| `curve.explicit2d` | `wave.audio` | 将函数转为音频 | ❌ 计划中 |
| `surface.explicit3d` | `curve.implicit2d` | 将曲面投影为 2D 隐式曲线 | ❌ 计划中 |

---

## 与 Core/ObjectSystem.md 的关系

本文档描述 ObjectKind 对**用户**的意义。`Core/ObjectSystem.md` 描述 ObjectKind 的：
- 技术字段（Object Header: uuid, kind, createdAt, ...）
- 生命周期状态（Created → Active → Edited → ...）
- DependencyGraph（对象之间的依赖关系）
- Conversion Engine（转换的技术实现）
- trans.json（转换日志格式）
