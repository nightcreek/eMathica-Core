# Testing Strategy Status

> 当前测试策略与验收入口。

## 当前测试层

- **App target tests**：Swift Testing / integration tests
- **Package tests**：各 `SharedLibraries/*/Tests` 中的 SwiftPM 测试
- **UI smoke tests**：最小启动与主流程检查
- **Golden fixtures**：Plane 主流程样例与预期结果

## 当前验证原则

每一次影响用户可见行为的改动，都至少应完成：

1. 相关 package 的 `swift test`
2. eMathica app 的 `xcodebuild` 构建
3. 如影响 Plane / Save-Load / 视觉输出，再补对应的 golden fixture 或回归样例

## 当前资产位置

- `eMathica/Tests/GoldenFixtures/Plane/2D_BasicGeometry/`
- `eMathica/Tests/GoldenFixtures/Plane/2D_ConstructionDependency/`
- `eMathica/Tests/GoldenFixtures/Plane/Function_CAS/`
- `SharedLibraries/EMathicaHomeFeature/Tests/EMathicaHomeFeatureTests/`

## 当前测试状态

- `SharedLibraries/EMathicaHomeFeature` 的 package 自测已可通过
- `eMathica` 的 app 构建已可通过
- 迁移型工作应继续保持“先 package test，再 app build”的顺序

## 规则

- 不把完成型 audit 当成长期测试策略来源
- 不把历史 archive 当成当前验收依据
- 测试文档应只描述当前有效的测试基线与验证方法
