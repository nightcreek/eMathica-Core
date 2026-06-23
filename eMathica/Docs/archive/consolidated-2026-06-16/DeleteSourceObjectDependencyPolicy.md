# Delete Source Object Dependency Policy

## 1. 本轮是否修改源码

否。

本轮只新增删除源对象依赖策略设计文档，不修改任何 Swift 源码、测试源码、项目配置或目录结构。

## 2. 背景与问题

当前 Plane 几何依赖主线已经具备以下基础：

- 依赖对象通过 `geometryDependency` 保存源对象引用
- 源对象变化后，派生对象可通过重算服务更新
- 删除源对象后，当前实现已经不是“未定义状态”，而是存在实际行为
- `PlaneGeometryDependencyTests` 已经全绿

但当前仍缺一份正式冻结的产品语义，用来回答这几个核心问题：

1. 删除源对象后，派生对象是删除、保留、静态化，还是进入 undefined？
2. 不同入口是否应采用相同策略？
3. `save/reopen` 应如何持久化删除结果？
4. `Plane-2D-ConstructionDependency` 和 `SaveLoad-GeometryDependency` fixture 后续应以哪条语义验收？

如果这一步不先冻结：

- 测试会继续混用不同假设
- save/load 修复没有统一目标
- Golden Fixture 无法写出稳定预期
- Plane Beta 到 Plane v1 的删除体验会持续漂移

## 3. 当前实现与已有策略

### 3.1 当前实现里已经存在的两条策略

当前仓库里，删除依赖相关对象并不是完全空白，而是已经存在两条明确路径：

1. `unlink`
   - 删除源对象
   - 保留受影响派生对象
   - 清除派生对象的 `geometryDependency`
   - 清除派生对象的 `geometryDefinitionStatus`
   - 结果等价于“保留最后有效几何值并转为独立静态对象”

2. `deleteAffected`
   - 删除源对象
   - 再删除相关依赖对象
   - 当前实现使用 `downstreamAffectedDerivedObjectIDs(...)`
   - 也就是当前代码路径偏向“递归 downstream”删除，而不是只删 direct dependents

### 3.2 当前入口并不完全一致

当前删除入口至少有三类：

1. 对象区 / ObjectPanel 删除
   - 通过 `WorkspaceView.requestDeleteObjects(...)`
   - 最终进入 `WorkspaceState.requestDeleteObjectsWithConfirmation(_:)`
   - 当存在受影响派生对象时，会弹出确认对话框

2. 批量删除 / `deleteSelectedObjects`
   - 同样进入 `requestDeleteObjectsWithConfirmation(_:)`
   - 目前也会出现 `unlink / deleteAffected` 选择

3. Plane 画布 delete 工具
   - 当前仍直接 `dispatch(.deleteObject(id: ...))`
   - 会走删除与 cleanup
   - 但不经过依赖确认对话框

### 3.3 当前实现已经提供的语义证据

从现有测试和代码可以确认：

- 删除中点源点后，中点会保留并静态化
- 删除平行线的参考对象或过点后，派生线会保留并静态化
- 删除交点源对象后，交点会保留并静态化
- `deleteAffected` 相关测试已经覆盖“删源对象 + 删直接相关对象 + 下游对象静态化”
- 历史记录文案已经区分：
  - `手动删除`
  - `删除相关对象`

### 3.4 当前实现的不足

虽然已有双策略，但仍存在几个没有冻结的点：

- 当前 `deleteAffected` 用的是 downstream closure，删除爆炸半径偏大
- ObjectPanel / batch delete 与 delete tool 入口不一致
- 当前没有正式规定哪些对象类型应默认支持 `unlink`
- 当前没有正式规定函数 / slider / 未来 3D 对象是否沿用同一语义
- 当前没有正式规定 `undo/redo` 的未来接入标准

## 4. 策略比较

### 策略 A：级联删除 `deleteAffected`

**定义**

- 删除源对象时，同时删除所有相关派生对象

**优点**

- 语义简单
- 不会留下失去依赖的对象
- save/load 结果容易理解

**缺点**

- 对创作型工作流过于粗暴
- 用户可能一删就是一整串对象
- 批量删除和小屏确认体验会变重

