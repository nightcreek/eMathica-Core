#if DEBUG
import Foundation
import EMathicaMathCore

struct PlaneSemanticSamplingDebugResult {
    var intentSummary: String
    var segmentCount: Int
    var pointCount: Int
    var issueCount: Int
    var issueSummary: String
}

enum PlaneSemanticSamplingDebugFormatter {
    static func makeResult(
        intentSummary: String,
        sampleSet: SampleSet2D
    ) -> PlaneSemanticSamplingDebugResult {
        let segmentCount = sampleSet.segments.count
        let pointCount = sampleSet.segments.reduce(0) { $0 + $1.points.count }
        let issueCount = sampleSet.issues.count
        let issueSummary: String
        if sampleSet.issues.isEmpty {
            issueSummary = "none"
        } else {
            issueSummary = sampleSet.issues.map { issue in
                "\(issue.kind.rawValue): \(issue.message)"
            }.joined(separator: " | ")
        }

        return PlaneSemanticSamplingDebugResult(
            intentSummary: intentSummary,
            segmentCount: segmentCount,
            pointCount: pointCount,
            issueCount: issueCount,
            issueSummary: issueSummary
        )
    }
}
#endif
