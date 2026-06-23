import Foundation
import CoreGraphics
import Testing
@testable import EMathicaMathCore
import EMathicaDocumentKit
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct PlaneSemanticPreviewPolicyTests {
    @Test func samplingViewportResolverUsesRealCanvasPixelSize() {
        let xRange = SamplingRange(lower: -2, upper: 2)
        let yRange = SamplingRange(lower: -1, upper: 3)
        let viewport = PlaneSamplingViewportResolver.makeViewport(
            xRange: xRange,
            yRange: yRange,
            canvasPixelSize: CGSize(width: 1440, height: 900)
        )
        #expect(viewport.pixelWidth == 1440)
        #expect(viewport.pixelHeight == 900)
        #expect(viewport.xRange == xRange)
        #expect(viewport.yRange == yRange)
    }

    @Test func samplingViewportResolverFallsBackWhenCanvasSizeInvalid() {
        let viewportFromNil = PlaneSamplingViewportResolver.makeViewport(
            xRange: .init(lower: -1, upper: 1),
            yRange: .init(lower: -1, upper: 1),
            canvasPixelSize: nil
        )
        #expect(viewportFromNil.pixelWidth == 1024)
        #expect(viewportFromNil.pixelHeight == 640)

        let viewportFromZero = PlaneSamplingViewportResolver.makeViewport(
            xRange: .init(lower: -1, upper: 1),
            yRange: .init(lower: -1, upper: 1),
            canvasPixelSize: CGSize(width: 0, height: 0)
        )
        #expect(viewportFromZero.pixelWidth == 1024)
        #expect(viewportFromZero.pixelHeight == 640)
    }

    @Test func samplingQualityPolicyUsesPreviewWhenInteracting() {
        let policy = PlaneSamplingQualityPolicy()
        #expect(policy.qualityProfile(isInteracting: true, userPreferred: .balanced) == .preview)
    }

    @Test func samplingQualityPolicyUsesUserPreferredWhenNotInteracting() {
        let policy = PlaneSamplingQualityPolicy()
        #expect(policy.qualityProfile(isInteracting: false, userPreferred: .precise) == .precise)
    }

    @Test func samplingQualityPolicyDefaultsToBalancedWhenNotInteracting() {
        let policy = PlaneSamplingQualityPolicy()
        #expect(policy.qualityProfile(isInteracting: false) == .balanced)
    }

    @Test func samplingQualityPolicyUsesPreviewWhenCanvasInteracting() {
        let policy = PlaneSamplingQualityPolicy()
        #expect(
            policy.qualityProfile(
                isInputEditing: false,
                isCanvasInteracting: true,
                userPreferred: .balanced
            ) == .preview
        )
    }

    @Test func samplingQualityPolicyUsesPreviewWhenEitherInputOrCanvasInteracting() {
        let policy = PlaneSamplingQualityPolicy()
        #expect(
            policy.qualityProfile(
                isInputEditing: true,
                isCanvasInteracting: false,
                userPreferred: .precise
            ) == .preview
        )
        #expect(
            policy.qualityProfile(
                isInputEditing: false,
                isCanvasInteracting: true,
                userPreferred: .precise
            ) == .preview
        )
    }

    @Test func policyEnablesParametricPolarPointCirclePiecewise() {
        let policy = PlaneSemanticPreviewPolicy()
        #expect(policy.shouldUseSemanticPreview(for: .parametric2D(
            x: .symbol(.init(name: "t", role: .parameter)),
            y: .power(base: .symbol(.init(name: "t", role: .parameter)), exponent: .integer(2)),
            parameter: .init(name: "t", role: .parameter),
            range: nil
        )))
        #expect(policy.shouldUseSemanticPreview(for: .polar(
            radius: .integer(1),
            angle: .init(name: "t", role: .parameter),
            range: nil
        )))
        #expect(policy.shouldUseSemanticPreview(for: .point(x: .integer(1), y: .integer(2))))
        #expect(policy.shouldUseSemanticPreview(for: .circle(
            center: .tuple([.integer(0), .integer(0)]),
            radius: .integer(1)
        )))
        #expect(policy.shouldUseSemanticPreview(for: .piecewise([
            .init(
                condition: .relation(
                    left: .symbol(.init(name: "x", role: .variable)),
                    relation: .less,
                    right: .integer(0)
                ),
                intent: .explicitY(
                    expression: .power(base: .symbol(.init(name: "x", role: .variable)), exponent: .integer(2)),
                    variable: .init(name: "x", role: .variable)
                )
            )
        ])))
    }

    @Test func policyEnablesImplicitButKeepsExplicitDisabledByDefault() {
        let policy = PlaneSemanticPreviewPolicy()
        #expect(policy.shouldUseSemanticPreview(for: .explicitY(
            expression: .power(base: .symbol(.init(name: "x", role: .variable)), exponent: .integer(2)),
            variable: .init(name: "x", role: .variable)
        )) == false)
        #expect(policy.shouldUseSemanticPreview(for: .explicitX(
            expression: .power(base: .symbol(.init(name: "y", role: .variable)), exponent: .integer(2)),
            variable: .init(name: "y", role: .variable)
        )) == false)
        #expect(policy.shouldUseSemanticPreview(for: .implicit(
            relation: .equation(
                left: .add([
                    .power(base: .symbol(.init(name: "x", role: .variable)), exponent: .integer(2)),
                    .power(base: .symbol(.init(name: "y", role: .variable)), exponent: .integer(2))
                ]),
                right: .integer(1)
            )
        )) == true)
        #expect(policy.shouldUseSemanticPreview(for: .conic(.init(kind: .unknown, source: .unknown("raw")))) == true)
    }

    @Test func draftPreviewUsesPreviewQualityWhenEditingAndBalancedWhenStable() {
        let now = Date()
        let document = EMathicaDocument(
            metadata: .init(title: "Plane", moduleID: "plane", createdAt: now, updatedAt: now, calculatorType: "plane"),
            moduleID: "plane",
            objects: []
        )
        let relation = Expr.equation(
            left: .add([
                .power(base: .symbol(.init(name: "x", role: .variable)), exponent: .integer(2)),
                .power(base: .symbol(.init(name: "y", role: .variable)), exponent: .integer(2))
            ]),
            right: .integer(1)
        )

        let stableInput = FormulaInputState(
            semanticState: .init(expression: relation, diagnostics: [], graphClassification: .init(intent: .implicit(relation: relation))),
            source: "x^2+y^2=1",
            displayLatex: "x^2+y^2=1",
            computeExpression: "x^2+y^2=1",
            isEditing: false
        )
        let editingInput = FormulaInputState(
            semanticState: .init(expression: relation, diagnostics: [], graphClassification: .init(intent: .implicit(relation: relation))),
            source: "x^2+y^2=1",
            displayLatex: "x^2+y^2=1",
            computeExpression: "x^2+y^2=1",
            isEditing: true
        )

        let stableDraft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: stableInput,
            document: document,
            previous: nil
        )
        let editingDraft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: editingInput,
            document: document,
            previous: nil
        )
        let stablePoints = stableDraft?.previewSamples.reduce(0) { $0 + $1.points.count } ?? 0
        let editingPoints = editingDraft?.previewSamples.reduce(0) { $0 + $1.points.count } ?? 0
        #expect(stablePoints > 0)
        #expect(editingPoints > 0)
        #expect(editingPoints <= stablePoints)
    }

    @Test func draftPreviewUsesPreviewQualityWhenCanvasIsInteracting() {
        let now = Date()
        let document = EMathicaDocument(
            metadata: .init(title: "Plane", moduleID: "plane", createdAt: now, updatedAt: now, calculatorType: "plane"),
            moduleID: "plane",
            objects: []
        )
        let relation = Expr.equation(
            left: .add([
                .power(base: .symbol(.init(name: "x", role: .variable)), exponent: .integer(2)),
                .power(base: .symbol(.init(name: "y", role: .variable)), exponent: .integer(2))
            ]),
            right: .integer(1)
        )
        let input = FormulaInputState(
            semanticState: .init(expression: relation, diagnostics: [], graphClassification: .init(intent: .implicit(relation: relation))),
            source: "x^2+y^2=1",
            displayLatex: "x^2+y^2=1",
            computeExpression: "x^2+y^2=1",
            isEditing: false
        )

        let stableDraft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: input,
            document: document,
            previous: nil,
            isCanvasInteracting: false
        )
        let interactingDraft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: input,
            document: document,
            previous: nil,
            isCanvasInteracting: true
        )
        let stablePoints = stableDraft?.previewSamples.reduce(0) { $0 + $1.points.count } ?? 0
        let interactingPoints = interactingDraft?.previewSamples.reduce(0) { $0 + $1.points.count } ?? 0
        #expect(stablePoints > 0)
        #expect(interactingPoints > 0)
        #expect(interactingPoints <= stablePoints)
    }

    @Test @MainActor func canvasInteractionStateIsRuntimeOnly() {
        let now = Date()
        let document = EMathicaDocument(
            metadata: .init(title: "Plane", moduleID: "plane", createdAt: now, updatedAt: now, calculatorType: "plane"),
            moduleID: "plane",
            objects: []
        )
        let state = WorkspaceState(
            module: .plane,
            document: document,
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        let beforeCanvas = state.document.canvasState
        state.dispatch(.setCanvasInteracting(true))
        #expect(state.isCanvasInteracting == true)
        #expect(state.document.canvasState == beforeCanvas)
        state.dispatch(.setCanvasInteracting(false))
        #expect(state.isCanvasInteracting == false)
        #expect(state.document.canvasState == beforeCanvas)
    }

    @Test func draftPreviewUsesSemanticPathForPolicyEnabledIntents() {
        let now = Date()
        let document = EMathicaDocument(
            metadata: .init(
                title: "Plane",
                moduleID: "plane",
                createdAt: now,
                updatedAt: now,
                calculatorType: "plane"
            ),
            moduleID: "plane",
            objects: []
        )

        let source = "y=x"
        let pointInput = FormulaInputState(
            semanticState: .init(
                expression: .tuple([.integer(1), .integer(2)]),
                diagnostics: [],
                graphClassification: .init(intent: .point(x: .integer(1), y: .integer(2)))
            ),
            source: source,
            displayLatex: source,
            computeExpression: source
        )
        let pointDraft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: pointInput,
            document: document,
            previous: nil
        )
        #expect(pointDraft != nil)
        #expect(pointDraft?.previewSamples.count == 1)
        #expect(pointDraft?.previewSamples.first?.points.count == 1)

        let polarInput = FormulaInputState(
            semanticState: .init(
                expression: .function(.sin, arguments: [.symbol(.init(name: "t", role: .parameter))]),
                diagnostics: [],
                graphClassification: .init(intent: .polar(
                    radius: .integer(1),
                    angle: .init(name: "t", role: .parameter),
                    range: nil
                ))
            ),
            source: source,
            displayLatex: source,
            computeExpression: source
        )
        let polarDraft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: polarInput,
            document: document,
            previous: nil
        )
        #expect(polarDraft?.previewSamples.isEmpty == false)

        let x = Symbol(name: "x", role: .variable)
        let piecewiseInput = FormulaInputState(
            semanticState: .init(
                expression: .piecewise(
                    branches: [
                        .init(
                            value: .power(base: .symbol(x), exponent: .integer(2)),
                            condition: .relation(left: .symbol(x), relation: .less, right: .integer(0))
                        ),
                        .init(
                            value: .symbol(x),
                            condition: .relation(left: .symbol(x), relation: .greaterOrEqual, right: .integer(0))
                        )
                    ],
                    otherwise: nil
                ),
                diagnostics: [],
                graphClassification: .init(intent: .piecewise([
                    .init(
                        condition: .relation(left: .symbol(x), relation: .less, right: .integer(0)),
                        intent: .explicitY(
                            expression: .power(base: .symbol(x), exponent: .integer(2)),
                            variable: x
                        )
                    ),
                    .init(
                        condition: .relation(left: .symbol(x), relation: .greaterOrEqual, right: .integer(0)),
                        intent: .explicitY(
                            expression: .symbol(x),
                            variable: x
                        )
                    )
                ]))
            ),
            source: source,
            displayLatex: source,
            computeExpression: source
        )
        let piecewiseDraft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: piecewiseInput,
            document: document,
            previous: nil
        )
        #expect(piecewiseDraft?.previewSamples.isEmpty == false)
    }

    @Test func draftPreviewPointWithSliderEnvironmentMovesOnUnitCircle() {
        let now = Date()
        let aSymbol = Symbol(name: "a", role: .parameter)
        let pointExpr = Expr.tuple([
            .function(.sin, arguments: [.symbol(aSymbol)]),
            .function(.cos, arguments: [.symbol(aSymbol)])
        ])
        let pointClassification = GraphClassificationResult(
            intent: .point(
                x: .function(.sin, arguments: [.symbol(aSymbol)]),
                y: .function(.cos, arguments: [.symbol(aSymbol)])
            )
        )

        func makeDocument(a: Double) -> EMathicaDocument {
            let parameter = MathObject(
                name: "a",
                type: .parameter,
                expression: MathExpression(displayText: "a=\(a)"),
                parameterValue: a,
                parameterMin: -10,
                parameterMax: 10,
                sliderSettings: .default,
                style: .init(colorToken: "pink")
            )
            return EMathicaDocument(
                metadata: .init(
                    title: "Plane",
                    moduleID: "plane",
                    createdAt: now,
                    updatedAt: now,
                    calculatorType: "plane"
                ),
                moduleID: "plane",
                objects: [parameter]
            )
        }

        let input = FormulaInputState(
            semanticState: .init(
                expression: pointExpr,
                diagnostics: [],
                graphClassification: pointClassification
            ),
            source: "(sin(a),cos(a))",
            displayLatex: "(sin(a),cos(a))",
            computeExpression: "(sin(a),cos(a))"
        )

        let draftAtZero = PlaneDraftPreviewService.makeDraft(
            formulaInputState: input,
            document: makeDocument(a: 0),
            previous: nil
        )
        let p0 = draftAtZero?.previewSamples.first?.points.first
        #expect(p0 != nil)
        #expect(abs((p0?.x ?? 99) - 0) < 1e-6)
        #expect(abs((p0?.y ?? -99) - 1) < 1e-6)

        let draftAtPiOver2 = PlaneDraftPreviewService.makeDraft(
            formulaInputState: input,
            document: makeDocument(a: Double.pi / 2.0),
            previous: nil
        )
        let p1 = draftAtPiOver2?.previewSamples.first?.points.first
        #expect(p1 != nil)
        #expect(abs((p1?.x ?? -99) - 1) < 1e-5)
        #expect(abs((p1?.y ?? 99) - 0) < 1e-5)
    }

    @Test func draftPreviewUsesParametricRangeInsteadOfDefaultFallback() {
        let now = Date()
        let document = EMathicaDocument(
            metadata: .init(
                title: "Plane",
                moduleID: "plane",
                createdAt: now,
                updatedAt: now,
                calculatorType: "plane"
            ),
            moduleID: "plane",
            objects: []
        )

        let source = "y=x"
        let t = Symbol(name: "t", role: .parameter)
        let input = FormulaInputState(
            semanticState: .init(
                expression: .tuple([
                    .symbol(t),
                    .power(base: .symbol(t), exponent: .integer(2))
                ]),
                diagnostics: [],
                graphClassification: .init(intent: .parametric2D(
                    x: .symbol(t),
                    y: .power(base: .symbol(t), exponent: .integer(2)),
                    parameter: t,
                    range: .init(lower: .integer(0), upper: .integer(1))
                ))
            ),
            source: source,
            displayLatex: source,
            computeExpression: source
        )

        let draft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: input,
            document: document,
            previous: nil
        )
        #expect(draft?.previewSamples.isEmpty == false)

        let allPoints = draft?.previewSamples.flatMap(\.points) ?? []
        #expect(allPoints.isEmpty == false)
        let maxX = allPoints.map(\.x).max() ?? 0
        let maxY = allPoints.map(\.y).max() ?? 0
        #expect(maxX <= 1.05)
        #expect(maxY <= 1.05)
    }

    @Test func draftPreviewConstantYParametricUsesProvidedRange() {
        let now = Date()
        let document = EMathicaDocument(
            metadata: .init(
                title: "Plane",
                moduleID: "plane",
                createdAt: now,
                updatedAt: now,
                calculatorType: "plane"
            ),
            moduleID: "plane",
            objects: []
        )

        let t = Symbol(name: "t", role: .parameter)
        let input = FormulaInputState(
            semanticState: .init(
                expression: .tuple([
                    .symbol(t),
                    .integer(1)
                ]),
                diagnostics: [],
                graphClassification: .init(intent: .parametric2D(
                    x: .symbol(t),
                    y: .integer(1),
                    parameter: t,
                    range: .init(lower: .integer(0), upper: .integer(1))
                ))
            ),
            source: "{x=t, y=1, 0<t<1}",
            displayLatex: "{x=t, y=1, 0<t<1}",
            computeExpression: "{x=t, y=1, 0<t<1}"
        )

        let draft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: input,
            document: document,
            previous: nil
        )
        #expect(draft?.previewSamples.isEmpty == false)

        let points = draft?.previewSamples.flatMap(\.points) ?? []
        #expect(points.isEmpty == false)
        let minX = points.map(\.x).min() ?? .infinity
        let maxX = points.map(\.x).max() ?? -.infinity
        #expect(minX >= -0.05)
        #expect(maxX <= 1.05)
        #expect(points.allSatisfy { abs($0.y - 1) <= 1e-6 })
    }

    @Test func draftPreviewDiagonalParametricUsesProvidedRange() {
        let now = Date()
        let document = EMathicaDocument(
            metadata: .init(
                title: "Plane",
                moduleID: "plane",
                createdAt: now,
                updatedAt: now,
                calculatorType: "plane"
            ),
            moduleID: "plane",
            objects: []
        )

        let t = Symbol(name: "t", role: .parameter)
        let input = FormulaInputState(
            semanticState: .init(
                expression: .tuple([
                    .symbol(t),
                    .symbol(t),
                    .chainedRelation(
                        expressions: [.integer(0), .symbol(t), .integer(1)],
                        relations: [.less, .less]
                    )
                ]),
                diagnostics: [],
                graphClassification: .init(intent: .parametric2D(
                    x: .symbol(t),
                    y: .symbol(t),
                    parameter: t,
                    range: .init(lower: .integer(0), upper: .integer(1))
                ))
            ),
            source: "{x=t, y=t, 0<t<1}",
            displayLatex: "{x=t, y=t, 0<t<1}",
            computeExpression: "{x=t, y=t, 0<t<1}"
        )

        let draft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: input,
            document: document,
            previous: nil
        )
        #expect(draft?.previewSamples.isEmpty == false)

        let points = draft?.previewSamples.flatMap(\.points) ?? []
        #expect(points.isEmpty == false)
        let maxX = points.map(\.x).max() ?? -.infinity
        let maxY = points.map(\.y).max() ?? -.infinity
        #expect(maxX <= 1.05)
        #expect(maxY <= 1.05)
    }

    @Test func draftPreviewDiagonalParametricUpperOnlyRangeUsesVisibleLowerBound() {
        let now = Date()
        let document = EMathicaDocument(
            metadata: .init(
                title: "Plane",
                moduleID: "plane",
                createdAt: now,
                updatedAt: now,
                calculatorType: "plane"
            ),
            moduleID: "plane",
            objects: []
        )

        let t = Symbol(name: "t", role: .parameter)
        let input = FormulaInputState(
            semanticState: .init(
                expression: .tuple([
                    .symbol(t),
                    .symbol(t),
                    .relation(left: .symbol(t), relation: .less, right: .integer(1))
                ]),
                diagnostics: [],
                graphClassification: .init(intent: .parametric2D(
                    x: .symbol(t),
                    y: .symbol(t),
                    parameter: t,
                    range: .init(lower: nil, upper: .integer(1))
                ))
            ),
            source: "{x=t, y=t, t<1}",
            displayLatex: "{x=t, y=t, t<1}",
            computeExpression: "{x=t, y=t, t<1}"
        )

        let draft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: input,
            document: document,
            previous: nil
        )
        #expect(draft?.previewSamples.isEmpty == false)
        let points = draft?.previewSamples.flatMap(\.points) ?? []
        #expect(points.isEmpty == false)
        let maxX = points.map(\.x).max() ?? -.infinity
        let maxY = points.map(\.y).max() ?? -.infinity
        #expect(maxX <= 1.05)
        #expect(maxY <= 1.05)
    }

    @Test func draftPreviewFallsBackToLegacyForPolicyDisabledOrSemanticFailure() {
        let now = Date()
        let document = EMathicaDocument(
            metadata: .init(
                title: "Plane",
                moduleID: "plane",
                createdAt: now,
                updatedAt: now,
                calculatorType: "plane"
            ),
            moduleID: "plane",
            objects: []
        )
        let source = "x^2+y^2=1"

        let explicitInput = FormulaInputState(
            semanticState: .init(
                expression: .power(base: .symbol(.init(name: "x", role: .variable)), exponent: .integer(2)),
                diagnostics: [],
                graphClassification: .init(intent: .explicitY(
                    expression: .power(base: .symbol(.init(name: "x", role: .variable)), exponent: .integer(2)),
                    variable: .init(name: "x", role: .variable)
                ))
            ),
            source: source,
            displayLatex: source,
            computeExpression: source
        )
        let explicitDraft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: explicitInput,
            document: document,
            previous: nil
        )
        #expect(explicitDraft?.previewSamples.isEmpty == false)

        let failedSemanticInput = FormulaInputState(
            semanticState: .init(
                expression: nil,
                diagnostics: [],
                graphClassification: .init(intent: .point(
                    x: .divide(numerator: .integer(1), denominator: .integer(0)),
                    y: .integer(1)
                ))
            ),
            source: source,
            displayLatex: source,
            computeExpression: source
        )
        let failedDraft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: failedSemanticInput,
            document: document,
            previous: nil
        )
        #expect(failedDraft?.previewSamples.isEmpty == false)

        let x = Symbol(name: "x", role: .variable)
        let failedPiecewiseInput = FormulaInputState(
            semanticState: .init(
                expression: .piecewise(
                    branches: [
                        .init(
                            value: .divide(numerator: .integer(1), denominator: .integer(0)),
                            condition: .relation(left: .symbol(x), relation: .less, right: .integer(0))
                        )
                    ],
                    otherwise: nil
                ),
                diagnostics: [],
                graphClassification: .init(intent: .piecewise([
                    .init(
                        condition: .relation(left: .symbol(x), relation: .less, right: .integer(0)),
                        intent: .explicitY(
                            expression: .divide(numerator: .integer(1), denominator: .integer(0)),
                            variable: x
                        )
                    )
                ]))
            ),
            // use legacy explicit form to ensure fallback has usable samples
            source: "y=x",
            displayLatex: "y=x",
            computeExpression: "y=x"
        )
        let failedPiecewiseDraft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: failedPiecewiseInput,
            document: document,
            previous: nil
        )
        #expect(failedPiecewiseDraft?.previewSamples.isEmpty == false)
    }

    @Test func draftPreviewUsesSemanticPathForImplicitCircle() {
        let now = Date()
        let document = EMathicaDocument(
            metadata: .init(title: "Plane", moduleID: "plane", createdAt: now, updatedAt: now, calculatorType: "plane"),
            moduleID: "plane",
            objects: []
        )
        let relation = Expr.equation(
            left: .add([
                .power(base: .symbol(.init(name: "x", role: .variable)), exponent: .integer(2)),
                .power(base: .symbol(.init(name: "y", role: .variable)), exponent: .integer(2))
            ]),
            right: .integer(1)
        )
        let input = FormulaInputState(
            semanticState: .init(expression: relation, diagnostics: [], graphClassification: .init(intent: .implicit(relation: relation))),
            source: "x^2+y^2=1",
            displayLatex: "x^2+y^2=1",
            computeExpression: "x^2+y^2=1"
        )
        let draft = PlaneDraftPreviewService.makeDraft(formulaInputState: input, document: document, previous: nil)
        #expect(draft?.previewSamples.isEmpty == false)
    }

    @Test func draftPreviewUsesSemanticPathForImplicitLineAndHyperbola() {
        let now = Date()
        let document = EMathicaDocument(
            metadata: .init(title: "Plane", moduleID: "plane", createdAt: now, updatedAt: now, calculatorType: "plane"),
            moduleID: "plane",
            objects: []
        )

        let line = Expr.equation(
            left: .add([
                .symbol(.init(name: "y", role: .variable)),
                .negate(.symbol(.init(name: "x", role: .variable)))
            ]),
            right: .integer(0)
        )
        let lineInput = FormulaInputState(
            semanticState: .init(expression: line, diagnostics: [], graphClassification: .init(intent: .implicit(relation: line))),
            source: "y-x=0",
            displayLatex: "y-x=0",
            computeExpression: "y-x=0"
        )
        let lineDraft = PlaneDraftPreviewService.makeDraft(formulaInputState: lineInput, document: document, previous: nil)
        #expect(lineDraft?.previewSamples.isEmpty == false)

        let hyperbola = Expr.equation(
            left: .add([
                .power(base: .symbol(.init(name: "x", role: .variable)), exponent: .integer(2)),
                .negate(.power(base: .symbol(.init(name: "y", role: .variable)), exponent: .integer(2)))
            ]),
            right: .integer(1)
        )
        let hyperbolaInput = FormulaInputState(
            semanticState: .init(expression: hyperbola, diagnostics: [], graphClassification: .init(intent: .implicit(relation: hyperbola))),
            source: "x^2-y^2=1",
            displayLatex: "x^2-y^2=1",
            computeExpression: "x^2-y^2=1"
        )
        let hyperbolaDraft = PlaneDraftPreviewService.makeDraft(formulaInputState: hyperbolaInput, document: document, previous: nil)
        #expect(hyperbolaDraft?.previewSamples.isEmpty == false)
    }

    @Test func draftPreviewUsesSemanticPathForConicEllipseAndHyperbola() {
        let now = Date()
        let document = EMathicaDocument(
            metadata: .init(title: "Plane", moduleID: "plane", createdAt: now, updatedAt: now, calculatorType: "plane"),
            moduleID: "plane",
            objects: []
        )

        let x = Expr.symbol(.init(name: "x", role: .variable))
        let y = Expr.symbol(.init(name: "y", role: .variable))

        let ellipseExpr = Expr.equation(
            left: .add([
                .divide(numerator: .power(base: x, exponent: .integer(2)), denominator: .integer(4)),
                .divide(numerator: .power(base: y, exponent: .integer(2)), denominator: .integer(9))
            ]),
            right: .integer(1)
        )
        let ellipseClassification = GraphClassifier().classify(ellipseExpr)
        guard case .conic = ellipseClassification.intent else {
            Issue.record("Expected conic ellipse intent")
            return
        }

        let ellipseInput = FormulaInputState(
            semanticState: .init(expression: ellipseExpr, diagnostics: [], graphClassification: ellipseClassification),
            source: "x^2/4+y^2/9=1",
            displayLatex: "x^2/4+y^2/9=1",
            computeExpression: "x^2/4+y^2/9=1"
        )
        let ellipseDraft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: ellipseInput,
            document: document,
            previous: nil
        )
        #expect(ellipseDraft?.previewSamples.isEmpty == false)

        let hyperbolaExpr = Expr.equation(
            left: .add([
                .divide(numerator: .power(base: x, exponent: .integer(2)), denominator: .integer(4)),
                .negate(.divide(numerator: .power(base: y, exponent: .integer(2)), denominator: .integer(9)))
            ]),
            right: .integer(1)
        )
        let hyperbolaClassification = GraphClassifier().classify(hyperbolaExpr)
        guard case .conic = hyperbolaClassification.intent else {
            Issue.record("Expected conic hyperbola intent")
            return
        }

        let hyperbolaInput = FormulaInputState(
            semanticState: .init(expression: hyperbolaExpr, diagnostics: [], graphClassification: hyperbolaClassification),
            source: "x^2/4-y^2/9=1",
            displayLatex: "x^2/4-y^2/9=1",
            computeExpression: "x^2/4-y^2/9=1"
        )
        let hyperbolaDraft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: hyperbolaInput,
            document: document,
            previous: nil
        )
        #expect(hyperbolaDraft?.previewSamples.isEmpty == false)
    }

    @Test func draftPreviewUsesSemanticPathForTranslatedConicEllipseAndHyperbola() {
        let now = Date()
        let document = EMathicaDocument(
            metadata: .init(title: "Plane", moduleID: "plane", createdAt: now, updatedAt: now, calculatorType: "plane"),
            moduleID: "plane",
            objects: []
        )

        let x = Expr.symbol(.init(name: "x", role: .variable))
        let y = Expr.symbol(.init(name: "y", role: .variable))

        let translatedEllipseExpr = Expr.equation(
            left: .add([
                .divide(
                    numerator: .power(base: .add([x, .negate(.integer(1))]), exponent: .integer(2)),
                    denominator: .integer(4)
                ),
                .divide(
                    numerator: .power(base: .add([y, .negate(.integer(2))]), exponent: .integer(2)),
                    denominator: .integer(9)
                )
            ]),
            right: .integer(1)
        )
        let ellipseClassification = GraphClassifier().classify(translatedEllipseExpr)
        guard case .conic = ellipseClassification.intent else {
            Issue.record("Expected translated conic ellipse intent")
            return
        }
        let ellipseInput = FormulaInputState(
            semanticState: .init(expression: translatedEllipseExpr, diagnostics: [], graphClassification: ellipseClassification),
            source: "(x-1)^2/4+(y-2)^2/9=1",
            displayLatex: "(x-1)^2/4+(y-2)^2/9=1",
            computeExpression: "(x-1)^2/4+(y-2)^2/9=1"
        )
        let ellipseDraft = PlaneDraftPreviewService.makeDraft(formulaInputState: ellipseInput, document: document, previous: nil)
        #expect(ellipseDraft?.previewSamples.isEmpty == false)

        let translatedHyperbolaExpr = Expr.equation(
            left: .add([
                .divide(
                    numerator: .power(base: .add([x, .negate(.integer(1))]), exponent: .integer(2)),
                    denominator: .integer(4)
                ),
                .negate(
                    .divide(
                        numerator: .power(base: .add([y, .negate(.integer(2))]), exponent: .integer(2)),
                        denominator: .integer(9)
                    )
                )
            ]),
            right: .integer(1)
        )
        let hyperbolaClassification = GraphClassifier().classify(translatedHyperbolaExpr)
        guard case .conic = hyperbolaClassification.intent else {
            Issue.record("Expected translated conic hyperbola intent")
            return
        }
        let hyperbolaInput = FormulaInputState(
            semanticState: .init(expression: translatedHyperbolaExpr, diagnostics: [], graphClassification: hyperbolaClassification),
            source: "(x-1)^2/4-(y-2)^2/9=1",
            displayLatex: "(x-1)^2/4-(y-2)^2/9=1",
            computeExpression: "(x-1)^2/4-(y-2)^2/9=1"
        )
        let hyperbolaDraft = PlaneDraftPreviewService.makeDraft(formulaInputState: hyperbolaInput, document: document, previous: nil)
        #expect(hyperbolaDraft?.previewSamples.isEmpty == false)
    }

    @Test func draftPreviewFallsBackWhenConicCanonicalMissing() {
        let now = Date()
        let document = EMathicaDocument(
            metadata: .init(title: "Plane", moduleID: "plane", createdAt: now, updatedAt: now, calculatorType: "plane"),
            moduleID: "plane",
            objects: []
        )

        let conic = ConicInfo(
            kind: .ellipse,
            source: .unknown("raw"),
            canonicalForm: nil,
            orientation: .axisAligned
        )
        let input = FormulaInputState(
            semanticState: .init(
                expression: .unknown("raw"),
                diagnostics: [],
                graphClassification: .init(intent: .conic(conic))
            ),
            source: "y=x",
            displayLatex: "y=x",
            computeExpression: "y=x"
        )
        let draft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: input,
            document: document,
            previous: nil
        )
        #expect(draft?.previewSamples.isEmpty == false)
    }

    @Test func implicitSemanticFailureFallsBackToLegacyOrLastValid() {
        let now = Date()
        let document = EMathicaDocument(
            metadata: .init(title: "Plane", moduleID: "plane", createdAt: now, updatedAt: now, calculatorType: "plane"),
            moduleID: "plane",
            objects: []
        )
        let previousSamples = [PlotSegment(points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 1, y: 1)])]
        let previous = DraftMathObject(
            ast: EditorState(),
            sourceExpression: "prev",
            displayLatex: "prev",
            computeExpression: "prev",
            parseError: nil,
            previewSamples: previousSamples,
            lastValidPreviewSamples: previousSamples,
            algebraAnalysis: nil,
            diagnostics: []
        )
        let badRelation = Expr.relation(
            left: .symbol(.init(name: "x", role: .variable)),
            relation: .less,
            right: .symbol(.init(name: "y", role: .variable))
        )
        let input = FormulaInputState(
            semanticState: .init(
                expression: badRelation,
                diagnostics: [],
                graphClassification: .init(intent: .implicit(relation: badRelation))
            ),
            source: "x<y",
            displayLatex: "x<y",
            computeExpression: "x<y"
        )
        let draft = PlaneDraftPreviewService.makeDraft(formulaInputState: input, document: document, previous: previous)
        #expect(draft?.previewSamples.isEmpty == false)
    }

    @Test func draftPreviewUsesSemanticPolarRangeFromInputBraceTheta() {
        let now = Date()
        let document = EMathicaDocument(
            metadata: .init(
                title: "Plane",
                moduleID: "plane",
                createdAt: now,
                updatedAt: now,
                calculatorType: "plane"
            ),
            moduleID: "plane",
            objects: []
        )

        let content = MathNode.sequence([
            .character("r"), .operatorSymbol("="), .character("θ"),
            .character(","),
            .character("0"), .operatorSymbol("<="), .character("θ"), .operatorSymbol("<="), .character("2"), .character("π")
        ])
        let braces = TemplateNode(kind: .braces, fields: [.init(id: .content, node: content)])
        var input = FormulaInputState(editorState: EditorState(root: .sequence([.template(braces)])))
        input.syncDerivedStrings()

        if case .polar(_, let angle, let range)? = input.semanticState.graphClassification?.intent {
            #expect(angle.name == "θ")
            #expect(range == .init(lower: .integer(0), upper: .multiply([.integer(2), .constant(.pi)])))
        } else {
            Issue.record("Expected polar intent")
            return
        }

        let draft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: input,
            document: document,
            previous: nil
        )
        #expect(draft?.previewSamples.isEmpty == false)

        let allPoints = draft?.previewSamples.flatMap(\.points) ?? []
        #expect(allPoints.isEmpty == false)
        let maxRadius = allPoints.map { hypot($0.x, $0.y) }.max() ?? 0
        #expect(maxRadius <= (2 * Double.pi + 0.2))
    }

    @Test func draftPreviewUsesSemanticPolarRangeFromInputBraceSin3Theta() {
        let now = Date()
        let document = EMathicaDocument(
            metadata: .init(
                title: "Plane",
                moduleID: "plane",
                createdAt: now,
                updatedAt: now,
                calculatorType: "plane"
            ),
            moduleID: "plane",
            objects: []
        )

        let content = MathNode.sequence([
            .character("r"), .operatorSymbol("="), .character("s"), .character("i"), .character("n"),
            .template(TemplateNode(kind: .parentheses, fields: [
                .init(id: .content, node: .sequence([.character("3"), .character("θ")]))
            ])),
            .character(","),
            .character("0"), .operatorSymbol("<="), .character("θ"), .operatorSymbol("<="), .character("2"), .character("π")
        ])
        let braces = TemplateNode(kind: .braces, fields: [.init(id: .content, node: content)])
        var input = FormulaInputState(editorState: EditorState(root: .sequence([.template(braces)])))
        input.syncDerivedStrings()

        if case .polar(_, let angle, let range)? = input.semanticState.graphClassification?.intent {
            #expect(angle.name == "θ")
            #expect(range == .init(lower: .integer(0), upper: .multiply([.integer(2), .constant(.pi)])))
        } else {
            Issue.record("Expected polar intent")
            return
        }

        let draft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: input,
            document: document,
            previous: nil
        )
        #expect(draft?.previewSamples.isEmpty == false)
    }

    @Test func draftPreviewUsesSemanticPolarRangeFromStrictInequalityTextPi() {
        let now = Date()
        let document = EMathicaDocument(
            metadata: .init(
                title: "Plane",
                moduleID: "plane",
                createdAt: now,
                updatedAt: now,
                calculatorType: "plane"
            ),
            moduleID: "plane",
            objects: []
        )

        let content = MathNode.sequence([
            .character("r"), .operatorSymbol("="), .character("s"), .character("i"), .character("n"),
            .template(TemplateNode(kind: .parentheses, fields: [
                .init(id: .content, node: .sequence([.character("θ")]))
            ])),
            .character(","),
            .character("0"), .operatorSymbol("<"), .character("θ"), .operatorSymbol("<"), .character("2"), .character("p"), .character("i")
        ])
        let braces = TemplateNode(kind: .braces, fields: [.init(id: .content, node: content)])
        var input = FormulaInputState(editorState: EditorState(root: .sequence([.template(braces)])))
        input.syncDerivedStrings()

        if case .polar(_, let angle, let range)? = input.semanticState.graphClassification?.intent {
            #expect(angle.name == "θ")
            #expect(range == .init(lower: .integer(0), upper: .multiply([.integer(2), .constant(.pi)])))
        } else {
            Issue.record("Expected polar intent")
            return
        }

        let draft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: input,
            document: document,
            previous: nil
        )
        #expect(draft?.previewSamples.isEmpty == false)
    }

    @Test func draftPreviewUsesSemanticCircleFromInputFunctionCall() {
        let now = Date()
        let document = EMathicaDocument(
            metadata: .init(
                title: "Plane",
                moduleID: "plane",
                createdAt: now,
                updatedAt: now,
                calculatorType: "plane"
            ),
            moduleID: "plane",
            objects: []
        )

        let centerTuple = TemplateNode(kind: .parentheses, fields: [
            .init(id: .content, node: .sequence([.character("0"), .character(","), .character("0")]))
        ])
        let callArgs = TemplateNode(kind: .parentheses, fields: [
            .init(id: .content, node: .sequence([
                .template(centerTuple),
                .character(","),
                .character("1")
            ]))
        ])
        var input = FormulaInputState(editorState: EditorState(root: .sequence([
            .character("c"), .character("i"), .character("r"), .character("c"), .character("l"), .character("e"),
            .template(callArgs)
        ])))
        input.syncDerivedStrings()

        #expect(input.semanticState.graphClassification?.intent == .circle(
            center: .tuple([.integer(0), .integer(0)]),
            radius: .integer(1)
        ))

        let draft = PlaneDraftPreviewService.makeDraft(
            formulaInputState: input,
            document: document,
            previous: nil
        )
        #expect(draft?.previewSamples.isEmpty == false)
    }
}
