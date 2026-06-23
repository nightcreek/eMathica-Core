# Expected Behavior

## Object Count

- 预期对象数量：`8`

## Function List

- `f_1`：`y=x`
- `f_2`：`x^2`
- `f_3`：`sin(x)`
- `f_4`：`1/x`
- `f_5`：`x^2+y^2=1`（implicit 输入，语义为 circle）
- `f_6`：参数圆
- `f_7`：极坐标玫瑰线
- `f_8`：两段 piecewise

## Metadata Preservation

支持对象应在 save / reopen 后保留：

- `rawInput`
- `sourceExpression`
- `originalLatex`
- `displayText`
- `editorASTData`
- `semanticGraphKind`
- `semanticParameterSymbol`
- `semanticParameterRange`

## Display Priority

对象区 / Inspector 显示优先级：

- `displayText`
- `originalLatex`
- `rawInput`
- `name`

## Edit Priority

重新编辑优先级：

1. 有效 `editorASTData`
2. `sourceExpression`
3. `rawInput`
4. `originalLatex`
5. `displayText`

## Semantic Intent

- `f_1 ~ f_4`：`explicitY`
- `f_5`：`circle`
- `f_6`：`parametric2D`
- `f_7`：`polar`
- `f_8`：`piecewise`

## Preview Behavior

- 基础文档可生成 preview
- reopen 后 preview 仍可生成
- preview 数据应非空
- 本轮不要求 expected preview image byte baseline

## Unsupported / Known Limitations

- `sqrt(x)` raw-text path 当前不纳入 hard-pass fixture
- 该路径应在文档中明确标注为 parser gap / known limitation
- brace-heavy fallback 风险仍存在，后续需要 parser gaps audit