**结论**

- 不适合作为 eMathica 的唯一默认策略

### 策略 B：保留 orphan / undefined

**定义**

- 删除源对象时，派生对象仍保留，但显示为 undefined / noSource

**优点**

- 用户能看到依赖断裂
- 未来可以考虑重新绑定源对象

**缺点**

- UI 和 save/load 复杂度明显增高
- ObjectPanel / Inspector / preview / thumbnail 都要定义 undefined 展示
- 对当前 Plane Beta 来说过重

**结论**

- 不建议作为当前主线策略
- 未来如做“修复依赖关系”工作流，再单独设计

### 策略 C：断开依赖并静态化 `unlink`

**定义**

- 删除源对象时，派生对象保留当前最后有效几何值，并清空依赖

**优点**

- 非常适合数学创作工具
- 用户画面不会突然塌掉
- 与当前已有 cleanup 机制一致

**缺点**

- 动态几何语义会被静默丢失
- 若没有明确提示，教学用户可能不知道对象已“冻结”

**结论**

- 很适合作为默认保守策略
- 但最好配合明确 UI 文案或历史记录语义

### 策略 D：用户选择 `unlink` 或 `deleteAffected`

**定义**

- 当删除会影响派生对象时，让用户选择：
  - 仅删除所选对象
  - 删除所选及相关对象
  - 取消

**优点**

- 最符合 eMathica“数学工具 + 数学创作工具”的双重定位
- 兼顾创作保留和结构清理
- 与当前部分 UI 已存在的确认对话框一致

**缺点**

- 对快捷删除和批量删除要额外定义好行为
- 如果每次都弹窗，会打断高频操作

**结论**

- 推荐作为长期正式策略
- 但要做成分阶段版本：
  - Beta 用简化版
  - v1 用完整版本

## 5. 推荐策略

### 5.1 总体推荐

推荐采用：

- **长期正式策略：策略 D**
- **默认保守动作：`unlink`**
- **高频快捷入口：允许无弹窗，但必须落在保守语义上**

原因：

- eMathica 不是只面向严格课堂证明，也不是只做纯图形创作
- `unlink` 能保住用户已经构出的视觉结果
- `deleteAffected` 能照顾希望保持依赖图整洁的用户
- 单一路线不够覆盖产品定位

### 5.2 Plane Beta 最小策略

Plane Beta 推荐冻结为：

1. **默认产品语义**
   - 以 `unlink` 作为默认保守语义
   - 即：删除源对象后，派生对象默认保留最后有效几何值并静态化

2. **需要确认的入口**
   - ObjectPanel 删除
   - 批量删除
   - 任何明显会影响多个对象的删除入口

3. **确认内容**
   - `仅删除所选对象` = `unlink`
   - `删除所选及相关对象` = `deleteAffected`
   - 暂不加入“以后不再提示”

4. **快捷入口策略**
   - delete 工具
   - 快捷键删除
   - 小屏高频删除操作

   在 Beta 阶段建议采用：
   - **不弹复杂确认**
   - **直接走 `unlink`**

5. **`deleteAffected` 范围**
   - Beta 阶段文档推荐的产品语义应以 **direct dependents 优先** 为准
   - 不建议把“递归 downstream 全删”作为默认用户心智

### 5.3 Plane v1 完整策略

Plane v1 推荐升级为：

1. 正式保留双策略：
   - `unlink`
   - `deleteAffected`

2. 增加用户偏好：
   - 每次询问
   - 默认仅删除所选对象
   - 默认删除所选及相关对象

3. 对话框可增强：
   - 显示受影响对象数量
   - 未来可选显示对象类型摘要

4. 快捷删除入口也应接入统一策略层：
   - 要么遵循全局偏好
   - 要么明确总是走 `unlink`
   - 不能继续和对象区语义完全脱节

5. `deleteAffected` 的正式范围建议：
   - 默认 direct dependents
   - 递归 downstream 如要支持，应作为后续高级模式，而不是 v1 默认

### 5.4 Space 后续策略

#### Space v0.2

- 借用 Plane Beta 的最小策略
- 仍以 `unlink` 为默认保守动作
- 不引入 3D 专属复杂弹窗

