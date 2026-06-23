import Foundation
import Testing
@testable import EMathicaMathCore
import EMathicaDocumentKit
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct PlaneDiagnosticsTests {
    @Test func semanticResolverReportsSerializationDiagnosticWhenASTMissing() {
        let expression = MathExpression(displayText: "y=x")
        let result = PlaneSemanticIntentResolver.resolveIntentResultWithDiagnostics(for: expression)
        #expect(result.resolved == nil)
        #expect(result.diagnostics.contains { $0.stage == .serialization && $0.code == "missing_editor_ast_data" })
    }

    @Test func semanticResolverReportsSerializationDiagnosticWhenASTInvalid() {
        let expression = MathExpression(displayText: "y=x", editorASTData: "{invalid-json")
        let result = PlaneSemanticIntentResolver.resolveIntentResultWithDiagnostics(for: expression)
        #expect(result.resolved == nil)
        #expect(result.diagnostics.contains { $0.stage == .serialization && $0.code == "invalid_editor_ast_data" })
    }

    @Test func fallbackResolverReportsRejectionForUnsupportedTupleShape() {
        let expr = Expr.tuple([
            .integer(1),
            .integer(2),
            .integer(3)
        ])
        let result = PlaneFallbackSamplingService.resolveIntentWithDiagnostics(
            expression: expr,
            classification: nil,
            parameterSymbolNames: [],
            source: .draft
        )
        #expect(result.resolved == nil)
        #expect(result.diagnostics.contains { $0.stage == .fallback && $0.code == "fallback_rejected_expression_shape" })
    }

    @Test func fallbackResolverUnknownClassificationCanReportFallbackApplied() {
        let expr = Expr.function(.sin, arguments: [.symbol(.init(name: "x", role: .variable))])
        let unknown = GraphClassificationResult(intent: .unknown(expr))
        let result = PlaneFallbackSamplingService.resolveIntentWithDiagnostics(
            expression: expr,
            classification: unknown,
            parameterSymbolNames: [],
            source: .committed
        )
        #expect(result.resolved != nil)
        #expect(result.diagnostics.contains { $0.stage == .fallback && $0.code == "classification_unknown_fallback_applied" })
    }

    @Test func samplingDiagnosticsReportEmptySampleSetAndIssues() {
        let sampleSet = SampleSet2D(
            segments: [],
            issues: [.init(kind: .evaluationUndefined, message: "division by zero")]
        )
        let diagnostics = PlaneFallbackSamplingService.diagnosticsForSampleSet(
            sampleSet,
            intent: .explicitY(expression: .integer(1), variable: .init(name: "x", role: .variable)),
            source: .draft
        )
        #expect(diagnostics.contains { $0.stage == .sampling && $0.code == SamplingIssueKind.evaluationUndefined.rawValue })
        #expect(diagnostics.contains { $0.stage == .sampling && $0.code == "empty_sample_set" })
    }

    @Test func draftPreviewCarriesDiagnosticsForInvalidSemanticState() {
        let now = Date()
        let document = EMathicaDocument(
            metadata: .init(title: "Plane", moduleID: "plane", createdAt: now, updatedAt: now, calculatorType: "plane"),
            moduleID: "plane",
            objects: []
        )
        let input = FormulaInputState(
            semanticState: .init(expression: nil, diagnostics: [], graphClassification: nil),
            source: "complex",
            displayLatex: "complex",
            computeExpression: "complex"
        )
        let draft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: input,
            document: document,
            previous: nil
        )
        #expect(draft != nil)
        #expect(draft?.diagnostics.isEmpty == false)
    }

    @Test func presenterPrioritizesErrorOverWarningAndInfo() {
        let diagnostics: [FormulaPlotDiagnostic] = [
            .init(stage: .sampling, severity: .info, code: "i1", message: "info", source: .draft),
            .init(stage: .classification, severity: .warning, code: "w1", message: "warning", source: .draft),
            .init(stage: .parse, severity: .error, code: "e1", message: "error", source: .draft)
        ]
        let presentation = FormulaDiagnosticPresenter.topPresentation(from: diagnostics, includeInfo: true)
        #expect(presentation?.severity == .error)
        #expect(presentation?.message == "error")
    }

    @Test func presenterSkipsInfoByDefault() {
        let diagnostics: [FormulaPlotDiagnostic] = [
            .init(stage: .sampling, severity: .info, code: "i1", message: "info only", source: .draft)
        ]
        #expect(FormulaDiagnosticPresenter.topPresentation(from: diagnostics) == nil)
        #expect(FormulaDiagnosticPresenter.topPresentation(from: diagnostics, includeInfo: true)?.severity == .info)
    }

    @Test func presenterPreservesOriginalOrderWithinSameSeverity() {
        let diagnostics: [FormulaPlotDiagnostic] = [
            .init(stage: .sampling, severity: .warning, code: "w1", message: "first warning", source: .draft),
            .init(stage: .fallback, severity: .warning, code: "w2", message: "second warning", source: .draft)
        ]
        let presentation = FormulaDiagnosticPresenter.topPresentation(from: diagnostics, includeInfo: false)
        #expect(presentation?.code == "w1")
    }

    @Test func presenterProvidesFallbackMessageForEmptyDiagnosticMessage() {
        let diagnostics: [FormulaPlotDiagnostic] = [
            .init(stage: .sampling, severity: .error, code: "empty", message: "   ", source: .draft)
        ]
        let presentation = FormulaDiagnosticPresenter.topPresentation(from: diagnostics)
        #expect(presentation?.message.contains("empty") == true)
    }

    @Test func presenterHandlesCommittedAlgebraDiagnostics() {
        let diagnostics: [AlgebraDiagnostic] = [
            .init(severity: .warning, message: "unsupported branch"),
            .init(severity: .error, message: "parse failed")
        ]
        let presentation = FormulaDiagnosticPresenter.topPresentation(from: diagnostics, includeInfo: false)
        #expect(presentation?.severity == .error)
        #expect(presentation?.message == "parse failed")
    }

    @Test func malformedChainedRangeStillReportsDiagnostic() {
        let template = TemplateNode(
            kind: .parametricEquation2D,
            fields: [
                .init(id: .parametricExpression(0), node: .sequence([.character("t")])),
                .init(id: .parametricExpression(1), node: .sequence([.character("t")])),
                .init(id: .parametricRange, node: .sequence([
                    .character("0"), .operatorSymbol("<"), .operatorSymbol("<"), .character("t")
                ]))
            ]
        )
        var input = FormulaInputState(editorState: EditorState(root: .sequence([.template(template)])))
        input.syncDerivedStrings()
        #expect(input.semanticState.diagnostics.contains { $0.severity == .error })
    }
}
