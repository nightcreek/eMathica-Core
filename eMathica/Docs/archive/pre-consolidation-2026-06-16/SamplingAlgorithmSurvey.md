# Sampling Algorithm Survey (Sampling-0)

## 一、eMathica 采样目标

eMathica 的采样系统需要覆盖以下数学对象，并且在架构上明确区分 2D 与 3D：

- 平面显函数 `y = f(x)`
- 平面横向显函数 `x = f(y)`
- 平面参数曲线
- 极坐标曲线
- 平面隐函数 `F(x, y) = 0`
- 几何图元：点、线、圆、圆锥曲线
- 未来立体显式曲面 `z = f(x, y)`
- 未来空间参数曲线
- 未来参数曲面
- 未来隐式曲面 `F(x, y, z) = 0`

核心结论：这些对象的采样方法差异很大，必须按图形意图分流，不能尝试一个“万能采样器”。

---

## 二、开源/常见软件参考

### 1) gnuplot

- 典型思想：固定 `samples`（和部分场景下的 `isosamples`）均匀采样。
- 优点：
  - 算法简单
  - 性能可预测
  - 参数直观
- 缺点：
  - 高频振荡函数、尖点、断点附近需要显著增大采样密度
  - 过低样本数会漏细节，过高样本数会浪费计算

对 eMathica 的启发：Sampling-1 用“固定均匀采样”做基线是合理的，但它只是起点。

### 2) JSXGraph

- 明确区分曲线类型（函数图像、参数曲线、极坐标曲线等）。
- 隐函数模块（`implicitcurve`）有独立控制参数（如分辨率、步进、容差、最大步数等）。
- 启发：
  - `GraphIntent` 分流方向正确
  - 隐函数采样不应混进显函数采样器内部

### 3) Matplotlib / scikit-image

- 等值线（contour）常见方法对应网格上的等值线提取，工程上广泛使用 marching squares 思路。
- 启发：
  - 2D 隐函数/等值线应使用网格算法，不应沿 x 或 y 单轴“硬扫”替代。

### 4) marching squares

- 面向 2D 标量场 `F(x,y)=0` 的等值线提取算法。
- 输出通常为线段或折线集合。
- 适合隐函数曲线（尤其多分支、闭环、复杂拓扑）。

### 5) marching cubes

- 面向 3D 标量场 `F(x,y,z)=0` 的等值面提取算法。
- 输出 mesh（三角网格）。
- 是未来 3D 隐式曲面的主流基线方案之一。

### 6) adaptive curve sampling

- 针对显函数/参数曲线，按曲率、屏幕误差或局部变化动态加密采样点。
- 能显著改善“少点丢细节、多点浪费性能”的矛盾。
- 对 eMathica 定位：应作为 Sampling-2（增强层），不是 Sampling-1 基线。

---

## 三、架构决策

### 1) 不写万能 Sampler

采样必须按图形意图分类，不同对象走不同采样器。

### 2) 采样器按 GraphIntent 分类

- `ExplicitFunctionSampler2D`
- `ParametricCurveSampler2D`
- `PolarCurveSampler2D`
- `ImplicitCurveSampler2D`
- `ExplicitSurfaceSampler3D`
- `ParametricSurfaceSampler3D`
- `ImplicitSurfaceSampler3D`

### 3) 命名强制区分 2D / 3D

- `SamplePoint2D`
- `SampleSegment2D`
- `SampleSet2D`
- `SamplePoint3D`
- `SurfaceMesh`

### 4) 共享基础类型（SamplingCore 根目录）

- `SamplingRange`
- `SamplingIssue`

### 5) 2D 曲线专用选项

- `CurveSamplingOptions2D`

### 6) 3D 曲面专用选项（未来）

- `SurfaceSamplingOptions3D`

---

## 四、第一阶段实现建议（Sampling-1）

Sampling-1 仅做最小可用链路，不接 Plane 业务：

- `ExplicitFunctionSampler2D.sampleY`
- 均匀采样
- 用 `ExprEvaluator` 做单点求值
- `undefined` 断线
- `nonFinite` 断线
- 大跳跃断线（阈值规则）
- 输出 `SampleSet2D`

Sampling-1 明确不做：

- 自适应采样
- 隐函数
- 参数曲线
- 3D 曲面
- Plane 业务接入

---

## 五、未来路线图

- **Sampling-1**：2D 显函数基础均匀采样
- **Sampling-2**：2D 显函数自适应采样
- **Sampling-3**：2D 参数曲线/极坐标
- **Sampling-4**：2D 隐函数 marching squares
- **Sampling-5**：3D 空间曲线/显式曲面
- **Sampling-6**：3D 隐式曲面 marching cubes / dual contouring

