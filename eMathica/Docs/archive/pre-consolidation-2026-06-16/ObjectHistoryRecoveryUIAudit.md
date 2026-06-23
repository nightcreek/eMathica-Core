# ObjectHistoryRecovery-1B UI 审计与交互设计（仅文档）

## 1. UI Entry Audit

### 1.1 当前可用入口结构

1. 文档菜单入口已存在：`WorkspaceView` 内 `DocumentMenuButton`（`Menu`）。
2. 顶层全局确认弹窗机制已存在：`WorkspaceView` 的 `.confirmationDialog(...)`（当前用于删除关联对象、恢复到打开时状态）。
3. 对象区是行级操作为主：`AlgebraObjectPanelView` + `WorkspaceObjectRowView`，目前没有“对象区全局列表管理”入口。
4. Inspector 目前是“当前选中对象 / 画布 / 计算器”上下文，不适合作为 deleted history 主入口。
5. sheet 复用能力已存在：`WorkspaceView`（重命名 sheet）与 `AlgebraObjectPanelView`（slider settings sheet）均采用标准 SwiftUI sheet 模式。

### 1.2 最小风险入口推荐

**推荐主入口：文档菜单（DocumentMenuButton）**

- 菜单项：`恢复已删除对象`
- 触发后打开一个 sheet（历史列表）
- 原因：
  - 全局语义正确（文件级能力，不是单对象能力）
  - 与“返回首页/重命名/恢复到打开时状态”同层级，用户心智一致
  - 不影响对象区行高与布局
  - 接入风险最低（现有 `WorkspaceView` 已承载全局 modal 与 dialog）

**不推荐作为主入口：Inspector**

- Inspector 是“当前选中对象”的细节面板，deleted history 是“文档级集合”。
- 放在 Inspector 会增加概念耦合，且用户必须先打开 Inspector 才能发现入口。

---

## 2. Deleted History List 设计（v1B）

### 2.1 列表标题与结构

- 标题：`已删除对象`
- 数据源：`document.deletedObjectHistory`（按时间逆序展示：最新在前）

### 2.2 列表项字段（最小集）

每条 `DeletedObjectRecord` 显示：

1. 对象名称（`object.name`）
2. 对象类型（`object.type.rawValue`）
3. 删除时间（短时间格式）
4. 删除来源（`context`）：
   - `userDelete` -> `手动删除`
   - `deleteAffected` -> `删除相关对象`
   - `unknown/nil` -> `未知`
5. 简短摘要（按类型）：
   - 点：`(x, y)`
   - 线段/直线/射线/圆：几何摘要或表达式摘要
   - 函数/表达式对象：`expression.displayText` 截断
6. 行内按钮：`恢复`

### 2.3 v1B 明确不做

- 不做缩略图
- 不做搜索
- 不做筛选
- 不做批量恢复
- 不做恢复组（batch）操作

---

## 3. Restore Interaction 设计

### 3.1 交互流程

点击 `恢复`：

1. 调用现有命令：`restoreDeletedObject(recordID:)`
2. 对象加入 active objects
3. 对应 history record 移除
4. 恢复对象设为选中（推荐）
5. sheet 处理建议：
   - v1B 推荐保持列表打开（便于连续恢复多个对象）
   - 可在恢复成功后轻量提示

### 3.2 视角行为建议

- **建议：恢复后自动选中对象**
  - 方便用户立刻在对象区/Inspector看到恢复结果。

- **建议：v1B 不自动移动画布到对象位置**
  - 自动定位会打断当前视角，尤其在批量回看历史时体验不稳定。
  - 如需定位可后置到 v1C（例如“恢复并定位”二级操作）。

---

## 4. Empty State

当 `deletedObjectHistory` 为空：

- 主文案：`没有可恢复的对象`
- 副文案：`删除的对象会保存在此处，最多保留最近 200 个。`

---

## 5. 是否提供“清空历史”

### 5.1 结论（v1B）

**不建议在 v1B 实现清空历史。**

理由：

1. 风险高（清空后不可恢复）
2. 需要额外确认弹窗与误触防护
3. 当前目标是先打通“查看 + 单对象恢复”闭环

### 5.2 后续阶段

- v1C/v1D 再加：
  - `清空已删除对象历史`
  - 二次确认
  - 可选“仅清理最旧记录/按来源清理”

---

## 6. 与 Undo/Redo 的关系（文案与认知）

应明确区分：

1. **Undo/Redo**：会话内撤销/重做。
2. **恢复已删除对象**：文件级历史池恢复（跨会话可用）。

恢复动作本身仍是 undoable：

- Undo restore：对象从 active list 移除，record 回到 history（由 snapshot 机制自然恢复）。
- Redo restore：对象再次恢复，record 再次移除。

文案建议避免“撤销删除”字样，统一用“恢复已删除对象”。

---

## 7. 文案建议（v1B）

### 7.1 入口与标题

- 菜单入口：`恢复已删除对象`
- 列表标题：`已删除对象`

### 7.2 操作按钮

- 行内按钮：`恢复`

### 7.3 空状态

- `没有可恢复的对象`
- `删除的对象会保存在此处，最多保留最近 200 个。`

### 7.4 说明文本

- `恢复后的对象会作为独立对象加入当前文档。`

---

## 8. 推荐实现分期

### ObjectHistoryRecovery-1B

1. 文档菜单入口
2. deleted history sheet 列表
3. 单对象恢复
4. 空状态
5. 恢复后选中对象
6. 不做 clear history / batch restore

### ObjectHistoryRecovery-1C

1. 清空历史
2. 批量恢复
3. 恢复组（batch）能力
4. 可选“恢复并定位”

### ObjectHistoryRecovery-1D

1. 搜索/筛选
2. 按类型/来源分组
3. 高级恢复选项（例如恢复动态关系）

