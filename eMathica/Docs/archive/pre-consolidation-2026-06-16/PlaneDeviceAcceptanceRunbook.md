# Plane Device Acceptance Runbook (v1 Core)

## 1. 测试环境

### 1.1 设备与系统
- iPad 真机（建议至少 1 台主力设备）
- Mac 本地运行（用于对照预览行为和键盘快捷键）

### 1.2 布局场景
- iPad 全屏横屏
- iPad Split View（1/2、1/3 宽度）
- Stage Manager 缩放窗口（如可用）

### 1.3 输入设备
- 触控 + Pencil（如有）
- 外接键盘（重点验证 Cmd+Z / Shift+Cmd+Z）

### 1.4 记录方式
- 每个模块至少 1 组截图或录屏
- 问题记录使用第 9 节模板

---

## 2. 动态几何验收

## 2.1 midpoint
前置条件：
- 新建 Plane 文档
- 创建两个点 A、B

步骤：
1. 使用 midpoint 工具选择 A、B 创建 M
2. 拖动 A，再拖动 B

预期：
- M 始终位于 AB 中点
- M 为派生对象（对象区有来源）

记录：
- 创建后画面
- 拖动前后对比

## 2.2 parallel / perpendicular
前置条件：
- 已有参考线对象（line/segment/ray）和 through 点 P

步骤：
1. 创建平行线 p（参考 l，过 P）
2. 创建垂线 q（参考 l，过 P）
3. 拖动参考线端点、拖动 P

预期：
- p 始终平行于参考对象并通过 P
- q 始终垂直于参考对象并通过 P
- 无可操作 helper point 泄漏

记录：
- 拖动后方向变化截图

## 2.3 dynamic circle: circleByCenterPoint
前置条件：
- 点 C（圆心）、点 T（过点）

步骤：
1. 使用 circle 工具（已有点 -> 已有点）创建圆
2. 分别拖动 C、T

预期：
- 圆随 C、T 变化动态更新
- 来源显示为“圆心 C，过 T”

## 2.4 dynamic circle: circleByCenterRadius
前置条件：
- 点 C（可已有或新建）

步骤：
1. circle：第一下选 C，第二下点空白创建固定半径圆
2. 拖动 C

预期：
- 圆心随 C 移动
- 半径保持不变
- 不创建 through helper point

## 2.5 intersections
前置条件：
- 构造 line-line、line-circle、circle-circle 三类可交对象

步骤：
1. 分别创建交点对象
2. 拖动来源对象制造“有解/无解/再有解”

预期：
- defined 时交点更新
- noSolution 时不按有效点渲染、不可正常命中
- 恢复有解后交点恢复更新

## 2.6 noSolution 消失与恢复
前置条件：
- 任意可进入 noSolution 的动态交点

步骤：
1. 调整来源使其无交点
2. 调整回有交点

预期：
- 状态从 defined -> noSolution -> defined
- 对象仍存在，不崩溃

---

## 3. 删除策略验收

## 3.1 单删 source + unlink
前置条件：
- source 被一个或多个 derived 直接依赖

步骤：
1. 删除 source
2. 在弹窗选择“仅删除所选对象”

预期：
- source 删除
- directly affected derived 转独立对象
- 几何/样式/名称保留

## 3.2 单删 source + delete affected
步骤：
1. 删除 source
2. 在弹窗选择“删除所选及相关对象”

预期：
- source + directly affected derived 一并删除
- 不递归删除 downstream

## 3.3 批删 + unlink / delete affected
前置条件：
- 选中多个 source（含存在依赖的对象）

步骤：
1. 执行 deleteSelectedObjects
2. 分别测试两种策略

预期：
- affected 去重、排除 selected
- 行为与单删策略一致

## 3.4 cancel
步骤：
1. 删除触发弹窗
2. 选择取消

预期：
- document 不变化
- 不新增 undo step

---

## 4. Undo / Redo / Revert 验收

## 4.1 基本对象操作
覆盖：
- 创建对象 undo/redo
- 移动 source point undo/redo
- 删除 source undo/redo
- 批量删除 undo/redo

预期：
- 每个用户动作是单个 undo step
- 连带 cleanup/recompute 同步恢复

## 4.2 画布操作
步骤：
1. 连续 pan/zoom
2. undo/redo

预期：
- pan/zoom 合并入栈，不是每帧一条
- undo 恢复到手势前视口状态

## 4.3 revert-to-open-state
步骤：
1. 打开文档后进行若干编辑
2. 执行“恢复到打开时状态”

预期：
- 文档回到 open baseline
- 如已设计为可撤销，undo 可回到 revert 前状态

## 4.4 输入编辑态快捷键冲突
步骤：
1. 进入公式编辑
2. 使用 Cmd+Z

预期：
- 不抢占文本编辑撤销（以当前产品定义为准）

---

## 5. Save / Load / Recent / Preview 验收

## 5.1 保存后重开
步骤：
1. 构造含多类动态依赖与状态的文档
2. 保存、关闭、重新打开

预期：
- geometryDependency 保留
- geometryDefinitionStatus 保留
- 重开后 source 移动仍可重算

## 5.2 noSolution roundtrip
步骤：
1. 让某交点处于 noSolution
2. 保存并重开

预期：
- 状态仍为 noSolution
- 不显示为有效旧点

## 5.3 preview / recent
步骤：
1. 保存后返回首页
2. 检查缩略图与最近使用排序

预期：
- preview 不显示 noSolution 旧点
- 圆不被拉成椭圆
- 最近使用 updatedAt 排序正确

---

## 6. 对象区验收

覆盖：
1. source/status 优先显示
2. noSolution 文案清晰
3. segment 显示长度
4. circle 显示半径
5. slider row 未回归
6. object panel 高度与滚动正常

记录：
- 长表达式对象
- 动态派生对象
- 参数对象混合场景

---

## 7. Inspector 验收

## 7.1 point
- 坐标
- 来源/状态（派生对象）

## 7.2 segment
- 端点 A/B
- 长度
- 方向角

## 7.3 circle
- 圆心
- 半径
- 直径

## 7.4 line / ray
- 方向向量
- 斜率（line）
- 方向角
- 起点/过点

## 7.5 intersection
- 来源对象
- 交点序号
- 定义状态
- 坐标（仅 defined）

## 7.6 non-defined guard
预期：
- non-defined 不显示误导性的旧几何值

---

## 8. 性能与交互观察

重点观察项：
1. dense dynamic scene 下 pan/zoom 流畅度
2. object panel 长列表滚动稳定性
3. preview 刷新延迟
4. 多步 undo/redo 连续操作
5. iPad Split View 下交互可用性

建议记录：
- 机型、系统版本
- 场景对象数量级
- 复现频率（稳定 / 偶发）

---

## 9. Bug 记录模板

请按以下字段记录：

- 测试项：
- 前置条件：
- 操作步骤：
- 实际结果：
- 预期结果：
- 截图/录屏：
- 是否可复现（稳定/偶发）：
- 关联对象/表达式：
- 设备与系统版本：
- 备注：

