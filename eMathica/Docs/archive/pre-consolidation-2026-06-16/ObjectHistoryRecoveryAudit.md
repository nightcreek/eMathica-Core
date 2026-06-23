# ObjectHistoryRecovery-1A 审计与设计（仅文档）

## 1. Current State Audit

### 1.1 文档模型与 `.emathica` 存储

当前 `EMathicaDocument` 主字段：
- `id`
- `metadata`
- `moduleID`
- `objects`（active objects）
- `canvasState`
- `packageStructure`

当前 `.emathica` 包结构（本地目录包）：
- `metadata.json`
- `document.json`
- `preview.png`

`document.json` 当前编码的是完整 `EMathicaDocument`，其中并没有 trash/history/archive 字段。  
`LocalProjectStore` 直接使用 `EMathicaPackageCodec` 对 document 编解码。  
`ProjectPreviewRenderer` 仅从 `document.objects` 构建预览。

结论：
- 当前没有“已删除对象恢复池”。
- 给 `EMathicaDocument` 增加 **optional** history 字段在 Codable 上是兼容的。
- 旧文档缺失该字段时应 decode 为 `nil` 或 `[]`。

### 1.2 删除链路

删除入口：
- 单删：`WorkspaceState.dispatch(.deleteObject(id:))`
- 批删：`dispatch(.deleteObjects(ids:))`
- 选中删除：`dispatch(.deleteSelectedObjects)` -> 先走确认策略

删除策略：
- `unlink`：仅删 selected；后续 cleanup 将直接依赖对象转独立。
- `delete affected`：删 selected + downstream recursive derived（当前已实现递归）。

删除执行：
- 模块层产出 `DocumentCommand.deleteObject/deleteObjects`。
- `WorkspaceState` 在 `document.apply` 前可拿到完整对象快照。
- `document.apply` 后会触发：
  - source-removal cleanup（清 dependency/status）
  - dependency recompute（按 changed sources）

结论：
- 删除前可以稳定拿快照，适合记录 history。
- 当前代码还没有“删除原因”统一枚举与透传。

### 1.3 Undo/Redo 边界

当前 `WorkspaceSessionHistory`：
- `openBaseline`
- `undoStack` / `redoStack`
- 只在内存，关闭文件后丢失，不写入 `.emathica`。

Undo/Redo 机制是 snapshot before/after 整文档恢复。  
因此一旦将 deleted-history 放入 `EMathicaDocument`，Undo/Redo 会自然一起回滚/重做。

结论：
- session undo 与 file-level history 是两层能力，边界清晰。
- 需要避免“在 redo/undo 过程中重复追加 history 记录”。

---

## 2. Undo vs ObjectHistoryRecovery Boundary

- Undo/Redo：
  - 目标是“撤销本次会话操作序列”。
  - 时间范围：当前打开会话。
  - 存储位置：内存。

- ObjectHistoryRecovery：
  - 目标是“恢复历史删除对象（跨会话）”。
  - 时间范围：持久历史池（最近 N 条）。
  - 存储位置：`document.json`（建议）。

不冲突原则：
1. 删除动作写入历史池（文档字段）。
2. Undo/Redo 只做 snapshot 切换，不额外“再写一笔历史”。
3. 恢复动作自身应是可 undo 的文档变更。

---

## 3. Proposed Data Model

## 3.1 简化模型（推荐 v1A）

```swift
struct DeletedObjectRecord: Codable, Hashable, Identifiable {
    var id: UUID
    var deletedAt: Date
    var object: MathObject
    var context: DeletedObjectContext?
}

enum DeletedObjectContext: String, Codable, Hashable {
    case userDelete
    case deleteAffected
    case unknown
}
```

文档字段建议：

```swift
var deletedObjectHistory: [DeletedObjectRecord]?
```

理由：
- 足够支持“恢复被删除对象”。
- 编码简单、兼容旧文档。
- context 可先弱化，后续逐步细化。

## 3.2 富模型（后续）

可扩展字段：
- `batchID`
- `sourceSelectionIDs`
- `relatedObjectIDs`
- `moduleID`
- `sequence`

建议留到 1C/1D，避免 1A 过重。

---

