# Sampling Comparison Cases (Legacy vs Semantic)

本清单用于 DEBUG 人工对比 `AlgebraCore` 旧采样链路与 `SamplingCore` 新语义采样链路。

## Cases

| 表达式 | 预期分类 | 连续性预期 | 断线预期 | 高频漏采风险 |
|---|---|---|---|---|
| `y=x` | explicitY | 连续 | 不应断线 | 低 |
| `y=x^2` | explicitY | 连续 | 不应断线 | 低 |
| `y=sin(x)` | explicitY | 连续 | 不应断线 | 中（视采样密度） |
| `y=1/x` | explicitY | 非连续 | 在 `x=0` 附近应断线 | 中 |
| `y=sqrt(x)` | explicitY | 分段定义 | `x<0` 区域应断线 | 低 |
| `y=ln(x)` | explicitY | 分段定义 | `x<=0` 区域应断线 | 低 |
| `x=y^2` | explicitX | 连续 | 不应断线 | 低 |
| `y=tan(x)` | explicitY | 含渐近线 | 在奇点附近应断线 | 高 |
| `y=abs(x)` | explicitY | 连续（尖点） | 不应断线 | 低（但拐点附近应可见） |
| `y=sin(20x)` | explicitY | 连续 | 不应断线 | 高（高频振荡） |

## 使用建议

1. 默认保持 `semanticSamplingComparisonEnabled = false`。  
2. 仅在 DEBUG 下临时开启对比。  
3. 开启后重点观察：  
   - `legacySegments/legacyPoints` 与 `semanticSegments/semanticPoints` 差异  
   - `semanticIssueSummary` 是否符合预期  
   - `fallbackReason` 是否合理  