#### Space v1

- 才进入完整的 3D 双策略设计
- 并补充 3D 术语：
  - 平面
  - 立体
  - 截交曲线
  - 工作平面

## 6. 对象类型策略表

| 源对象类型 | 典型派生对象 | 推荐删除策略 | 是否允许 unlink | 是否建议弹窗 | save/reopen 语义 |
|---|---|---|---|---|---|
| 点 | 中点、线段、圆、圆弧、平行线、垂线、交点 | 默认 `unlink`，允许用户选 `deleteAffected` | 是 | 是 | `unlink` 后派生对象保存为静态对象；`deleteAffected` 后对象不存在 |
| 线 | 交点、平行线、垂线、切线（future）、法线（future） | 默认 `unlink`，允许用户选 `deleteAffected` | 是 | 是 | 与点一致 |
| 线段 | 中点、交点、平行线、垂线 | 默认 `unlink`，允许用户选 `deleteAffected` | 是 | 是 | 与点一致 |
| 射线 | 交点、future point-on-ray | 默认 `unlink`，允许用户选 `deleteAffected` | 是 | 是 | 与点一致 |
| 圆 | 交点、future 切线、future 圆上点、future 圆弧派生 | 默认 `unlink`，允许用户选 `deleteAffected` | 是 | 是 | 与点一致 |
| 圆弧 | future 交点、future 扇形、future 测量对象 | 默认 `unlink`，允许用户选 `deleteAffected` | 是 | 视入口而定 | 与点一致 |
| 函数图像 | 根、极值点、切线、法线、交点、future table/result 对象 | Beta 阶段优先 `deleteAffected`；v1 再开放双策略 | 有条件允许 | 是 | Beta 阶段避免静默冻结代数语义；v1 如 unlink，则保存为静态图形/对象快照 |
| 参数 / slider | 参数驱动函数、参数驱动几何对象、动画对象 | Beta 阶段优先 `deleteAffected`；v1 可加双策略 | 有条件允许 | 是 | Beta 阶段优先保持语义清晰；v1 如 unlink，则保留最后值并解除绑定 |
| 未来 3D 点 | 3D 线、3D 线段、平面、球、截交对象 | 默认 `unlink`，允许用户选 `deleteAffected` | 是 | 是 | 与 2D 点同构 |
| 未来 3D 平面 | 截交线、平行平面、垂直平面、曲面截线 | 默认 `unlink`，允许用户选 `deleteAffected` | 是 | 是 | 与 2D 线/圆的策略对应 |

## 7. UI / 交互建议

### 7.1 Plane Beta

建议冻结为：

- ObjectPanel / 批量删除：
  - 若存在受影响派生对象，弹出确认
  - 选项仅保留：
    - `仅删除所选对象`
    - `删除所选及相关对象`
    - `取消`

- delete 工具 / 快捷删除：
  - 默认走 `unlink`
  - 不弹复杂确认
  - 以保持高频操作流畅

- ObjectPanel / Inspector 表达：
  - `unlink` 后对象不再显示“派生 / 动态”提示
  - 其显示应回到普通静态对象
  - 不进入 orphan / undefined 模式

### 7.2 Plane v1

建议增加：

- “以后不再提示”或设置项：
  - 每次询问
  - 默认仅删除所选对象
  - 默认删除所选及相关对象

- 更清楚的对话框文案：
  - 被多少个动态对象引用
  - 可能影响哪些类型

### 7.3 跨平台一致性

- iPad / macOS / iPhone 应采用**同一删除语义**
- 差异只应体现在交互承载方式：
  - iPad：confirmation dialog / popover
  - macOS：sheet / alert / menu action
  - iPhone：更紧凑的 confirmation UI

不建议按平台改变“删除后对象是静态化还是级联删除”的核心规则。

## 8. SaveLoad 语义

删除策略一旦冻结，save/reopen 也必须跟着固定：

### `unlink`

- 保存前：
  - 源对象已被删除
  - 派生对象的 `geometryDependency` 已清空
  - `geometryDefinitionStatus` 已清空
  - 几何外观、位置、样式保留

