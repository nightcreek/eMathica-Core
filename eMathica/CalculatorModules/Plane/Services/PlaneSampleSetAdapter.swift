import Foundation
import EMathicaMathCore

enum PlaneSampleSetAdapter {
    static func adaptToPlotSegments(_ sampleSet: SampleSet2D) -> [PlotSegment]? {
        let segments = sampleSet.segments.compactMap { segment -> PlotSegment? in
            guard !segment.points.isEmpty else { return nil }
            let points = segment.points.map { point in
                WorldPoint(x: point.x, y: point.y)
            }
            return PlotSegment(points: points)
        }
        return segments.isEmpty ? nil : segments
    }
}
