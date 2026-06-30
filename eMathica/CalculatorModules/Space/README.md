# Space — 3D 空间计算器模块

> 三维空间几何模块。

## 职责

提供 3D 几何对象的渲染、交互和构造能力。当前处于早期开发阶段。

## 公共接口

- `SpaceWorkspaceModuleProvider` — 模块提供者

## 子模块

| 模块 | 说明 |
|------|------|
| Commands/ | 命令处理 |
| Services/ | 核心服务（几何解析、命中测试、线框渲染） |
| Tools/ | 工具定义 |
| Views/ | 视图层（`SpaceCanvasView`） |

## 功能状态

- 3D 线框渲染基础可用
- 基本命中测试实现
- 完整的几何解析器骨架
- 尚未形成完整的产品闭环

## 依赖

- EMathicaMathCore
- EMathicaWorkspaceKit
- EMathicaThemeKit

## 依赖此模块

无（Space 是终端计算器模块）
