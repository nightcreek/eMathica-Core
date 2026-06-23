import EMathicaWorkspaceKit
import Foundation
import EMathicaMathCore

enum PlaneResolvedIntentSource: Equatable {
    case classification
    case fallback
}

struct PlaneResolvedIntent: Equatable {
    var intent: GraphIntent
    let source: PlaneResolvedIntentSource
}

struct PlaneImplicitFallbackPolicy {
    static let previewGridResolution: Int = 96
    static let renderGridResolution: Int = 128
    static let maxGridResolution: Int = 160
    static let maxSegments: Int = 4096
    static let maxEvaluationCount: Int = 30_000
}

enum PlaneFallbackSamplingService {
    struct ResolveIntentResult: Equatable {
        var resolved: PlaneResolvedIntent?
        var diagnostics: [FormulaPlotDiagnostic]
    }

    static func resolveIntent(
        expression: Expr?,
        classification: GraphClassificationResult?,
        parameterSymbolNames: Set<String>
    ) -> PlaneResolvedIntent? {
        resolveIntentWithDiagnostics(
            expression: expression,
            classification: classification,
            parameterSymbolNames: parameterSymbolNames,
            source: .committed
        ).resolved
    }

    static func resolveIntentWithDiagnostics(
        expression: Expr?,
        classification: GraphClassificationResult?,
        parameterSymbolNames: Set<String>,
        source: FormulaPlotDiagnosticSource
    ) -> ResolveIntentResult {
        var diagnostics: [FormulaPlotDiagnostic] = []

        if let classification {
            diagnostics.append(contentsOf: classification.diagnostics.map {
                FormulaPlotDiagnostic.fromGraph($0, source: source)
            })
            if case .unknown = classification.intent {
                if let expression,
                   let fallback = fallbackIntent(from: expression, parameterSymbolNames: parameterSymbolNames) {
                    diagnostics.append(
                        FormulaPlotDiagnostic(
                            stage: .fallback,
                            severity: .info,
                            code: "classification_unknown_fallback_applied",
                            message: "分类结果为 unknown，已使用 fallback 采样意图",
                            source: source
                        )
                    )
                    return ResolveIntentResult(
                        resolved: PlaneResolvedIntent(intent: fallback, source: .fallback),
                        diagnostics: diagnostics
                    )
                }
                diagnostics.append(
                    FormulaPlotDiagnostic(
                        stage: .fallback,
                        severity: .error,
                        code: "classification_unknown_fallback_unavailable",
                        message: "分类结果为 unknown，且 fallback 无法接管",
                        source: source
                    )
                )
                return ResolveIntentResult(resolved: nil, diagnostics: diagnostics)
            }
            return ResolveIntentResult(
                resolved: PlaneResolvedIntent(intent: classification.intent, source: .classification),
                diagnostics: diagnostics
            )
        }

        guard let expression else {
            diagnostics.append(
                FormulaPlotDiagnostic(
                    stage: .fallback,
                    severity: .error,
                    code: "missing_expression_for_fallback",
                    message: "缺少语义表达式，无法进行 fallback",
                    source: source
                )
            )
            return ResolveIntentResult(resolved: nil, diagnostics: diagnostics)
        }

        guard let fallback = fallbackIntent(from: expression, parameterSymbolNames: parameterSymbolNames) else {
            diagnostics.append(
                FormulaPlotDiagnostic(
                    stage: .fallback,
                    severity: .warning,
                    code: "fallback_rejected_expression_shape",
                    message: "fallback 拒绝该表达式形态",
                    source: source
                )
            )
            return ResolveIntentResult(resolved: nil, diagnostics: diagnostics)
        }

        diagnostics.append(
            FormulaPlotDiagnostic(
                stage: .fallback,
                severity: .info,
                code: "fallback_applied_without_classification",
                message: "未提供分类结果，已直接使用 fallback 采样意图",
                source: source
            )
        )
        return ResolveIntentResult(
            resolved: PlaneResolvedIntent(intent: fallback, source: .fallback),
            diagnostics: diagnostics
        )
    }

