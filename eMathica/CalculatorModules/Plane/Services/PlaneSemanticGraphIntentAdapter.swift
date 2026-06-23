import Foundation
import EMathicaMathCore

enum PlaneSemanticGraphIntentAdapter {
    static func semanticGraphKind(from intent: GraphIntent?) -> SemanticGraphKind? {
        guard let intent else { return nil }
        switch intent {
        case .explicitY:
            return .explicitY
        case .explicitX:
            return .explicitX
        case .parametric2D:
            return .parametric2D
        case .polar:
            return .polar
        case .point:
            return .point
        case .circle:
            return .circle
        case .conic(let info):
            switch info.kind {
            case .circle:
                return .circle
            case .ellipse:
                return .ellipse
            case .hyperbola:
                return .hyperbola
            case .parabola:
                return .parabola
            case .unknown:
                return .conic
            }
        case .piecewise:
            return .piecewise
        case .implicit:
            return .implicit
        case .unknown:
            return .unknown
        }
    }

    static func metadataText(
        semanticGraphKind: SemanticGraphKind?,
        semanticParameterSymbol: Symbol?,
        semanticParameterRange: ParameterRange?,
        algebraAnalysis: AlgebraAnalysisResult?
    ) -> String? {
        if let semanticGraphKind {
            if (semanticGraphKind == .parametric2D || semanticGraphKind == .polar),
               let rangeText = parameterRangeText(symbol: semanticParameterSymbol, range: semanticParameterRange) {
                return "\(displayName(for: semanticGraphKind)) · \(rangeText)"
            }
            return displayName(for: semanticGraphKind)
        }
        guard let analysis = algebraAnalysis else { return nil }
        let shape = analysis.recognizedShape?.displayName ?? analysis.classification.summary
        let strategy = analysis.plotStrategy?.displayName ?? "默认绘制"
        return "\(shape) · \(strategy)"
    }

    static func parameterSymbol(from intent: GraphIntent?) -> Symbol? {
        guard let intent else { return nil }
        switch intent {
        case .parametric2D(_, _, let parameter, _):
            return parameter
        case .polar(_, let angle, _):
            return angle
        default:
            return nil
        }
    }

    static func parameterRange(from intent: GraphIntent?) -> ParameterRange? {
        guard let intent else { return nil }
        switch intent {
        case .parametric2D(_, _, _, let range):
            return range
        case .polar(_, _, let range):
            return range
        default:
            return nil
        }
    }

    static func displayName(for kind: SemanticGraphKind) -> String {
        switch kind {
        case .explicitY:
            return "显函数 y=f(x)"
        case .explicitX:
            return "显函数 x=f(y)"
        case .parametric2D:
            return "参数方程"
        case .polar:
            return "极坐标曲线"
        case .point:
            return "点"
        case .circle:
            return "圆"
        case .ellipse:
            return "椭圆"
        case .hyperbola:
            return "双曲线"
        case .parabola:
            return "抛物线"
        case .conic:
            return "圆锥曲线"
        case .piecewise:
            return "分段函数"
        case .implicit:
            return "隐函数"
        case .unknown:
            return "未分类"
        }
    }

    private static func parameterRangeText(symbol: Symbol?, range: ParameterRange?) -> String? {
        guard let range else { return nil }
        let name = symbol?.name ?? "t"
        let lower = range.lower.map(compactExprText) ?? "-∞"
        let upper = range.upper.map(compactExprText) ?? "∞"
        return "\(lower) < \(name) < \(upper)"
    }

    private static func compactExprText(_ expr: Expr) -> String {
        switch expr {
        case .integer(let value):
            return String(value)
        case .decimal(let text):
            return text
        case .real(let value):
            if value == Double(Int(value)) {
                return String(Int(value))
            }
            return String(value)
        case .rational(let n, let d):
            return "\(n)/\(d)"
        case .symbol(let symbol):
            return symbol.name
        case .constant(let constant):
            switch constant {
            case .pi:
                return "π"
            case .e:
                return "e"
            case .imaginaryUnit:
                return "i"
            case .infinity:
                return "∞"
            }
        case .multiply(let factors):
            if factors.count == 2 {
                if case .integer(let n) = factors[0], case .constant(.pi) = factors[1] {
                    return "\(n)π"
                }
                if case .constant(.pi) = factors[0], case .integer(let n) = factors[1] {
                    return "\(n)π"
                }
            }
            return ExprDebugPrinter().print(expr)
        default:
            return ExprDebugPrinter().print(expr)
        }
    }
}

private extension RecognizedShapeKind {
    var displayName: String {
        switch self {
        case .circle:
            return "圆"
        case .ellipse:
            return "椭圆"
        case .hyperbola:
            return "双曲线"
        case .parabola:
            return "抛物线"
        case .superellipse:
            return "超椭圆"
        }
    }
}

private extension PlotStrategyKind {
    var displayName: String {
        switch self {
        case .explicitY:
            return "y=f(x)"
        case .explicitX:
            return "x=f(y)"
        case .horizontalLine:
            return "水平线"
        case .verticalLine:
            return "竖直线"
        case .conicParametric:
            return "圆锥曲线参数化"
        case .parametric:
            return "参数方程"
        case .implicit:
            return "隐式曲线"
        case .unsupported:
            return "未支持"
        }
    }
}
