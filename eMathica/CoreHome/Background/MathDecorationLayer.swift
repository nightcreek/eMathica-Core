import EMathicaThemeKit
import SwiftUI

struct MathDecorationLayer: View {
    @Environment(\.colorScheme) private var colorScheme

    let layout: HomeBackgroundLayout
    let theme: HomeBackgroundTheme

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let leftRect = denormalize(layout.leftMathRect, in: size)
            let rightRect = denormalize(layout.rightMathRect, in: size)
            let dotRect = denormalize(layout.dotMatrixRect, in: size)

            Canvas { context, _ in
                if layout.shouldDrawLeftGraph {
                    drawLeftMathGraph(in: leftRect, context: &context)
                }
                if layout.shouldDrawRightGeometry {
                    drawRightGeometry(in: rightRect, context: &context)
                }
                if layout.shouldDrawDotMatrix {
                    drawDotMatrix(in: dotRect, context: &context)
                }
            }
            .allowsHitTesting(false)
        }
    }

    private func drawLeftMathGraph(in rect: CGRect, context: inout GraphicsContext) {
        let modeScale: CGFloat = colorScheme == .dark ? 0.74 : 0.78
        let phoneScale: CGFloat = layout.profile == .phonePortrait ? 0.86 : 1.0
        let scale = layout.mathOpacityScale * modeScale * phoneScale
        let axisColor = colorScheme == .dark
            ? Color.white.opacity(0.17 * scale)
            : Color(red: 0.26, green: 0.37, blue: 0.56).opacity(0.20 * scale)
        let sinColor = colorScheme == .dark
            ? Color(red: 0.68, green: 0.52, blue: 0.98).opacity(0.30 * scale)
            : Color(red: 0.62, green: 0.48, blue: 0.92).opacity(0.30 * scale)
        let cosColor = colorScheme == .dark
            ? Color(red: 0.38, green: 0.66, blue: 1.00).opacity(0.30 * scale)
            : Color(red: 0.34, green: 0.62, blue: 1.00).opacity(0.30 * scale)
        let labelColor = colorScheme == .dark
            ? Color.white.opacity(0.20 * scale)
            : Color(red: 0.24, green: 0.34, blue: 0.52).opacity(0.24 * scale)

        let center = CGPoint(x: rect.midX, y: rect.midY)
        var axis = Path()
        axis.move(to: CGPoint(x: rect.minX, y: center.y))
        axis.addLine(to: CGPoint(x: rect.maxX, y: center.y))
        axis.move(to: CGPoint(x: center.x, y: rect.minY))
        axis.addLine(to: CGPoint(x: center.x, y: rect.maxY))
        context.stroke(axis, with: .color(axisColor), style: StrokeStyle(lineWidth: colorScheme == .dark ? 0.9 : 1.0))

        let sinPath = graphPath(in: rect, function: { sin($0) })
        let cosPath = graphPath(in: rect, function: { cos($0) })
        context.stroke(sinPath, with: .color(sinColor), style: StrokeStyle(lineWidth: colorScheme == .dark ? 1.5 : 1.7, lineCap: .round))
        context.stroke(cosPath, with: .color(cosColor), style: StrokeStyle(lineWidth: colorScheme == .dark ? 1.5 : 1.7, lineCap: .round))

        context.draw(
            Text("y = sin x")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(labelColor),
            at: CGPoint(x: rect.minX + rect.width * 0.26, y: rect.minY + rect.height * 0.18)
        )
        context.draw(
            Text("y = cos x")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(labelColor),
            at: CGPoint(x: rect.minX + rect.width * 0.26, y: rect.minY + rect.height * 0.30)
        )
    }

    private func drawRightGeometry(in rect: CGRect, context: inout GraphicsContext) {
        let modeScale: CGFloat = colorScheme == .dark ? 0.85 : 1.15
        let scale = layout.mathOpacityScale * modeScale
        let lineColor = colorScheme == .dark
            ? Color.white.opacity(0.22 * scale)
            : Color(red: 0.24, green: 0.36, blue: 0.58).opacity(0.34 * scale)
        let dashedColor = colorScheme == .dark
            ? Color.white.opacity(0.16 * scale)
            : Color(red: 0.30, green: 0.43, blue: 0.62).opacity(0.26 * scale)
        let labelColor = colorScheme == .dark
            ? Color.white.opacity(0.26 * scale)
            : Color(red: 0.26, green: 0.37, blue: 0.56).opacity(0.48 * scale)

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) * 0.34
        let a = CGPoint(x: center.x, y: center.y - r)
        let b = CGPoint(x: center.x - r * 0.82, y: center.y + r * 0.48)
        let c = CGPoint(x: center.x + r * 0.82, y: center.y + r * 0.48)

        context.stroke(
            Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
            with: .color(lineColor),
            style: StrokeStyle(lineWidth: 1.1)
        )

        var triangle = Path()
        triangle.move(to: a)
        triangle.addLine(to: b)
        triangle.addLine(to: c)
        triangle.addLine(to: a)
        context.stroke(triangle, with: .color(lineColor), style: StrokeStyle(lineWidth: 1.1))

        var spokes = Path()
        spokes.move(to: center); spokes.addLine(to: a)
        spokes.move(to: center); spokes.addLine(to: b)
        spokes.move(to: center); spokes.addLine(to: c)
        context.stroke(spokes, with: .color(dashedColor), style: StrokeStyle(lineWidth: 0.95, dash: [3, 3]))

        for (label, point) in [("A", a), ("B", b), ("C", c), ("O", center)] {
            context.fill(Path(ellipseIn: CGRect(x: point.x - 2, y: point.y - 2, width: 4, height: 4)), with: .color(lineColor))
            context.draw(
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(labelColor),
                at: CGPoint(x: point.x + 10, y: point.y - 8)
            )
        }
    }

    private func drawDotMatrix(in rect: CGRect, context: inout GraphicsContext) {
        let modeScale: CGFloat = colorScheme == .dark ? 0.74 : 0.78
        let scale = layout.mathOpacityScale * modeScale
        let dotColor = colorScheme == .dark
            ? Color.white.opacity(0.14 * scale)
            : Color(red: 0.34, green: 0.52, blue: 0.82).opacity(0.14 * scale)
        let cols = 5
        let rows = 6
        let dx = rect.width / CGFloat(cols)
        let dy = rect.height / CGFloat(rows)
        for row in 0..<rows {
            for col in 0..<cols {
                let x = rect.minX + CGFloat(col) * dx + dx * 0.5
                let y = rect.minY + CGFloat(row) * dy + dy * 0.5
                context.fill(
                    Path(ellipseIn: CGRect(x: x - 1.3, y: y - 1.3, width: 2.6, height: 2.6)),
                    with: .color(dotColor)
                )
            }
        }
    }

    private func graphPath(in rect: CGRect, function: (Double) -> Double) -> Path {
        var path = Path()
        let samples = 80
        let xMin = -Double.pi * 1.2
        let xMax = Double.pi * 1.2

        for i in 0...samples {
            let t = Double(i) / Double(samples)
            let x = xMin + (xMax - xMin) * t
            let y = function(x)

            let nx = CGFloat((x - xMin) / (xMax - xMin))
            let ny = CGFloat((y + 1.3) / 2.6)
            let px = rect.minX + nx * rect.width
            let py = rect.maxY - ny * rect.height

            if i == 0 {
                path.move(to: CGPoint(x: px, y: py))
            } else {
                path.addLine(to: CGPoint(x: px, y: py))
            }
        }
        return path
    }

    private func denormalize(_ rect: CGRect, in size: CGSize) -> CGRect {
        CGRect(
            x: rect.origin.x * size.width,
            y: rect.origin.y * size.height,
            width: rect.size.width * size.width,
            height: rect.size.height * size.height
        )
    }
}
