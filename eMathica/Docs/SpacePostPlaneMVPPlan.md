# Space Post-Plane-MVP Plan

## 1. 当前状态

Space 当前已经具备一个可运行的 v0.1 骨架，能支撑基础 3D wireframe 工作流：

- `SpaceMathCore`
- `SpaceDocumentModel`
- `SpaceCanvas`
- `SpaceTools`
- `SpaceHitTest`
- `SpaceSnapping`
- `SpaceWorkPlane`
- `SpaceInspector`
- `SpacePreview`

从当前代码与既有验收文档看，Space 现阶段的主链路主要覆盖：

- 3D 对象：`point3D` / `segment3D` / `line3D` / `plane3D`
- 视角交互：`orbit` / `pan` / `zoom`
- 基础编辑：`select` / 最小 `snapping` / `work plane`
- 文档闭环：`save/load` / `preview` / `delete + recovery`

这意味着 Space 不是空壳，而是一个已经跑通 v0.1 核心闭环的骨架；但它仍然是以稳定性优先的阶段，不适合在 Plane MVP 未稳定前继续扩张能力面。

## 2. bugfix-only 模块

以下模块建议保持 bugfix-only，只接受崩溃修复、明显错误修复、稳定性修复和验收中发现的回归修复，不再继续扩核心功能：

- `SpaceMathCore`
- `SpaceDocumentModel`
- `SpaceCanvas`
- `SpaceTools`
- `SpaceHitTest`
- `SpaceSnapping`
- `SpaceWorkPlane`
- `SpaceInspector`
- `SpacePreview`

bugfix-only 的含义：

- 允许修复选择、命中、预览、保存/恢复、显示上的明显缺陷；
- 不在这一阶段新增新的 3D 表达式能力；
- 不在这一阶段引入新的交互范式；
- 不在这一阶段扩展到曲面、动态依赖或高级渲染路线。

## 3. 暂缓模块

以下能力建议先暂缓，不要在 Plane MVP 未稳定前插入到主开发队列：

- Space CAS
- `z=f(x,y)` 曲面
- 隐式曲面
- 参数曲面
- 3D dynamic geometry
- arbitrary work plane
- selected plane as work plane
- 3D drag editing
- SceneKit / Metal 渲染路线
- advanced snapping 可视化指示器
- 更复杂的对象关系编辑器
- 更细粒度的 3D 对象面板扩展

这些模块并不是“不要做”，而是“现在不要插入主线”。它们属于后续独立规划的能力面，应该等 Plane 的主闭环完全稳定后再分批推进。

## 4. v0.2 目标

Space v0.2 建议以“在 v0.1 骨架上补足稳定性与少量能力扩展”为目标，而不是一次性跳到曲面或高级几何系统。

推荐的 v0.2 目标顺序：

1. 稳定现有 v0.1 行为
   - 继续修复 `SpaceCanvas`、`SpaceHitTest`、`SpaceSnapping`、`SpacePreview`、`SpaceInspector` 的回归
   - 先把现有 3D wireframe 体验做稳

2. 完善基础几何交互
   - 更稳的命中、高亮、恢复、保存/读取一致性
   - 更明确的 work plane 切换与状态反馈

3. 再引入动态几何
   - 3D dependency
   - 由点、线、平面关系驱动的联动更新

4. 最后再评估更高阶表达式几何
   - 曲面
   - 参数曲线/曲面
   - 隐式曲面

## 5. 曲面绘制路线

Space 的曲面路线建议按风险从低到高分层推进：

### 5.1 第一层：离散化的静态曲面

- 从表达式或参数方程生成有限采样网格
- 先做可视化，不先做复杂编辑
- 只要求能正确显示、正确缩放、正确裁剪

### 5.2 第二层：参数曲面

- `u/v` 参数域采样
- 网格三角化或线框化显示
- 先确保渲染稳定，再考虑更复杂的交互

### 5.3 第三层：隐式曲面

- 从隐式方程生成等值面
- 优先选择稳定、可控的近似方案
- 这一步的风险最高，建议独立排期，不要和 Plane 主线并行推进

### 5.4 暂不建议的路线

- 直接切到 SceneKit / Metal 的全新渲染栈
- 一次性做“可编辑曲面 + 高阶依赖 + 高级采样”全链路

## 6. 与 Plane 的边界

### 6.1 应该共享的部分

Space 和 Plane 可以共享的，应该尽量只保留真正通用的基础设施：

- `DocumentSystem`
- 保存/加载框架
- preview 文件与项目包结构
- 通用工具栏/工作区壳层
- 通用命中/渲染/命令分发框架中的抽象接口
- 通用的对象面板/检查器骨架

### 6.2 不应该共享的部分

以下内容不建议强行共享，否则容易把 Plane 的不稳定性带进 Space，或把 Space 的 3D 语义拖进 Plane：

- Plane 专属函数输入、表达式预览、采样链路
- Space 专属相机、工作平面、3D 命中、3D 选择逻辑
- Plane 的 2D 对象命名、编辑、几何构造规则
- Space 的 3D 对象语义、plane3D / line3D / segment3D 的构造与恢复逻辑

### 6.3 共享原则

- 共享“壳层”和“文件系统”，不要共享“语义细节”
- 共享“接口”，不要共享“具体业务规则”
- 如果一个逻辑明显是 Plane 专属或 Space 专属，就不要放回 WorkspaceKit 核心壳层里硬共用

## 7. 启动 Space v0.2 的前置条件

在启动 Space v0.2 之前，Plane 至少需要满足以下条件：

1. Plane 的 create/edit 实时预览主闭环稳定
   - 输入函数
   - 看到实时预览
   - 回车创建对象
   - edit 预览与 create 预览一致

2. Plane 的对象创建/删除/选择主链路稳定
   - 点、线段、圆、圆弧、函数都能稳定创建
   - 删除工具和对象面板删除行为一致
   - 选择与拖拽不互相污染

3. Plane 的命名与保存链路稳定
   - 自动命名不重复
   - 显式函数名冲突策略一致
   - 保存/重开后对象表达式仍然正确

4. 首页缩略图链路稳定
   - `preview.png` 能正确生成
   - 首页卡片能稳定读取缩略图
   - 重开项目时不会因为预览链路引入额外风险

5. WorkspaceKit 边界继续保持收口
   - 不再新增更多 Plane/Space 专属逻辑回流到壳层
   - 共享层只保留最小必要接口

只要 Plane 仍处于回归修复和闭环收口阶段，Space v0.2 就不应该进入主开发队列；它最多保持 bugfix-only 和文档整理节奏。