---

## 六、边界要求（强约束）

- `ExprEvaluator` 只负责**单点求值**，不选择采样点
- `Sampler` 只负责**采样策略**，不实现数学函数求值
- `GraphClassifier` 只负责**图形意图分类**，不决定采样密度
- `Renderer` 只负责绘制 `SampleSet` / `Mesh`，不做数学分析
- Plane 旧采样器暂时保留
- 新 `SamplingCore` 不依赖 `WorkspaceKit` 或旧 `AlgebraCore`

---

## 七、采样质量档位设计

eMathica 建议提供 4 个用户可选采样质量档位（默认 `balanced`）：

- `preview`（UI 名称：**极速预览**）
- `balanced`（UI 名称：**平衡**）
- `precise`（UI 名称：**高精度**）
- `exploratory`（UI 名称：**探索模式**）

### 档位含义（不是仅 sampleCount 差异）

- `preview`：
  - 固定均匀采样
  - 低采样数
  - 目标是输入实时反馈与低延迟
- `balanced`（默认）：
  - 均匀采样 + 轻量细分
  - 兼顾性能和形状完整性
- `precise`：
  - 屏幕误差/曲率驱动的自适应采样
  - 优先视觉精度和几何细节
- `exploratory`：
  - 实验策略组合：高频探测、断点候选点、`DomainAnalyzer` hints
  - 用于复杂表达式探索，不保证最低成本

### GraphIntent 维度的档位映射

同一质量档在不同 `GraphIntent` 下应映射到不同算法策略，而不是“一把尺子”：

- `explicitY` / `explicitX`
  - `preview`: 低密度均匀采样
  - `balanced`: 均匀 + 轻量细分
  - `precise`: 自适应曲率/误差控制
  - `exploratory`: 高频探测 + 断点候选增强

- `parametric2D`
  - `preview`: 低密度均匀参数步进
  - `balanced`: 均匀参数步进 + 局部细分
  - `precise`: 基于曲率/速度变化的自适应参数步进
  - `exploratory`: 参数域探测 + 拐点候选强化

- `polar`
  - `preview`: 低密度角度步进
  - `balanced`: 常规角度步进 + 局部细分
  - `precise`: 按屏幕误差进行角域自适应
  - `exploratory`: 原点邻域和高振荡角域增强探测

- `implicit2D`
  - `preview`: 粗网格 marching squares
  - `balanced`: 中等网格 + 局部重采样
  - `precise`: 细网格 + 多轮局部细化
  - `exploratory`: 多尺度网格 + 分支追踪候选

- `explicitSurface3D`
  - `preview`: 低分辨率规则网格
  - `balanced`: 中分辨率网格 + 轻量细分
  - `precise`: 误差驱动细分网格
  - `exploratory`: 多分辨率采样 + 局部异常探测

- `parametricSurface3D`
  - `preview`: 低密度参数网格
  - `balanced`: 中密度参数网格
  - `precise`: 参数域自适应细分
  - `exploratory`: 参数域多尺度探测 + 奇异区候选

- `implicitSurface3D`
  - `preview`: 粗体素 marching cubes
  - `balanced`: 中体素 marching cubes
  - `precise`: 细体素 + 局部重建（可结合 dual contouring）
  - `exploratory`: 多尺度体素 + 拓扑敏感探测

### 交互期临时降级策略

交互期间应允许临时降级到 `preview`，以保障流畅度：

- 用户输入中：使用 `preview`
- 拖动画布中：使用 `preview`
- 缩放中：使用 `preview`
- 停止交互后：恢复用户选择档位（默认 `balanced`）

### 建议后续代码结构

- `SamplingQualityProfile`
- `SamplingProfileResolver`
- `CurveSamplingOptions2D`
- `CurveSamplingAlgorithm2D`

并继续坚持 2D/3D 显式命名分层：

- `SampleSet2D`
- `SampleSet3D` 或 `SurfaceMesh`
- `ExplicitFunctionSampler2D`
- `ExplicitSurfaceSampler3D`

---

## 结论摘要

1. eMathica 采样应走“GraphIntent 分流 + 专用采样器”路线。  
2. Sampling-1 采用固定均匀采样作为稳定基线，先解决可用性与接口稳定性。  
3. 隐函数与 3D 必须单独算法线（marching squares / marching cubes），不能在显函数采样器里硬扩展。  
4. 架构上要严格分离 Classifier / Evaluator / Sampler / Renderer 职责，避免新旧链路再次耦合。  
