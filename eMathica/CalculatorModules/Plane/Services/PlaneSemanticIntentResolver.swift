import EMathicaWorkspaceKit
import Foundation
import EMathicaMathCore

enum PlaneSemanticIntentResolver {
    static func resolveIntentResultWithDiagnostics(
        for expression: MathExpression,
        parameterSymbolNames: Set<String> = [],
        source: FormulaPlotDiagnosticSource = .committed
    ) -> (resolved: PlaneResolvedIntent?, diagnostics: [FormulaPlotDiagnostic]) {
        var diagnostics: [FormulaPlotDiagnostic] = []

        guard let astJSON = expression.editorASTData,
              let astData = astJSON.data(using: .utf8) else {
            diagnostics.append(
                FormulaPlotDiagnostic(
                    stage: .serialization,
                    severity: .error,
                    code: "missing_editor_ast_data",
                    message: "缺少 editor AST 数据，无法进行语义解析",
                    source: source
                )
            )
            return (nil, diagnostics)
        }

        guard let editorState = try? JSONDecoder().decode(EditorState.self, from: astData) else {
            diagnostics.append(
                FormulaPlotDiagnostic(
                    stage: .serialization,
                    severity: .error,
                    code: "invalid_editor_ast_data",
                    message: "editor AST 数据损坏或无法解码",
                    source: source
                )
            )
            return (nil, diagnostics)
        }

        let symbolTable = SymbolTable(
            symbols: Dictionary(
                uniqueKeysWithValues: parameterSymbolNames.map { name in
                    (name, Symbol(name: name, role: .parameter))
                }
            )
        )

        let lowered = MathNodeSemanticLowering().lower(
            editorState.root,
            context: LoweringContext(mode: .expression, symbolTable: symbolTable)
        )
        diagnostics.append(contentsOf: lowered.diagnostics.map { FormulaPlotDiagnostic.fromExpr($0, source: source) })
        guard !lowered.diagnostics.contains(where: { $0.severity == .error }),
              let expr = lowered.expr else {
            return (nil, diagnostics)
        }

        let classification = GraphClassifier(parameterSymbolNames: parameterSymbolNames).classify(expr)
        let fallbackResolved = PlaneFallbackSamplingService.resolveIntentWithDiagnostics(
            expression: expr,
            classification: classification,
            parameterSymbolNames: parameterSymbolNames,
            source: source
        )
        diagnostics.append(contentsOf: fallbackResolved.diagnostics)
        guard var resolved = fallbackResolved.resolved else {
            return (nil, diagnostics)
        }
        applyPersistedParameterRangeIfNeeded(expression: expression, intent: &resolved.intent)
        return (resolved, diagnostics)
    }

    static func resolveIntentResult(
        for expression: MathExpression,
        parameterSymbolNames: Set<String> = []
    ) -> PlaneResolvedIntent? {
        resolveIntentResultWithDiagnostics(
            for: expression,
            parameterSymbolNames: parameterSymbolNames
        ).resolved
    }

    static func resolveIntent(
        for expression: MathExpression,
        parameterSymbolNames: Set<String> = []
    ) -> GraphIntent? {
        resolveIntentResult(
            for: expression,
            parameterSymbolNames: parameterSymbolNames
        )?.intent
    }

    private static func applyPersistedParameterRangeIfNeeded(
        expression: MathExpression,
        intent: inout GraphIntent
    ) {
        guard let persistedRange = expression.semanticParameterRange else { return }
        guard let persistedSymbol = expression.semanticParameterSymbol else { return }

        switch intent {
        case .parametric2D(let xExpr, let yExpr, let parameter, let range):
            guard range == nil, parameter.name == persistedSymbol.name else { return }
            intent = .parametric2D(
                x: xExpr,
                y: yExpr,
                parameter: parameter,
                range: persistedRange
            )
        case .polar(let radius, let angle, let range):
            guard range == nil, angle.name == persistedSymbol.name else { return }
            intent = .polar(
                radius: radius,
                angle: angle,
                range: persistedRange
            )
        default:
            return
        }
    }
}
