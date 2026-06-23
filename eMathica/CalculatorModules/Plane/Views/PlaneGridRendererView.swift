import EMathicaMathCore
import SwiftUI

struct PlaneGridRendererView: View {
    @Environment(\.colorScheme) private var colorScheme

    let canvasState: CanvasState

    var body: some View {
        Canvas { context, size in
            guard canvasState.showGrid else { return }

            let scale = CGFloat(canvasState.scale)
            let grid = gridSpacing(scale: scale)
            let origin = originInView(size: size)

            var minor = Path()
            var major = Path()

            let minX = -origin.x
            let maxX = size.width - origin.x
            let minY = -origin.y
            let maxY = size.height - origin.y

            drawVerticalLines(minX: minX, maxX: maxX, minY: minY, maxY: maxY, spacing: grid.minor, path: &minor)
            drawHorizontalLines(minX: minX, maxX: maxX, minY: minY, maxY: maxY, spacing: grid.minor, path: &minor)

            drawVerticalLines(minX: minX, maxX: maxX, minY: minY, maxY: maxY, spacing: grid.major, path: &major)
            drawHorizontalLines(minX: minX, maxX: maxX, minY: minY, maxY: maxY, spacing: grid.major, path: &major)

            let minorColor = colorScheme == .dark ? Color(red: 0.45, green: 0.55, blue: 0.85).opacity(0.10) : Color(red: 0.22, green: 0.34, blue: 0.62).opacity(0.10)
            let majorColor = colorScheme == .dark ? Color(red: 0.62, green: 0.72, blue: 1.0).opacity(0.16) : Color(red: 0.10, green: 0.22, blue: 0.48).opacity(0.14)

            context.translateBy(x: origin.x, y: origin.y)
            context.stroke(minor, with: .color(minorColor), lineWidth: 1)
            context.stroke(major, with: .color(majorColor), lineWidth: 1)
        }
    }

    private func originInView(size: CGSize) -> CGPoint {
        CGPoint(x: size.width * 0.5 + canvasState.origin.x, y: size.height * 0.5 + canvasState.origin.y)
    }

    private func gridSpacing(scale: CGFloat) -> (minor: CGFloat, major: CGFloat) {
        let targetMajorPixels: CGFloat = 90
        let worldUnitsAtTarget = Double(targetMajorPixels / max(scale, 1e-12))
        let majorWorld = niceGridStep(targetUnits: max(worldUnitsAtTarget, 1e-12))
        let minorWorld = majorWorld / 5
        let majorPixels = CGFloat(majorWorld) * scale
        let minorPixels = CGFloat(minorWorld) * scale
        return (minor: max(minorPixels, 4), major: max(majorPixels, 20))
    }

    private func niceGridStep(targetUnits: Double) -> Double {
        let safe = max(targetUnits, 1e-15)
        let exponent = floor(log10(safe))
        let base = pow(10.0, exponent)
        let normalized = safe / base
        let stepNorm: Double
        if normalized <= 1 {
            stepNorm = 1
        } else if normalized <= 2 {
            stepNorm = 2
        } else if normalized <= 5 {
            stepNorm = 5
        } else {
            stepNorm = 10
        }
        return stepNorm * base
    }

    private func drawVerticalLines(minX: CGFloat, maxX: CGFloat, minY: CGFloat, maxY: CGFloat, spacing: CGFloat, path: inout Path) {
        guard spacing > 0 else { return }
        var x = floor(minX / spacing) * spacing
        while x <= maxX {
            path.move(to: CGPoint(x: x, y: minY))
            path.addLine(to: CGPoint(x: x, y: maxY))
            x += spacing
        }
    }

    private func drawHorizontalLines(minX: CGFloat, maxX: CGFloat, minY: CGFloat, maxY: CGFloat, spacing: CGFloat, path: inout Path) {
        guard spacing > 0 else { return }
        var y = floor(minY / spacing) * spacing
        while y <= maxY {
            path.move(to: CGPoint(x: minX, y: y))
            path.addLine(to: CGPoint(x: maxX, y: y))
            y += spacing
        }
    }
}
