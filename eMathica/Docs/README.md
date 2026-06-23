# Docs/ — 开发文档

> 最后更新: 2026-06-18
> Architecture Freeze: 生效中

---

## 这个目录是什么

`Docs/` 是 eMathica 项目的**开发文档**。记录每个模块的当前状态、已知问题、技术债务。

**与 AI/ 的关系：**

| 目录 | 角色 | 读者 |
|------|------|------|
| **Docs/** | 开发文档。当前状态、已知问题、审计诊断 | 开发者、QA |
| **AI/** | 项目知识库。架构、对象系统、路线图、产品设计 | AI Agent、新开发者、产品经理 |

**简单规则：** 想知道当前能不能跑、有什么 bug、哪个模块什么状态 → 读 `Docs/`。想理解项目全貌和架构 → 读 `AI/`。

---

## 目录结构

```
Docs/
├── README.md                           ← 你正在读的文件
│
├── Architecture/                        ← 仓库和包的整体架构状态
│   ├── RepositoryArchitectureStatus.md  ← 目录布局、App Target vs Package 关系
│   └── PackageArchitectureStatus.md     ← 5 个 Package 的当前状态、依赖图
│
├── Plane/                               ← Plane（2D 几何 + 函数绘图）模块
│   ├── PlaneCurrentStatus.md            ← MVP 完成度、E2E 功能环
│   ├── PlaneKnownIssues.md              ← 已知 bug 列表（P0/P1/P2）
│   ├── PlaneToolingHistory.md           ← 工具清单（17 个工具）、缺失工具
│   └── PlaneGeometryDependencyFailureAudit.md  ← 几何依赖系统失败用例诊断
│
├── Testing/
│   └── TestingStrategyStatus.md         ← 测试框架、46 个测试文件、Golden Fixture 计划
│
├── EMathicaGeoGebraCapabilityMatrix.md  ← eMathica vs GeoGebra 功能对标矩阵
├── SpacePostPlaneMVPPlan.md             ← Space 模块开发路线图
├── WorkspaceKitBoundaryFollowupAudit.md ← WorkspaceKit 边界泄露清单
├── WorkspacePlaneDecouplingPlan.md      ← WorkspaceKit-Plane 解耦方案
├── DerivativeMVPRetroactiveAudit.md     ← 导数 MVP 实现回顾
├── EquationSolvingArchitectureAudit.md  ← 方程求解架构设计
├── KeyboardLegacyCleanupAudit.md        ← 键盘遗留代码清理方案
│
└── archive/                             ← 历史审计文档（已吸收到当前文档,不再更新）
    ├── consolidated-2026-06-16/         ← 22 个已合并的历史文档
    └── pre-consolidation-2026-06-16/    ← 34 个合并前的原始审计文档
```

---

## 怎么读

### 新开发者阅读顺序

```
第1步 →  Architecture/RepositoryArchitectureStatus.md  ← 仓库长什么样
第2步 →  Architecture/PackageArchitectureStatus.md     ← 包怎么分的
第3步 →  Plane/PlaneCurrentStatus.md                   ← 核心模块状态
第4步 →  Plane/PlaneKnownIssues.md                     ← 有什么 bug
第5步 →  Testing/TestingStrategyStatus.md              ← 怎么测试
```

### 接手 Plane 模块

```
PlaneCurrentStatus.md      ← 整体状态
    ↓
PlaneToolingHistory.md     ← 工具有哪些
    ↓
PlaneKnownIssues.md        ← 有什么 bug
    ↓
PlaneGeometryDependencyFailureAudit.md  ← 依赖系统的具体问题
```

### 接手 Space 模块

```
SpacePostPlaneMVPPlan.md   ← 当前状态 + 路线图
    ↓
WorkspaceKitBoundaryFollowupAudit.md  ← 边界泄露（影响 Space）
```

### 接手 WorkspaceKit

```
WorkspaceKitBoundaryFollowupAudit.md  ← 当前的边界泄露
    ↓
WorkspacePlaneDecouplingPlan.md       ← 解耦方案
```

### 查功能对标

```
EMathicaGeoGebraCapabilityMatrix.md   ← eMathica vs GeoGebra
```

---

## 每个文件的职责

### Architecture/ — 架构状态

| 文件 | 回答什么问题 | 什么情况下更新 |
|------|-------------|---------------|
| `RepositoryArchitectureStatus.md` | 仓库目录怎么组织的？App Target 和 Package 什么关系？Architecture Freeze 什么状态？ | 目录结构调整或 Freeze 状态变更时 |
| `PackageArchitectureStatus.md` | 5 个 Package 各是什么角色？依赖图长什么样？哪些包在 Xcode 中已采纳？ | Package 增删或依赖关系变更时 |

### Plane/ — 平面几何模块

| 文件 | 回答什么问题 | 什么情况下更新 |
|------|-------------|---------------|
| `PlaneCurrentStatus.md` | Plane MVP 到什么程度了？E2E 功能闭环通了吗？UI 打磨到什么程度？紧凑布局？函数命名？ | 每个开发迭代后 |
| `PlaneKnownIssues.md` | 当前有哪些 bug？哪些是 P0 阻塞？哪些是 P1 必须在 v1.0 前修？哪些测试挂了？ | 发现新 bug 或修 bug 后 |
| `PlaneToolingHistory.md` | Plane 有哪些工具（17 个）？每个工具什么状态？哪些工具还没做？ | 新增或大改工具时 |
| `PlaneGeometryDependencyFailureAudit.md` | 几何依赖系统（中点、交点、平行/垂线、圆弧、删除源对象、保存重开）有哪些失败用例？根因是什么？ | 依赖系统大修后 |

### Testing/ — 测试策略

| 文件 | 回答什么问题 | 什么情况下更新 |
|------|-------------|---------------|
| `TestingStrategyStatus.md` | 测试怎么组织的？46 个测试文件涵盖什么？Golden Fixture 到哪了？MathCore 测试在 App Target 和 Package 间重复了吗？ | 测试策略调整或大规模新增测试后 |

### 根目录独立文档

| 文件 | 回答什么问题 | 类型 |
|------|-------------|------|
| `EMathicaGeoGebraCapabilityMatrix.md` | eMathica 的 Plane/Space/MathCore 功能覆盖对标 GeoGebra 到什么程度？当前基线是什么？差距在哪？ | 对标分析 |
| `SpacePostPlaneMVPPlan.md` | Space 模块当前 v0.1 骨架状态、bugfix-only 模块、暂缓模块、v0.2 目标、曲面绘制路线、启动条件 | 路线图 |
| `WorkspaceKitBoundaryFollowupAudit.md` | WorkspaceKit 中还有哪些 Plane/Space 专属逻辑泄露过边界？（16+ 处泄露清单，含风险评估） | 技术债务 |
| `WorkspacePlaneDecouplingPlan.md` | 怎么消除 WorkspaceKit 对 CalculatorModules/Plane 的反向依赖？（协议注入方案，含迁移步骤） | 设计方案 |
| `DerivativeMVPRetroactiveAudit.md` | 已完成的导数 MVP 是如何在 MathCore 和 Plane 间分层的？Expr AST → Simplifier → Differentiator → 桥接 → Plane 函数管道每个环节什么状态？ | 回顾审计 |
| `EquationSolvingArchitectureAudit.md` | 方程求解应该放在哪一层？MathCore 现有求解能力如何？MVP 范围是什么？结果类型怎么设计？怎么接入 Plane？ | 设计方案 |
| `KeyboardLegacyCleanupAudit.md` | 哪些键盘/输入文件可以删？（5 个遗留文件清单 + 替换方案 + 调用点迁移计划） | 清理方案 |

---

## 与 AI/ 的分工

| 问题 | 读哪个 |
|------|--------|
| 项目当前什么架构？ | `AI/Core/Architecture.md` |
| 有什么 ObjectKind？ | `AI/Core/ObjectSystem.md` |
| P0–P4 做什么？ | `AI/Core/Roadmap.md` |
| 每个 Calculator 是什么产品？ | `AI/ProductDesign/` |
| 有哪些能力？ | `AI/Data/CapabilityRegistry.json` |
| 仓库目录怎么组织的？ | `Docs/Architecture/RepositoryArchitectureStatus.md` |
| 包怎么分的？ | `Docs/Architecture/PackageArchitectureStatus.md` |
| Plane 当前什么状态？ | `Docs/Plane/PlaneCurrentStatus.md` |
| Plane 有什么 bug？ | `Docs/Plane/PlaneKnownIssues.md` |
| WorkspaceKit 有什么问题？ | `Docs/WorkspaceKitBoundaryFollowupAudit.md` |
| 测试怎么跑？ | `Docs/Testing/TestingStrategyStatus.md` |

---

## archive/ — 历史文档

```
archive/
├── consolidated-2026-06-16/     ← 22 个文档。是 Docs/ 重组时合并的源文档。
│                                  现已吸收到 Architecture/、Plane/、Testing/ 中。
│                                  仅供历史参考，不反映当前状态。
│
└── pre-consolidation-2026-06-16/ ← 34 个文档。Docs/ 重组前的原始审计文档。
                                    已全部被当前活跃文档取代。
                                    仅供历史参考，不反映当前状态。
```

**规则：** `archive/` 中的文档**冻结不再更新**。当前真相在活跃文档中。
