#if DEBUG
import Foundation
import EMathicaMathCore

struct PlaneSamplingComparisonDebugResult {
    var inputSummary: String
    var intentSummary: String
    var legacySegmentCount: Int
    var legacyPointCount: Int
    var semanticSegmentCount: Int
    var semanticPointCount: Int
    var semanticIssueCount: Int
    var semanticIssueSummary: String
    var fallbackReason: String?
}

enum PlaneSemanticFallbackReason: String {
    case noSemanticState = "no semantic state"
    case semanticBlockingError = "semantic blocking error"
    case missingGraphClassification = "missing graph classification"
    case unsupportedGraphIntent = "unsupported graph intent"
    case emptySemanticSampleSet = "empty semantic sample set"
    case adapterFailed = "adapter failed"
}

enum PlaneSamplingComparisonDebugFormatter {
    static func makeResult(
        inputSummary: String,
        intentSummary: String,
        legacySegments: [PlotSegment],
        semanticSampleSet: SampleSet2D?,
        adaptedSemanticSegments: [PlotSegment]?,
        fallbackReason: PlaneSemanticFallbackReason?
    ) -> PlaneSamplingComparisonDebugResult {
        let legacySegmentCount = legacySegments.count
        let legacyPointCount = legacySegments.reduce(0) { $0 + $1.points.count }

        let semanticSegmentCount = adaptedSemanticSegments?.count ?? 0
        let semanticPointCount = adaptedSemanticSegments?.reduce(0) { $0 + $1.points.count } ?? 0
        let semanticIssueCount = semanticSampleSet?.issues.count ?? 0
        let semanticIssueSummary: String
        if let semanticSampleSet, !semanticSampleSet.issues.isEmpty {
            semanticIssueSummary = semanticSampleSet.issues.map { issue in
                "\(issue.kind.rawValue): \(issue.message)"
            }.joined(separator: " | ")
        } else {
            semanticIssueSummary = "none"
        }

        return PlaneSamplingComparisonDebugResult(
            inputSummary: inputSummary,
            intentSummary: intentSummary,
            legacySegmentCount: legacySegmentCount,
            legacyPointCount: legacyPointCount,
            semanticSegmentCount: semanticSegmentCount,
            semanticPointCount: semanticPointCount,
            semanticIssueCount: semanticIssueCount,
            semanticIssueSummary: semanticIssueSummary,
            fallbackReason: fallbackReason?.rawValue
        )
    }
}
#endif
