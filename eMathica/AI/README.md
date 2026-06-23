# eMathica — AI Knowledge Base

> 最后更新: 2026-06-18
> Architecture Freeze: 生效中

---

## 这个目录是什么

`AI/` 是 eMathica 项目的**知识库**。目标：任何一个 AI Agent 或新开发者,只需阅读这个目录就能理解项目全貌。

不是审计报告堆积区。不是设计草稿箱。是**项目真相的唯一来源**。

---

## 目录结构

```
AI/
├── README.md                 ← 你正在读的文件
│
├── Core/                     ← 项目架构真相（怎么做的）
│   ├── Architecture.md       ← 四层架构、Calculator 定义、Package 分层、风险
│   ├── ObjectSystem.md       ← 38 种 ObjectKind、Object Header、转换引擎
│   └── Roadmap.md            ← P0–P4 优先级、阶段状态、下一步做什么
│
├── Data/                     ← 机器可读数据
│   └── CapabilityRegistry.json  ← 全部 80 条能力注册表（Schema v1.0.0）
│
├── ProductDesign/            ← 产品设计文档（做什么）
│   ├── README.md             ← 产品设计文档入口
│   ├── Calculators.md        ← 6 个 Calculator 模块的产品定义
│   ├── ObjectKinds.md        ← 38 种数学对象的产品定义
│   └── PlaneDesign.md        ← Plane Calculator 完整产品设计（函数、列表、手绘、区域、样式、动画、导出）
│
├── temp/                     ← 临时参考文档（任务完成后删除）
│   ├── R1_CalculatorRealityAudit.md     ← 6 个 Calculator 真实代码现状
│   ├── R2_PackageRealityAudit.md        ← 5 个 Package 真实磁盘现状
│   └── R3_CapabilityCoverageAudit.md    ← 80 条能力注册表 vs 真实代码对照
│
└── archive/                  ← 历史审计文档（已吸收到 Core，不再更新）
    ├── Audits/               ← 8 个历史审计报告
    ├── Design/               ← 5 个历史设计文档
    └── temp/                 ← (空)
```

---

## 怎么读

### 新开发者 / 新 AI Agent 阅读顺序

```
第1步 → Core/Architecture.md     ← 理解项目怎么搭的
第2步 → Core/ObjectSystem.md     ← 理解项目操作什么数据
第3步 → Core/Roadmap.md          ← 理解现在该做什么
第4步 → ProductDesign/Calculators.md  ← 理解产品有哪些功能模块
第5步 → Data/CapabilityRegistry.json  ← 查具体能力细节
```

### 产品经理 / 设计师 阅读顺序

```
第1步 → ProductDesign/README.md       ← 产品设计文档入口
第2步 → ProductDesign/Calculators.md   ← 每个 Calculator 做什么
第3步 → ProductDesign/PlaneDesign.md   ← Plane 的完整产品设计
第4步 → ProductDesign/ObjectKinds.md   ← 支持哪些数学对象类型
第5步 → Core/Roadmap.md               ← 当前进度和下一步
```

### 想了解真实代码现状

```
temp/R1_CalculatorRealityAudit.md  ← Calculator 真实代码 vs Roadmap
temp/R2_PackageRealityAudit.md     ← Package 真实磁盘 vs Architecture.md
temp/R3_CapabilityCoverageAudit.md ← Registry 标注 vs 实际代码
```

---

## 每个文件的职责

### Core/ — 项目架构真相

| 文件 | 回答什么问题 | 什么情况下更新 |
|------|-------------|---------------|
| `Architecture.md` | 项目是什么架构？四层怎么分层？Calculator 是什么？当前有哪些风险？ | 架构审计发现结构性变化时 |
| `ObjectSystem.md` | 有哪些 ObjectKind？Object 有哪些字段？怎么转换？trans.json 是什么？ | ObjectKind 树、Header、转换模型变更时 |
| `Roadmap.md` | P0–P4 各阶段做什么？当前在哪个阶段？下一阶段是什么？ | 阶段完成或优先级重排时 |

