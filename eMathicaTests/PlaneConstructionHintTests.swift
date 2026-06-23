import Foundation
import Testing
import EMathicaMathCore
@testable import eMathica

struct PlaneConstructionHintTests {
    @Test func segmentAndCircleConstructionHintsDescribeTheCurrentStep() {
        let segmentState = PlaneInteractionState(
            activeConstruction: .segmentSecondPoint(
                startWorldPoint: WorldPoint(x: 1, y: 2),
                startPointID: nil
            ),
            pendingPointID: nil,
            pendingWorldPoint: WorldPoint(x: 1, y: 2),
            constructionPreview: .temporarySegment(
                start: WorldPoint(x: 1, y: 2),
                current: WorldPoint(x: 2, y: 3)
            )
        )
        #expect(segmentState.constructionHintText == "线段：选择第二个点")

        let circleState = PlaneInteractionState(
            activeConstruction: .circleRadius(centerPointID: nil),
            pendingPointID: nil,
            pendingWorldPoint: WorldPoint(x: 0, y: 0),
            constructionPreview: .temporaryCircle(
                center: WorldPoint(x: 0, y: 0),
                currentRadiusPoint: WorldPoint(x: 3, y: 0)
            )
        )
        #expect(circleState.constructionHintText == "圆：选择圆上一点")
    }

    @Test func arcConstructionHintsDescribeSecondAndThirdSteps() {
        let secondStepState = PlaneInteractionState(
            activeConstruction: .arcSecondPoint(
                firstWorldPoint: WorldPoint(x: 0, y: 0),
                firstPointID: nil
            ),
            pendingPointID: nil,
            pendingWorldPoint: WorldPoint(x: 1, y: 0),
            constructionPreview: nil
        )
        #expect(secondStepState.constructionHintText == "圆弧：选择第二个点")

        let thirdStepState = PlaneInteractionState(
            activeConstruction: .arcThirdPoint(
                firstWorldPoint: WorldPoint(x: 0, y: 0),
                firstPointID: nil,
                secondWorldPoint: WorldPoint(x: 1, y: 0),
                secondPointID: nil
            ),
            pendingPointID: nil,
            pendingWorldPoint: WorldPoint(x: 1, y: 1),
            constructionPreview: .temporaryArc(
                pointA: WorldPoint(x: 0, y: 0),
                pointB: WorldPoint(x: 1, y: 0),
                pointC: WorldPoint(x: 1, y: 1)
            )
        )
        #expect(thirdStepState.constructionHintText == "圆弧：选择第三个点")
    }

    @Test func clearConstructionProgressRemovesIntermediateStateWithoutTouchingOtherFlags() {
        var state = PlaneInteractionState(
            activeConstruction: .intersectionSecondObject(firstObjectID: UUID()),
            pendingPointID: UUID(),
            pendingWorldPoint: WorldPoint(x: 2, y: 3),
            constructionPreview: .temporaryIntersections(points: [WorldPoint(x: 1, y: 1)]),
            isDraggingObject: true,
            draggingObjectID: UUID()
        )

        state.clearConstructionProgress()

        #expect(state.activeConstruction == nil)
        #expect(state.pendingPointID == nil)
        #expect(state.pendingWorldPoint == nil)
        #expect(state.constructionPreview == nil)
        #expect(state.isDraggingObject == true)
        #expect(state.draggingObjectID != nil)
    }
}
