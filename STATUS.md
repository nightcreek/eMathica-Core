# Status — eMathica Core

> 当前项目状态。

## 当前版本状态

eMathica 仍处于持续开发中，但首页主链路已经完成 package 化收口：
`EMathicaHomeFeature` 负责 Home UI、Home state、layout、visual shell 和 action bridge。

## 已完成

- Plane MVP 主闭环
- HomeFeature package 化完成
- `SharedLibraries/` 作为当前物理 package root 明确化
- 资源冲突清理完成，App 构建恢复正常

## 当前活跃模块

| 模块 | 状态 | 说明 |
|------|------|------|
| Plane | Active | 当前主开发模块，继续推进功能与稳定性 |
| Home | Active | 已切换为 `EMathicaHomeFeature` package-backed 主屏幕 |
| Packages | Active | 继续维护 `SharedLibraries/` 下的 6 个 SwiftPM 包 |

## 近期约束

- 不推进 `ProjectPreviewRenderer` 的 package 化
- 不创建最终 `Packages/` taxonomy 目录
- 不重写 Xcode project 结构

## 构建状态

- `SharedLibraries/EMathicaHomeFeature`: `swift test` 通过
- `eMathica`: `xcodebuild` 通过

## 下一步建议

1. 先做文档治理和提交切分计划
2. 再继续 Plane / Space / MathInput 的后续阶段
3. 保持 HomeFeature package API 收口，不再回滚到 app target
