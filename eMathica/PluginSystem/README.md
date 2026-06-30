# PluginSystem — 插件系统

> 插件协议定义层。当前仅定义接口，无插件加载运行时。

## 职责

定义 eMathica 的插件系统协议，允许第三方扩展功能。

## 协议

| 文件 | 说明 |
|------|------|
| `PluginProtocol.swift` | 插件主协议 |
| `PluginManifest.swift` | 插件清单定义 |
| `PluginError.swift` | 插件错误类型 |
| `PluginResult.swift` | 插件结果类型 |
| `PluginPlaceholder.swift` | 插件占位实现 |

## 当前状态

协议接口已定义，但插件加载运行时尚未实现。

## 依赖

无（纯协议定义）

## 依赖此模块

- 各 Calculator 模块（未来）
