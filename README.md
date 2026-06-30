# eMathica Core

> 数学创作，不止于计算。

eMathica 是主应用，负责 Plane、Space、Home、插件协议入口与应用级 composition。
它的定位不是单纯的计算器，而是一个以数学表达和创作为中心的 SwiftUI app。

## 当前状态

- Plane 仍是当前主开发模块。
- HomeFeature 已迁入 `SharedLibraries/EMathicaHomeFeature`。
- App target 继续承担 shell / navigation / concrete service composition。
- `SharedLibraries/` 是当前真实物理 package root。
- `Packages/shared/`、`Packages/emathica-only/`、`Packages/openmathink-only/` 只是未来 taxonomy 目标，不是当前事实。

## 当前目录结构

```
eMathica/
├── App/                  ← App shell 与 composition
├── CalculatorModules/    ← Plane / Space / 占位模块
├── CoreHome/             ← 仅保留少量 app-private 支撑文件
├── Docs/                 ← 当前有效开发文档
├── AI/                   ← 长期知识库
├── PluginSystem/         ← 插件协议
└── Tests/                ← 集成测试与 Golden Fixtures

SharedLibraries/
├── EMathicaMathCore/
├── EMathicaDocumentKit/
├── EMathicaThemeKit/
├── EMathicaMathInputKit/
├── EMathicaWorkspaceKit/
└── EMathicaHomeFeature/
```

## App-as-shell / Package-first

- App target 负责导航、状态拼装和 concrete service 注入。
- 可复用逻辑优先落在 SharedLibraries 中。
- HomeFeature 这条首页主链路已经转为 package-backed。
- `ProjectPreviewRenderer` 与 `LocalProjectStore` 继续留在 app-private 边界。

## 主要 package

- `EMathicaMathCore`：数学引擎核心
- `EMathicaDocumentKit`：文档模型与持久化协议
- `EMathicaThemeKit`：主题与视觉系统
- `EMathicaMathInputKit`：数学输入系统
- `EMathicaWorkspaceKit`：工作区基础设施
- `EMathicaHomeFeature`：首页 feature package（eMathica-only）

## 如何打开

1. 打开 `eMathica.xcodeproj`
2. 选择 `eMathica` scheme
3. 运行 iPad 或 macOS 目标

## 文档阅读顺序

1. `AI/README.md` — AI 知识库入口
2. `AI/Core/Architecture.md` — 当前架构真相
3. `AI/Core/Roadmap.md` — 当前路线图
4. `Docs/README.md` — 当前开发文档入口
5. `SharedLibraries/README.md` — 包根目录入口
