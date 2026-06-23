import CoreGraphics
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct ProjectPreviewTransformTests {
    @Test func transformUsesUniformScaleForRectangularImage() {
        let bounds = ProjectPreviewRenderer.PreviewWorldToPixelTransform(
            bounds: .init(minX: -10, maxX: 10, minY: -10, maxY: 10),
            size: CGSize(width: 620, height: 400)
        )
        #expect(abs(bounds.scale - 20.0) < 1e-9)
        #expect(abs(bounds.contentWidth - 400.0) < 1e-9)
        #expect(abs(bounds.contentHeight - 400.0) < 1e-9)
    }

    @Test func projectedCircleRadiiStayEqual() {
        let transform = ProjectPreviewRenderer.PreviewWorldToPixelTransform(
            bounds: .init(minX: -10, maxX: 10, minY: -10, maxY: 10),
            size: CGSize(width: 620, height: 400)
        )
        let center = transform.screenPoint(for: .init(x: 0, y: 0))
        let px = transform.screenPoint(for: .init(x: 2, y: 0))
        let py = transform.screenPoint(for: .init(x: 0, y: 2))
        let rx = abs(px.x - center.x)
        let ry = abs(py.y - center.y)
        #expect(abs(rx - ry) < 1e-9)
    }

    @Test func centeredWorldMapsToCenteredContentRect() {
        let transform = ProjectPreviewRenderer.PreviewWorldToPixelTransform(
            bounds: .init(minX: -10, maxX: 10, minY: -10, maxY: 10),
            size: CGSize(width: 620, height: 400)
        )
        let center = transform.screenPoint(for: .init(x: 0, y: 0))
        #expect(abs(center.x - (transform.xOffset + transform.contentWidth * 0.5)) < 1e-9)
        #expect(abs(center.y - (transform.yOffset + transform.contentHeight * 0.5)) < 1e-9)
    }

    @Test func thumbnailPointRadiusIsWorldScaleIndependent() {
        let radiusA = ProjectPreviewRenderer.thumbnailPointRadius(from: 6)
        let radiusB = ProjectPreviewRenderer.thumbnailPointRadius(from: 6)
        #expect(abs(radiusA - radiusB) < 1e-9)
        #expect(abs(radiusA - 3.0) < 1e-9)
    }

    @Test func thumbnailPointRadiusIsClamped() {
        let minRadius = ProjectPreviewRenderer.thumbnailPointRadius(from: 1)
        let maxRadius = ProjectPreviewRenderer.thumbnailPointRadius(from: 99)
        #expect(abs(minRadius - 2.5) < 1e-9)
        #expect(abs(maxRadius - 6.0) < 1e-9)
    }
}
