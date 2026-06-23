# Quadratic Conic Recognition Design (ConicRecognition-4A)

## 1. 当前能力回顾

- 语义输入已经可得到 `Expr`，并且 `GraphClassifier` 已支持：
  - 原点圆、平移圆
  - 原点/平移标准椭圆与双曲线（结构化标准式）
- 识别路径仍是 pattern matching + 数值可求值检查。
- 采样层已可消费 `GraphIntent.circle` / `GraphIntent.conic` 并出图。
- 不支持一般二次型 `Ax² + Bxy + Cy² + Dx + Ey + F = 0` 的统一识别。

## 2. 为什么一般二次型不能直接塞进现有 pattern matching

现有识别是“标准式模板匹配”，依赖固定 AST 形状（例如 `divide(power(...,2), ...)`）。  
一般二次型在 AST 里可能出现多种等价结构：

- `add`/`negate`/`multiply` 的组合顺序不同
- 常数项分布在等式两侧
- `xy` 项可能写成 `x*y` 或 `y*x`
- 一次项 `Dx + Ey` 可能被拆成不同乘法/加法树

如果继续堆模板，复杂度会指数上涨，回归风险也高。  
因此需要先抽象成统一系数表示，再做分类。

## 3. 当前类型审计结论

### 3.1 Expr 是否足够表达一般二次型

足够。`Expr` 已能表达：

- 二次项：`power(symbol("x"), 2)`、`multiply([x, y])`
- 一次项：`multiply([k, x])`、`multiply([k, y])`
- 常数项与分式项：`integer/rational/decimal/real/divide/negate/add`

### 3.2 CanonicalExpr 是否更适合系数提取

更适合“稳定遍历”，因为它的 `sum/product/power` 命名更语义化，且 `Hashable`。  
但当前 canonicalize 还不会做完整多项式规范化（例如不做通用展开/合并同类项）。  
建议 4B 第一版仍从 `Expr`（经过 normalize/simplify）提取，后续再评估迁移到 `CanonicalExpr`。

### 3.3 Normalizer / Simplifier 当前可提供的稳定性

- `ExpressionNormalizer`：能稳定 flatten `add/multiply`，递归规整子树。
- `ExpressionSimplifier`：能处理基础 `0/1` 规则、双重负号、整数分式约分、`x^0/x^1`。
- 仍不足：
  - 不做通用分配律展开
  - 不做通用同类项合并
  - 不做符号系数代数整理

结论：足够支持“数值系数 + 已接近多项式和式”的第一版提取器。

### 3.4 GraphClassifier 现有结构是否适合扩展

适合。当前 conic 相关 helper 已分层：

- `classifyOriginCircleIntent`
- `classifyTranslatedCircleIntent`
- `classifyStandardOriginConicIntent`
- `classifyStandardTranslatedConicIntent`

可在未来新增一个统一入口（例如 `classifyGeneralQuadraticConicIntent`）并放在 conic 识别链中，失败继续 fallback implicit。

### 3.5 当前是否已有系数提取能力

没有独立的“二次型系数提取器”。  
建议新增到 **MathCore/CASCore**，而不是 GraphCore：

- CASCore 负责表达式结构化分析更合适
- GraphCore 保持“意图分类编排层”

## 4. QuadraticFormExtractor 设计

建议新增：

- `MathCore/CASCore/QuadraticFormExtractor.swift`

建议接口：

```swift
struct QuadraticForm2D {
    var a: Expr   // x² coefficient
    var b: Expr   // xy coefficient
    var c: Expr   // y² coefficient
    var d: Expr   // x coefficient
    var e: Expr   // y coefficient
    var f: Expr   // constant
}

struct QuadraticFormExtractor {
    func extract(from expr: Expr) -> Result<QuadraticForm2D, [ExprDiagnostic]>
}
```

目标标准：`A x² + B xy + C y² + D x + E y + F = 0`

## 5. 4B 第一版提取范围（建议）

只支持数值系数：

- `integer / rational / decimal / real`
- `negate`
- `divide`（分母可数值求值）

暂不支持：

- 符号系数（`a,b,c`）
- 函数系数
- 高阶项（`x^3` 等）
- 非多项式项（三角、指数、绝对值等）

若超出范围，返回诊断并交由上层 fallback implicit。

## 6. 分类规则设计（基于二次型）

提取到 `A,B,C,D,E,F` 后可先做数值判别：

- 判别式：`Δ = B² - 4AC`
  - `Δ < 0` -> ellipse-like
  - `Δ = 0` -> parabola-like
  - `Δ > 0` -> hyperbola-like

注意：

- 退化情况（空集、单点、相交线、重合线）第一版不做精细处理，直接 fallback implicit。
- 仅当关键量可稳定数值求值时才进入 conic 分类。

## 7. rotation / translation 设计（本轮仅设计）

### 7.1 旋转（`B != 0`）

- `B != 0` 表示存在 `xy` 耦合，需要旋转坐标轴。
- 建议后续扩展 `ConicInfo` 支持 `rotationAngle`（Expr 或 Double）。
- 采样策略可为：在局部坐标参数化 -> 旋转和平移回世界坐标。

### 7.2 平移（`D,E`）

- 对非抛物线可通过线性代数求中心（解梯度为零点）。
- 抛物线一般没有“中心”，更适合用轴线+顶点参数表达。
- 若引入统一方法，建议后续加入轻量矩阵/二次型工具（仍放 CASCore）。

## 8. ConicInfo 后续扩展建议（仅建议，不改类型）

可考虑新增：

- `generalQuadratic`（原始系数快照）
- `center`
- `rotationAngle`
- `semiAxes`
- `focalParameter`（尤其 parabola）
- `degeneracy`（none/point/linePair/...）

当前阶段不必一次到位，建议按 4C/4D/4E 分批加。

## 9. 采样策略建议（未来）

- ellipse：参数曲线采样
- hyperbola：双支参数曲线，范围由 viewport/质量档位估算
- parabola：优先转 explicitY/explicitX；否则参数化
- rotated conic：参数化后应用旋转+平移变换
- 识别不稳定/退化：fallback implicit（Marching Squares）

## 10. fallback 策略

- 提取失败、分类不确定、退化未处理：`GraphIntent.implicit`
- 保持当前 Plane semantic preview 的鲁棒回退链路（semantic 失败 -> legacy/last-valid）

## 11. 分阶段实现路线

- **4B**：`QuadraticFormExtractor`（仅数值系数提取）
- **4C**：非旋转一般二次型分类（`B=0` 优先）
- **4D**：旋转二次型（`xy` 项）审计与实现
- **4E**：退化 conic 检测与分类策略

## 12. 测试计划（未来）

- 提取层：
  - 成功提取标准与非标准排列的 `A..F`
  - 拒绝高阶项/非多项式项/符号不可求值系数
- 分类层：
  - `Δ` 三类覆盖（ellipse/parabola/hyperbola-like）
  - 失败与退化 fallback implicit
- 预览层：
  - conic intent 生成稳定样本
  - fallback 路径不破坏现有 explicit/implicit 行为
