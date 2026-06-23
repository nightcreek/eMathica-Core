# Plane Geometry Inspector Properties Audit

## 1. Scope

This pass is audit/design only.

- No Swift production code changes
- No test changes
- No UI implementation

Goal: define a safe Inspector geometry-property structure after row-level minimal property display (`segment length`, `circle radius`) is already in place.

---

## 2. Current Inspector Structure Audit

Based on:

- `eMathica/WorkspaceKit/Inspector/ObjectInspectorPanel.swift`
- `eMathica/WorkspaceKit/ObjectPanel/WorkspaceObjectRowView.swift`
- `eMathica/WorkspaceKit/ObjectPanel/GeometryDependencyPresentation.swift`
- `eMathica/CalculatorModules/Plane/Services/PlaneGeometryResolver.swift`
- `eMathica/MathCore/MathObject.swift`
- `eMathica/DocumentSystem/GeometryDefinition.swift`

### 2.1 Current sections in Inspector

`ObjectInspectorPanel` currently provides:

1. `对象`
   - 名称 / 类型 / 显示 / 可见 / 颜色
2. `样式`
   - 调色板、透明度、填充透明度等
3. `参数`（仅 parameter 对象）
   - slider 值、min/max/step/precision/speed/playback mode
4. `CAS`（有 algebraAnalysis 时）
5. `参数化重写`（有 rewriteInfo 时）
6. `诊断`（有 diagnostics 时）
7. `画布设置`
8. `平面计算器设置`

### 2.2 Type awareness

Inspector currently has limited type branching:

- `object.type == .parameter` 时显示参数 section
- `object.expression.algebraAnalysis != nil` 时显示 CAS/rewrite/diagnostics

It does **not** yet provide a geometry-type-specific section for point/segment/line/ray/circle/intersection.

### 2.3 Existing coverage summary

- Name/type/visibility/style: **Yes**
- Expression/CAS diagnostics: **Yes**
- Slider settings: **Yes**
- Geometry-specific property section: **No**

### 2.4 Context availability

`ObjectInspectorPanel` already has `@Bindable var state: WorkspaceState`, so it can access:

- selected object
- full `state.document.objects`

That is enough context to compute resolved geometry via `PlaneGeometryResolver` if needed.

### 2.5 Real-time suitability

Given current binding model and resolver APIs, Inspector can support real-time resolved geometry display.
No model/schema expansion is strictly required for v1-level geometry property readout.

---

## 3. Geometry Property Section Design

Recommended new section title:

- `几何属性`

Displayed content should be type-based.

## 3.1 Point

Recommended:

- 坐标：`x`, `y`
- 动态关系：是否派生（可由 `geometryDependency != nil`）
- 来源对象（若有 dependency）

## 3.2 Segment

Recommended:

- 端点 A / B
- 长度
- 方向角

## 3.3 Line

Recommended:

- 线上一点
- 方向向量
- 斜率
- 水平/竖直标记（可选）

## 3.4 Ray

Recommended:

- 起点
- 方向向量
- 方向角

## 3.5 Circle

Recommended:

- 圆心
- 半径
- 直径

Deferred:

- 面积
- 周长

## 3.6 Intersection

Recommended:

- 来源对象
- 定义状态
- 交点坐标（defined 时）

For `noSolution`/`missingSource`/`unsupported`/`invalid`, status must be primary; do not present stale coordinate as currently valid.

## 3.7 Dynamic object (general)

Recommended:

- dependency kind
- source objects
- current definition status
- existing convert action entry (already handled in object menu; Inspector can mirror info later)

---

## 4. Row vs Inspector Responsibility

## 4.1 Row (keep minimal)

Row should remain compact:

1. primary value/expression
2. source relation (derived)
3. non-defined status
4. tiny low-risk metric only (`长度`/`半径`, already added)

Do not continue to expand row attributes.

## 4.2 Inspector (detailed)

Inspector should carry full geometry detail surface:

- numerical values
- vectors/angles
- dependency/source metadata
- status semantics

This keeps row readable and avoids further row height/layout pressure.

---

## 5. Performance Strategy

### 5.1 Compute-on-render feasibility

For v1 candidate properties (point coords, segment length, circle radius, line/ray vector/slope), resolver cost is low. Compute-on-render is acceptable.

### 5.2 Caching recommendation

No mandatory cache for v1 inspector properties.

Potential future optimization only if:

- large object counts
- measurable inspector scrolling/jank

### 5.3 Low-cost vs high-cost properties

Low-cost now:

- distances
- vector deltas
- slope/direction angle

Defer/high-risk:

- heavy algebraic domain/range inference
- expensive symbolic derivations

---

## 6. Suggested Chinese Labels

- `几何属性`
- `坐标`
- `端点`
- `长度`
- `方向`
- `斜率`
- `圆心`
- `半径`
- `直径`
- `来源对象`
- `定义状态`

Status wording alignment:

- `当前无交点`
- `源对象缺失`
- `暂不支持该关系`
- `定义无效`

---

## 7. Recommended Implementation Phases

## 7.1 GeometryInspectorProperties-1A

Minimal geometry section for:

- point
- segment
- circle

Focus:

- coordinates / length / radius / diameter
- status-aware display

## 7.2 GeometryInspectorProperties-1B

Expand to:

- line
- ray
- intersection
- dynamic dependency detail

Focus:

- direction/slope
- source/status detail

## 7.3 GeometryPropertyFormatting-1

Unified formatting:

- decimal precision
- angle display
- numeric compactness rules

---

## 8. Risks

P1 risks:

1. Reusing stale coordinate text for non-defined intersections could confuse users.
2. Overloading Inspector with mixed CAS + geometry details can reduce scannability if section order is not curated.
3. If formatting is inconsistent between row and inspector, users may perceive geometry values as unstable.

Mitigation:

- make status-first rules explicit in geometry section
- keep geometry section separate from CAS section
- add shared formatting helper in later formatting pass

---

## 9. Conclusion

Current Inspector is a good host for detailed geometry properties and already has sufficient state context.  
Recommended next step is `GeometryInspectorProperties-1A` with a conservative, status-aware geometry section for point/segment/circle first, while keeping row compact and unchanged.

