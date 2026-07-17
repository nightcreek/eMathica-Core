# eMathica Engineering Development Principles

Version 1.0

## Core Philosophy

eMathica 的开发遵循 `Reality First`，而不是 `Assumption First`。

任何修改必须建立在真实运行时行为（Reality）的基础上，而不是代码阅读后的推测。

所有开发都应遵循：

```text
Reality Audit
    ↓
Reality Trace（必要时）
    ↓
Root Cause Identification
    ↓
Minimal Fix
    ↓
Reality Validation
    ↓
Phase Complete
```

不得跳过任何关键阶段。

## Principle 1 — Reality Before Modification

任何 Bug、设计问题、架构问题：

先审计，再修改。

禁止：

```text
Read Code
↓
Guess Root Cause
↓
Modify
```

必须：

```text
Reality Audit
↓
Collect Evidence
↓
Identify Root Cause
↓
Modify
```

任何 Root Cause 必须有：

- Runtime Trace
- Production Call Graph
- Source Evidence

至少其中两项支撑。

## Principle 2 — Production Path First

任何审计优先分析：

- Production Runtime Path

而不是：

- Legacy
- Dead Code
- Tests
- Experimental Branch

所有结论必须说明：

- Production
- Transitional
- Legacy
- Dead

不能混为一谈。

## Principle 3 — Runtime Is the Source of Truth

源码说明设计，Runtime 才说明 Reality。

如果：

```text
Source != Runtime
```

一律相信：

```text
Runtime
```

例如：

- FormulaDisplayBridge
- Direction Navigation
- Hardware Keyboard

都必须以 Runtime 结果为准。

## Principle 4 — First Divergence

任何 Bug 必须回答：

第一处分叉点在哪里？

不要只看到最终 UI 表现，要找到：

预期状态与实际状态第一次开始偏离的位置。

## Principle 5 — Root Cause Must Be Unique

Root Cause 必须能够写成：

- Exact File
- Exact Type
- Exact Function
- Exact Condition
- Expected
- Actual

如果不能做到，说明 Root Cause 仍未锁定，继续审计，不要修改。

## Principle 6 — Minimal Fix

只修改 Root Cause。

不要：

- 顺手重构
- 顺手优化
- 扩大 Scope

每一轮最好是：

```text
One Root Cause
↓
One Fix
```

## Principle 7 — Stable Architecture

任何 Fix 不能破坏已经通过 Validation 的模块。

不要为了某个子系统的问题去动另一个已验证模块，除非有 Runtime Evidence。

## Principle 8 — Validation Is Mandatory

修改完成后必须做 Reality Validation。

包括：

- Real Device
- Real User Flow
- Real Interaction

以及：

- Unit Tests
- Package Tests
- Build
- Regression

二者缺一不可。

## Principle 9 — Debug Instrumentation

Runtime Trace 必须是 `DEBUG Only`。

要求统一前缀，例如：

- `[FormulaDirectionNavigationTrace]`
- `[HardwareKeyboardIngressTrace]`

Release 不得包含调试逻辑。

## Principle 10 — Every Phase Ends Cleanly

每个阶段结束必须输出：

- R1 Summary
- R2 Reality
- R3 Fix
- R4 Validation
- R5 Working Tree
- R6 Tests

并说明：

- Code modified
- Tests modified
- Production behavior changed
- Commit
- Push

不得省略。

## Principle 11 — Preserve Phase Boundaries

不同阶段不要混改。

例如：

- Direction Navigation 阶段结束以后，再开始 Hardware Keyboard

每个 Phase 只解决一个主题。

## Principle 12 — Working Tree Discipline

任何阶段都要保持 Working Tree 可解释。

允许保留上一阶段的 Debug Trace，但必须说明：

- 哪些是 Pre-existing
- 哪些是 New
- 哪些是 Temporary

禁止混入无关格式修改。

## Principle 13 — Production Over Tests

Tests 不能证明 Production，Tests 只能证明 Tests。

必须始终回答：

Production Reality 是什么？

例如：

- Tests 全过
- Production 仍然失败

最后要用 Runtime Trace 找到真正 Root Cause。

## Principle 14 — Large Features Must Be Layered

任何大型模块都采用：

```text
Audit
↓
Trace
↓
Minimal Fix
↓
Validation
↓
Next Layer
```

例如 Keyboard：

1. UI Framework
2. Semantic Mapping
3. Platform Integration

不要一次完成全部。

## Principle 15 — Never Skip Reality Validation

如果没有 Reality Validation，这一阶段不能认为完成。

任何“应该可以”都不是完成。

只有：

```text
Real Device
↓
Pass
```

才能 Phase Complete。

## Codex Working Rules

Codex 在 eMathica 项目中默认遵循：

1. 不猜测 Root Cause。
2. 不扩大修改范围。
3. 不跨 Phase 修改。
4. 不修改无关模块。
5. Runtime Reality 高于 Source Assumption。
6. Production 高于 Tests。
7. Root Cause 必须唯一。
8. Fix 必须最小。
9. Validation 必须真实。
10. 每轮开发都必须形成完整的审计、修复、验证闭环。

## Recommended Location

建议将本文件放在：

```text
eMathica/Documentation/development/EngineeringDevelopmentPrinciples.md
```

如果后续希望收束为更正式的贡献说明，也可以再整理进 `CONTRIBUTING.md` 的 Workflow 章节。