    static func diagnosticsForSampleSet(
        _ sampleSet: SampleSet2D,
        intent: GraphIntent,
        source: FormulaPlotDiagnosticSource
    ) -> [FormulaPlotDiagnostic] {
        var diagnostics = sampleSet.issues.map { FormulaPlotDiagnostic.fromSampling($0, source: source) }
        if sampleSet.segments.isEmpty {
            diagnostics.append(
                FormulaPlotDiagnostic(
                    stage: .sampling,
                    severity: .warning,
                    code: "empty_sample_set",
                    message: "采样完成但可见范围内没有可绘制片段",
                    source: source
                )
            )
        }
        if case .unknown = intent {
            diagnostics.append(
                FormulaPlotDiagnostic(
                    stage: .sampling,
                    severity: .error,
                    code: "unknown_intent_not_sampled",
                    message: "unknown 意图无法采样",
                    source: source
                )
            )
        }
        return diagnostics
    }

    static func fallbackIntent(from expr: Expr, parameterSymbolNames: Set<String>) -> GraphIntent? {
        switch expr {
        case .equation(let left, let right):
            if let explicit = explicitIntentFromEquationLike(left: left, right: right, parameterSymbolNames: parameterSymbolNames) {
                return explicit
            }
            return implicitFallbackIfPossible(expr)
        case .relation(let left, let relation, let right):
            guard relation == .equal else { return nil }
            if let explicit = explicitIntentFromEquationLike(left: left, right: right, parameterSymbolNames: parameterSymbolNames) {
                return explicit
            }
            return implicitFallbackIfPossible(expr)
        case .tuple, .vector, .matrix, .piecewise, .assignment, .functionDefinition, .unknown:
            return nil
        default:
            if let implicit = implicitFallbackForBareExpression(expr, parameterSymbolNames: parameterSymbolNames) {
                return implicit
            }
            return explicitIntentFromBareExpression(expr, parameterSymbolNames: parameterSymbolNames)
        }
    }

    static func sampler(qualityProfile: SamplingQualityProfile) -> GraphIntentSampler2D {
        let curveOptions = CurveSamplingOptions2D.defaults(for: qualityProfile)
        let parametricSampler = ParametricCurveSampler2D(options: curveOptions)
        let implicitResolution = implicitResolution(for: qualityProfile)
        let implicitOptions = ImplicitCurveSamplingOptions2D(
            qualityProfile: qualityProfile,
            xResolution: implicitResolution,
            yResolution: implicitResolution,
            maxAbsCoordinate: 1.0e12,
            enableSegmentStitching: true,
            stitchingTolerance: 1.0e-6
        )

        return GraphIntentSampler2D(
            explicitFunctionSampler: .init(options: curveOptions),
            parametricCurveSampler: parametricSampler,
            polarCurveSampler: .init(parametricCurveSampler: parametricSampler),
            primitiveSampler: .init(parametricCurveSampler: parametricSampler),
            implicitCurveSampler: .init(options: implicitOptions),
            piecewiseSampler: .init(options: curveOptions),
            conicSampler: .init(
                parametricCurveSampler: parametricSampler,
                explicitFunctionSampler: .init(options: curveOptions)
            )
        )
    }

    static func limitSegmentsIfNeeded(_ sampleSet: SampleSet2D, intent: GraphIntent) -> SampleSet2D {
        guard case .implicit = intent else { return sampleSet }
        guard sampleSet.segments.count > PlaneImplicitFallbackPolicy.maxSegments else { return sampleSet }
        let kept = Array(sampleSet.segments.prefix(PlaneImplicitFallbackPolicy.maxSegments))
        var issues = sampleSet.issues
        issues.append(
            SamplingIssue(
                kind: .insufficientSamples,
                message: "implicit segments truncated to \(PlaneImplicitFallbackPolicy.maxSegments)"
            )
        )
        return SampleSet2D(segments: kept, issues: issues)
    }

    private static func explicitIntentFromEquationLike(
        left: Expr,
        right: Expr,
        parameterSymbolNames: Set<String>
    ) -> GraphIntent? {
        if isSymbol(left, named: "y"),
           supportsExplicitY(right, parameterSymbolNames: parameterSymbolNames) {
            return .explicitY(
                expression: right,
                variable: Symbol(name: "x", role: .variable)
            )
        }
        if isSymbol(left, named: "x"),
           supportsExplicitX(right, parameterSymbolNames: parameterSymbolNames) {
            return .explicitX(
                expression: right,
                variable: Symbol(name: "y", role: .variable)
            )
        }
        return nil
    }

