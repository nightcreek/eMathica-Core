# Rotated Conic Recognition Design (ConicRecognition-4E)

## 1. 当前能力回顾

当前系统已具备：
- 非旋转 (`Bxy = 0`) 的 `circle / ellipse / hyperbola / parabola` 识别与采样链路。
- `QuadraticFormExtractor` 可从 `Expr` 提取二次型系数：
  - `A = xx`
  - `B = xy`
  - `C = yy`
  - `D = x`
  - `E = y`
  - `F = constant`
- `ConicSampler2D` 可采样 axis-aligned 的 `translatedEllipse / translatedHyperbolaX/Y / translatedParabolaX/Y`。

当前不具备：
- `Bxy != 0` 的旋转二次曲线识别与采样。
- 通用“局部坐标采样 -> 世界坐标旋转/平移映射”的公共变换层。

## 2. 为什么 `Bxy` 需要旋转坐标

一般二次型：

`Ax^2 + Bxy + Cy^2 + Dx + Ey + F = 0`

其中 `Bxy` 是坐标轴耦合项。只靠当前 axis-aligned pattern matching 无法直接稳定归类为 ellipse/hyperbola/parabola。

核心思路：
1. 先做刚体变换（旋转 + 平移）把式子转到局部坐标系。
2. 在局部坐标系中得到标准型（无 `xy` 项）。
3. 用现有非旋转分类与采样方式处理。
4. 把局部采样点映射回世界坐标。

## 3. 旋转角公式与数值注意

对二次项矩阵：

`Q = [[A, B/2], [B/2, C]]`

消去交叉项的经典角度满足：

`tan(2θ) = B / (A - C)`

实现建议：
- 使用 `θ = 0.5 * atan2(B, A - C)`（避免直接 `tan` 带来的除零问题）。
- 当 `abs(B) <= epsilon` 时走非旋转路径（`θ = 0`）。
- 当 `abs(A - C)` 很小且 `abs(B)` 不小，`atan2` 仍可稳定给出接近 `±π/4` 的角度。
- 角度统一用 `Double` radians。

## 4. center / vertex 计算设计

### 4.1 ellipse/hyperbola（有中心）

对一般二次式可通过线性系统求中心 `(h, k)`：

对梯度设零：
- `2A h + B k + D = 0`
- `B h + 2C k + E = 0`

矩阵形式：

`M * [h, k]^T = -[D, E]^T`，其中 `M = [[2A, B], [B, 2C]]`

若 `det(M)` 过小（病态或接近抛物线/退化），不强行求解，fallback implicit。

### 4.2 parabola（无“中心”）

抛物线没有中心，使用“顶点 + 轴向”表示更合理：
- 先旋转消 `xy`。
- 在局部坐标里按一元二次完成平方得到顶点与开口系数。
- 再把顶点映射回世界坐标。

本阶段仅设计，不实现 rotated parabola 数值细节。

## 5. ConicInfo 扩展方案比较

当前 `ConicInfo`：
- `kind`
- `source`
- `canonicalForm`
- `orientation`（`axisAligned/rotated/unknown`，无角度）

### 方案 A（推荐，最小增量）
- 保留 `ConicOrientation`。
- 在 `ConicInfo` 新增：
  - `rotationAngle: Double?`

优点：
- 改动最小。
- 与当前 `orientation` 字段兼容。
- 足够支撑“axis-aligned 参数 + 旋转角”采样。

缺点：
- 仅有角度，缺少统一 frame 语义封装。

### 方案 B（中期演进）
- 新增 `ConicCoordinateFrame`：
  - `center: Expr`
  - `rotationAngle: Double`
- `ConicInfo` 持有 `frame`。

优点：
- 语义完整，适合后续复杂 conic。

缺点：
- 改动面更大，不适合第一步落地。

### 方案 C（在 canonicalForm 中塞 rotated case）
- 为每种 conic 增加 `rotated...` case。

优点：
- 表达直接。

缺点：
- case 爆炸，维护成本高。
- 与“先局部后变换”的通用采样思路耦合过重。

**结论：优先方案 A，后续可平滑演进到 B。**

## 6. ConicSampler2D 坐标变换设计

目标：不重写现有采样器，复用局部标准采样能力。

建议流程：
1. 在局部坐标系构造 canonical 表达并采样（ellipse/hyperbola/parabola）。
2. 得到局部 `SampleSet2D`。
3. 对每个点应用：
   - 旋转 `R(theta)`
   - 平移到世界 `center`
4. 输出世界坐标 `SampleSet2D`。

建议新增（后续实现阶段）：
- `ConicCoordinateTransform2D`
  - `centerX, centerY, rotationAngle`
  - `apply(_ point: SamplePoint2D) -> SamplePoint2D`
- `SampleSet2D.mapPoints(_:)`
  - 对所有 segment 的 points 做纯函数变换。

这样能避免修改 renderer，并保持 SamplingCore 独立于 UI/WorkspaceKit。

## 7. fallback 策略

以下情况建议继续 fallback implicit：
- `QuadraticFormExtractor` 提取失败。
- 旋转/中心求解病态（矩阵接近奇异）。
- 分类结果不稳定（接近退化边界）。
- 参数不满足采样前提（例如轴长非正）。
- 退化 conic（本阶段不处理）。

保持原则：
- 识别失败不报致命错误，不阻断可视化。
- 仍可由 implicit sampler 提供可用预览。

## 8. 分阶段路线建议

- **4E-doc（本轮）**：旋转 conic 设计审计（本文档）。
- **4F**：类型扩展（`rotationAngle` / 可选 frame）。
- **4G**：`QuadraticForm` 路径支持 rotated ellipse/hyperbola 分类。
- **4H**：`ConicSampler2D` 支持局部采样后旋转/平移映射。
- **4I**：rotated parabola 识别与采样。
- **4J**：退化 conic 处理（点、空集、直线对等）。

## 9. 测试计划（设计）

建议后续覆盖：
- `xy` 项存在时能稳定进入 rotated 分类，不误判为非旋转。
- 旋转角数值稳定性（`A≈C`、`B≈0`）。
- 采样点逆变换后满足原方程近似。
- fallback 场景仍可走 implicit，且不崩溃。
- 对象区文案保持与 `ConicKind` 一致（不新增 UI 规则）。
