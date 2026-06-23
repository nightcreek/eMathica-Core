import EMathicaMathCore
typealias PlotSegment = EMathicaMathCore.PlotSegment
import Foundation
import CoreGraphics

//struct PlotSegment: Hashable {
enum ParametricCurveSampler {
    static func sample(
        _ curve: ParametricCurveDefinition,
        viewport: CanvasState,
        canvasSize: CGSize,
        parameterValues: [String: Double] = [:]
    ) -> [PlotSegment] {
        if curve.kind == .hyperbolaHorizontal || curve.kind == .hyperbolaVertical {
            return sampleTwoBranchCurve(curve, viewport: viewport, canvasSize: canvasSize, parameterValues: parameterValues)
        }

        let range = samplingRange(for: curve, viewport: viewport, canvasSize: canvasSize)
        let samples = max(240, Int(max(canvasSize.width, canvasSize.height)))
        var segments: [PlotSegment] = []
        var current: [WorldPoint] = []

        for index in 0...samples {
            let progress = Double(index) / Double(samples)
            let t = range.lowerBound + (range.upperBound - range.lowerBound) * progress

            guard let point = evaluate(curve, t: t, branch: 1, parameterValues: parameterValues), point.x.isFinite, point.y.isFinite else {
                if !current.isEmpty {
                    segments.append(PlotSegment(points: current))
                    current = []
                }
                continue
            }

            current.append(point)
        }

        if !current.isEmpty {
            segments.append(PlotSegment(points: current))
        }
        return segments
    }

    private static func sampleTwoBranchCurve(
        _ curve: ParametricCurveDefinition,
        viewport: CanvasState,
        canvasSize: CGSize,
        parameterValues: [String: Double]
    ) -> [PlotSegment] {
        let range = samplingRange(for: curve, viewport: viewport, canvasSize: canvasSize)
        let samples = max(240, Int(max(canvasSize.width, canvasSize.height)))
        var segments: [PlotSegment] = []

        for branch in [-1.0, 1.0] {
                        var points: [WorldPoint] = []
            for index in 0...samples {
                let progress = Double(index) / Double(samples)
                let t = range.lowerBound + (range.upperBound - range.lowerBound) * progress
                guard let point = evaluate(curve, t: t, branch: branch, parameterValues: parameterValues), point.x.isFinite, point.y.isFinite else {
                    if !points.isEmpty {
                        segments.append(PlotSegment(points: points))
                        points = []
                    }
                    continue
                }
                points.append(point)
            }
            if !points.isEmpty {
                segments.append(PlotSegment(points: points))
            }
        }

        return segments
    }

    private static func evaluate(
        _ curve: ParametricCurveDefinition,
        t: Double,
        branch: Double,
        parameterValues: [String: Double]
    ) -> WorldPoint? {
        switch curve.kind {
        case .circle, .ellipse:
            guard
                let radiusX = resolve(curve.radiusX, symbol: curve.radiusXSymbol, parameterValues: parameterValues),
                let radiusY = resolve(curve.radiusY, symbol: curve.radiusYSymbol, parameterValues: parameterValues),
                radiusX != 0,
                radiusY != 0
            else {
                return nil
            }
            return WorldPoint(
                x: curve.centerX + radiusX * cos(t),
                y: curve.centerY + radiusY * sin(t)
            )
        case .hyperbolaHorizontal:
            guard curve.radiusX > 0, curve.radiusY > 0 else { return nil }
            return WorldPoint(
                x: curve.centerX + branch * curve.radiusX * cosh(t),
                y: curve.centerY + curve.radiusY * sinh(t)
            )
        case .hyperbolaVertical:
            guard curve.radiusX > 0, curve.radiusY > 0 else { return nil }
            return WorldPoint(
                x: curve.centerX + curve.radiusX * sinh(t),
                y: curve.centerY + branch * curve.radiusY * cosh(t)
            )
        case .parabolaHorizontal:
            guard let p = curve.focalParameter, abs(p) > 0.000001 else { return nil }
            return WorldPoint(
                x: curve.centerX + p * t * t,
                y: curve.centerY + 2 * p * t
            )
        case .parabolaVertical:
            guard let p = curve.focalParameter, abs(p) > 0.000001 else { return nil }
            return WorldPoint(
                x: curve.centerX + 2 * p * t,
                y: curve.centerY + p * t * t
            )
        case .superellipse:
            guard
                let radiusX = resolve(curve.radiusX, symbol: curve.radiusXSymbol, parameterValues: parameterValues),
                let radiusY = resolve(curve.radiusY, symbol: curve.radiusYSymbol, parameterValues: parameterValues),
                let n = resolve(curve.exponent, symbol: curve.exponentSymbol, parameterValues: parameterValues),
                radiusX != 0,
                radiusY != 0,
                n > 0
            else {
                return nil
            }

            let cosine = cos(t)
            let sine = sin(t)
            let x = curve.centerX + radiusX * signedPower(cosine, exponent: 2 / n)
            let y = curve.centerY + radiusY * signedPower(sine, exponent: 2 / n)
            return WorldPoint(x: x, y: y)
        }
    }

