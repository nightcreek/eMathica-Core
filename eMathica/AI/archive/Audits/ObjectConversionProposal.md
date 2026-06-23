# Object Conversion Proposal

> **日期:** 2026-06-16
> **原则:** Materialize conversion — 对象跨计算器转换时，kind 实质升级并记录历史

---

## 1. Materialize Conversion Principle

**如果用户在一个 calculator 中编辑了对象，使其语义升级，则对象 kind 必须实质改变。**

这是与"view adapter"模式的关键区别：

| 模式 | 行为 | kind 变化 | 适用场景 |
|------|------|-----------|---------|
| **View adaptation** | 计算器仅以不同方式显示对象 | 不变 | Plane 导入 2D 点显示为散点 |
| **Materialize conversion** | 用户编辑导致语义变化 | **改变** | Space 编辑 2D 点的 z → 变为 3D 点 |

### 判断标准

```
if user_edit_changes_mathematical_semantics:
    → materialize conversion (kind changes, trans.json recorded)
else:
    → view adaptation (kind stays, only view changes)
```

---

## 2. Conversion Capability Naming

遵循 `object.convert.{from}.to{To}` 命名：

```
object.convert.point2d.toPoint3d
object.convert.point3d.toPoint2d
object.convert.curve.toWave
object.convert.curve.toTable
object.convert.table.toPointSet
object.convert.surface.toImplicit2d
object.convert.wave.toCurve
```

---

## 3. trans.json Planning

### 3.1 File Location

```
{UUID}.emathica/
├── metadata.json
├── document.json
├── preview.png
└── trans.json          ← NEW: conversion history
```

### 3.2 Record Format

```json
{
  "version": "1.0",
  "conversions": [
    {
      "conversionID": "UUID",
      "objectUUID": "original-object-UUID",
      "resultObjectUUID": "new-object-UUID",
      "fromKind": "point.2d",
      "toKind": "point.3d",
      "capability": "object.convert.point2d.toPoint3d",
      "timestamp": "2026-06-16T10:30:00Z",
      "triggeredBy": "space.edit.z",
      "metadata": {
        "z": 5.0,
        "preserveXY": true
      }
    }
  ]
}
```

### 3.3 Fields

| Field | Type | Description |
|-------|------|-------------|
| `conversionID` | UUID | 转换记录唯一 ID |
| `objectUUID` | UUID | 源对象 UUID |
| `resultObjectUUID` | UUID | 转换后新对象 UUID（可能与 objectUUID 相同如果原地升级，或不同如果创建新对象） |
| `fromKind` | string | 转换前 object kind |
| `toKind` | string | 转换后 object kind |
| `capability` | string | 使用的转换能力 ID |
| `timestamp` | ISO 8601 | 转换时间 |
| `triggeredBy` | string | 触发此转换的 calculator + action |
| `metadata` | JSON object | 转换参数 |

---

## 4. Conversion Examples

### 4.1 point.2d → point.3d

**场景:** 用户在 Plane 中创建了一个 2D 点，然后在 Space 中编辑其 z 坐标。

```
Before:
  object: { id: A, kind: "point.2d", position: (3, 5) }

User action in Space:
  Open Plane document in Space (view adaptation: 2D points shown with z=0)
  Select point A
  Edit z coordinate: 0 → 7

After (materialize conversion):
  object: { id: A, kind: "point.3d", position: (3, 5, 7) }
  
  trans.json:
  {
    "conversionID": "B",
    "objectUUID": "A",
    "resultObjectUUID": "A",
    "fromKind": "point.2d",
    "toKind": "point.3d",
    "capability": "object.convert.point2d.toPoint3d",
    "triggeredBy": "space.edit.z",
    "metadata": { "z": 7.0, "preserveXY": true }
  }
```

**反向转换 (point.3d → point.2d):**
```
  capability: "object.convert.point3d.toPoint2d"
  metadata: { "dropZ": true, "originalZ": 7.0 }
```
注意：反向转换会丢失 z 信息，应当提示用户确认。

### 4.2 curve.explicit2d → wave.audio

**场景:** 用户在 Plane 中绘制了 y=sin(x)，然后导入 Music calculator 播放为音频。

```
Before:
  object: { id: C, kind: "curve.explicit2d", expression: "y = sin(x)" }

User action in Music:
  Import curve as audio source
  Select frequency range [20Hz, 20000Hz]
  Map x → time, y → amplitude

After (materialize conversion via sampling):
  object: { id: C, kind: "wave.audio", 
            samples: [amplitudes over time],
            sampleRate: 44100,
            duration: 5.0 }
  
  trans.json:
  {
    "conversionID": "D",
    "objectUUID": "C",
    "resultObjectUUID": "C",
    "fromKind": "curve.explicit2d",
    "toKind": "wave.audio",
    "capability": "object.convert.curve.toWave",
    "triggeredBy": "music.import.function",
    "metadata": { 
      "frequencyRange": "20-20000",
      "sampleRate": 44100,
      "mapping": "x→time, y→amplitude"
    }
  }
```

