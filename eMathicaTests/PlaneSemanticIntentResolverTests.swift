import Foundation
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica
import EMathicaMathCore

struct PlaneSemanticIntentResolverTests {
    @Test func resolverInjectsPersistedParametricRangeWhenAstHasNoRange() throws {
        let t = Symbol(name: "t", role: .parameter)
        let expression = MathExpression(
            displayText: "{x=t^2,y=t,0<t<2}",
            semanticGraphKind: .parametric2D,
            semanticParameterSymbol: t,
            semanticParameterRange: .init(lower: .integer(0), upper: .integer(2)),
            editorASTData: editorASTData(for: parametricTemplateState())
        )

        guard let intent = PlaneSemanticIntentResolver.resolveIntent(for: expression) else {
            Issue.record("Expected resolved semantic intent")
            return
        }
        guard case .parametric2D(_, _, let parameter, let range) = intent else {
            Issue.record("Expected parametric2D intent, got \(intent)")
            return
        }
        #expect(parameter == t)
        #expect(range == .init(lower: .integer(0), upper: .integer(2)))
    }

    @Test func resolvedParametricIntentRangeConstrainsSampleBounds() throws {
        let t = Symbol(name: "t", role: .parameter)
        let expression = MathExpression(
            displayText: "{x=t^2,y=t,0<t<2}",
            semanticGraphKind: .parametric2D,
            semanticParameterSymbol: t,
            semanticParameterRange: .init(lower: .integer(0), upper: .integer(2)),
            editorASTData: editorASTData(for: parametricTemplateState())
        )
        guard let intent = PlaneSemanticIntentResolver.resolveIntent(for: expression) else {
            Issue.record("Expected resolved semantic intent")
            return
        }

        let options = CurveSamplingOptions2D(
            qualityProfile: .preview,
            algorithm: .uniform,
            initialSampleCount: 9,
            maxSampleCount: 9,
            maxRefinementDepth: 0,
            discontinuityThreshold: 1000,
            maxAbsCoordinate: 1.0e12,
            refinementErrorThreshold: .infinity,
            screenErrorTolerance: nil
        )
        let sampleSet = GraphIntentSampler2D(
            parametricCurveSampler: .init(options: options)
        ).sample(
            intent: intent,
            xRange: .init(lower: -10, upper: 10)
        )

        let points = sampleSet.segments.flatMap(\.points)
        #expect(!points.isEmpty)
        let maxX = points.map(\.x).max() ?? -.infinity
        let maxY = points.map(\.y).max() ?? -.infinity
        #expect(maxX <= 4 + 1e-9)
        #expect(maxY <= 2 + 1e-9)
    }

    private func editorASTData(for state: EditorState) -> String {
        let data = try! JSONEncoder().encode(state)
        return String(decoding: data, as: UTF8.self)
    }

    private func parametricTemplateState() -> EditorState {
        let template = TemplateNode(
            kind: .parametricEquation2D,
            fields: [
                .init(id: .parametricExpression(0), node: .sequence([.character("t"), .operatorSymbol("^"), .character("2")])),
                .init(id: .parametricExpression(1), node: .sequence([.character("t")]))
            ]
        )
        return EditorState(root: .sequence([.template(template)]))
    }
}
