# ConicRecognition Plan

## 1. 已完成阶段

- ConicRecognition-1A：原点圆 `x² + y² = c` -> `GraphIntent.circle`
- ConicRecognition-2A：`ConicInfo.canonicalForm` 扩展
- ConicRecognition-2B：原点 ellipse/hyperbola 标准形识别
- ConicRecognition-2C：`ConicSampler2D`（参数化复用 `ParametricCurveSampler2D`）
- ConicRecognition-2D：Plane 默认 semantic preview 启用 conic；对象区文案显示“椭圆/双曲线/抛物线/圆锥曲线”
- ConicRecognition-3A：平移圆标准式识别
  - `(x-a)^2 + (y-b)^2 = c` -> `GraphIntent.circle`
  - 支持 `(x+a)/(y+b)` 形式
  - 支持左右交换、项顺序交换
  - 不支持展开式配方
- ConicRecognition-3B：平移椭圆/双曲线标准式识别
  - `(x-a)^2/A + (y-b)^2/B = 1` -> `translatedEllipse`
  - `(x-a)^2/A - (y-b)^2/B = 1` -> `translatedHyperbolaX`
  - `(y-b)^2/B - (x-a)^2/A = 1` -> `translatedHyperbolaY`
  - `A,B` 必须可数值求值且 `> 0`
  - 支持左右交换、项顺序交换
  - 不支持展开式、旋转项、一般二次型
- ConicRecognition-4B：`QuadraticFormExtractor`
  - 新增 2D 二次型系数提取（`A x² + B xy + C y² + D x + E y + F`）
  - 第一版仅支持数值系数与已展开/近展开项
- ConicRecognition-4C：非旋转一般二次型分类
  - 基于 `QuadraticFormExtractor` 对 `Ax² + Cy² + Dx + Ey + F = 0`（`Bxy ≈ 0`）分类
  - 可识别 `circle / ellipse / hyperbola`
  - 产出 `GraphIntent.circle` 或 `GraphIntent.conic(canonicalForm: translated...)`
  - 识别结果可进入 semantic preview
- ConicRecognition-4D：非旋转抛物线识别与采样
  - `Ax² + Dx + Ey + F = 0` -> `translatedParabolaY`
  - `Cy² + Ey + Dx + F = 0` -> `translatedParabolaX`
  - 使用 `QuadraticFormExtractor`
  - 输出 `ConicInfo(kind: .parabola, canonicalForm: .translatedParabolaY/.translatedParabolaX)`
  - `ConicSampler2D` 复用 `ExplicitFunctionSampler2D.sampleY/sampleX`
- ConicRecognition-4E：rotated conic / `xy` 项设计审计
- ConicRecognition-4F：旋转 conic 基础类型扩展
  - `ConicInfo.rotationAngle`
  - `SampleSet2D.mapPoints(...)`
  - `ConicCoordinateTransform2D`
- ConicRecognition-4G：rotated ellipse / hyperbola 分类与采样接入
- PolynomialExpansion-2A：`PolynomialExpander` 有限展开实现
- PolynomialExpansion-2B：`QuadraticFormExtractor` 增加 `.strict/.expanded2D` options
- PolynomialExpansion-2C：GraphClassifier 一般二次型路径接入 expanded2D fallback（strict 失败后尝试）

## 2. 当前支持

- `x² + y² = c` -> circle
- `(x-a)^2 + (y-b)^2 = c` -> translated circle
- `x²/A + y²/B = 1` -> origin ellipse
- `x²/A - y²/B = 1` -> origin hyperbola X
- `y²/B - x²/A = 1` -> origin hyperbola Y
- `(x-a)^2/A + (y-b)^2/B = 1` -> translated ellipse
- `(x-a)^2/A - (y-b)^2/B = 1` -> translated hyperbola X
- `(y-b)^2/B - (x-a)^2/A = 1` -> translated hyperbola Y
- `Ax² + Cy² + Dx + Ey + F = 0` 且 `Bxy=0` 的非旋转展开式
  - 可识别 circle / ellipse / hyperbola / parabola
  - 可生成 `canonicalForm` 或 `GraphIntent.circle`
  - 可进入 semantic preview
- `Bxy ≠ 0` 的 rotated ellipse / rotated hyperbola
- 通过 expanded2D 可覆盖部分“自然输入”：
  - `(x+1)^2 + y^2 = 4`
  - `(x+1)(x-1) + y^2 = 0`

## 3. 当前仍不支持

- rotated parabola
- 退化 conic
- symbolic coefficients
- arbitrary polynomial expansion（超出 degree/term 限制）
- 一般 CAS 化简（非有限展开路径）

## 4. 下一步建议

- ConicRecognition-4H：rotated parabola 识别与采样
- ConicRecognition-4I：退化 conic 处理设计
- PolynomialExpansion-2E：expanded2D conic 误判审计
- PolynomialExpansion-3A：有限符号系数策略审计
- Sampling3D-1：3D SamplingCore 设计

## 5. 兼容与 fallback 说明

- conic 识别失败时继续 fallback implicit/legacy 路径，不阻断预览。
- 一般二次型提取现在采用 strict-first，strict 失败后尝试 expanded2D；expanded2D 失败继续 fallback implicit。
- `PlaneSemanticPreviewPolicy` 当前 conic 默认启用，但 semantic 采样失败仍会回退 legacy/last-valid。
- 本计划不改变 `GraphClassifier` 之外的输入语义边界，不依赖字符串/LaTeX 回解析。
