import EMathicaMathCore
import SwiftUI

struct PlaneAxisRendererView: View {
    @Environment(\.colorScheme) private var colorScheme

    let canvasState: CanvasState

    var body: some View {
        Canvas { context, size in
            let origin = CGPoint(x: size.width * 0.5 + canvasState.origin.x, y: size.height * 0.5 + canvasState.origin.y)

            var path = Path()
            path.move(to: CGPoint(x: 0, y: origin.y))
            path.addLine(to: CGPoint(x: size.width, y: origin.y))
            path.move(to: CGPoint(x: origin.x, y: 0))
            path.addLine(to: CGPoint(x: origin.x, y: size.height))

            let axisColor = colorScheme == .dark ? Color.white.opacity(0.55) : Color.black.opacity(0.45)
            context.stroke(path, with: .color(axisColor), lineWidth: 1.5)

            let originDot = CGRect(x: origin.x - 2.5, y: origin.y - 2.5, width: 5, height: 5)
            context.fill(Path(ellipseIn: originDot), with: .color(axisColor.opacity(0.9)))
        }
    }
}
