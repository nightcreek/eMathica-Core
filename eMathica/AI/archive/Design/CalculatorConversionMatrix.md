# Calculator Conversion Matrix

> **日期:** 2026-06-17
> **模式:** 只读架构审计
> **输入:** ObjectConversionProposal.md, CalculatorCapabilityMatrix.md, PostCapabilityAuditArchitectureCorrectionPlan.md
> **原则:** Materialize Conversion, trans.json, 不可逆标注

---

## 1. 转换分类

| 状态 | 代码 | 含义 | 判定标准 |
|------|------|------|----------|
| **Implemented** | ✅ | 当前已实现 | 源码中有完整的 kind change + 数据迁移逻辑 |
| **Planned (P2)** | 📋 | 短期规划实施 | P2 优先级，point.2d ↔ point.3d |
| **Planned (P4)** | 📅 | 长期规划 | P4 优先级，依赖未开发的 Calculator |
| **Research** | 🔬 | 需要研究可行性 | 数学上合理但实现细节未明确 |
| **Not Recommended** | ❌ | 不推荐转换 | 语义不匹配、数据损失过大、不可逆 |
| **Forbidden** | 🚫 | 禁止转换 | 违反数学语义或安全边界 |

---

## 2. Materialize Conversion vs View Adaptation

在进行转换矩阵之前，必须区分两种跨 Calculator 的"看起来像转换"的行为：

```
View Adaptation (不改变 kind)
  例: Plane 以 scatter plot 方式查看 set.point2d
  → kind 保持 set.point2d
  → trans.json 不记录
  → 用户退出 Plane 后，对象仍是 set.point2d

Materialize Conversion (改变 kind)
  例: Space 编辑 point.2d 的 Z 坐标 → 对象变成 point.3d
  → kind 从 point.2d 变为 point.3d
  → trans.json 记录: {fromKind: "point.2d", toKind: "point.3d", triggeredBy: "space.edit.z"}
  → 所有 Calculator 看到的都是 point.3d
```

**判定规则:**
```
if user_edit_changes_mathematical_semantics:
    → materialize conversion
else:
    → view adaptation
```

---

## 3. 完整转换矩阵

### 3.1 点对象转换

| From → To | 状态 | Capability ID | 触发 Calculator | 可逆? | 数据损失 |
|-----------|------|---------------|-----------------|-------|---------|
| **point.2d → point.3d** | 📋 P2 | `object.convert.point2d.toPoint3d` | Space (编辑Z) | ✅ 可逆 (→point.2d) | Z=0 |
| **point.3d → point.2d** | 📋 P2 | `object.convert.point3d.toPoint2d` | Plane (降至2D) | ✅ 可逆 (→point.3d) | ⚠️ 丢失 Z 坐标 |
| **point.2d → set.point2d** | ❌ 不推荐 | — | — | — | 语义错误 (单点→集合) |
| **point.3d → set.point3d** | ❌ 不推荐 | — | — | — | 语义错误 |

### 3.2 曲线对象转换

| From → To | 状态 | Capability ID | 触发 Calculator | 可逆? | 数据损失 |
|-----------|------|---------------|-----------------|-------|---------|
| **curve.explicit2d → table.function** | 📅 P4 | `object.convert.curve.toTable` | Data (采样为表格) | ⚠️ 大致可逆 (插值回归) | ⚠️ 采样精度损失 |
| **curve.explicit2d → wave.audio** | 📅 P4 | `object.convert.curve.toWave` | Music (采样为音频) | 🚫 不可逆 | 🚫 音频无法恢复原函数 |
| **curve.parametric2d → table.function** | 📅 P4 | `object.convert.parametric.toTable` | Data (参数采样) | ⚠️ 大致可逆 | ⚠️ 采样精度+参数信息损失 |
| **curve.explicit2d → curve.parametric2d** | 🔬 Research | `object.convert.explicit.toParametric` | Plane/Data | ✅ 可逆 (参数→显式) | 表达形式变化，数学等价 |
| **curve.parametric2d → curve.explicit2d** | 🔬 Research | `object.convert.parametric.toExplicit` | Plane | ⚠️ 不可逆 (不是所有parametric都可explicit化) | 🚫 可能无法转换 |
| **curve.implicit2d → curve.explicit2d** | 🔬 Research | — | Plane | ⚠️ 不可逆 | 🚫 多数implicit曲线不可explicit化 |
| **curve.parametric3d → curve.parametric2d** | ❌ 不推荐 | — | — | ⚠️ | 🚫 丢失 Z 维度信息 |

