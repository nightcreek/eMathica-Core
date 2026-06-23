# 产品设计文档

> 这些文档回答 **"eMathica 是什么产品"**,不是"怎么实现的"。
>
> 想了解架构（怎么做的）→ 读 `AI/Core/`。
> 想了解产品（做什么的）→ 读这里。

---

## 与 Core 文档的关系

| Core 文档 | 对应 ProductDesign 文档 | 区别 |
|-----------|----------------------|------|
| `Architecture.md` | `Calculators.md`、`PlaneDesign.md` | Architecture 讲四层分层和 Calculator 协议定义；ProductDesign 讲用户能用每个模块做什么 |
| `ObjectSystem.md` | `ObjectKinds.md` | ObjectSystem 讲 Object Header 字段和转换引擎；ObjectKinds 讲每种数学对象对用户的意义 |
| `Roadmap.md` | — | Roadmap 确定先后顺序，ProductDesign 确定功能范围 |

---

## 文档列表

| 文件 | 内容 |
|------|------|
| [Calculators.md](Calculators.md) | 6 个 Calculator 模块的产品定义：用户视角的功能、支持的对象类型、当前状态 |
| [ObjectKinds.md](ObjectKinds.md) | 38 种 ObjectKind 的产品定义：每种数学对象对用户意味着什么、在哪些 Calculator 中可用 |
| [PlaneDesign.md](PlaneDesign.md) | Plane Calculator 完整产品设计：定位、坐标系、对象类型、函数系统、列表、手绘拟合、区域填色、样式、动画、导出等长期方向 |

---

## 阅读顺序

```
Calculators.md   →   理解产品有哪些功能模块
    ↓
PlaneDesign.md   →   深入理解 Plane 的完整设计（对象、函数、列表、手绘、区域、样式、动画、导出）
    ↓
ObjectKinds.md   →   理解支持哪些数学对象类型
    ↓
(然后读 Core/Roadmap.md 了解当前进度)
```