- 重开后：
  - 这些对象就是普通静态对象
  - 不应再重新绑定回旧源对象
  - ObjectPanel / Inspector 不应继续展示依赖关系

### `deleteAffected`

- 保存前：
  - 所选对象与相关对象都已从文档中移除

- 重开后：
  - 这些对象应保持不存在
  - `preview.png` 和首页缩略图应反映新的对象集合

### orphan / undefined

- 当前不建议作为正式持久化主线
- 否则需要额外定义：
  - orphan status 如何编码
  - 重开后如何展示
  - 用户如何修复依赖

## 9. 测试与 Golden Fixture 影响

### 对 `PlaneGeometryDependencyTests`

应明确区分两类测试：

1. `unlink` 路径
   - 删除源对象后
   - 派生对象保留
   - `geometryDependency == nil`
   - 位置 / 点集保持最后有效值

2. `deleteAffected` 路径
   - 删除源对象与相关对象
   - 幸存 downstream 对象如仍存在，应已静态化

### 对 `PlaneToolingTests`

- delete 工具应按 Beta 语义明确测试：
  - 当前若不弹窗，则应验证它采用的是哪条默认策略

### 对 `SaveLoad-GeometryDependency` fixture

这份策略直接决定 fixture 的两组样例：

1. `unlink save/reopen`
2. `deleteAffected save/reopen`

如果不先冻结策略，fixture 无法写 expected state。

### 对 `Plane-2D-ConstructionDependency` fixture

该 fixture 需要把删除源对象场景拆成至少两条：

- 删点 / 线 / 圆 -> `unlink`
- 删点 / 线 / 圆 -> `deleteAffected`

### 对 First Golden Fixture Creation

后续创建真实 fixture 时，删除场景必须带：

- 操作前对象树
- 删除动作
- 期望剩余对象树
- 保存重开后的对象树

### 对后续 `Geometry Dependency SaveLoad Consistency Fix`

修复任务不该再讨论“要不要 unlink / deleteAffected”，而应直接按本策略验收：

- unlink 后是否真的静态化并持久化
- deleteAffected 后是否真的清空对象并更新 thumbnail

## 10. 风险清单

| 风险 | 影响 | 规避方式 |
|---|---|---|
| 当前 `deleteAffected` 使用 downstream 递归删除，爆炸半径可能超出用户预期 | 批量删除、复杂依赖图、创作型作品 | 在实现任务里先做最小审计，明确是否要收窄为 direct dependents |
| delete 工具与对象区删除入口语义不一致 | 用户心智混乱，测试难统一 | Beta 阶段先把 delete tool 的默认策略写死为保守语义 |
| `unlink` 后静态化过于隐蔽 | 用户可能误以为对象仍是动态的 | ObjectPanel / Inspector 明确不再展示依赖信息；必要时加历史上下文 |
| save/reopen 若未按策略一致编码 | reopen 后对象状态漂移 | 用 `SaveLoad-GeometryDependency` fixture 固定 unlink / deleteAffected 两条样例 |
| 未来 undo/redo 若只恢复对象数量不恢复语义 | 删除恢复后依赖链断裂 | 后续 undo/redo 接入时以“恢复删除前完整依赖图状态”为标准 |
| 未来函数 / slider 依赖直接套用几何语义 | 代数语义冻结不透明 | 对函数 / slider 在 Beta 阶段优先采用更保守策略，v1 再扩展 |

## 11. 后续最小任务

1. `Delete Source Object Minimal Implementation Audit`
   - 对齐当前各删除入口与 Beta 推荐语义，尤其是 delete tool 是否仍绕过策略层
2. `Geometry Dependency SaveLoad Consistency Fix`
   - 按本文冻结的 unlink / deleteAffected 语义检查保存重开是否一致
3. `PlaneGeometryDependencyTests Delete Semantics Update`
   - 把相关测试名称、注释和分类与正式产品语义统一
4. `First Golden Fixture Creation: Plane-2D-ConstructionDependency`
   - 先创建最关键的依赖删除 fixture
5. `First Golden Fixture Creation: Plane-2D-BasicGeometry`
   - 作为基础几何与删除语义的对照样例
