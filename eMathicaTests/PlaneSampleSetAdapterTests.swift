import Testing
@testable import EMathicaMathCore
import EMathicaDocumentKit
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct PlaneSampleSetAdapterTests {
    @Test func adaptPreservesMultipleSegments() {
        let set = SampleSet2D(
            segments: [
                SampleSegment2D(points: [.init(x: 0, y: 0), .init(x: 1, y: 1)]),
                SampleSegment2D(points: [.init(x: 2, y: 3), .init(x: 4, y: 5)])
            ],
            issues: []
        )

        let adapted = PlaneSampleSetAdapter.adaptToPlotSegments(set)
        #expect(adapted != nil)
        #expect(adapted?.count == 2)
        #expect(adapted?[0].points.count == 2)
        #expect(adapted?[1].points.count == 2)
        #expect(adapted?[1].points[0].x == 2)
        #expect(adapted?[1].points[0].y == 3)
    }

    @Test func adaptReturnsNilForEmptySegments() {
        let set = SampleSet2D(segments: [], issues: [])
        #expect(PlaneSampleSetAdapter.adaptToPlotSegments(set) == nil)
    }

    @Test func adaptPreservesSinglePointSegment() {
        let set = SampleSet2D(
            segments: [
                .init(points: [.init(x: 1, y: 2)])
            ],
            issues: []
        )
        let adapted = PlaneSampleSetAdapter.adaptToPlotSegments(set)
        #expect(adapted?.count == 1)
        #expect(adapted?.first?.points.count == 1)
        #expect(adapted?.first?.points.first?.x == 1)
        #expect(adapted?.first?.points.first?.y == 2)
    }

    @Test func adaptSupportsPiecewiseSampleSetSegments() {
        let x = Symbol(name: "x", role: .variable)
        let branches: [GraphIntentBranch] = [
            .init(
                condition: .relation(left: .symbol(x), relation: .less, right: .integer(0)),
                intent: .explicitY(
                    expression: .power(base: .symbol(x), exponent: .integer(2)),
                    variable: x
                )
            ),
            .init(
                condition: .relation(left: .symbol(x), relation: .greaterOrEqual, right: .integer(0)),
                intent: .explicitY(expression: .symbol(x), variable: x)
            )
        ]
        let set = PiecewiseSampler2D().sampleY(
            branches: branches,
            variable: x,
            range: .init(lower: -1, upper: 1)
        )
        let adapted = PlaneSampleSetAdapter.adaptToPlotSegments(set)
        #expect(adapted != nil)
        #expect((adapted?.isEmpty ?? true) == false)
    }

    @Test func adaptSupportsImplicitStitchedCircleSegments() {
        let relation = Expr.equation(
            left: .add([
                .power(base: .symbol(Symbol(name: "x", role: .variable)), exponent: .integer(2)),
                .power(base: .symbol(Symbol(name: "y", role: .variable)), exponent: .integer(2))
            ]),
            right: .integer(1)
        )
        let sampleSet = ImplicitCurveSampler2D(
            options: .init(
                qualityProfile: .balanced,
                xResolution: 96,
                yResolution: 96,
                enableSegmentStitching: true,
                stitchingTolerance: 1e-6
            )
        ).sample(
            relation: relation,
            xRange: .init(lower: -2, upper: 2),
            yRange: .init(lower: -2, upper: 2)
        )
        #expect(!sampleSet.segments.isEmpty)
        let adapted = PlaneSampleSetAdapter.adaptToPlotSegments(sampleSet)
        #expect(adapted != nil)
        #expect((adapted?.isEmpty ?? true) == false)
    }
}
