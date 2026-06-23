import Foundation
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct SessionUndoRedoTests {
    @MainActor
    @Test func openBaselineInitializesWithEmptyStacks() throws {
        let state = makeState(objects: [])
        #expect(state.undoDepth == 0)
        #expect(state.redoDepth == 0)
        #expect(state.canUndo == false)
        #expect(state.canRedo == false)
        #expect(state.canRevertToOpenState == false)
    }

    @MainActor
    @Test func undoRedoForCreatePointWorks() throws {
        let state = makeState(objects: [])
        let world = WorldPoint(x: 1, y: 2)

        state.dispatch(.createPoint(at: world))
        #expect(state.undoDepth == 1)
        #expect(state.document.objects.count == 1)
        #expect(state.canUndo == true)
        #expect(state.canRevertToOpenState == true)

        state.dispatch(.undo)
        #expect(state.document.objects.isEmpty)
        #expect(state.redoDepth == 1)
        #expect(state.canRedo == true)

        state.dispatch(.redo)
        #expect(state.document.objects.count == 1)
        #expect(state.undoDepth == 1)
    }

    @MainActor
    @Test func movingDynamicMidpointSourceRecordsSingleUndoStepAndRestoresDerived() throws {
        let pointA = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let pointB = MathObject(
            id: UUID(),
            name: "B",
            type: .point,
            expression: MathExpression(displayText: "B=(2,0)"),
            position: WorldPoint(x: 2, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let midpoint = MathObject(
            id: UUID(),
            name: "M",
            type: .point,
            expression: MathExpression(displayText: "M=(1,0)"),
            position: WorldPoint(x: 1, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .midpointOfPoints(pointAID: pointA.id, pointBID: pointB.id)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "green")
        )
        let state = makeState(objects: [pointA, pointB, midpoint])

        state.dispatch(.updateObjectPosition(id: pointA.id, position: WorldPoint(x: 2, y: 2)))
        #expect(state.undoDepth == 1)
        guard let movedM = state.document.objects.first(where: { $0.id == midpoint.id }) else {
            Issue.record("midpoint missing after move")
            return
        }
        #expect(movedM.position == WorldPoint(x: 2, y: 1))

        state.dispatch(.undo)
        guard let restoredA = state.document.objects.first(where: { $0.id == pointA.id }),
              let restoredM = state.document.objects.first(where: { $0.id == midpoint.id }) else {
            Issue.record("objects missing after undo")
            return
        }
        #expect(restoredA.position == WorldPoint(x: 0, y: 0))
        #expect(restoredM.position == WorldPoint(x: 1, y: 0))
        #expect(restoredM.geometryDependency != nil)
    }

    @MainActor
    @Test func objectDragCoalescesMultipleUpdatesIntoSingleUndoStep() throws {
        let point = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let state = makeState(objects: [point])

        state.dispatch(.setObjectDragging(id: point.id, isDragging: true))
        state.dispatch(.updateObjectPosition(id: point.id, position: WorldPoint(x: 1, y: 1)))
        state.dispatch(.updateObjectPosition(id: point.id, position: WorldPoint(x: 2, y: 2)))
        state.dispatch(.updateObjectPosition(id: point.id, position: WorldPoint(x: 3, y: 3)))
        state.dispatch(.setObjectDragging(id: point.id, isDragging: false))

        #expect(state.undoDepth == 1)
        guard let moved = state.document.objects.first(where: { $0.id == point.id }) else {
            Issue.record("Missing moved point")
            return
        }
        #expect(moved.position == WorldPoint(x: 3, y: 3))

        state.dispatch(.undo)
        guard let restored = state.document.objects.first(where: { $0.id == point.id }) else {
            Issue.record("Missing restored point")
            return
        }
        #expect(restored.position == WorldPoint(x: 0, y: 0))
    }

    @MainActor
    @Test func deleteSourceWithCleanupIsSingleUndoStepAndUndoRestoresDependency() throws {
        let pointA = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let pointB = MathObject(
            id: UUID(),
            name: "B",
            type: .point,
            expression: MathExpression(displayText: "B=(2,0)"),
            position: WorldPoint(x: 2, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let midpoint = MathObject(
            id: UUID(),
            name: "M",
            type: .point,
            expression: MathExpression(displayText: "M=(1,0)"),
            position: WorldPoint(x: 1, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .midpointOfPoints(pointAID: pointA.id, pointBID: pointB.id)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "green")
        )
        let state = makeState(objects: [pointA, pointB, midpoint])

        state.dispatch(.deleteObject(id: pointA.id))
        #expect(state.undoDepth == 1)
        guard let afterDeleteM = state.document.objects.first(where: { $0.id == midpoint.id }) else {
            Issue.record("midpoint missing")
            return
        }
        #expect(afterDeleteM.geometryDependency == nil)

        state.dispatch(.undo)
        guard let restoredA = state.document.objects.first(where: { $0.id == pointA.id }),
              let restoredM = state.document.objects.first(where: { $0.id == midpoint.id }) else {
            Issue.record("restored objects missing")
            return
        }
        #expect(restoredA.position == pointA.position)
        #expect(restoredM.geometryDependency != nil)
    }

    @MainActor
    @Test func deleteObjectRecordsDeletedHistoryAndUndoRestoresHistoryState() throws {
        let point = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let state = makeState(objects: [point])

        state.dispatch(.deleteObject(id: point.id))
        #expect(state.document.objects.isEmpty)
        #expect(state.document.deletedObjectHistory?.count == 1)
        #expect(state.document.deletedObjectHistory?.first?.object.id == point.id)
        #expect(state.document.deletedObjectHistory?.first?.context == .userDelete)

        state.dispatch(.undo)
        #expect(state.document.objects.contains(where: { $0.id == point.id }))
        #expect(state.document.deletedObjectHistory == nil || state.document.deletedObjectHistory?.isEmpty == true)

        state.dispatch(.redo)
        #expect(state.document.objects.isEmpty)
        #expect(state.document.deletedObjectHistory?.count == 1)
    }

    @MainActor
    @Test func canvasPanZoomUpdatesCoalesceIntoSingleUndoStep() throws {
        let state = makeState(objects: [])
        let before = state.document.canvasState

        state.dispatch(.setCanvasInteracting(true))
        state.dispatch(.setCanvasViewport(CanvasState(
            origin: CGPoint(x: 20, y: 10),
            scale: before.scale,
            showGrid: before.showGrid,
            showAxis: before.showAxis,
            minScale: before.minScale,
            maxScale: before.maxScale
        )))
        state.dispatch(.setCanvasViewport(CanvasState(
            origin: CGPoint(x: 40, y: 20),
            scale: before.scale * 1.2,
            showGrid: before.showGrid,
            showAxis: before.showAxis,
            minScale: before.minScale,
            maxScale: before.maxScale
        )))
        state.dispatch(.setCanvasInteracting(false))

        #expect(state.undoDepth == 1)
        #expect(state.document.canvasState.origin == CGPoint(x: 40, y: 20))

        state.dispatch(.undo)
        #expect(state.document.canvasState == before)
    }

    @MainActor
    @Test func revertToOpenStateRestoresBaselineAndIsUndoable() throws {
        let state = makeState(objects: [])
        let baseline = state.document

        state.dispatch(.createPoint(at: WorldPoint(x: 1, y: 1)))
        #expect(state.document != baseline)

        state.dispatch(.revertToOpenState)
        #expect(state.document == baseline)
        #expect(state.canUndo)

        state.dispatch(.undo)
        #expect(state.document != baseline)
    }

    @MainActor
    @Test func deleteSelectedWithAffectedShowsConfirmationAndUnlinkIsSingleUndoStep() throws {
        let pointA = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let pointB = MathObject(
            id: UUID(),
            name: "B",
            type: .point,
            expression: MathExpression(displayText: "B=(2,0)"),
            position: WorldPoint(x: 2, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let midpoint = MathObject(
            id: UUID(),
            name: "M",
            type: .point,
            expression: MathExpression(displayText: "M=(1,0)"),
            position: WorldPoint(x: 1, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .midpointOfPoints(pointAID: pointA.id, pointBID: pointB.id)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "green")
        )
        let state = makeState(objects: [pointA, pointB, midpoint])
        state.selectedObjectIDs = [pointA.id]

        state.dispatch(.deleteSelectedObjects)
        #expect(state.document.objects.contains(where: { $0.id == pointA.id }))
        #expect(state.pendingDependencyDeletion != nil)
        #expect(state.undoDepth == 0)

        state.confirmPendingDependencyDeletion(strategy: .unlink)
        #expect(state.pendingDependencyDeletion == nil)
        #expect(state.document.objects.contains(where: { $0.id == pointA.id }) == false)
        guard let remainingMidpoint = state.document.objects.first(where: { $0.id == midpoint.id }) else {
            Issue.record("Missing midpoint after unlink")
            return
        }
        #expect(remainingMidpoint.geometryDependency == nil)
        #expect(state.document.deletedObjectHistory?.count == 1)
        #expect(state.document.deletedObjectHistory?.first?.object.id == pointA.id)
        #expect(state.undoDepth == 1)

        state.dispatch(.undo)
        #expect(state.document.objects.contains(where: { $0.id == pointA.id }))
        guard let restoredMidpoint = state.document.objects.first(where: { $0.id == midpoint.id }) else {
            Issue.record("Missing midpoint after undo")
            return
        }
        #expect(restoredMidpoint.geometryDependency != nil)
    }

    @MainActor
    @Test func deleteSelectedWithAffectedDeletesDownstreamRecursively() throws {
        let pointA = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let pointB = MathObject(
            id: UUID(),
            name: "B",
            type: .point,
            expression: MathExpression(displayText: "B=(2,0)"),
            position: WorldPoint(x: 2, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let midpoint = MathObject(
            id: UUID(),
            name: "M",
            type: .point,
            expression: MathExpression(displayText: "M=(1,0)"),
            position: WorldPoint(x: 1, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .midpointOfPoints(pointAID: pointA.id, pointBID: pointB.id)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "green")
        )
        let circle = MathObject(
            id: UUID(),
            name: "C",
            type: .circle,
            expression: MathExpression(displayText: "C: 圆"),
            points: [WorldPoint(x: 1, y: 0), WorldPoint(x: 3, y: 0)],
            geometryDefinition: GeometryDefinition(kind: .circle, anchors: [.object(midpoint.id), .fixedPoint(WorldPoint(x: 3, y: 0))]),
            geometryDependency: GeometryDependency(kind: .circleByCenterRadius(centerPointID: midpoint.id, radius: 2)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "green")
        )
        let unrelated = MathObject(
            id: UUID(),
            name: "U",
            type: .point,
            expression: MathExpression(displayText: "U=(9,9)"),
            position: WorldPoint(x: 9, y: 9),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "indigo")
        )
        let state = makeState(objects: [pointA, pointB, midpoint, circle, unrelated])
        state.selectedObjectIDs = [pointA.id]

        state.dispatch(.deleteSelectedObjects)
        guard let context = state.pendingDependencyDeletion else {
            Issue.record("Missing dependency delete context")
            return
        }
        #expect(context.affectedIDs == Set([midpoint.id]))

        state.confirmPendingDependencyDeletion(strategy: .deleteAffected)
        #expect(state.document.objects.contains(where: { $0.id == pointA.id }) == false)
        #expect(state.document.objects.contains(where: { $0.id == midpoint.id }) == false)
        #expect(state.document.objects.contains(where: { $0.id == circle.id }) == false)
        #expect(state.document.objects.contains(where: { $0.id == unrelated.id }))
        #expect(state.undoDepth == 1)
    }

    @MainActor
    @Test func deleteSelectedWithoutAffectedKeepsOldBehavior() throws {
        let pointA = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let pointB = MathObject(
            id: UUID(),
            name: "B",
            type: .point,
            expression: MathExpression(displayText: "B=(1,1)"),
            position: WorldPoint(x: 1, y: 1),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let state = makeState(objects: [pointA, pointB])
        state.selectedObjectIDs = [pointA.id]

        state.dispatch(.deleteSelectedObjects)
        #expect(state.pendingDependencyDeletion == nil)
        #expect(state.document.objects.contains(where: { $0.id == pointA.id }) == false)
        #expect(state.undoDepth == 1)
    }

    @MainActor
    @Test func singleDeleteWithAffectedUnlinkSupportsUndoRedoInOneStep() throws {
        let pointA = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let pointB = MathObject(
            id: UUID(),
            name: "B",
            type: .point,
            expression: MathExpression(displayText: "B=(2,0)"),
            position: WorldPoint(x: 2, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let midpoint = MathObject(
            id: UUID(),
            name: "M",
            type: .point,
            expression: MathExpression(displayText: "M=(1,0)"),
            position: WorldPoint(x: 1, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .midpointOfPoints(pointAID: pointA.id, pointBID: pointB.id)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "green")
        )
        let state = makeState(objects: [pointA, pointB, midpoint])

        state.requestDeleteObjectsWithConfirmation([pointA.id])
        #expect(state.pendingDependencyDeletion != nil)
        #expect(state.undoDepth == 0)
        state.confirmPendingDependencyDeletion(strategy: .unlink)

        #expect(state.undoDepth == 1)
        #expect(state.document.objects.contains(where: { $0.id == pointA.id }) == false)
        guard let afterDeleteMidpoint = state.document.objects.first(where: { $0.id == midpoint.id }) else {
            Issue.record("Missing midpoint after unlink")
            return
        }
        #expect(afterDeleteMidpoint.geometryDependency == nil)
        #expect(afterDeleteMidpoint.geometryDefinitionStatus == nil)

        state.dispatch(.undo)
        guard let restoredMidpoint = state.document.objects.first(where: { $0.id == midpoint.id }) else {
            Issue.record("Missing midpoint after undo")
            return
        }
        #expect(state.document.objects.contains(where: { $0.id == pointA.id }))
        #expect(restoredMidpoint.geometryDependency != nil)
        #expect(restoredMidpoint.geometryDefinitionStatus == .defined)

        state.dispatch(.redo)
        #expect(state.document.objects.contains(where: { $0.id == pointA.id }) == false)
        guard let redoneMidpoint = state.document.objects.first(where: { $0.id == midpoint.id }) else {
            Issue.record("Missing midpoint after redo")
            return
        }
        #expect(redoneMidpoint.geometryDependency == nil)
        #expect(redoneMidpoint.geometryDefinitionStatus == nil)
    }

    @MainActor
    @Test func singleDeleteWithAffectedDeleteAffectedSupportsUndoRedoInOneStep() throws {
        let pointA = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let pointB = MathObject(
            id: UUID(),
            name: "B",
            type: .point,
            expression: MathExpression(displayText: "B=(2,0)"),
            position: WorldPoint(x: 2, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let midpoint = MathObject(
            id: UUID(),
            name: "M",
            type: .point,
            expression: MathExpression(displayText: "M=(1,0)"),
            position: WorldPoint(x: 1, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .midpointOfPoints(pointAID: pointA.id, pointBID: pointB.id)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "green")
        )
        let downstream = MathObject(
            id: UUID(),
            name: "C",
            type: .circle,
            expression: MathExpression(displayText: "C: 圆"),
            points: [WorldPoint(x: 1, y: 0), WorldPoint(x: 3, y: 0)],
            geometryDefinition: GeometryDefinition(kind: .circle, anchors: [.object(midpoint.id), .fixedPoint(WorldPoint(x: 3, y: 0))]),
            geometryDependency: GeometryDependency(kind: .circleByCenterRadius(centerPointID: midpoint.id, radius: 2)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "green")
        )
        let state = makeState(objects: [pointA, pointB, midpoint, downstream])

        state.requestDeleteObjectsWithConfirmation([pointA.id])
        state.confirmPendingDependencyDeletion(strategy: .deleteAffected)
        #expect(state.undoDepth == 1)
        #expect(state.document.objects.contains(where: { $0.id == pointA.id }) == false)
        #expect(state.document.objects.contains(where: { $0.id == midpoint.id }) == false)
        #expect(state.document.objects.contains(where: { $0.id == downstream.id }) == false)

        state.dispatch(.undo)
        #expect(state.document.objects.contains(where: { $0.id == pointA.id }))
        #expect(state.document.objects.contains(where: { $0.id == midpoint.id }))
        guard let restoredDownstream = state.document.objects.first(where: { $0.id == downstream.id }) else {
            Issue.record("Missing downstream after undo")
            return
        }
        #expect(restoredDownstream.geometryDependency != nil)
        #expect(restoredDownstream.geometryDefinitionStatus == .defined)

        state.dispatch(.redo)
        #expect(state.document.objects.contains(where: { $0.id == pointA.id }) == false)
        #expect(state.document.objects.contains(where: { $0.id == midpoint.id }) == false)
    }

    @MainActor
    @Test func deleteAffectedRecursiveRemovesCircleAndIntersectionDownstream() throws {
        let center = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let line = MathObject(
            id: UUID(),
            name: "l",
            type: .line,
            expression: MathExpression(displayText: "l: 直线"),
            points: [WorldPoint(x: -5, y: 0), WorldPoint(x: 5, y: 0)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.fixedPoint(WorldPoint(x: -5, y: 0)), .fixedPoint(WorldPoint(x: 5, y: 0))]),
            style: MathStyle(colorToken: "blue")
        )
        let circle = MathObject(
            id: UUID(),
            name: "c",
            type: .circle,
            expression: MathExpression(displayText: "c: 圆"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 2, y: 0)],
            geometryDefinition: GeometryDefinition(kind: .circle, anchors: [.object(center.id), .fixedPoint(WorldPoint(x: 2, y: 0))]),
            geometryDependency: GeometryDependency(kind: .circleByCenterRadius(centerPointID: center.id, radius: 2)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "green")
        )
        let intersection = MathObject(
            id: UUID(),
            name: "I",
            type: .point,
            expression: MathExpression(displayText: "I=(2,0)"),
            position: WorldPoint(x: 2, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .intersectionOf(objectAID: line.id, objectBID: circle.id, index: 0)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "yellowOrange")
        )
        let state = makeState(objects: [center, line, circle, intersection])

        state.requestDeleteObjectsWithConfirmation([center.id])
        state.confirmPendingDependencyDeletion(strategy: .deleteAffected)

        #expect(state.document.objects.contains(where: { $0.id == center.id }) == false)
        #expect(state.document.objects.contains(where: { $0.id == circle.id }) == false)
        #expect(state.document.objects.contains(where: { $0.id == intersection.id }) == false)
        #expect(state.document.objects.contains(where: { $0.id == line.id }))

        state.dispatch(.undo)
        #expect(state.document.objects.contains(where: { $0.id == center.id }))
        #expect(state.document.objects.contains(where: { $0.id == circle.id }))
        #expect(state.document.objects.contains(where: { $0.id == intersection.id }))
        guard let history = state.document.deletedObjectHistory else {
            Issue.record("Missing deleted history")
            return
        }
        #expect(history.count == 3)
        #expect(history.allSatisfy { $0.context == .deleteAffected })
    }

    @MainActor
    @Test func restoreDeletedObjectRestoresAsIndependentAndIsUndoable() throws {
        let pointA = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let pointB = MathObject(
            id: UUID(),
            name: "B",
            type: .point,
            expression: MathExpression(displayText: "B=(2,0)"),
            position: WorldPoint(x: 2, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let midpoint = MathObject(
            id: UUID(),
            name: "M",
            type: .point,
            expression: MathExpression(displayText: "M=(1,0)"),
            position: WorldPoint(x: 1, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .midpointOfPoints(pointAID: pointA.id, pointBID: pointB.id)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "green")
        )
        let state = makeState(objects: [pointA, pointB, midpoint])

        state.dispatch(.deleteObject(id: midpoint.id))
        let recordID = try #require(state.document.deletedObjectHistory?.first?.id)
        state.dispatch(.restoreDeletedObject(recordID: recordID))

        guard let restored = state.document.objects.first(where: { $0.name == "M" }) else {
            Issue.record("Missing restored object")
            return
        }
        #expect(restored.geometryDependency == nil)
        #expect(restored.geometryDefinitionStatus == nil)
        #expect(state.document.deletedObjectHistory?.isEmpty ?? true)
        #expect(state.selectedObjectID == restored.id)

        state.dispatch(.undo)
        #expect(state.document.objects.contains(where: { $0.id == midpoint.id }) == false)
        #expect(state.document.deletedObjectHistory?.count == 1)
    }

    @MainActor
    @Test func restoreDeletedObjectHandlesIDConflictByAssigningNewID() throws {
        let originalID = UUID()
        let activeConflict = MathObject(
            id: originalID,
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let deletedPayload = MathObject(
            id: originalID,
            name: "DeletedA",
            type: .point,
            expression: MathExpression(displayText: "DeletedA=(1,1)"),
            position: WorldPoint(x: 1, y: 1),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .midpointOfPoints(pointAID: UUID(), pointBID: UUID())),
            geometryDefinitionStatus: .missingSource,
            style: MathStyle(colorToken: "green")
        )
        let record = DeletedObjectRecord(object: deletedPayload, context: .userDelete)
        let state = makeState(objects: [activeConflict])
        state.document.deletedObjectHistory = [record]

        state.dispatch(.restoreDeletedObject(recordID: record.id))
        guard let restored = state.document.objects.first(where: { $0.name == "DeletedA" }) else {
            Issue.record("Missing restored object")
            return
        }
        #expect(restored.id != originalID)
        #expect(restored.geometryDependency == nil)
        #expect(restored.geometryDefinitionStatus == nil)
        #expect(state.selectedObjectID == restored.id)
    }

    @MainActor
    @Test func batchDeleteWithAffectedUnlinkSupportsRedo() throws {
        let pointA = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let pointB = MathObject(
            id: UUID(),
            name: "B",
            type: .point,
            expression: MathExpression(displayText: "B=(2,0)"),
            position: WorldPoint(x: 2, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let midpoint = MathObject(
            id: UUID(),
            name: "M",
            type: .point,
            expression: MathExpression(displayText: "M=(1,0)"),
            position: WorldPoint(x: 1, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .midpointOfPoints(pointAID: pointA.id, pointBID: pointB.id)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "green")
        )
        let state = makeState(objects: [pointA, pointB, midpoint])
        state.selectedObjectIDs = [pointA.id, pointB.id]

        state.dispatch(.deleteSelectedObjects)
        state.confirmPendingDependencyDeletion(strategy: .unlink)
        #expect(state.undoDepth == 1)
        #expect(state.document.objects.contains(where: { $0.id == pointA.id }) == false)
        #expect(state.document.objects.contains(where: { $0.id == pointB.id }) == false)
        guard let afterDeleteMidpoint = state.document.objects.first(where: { $0.id == midpoint.id }) else {
            Issue.record("Missing midpoint after batch unlink")
            return
        }
        #expect(afterDeleteMidpoint.geometryDependency == nil)

        state.dispatch(.undo)
        #expect(state.document.objects.contains(where: { $0.id == pointA.id }))
        #expect(state.document.objects.contains(where: { $0.id == pointB.id }))
        state.dispatch(.redo)
        #expect(state.document.objects.contains(where: { $0.id == pointA.id }) == false)
        #expect(state.document.objects.contains(where: { $0.id == pointB.id }) == false)
    }

    @MainActor
    @Test func deleteConfirmationCancelDoesNotMutateDocumentOrUndoStack() throws {
        let pointA = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let pointB = MathObject(
            id: UUID(),
            name: "B",
            type: .point,
            expression: MathExpression(displayText: "B=(2,0)"),
            position: WorldPoint(x: 2, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let midpoint = MathObject(
            id: UUID(),
            name: "M",
            type: .point,
            expression: MathExpression(displayText: "M=(1,0)"),
            position: WorldPoint(x: 1, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .midpointOfPoints(pointAID: pointA.id, pointBID: pointB.id)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "green")
        )
        let state = makeState(objects: [pointA, pointB, midpoint])
        let beforeDocument = state.document
        let beforeUndo = state.undoDepth
        let beforeRedo = state.redoDepth

        state.requestDeleteObjectsWithConfirmation([pointA.id])
        #expect(state.pendingDependencyDeletion != nil)
        state.cancelPendingDependencyDeletion()

        #expect(state.pendingDependencyDeletion == nil)
        #expect(state.document == beforeDocument)
        #expect(state.undoDepth == beforeUndo)
        #expect(state.redoDepth == beforeRedo)
    }

    @MainActor
    @Test func revertAfterDeletionRestoresBaselineAndUndoRevertReturnsDeletionState() throws {
        let pointA = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let pointB = MathObject(
            id: UUID(),
            name: "B",
            type: .point,
            expression: MathExpression(displayText: "B=(2,0)"),
            position: WorldPoint(x: 2, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let midpoint = MathObject(
            id: UUID(),
            name: "M",
            type: .point,
            expression: MathExpression(displayText: "M=(1,0)"),
            position: WorldPoint(x: 1, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .midpointOfPoints(pointAID: pointA.id, pointBID: pointB.id)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "green")
        )
        let state = makeState(objects: [pointA, pointB, midpoint])
        let baseline = state.document

        state.requestDeleteObjectsWithConfirmation([pointA.id])
        state.confirmPendingDependencyDeletion(strategy: .unlink)
        let deletionState = state.document
        #expect(deletionState != baseline)

        state.dispatch(.revertToOpenState)
        #expect(state.document == baseline)
        #expect(state.canUndo)

        state.dispatch(.undo)
        #expect(state.document == deletionState)
    }

    @MainActor
    @Test func unlinkClearsNoSolutionStatusAndUndoRestoresIt() throws {
        let sourceA = MathObject(
            id: UUID(),
            name: "l1",
            type: .line,
            expression: MathExpression(displayText: "l1: 直线"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 1, y: 0)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.fixedPoint(WorldPoint(x: 0, y: 0)), .fixedPoint(WorldPoint(x: 1, y: 0))]),
            style: MathStyle(colorToken: "blue")
        )
        let sourceB = MathObject(
            id: UUID(),
            name: "c1",
            type: .circle,
            expression: MathExpression(displayText: "c1: 圆"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 1, y: 0)],
            geometryDefinition: GeometryDefinition(kind: .circle, anchors: [.fixedPoint(WorldPoint(x: 0, y: 0)), .fixedPoint(WorldPoint(x: 1, y: 0))]),
            style: MathStyle(colorToken: "green")
        )
        let intersection = MathObject(
            id: UUID(),
            name: "I",
            type: .point,
            expression: MathExpression(displayText: "I"),
            position: WorldPoint(x: 9, y: 9),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .intersectionOf(objectAID: sourceA.id, objectBID: sourceB.id, index: 0)),
            geometryDefinitionStatus: .noSolution,
            style: MathStyle(colorToken: "yellowOrange")
        )
        let state = makeState(objects: [sourceA, sourceB, intersection])

        state.requestDeleteObjectsWithConfirmation([sourceA.id])
        state.confirmPendingDependencyDeletion(strategy: .unlink)
        guard let afterUnlink = state.document.objects.first(where: { $0.id == intersection.id }) else {
            Issue.record("Missing intersection after unlink")
            return
        }
        #expect(afterUnlink.geometryDependency == nil)
        #expect(afterUnlink.geometryDefinitionStatus == nil)

        state.dispatch(.undo)
        guard let restored = state.document.objects.first(where: { $0.id == intersection.id }) else {
            Issue.record("Missing intersection after undo")
            return
        }
        #expect(restored.geometryDependency != nil)
        #expect(restored.geometryDefinitionStatus == .noSolution)
    }

    @MainActor
    private func makeState(objects: [MathObject]) -> WorkspaceState {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "undo-test",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: objects
        )
        return WorkspaceState(
            module: .plane,
            document: document,
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
    }
}
