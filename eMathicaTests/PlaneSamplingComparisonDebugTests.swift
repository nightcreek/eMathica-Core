import Testing
@testable import EMathicaMathCore
import EMathicaDocumentKit
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

#if DEBUG
struct PlaneSamplingComparisonDebugTests {
    @Test func comparisonFormatterCountsSegmentsAndPoints() {
        let legacy = [
            PlotSegment(points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 1, y: 1)])
        ]
        let semantic = SampleSet2D(
            segments: [
                .init(points: [.init(x: 0, y: 0)]),
                .init(points: [.init(x: 2, y: 3), .init(x: 4, y: 5)])
            ],
            issues: [.init(kind: .unsupportedIntent, message: "unsupported")]
        )
        let adapted = PlaneSampleSetAdapter.adaptToPlotSegments(semantic)

        let result = PlaneSamplingComparisonDebugFormatter.makeResult(
            inputSummary: "x^2",
            intentSummary: "explicitY",
            legacySegments: legacy,
            semanticSampleSet: semantic,
            adaptedSemanticSegments: adapted,
            fallbackReason: nil
        )

        #expect(result.legacySegmentCount == 1)
        #expect(result.legacyPointCount == 2)
        #expect(result.semanticSegmentCount == 2)
        #expect(result.semanticPointCount == 3)
        #expect(result.semanticIssueCount == 1)
    }

    @Test func comparisonFormatterIncludesFallbackReason() {
        let result = PlaneSamplingComparisonDebugFormatter.makeResult(
            inputSummary: "x^2+y^2=1",
            intentSummary: "implicit(...)",
            legacySegments: [],
            semanticSampleSet: nil,
            adaptedSemanticSegments: nil,
            fallbackReason: .unsupportedGraphIntent
        )
        #expect(result.fallbackReason == PlaneSemanticFallbackReason.unsupportedGraphIntent.rawValue)
    }
}
#endif
