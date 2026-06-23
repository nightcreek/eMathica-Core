import Foundation
import Testing
@testable import EMathicaMathCore
import EMathicaDocumentKit
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct PlaneSemanticGraphIntentAdapterTests {
    @Test func adapterMapsParametricIntentToSemanticKind() {
        let intent = GraphIntent.parametric2D(
            x: .power(base: .symbol(Symbol(name: "t", role: .parameter)), exponent: .integer(2)),
            y: .multiply([.integer(2), .symbol(Symbol(name: "t", role: .parameter))]),
            parameter: Symbol(name: "t", role: .parameter),
            range: nil
        )
        let kind = PlaneSemanticGraphIntentAdapter.semanticGraphKind(from: intent)
        #expect(kind == .parametric2D)
    }

    @Test func metadataPrefersSemanticKindForParametric() {
        let text = PlaneSemanticGraphIntentAdapter.metadataText(
            semanticGraphKind: .parametric2D,
            semanticParameterSymbol: nil,
            semanticParameterRange: nil,
            algebraAnalysis: nil
        )
        #expect(text == "参数方程")
    }

    @Test func metadataFallsBackToLegacyWhenSemanticMissing() {
        let analysis = AlgebraCore.analyzePlaneLatex("x=y^2")
        let text = PlaneSemanticGraphIntentAdapter.metadataText(
            semanticGraphKind: nil,
            semanticParameterSymbol: nil,
            semanticParameterRange: nil,
            algebraAnalysis: analysis
        )
        #expect(text != nil)
        #expect(text?.contains("x=f(y)") == true)
    }

    @Test func metadataIncludesRangeForParametric() {
        let text = PlaneSemanticGraphIntentAdapter.metadataText(
            semanticGraphKind: .parametric2D,
            semanticParameterSymbol: Symbol(name: "t", role: .parameter),
            semanticParameterRange: .init(lower: .integer(0), upper: .integer(1)),
            algebraAnalysis: nil
        )
        #expect(text == "参数方程 · 0 < t < 1")
    }

    @Test func metadataFormatsPiRangeForParametric() {
        let text = PlaneSemanticGraphIntentAdapter.metadataText(
            semanticGraphKind: .parametric2D,
            semanticParameterSymbol: Symbol(name: "t", role: .parameter),
            semanticParameterRange: .init(
                lower: .integer(0),
                upper: .multiply([.integer(2), .constant(.pi)])
            ),
            algebraAnalysis: nil
        )
        #expect(text == "参数方程 · 0 < t < 2π")
    }

    @Test func metadataFormatsPiRangeForPolar() {
        let text = PlaneSemanticGraphIntentAdapter.metadataText(
            semanticGraphKind: .polar,
            semanticParameterSymbol: Symbol(name: "θ", role: .parameter),
            semanticParameterRange: .init(
                lower: .integer(0),
                upper: .multiply([.integer(2), .constant(.pi)])
            ),
            algebraAnalysis: nil
        )
        #expect(text == "极坐标曲线 · 0 < θ < 2π")
    }

    @Test func metadataTextForPolarWithoutRange() {
        let text = PlaneSemanticGraphIntentAdapter.metadataText(
            semanticGraphKind: .polar,
            semanticParameterSymbol: Symbol(name: "θ", role: .parameter),
            semanticParameterRange: nil,
            algebraAnalysis: nil
        )
        #expect(text == "极坐标曲线")
    }

    @Test func metadataTextForCircle() {
        let text = PlaneSemanticGraphIntentAdapter.metadataText(
            semanticGraphKind: .circle,
            semanticParameterSymbol: nil,
            semanticParameterRange: nil,
            algebraAnalysis: nil
        )
        #expect(text == "圆")
    }

    @Test func metadataTextForPoint() {
        let text = PlaneSemanticGraphIntentAdapter.metadataText(
            semanticGraphKind: .point,
            semanticParameterSymbol: nil,
            semanticParameterRange: nil,
            algebraAnalysis: nil
        )
        #expect(text == "点")
    }

    @Test func originCircleEquationSemanticKindAndPreview() {
        let x = Expr.symbol(Symbol(name: "x", role: .variable))
        let y = Expr.symbol(Symbol(name: "y", role: .variable))
        let expr = Expr.equation(
            left: .add([
                .power(base: x, exponent: .integer(2)),
                .power(base: y, exponent: .integer(2))
            ]),
            right: .integer(1)
        )
        let classification = GraphClassifier().classify(expr)
        guard case .circle = classification.intent else {
            Issue.record("Expected circle intent, got \(classification.intent)")
            return
        }
        #expect(PlaneSemanticGraphIntentAdapter.semanticGraphKind(from: classification.intent) == .circle)

        let now = Date()
        let metadata = ProjectMetadata(
            title: "Plane",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: []
        )
        let input = FormulaInputState(
            semanticState: .init(expression: expr, diagnostics: [], graphClassification: classification),
            source: "x^2+y^2=1",
            displayLatex: "x^2+y^2=1",
            computeExpression: "x^2+y^2=1"
        )
        let draft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: input,
            document: document,
            previous: nil
        )
        #expect(draft?.previewSamples.isEmpty == false)
    }

    @Test func metadataTextForPiecewise() {
        let text = PlaneSemanticGraphIntentAdapter.metadataText(
            semanticGraphKind: .piecewise,
            semanticParameterSymbol: nil,
            semanticParameterRange: nil,
            algebraAnalysis: nil
        )
        #expect(text == "分段函数")
    }

    @Test func metadataTextForImplicit() {
        let text = PlaneSemanticGraphIntentAdapter.metadataText(
            semanticGraphKind: .implicit,
            semanticParameterSymbol: nil,
            semanticParameterRange: nil,
            algebraAnalysis: nil
        )
        #expect(text == "隐函数")
    }

    @Test func adapterMapsConicKindToSemanticKinds() {
        #expect(
            PlaneSemanticGraphIntentAdapter.semanticGraphKind(
                from: .conic(.init(kind: .ellipse, source: .unknown("e")))
            ) == .ellipse
        )
        #expect(
            PlaneSemanticGraphIntentAdapter.semanticGraphKind(
                from: .conic(.init(kind: .hyperbola, source: .unknown("h")))
            ) == .hyperbola
        )
        #expect(
            PlaneSemanticGraphIntentAdapter.semanticGraphKind(
                from: .conic(.init(kind: .parabola, source: .unknown("p")))
            ) == .parabola
        )
        #expect(
            PlaneSemanticGraphIntentAdapter.semanticGraphKind(
                from: .conic(.init(kind: .unknown, source: .unknown("u")))
            ) == .conic
        )
    }

    @Test func metadataTextForConicKinds() {
        #expect(
            PlaneSemanticGraphIntentAdapter.metadataText(
                semanticGraphKind: .ellipse,
                semanticParameterSymbol: nil,
                semanticParameterRange: nil,
                algebraAnalysis: nil
            ) == "椭圆"
        )
        #expect(
            PlaneSemanticGraphIntentAdapter.metadataText(
                semanticGraphKind: .hyperbola,
                semanticParameterSymbol: nil,
                semanticParameterRange: nil,
                algebraAnalysis: nil
            ) == "双曲线"
        )
        #expect(
            PlaneSemanticGraphIntentAdapter.metadataText(
                semanticGraphKind: .parabola,
                semanticParameterSymbol: nil,
                semanticParameterRange: nil,
                algebraAnalysis: nil
            ) == "抛物线"
        )
        #expect(
            PlaneSemanticGraphIntentAdapter.metadataText(
                semanticGraphKind: .conic,
                semanticParameterSymbol: nil,
                semanticParameterRange: nil,
                algebraAnalysis: nil
            ) == "圆锥曲线"
        )
    }

    @Test func draftPreviewUsesSemanticParametricSamplingForBraceSystem() {
        let content = MathNode.sequence([
            .character("x"), .operatorSymbol("="), .character("t"), .operatorSymbol("^"), .character("2"),
            .character(","),
            .character("y"), .operatorSymbol("="), .character("2"), .character("t")
        ])
        let braces = TemplateNode(kind: .braces, fields: [
            .init(id: .content, node: content)
        ])
        var input = FormulaInputState(editorState: EditorState(root: .sequence([.template(braces)])))
        input.syncDerivedStrings()

        let now = Date()
        let metadata = ProjectMetadata(
            title: "Plane",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: []
        )

        let draft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: input,
            document: document,
            previous: nil
        )
        #expect(draft != nil)
        #expect(draft?.previewSamples.isEmpty == false)
    }

    @Test func draftPreviewUsesSemanticSamplingForExpandedCircleEqualsZero() {
        let x = Expr.symbol(Symbol(name: "x", role: .variable))
        let y = Expr.symbol(Symbol(name: "y", role: .variable))
        let expr = Expr.equation(
            left: .add([
                .power(base: x, exponent: .integer(2)),
                .multiply([.integer(-2), x]),
                .power(base: y, exponent: .integer(2)),
                .multiply([.integer(-4), y]),
                .integer(-4)
            ]),
            right: .integer(0)
        )
        let classification = GraphClassifier().classify(expr)
        let input = FormulaInputState(
            semanticState: .init(
                expression: expr,
                diagnostics: [],
                graphClassification: classification
            ),
            source: "x^2-2x+y^2-4y-4=0",
            displayLatex: "x^2-2x+y^2-4y-4=0",
            computeExpression: "x^2-2x+y^2-4y-4=0",
            isEditing: false
        )

        let now = Date()
        let document = EMathicaDocument(
            metadata: .init(title: "Plane", moduleID: "plane", createdAt: now, updatedAt: now, calculatorType: "plane"),
            moduleID: "plane",
            objects: []
        )
        let draft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: input,
            document: document,
            previous: nil
        )
        #expect(draft != nil)
        #expect(draft?.previewSamples.isEmpty == false)
    }

    @Test func draftPreviewUsesSemanticSamplingForExpandedEllipseEqualsZero() {
        let x = Expr.symbol(Symbol(name: "x", role: .variable))
        let y = Expr.symbol(Symbol(name: "y", role: .variable))
        let expr = Expr.equation(
            left: .add([
                .multiply([.integer(4), .power(base: x, exponent: .integer(2))]),
                .multiply([.integer(9), .power(base: y, exponent: .integer(2))]),
                .integer(-36)
            ]),
            right: .integer(0)
        )
        let classification = GraphClassifier().classify(expr)
        let input = FormulaInputState(
            semanticState: .init(
                expression: expr,
                diagnostics: [],
                graphClassification: classification
            ),
            source: "4x^2+9y^2-36=0",
            displayLatex: "4x^2+9y^2-36=0",
            computeExpression: "4x^2+9y^2-36=0",
            isEditing: false
        )

        let now = Date()
        let document = EMathicaDocument(
            metadata: .init(title: "Plane", moduleID: "plane", createdAt: now, updatedAt: now, calculatorType: "plane"),
            moduleID: "plane",
            objects: []
        )
        let draft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: input,
            document: document,
            previous: nil
        )
        #expect(draft != nil)
        #expect(draft?.previewSamples.isEmpty == false)
    }

    @Test func braceParametricWithConstantYAndRangeClassifiesAsParametric2D() {
        let content = MathNode.sequence([
            .character("x"), .operatorSymbol("="), .character("t"),
            .character(","),
            .character("y"), .operatorSymbol("="), .character("1"),
            .character(","),
            .character("0"), .operatorSymbol("<"), .character("t"), .operatorSymbol("<"), .character("1")
        ])
        let braces = TemplateNode(kind: .braces, fields: [
            .init(id: .content, node: content)
        ])
        var input = FormulaInputState(editorState: EditorState(root: .sequence([.template(braces)])))
        input.syncDerivedStrings()

        guard case .parametric2D(let xExpr, let yExpr, let parameter, let range)? = input.semanticState.graphClassification?.intent else {
            Issue.record("Expected parametric2D, got \(String(describing: input.semanticState.graphClassification?.intent))")
            return
        }
        #expect(xExpr == .symbol(Symbol(name: "t", role: .parameter)))
        #expect(yExpr == .integer(1))
        #expect(parameter.name == "t")
        #expect(range == .init(lower: .integer(0), upper: .integer(1)))
    }

    @Test func braceParametricWithConstantYRangeProducesNonEmptySemanticDraftPreview() {
        let content = MathNode.sequence([
            .character("x"), .operatorSymbol("="), .character("t"),
            .character(","),
            .character("y"), .operatorSymbol("="), .character("1"),
            .character(","),
            .character("0"), .operatorSymbol("<"), .character("t"), .operatorSymbol("<"), .character("1")
        ])
        let braces = TemplateNode(kind: .braces, fields: [
            .init(id: .content, node: content)
        ])
        var input = FormulaInputState(editorState: EditorState(root: .sequence([.template(braces)])))
        input.syncDerivedStrings()

        let now = Date()
        let document = EMathicaDocument(
            metadata: .init(title: "Plane", moduleID: "plane", createdAt: now, updatedAt: now, calculatorType: "plane"),
            moduleID: "plane",
            objects: []
        )

        let draft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: input,
            document: document,
            previous: nil
        )
        #expect(draft != nil)
        #expect(draft?.previewSamples.isEmpty == false)
    }

    @Test func draftPreviewUsesSemanticSamplingForParabolaEqualsZero() {
        let x = Expr.symbol(Symbol(name: "x", role: .variable))
        let y = Expr.symbol(Symbol(name: "y", role: .variable))
        let expr = Expr.equation(
            left: .add([
                .power(base: x, exponent: .integer(2)),
                .negate(y)
            ]),
            right: .integer(0)
        )
        let classification = GraphClassifier().classify(expr)
        #expect(PlaneSemanticGraphIntentAdapter.semanticGraphKind(from: classification.intent) == .parabola)

        let metadataText = PlaneSemanticGraphIntentAdapter.metadataText(
            semanticGraphKind: .parabola,
            semanticParameterSymbol: nil,
            semanticParameterRange: nil,
            algebraAnalysis: nil
        )
        #expect(metadataText == "抛物线")

        let input = FormulaInputState(
            semanticState: .init(
                expression: expr,
                diagnostics: [],
                graphClassification: classification
            ),
            source: "x^2-y=0",
            displayLatex: "x^2-y=0",
            computeExpression: "x^2-y=0",
            isEditing: false
        )

        let now = Date()
        let document = EMathicaDocument(
            metadata: .init(title: "Plane", moduleID: "plane", createdAt: now, updatedAt: now, calculatorType: "plane"),
            moduleID: "plane",
            objects: []
        )
        let draft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: input,
            document: document,
            previous: nil
        )
        #expect(draft != nil)
        #expect(draft?.previewSamples.isEmpty == false)
    }

    @Test func draftPreviewUsesSemanticSamplingForRotatedEllipseEqualsZero() {
        let x = Expr.symbol(Symbol(name: "x", role: .variable))
        let y = Expr.symbol(Symbol(name: "y", role: .variable))
        let expr = Expr.equation(
            left: .add([
                .power(base: x, exponent: .integer(2)),
                .multiply([.integer(2), x, y]),
                .multiply([.integer(3), .power(base: y, exponent: .integer(2))]),
                .integer(-1)
            ]),
            right: .integer(0)
        )
        let classification = GraphClassifier().classify(expr)
        #expect(PlaneSemanticGraphIntentAdapter.semanticGraphKind(from: classification.intent) == .ellipse)

        let now = Date()
        let document = EMathicaDocument(
            metadata: .init(title: "Plane", moduleID: "plane", createdAt: now, updatedAt: now, calculatorType: "plane"),
            moduleID: "plane",
            objects: []
        )
        let input = FormulaInputState(
            semanticState: .init(expression: expr, diagnostics: [], graphClassification: classification),
            source: "x^2+2xy+3y^2-1=0",
            displayLatex: "x^2+2xy+3y^2-1=0",
            computeExpression: "x^2+2xy+3y^2-1=0",
            isEditing: false
        )
        let draft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: input,
            document: document,
            previous: nil
        )
        #expect(draft != nil)
        #expect(draft?.previewSamples.isEmpty == false)
    }

    @Test func draftPreviewUsesSemanticSamplingForRotatedHyperbolaEqualsZero() {
        let x = Expr.symbol(Symbol(name: "x", role: .variable))
        let y = Expr.symbol(Symbol(name: "y", role: .variable))
        let expr = Expr.equation(
            left: .add([
                .power(base: x, exponent: .integer(2)),
                .multiply([.integer(4), x, y]),
                .power(base: y, exponent: .integer(2)),
                .integer(-1)
            ]),
            right: .integer(0)
        )
        let classification = GraphClassifier().classify(expr)
        #expect(PlaneSemanticGraphIntentAdapter.semanticGraphKind(from: classification.intent) == .hyperbola)

        let now = Date()
        let document = EMathicaDocument(
            metadata: .init(title: "Plane", moduleID: "plane", createdAt: now, updatedAt: now, calculatorType: "plane"),
            moduleID: "plane",
            objects: []
        )
        let input = FormulaInputState(
            semanticState: .init(expression: expr, diagnostics: [], graphClassification: classification),
            source: "x^2+4xy+y^2-1=0",
            displayLatex: "x^2+4xy+y^2-1=0",
            computeExpression: "x^2+4xy+y^2-1=0",
            isEditing: false
        )
        let draft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: input,
            document: document,
            previous: nil
        )
        #expect(draft != nil)
        #expect(draft?.previewSamples.isEmpty == false)
    }
}