### 3.3 线段对象转换

| From → To | 状态 | Capability ID | 触发 Calculator | 可逆? | 数据损失 |
|-----------|------|---------------|-----------------|-------|---------|
| **segment.2d → segment.3d** | 🔬 Research | `object.convert.segment2d.toSegment3d` | Space | ✅ 可逆 | Z=0 |
| **segment.3d → segment.2d** | 🔬 Research | `object.convert.segment3d.toSegment2d` | Plane | ✅ 可逆 | ⚠️ 丢失 Z 坐标 |
| **segment.2d → line.2d** | 🚫 禁止 | — | — | — | 语义变化 (有限→无限) |
| **segment.2d → ray.2d** | 🚫 禁止 | — | — | — | 语义变化 |

### 3.4 曲面对象转换

| From → To | 状态 | Capability ID | 触发 Calculator | 可逆? | 数据损失 |
|-----------|------|---------------|-----------------|-------|---------|
| **surface.explicit3d → curve.implicit2d** (等高线) | 📅 P4 | `object.convert.surface.toContour` | Modeling | 🚫 不可逆 | 🚫 等高线丢失高度信息 |
| **surface.parametric3d → table.data** (网格采样) | 🔬 Research | — | Data | 🚫 不可逆 | 🚫 采样精度损失 |

### 3.5 数据集合转换

| From → To | 状态 | Capability ID | 触发 Calculator | 可逆? | 数据损失 |
|-----------|------|---------------|-----------------|-------|---------|
| **table.data → set.point2d** | 📅 P4 | `object.convert.table.toPointSet` | Data | ⚠️ 大致可逆 | ⚠️ 丢失非坐标列 |
| **set.point2d → table.data** | 📅 P4 | `object.convert.pointSet.toTable` | Data | ⚠️ 大致可逆 | ⚠️ 丢失顺序和分组 |
| **table.function → curve.explicit2d** | 📅 P4 | `object.convert.table.toCurve` | Data/Plane | ⚠️ 不精确 | ⚠️ 插值/回归不是原函数 |

### 3.6 文本与媒体转换

| From → To | 状态 | Capability ID | 触发 Calculator | 可逆? | 数据损失 |
|-----------|------|---------------|-----------------|-------|---------|
| **formula.symbolic → text.block** (LaTeX 源码) | ✅ 已实现 | — | 所有 (View) | ✅ 可逆 (text→formula parse) | 无 (保留 LaTeX 字符串) |
| **text.block → formula.symbolic** | 📅 P4 | `object.convert.text.toFormula` | Notes | ⚠️ 需解析验证 | ⚠️ 非LaTeX文本无法转换 |
| **image.asset → surface.explicit3d** (高度图) | 🔬 Research | — | Modeling | 🚫 不可逆 | 🚫 图像→几何不可逆 |
| **formula.symbolic → wave.audio** (公式→音频) | 🚫 禁止 | — | — | — | 语义错误 (公式不是函数曲线) |

### 3.7 跨 Calculator 非法转换

| From → To | 状态 | 原因 |
|-----------|------|------|
| **wave.audio → any geometric kind** | 🚫 禁止 | 音频是波形采样结果，无法逆向恢复几何语义 |
| **text.block → curve.explicit2d** | 🚫 禁止 | 文本不是数学对象 |
| **slider.parameter → point.2d** | 🚫 禁止 | 参数不是几何对象 |
| **construction.* → curve.* | 🚫 禁止 | 构造关系不是独立数学对象 |

---

## 4. 转换优先级矩阵

```
高优先级 (P2 — 验证 Materialize Conversion 管道)
  point.2d → point.3d    ← 最简单，验证完整管道
  point.3d → point.2d    ← 验证逆转换+数据损失警告

中优先级 (P4 — 依赖 Data Calculator 开发)
  curve.explicit2d → table.function    ← Data MVP 核心场景
  table.function → curve.explicit2d    ← 回归/插值

低优先级 (P4 — 依赖 Music/Modeling Calculator 开发)
  curve.explicit2d → wave.audio        ← Music MVP 核心场景
  surface.explicit3d → curve.implicit2d  ← Modeling MVP (等高线)

研究级 (P4 — 数学可行性待验证)
  curve.explicit2d → curve.parametric2d  ← 表达形式转换
  segment.2d → segment.3d               ← 线段维度升级
```

