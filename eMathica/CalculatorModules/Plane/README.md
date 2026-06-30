# Plane — 平面几何计算器模块

> 2D 平面几何与函数绘图模块。

## 职责

提供二维几何对象的创建、编辑、构造和函数图形绘制能力。是 eMathica 当前最成熟的计算器模块。

## 公共接口

- `PlaneModule` — 模块入口
- `PlaneWorkspaceConfig` — 工作区配置
- `PlaneWorkspaceModuleProvider` — 模块提供者

## 子模块

| 模块 | 说明 |
|------|------|
| Commands/ | 命令处理（`PlaneCommandHandler`，52KB） |
| Interaction/ | 交互状态机（`PlaneInteractionState`, `PlaneInteractionReducer`, `PlaneConstructionMode`） |
| Rendering/ | 渲染（`ParametricCurveSampler`） |
| Services/ | 核心服务（几何解析、命中测试、草稿预览、依赖重算、交点求解等 15 个文件） |
| Tools/ | 工具定义（17 个工具的动作、ID、提供者） |
| Views/ | 视图层（画布视图 39KB，对象渲染视图 28KB 等） |

## 功能完成度（vs GeoGebra ~50%）

| 维度 | 完成度 |
|------|--------|
| 几何对象 | ~55% |
| 几何构造 | ~45% |
| 动态几何 | ~60% |
| 函数绘图 | ~70% |
| CAS/代数 | ~30% |
| 输入系统 | ~65% |
| 对象面板 | ~35% |
| 导出 | ~25% |

## 依赖

- EMathicaMathCore
- EMathicaWorkspaceKit（含断开的 PlaneGeometryStubs）
- EMathicaThemeKit

## 依赖此模块

无（Plane 是终端计算器模块）

## 设计约束

- 11 个测试因 WorkspaceKit 使用 `PlaneGeometryStubs` 替代真实 `PlaneGeometryResolver` 而失败
- 架构冻结期间不可修改包依赖

了解更多：`Docs/Plane/PlaneCurrentStatus.md` | `Docs/Plane/PlaneKnownIssues.md`
