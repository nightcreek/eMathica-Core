# Space Calculator v0.1 Core Status

## 1. Scope

Space v0.1 范围定义为一个可用的 3D wireframe calculator 核心闭环，覆盖：

- 3D 对象：`point3D` / `segment3D` / `line3D` / `plane3D`
- 3D 视角交互：`orbit` / `pan` / `zoom`
- 基础编辑交互：`select` / 最小 `snapping` / `work plane`
- 文档闭环：`save/load` / `preview` / `delete + recovery`

目标是先稳定主路径，不追求 v0.1 之外的高级能力（CAS、曲面、动态依赖等）。

---

## 2. Completed Modules

已完成模块：

1. `SpaceMathCore-1`
2. `SpaceDocumentModel-1`
3. `SpaceCanvas-1`
4. `SpaceCanvasVisualFix-2`
5. `SpaceTools-1A/1B/1C`
   - point3D
   - segment3D
   - line3D
   - plane3D
6. `SpaceHitTest-1A`
7. `SpaceSnapping-1A`
8. `SpaceWorkPlane-1A`
9. `SpaceInspector-1`
10. `SpacePreview-1`
11. `SpaceV0.1DeviceAcceptanceRunbook-1`

---

## 3. Frozen Modules (bugfix-only)

以下模块进入 bugfix-only 冻结状态（不再继续扩功能）：

1. SpaceMathCore v0.1
2. SpaceDocumentModel v0.1
3. SpaceCanvas v0.1
4. SpaceTools v0.1
5. SpaceHitTest v0.1
6. SpaceSnapping v0.1
7. SpaceWorkPlane v0.1
8. SpaceInspector v0.1
9. SpacePreview v0.1

冻结含义：
- 只接受稳定性、崩溃、错误行为、明显交互缺陷修复；
- 不在该周期内追加新的核心功能定义。

---

## 4. Device-tested Behaviors

当前真机复测中已基本通过的行为：

- orbit / pan / zoom 主交互
- light / dark 模式下 SpaceCanvas 可读性
- point / segment / line / plane 创建主链路
- select / highlight
- snapping（point3D 优先，未命中 fallback）
- XY / YZ / ZX work plane 切换与落点
- Space Inspector 属性显示
- save / load / preview 闭环
- delete / recovery（含恢复后可继续操作）

---

## 5. Known Limitations

当前明确限制：

- 无 Space CAS
- 无 `z=f(x,y)` 曲面
- 无 `z=y -> plane3D` 表达式分类器
- 无 3D dependency（静态对象为主）
- 无 dynamic plane
- 无 arbitrary work plane
- 无 selected plane as work plane
- 无 3D drag editing
- 无 SceneKit / Metal 渲染路线
- 无高级 snapping 可视化指示器

---

## 6. Deferred Items

### P1（中期后置）

- 3D drag editing audit
- Space dynamic geometry audit
- selected plane as work plane
- snapping visual indicator
- 更细化的 3D object panel row 信息

### P2（长期后置）

- Space CAS
- `z=f(x,y)` surface
- implicit surface
- parametric curve / surface
- SceneKit / Metal 路线
- advanced camera controls

---

## 7. Next-stage Roadmap

建议并行评估的 4 条路线：

1. **Space v0.1 Stabilization**
   - 继续按真机 runbook 执行验收
   - 聚焦缺陷修复，不扩展能力面

2. **Space Dynamic Geometry**
   - 3D dependency
   - point-line-plane relation 约束与更新链

3. **Space Expression / CAS**
   - `z=f(x,y)`、参数曲线/曲面
   - 表达式对象与 3D 几何对象语义桥接

4. **Rendering Upgrade**
   - SceneKit/Metal 路线评估，或持续优化 wireframe 风格与层次

---

## 8. Rule

下一次 Space 验收周期前遵循：

- Space v0.1 不新增核心功能；
- 仅接受 bugfix；
- 新能力必须进入独立分支，并配套独立验收计划与回归清单。