---

## 5. 转换能力 ID 命名规范

```
object.convert.{fromKind}.to{ToKind}

fromKind: 小写点号分隔，如 point.2d
ToKind: CamelCase 缩写，如 ToPoint3d
```

| 转换 | Capability ID |
|------|---------------|
| point.2d → point.3d | `object.convert.point2d.toPoint3d` |
| point.3d → point.2d | `object.convert.point3d.toPoint2d` |
| curve.explicit2d → table.function | `object.convert.curve.toTable` |
| table.function → curve.explicit2d | `object.convert.table.toCurve` |
| curve.explicit2d → wave.audio | `object.convert.curve.toWave` |
| surface.explicit3d → curve.implicit2d | `object.convert.surface.toContour` |
| table.data → set.point2d | `object.convert.table.toPointSet` |
| set.point2d → table.data | `object.convert.pointSet.toTable` |

---

## 6. Calculator 转换参与度

### 6.1 各 Calculator 的转换角色

| Calculator | 作为源 Calculator | 作为目标 Calculator | 主要转换 |
|-----------|-----------------|-------------------|---------|
| **Plane** | point.2d→3d, curve→table, curve→wave | point.3d→2d, table→curve | 2D → 3D 升维 / 曲线导出 |
| **Space** | point.3d→2d | point.2d→3d | 3D → 2D 降维 (Z编辑) |
| **Data** | table→curve, table→pointSet | curve→table, pointSet→table | 数据 ↔ 曲线 互转 |
| **Music** | — | curve→wave | 仅作为转换目标 (消费函数→生成音频) |
| **Notes** | — | formula↔text | 公式 ↔ 文本 互转 |
| **Modeling** | surface→contour | — | 曲面 → 等高线 |

### 6.2 转换触发源

| 触发方式 | 示例 | trans.json 记录 |
|---------|------|----------------|
| **用户编辑触发** | Space 编辑 point.2d 的 Z 坐标 | `triggeredBy: "space.edit.z"` |
| **用户显式转换** | 用户选择 "导出为表格" | `triggeredBy: "user.convert"` |
| **Calculator 导入触发** | Data 导入 CSV 生成 table | `triggeredBy: "data.import.csv"` |
| **插件触发** | Plugin Block 输出新 kind | `triggeredBy: "plugin.block.{blockID}"` |

---

## 7. trans.json 与 DependencyGraph 的分离

### 7.1 两条独立的记录线

```
trans.json (时间维度 — 转换历史)
  记录: 对象的 kind 变更历史
  目的: 溯源、跨Calculator一致性、撤销
  格式: [{fromKind, toKind, timestamp, triggeredBy, metadata}]
  位置: {UUID}.emathica/trans.json

DependencyGraph (空间维度 — 对象依赖)
  记录: 对象之间的依赖关系
  目的: 级联重算、删除策略、循环检测
  格式: {objectID: [dependentObjectIDs]}
  位置: 内存 (未来可能持久化)
```

### 7.2 为什么必须分离

```
❌ 错误做法: trans.json 记录依赖关系
  {fromKind: "point.2d", toKind: "point.3d", dependsOn: [segment1, circle1]}
  → dependsOn 是 DependencyGraph 的职责

✅ 正确做法: trans.json 仅记录 kind 变更
  {fromKind: "point.2d", toKind: "point.3d", triggeredBy: "space.edit.z", metadata: {z: 5.0}}
  → DependencyGraph 单独记录: point3d_1 dependsOn [segment1_3d, circle1_3d]
```

**示例场景:**
```
1. Plane 创建 point.2d (x=2, y=3)
2. Plane 创建 segment.2d (端点A=point.2d, 端点B=(5,7))
   → DependencyGraph: segment1 dependsOn [point1]
3. Space 编辑 point.2d 的 Z=5
   → Materialize Conversion: point.2d → point.3d (kind change)
   → trans.json 记录: {fromKind: "point.2d", toKind: "point.3d", ...}
   → DependencyGraph: segment1 的端点现在引用 point.3d (依赖关系不变)
4. 用户删除 point.3d
   → DependencyGraph: segment1 标记为 "missingSource"
   → trans.json: 不记录删除
```

