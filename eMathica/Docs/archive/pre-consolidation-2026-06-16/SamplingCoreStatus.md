# SamplingCore Status

## 1. 当前 2D SamplingCore 总览

### 已支持
- `explicitY`
- `explicitX`
- `parametric2D`
- `polar`
- `point`
- `circle`
- `implicit`
- `piecewise`
- `conic`

### 暂未支持/未完成
- 3D SamplingCore
- advanced adaptive sampling（进一步策略化）

## 2. GraphIntent -> Sampler 映射表

- `explicitY` -> `ExplicitFunctionSampler2D.sampleY`
- `explicitX` -> `ExplicitFunctionSampler2D.sampleX`
- `parametric2D` -> `ParametricCurveSampler2D.sample`
- `polar` -> `PolarCurveSampler2D.sample` -> `ParametricCurveSampler2D.sample`
- `point` -> `PrimitiveSampler2D.samplePoint`
- `circle` -> `PrimitiveSampler2D.sampleCircle` -> `ParametricCurveSampler2D.sample`
- `implicit` -> `ImplicitCurveSampler2D.sample`（Marching Squares + SegmentStitcher2D）
- `piecewise` -> `PiecewiseSampler2D.sampleY`
- `conic` -> `ConicSampler2D.sample` -> `ParametricCurveSampler2D.sample`

## 3. Plane semantic preview 默认策略

`PlaneSemanticPreviewPolicy` 当前默认：

### 默认启用
- `parametric2D`
- `polar`
- `point`
- `circle`
- `piecewise`
- `implicit`
- `conic`

### 默认关闭
- `explicitY`
- `explicitX`
- `unknown`

### 说明
- `explicitY/explicitX`：继续走 legacy，优先稳定性，避免大范围行为变化。
- 其余默认启用项在 semantic 失败时仍会 fallback legacy/last-valid。

## 4. 当前质量档位

`SamplingQualityProfile`：
- `preview`
- `balanced`
- `precise`
- `exploratory`

当前语义：
- explicit/parametric/polar/circle/conic：支持 `uniform`、`basic refinement`、`adaptiveScreenSpace`
- `adaptiveScreenSpace`：基于 `SamplingViewport2D` 的屏幕空间中点误差细分
- `hybridExploratory`：当前仍 fallback 到 adaptive/basic refinement，尚未实现独立探索策略
- implicit：固定网格 Marching Squares + SegmentStitcher2D
- piecewise：第一版 uniform baseline，不做 refinement
- conic：参数化后复用 `ParametricCurveSampler2D`，可间接受益于 `adaptiveScreenSpace`

## 5. 当前限制

- implicit 无 adaptive grid
- explicit sampler `maxSampleCount` 目前是结果截断式约束，后续可演进为采样预算模型
- piecewise 当前只支持 `explicitY` branch
- piecewise 推荐入口仍是内置 piecewise 模板（自由文本 braces/cases 不保证稳定 lowering 为 `Expr.piecewise`）
- conic 已支持非旋转 `circle / ellipse / hyperbola / parabola`（包含标准式、平移标准式、非旋转展开式 `Bxy=0`）
- conic 已支持 rotated `ellipse / hyperbola`（`Bxy ≠ 0`）
- conic 识别前置 CAS 已增强：一般二次型 strict 提取失败时，会尝试有限 `expanded2D`（PolynomialExpander）
- 因此部分自然输入（如 `(x+1)^2 + y^2 = 4`、`(x+1)(x-1) + y^2 = 0`）可识别为 `circle/conic` 并进入 semantic preview
- parabola 采样通过 `ConicSampler2D` -> `ExplicitFunctionSampler2D.sampleY/sampleX`
- conic 仍不支持 rotated parabola
- 退化 conic 仍 fallback `implicit`
- `circle((cx,cy), r)` 函数式输入已支持
- `x² + y² = c` 已识别为 `circle`
- `(x-a)^2 + (y-b)^2 = c` 已识别为平移圆
- `x²/A ± y²/B = 1` 已识别为原点 `conic`（ellipse/hyperbola）
- `(x-a)^2/A ± (y-b)^2/B = 1` 已识别为平移 `conic`（ellipse/hyperbola）
- conic 识别失败会 fallback `implicit`
- Plane 已接入真实 canvas pixel size，`SamplingViewport2D` 不再默认依赖 `1024×640`；仅在尺寸不可用时 fallback
- InputNormalization-1 已完成 semantic lowering 层第一版归一化
- 目前已支持常见全角数字、字母、运算符、括号、逗号、`≤/≥/≠`
- 3D sampling 尚未启动

## 6. 后续路线建议

- Adaptive：真正 screen-space adaptive sampling 深化
- ConicRecognition-4H：rotated parabola 识别与采样
- DegenerateConic-1：退化 conic 处理设计
- PolynomialExpansion-2E：expanded2D conic 误判审计
- PolynomialExpansion-3A：有限符号系数策略审计
- Sampling3D-1：3D SamplingCore 设计
- InputNormalization-2：更多 Unicode 数学输入归一化

## 7. 职责边界

- Lowering 不做采样
- GraphClassifier 不做采样
- ExprEvaluator 只做单点数值求值
- ConditionEvaluator 只做条件布尔判断
- Sampler 只做采样策略，不解析字符串
- Renderer 只绘制 `PlotSegment`（以及 future primitives）
- DocumentSystem 不持久化运行期采样结果
