import Foundation
import EMathicaMathCore

struct PlaneSemanticPreviewPolicy {
    // piecewise 默认启用仅针对已经 lower 成 Expr.piecewise / GraphIntent.piecewise 的语义链路。
    // 当前推荐入口是内置 piecewise 模板；本策略不改变自由文本 braces/cases 的 lowering 语义。
    // implicit 现已默认启用：SamplingCore 已具备 Marching Squares + segment stitching，
    // 并经过常见隐函数端到端验证。若 semantic 采样失败，DraftPreview 仍会回退 legacy 路径。
    // explicitY / explicitX 继续保持 legacy，避免大范围行为变化。
    func shouldUseSemanticPreview(for intent: GraphIntent) -> Bool {
        switch intent {
        case .parametric2D, .polar, .point, .circle, .piecewise, .implicit, .conic:
            return true
        case .explicitY, .explicitX, .unknown:
            return false
        }
    }
}