---

## 8. 转换安全性分类

| 安全级别 | 条件 | 示例 | UI 行为 |
|---------|------|------|---------|
| **Safe** (绿色) | 完全可逆，无数据损失 | point.2d ↔ point.3d (保留 Z=0) | 静默转换 |
| **Warning** (黄色) | 大致可逆，有精度损失 | curve → table → curve | 显示 "精度可能损失" 警告 |
| **Caution** (橙色) | 不可逆，有数据损失 | point.3d → point.2d (丢失Z) | 显示 "将丢失 Z 坐标信息" 确认对话框 |
| **Danger** (红色) | 完全不可逆，永久损失 | curve → wave (无法恢复函数) | 显示 "不可逆操作" 双重确认对话框 |

---

## 9. 当前已实现的隐式"转换"

虽然 Materialize Conversion 系统未正式实现，但当前代码中存在隐式的类型边界穿越：

| 场景 | 当前实现方式 | 问题 |
|------|------------|------|
| Plane → Space 查看 point.2d | Space 读取 document.objects 中 type=.point 的对象，用 Z=0 渲染 | 不是转换，是 View Adaptation |
| Space 的 plane.3d | 使用 `MathObjectType.function` + `GeometryDefinition.kind == .plane3d` | 类型泄露 |
| Plane legacy sampling | `PlaneLegacyExplicitSampling` 独立于 MathCore 的 `ExplicitFunctionSampler2D` | 采样逻辑重复 |
| Draft preview | `PlaneDraftPreviewService` 和 `ProjectPreviewRenderer` 各自采样 | 重复的采样→渲染管道 |

---

## 10. 第一批转换实现建议 (P2)

### 10.1 point.2d → point.3d

```
触发条件: Space calculator 中用户编辑 point.2d 对象的 Z 坐标
前置条件:
  1. point.2d 的 Primary Owner 是 Plane (createdBy = "plane")
  2. Space 在 enabledCalculators 中
  3. 文档的 primaryCalculator 允许 Space 编辑
转换流程:
  1. Space 用户输入 Z 值
  2. 系统检查: 该对象当前 kind 是否为 point.2d
  3. 如果是 → 触发 object.convert.point2d.toPoint3d
  4. kind 变更为 point.3d
  5. MathObject 数据: position 从 WorldPoint(x,y) 扩展为 WorldPoint3D(x,y,z)
  6. trans.json 追加记录
  7. 若 Z=0 → 标记为可逆 (逆转换不丢失数据)
  8. 若 Z≠0 → 标记为可逆但有损 (逆转换丢失 Z)
```

### 10.2 point.3d → point.2d

```
触发条件: Plane calculator 中用户将 point.3d 降至 2D 查看
前置条件:
  1. point.3d 的 Primary Owner 是 Space
  2. Plane 在 enabledCalculators 中
转换流程:
  1. Plane 用户选择 "降至 2D" (或通过 Projection 编辑 XY)
  2. 系统检查: 该对象当前 kind 是否为 point.3d
  3. 如果是 → 触发 object.convert.point3d.toPoint2d
  4. kind 变更为 point.2d
  5. Z 坐标被丢弃 (或暂存于 metadata)
  6. trans.json 追加记录: {fromKind: "point.3d", toKind: "point.2d", metadata: {lostZ: 5.0}}
  7. 显示警告: "将丢失 Z 坐标 (当前 Z=5.0)"
  8. 用户确认后执行
```

---

## 11. 当前限制与 Stop Conditions

| 限制 | 状态 | 阻塞内容 |
|------|------|---------|
| **MathObjectType 无 3D 专属枚举** | ⚠️ 需 P1 解决 | point.3d 和 point.2d 无法通过 type 字段区分 |
| **无 trans.json 存储格式** | ⚠️ 需 P1 定义 | 转换历史无法持久化 |
| **无 ObjectConverter 协议** | ⚠️ 需 P2 实现 | 转换逻辑无统一调度点 |
| **Data/Music/Modeling Calculator 不存在** | ⚠️ P4 前阻塞 | 依赖这些 Calculator 的转换无法验证 |
| **Plane legacy sampling 未废弃** | ⚠️ 需 P3 解决 | curve→table 转换可能采样不正确 |
