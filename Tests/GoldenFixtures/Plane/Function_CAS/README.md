# Plane-Function-CAS Golden Fixture

## 覆盖能力

- explicitY 基础函数
- domain / discontinuity 风险函数
- implicit 函数
- parametric 函数
- polar 函数
- piecewise 函数
- `rawInput / sourceExpression / originalLatex / displayText / editorASTData`
- save / reopen 后 metadata 保持
- reopen 后重新编辑
- semantic intent / `GraphIntent` 重建
- preview / thumbnail 可渲染
- unsupported parser gap 的明确记录

## 函数对象列表

必须通过的对象：

- `f_1`：`y=x`
- `f_2`：`x^2`
- `f_3`：`sin(x)`
- `f_4`：`1/x`
- `f_5`：`x^2+y^2=1`（implicit 输入，当前语义识别为 circle）
- `f_6`：参数圆 `x=cos(t), y=sin(t), 0<=t<=2π`
- `f_7`：极坐标玫瑰线 `r=sin(3θ), 0<=θ<=2π`
- `f_8`：两段 piecewise

Known limitation：

- `sqrt(x)` raw-text commit path 当前不作为 hard-pass fixture case

## Metadata 字段

每个支持对象应覆盖：

- `rawInput`
- `sourceExpression`
- `originalLatex`
- `displayText`
- `editorASTData`
- `semanticGraphKind`
- `semanticParameterSymbol`
- `semanticParameterRange`

## GraphIntent / semantic expectations

- `f_1 ~ f_4`：`explicitY`
- `f_5`：`circle`（来自 implicit 圆方程）
- `f_6`：`parametric2D`
- `f_7`：`polar`
- `f_8`：`piecewise`

## Save/Reopen 行为

- object count 保持 `8`
- `id / name` 保持
- metadata round-trip 保持
- reopen 后 semantic intent 可继续重建
- `ProjectPreviewRenderer` 可继续渲染

## Edit After Reopen 行为

- 有效 `editorASTData` 时优先恢复结构化编辑
- AST 缺失时 fallback 到：
  - `sourceExpression`
  - `rawInput`
  - `originalLatex`
  - `displayText`
- 不应把 display-only text 当成唯一编辑源

## Preview 行为

- fixture 文档可生成 PNG preview
- reopen 后 preview 仍可生成
- preview 不要求本轮建立 expected image baseline

## Known Limitations

- 本轮 fixture 使用 **test builder 动态生成**，未提交真实 `.emathica` package
- `sqrt(x)` raw-text parser path 仍作为已知限制记录，不纳入 hard-pass
- brace-heavy fallback 在 `editorASTData` 缺失/损坏时仍可能存在 parser-adjacent drift，本轮未修 parser
- 本轮未覆盖手工 iPad / macOS / iPhone 验收