    private static func explicitIntentFromBareExpression(
        _ expr: Expr,
        parameterSymbolNames: Set<String>
    ) -> GraphIntent? {
        let vars = variableNames(in: expr)
        let nonParameterVars = vars.subtracting(parameterSymbolNames)
        let hasX = nonParameterVars.contains("x")
        let hasY = nonParameterVars.contains("y")

        if hasX && !hasY {
            return .explicitY(expression: expr, variable: Symbol(name: "x", role: .variable))
        }
        if hasY && !hasX {
            return .explicitX(expression: expr, variable: Symbol(name: "y", role: .variable))
        }
        return nil
    }

    private static func implicitFallbackForBareExpression(
        _ expr: Expr,
        parameterSymbolNames: Set<String>
    ) -> GraphIntent? {
        let vars = variableNames(in: expr).subtracting(parameterSymbolNames)
        guard vars.contains("x"), vars.contains("y") else { return nil }
        return .implicit(relation: .equation(left: expr, right: .integer(0)))
    }

    private static func implicitFallbackIfPossible(_ expr: Expr) -> GraphIntent? {
        let vars = variableNames(in: expr)
        guard vars.contains("x"), vars.contains("y") else { return nil }
        switch expr {
        case .equation, .relation, .chainedRelation:
            return .implicit(relation: expr)
        default:
            return nil
        }
    }

    private static func supportsExplicitY(
        _ expr: Expr,
        parameterSymbolNames: Set<String>
    ) -> Bool {
        let vars = variableNames(in: expr).subtracting(parameterSymbolNames)
        return !vars.contains("y")
    }

    private static func supportsExplicitX(
        _ expr: Expr,
        parameterSymbolNames: Set<String>
    ) -> Bool {
        let vars = variableNames(in: expr).subtracting(parameterSymbolNames)
        return !vars.contains("x")
    }

    private static func isSymbol(_ expr: Expr, named name: String) -> Bool {
        guard case .symbol(let symbol) = expr else { return false }
        return symbol.name == name
    }

    private static func implicitResolution(for qualityProfile: SamplingQualityProfile) -> Int {
        let raw: Int
        switch qualityProfile {
        case .preview:
            raw = PlaneImplicitFallbackPolicy.previewGridResolution
        case .balanced:
            raw = PlaneImplicitFallbackPolicy.renderGridResolution
        case .precise, .exploratory:
            raw = PlaneImplicitFallbackPolicy.maxGridResolution
        }

        let maxByEval = Int(Double(PlaneImplicitFallbackPolicy.maxEvaluationCount).squareRoot())
        let upper = min(PlaneImplicitFallbackPolicy.maxGridResolution, maxByEval)
        return max(64, min(raw, upper))
    }

    private static func variableNames(in expr: Expr) -> Set<String> {
        var result: Set<String> = []

        func collect(_ value: Expr) {
            switch value {
            case .symbol(let symbol):
                switch symbol.role {
                case .variable, .parameter, .unknown:
                    result.insert(symbol.name)
                default:
                    break
                }
            case .add(let values), .multiply(let values), .tuple(let values), .vector(let values):
                values.forEach(collect)
            case .power(let base, let exponent):
                collect(base)
                collect(exponent)
            case .negate(let inner):
                collect(inner)
            case .divide(let numerator, let denominator):
                collect(numerator)
                collect(denominator)
            case .function(_, let arguments):
                arguments.forEach(collect)
            case .equation(let left, let right):
                collect(left)
                collect(right)
            case .relation(let left, _, let right):
                collect(left)
                collect(right)
            case .chainedRelation(let expressions, _):
                expressions.forEach(collect)
            case .piecewise(let branches, let otherwise):
                for branch in branches {
                    collect(branch.value)
                    collect(branch.condition)
                }
                if let otherwise {
                    collect(otherwise)
                }
            case .matrix(let matrix):
                matrix.rows.flatMap { $0 }.forEach(collect)
            case .assignment(let target, let value):
                collect(target)
                collect(value)
            case .functionDefinition(_, let parameters, let body):
                var bodyVars: Set<String> = []
                collect(body)
                bodyVars = result
                for parameter in parameters {
                    bodyVars.remove(parameter.name)
                }
                result = bodyVars
            case .integer, .rational, .decimal, .real, .constant, .unknown:
                break
            }
        }

        collect(expr)
        return result
    }
}
