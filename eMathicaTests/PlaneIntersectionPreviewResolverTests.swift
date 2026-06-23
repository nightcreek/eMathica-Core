import Foundation
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct PlaneIntersectionPreviewResolverTests {
    @Test func lineCirclePreviewReturnsTwoPoints() {
        let (line, circle) = makeLineAndCircle()
        let points = PlaneIntersectionPreviewResolver.previewPoints(
            firstObjectID: line.id,
            secondObjectID: circle.id,
            objects: [line, circle]
        )
        #expect(points.count == 2)
    }

    @Test func sameObjectReturnsNoPreview() {
        let (line, _) = makeLineAndCircle()
        let points = PlaneIntersectionPreviewResolver.previewPoints(
            firstObjectID: line.id,
            secondObjectID: line.id,
            objects: [line]
        )
        #expect(points.isEmpty)
    }

    @Test func hiddenSecondObjectIsIgnored() {
        let (line, circle) = makeLineAndCircle()
        let hiddenCircle = MathObject(
            id: circle.id,
            name: circle.name,
            type: circle.type,
            expression: circle.expression,
            style: circle.style,
            isVisible: false
        )
        let points = PlaneIntersectionPreviewResolver.previewPoints(
            firstObjectID: line.id,
            secondObjectID: hiddenCircle.id,
            objects: [line, hiddenCircle]
        )
        #expect(points.isEmpty)
    }

    @Test func invalidObjectTypeAsSecondReturnsNoPreview() {
        let (line, _) = makeLineAndCircle()
        let point = MathObject(
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            position: .zero,
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let points = PlaneIntersectionPreviewResolver.previewPoints(
            firstObjectID: line.id,
            secondObjectID: point.id,
            objects: [line, point]
        )
        #expect(points.isEmpty)
    }

    @Test func tangentCircleCirclePreviewReturnsOnePoint() {
        let c1 = makeCircle(name: "c1", source: "x^2+y^2=1")
        let c2 = makeCircle(name: "c2", source: "(x-2)^2+y^2=1")
        let points = PlaneIntersectionPreviewResolver.previewPoints(
            firstObjectID: c1.id,
            secondObjectID: c2.id,
            objects: [c1, c2]
        )
        #expect(points.count == 1)
    }

    private func makeLineAndCircle() -> (MathObject, MathObject) {
        let line = MathObject(
            name: "l1",
            type: .line,
            expression: MathExpression(displayText: "l1: 直线"),
            points: [WorldPoint(x: -2, y: 0), WorldPoint(x: 2, y: 0)],
            geometryDefinition: GeometryDefinition(
                kind: .line,
                anchors: [.fixedPoint(WorldPoint(x: -2, y: 0)), .fixedPoint(WorldPoint(x: 2, y: 0))]
            ),
            style: MathStyle(colorToken: "indigo")
        )
        return (line, makeCircle(name: "c1", source: "x^2+y^2=1"))
    }

    private func makeCircle(name: String, source: String) -> MathObject {
        let built = PlaneExpressionService.buildExpression(from: source, fallbackToExplicitY: false)
        switch built {
        case .success(let expression):
            return MathObject(
                name: name,
                type: .circle,
                expression: expression,
                style: MathStyle(colorToken: "green")
            )
        case .failure(let error):
            Issue.record("failed to build circle expression: \(error.message)")
            return MathObject(
                name: name,
                type: .circle,
                expression: MathExpression(displayText: source),
                style: MathStyle(colorToken: "green")
            )
        }
    }
}
