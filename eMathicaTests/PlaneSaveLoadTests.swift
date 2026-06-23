import Foundation
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct PlaneSaveLoadTests {
    @Test func documentRoundTripPreservesDependencyStatusCanvasAndSliderFields() throws {
        let centerID = UUID()
        let throughID = UUID()
        let referenceID = UUID()
        let throughPointID = UUID()
        let lineAID = UUID()
        let lineBID = UUID()

        let center = MathObject(
            id: centerID,
            name: "C",
            type: .point,
            expression: MathExpression(displayText: "C=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "green")
        )
        let through = MathObject(
            id: throughID,
            name: "T",
            type: .point,
            expression: MathExpression(displayText: "T=(2,0)"),
            position: WorldPoint(x: 2, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "pink")
        )
        let reference = MathObject(
            id: referenceID,
            name: "s1",
            type: .segment,
            expression: MathExpression(displayText: "s1"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 3, y: 1)],
            geometryDefinition: GeometryDefinition(kind: .segment, anchors: [.fixedPoint(WorldPoint(x: 0, y: 0)), .fixedPoint(WorldPoint(x: 3, y: 1))]),
            style: MathStyle(colorToken: "blue")
        )
        let throughPoint = MathObject(
            id: throughPointID,
            name: "P",
            type: .point,
            expression: MathExpression(displayText: "P=(1,2)"),
            position: WorldPoint(x: 1, y: 2),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let lineA = MathObject(
            id: lineAID,
            name: "l1",
            type: .line,
            expression: MathExpression(displayText: "l1"),
            points: [WorldPoint(x: -2, y: 0), WorldPoint(x: 2, y: 0)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.fixedPoint(WorldPoint(x: -2, y: 0)), .fixedPoint(WorldPoint(x: 2, y: 0))]),
            style: MathStyle(colorToken: "indigo")
        )
        let lineB = MathObject(
            id: lineBID,
            name: "l2",
            type: .line,
            expression: MathExpression(displayText: "l2"),
            points: [WorldPoint(x: -1, y: 1), WorldPoint(x: 1, y: 1)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.fixedPoint(WorldPoint(x: -1, y: 1)), .fixedPoint(WorldPoint(x: 1, y: 1))]),
            style: MathStyle(colorToken: "purple")
        )
        let parameter = MathObject(
            name: "a",
            type: .parameter,
            expression: MathExpression(displayText: "a=2"),
            parameterValue: 2,
            sliderSettings: SliderSettings(
                min: -5,
                max: 5,
                step: 0.2,
                precision: 2,
                speed: 1.4,
                playbackMode: .pingPong,
                playbackLoopMode: .loop
            ),
            style: MathStyle(colorToken: "orange")
        )

        let midpoint = MathObject(
            name: "M",
            type: .point,
            expression: MathExpression(displayText: "M"),
            position: WorldPoint(x: 1, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .midpointOfPoints(pointAID: centerID, pointBID: throughID)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "green")
        )
        let parallel = MathObject(
            name: "p",
            type: .line,
            expression: MathExpression(displayText: "p"),
            points: [WorldPoint(x: 1, y: 2), WorldPoint(x: 4, y: 3)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.object(throughPointID), .fixedPoint(WorldPoint(x: 4, y: 3))]),
            geometryDependency: GeometryDependency(kind: .parallelLine(referenceObjectID: referenceID, throughPointID: throughPointID)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "blue")
        )
        let perpendicular = MathObject(
            name: "q",
            type: .line,
            expression: MathExpression(displayText: "q"),
            points: [WorldPoint(x: 1, y: 2), WorldPoint(x: 0, y: 5)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.object(throughPointID), .fixedPoint(WorldPoint(x: 0, y: 5))]),
            geometryDependency: GeometryDependency(kind: .perpendicularLine(referenceObjectID: referenceID, throughPointID: throughPointID)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "cyan")
        )
        let circleByPoint = MathObject(
            name: "c1",
            type: .circle,
            expression: MathExpression(displayText: "c1"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 2, y: 0)],
            geometryDefinition: GeometryDefinition(kind: .circle, anchors: [.object(centerID), .object(throughID)]),
            geometryDependency: GeometryDependency(kind: .circleByCenterPoint(centerPointID: centerID, throughPointID: throughID)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "green")
        )
        let circleByRadius = MathObject(
            name: "c2",
            type: .circle,
            expression: MathExpression(displayText: "c2"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 3, y: 0)],
            geometryDefinition: GeometryDefinition(kind: .circle, anchors: [.object(centerID), .fixedPoint(WorldPoint(x: 3, y: 0))]),
            geometryDependency: GeometryDependency(kind: .circleByCenterRadius(centerPointID: centerID, radius: 3)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "green")
        )
        let noSolutionIntersection = MathObject(
            name: "I",
            type: .point,
            expression: MathExpression(displayText: "I"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .intersectionOf(objectAID: lineAID, objectBID: lineBID, index: 0)),
            geometryDefinitionStatus: .noSolution,
            style: MathStyle(colorToken: "yellowOrange")
        )

        let now = Date()
        let document = EMathicaDocument(
            metadata: ProjectMetadata(
                title: "save-load-roundtrip",
                moduleID: "plane",
                createdAt: now,
                updatedAt: now,
                calculatorType: "plane"
            ),
            moduleID: "plane",
            objects: [center, through, reference, throughPoint, lineA, lineB, parameter, midpoint, parallel, perpendicular, circleByPoint, circleByRadius, noSolutionIntersection],
            canvasState: CanvasState(
                origin: CGPoint(x: 48, y: -22),
                scale: 78,
                showGrid: false,
                showAxis: true,
                minScale: 10,
                maxScale: 800
            )
        )

        let encoded = try EMathicaPackageCodec.makeEncoder().encode(document)
        let decoded = try EMathicaPackageCodec.makeDecoder().decode(EMathicaDocument.self, from: encoded)

        #expect(decoded.canvasState == document.canvasState)
        #expect(decoded.objects.count == document.objects.count)
        #expect(Set(decoded.objects.map(\.id)) == Set(document.objects.map(\.id)))
        #expect(decoded.objects.contains { $0.geometryDefinition?.kind == .circle })
        #expect(decoded.objects.contains { $0.geometryDependency?.kind == .circleByCenterRadius(centerPointID: centerID, radius: 3) })
        #expect(decoded.objects.contains { $0.geometryDefinitionStatus == .noSolution })
        guard let decodedParameter = decoded.objects.first(where: { $0.type == .parameter }) else {
            Issue.record("Missing parameter")
            return
        }
        #expect(decodedParameter.parameterValue == 2)
        #expect(decodedParameter.sliderSettings?.speed == 1.4)
    }

    @Test func documentRoundTripPreservesDeletedObjectHistoryAndTrimsTo200() throws {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "history-roundtrip",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        var document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: []
        )

        let records: [DeletedObjectRecord] = (0..<210).map { index in
            let object = MathObject(
                name: "P\(index)",
                type: .point,
                expression: MathExpression(displayText: "P\(index)"),
                position: WorldPoint(x: Double(index), y: Double(index)),
                geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
                style: MathStyle(colorToken: "yellowOrange")
            )
            return DeletedObjectRecord(
                deletedAt: now.addingTimeInterval(Double(index)),
                object: object,
                context: .unknown
            )
        }
        document.apply(.appendDeletedObjectRecords(records))
        #expect(document.deletedObjectHistory?.count == EMathicaDocument.deletedObjectHistoryLimit)

        let encoded = try EMathicaPackageCodec.makeEncoder().encode(document)
        let decoded = try EMathicaPackageCodec.makeDecoder().decode(EMathicaDocument.self, from: encoded)
        #expect(decoded.deletedObjectHistory?.count == EMathicaDocument.deletedObjectHistoryLimit)
        #expect(decoded.objects.isEmpty)
    }

    @MainActor
    @Test func reopenedWorkspaceStartsFreshUndoHistoryAndBaselineAtOpenedDocument() throws {
        let document = PlaneModule.newDocument(title: "session-baseline")
        let state = WorkspaceState(
            module: .plane,
            document: document,
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )

        state.dispatch(.createPoint(at: WorldPoint(x: 1, y: 1)))
        #expect(state.canUndo)
        let persisted = state.document

        let data = try EMathicaPackageCodec.makeEncoder().encode(persisted)
        let reopenedDocument = try EMathicaPackageCodec.makeDecoder().decode(EMathicaDocument.self, from: data)

        let reopened = WorkspaceState(
            module: .plane,
            document: reopenedDocument,
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        #expect(reopened.undoDepth == 0)
        #expect(reopened.redoDepth == 0)
        #expect(reopened.canUndo == false)
        #expect(reopened.canRedo == false)
        #expect(reopened.canRevertToOpenState == false)

        reopened.dispatch(.createPoint(at: WorldPoint(x: 2, y: 2)))
        #expect(reopened.canRevertToOpenState)
        reopened.dispatch(.revertToOpenState)
        #expect(reopened.document == reopenedDocument)
    }

    @MainActor
    @Test func reopenKeepsNoSolutionAndCanRecoverToDefinedAfterSourceMove() throws {
        let pA = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let pB = MathObject(
            id: UUID(),
            name: "B",
            type: .point,
            expression: MathExpression(displayText: "B=(2,0)"),
            position: WorldPoint(x: 2, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let qA = MathObject(
            id: UUID(),
            name: "C",
            type: .point,
            expression: MathExpression(displayText: "C=(0,1)"),
            position: WorldPoint(x: 0, y: 1),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "green")
        )
        let qB = MathObject(
            id: UUID(),
            name: "D",
            type: .point,
            expression: MathExpression(displayText: "D=(2,1)"),
            position: WorldPoint(x: 2, y: 1),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "green")
        )
        let l1 = MathObject(
            id: UUID(),
            name: "l1",
            type: .line,
            expression: MathExpression(displayText: "l1"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 2, y: 0)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.object(pA.id), .object(pB.id)]),
            style: MathStyle(colorToken: "blue")
        )
        let l2 = MathObject(
            id: UUID(),
            name: "l2",
            type: .line,
            expression: MathExpression(displayText: "l2"),
            points: [WorldPoint(x: 0, y: 1), WorldPoint(x: 2, y: 1)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.object(qA.id), .object(qB.id)]),
            style: MathStyle(colorToken: "pink")
        )
        let intersection = MathObject(
            id: UUID(),
            name: "I",
            type: .point,
            expression: MathExpression(displayText: "I=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .intersectionOf(objectAID: l1.id, objectBID: l2.id, index: 0)),
            geometryDefinitionStatus: .noSolution,
            style: MathStyle(colorToken: "yellowOrange")
        )
        let now = Date()
        let document = EMathicaDocument(
            metadata: ProjectMetadata(
                title: "no-solution-reopen",
                moduleID: "plane",
                createdAt: now,
                updatedAt: now,
                calculatorType: "plane"
            ),
            moduleID: "plane",
            objects: [pA, pB, qA, qB, l1, l2, intersection]
        )

        let data = try EMathicaPackageCodec.makeEncoder().encode(document)
        let reopenedDocument = try EMathicaPackageCodec.makeDecoder().decode(EMathicaDocument.self, from: data)
        let state = WorkspaceState(
            module: .plane,
            document: reopenedDocument,
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )

        guard let reopenedIntersection = state.document.objects.first(where: { $0.id == intersection.id }) else {
            Issue.record("Missing reopened intersection")
            return
        }
        #expect(reopenedIntersection.geometryDefinitionStatus == .noSolution)

        state.dispatch(.updateObjectPosition(id: qB.id, position: WorldPoint(x: 2, y: 3)))
        guard let recoveredIntersection = state.document.objects.first(where: { $0.id == intersection.id }) else {
            Issue.record("Missing recovered intersection")
            return
        }
        #expect(recoveredIntersection.geometryDefinitionStatus == .defined)
        #expect(recoveredIntersection.position != reopenedIntersection.position)
    }

    @MainActor
    @Test func midpointDependencySurvivesSaveReopenAndRecomputesAfterSourceMove() throws {
        let a = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let b = MathObject(
            id: UUID(),
            name: "B",
            type: .point,
            expression: MathExpression(displayText: "B=(4,0)"),
            position: WorldPoint(x: 4, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let midpoint = MathObject(
            id: UUID(),
            name: "M",
            type: .point,
            expression: MathExpression(displayText: "M=(2,0)"),
            position: WorldPoint(x: 2, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .midpointOfPoints(pointAID: a.id, pointBID: b.id)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "green")
        )
        let state = try reopenedState(
            objects: [a, b, midpoint],
            title: "midpoint-reopen"
        )

        guard let reopenedMidpoint = state.document.objects.first(where: { $0.id == midpoint.id }) else {
            Issue.record("Missing reopened midpoint")
            return
        }
        #expect(reopenedMidpoint.geometryDependency?.kind == midpoint.geometryDependency?.kind)
        #expect(reopenedMidpoint.geometryDefinitionStatus == .defined)

        state.dispatch(.updateObjectPosition(id: b.id, position: WorldPoint(x: 6, y: 0)))
        guard let recomputedMidpoint = state.document.objects.first(where: { $0.id == midpoint.id }) else {
            Issue.record("Missing recomputed midpoint")
            return
        }
        #expect(recomputedMidpoint.position == WorldPoint(x: 3, y: 0))
        #expect(recomputedMidpoint.geometryDependency?.kind == midpoint.geometryDependency?.kind)
    }

    @MainActor
    @Test func intersectionDependencySurvivesSaveReopenAndRecomputesAfterSourceMove() throws {
        let pA = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let pB = MathObject(
            id: UUID(),
            name: "B",
            type: .point,
            expression: MathExpression(displayText: "B=(4,0)"),
            position: WorldPoint(x: 4, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let qA = MathObject(
            id: UUID(),
            name: "C",
            type: .point,
            expression: MathExpression(displayText: "C=(2,-2)"),
            position: WorldPoint(x: 2, y: -2),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "green")
        )
        let qB = MathObject(
            id: UUID(),
            name: "D",
            type: .point,
            expression: MathExpression(displayText: "D=(2,2)"),
            position: WorldPoint(x: 2, y: 2),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "green")
        )
        let l1 = MathObject(
            id: UUID(),
            name: "l1",
            type: .line,
            expression: MathExpression(displayText: "l1"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 4, y: 0)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.object(pA.id), .object(pB.id)]),
            style: MathStyle(colorToken: "blue")
        )
        let l2 = MathObject(
            id: UUID(),
            name: "l2",
            type: .line,
            expression: MathExpression(displayText: "l2"),
            points: [WorldPoint(x: 2, y: -2), WorldPoint(x: 2, y: 2)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.object(qA.id), .object(qB.id)]),
            style: MathStyle(colorToken: "pink")
        )
        let intersection = MathObject(
            id: UUID(),
            name: "I",
            type: .point,
            expression: MathExpression(displayText: "I=(2,0)"),
            position: WorldPoint(x: 2, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .intersectionOf(objectAID: l1.id, objectBID: l2.id, index: 0)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "yellowOrange")
        )
        let state = try reopenedState(
            objects: [pA, pB, qA, qB, l1, l2, intersection],
            title: "intersection-reopen"
        )

        guard let reopenedIntersection = state.document.objects.first(where: { $0.id == intersection.id }) else {
            Issue.record("Missing reopened intersection")
            return
        }
        #expect(reopenedIntersection.geometryDependency?.kind == intersection.geometryDependency?.kind)
        #expect(reopenedIntersection.geometryDefinitionStatus == .defined)
        #expect(reopenedIntersection.position == WorldPoint(x: 2, y: 0))

        state.dispatch(.updateObjectPosition(id: qB.id, position: WorldPoint(x: 4, y: 2)))
        guard let recomputedIntersection = state.document.objects.first(where: { $0.id == intersection.id }) else {
            Issue.record("Missing recomputed intersection")
            return
        }
        #expect(recomputedIntersection.geometryDefinitionStatus == .defined)
        #expect(recomputedIntersection.position == WorldPoint(x: 3, y: 0))

        state.dispatch(.updateObjectPosition(id: pB.id, position: WorldPoint(x: 4, y: 2)))
        guard let movedIntersection = state.document.objects.first(where: { $0.id == intersection.id }) else {
            Issue.record("Missing moved intersection")
            return
        }
        #expect(movedIntersection.geometryDefinitionStatus == .defined)
        #expect(movedIntersection.position == WorldPoint(x: 4, y: 2))
    }

    @MainActor
    @Test func parallelAndPerpendicularDependenciesSurviveSaveReopenAndRecompute() throws {
        let a = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let b = MathObject(
            id: UUID(),
            name: "B",
            type: .point,
            expression: MathExpression(displayText: "B=(4,0)"),
            position: WorldPoint(x: 4, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let through = MathObject(
            id: UUID(),
            name: "P",
            type: .point,
            expression: MathExpression(displayText: "P=(1,2)"),
            position: WorldPoint(x: 1, y: 2),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "green")
        )
        let reference = MathObject(
            id: UUID(),
            name: "s1",
            type: .segment,
            expression: MathExpression(displayText: "s1"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 4, y: 0)],
            geometryDefinition: GeometryDefinition(kind: .segment, anchors: [.object(a.id), .object(b.id)]),
            style: MathStyle(colorToken: "blue")
        )
        let parallel = MathObject(
            id: UUID(),
            name: "p",
            type: .line,
            expression: MathExpression(displayText: "p"),
            points: [WorldPoint(x: 1, y: 2), WorldPoint(x: 5, y: 2)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.object(through.id), .fixedPoint(WorldPoint(x: 5, y: 2))]),
            geometryDependency: GeometryDependency(kind: .parallelLine(referenceObjectID: reference.id, throughPointID: through.id)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "indigo")
        )
        let perpendicular = MathObject(
            id: UUID(),
            name: "q",
            type: .line,
            expression: MathExpression(displayText: "q"),
            points: [WorldPoint(x: 1, y: 2), WorldPoint(x: 1, y: 6)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.object(through.id), .fixedPoint(WorldPoint(x: 1, y: 6))]),
            geometryDependency: GeometryDependency(kind: .perpendicularLine(referenceObjectID: reference.id, throughPointID: through.id)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "cyan")
        )
        let state = try reopenedState(
            objects: [a, b, through, reference, parallel, perpendicular],
            title: "parallel-perpendicular-reopen"
        )

        guard let reopenedParallel = state.document.objects.first(where: { $0.id == parallel.id }),
              let reopenedPerpendicular = state.document.objects.first(where: { $0.id == perpendicular.id }) else {
            Issue.record("Missing reopened derived lines")
            return
        }
        #expect(reopenedParallel.geometryDependency?.kind == parallel.geometryDependency?.kind)
        #expect(reopenedPerpendicular.geometryDependency?.kind == perpendicular.geometryDependency?.kind)

        state.dispatch(.updateObjectPosition(id: through.id, position: WorldPoint(x: 3, y: -1)))

        guard let movedParallel = state.document.objects.first(where: { $0.id == parallel.id }),
              let movedPerpendicular = state.document.objects.first(where: { $0.id == perpendicular.id }),
              let movedParallelPoints = movedParallel.points,
              let movedPerpendicularPoints = movedPerpendicular.points else {
            Issue.record("Missing recomputed derived lines")
            return
        }
        #expect(movedParallelPoints.first == WorldPoint(x: 3, y: -1))
        #expect(movedPerpendicularPoints.first == WorldPoint(x: 3, y: -1))
        #expect(movedParallel.geometryDefinitionStatus == .defined)
        #expect(movedPerpendicular.geometryDefinitionStatus == .defined)
    }

    @MainActor
    @Test func segmentAnchorsSurviveSaveReopenAndResolvedEndpointsTrackSourcePoints() throws {
        let a = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let b = MathObject(
            id: UUID(),
            name: "B",
            type: .point,
            expression: MathExpression(displayText: "B=(4,1)"),
            position: WorldPoint(x: 4, y: 1),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let segment = MathObject(
            id: UUID(),
            name: "s1",
            type: .segment,
            expression: MathExpression(displayText: "s1"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 4, y: 1)],
            geometryDefinition: GeometryDefinition(kind: .segment, anchors: [.object(a.id), .object(b.id)]),
            style: MathStyle(colorToken: "blue")
        )
        let state = try reopenedState(
            objects: [a, b, segment],
            title: "segment-anchor-reopen"
        )

        guard let reopenedSegment = state.document.objects.first(where: { $0.id == segment.id }),
              let anchors = reopenedSegment.geometryDefinition?.anchors else {
            Issue.record("Missing reopened segment")
            return
        }
        #expect(anchors.count == 2)
        #expect(anchors[0].objectID == a.id)
        #expect(anchors[1].objectID == b.id)

        state.dispatch(.updateObjectPosition(id: b.id, position: WorldPoint(x: 6, y: 3)))
        guard let updatedSegment = state.document.objects.first(where: { $0.id == segment.id }),
              let endpoints = PlaneGeometryResolver.segmentEndpoints(for: updatedSegment, in: state.document.objects) else {
            Issue.record("Missing resolved segment endpoints after source move")
            return
        }
        #expect(endpoints.0 == WorldPoint(x: 0, y: 0))
        #expect(endpoints.1 == WorldPoint(x: 6, y: 3))
        #expect(updatedSegment.geometryDependency == nil)
    }

    @MainActor
    @Test func unlinkAfterDeletingSourceSavesAsStaticObjectWithoutDanglingDependency() throws {
        let a = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let b = MathObject(
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
            geometryDependency: GeometryDependency(kind: .midpointOfPoints(pointAID: a.id, pointBID: b.id)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "green")
        )
        let now = Date()
        let document = EMathicaDocument(
            metadata: ProjectMetadata(
                title: "unlink-save-reopen",
                moduleID: "plane",
                createdAt: now,
                updatedAt: now,
                calculatorType: "plane"
            ),
            moduleID: "plane",
            objects: [a, b, midpoint]
        )
        let state = WorkspaceState(
            module: .plane,
            document: document,
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )

        state.dispatch(.deleteObject(id: a.id))
        let reopened = try reopen(state.document)

        #expect(reopened.objects.contains(where: { $0.id == a.id }) == false)
        guard let reopenedMidpoint = reopened.objects.first(where: { $0.id == midpoint.id }) else {
            Issue.record("Missing midpoint after unlink reopen")
            return
        }
        #expect(reopenedMidpoint.geometryDependency == nil)
        #expect(reopenedMidpoint.geometryDefinitionStatus == nil)
        #expect(reopenedMidpoint.position == WorldPoint(x: 1, y: 0))
        #expect(hasDanglingGeometryDependency(in: reopened) == false)

        let reopenedState = WorkspaceState(
            module: .plane,
            document: reopened,
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
        reopenedState.dispatch(.updateObjectPosition(id: b.id, position: WorldPoint(x: 8, y: 0)))
        guard let midpointAfterMove = reopenedState.document.objects.first(where: { $0.id == midpoint.id }) else {
            Issue.record("Missing midpoint after remaining source move")
            return
        }
        #expect(midpointAfterMove.position == WorldPoint(x: 1, y: 0))
    }

    @MainActor
    @Test func deleteAffectedSaveReopenKeepsDeletedObjectsAbsentAndDownstreamStatic() throws {
        let a = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let b = MathObject(
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
            geometryDependency: GeometryDependency(kind: .midpointOfPoints(pointAID: a.id, pointBID: b.id)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "green")
        )
        let downstreamCircle = MathObject(
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
        let now = Date()
        let document = EMathicaDocument(
            metadata: ProjectMetadata(
                title: "delete-affected-save-reopen",
                moduleID: "plane",
                createdAt: now,
                updatedAt: now,
                calculatorType: "plane"
            ),
            moduleID: "plane",
            objects: [a, b, midpoint, downstreamCircle]
        )
        let state = WorkspaceState(
            module: .plane,
            document: document,
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )

        state.requestDeleteObjectsWithConfirmation(Set([a.id]))
        state.confirmPendingDependencyDeletion(strategy: .deleteAffected)
        let reopened = try reopen(state.document)

        #expect(reopened.objects.contains(where: { $0.id == a.id }) == false)
        #expect(reopened.objects.contains(where: { $0.id == midpoint.id }) == false)
        guard let reopenedCircle = reopened.objects.first(where: { $0.id == downstreamCircle.id }) else {
            Issue.record("Missing downstream circle after deleteAffected reopen")
            return
        }
        #expect(reopenedCircle.geometryDependency == nil)
        #expect(reopenedCircle.geometryDefinitionStatus == nil)
        #expect(reopenedCircle.points == downstreamCircle.points)
        #expect(hasDanglingGeometryDependency(in: reopened) == false)
        #expect(ProjectPreviewRenderer.renderPNGData(for: reopened)?.isEmpty == false)
    }

    @MainActor
    private func reopenedState(objects: [MathObject], title: String) throws -> WorkspaceState {
        let now = Date()
        let document = EMathicaDocument(
            metadata: ProjectMetadata(
                title: title,
                moduleID: "plane",
                createdAt: now,
                updatedAt: now,
                calculatorType: "plane"
            ),
            moduleID: "plane",
            objects: objects
        )
        let reopenedDocument = try reopen(document)
        return WorkspaceState(
            module: .plane,
            document: reopenedDocument,
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
    }

    private func reopen(_ document: EMathicaDocument) throws -> EMathicaDocument {
        let data = try EMathicaPackageCodec.makeEncoder().encode(document)
        return try EMathicaPackageCodec.makeDecoder().decode(EMathicaDocument.self, from: data)
    }

    private func hasDanglingGeometryDependency(in document: EMathicaDocument) -> Bool {
        let objectIDs = Set(document.objects.map(\.id))
        return document.objects.contains { object in
            guard let dependency = object.geometryDependency else { return false }
            return referencedObjectIDs(in: dependency).contains { !objectIDs.contains($0) }
        }
    }

    private func referencedObjectIDs(in dependency: GeometryDependency) -> [UUID] {
        switch dependency.kind {
        case .midpointOfPoints(let pointAID, let pointBID):
            return [pointAID, pointBID]
        case .parallelLine(let referenceObjectID, let throughPointID):
            return [referenceObjectID, throughPointID]
        case .perpendicularLine(let referenceObjectID, let throughPointID):
            return [referenceObjectID, throughPointID]
        case .intersectionOf(let objectAID, let objectBID, _):
            return [objectAID, objectBID]
        case .circleByCenterPoint(let centerPointID, let throughPointID):
            return [centerPointID, throughPointID]
        case .circleByCenterRadius(let centerPointID, _):
            return [centerPointID]
        case .arcByThreePoints(let pointAID, let pointBID, let pointCID):
            return [pointAID, pointBID, pointCID]
        }
    }
}
