# Plane-2D-ConstructionDependency Golden Fixture

## 覆盖能力

- 中点
- 交点
- 平行线
- 垂线
- 源对象拖拽后的依赖重算
- 删除源对象后的 `unlink` 静态化
- 删除源对象后的 `deleteAffected`
- save / reopen 后依赖保持
- preview / thumbnail 可渲染
- ObjectPanel / Inspector 通过真实 Plane resolver 展示几何属性

## 对象列表

基础源对象：

- `A`：自由点 `(0, 0)`
- `B`：自由点 `(4, 1)`
- `C`：自由点 `(2, -2)`
- `D`：自由点 `(2, 2)`
- `ℓ1`：直线 `AB`
- `ℓ2`：直线 `CD`

派生对象：

- `M`：`A` 与 `B` 的中点
- `X`：`ℓ1` 与 `ℓ2` 的交点
- `p`：过 `C` 且平行于 `ℓ1` 的直线
- `q`：过 `D` 且垂直于 `ℓ1` 的直线
- `Y`：`p` 与 `q` 的交点，作为二级依赖对象

说明：

- 当前 fixture 把 `Y` 主要用作删除语义和 save/reopen 语义的二级依赖样例。
- 当前自动化基线对“源对象拖拽后的实时重算”只强制覆盖直接依赖对象：`M / X / p / q`。
- `Y` 的多级依赖实时联动暂不作为本轮 golden fixture 的硬性通过条件，后续若产品语义扩展，可再升级这一项。

## 依赖关系

- `M` depends on `A`, `B`
- `X` depends on `ℓ1`, `ℓ2`
- `p` depends on `ℓ1`, `C`
- `q` depends on `ℓ1`, `D`
- `Y` depends on `p`, `q`

## 自动化测试入口

当前 fixture 采用 **test builder 动态生成**，真实 `.emathica` 包文件本轮未提交。

对应测试文件：

- `/Users/night_creek/开发/eMathica/eMathica/eMathica/eMathicaTests/PlaneConstructionDependencyGoldenFixtureTests.swift`

主要测试：

- `constructionDependencyFixtureCanBeBuilt`
- `constructionDependencyFixtureRecomputesAfterSourceMove`
- `constructionDependencyFixtureSurvivesSaveReopen`
- `constructionDependencyFixtureUnlinkSavesAsStatic`
- `constructionDependencyFixtureDeleteAffectedSavesExpectedObjects`
- `constructionDependencyFixturePreviewRenders`

## 当前限制

- 本轮未提交真实 `.emathica` 包文件
- 本轮未提交 expected preview image
- 本轮未覆盖手工 iPad / macOS / iPhone 验收
- 本轮 fixture 重点是依赖构造链路，不覆盖函数 metadata、graphing 质量或 UI polish

## 后续固化方向

后续若需要把它升级为更完整的长期资源，可继续补：

1. 真实 `Plane-2D-ConstructionDependency.emathica` 包
2. expected preview image / thumbnail baseline
3. iPad / macOS / iPhone 手工 QA checklist
4. 与 `SaveLoad-GeometryDependency` 对应的 package-level fixture 验收
