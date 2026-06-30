# Docs

> eMathica 的当前开发文档入口。

`Docs/` 只保存当前有效的开发、测试和模块状态文档。
已完成的 audit / report / plan 不应长期保留在这里；如果需要长期参考，应写入更稳定的活跃文档中，而不是继续堆在 `Docs/` 入口下。

## 当前有效文档

| 文档 / 目录 | 内容 | 说明 |
|---|---|---|
| `Architecture/` | 仓库级架构状态与当前边界说明 | 仅保留当前有效的架构入口，历史快照不在这里长期保留 |
| `Plane/` | Plane 当前状态与已知问题 | 当前主模块的开发文档 |
| `Testing/` | 测试策略与基线 | 当前测试策略入口 |
| `EMathicaGeoGebraCapabilityMatrix.md` | eMathica 与 GeoGebra 的能力对标 | 当前能力参考文档 |

## 子目录

- `Architecture`
- `Plane`
- `Testing`

## 文档规则

- `Docs/` 只保留当前有效文档。
- 已完成的 audit / report / migration / phase / temporary plan 不长期保留。
- 归档性材料不应成为当前真相来源。
- package README 应放在各 package 自己的目录中。
