import Foundation
import Testing
@testable import EMathicaMathCore
import EMathicaDocumentKit
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct PlaneFallbackSamplingServiceTests {
    @Test func bareExpressionWithXFallsBackToExplicitY() {
        let expr = Expr.power(
            base: .symbol(Symbol(name: "x", role: .variable)),
            exponent: .integer(2)
        )
        let resolved = PlaneFallbackSamplingService.resolveIntent(
            expression: expr,
            classification: nil,
            parameterSymbolNames: []
        )
        #expect(resolved?.source == .fallback)
        guard case .explicitY(let sampledExpr, let variable)? = resolved?.intent else {
            Issue.record("Expected explicitY fallback")
            return
        }
        #expect(sampledExpr == expr)
        #expect(variable.name == "x")
    }

    @Test func bareExpressionWithSliderParameterFallsBackToExplicitY() {
        let expr = Expr.multiply([
            .symbol(Symbol(name: "a", role: .parameter)),
            .symbol(Symbol(name: "x", role: .variable))
        ])
        let resolved = PlaneFallbackSamplingService.resolveIntent(
            expression: expr,
            classification: nil,
            parameterSymbolNames: ["a"]
        )
        #expect(resolved?.source == .fallback)
        guard case .explicitY = resolved?.intent else {
            Issue.record("Expected explicitY fallback for slider-dependent expression")
            return
        }
    }

    @Test func tupleDoesNotFallbackToExplicitFunction() {
        let tuple = Expr.tuple([.integer(1), .integer(2)])
        let resolved = PlaneFallbackSamplingService.resolveIntent(
            expression: tuple,
            classification: nil,
            parameterSymbolNames: []
        )
        #expect(resolved == nil)
    }

    @Test func unknownClassificationCanFallbackToExplicitYEquation() {
        let rhs = Expr.function(.sin, arguments: [.symbol(Symbol(name: "x", role: .variable))])
        let expr = Expr.equation(
            left: .symbol(Symbol(name: "y", role: .variable)),
            right: rhs
        )
        let classification = GraphClassificationResult(intent: .unknown(expr))
        let resolved = PlaneFallbackSamplingService.resolveIntent(
            expression: expr,
            classification: classification,
            parameterSymbolNames: []
        )
        #expect(resolved?.source == .fallback)
        guard case .explicitY(let sampledExpr, _)? = resolved?.intent else {
            Issue.record("Expected explicitY fallback from unknown classification")
            return
        }
        #expect(sampledExpr == rhs)
    }

    @Test func implicitFallbackCanSampleWhenClassificationMissing() {
        let x = Expr.symbol(Symbol(name: "x", role: .variable))
        let y = Expr.symbol(Symbol(name: "y", role: .variable))
        let relation = Expr.equation(
            left: .add([
                .power(base: x, exponent: .integer(2)),
                .power(base: y, exponent: .integer(2))
            ]),
            right: .integer(1)
        )
        let input = FormulaInputState(
            semanticState: .init(
                expression: relation,
                diagnostics: [],
                graphClassification: nil
            ),
            source: "x^2+y^2=1",
            displayLatex: "x^2+y^2=1",
            computeExpression: "x^2+y^2=1"
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
        #expect(draft?.previewSamples.isEmpty == false)
    }

    @Test func equationWithXAndYFallsBackToImplicit() {
        let x = Expr.symbol(Symbol(name: "x", role: .variable))
        let y = Expr.symbol(Symbol(name: "y", role: .variable))
        let expr = Expr.equation(
            left: .add([
                .power(base: x, exponent: .integer(2)),
                .power(base: y, exponent: .integer(2))
            ]),
            right: .integer(1)
        )
        let resolved = PlaneFallbackSamplingService.resolveIntent(
            expression: expr,
            classification: GraphClassificationResult(intent: .unknown(expr)),
            parameterSymbolNames: []
        )
        #expect(resolved?.source == .fallback)
        guard case .implicit(let relation)? = resolved?.intent else {
            Issue.record("Expected implicit fallback")
            return
        }
        #expect(relation == expr)
    }

    @Test func bareExpressionWithXAndYFallsBackToImplicitZeroEquation() {
        let x = Expr.symbol(Symbol(name: "x", role: .variable))
        let y = Expr.symbol(Symbol(name: "y", role: .variable))
        let expr = Expr.add([
            .power(base: x, exponent: .integer(2)),
            .power(base: y, exponent: .integer(2)),
            .negate(.integer(1))
        ])
        let resolved = PlaneFallbackSamplingService.resolveIntent(
            expression: expr,
            classification: nil,
            parameterSymbolNames: []
        )
        guard case .implicit(let relation)? = resolved?.intent else {
            Issue.record("Expected implicit fallback for bare expression with x and y")
            return
        }
        guard case .equation(let left, let right) = relation else {
            Issue.record("Expected implicit equation relation")
            return
        }
        #expect(left == expr)
        #expect(right == .integer(0))
    }

    @Test func explicitYPriorityBeatsImplicitFallback() {
        let x = Expr.symbol(Symbol(name: "x", role: .variable))
        let expr = Expr.equation(
            left: .symbol(Symbol(name: "y", role: .variable)),
            right: .power(base: x, exponent: .integer(2))
        )
        let resolved = PlaneFallbackSamplingService.resolveIntent(
            expression: expr,
            classification: GraphClassificationResult(intent: .unknown(expr)),
            parameterSymbolNames: []
        )
        guard case .explicitY? = resolved?.intent else {
            Issue.record("Expected explicitY to keep priority")
            return
        }
    }

    @Test func explicitXPriorityBeatsImplicitFallback() {
        let y = Expr.symbol(Symbol(name: "y", role: .variable))
        let expr = Expr.equation(
            left: .symbol(Symbol(name: "x", role: .variable)),
            right: .power(base: y, exponent: .integer(2))
        )
        let resolved = PlaneFallbackSamplingService.resolveIntent(
            expression: expr,
            classification: GraphClassificationResult(intent: .unknown(expr)),
            parameterSymbolNames: []
        )
        guard case .explicitX? = resolved?.intent else {
            Issue.record("Expected explicitX to keep priority")
            return
        }
    }

    @Test func implicitFallbackSamplingSupportsParameterEnvironment() {
        let x = Expr.symbol(Symbol(name: "x", role: .variable))
        let y = Expr.symbol(Symbol(name: "y", role: .variable))
        let a = Expr.symbol(Symbol(name: "a", role: .parameter))
        let relation = Expr.equation(
            left: .add([
                .power(base: x, exponent: .integer(2)),
                .power(base: y, exponent: .integer(2))
            ]),
            right: a
        )
        let resolved = PlaneFallbackSamplingService.resolveIntent(
            expression: relation,
            classification: GraphClassificationResult(intent: .unknown(relation)),
            parameterSymbolNames: ["a"]
        )
        guard let intent = resolved?.intent else {
            Issue.record("Expected resolved fallback intent")
            return
        }

        let viewport = SamplingViewport2D(
            xRange: .init(lower: -2, upper: 2),
            yRange: .init(lower: -2, upper: 2),
            pixelWidth: 1024,
            pixelHeight: 768
        )
        let sampler = PlaneFallbackSamplingService.sampler(qualityProfile: .preview)
        let sampleSet = sampler.sample(
            intent: intent,
            xRange: viewport.xRange,
            yRange: viewport.yRange,
            viewport: viewport,
            environment: .variables(["a": 1])
        )
        #expect(sampleSet.segments.isEmpty == false)
    }

    @Test func implicitFallbackPolicyConstantsStayBounded() {
        #expect(PlaneImplicitFallbackPolicy.previewGridResolution <= PlaneImplicitFallbackPolicy.renderGridResolution)
        #expect(PlaneImplicitFallbackPolicy.renderGridResolution <= PlaneImplicitFallbackPolicy.maxGridResolution)
        #expect(PlaneImplicitFallbackPolicy.maxSegments > 0)
        #expect(PlaneImplicitFallbackPolicy.maxEvaluationCount > 0)
    }
}