    private static func samplingRange(
        for curve: ParametricCurveDefinition,
        viewport: CanvasState,
        canvasSize: CGSize
    ) -> ClosedRange<Double> {
        switch curve.kind {
        case .hyperbolaHorizontal, .hyperbolaVertical:
            let bounds = worldBounds(viewport: viewport, canvasSize: canvasSize)
            let xExtent = max(abs(bounds.minX - curve.centerX), abs(bounds.maxX - curve.centerX))
            let yExtent = max(abs(bounds.minY - curve.centerY), abs(bounds.maxY - curve.centerY))
            let xT = acosh(max(1, xExtent / max(curve.radiusX, 0.000001)))
            let yT = asinh(yExtent / max(curve.radiusY, 0.000001))
            let tMax = min(max(max(xT, yT) + 0.35, 2.5), 8)
            return -tMax...tMax
        case .parabolaHorizontal, .parabolaVertical:
            guard let p = curve.focalParameter, abs(p) > 0.000001 else {
                return curve.tMin...curve.tMax
            }
            let bounds = worldBounds(viewport: viewport, canvasSize: canvasSize)
            let xExtent = max(abs(bounds.minX - curve.centerX), abs(bounds.maxX - curve.centerX))
            let yExtent = max(abs(bounds.minY - curve.centerY), abs(bounds.maxY - curve.centerY))
            let linearExtent = curve.kind == .parabolaHorizontal ? yExtent : xExtent
            let quadraticExtent = curve.kind == .parabolaHorizontal ? xExtent : yExtent
            let linearT = linearExtent / max(2 * abs(p), 0.000001)
            let quadraticT = sqrt(quadraticExtent / max(abs(p), 0.000001))
            let tMax = min(max(max(linearT, quadraticT) + 1, 4), 80)
            return -tMax...tMax
        case .circle, .ellipse, .superellipse:
            return curve.tMin...curve.tMax
        }
    }

    private static func worldBounds(
        viewport: CanvasState,
        canvasSize: CGSize
    ) -> (minX: Double, maxX: Double, minY: Double, maxY: Double) {
        let rect = viewport.visibleWorldRect(in: canvasSize)
        return (rect.minX, rect.maxX, rect.minY, rect.maxY)
    }

    private static func resolve(
        _ fallback: Double,
        symbol: String?,
        parameterValues: [String: Double]
    ) -> Double? {
        guard let symbol else { return fallback }
        return parameterValues[symbol]
    }

    private static func signedPower(_ value: Double, exponent: Double) -> Double {
        let magnitude = pow(abs(value), exponent)
        if value < 0 {
            return -magnitude
        }
        return magnitude
    }
}
