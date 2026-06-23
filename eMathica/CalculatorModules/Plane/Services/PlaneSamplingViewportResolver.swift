import CoreGraphics
import EMathicaMathCore

enum PlaneSamplingViewportResolver {
    static func makeViewport(
        xRange: SamplingRange,
        yRange: SamplingRange,
        canvasPixelSize: CGSize?
    ) -> SamplingViewport2D {
        let fallbackWidth = 1024.0
        let fallbackHeight = 640.0

        let width = canvasPixelSize.map { Double($0.width) } ?? fallbackWidth
        let height = canvasPixelSize.map { Double($0.height) } ?? fallbackHeight
        let resolvedWidth = width.isFinite && width > 0 ? Double(width) : fallbackWidth
        let resolvedHeight = height.isFinite && height > 0 ? Double(height) : fallbackHeight

        return SamplingViewport2D(
            xRange: xRange,
            yRange: yRange,
            pixelWidth: resolvedWidth,
            pixelHeight: resolvedHeight
        )
    }
}