## 4. Capacity Policy（200 条）

策略：
1. 新记录 append 到末尾（时间正向）。
2. 若 `count > 200`，删除最旧（从头 trim）。
3. 批量删除按“实际删除顺序”逐条追加。
4. `delete affected` 可在 v1A 先逐条记录；v1C 再引入 batchID 组恢复。

这满足“最近 200 个删除对象”并控制文件体积。

---

## 5. Restore Policy

## 5.1 ID 冲突

- 若原 ID 未占用：优先复用原 ID。
- 若冲突：生成新 ID。
- v1A 不做复杂跨对象引用重写（因为恢复默认转独立对象）。

## 5.2 dependency 缺失

v1A 推荐：**一律恢复为独立对象**
- 清 `geometryDependency`
- 清 `geometryDefinitionStatus`
- 保留：
  - `position/points/geometryDefinition`
  - `expression/style/name/isVisible`

理由：
- 避免 source 不全导致悬挂依赖混乱。
- 行为可预期、风险最低。

## 5.3 source 仍存在

即使 source 还在，v1A 也先恢复为独立对象。  
“恢复动态关系”放 v1C 后续能力。

---

## 6. Interaction with Active Document / Preview

history objects 必须与 active list 隔离：
1. 不参与渲染。
2. 不参与 hit test。
3. 不进入 object panel active list。
4. 不参与 dependency recompute/cleanup。
5. 不参与 project preview。

实现路径上应保持：
- preview renderer 只读取 `document.objects`（当前就是这样）。
- history 只作为附加池，不并入 active objects。

---

## 7. Command Design Suggestion (for implementation phase)

WorkspaceCommand（建议）：
- `restoreDeletedObject(recordID: UUID)`
- `clearDeletedObjectHistory`
- `removeDeletedObjectRecord(recordID: UUID)`（可选）

DocumentCommand（建议）：
- `appendDeletedObjectRecords([DeletedObjectRecord])`
- `trimDeletedObjectHistory(maxCount: Int)`
- `restoreDeletedObject(recordID: UUID, object: MathObject)`

也可先不扩 `DocumentCommand`，在 `WorkspaceState` 里组合 update metadata/document 字段。  
但长期更建议 command 化，便于测试与审计。

---

## 8. Undo/Redo Interaction Rules

建议规则：
1. 删除对象：
   - active object 删除；
   - history 追加记录；
   - 作为同一 undo step。

2. Undo 删除：
   - 恢复到 before snapshot；
   - history 也回到 before（自动一致）。

3. Redo 删除：
   - 恢复到 after snapshot；
   - history 恢复包含该记录（不再重复 append）。

4. 恢复 deleted object：
   - active list 新增对象；
   - 该记录可选择移除或标记已恢复（v1A 推荐移除）；
   - 整体应 undoable。

5. Revert-to-open-state：
   - 回到 baseline，包括 baseline 时的 history 内容。

---

## 9. Risks

P0/P1 风险点：
1. 文件体积增长（history 存完整 MathObject）。
2. 恢复时 ID 冲突。
3. 恢复 dependency 导致 missingSource 混乱（v1A 通过“恢复独立对象”规避）。
4. delete affected 大批量删除产生大量记录。
5. undo/redo 流程里重复写 history（需 guard `isApplyingHistorySnapshot` 语义）。
6. Codable 兼容（旧文档缺字段必须安全）。
7. preview/渲染误读 history（需严格只读 active objects）。

---

## 10. Implementation Phases

### ObjectHistoryRecovery-1A
- `EMathicaDocument` 增加 optional history 字段。
- 删除时记录对象快照。
- 上限 200 trim。
- 保存/打开 roundtrip。
- 先不做 UI 或仅内部调试入口。
- 恢复对象默认转独立。

### ObjectHistoryRecovery-1B
- 恢复 UI（列表 + 单对象恢复）。
- 恢复操作 undoable。

### ObjectHistoryRecovery-1C
- batchID / 批量恢复。
- 关联对象组恢复。
- 可选恢复动态关系。

### ObjectHistoryRecovery-1D
- 历史管理（清空、筛选）。
- 文件体积策略（压缩/精简上下文）。