### 4.3 curve.explicit2d → table.data

**场景:** 用户在 Plane 中绘制了 y=x²，然后导入 Data calculator 生成数值表。

```
Before:
  object: { id: E, kind: "curve.explicit2d", expression: "y = x^2" }

User action in Data:
  Import curve as table
  Select x range [-5, 5], step 0.5

After (materialize conversion by sampling):
  object: { id: E, kind: "table.data",
            columns: [
              { "x": -5, "y": 25 },
              { "x": -4.5, "y": 20.25 },
              ...
            ]}
  
  trans.json:
  {
    "conversionID": "F",
    "objectUUID": "E",
    "resultObjectUUID": "E",
    "fromKind": "curve.explicit2d",
    "toKind": "table.data",
    "capability": "object.convert.curve.toTable",
    "triggeredBy": "data.import.sample",
    "metadata": { 
      "xRange": [-5, 5],
      "step": 0.5,
      "pointCount": 21
    }
  }
```

### 4.4 surface.parametric3d → curve.implicit2d (等值线)

**场景:** Space 中的 3D 曲面生成 2D 等值线，导入 Plane 进行分析。

```
Before:
  object: { id: G, kind: "surface.parametric3d" }

User action:
  Select contour level z = 5
  Project to XY plane

After:
  new object: { id: H, kind: "curve.implicit2d" }
  
  trans.json:
  {
    "conversionID": "I",
    "objectUUID": "G",
    "resultObjectUUID": "H",
    "fromKind": "surface.parametric3d",
    "toKind": "curve.implicit2d",
    "capability": "object.convert.surface.toImplicit2d",
    "triggeredBy": "space.contour.project",
    "metadata": { "contourLevel": 5.0, "plane": "xy" }
  }
```

---

## 5. Conversion History & Dependency Graph

### 5.1 关系

`trans.json` 记录的是 **时间维度上的转换链**，而 `DependencyGraph` 处理的是 **空间维度上的对象依赖**。

```
trans.json:
  point.2d → point.3d (time: user edited z)
  
DependencyGraph:
  point.3d ← midpointOf(point.3d, otherPoint.3d) (space: construction dependency)
```

两者互补：
- DependencyGraph 确保重建依赖对象时使用正确的源对象
- trans.json 确保溯源：这个 3D 点最初是从哪个 2D 点转换来的

### 5.2 查询

未来可以通过 trans.json 回答：
- "这个 `point.3d` 最初是 `point.2d` 吗？"
- "这个 `wave.audio` 是从哪个 `curve` 生成的？"
- "这个 `table.data` 的原始曲线是什么？"

这对用户理解和 undo 很重要。

---

## 6. Conversion Safety

### 6.1 不可逆转换警告

| Conversion | Reversible? | Warning |
|-----------|-------------|---------|
| `point.2d → point.3d` | `point.3d → point.2d` (lose z) | ⚠️ 反向会丢失 z 信息 |
| `point.3d → point.2d` | 可逆 (z=0) | ℹ️ 恢复时 z=0 |
| `curve → table` | `table → curve` (by interpolation) | ⚠️ 插值不是原始函数 |
| `curve → wave` | 不可逆 | 🔴 音频是采样结果，不能恢复曲线 |

### 6.2 权限

- 同计算器内编辑：自动转换，无需确认
- 跨计算器导入：需要用户确认（"导入此对象到 Space 会将其转换为 3D 点"）
- 不可逆转换：必须明确警告用户

---

## 7. Implementation Notes

### Phase 1 (Post-v1.0): trans.json Storage
1. 在 `EMathicaPackageLayout` 中添加 `transURL`（`rootURL/trans.json`）
2. 在 `LocalProjectStore.saveProject` 中写入 `trans.json`
3. 在 `LocalProjectStore.loadProject` 中读取 `trans.json`

### Phase 2 (Post-v1.0): Conversion Pipeline
1. 在 `EMathicaObjectKit` 中定义 `ObjectConverter` 协议
2. 每个 calculator 注册其支持的 conversion
3. 转换时调用 `ObjectConverter.convert()`, 返回新的 `MathObject` + `ConversionRecord`

### Phase 3 (Future): Conversion UI
1. 跨计算器导入时显示预览
2. 不可逆转换显示警告对话框
3. trans.json 历史在 Inspector 中可查看