### Data/ — 机器可读数据

| 文件 | 回答什么问题 | 什么情况下更新 |
|------|-------------|---------------|
| `CapabilityRegistry.json` | 项目有哪些能力？哪些已实现、部分实现、计划中？ | 能力新增、废弃、状态变更时 |

### ProductDesign/ — 产品设计文档

| 文件 | 回答什么问题 | 什么情况下更新 |
|------|-------------|---------------|
| `README.md` | 产品设计文档怎么读？与 Core 文档什么关系？ | 产品设计流程变更时 |
| `Calculators.md` | Plane/Space/Data/Music/Notes/Modeling 各是什么？用户能用它们做什么？ | 新 Calculator 上线或旧 Calculator 大幅改版时 |
| `ObjectKinds.md` | 每个 ObjectKind 对用户意味着什么？哪些是数学概念、哪些是 UI 概念？ | ObjectKind 树变更时 |
| `PlaneDesign.md` | Plane 的完整产品蓝图是什么？函数系统怎么设计？列表、手绘拟合、区域填色怎么做？样式系统、动画、导出什么方向？ | Plane 产品方向调整时 |

### temp/ — 临时参考文档

| 文件 | 说明 | 何时删除 |
|------|------|---------|
| `R1_CalculatorRealityAudit.md` | 6 个 Calculator 逐文件真实代码审计 | 代码大改导致审计过时后 |
| `R2_PackageRealityAudit.md` | 5 个 Package 磁盘现状 + DocumentSystem/ 重复分析 | 同上 |
| `R3_CapabilityCoverageAudit.md` | 80 条能力 vs 真实代码对照，标注 mismatch | Registry 更新后可删除 |

### archive/ — 历史文档

`archive/Audits/` 和 `archive/Design/` 中的 13 个文档是**已完成的审计报告和设计提案**。它们的结论已完全吸收到 `Core/` 文档中。

可以查阅,但**不应作为当前真相来源**使用。当前真相在 `Core/` 中。

---

## 文档治理规则

### 三类文档

| 类型 | 位置 | 规则 |
|------|------|------|
| **永久文档** | `Core/`、`Data/`、`ProductDesign/` | 审计发现新信息后**更新**,不替换 |
| **临时文档** | `temp/` | 存放进行中的审计、分析。任务完成后 14 天内删除 |
| **归档文档** | `archive/` | 已完成的审计报告和设计提案。结论已吸收,冻结不再更新 |

### 核心原则

```
审计  →  更新 Core 文档  →  删除 temp 文档  →  归档审计报告
```

**不是：**

```
审计  →  新增永久文档
```

### 什么情况下可以新增 Core 文档？

几乎永远不允许。如果发现 Core 文档无法描述的**全新架构维度**,需要项目负责人明确批准。

### Roadmap 怎么维护？

| 时机 | 操作 |
|------|------|
| 完成一个 P 阶段 | 更新 Phase Status 表,标记完成 |
| 发现阻塞 | 更新 P 阶段说明,记录阻塞原因 |
| 重新分类任务 | 更新 Priority Stack 和受影响的章节 |
| 每季度 | 审查所有 P 任务是否仍然相关 |

### CapabilityRegistry 怎么维护？

| 时机 | 操作 |
|------|------|
| 新增能力 | 添加新条目 |
| 能力状态变更 | 更新 `status` 和 `testStatus` |
| 废弃能力 | 设置 `deprecated: true` |
| 每季度 | 审查 `testStatus`、`priority`、`deprecated` 准确性 |

---

## 与 Docs/ 的关系

| 目录 | 角色 | 读者 |
|------|------|------|
| `AI/` | 项目知识库。架构、产品设计、路线图 | AI Agent、新开发者、产品经理 |
| `Docs/` | 开发文档。当前状态、已知问题、测试策略 | 开发者、QA |

**简单规则：** 想理解项目全貌 → 读 `AI/`。想了解具体模块的当前开发状态 → 读 `Docs/`。
