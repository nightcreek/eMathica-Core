import EMathicaMathCore
import Foundation

enum PlaneLegacyExplicitSampling {
    static func sampleExplicitY(
        _ expression: AlgebraExpression,
        visibleWorldRect: WorldRect,
        samples: Int,
        parameterValues: [String: Double]
    ) -> [PlotSegment] {
        sample(
            expression: expression,
            range: visibleWorldRect.minX...visibleWorldRect.maxX,
            visibleWorldRect: visibleWorldRect,
            samples: samples,
            parameterValues: parameterValues,
            injectedVariable: "x",
            pointBuilder: { sampled, evaluated in
                WorldPoint(x: sampled, y: evaluated)
            },
            jumpMetric: { previous, current in
                abs(current.y - previous.y)
            },
            expandedBoundsContains: { point, rect in
                point.y >= rect.minY && point.y <= rect.maxY
            }
        )
    }

    static func sampleExplicitX(
        _ expression: AlgebraExpression,
        visibleWorldRect: WorldRect,
        samples: Int,
        parameterValues: [String: Double]
    ) -> [PlotSegment] {
        sample(
            expression: expression,
            range: visibleWorldRect.minY...visibleWorldRect.maxY,
            visibleWorldRect: visibleWorldRect,
            samples: samples,
            parameterValues: parameterValues,
            injectedVariable: "y",
            pointBuilder: { sampled, evaluated in
                WorldPoint(x: evaluated, y: sampled)
            },
            jumpMetric: { previous, current in
                abs(current.x - previous.x)
            },
            expandedBoundsContains: { point, rect in
                point.x >= rect.minX && point.x <= rect.maxX
            }
        )
    }

    private static func sample(
        expression: AlgebraExpression,
        range: ClosedRange<Double>,
        visibleWorldRect: WorldRect,
        samples: Int,
        parameterValues: [String: Double],
        injectedVariable: String,
        pointBuilder: (Double, Double) -> WorldPoint,
        jumpMetric: (WorldPoint, WorldPoint) -> Double,
        expandedBoundsContains: (WorldPoint, WorldRect) -> Bool
    ) -> [PlotSegment] {
        guard samples > 0, range.lowerBound.isFinite, range.upperBound.isFinite else { return [] }

        let expandedRect = expandedBounds(for: visibleWorldRect)
        let jumpThreshold = discontinuityThreshold(for: visibleWorldRect)

        var segments: [PlotSegment] = []
        var current: [WorldPoint] = []
        var previousPoint: WorldPoint?

        for index in 0...samples {
            let sampled = range.lowerBound + (range.upperBound - range.lowerBound) * (Double(index) / Double(samples))
            var variables = parameterValues
            variables[injectedVariable] = sampled

            guard let evaluated = AlgebraEvaluator.evaluate(expression, variables: variables),
                  evaluated.isFinite else {
                flush(&current, into: &segments)
                previousPoint = nil
                continue
            }

            let point = pointBuilder(sampled, evaluated)
            guard expandedBoundsContains(point, expandedRect) else {
                flush(&current, into: &segments)
                previousPoint = nil
                continue
            }

            if let previousPoint, jumpMetric(previousPoint, point) > jumpThreshold {
                flush(&current, into: &segments)
            }

            current.append(point)
            previousPoint = point
        }

        flush(&current, into: &segments)
        return segments
    }

    private static func expandedBounds(for rect: WorldRect) -> WorldRect {
        let expansionFactor = 4.0
        let safeWidth = max(rect.width, 1.0)
        let safeHeight = max(rect.height, 1.0)
        let centerX = (rect.minX + rect.maxX) * 0.5
        let centerY = (rect.minY + rect.maxY) * 0.5
        return WorldRect(
            minX: centerX - safeWidth * expansionFactor,
            minY: centerY - safeHeight * expansionFactor,
            maxX: centerX + safeWidth * expansionFactor,
            maxY: centerY + safeHeight * expansionFactor
        )
    }

    private static func discontinuityThreshold(for rect: WorldRect) -> Double {
        let dominantSpan = max(rect.width, rect.height, 1.0)
        return max(12.0, dominantSpan * 1.5)
    }

    private static func flush(_ current: inout [WorldPoint], into segments: inout [PlotSegment]) {
        guard current.isEmpty == false else { return }
        segments.append(PlotSegment(points: current))
        current.removeAll(keepingCapacity: true)
    }
}
