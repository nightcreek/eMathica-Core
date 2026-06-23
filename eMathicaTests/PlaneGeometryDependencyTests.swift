import Foundation
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct PlaneGeometryDependencyTests {
    @Test func geometryDependencyCodableRoundTripForMidpointOfPoints() throws {
        let dependency = GeometryDependency(
            kind: .midpointOfPoints(pointAID: UUID(), pointBID: UUID())
        )
        let data = try JSONEncoder().encode(dependency)
        let decoded = try JSONDecoder().decode(GeometryDependency.self, from: data)
        #expect(decoded == dependency)
    }

    @Test func geometryDependencyCodableRoundTripForParallelLine() throws {
        let dependency = GeometryDependency(
            kind: .parallelLine(referenceObjectID: UUID(), throughPointID: UUID())
        )
        let data = try JSONEncoder().encode(dependency)
        let decoded = try JSONDecoder().decode(GeometryDependency.self, from: data)
        #expect(decoded == dependency)
    }

    @Test func geometryDependencyCodableRoundTripForPerpendicularLine() throws {
        let dependency = GeometryDependency(
            kind: .perpendicularLine(referenceObjectID: UUID(), throughPointID: UUID())
        )
        let data = try JSONEncoder().encode(dependency)
        let decoded = try JSONDecoder().decode(GeometryDependency.self, from: data)
        #expect(decoded == dependency)
    }

    @Test func geometryDependencyCodableRoundTripForIntersectionOf() throws {
        let dependency = GeometryDependency(
            kind: .intersectionOf(objectAID: UUID(), objectBID: UUID(), index: 0)
        )
        let data = try JSONEncoder().encode(dependency)
        let decoded = try JSONDecoder().decode(GeometryDependency.self, from: data)
        #expect(decoded == dependency)
    }

    @Test func geometryDependencyCodableRoundTripForCircleByCenterPoint() throws {
        let dependency = GeometryDependency(
            kind: .circleByCenterPoint(centerPointID: UUID(), throughPointID: UUID())
        )
        let data = try JSONEncoder().encode(dependency)
        let decoded = try JSONDecoder().decode(GeometryDependency.self, from: data)
        #expect(decoded == dependency)
    }

    @Test func geometryDependencyCodableRoundTripForCircleByCenterRadius() throws {
        let dependency = GeometryDependency(
            kind: .circleByCenterRadius(centerPointID: UUID(), radius: 3.5)
        )
        let data = try JSONEncoder().encode(dependency)
        let decoded = try JSONDecoder().decode(GeometryDependency.self, from: data)
        #expect(decoded == dependency)
    }

    @Test func staticPointRoundTripKeepsNilDependency() throws {
        let point = MathObject(
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let data = try JSONEncoder().encode(point)
        let decoded = try JSONDecoder().decode(MathObject.self, from: data)
        #expect(decoded.geometryDependency == nil)
        #expect(decoded.geometryDefinitionStatus == nil)
    }

    @Test func geometryDefinitionStatusCodableRoundTrip() throws {
        let point = MathObject(
            name: "P",
            type: .point,
            expression: MathExpression(displayText: "P=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .intersectionOf(objectAID: UUID(), objectBID: UUID(), index: 0)),
            geometryDefinitionStatus: .noSolution,
            style: MathStyle(colorToken: "yellowOrange")
        )
        let data = try JSONEncoder().encode(point)
        let decoded = try JSONDecoder().decode(MathObject.self, from: data)
        #expect(decoded.geometryDefinitionStatus == .noSolution)
    }

    @Test func allGeometryDefinitionStatusesCodableRoundTrip() throws {
        let statuses: [GeometryDefinitionStatus] = [.defined, .noSolution, .missingSource, .unsupported, .invalid]
        for status in statuses {
            let data = try JSONEncoder().encode(status)
            let decoded = try JSONDecoder().decode(GeometryDefinitionStatus.self, from: data)
            #expect(decoded == status)
        }
    }

    @Test func dependencyAndStatusRoundTripTogether() throws {
        let object = MathObject(
            name: "L",
            type: .line,
            expression: MathExpression(displayText: "L"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 1, y: 0)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.fixedPoint(WorldPoint(x: 0, y: 0)), .fixedPoint(WorldPoint(x: 1, y: 0))]),
            geometryDependency: GeometryDependency(kind: .parallelLine(referenceObjectID: UUID(), throughPointID: UUID())),
            geometryDefinitionStatus: .missingSource,
            style: MathStyle(colorToken: "indigo")
        )
        let data = try JSONEncoder().encode(object)
        let decoded = try JSONDecoder().decode(MathObject.self, from: data)
        #expect(decoded.geometryDependency == object.geometryDependency)
        #expect(decoded.geometryDefinitionStatus == .missingSource)
    }

    @Test func directlyAffectedQueryFindsDependentsAcrossAllDependencyKinds() throws {
        let source = UUID()
        let other = UUID()
        let objects: [MathObject] = [
            MathObject(name: "m", type: .point, expression: MathExpression(displayText: "m"), geometryDependency: GeometryDependency(kind: .midpointOfPoints(pointAID: source, pointBID: other)), style: MathStyle(colorToken: "green")),
            MathObject(name: "p", type: .line, expression: MathExpression(displayText: "p"), geometryDependency: GeometryDependency(kind: .parallelLine(referenceObjectID: source, throughPointID: other)), style: MathStyle(colorToken: "indigo")),
            MathObject(name: "q", type: .line, expression: MathExpression(displayText: "q"), geometryDependency: GeometryDependency(kind: .perpendicularLine(referenceObjectID: other, throughPointID: source)), style: MathStyle(colorToken: "indigo")),
            MathObject(name: "i", type: .point, expression: MathExpression(displayText: "i"), geometryDependency: GeometryDependency(kind: .intersectionOf(objectAID: source, objectBID: other, index: 0)), style: MathStyle(colorToken: "yellowOrange")),
            MathObject(name: "c1", type: .circle, expression: MathExpression(displayText: "c1"), geometryDependency: GeometryDependency(kind: .circleByCenterPoint(centerPointID: source, throughPointID: other)), style: MathStyle(colorToken: "green")),
            MathObject(name: "c2", type: .circle, expression: MathExpression(displayText: "c2"), geometryDependency: GeometryDependency(kind: .circleByCenterRadius(centerPointID: source, radius: 2)), style: MathStyle(colorToken: "green")),
            MathObject(name: "s", type: .point, expression: MathExpression(displayText: "s"), style: MathStyle(colorToken: "blue"))
        ]

        let affected = PlaneGeometryDependencyRecomputeService.directlyAffectedDerivedObjectIDs(
            objects: objects,
            candidateSourceIDs: [source]
        )

        #expect(affected.count == 6)
        #expect(objects.filter { affected.contains($0.id) }.map(\.name).sorted() == ["c1", "c2", "i", "m", "p", "q"])
    }

    @Test func directlyAffectedQueryExcludesSelectedAndDoesNotRecurseDownstream() throws {
        let sourceID = UUID()
        let directID = UUID()
        let downstreamID = UUID()
        let objects: [MathObject] = [
            MathObject(id: sourceID, name: "A", type: .point, expression: MathExpression(displayText: "A"), style: MathStyle(colorToken: "yellowOrange")),
            MathObject(id: directID, name: "M", type: .point, expression: MathExpression(displayText: "M"), geometryDependency: GeometryDependency(kind: .midpointOfPoints(pointAID: sourceID, pointBID: UUID())), style: MathStyle(colorToken: "green")),
            MathObject(id: downstreamID, name: "C", type: .circle, expression: MathExpression(displayText: "C"), geometryDependency: GeometryDependency(kind: .circleByCenterRadius(centerPointID: directID, radius: 2)), style: MathStyle(colorToken: "green"))
        ]

        let affected = PlaneGeometryDependencyRecomputeService.directlyAffectedDerivedObjectIDs(
            objects: objects,
            candidateSourceIDs: [sourceID]
        )

        #expect(affected == [directID])
    }

    @Test func downstreamAffectedQueryRecursivelyFindsDerivedChain() throws {
        let sourceID = UUID()
        let directID = UUID()
        let downstreamID = UUID()
        let downstream2ID = UUID()
        let objects: [MathObject] = [
            MathObject(id: sourceID, name: "A", type: .point, expression: MathExpression(displayText: "A"), style: MathStyle(colorToken: "yellowOrange")),
            MathObject(id: directID, name: "M", type: .point, expression: MathExpression(displayText: "M"), geometryDependency: GeometryDependency(kind: .midpointOfPoints(pointAID: sourceID, pointBID: UUID())), style: MathStyle(colorToken: "green")),
            MathObject(id: downstreamID, name: "C", type: .circle, expression: MathExpression(displayText: "C"), geometryDependency: GeometryDependency(kind: .circleByCenterRadius(centerPointID: directID, radius: 2)), style: MathStyle(colorToken: "green")),
            MathObject(id: downstream2ID, name: "I", type: .point, expression: MathExpression(displayText: "I"), geometryDependency: GeometryDependency(kind: .intersectionOf(objectAID: downstreamID, objectBID: UUID(), index: 0)), style: MathStyle(colorToken: "yellowOrange"))
        ]

        let affected = PlaneGeometryDependencyRecomputeService.downstreamAffectedDerivedObjectIDs(
            objects: objects,
            candidateSourceIDs: [sourceID]
        )

        #expect(affected == [directID, downstreamID, downstream2ID])
    }

    @Test func midpointRecomputeUpdatesDerivedPointAndPreservesIdentityFields() throws {
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
            geometryDependency: GeometryDependency(kind: .midpointOfPoints(pointAID: pointA.id, pointBID: pointB.id)),
            style: MathStyle(colorToken: "green", opacity: 0.6, lineWidth: 3)
        )

        var objects = [pointA, pointB, midpoint]
        objects[0].position = WorldPoint(x: 2, y: 2)
        let patches = PlaneGeometryDependencyRecomputeService.midpointPatches(
            objects: objects,
            changedSourceIDs: [pointA.id]
        )
        #expect(patches.count == 1)
        guard let firstPatch = patches.first else { return }
        #expect(firstPatch.0 == midpoint.id)
        #expect(firstPatch.1.position == WorldPoint(x: 3, y: 1))
    }

    @Test func midpointRecomputeMissingSourceDoesNotCrashAndProducesNoPatch() throws {
        let pointAID = UUID()
        let pointBID = UUID()
        let midpoint = MathObject(
            id: UUID(),
            name: "M",
            type: .point,
            expression: MathExpression(displayText: "M=(2,0)"),
            position: WorldPoint(x: 2, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .midpointOfPoints(pointAID: pointAID, pointBID: pointBID)),
            style: MathStyle(colorToken: "green")
        )
        let patches = PlaneGeometryDependencyRecomputeService.midpointPatches(
            objects: [midpoint],
            changedSourceIDs: [pointAID]
        )
        #expect(patches.isEmpty)
    }

    @MainActor
    @Test func movingSourcePointRecomputesDynamicMidpointInWorkspaceState() throws {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "dep-recompute",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
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
            style: MathStyle(colorToken: "green")
        )
        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: [pointA, pointB, midpoint]
        )
        let state = WorkspaceState(
            module: .plane,
            document: document,
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )

        state.dispatch(.updateObjectPosition(id: pointA.id, position: WorldPoint(x: 2, y: 2)))

        guard let updatedMidpoint = state.document.objects.first(where: { $0.id == midpoint.id }) else {
            Issue.record("Missing midpoint")
            return
        }
        #expect(updatedMidpoint.position == WorldPoint(x: 2, y: 1))
        #expect(updatedMidpoint.geometryDependency != nil)
    }

    @MainActor
    @Test func draggingStaticPointStillUpdatesPosition() throws {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "static-point-drag",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        let point = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: [point]
        )
        let state = WorkspaceState(
            module: .plane,
            document: document,
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )

        state.dispatch(.updateObjectPosition(id: point.id, position: WorldPoint(x: 3, y: 4)))
        guard let moved = state.document.objects.first(where: { $0.id == point.id }) else {
            Issue.record("Missing point after drag")
            return
        }
        #expect(moved.position == WorldPoint(x: 3, y: 4))
        #expect(moved.geometryDependency == nil)
    }

    @MainActor
    @Test func draggingDynamicMidpointDoesNotClearDependencyAndKeepsFollowingSources() throws {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "dep-drag",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
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
            style: MathStyle(colorToken: "green")
        )
        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: [pointA, pointB, midpoint]
        )
        let state = WorkspaceState(
            module: .plane,
            document: document,
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )

        state.dispatch(.updateObjectPosition(id: midpoint.id, position: WorldPoint(x: 5, y: 5)))
        guard let draggedMidpoint = state.document.objects.first(where: { $0.id == midpoint.id }) else {
            Issue.record("Missing midpoint after drag")
            return
        }
        #expect(draggedMidpoint.geometryDependency != nil)
        #expect(draggedMidpoint.position == WorldPoint(x: 1, y: 0))

        state.dispatch(.updateObjectPosition(id: pointA.id, position: WorldPoint(x: 10, y: 10)))
        guard let midpointAfterSourceMove = state.document.objects.first(where: { $0.id == midpoint.id }) else {
            Issue.record("Missing midpoint after source move")
            return
        }
        #expect(midpointAfterSourceMove.position == WorldPoint(x: 6, y: 5))
        #expect(midpointAfterSourceMove.geometryDependency != nil)
    }

    @MainActor
    @Test func convertObjectToStaticClearsDependencyAndPreservesFields() throws {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "dep-static",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
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
            style: MathStyle(colorToken: "green", opacity: 0.7, lineWidth: 2.5, pointSize: 7),
            isVisible: false
        )
        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: [pointA, pointB, midpoint]
        )
        let state = WorkspaceState(
            module: .plane,
            document: document,
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )

        state.dispatch(.convertObjectToStatic(id: midpoint.id))
        guard let converted = state.document.objects.first(where: { $0.id == midpoint.id }) else {
            Issue.record("Missing midpoint after convert-to-static")
            return
        }
        #expect(converted.geometryDependency == nil)
        #expect(converted.position == WorldPoint(x: 1, y: 0))
        #expect(converted.name == "M")
        #expect(converted.style == midpoint.style)
        #expect(converted.isVisible == midpoint.isVisible)

        state.dispatch(.updateObjectPosition(id: pointA.id, position: WorldPoint(x: 10, y: 10)))
        guard let midpointAfterSourceMove = state.document.objects.first(where: { $0.id == midpoint.id }) else {
            Issue.record("Missing midpoint after source move")
            return
        }
        #expect(midpointAfterSourceMove.position == WorldPoint(x: 1, y: 0))
        #expect(midpointAfterSourceMove.geometryDependency == nil)
    }

    @MainActor
    @Test func convertObjectToStaticOnStaticObjectIsNoOp() throws {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "static-noop",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        let point = MathObject(
            id: UUID(),
            name: "P",
            type: .point,
            expression: MathExpression(displayText: "P=(1,2)"),
            position: WorldPoint(x: 1, y: 2),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "green")
        )
        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: [point]
        )
        let state = WorkspaceState(
            module: .plane,
            document: document,
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )

        state.dispatch(.convertObjectToStatic(id: point.id))
        guard let after = state.document.objects.first(where: { $0.id == point.id }) else {
            Issue.record("Missing point after noop convert")
            return
        }
        #expect(after.position == WorldPoint(x: 1, y: 2))
        #expect(after.geometryDependency == nil)
        #expect(after.name == "P")
        #expect(after.style == point.style)
    }

    @MainActor
    @Test func movingThroughPointRecomputesDynamicParallelLine() throws {
        let state = makeDerivedLineWorkspaceState(mode: .parallel)
        guard let lineID = state.document.objects.first(where: { $0.type == .line })?.id,
              let throughPointID = state.document.objects.first(where: { $0.name == "P" })?.id else {
            Issue.record("Missing line or through point")
            return
        }

        state.dispatch(.updateObjectPosition(id: throughPointID, position: WorldPoint(x: 4, y: 5)))
        guard let updatedLine = state.document.objects.first(where: { $0.id == lineID }),
              let linePoints = updatedLine.points, linePoints.count >= 2 else {
            Issue.record("Missing updated line points")
            return
        }
        #expect(linePoints[0] == WorldPoint(x: 4, y: 5))
        let referenceDirection = WorldPoint(x: 3, y: 1)
        let lineDirection = WorldPoint(x: linePoints[1].x - linePoints[0].x, y: linePoints[1].y - linePoints[0].y)
        #expect(abs(cross(referenceDirection, lineDirection)) < 1e-9)
    }

    @MainActor
    @Test func recomputeDerivedParallelLineKeepsObjectCountAndUsesFixedPointAnchor() throws {
        let state = makeDerivedLineWorkspaceState(mode: .parallel)
        let beforeCount = state.document.objects.count
        guard let lineID = state.document.objects.first(where: { $0.type == .line })?.id,
              let throughPointID = state.document.objects.first(where: { $0.name == "P" })?.id else {
            Issue.record("Missing dynamic parallel setup")
            return
        }

        state.dispatch(.updateObjectPosition(id: throughPointID, position: WorldPoint(x: -3, y: 6)))

        #expect(state.document.objects.count == beforeCount)
        guard let updatedLine = state.document.objects.first(where: { $0.id == lineID }),
              let definition = updatedLine.geometryDefinition,
              let linePoints = updatedLine.points, linePoints.count >= 2 else {
            Issue.record("Missing updated line state")
            return
        }
        #expect(definition.anchors.count == 2)
        #expect(definition.anchors[0].kind == .object)
        #expect(definition.anchors[1].kind == .fixedPoint)
        #expect(definition.anchors[1].point == linePoints[1])
    }

    @MainActor
    @Test func legacyDerivedLineWithObjectSecondAnchorMigratesToFixedPointOnRecompute() throws {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "legacy-derived-line",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
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
            expression: MathExpression(displayText: "B=(3,1)"),
            position: WorldPoint(x: 3, y: 1),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let reference = MathObject(
            id: UUID(),
            name: "s1",
            type: .segment,
            expression: MathExpression(displayText: "s1: 线段"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 3, y: 1)],
            geometryDefinition: GeometryDefinition(kind: .segment, anchors: [.object(pointA.id), .object(pointB.id)]),
            style: MathStyle(colorToken: "blue")
        )
        let throughPoint = MathObject(
            id: UUID(),
            name: "P",
            type: .point,
            expression: MathExpression(displayText: "P=(2,2)"),
            position: WorldPoint(x: 2, y: 2),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let helper = MathObject(
            id: UUID(),
            name: "H",
            type: .point,
            expression: MathExpression(displayText: "H=(5,3)"),
            position: WorldPoint(x: 5, y: 3),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let derivedLine = MathObject(
            id: UUID(),
            name: "ℓ1",
            type: .line,
            expression: MathExpression(displayText: "ℓ1: 直线"),
            points: [throughPoint.position!, helper.position!],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.object(throughPoint.id), .object(helper.id)]),
            geometryDependency: GeometryDependency(kind: .parallelLine(referenceObjectID: reference.id, throughPointID: throughPoint.id)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "indigo")
        )
        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: [pointA, pointB, reference, throughPoint, helper, derivedLine]
        )
        let state = WorkspaceState(
            module: .plane,
            document: document,
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )

        state.dispatch(.updateObjectPosition(id: throughPoint.id, position: WorldPoint(x: 6, y: -1)))

        guard let updatedLine = state.document.objects.first(where: { $0.id == derivedLine.id }),
              let definition = updatedLine.geometryDefinition,
              let linePoints = updatedLine.points, linePoints.count >= 2 else {
            Issue.record("Missing updated legacy derived line")
            return
        }
        #expect(definition.anchors[0].kind == .object)
        #expect(definition.anchors[0].objectID == throughPoint.id)
        #expect(definition.anchors[1].kind == .fixedPoint)
        #expect(definition.anchors[1].point == linePoints[1])

        guard let helperAfter = state.document.objects.first(where: { $0.id == helper.id }) else {
            Issue.record("Missing legacy helper point")
            return
        }
        #expect(helperAfter.position == helper.position)
    }

    @MainActor
    @Test func movingReferenceEndpointRecomputesDynamicPerpendicularLine() throws {
        let state = makeDerivedLineWorkspaceState(mode: .perpendicular)
        guard let lineID = state.document.objects.first(where: { $0.type == .line })?.id,
              let endpointID = state.document.objects.first(where: { $0.name == "B" })?.id else {
            Issue.record("Missing line or endpoint")
            return
        }

        state.dispatch(.updateObjectPosition(id: endpointID, position: WorldPoint(x: 0, y: 4)))
        guard let updatedLine = state.document.objects.first(where: { $0.id == lineID }),
              let linePoints = updatedLine.points, linePoints.count >= 2 else {
            Issue.record("Missing updated line points")
            return
        }
        let referenceDirection = WorldPoint(x: 0, y: 4)
        let lineDirection = WorldPoint(x: linePoints[1].x - linePoints[0].x, y: linePoints[1].y - linePoints[0].y)
        #expect(abs(dot(referenceDirection, lineDirection)) < 1e-9)
    }

    @MainActor
    @Test func convertToStaticStopsDynamicParallelLineRecompute() throws {
        let state = makeDerivedLineWorkspaceState(mode: .parallel)
        guard let line = state.document.objects.first(where: { $0.type == .line }),
              let throughPointID = state.document.objects.first(where: { $0.name == "P" })?.id else {
            Issue.record("Missing line or through point")
            return
        }
        let originalPoints = line.points

        state.dispatch(.convertObjectToStatic(id: line.id))
        state.dispatch(.updateObjectPosition(id: throughPointID, position: WorldPoint(x: 8, y: 8)))

        guard let after = state.document.objects.first(where: { $0.id == line.id }) else {
            Issue.record("Missing line after convert-to-static")
            return
        }
        #expect(after.geometryDependency == nil)
        #expect(after.geometryDefinitionStatus == nil)
        #expect(after.points == originalPoints)
    }

    @MainActor
    @Test func deletingMidpointSourceConvertsDerivedMidpointToStatic() throws {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "dep-delete-midpoint",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
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
            style: MathStyle(colorToken: "green")
        )
        let document = EMathicaDocument(metadata: metadata, moduleID: "plane", objects: [pointA, pointB, midpoint])
        let state = WorkspaceState(
            module: .plane,
            document: document,
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )

        state.dispatch(.deleteObject(id: pointA.id))
        guard let remainingMidpoint = state.document.objects.first(where: { $0.id == midpoint.id }) else {
            Issue.record("Missing midpoint after source deletion")
            return
        }
        #expect(remainingMidpoint.geometryDependency == nil)
        #expect(remainingMidpoint.position == WorldPoint(x: 1, y: 0))

        state.dispatch(.updateObjectPosition(id: pointB.id, position: WorldPoint(x: 10, y: 0)))
        guard let midpointAfterMove = state.document.objects.first(where: { $0.id == midpoint.id }) else {
            Issue.record("Missing midpoint after remaining source move")
            return
        }
        #expect(midpointAfterMove.position == WorldPoint(x: 1, y: 0))
    }

    @MainActor
    @Test func deleteAffectedStrategyDeletesSourceAndDirectDependentsButNotDownstream() throws {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "dep-delete-direct-only",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
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
        let unrelated = MathObject(
            id: UUID(),
            name: "U",
            type: .point,
            expression: MathExpression(displayText: "U=(5,5)"),
            position: WorldPoint(x: 5, y: 5),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "indigo")
        )

        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: [pointA, pointB, midpoint, downstreamCircle, unrelated]
        )
        let state = WorkspaceState(
            module: .plane,
            document: document,
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )

        let affected = state.directlyAffectedDerivedObjectIDs(for: [pointA.id])
        #expect(affected == [midpoint.id])

        state.dispatch(.deleteObjects(ids: [pointA.id, midpoint.id]))

        #expect(state.document.objects.contains(where: { $0.id == pointA.id }) == false)
        #expect(state.document.objects.contains(where: { $0.id == midpoint.id }) == false)
        guard let remainingCircle = state.document.objects.first(where: { $0.id == downstreamCircle.id }) else {
            Issue.record("Downstream circle missing")
            return
        }
        #expect(remainingCircle.geometryDependency == nil)
        #expect(remainingCircle.points == downstreamCircle.points)
        #expect(state.document.objects.contains(where: { $0.id == unrelated.id }))
    }

    @MainActor
    @Test func deleteAffectedConfirmationDeletesDirectDependentsAndStaticizesDownstream() throws {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "dep-delete-confirmation-direct-only",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
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

        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: [pointA, pointB, midpoint, downstreamCircle]
        )
        let state = WorkspaceState(
            module: .plane,
            document: document,
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )

        state.requestDeleteObjectsWithConfirmation(Set([pointA.id]))
        #expect(state.pendingDependencyDeletion?.selectedIDs == Set([pointA.id]))
        #expect(state.pendingDependencyDeletion?.affectedIDs == Set([midpoint.id]))

        state.confirmPendingDependencyDeletion(strategy: .deleteAffected)

        #expect(state.document.objects.contains(where: { $0.id == pointA.id }) == false)
        #expect(state.document.objects.contains(where: { $0.id == midpoint.id }) == false)
        guard let remainingCircle = state.document.objects.first(where: { $0.id == downstreamCircle.id }) else {
            Issue.record("Downstream circle missing after confirmed deleteAffected")
            return
        }
        #expect(remainingCircle.geometryDependency == nil)
        #expect(remainingCircle.geometryDefinitionStatus == nil)
        #expect(remainingCircle.points == downstreamCircle.points)
    }

    @MainActor
    @Test func deletingObjectWithoutAffectedDependentsBehavesAsBefore() throws {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "dep-delete-no-affected",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
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
        let document = EMathicaDocument(metadata: metadata, moduleID: "plane", objects: [pointA, pointB])
        let state = WorkspaceState(
            module: .plane,
            document: document,
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )

        let affected = state.directlyAffectedDerivedObjectIDs(for: [pointA.id])
        #expect(affected.isEmpty)

        state.dispatch(.deleteObject(id: pointA.id))
        #expect(state.document.objects.count == 1)
        #expect(state.document.objects.first?.id == pointB.id)
    }

    @MainActor
    @Test func deletingParallelReferenceConvertsDerivedLineToStatic() throws {
        let state = makeDerivedLineWorkspaceState(mode: .parallel)
        guard let line = state.document.objects.first(where: { $0.type == .line }),
              let reference = state.document.objects.first(where: { $0.type == .segment }) else {
            Issue.record("Missing line/reference")
            return
        }
        let originalPoints = line.points

        state.dispatch(.deleteObject(id: reference.id))
        guard let after = state.document.objects.first(where: { $0.id == line.id }) else {
            Issue.record("Missing line after source deletion")
            return
        }
        #expect(after.geometryDependency == nil)
        #expect(after.points == originalPoints)
    }

    @MainActor
    @Test func deletingPerpendicularThroughPointConvertsDerivedLineToStatic() throws {
        let state = makeDerivedLineWorkspaceState(mode: .perpendicular)
        guard let line = state.document.objects.first(where: { $0.type == .line }),
              let throughPoint = state.document.objects.first(where: { $0.name == "P" }) else {
            Issue.record("Missing line/through point")
            return
        }
        let originalPoints = line.points

        state.dispatch(.deleteObject(id: throughPoint.id))
        guard let after = state.document.objects.first(where: { $0.id == line.id }) else {
            Issue.record("Missing line after through deletion")
            return
        }
        #expect(after.geometryDependency == nil)
        #expect(after.points == originalPoints)
    }

    @MainActor
    @Test func hidingSourcesDoesNotClearDependencies() throws {
        let midpointState = makeMidpointWorkspaceState()
        guard let midpoint = midpointState.document.objects.first(where: { $0.name == "M" }),
              let source = midpointState.document.objects.first(where: { $0.name == "A" }) else {
            Issue.record("Missing midpoint/source")
            return
        }
        midpointState.dispatch(.toggleObjectVisibility(id: source.id))
        guard let midpointAfterHide = midpointState.document.objects.first(where: { $0.id == midpoint.id }) else {
            Issue.record("Missing midpoint after hide")
            return
        }
        #expect(midpointAfterHide.geometryDependency != nil)

        let lineState = makeDerivedLineWorkspaceState(mode: .parallel)
        guard let line = lineState.document.objects.first(where: { $0.type == .line }),
              let reference = lineState.document.objects.first(where: { $0.type == .segment }) else {
            Issue.record("Missing line/reference for hide test")
            return
        }
        lineState.dispatch(.toggleObjectVisibility(id: reference.id))
        guard let lineAfterHide = lineState.document.objects.first(where: { $0.id == line.id }) else {
            Issue.record("Missing line after hide")
            return
        }
        #expect(lineAfterHide.geometryDependency != nil)
    }

    @Test func documentRoundTripPreservesMidpointDependency() throws {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "dep-roundtrip",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
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
            style: MathStyle(colorToken: "green")
        )
        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: [pointA, pointB, midpoint]
        )

        let data = try JSONEncoder().encode(document)
        let decoded = try JSONDecoder().decode(EMathicaDocument.self, from: data)
        guard let decodedMidpoint = decoded.objects.first(where: { $0.id == midpoint.id }) else {
            Issue.record("Missing decoded midpoint")
            return
        }
        #expect(decodedMidpoint.geometryDependency != nil)
    }

    @MainActor
    @Test func movingIntersectionSourcesRecomputesDynamicIntersectionPoint() throws {
        let state = makeDynamicIntersectionWorkspaceState()
        guard let intersectionPoint = state.document.objects.first(where: { $0.name == "P" && $0.type == .point }),
              let sourcePointID = state.document.objects.first(where: { $0.name == "B" })?.id else {
            Issue.record("Missing dynamic intersection setup")
            return
        }
        let originalPosition = intersectionPoint.position
        state.dispatch(.updateObjectPosition(id: sourcePointID, position: WorldPoint(x: 1, y: 2)))

        guard let updated = state.document.objects.first(where: { $0.id == intersectionPoint.id }),
              let updatedPosition = updated.position else {
            Issue.record("Missing updated intersection point")
            return
        }
        #expect(updated.geometryDependency != nil)
        #expect(updatedPosition != originalPosition)
    }

    @MainActor
    @Test func intersectionNoSolutionTransitionKeepsLastPosition() throws {
        let state = makeDynamicIntersectionWorkspaceState()
        guard let intersectionPoint = state.document.objects.first(where: { $0.name == "P" && $0.type == .point }),
              let pointDID = state.document.objects.first(where: { $0.name == "D" })?.id else {
            Issue.record("Missing dynamic intersection setup")
            return
        }
        let original = intersectionPoint.position

        // Move the second line onto a parallel, non-coincident configuration in a single step
        // so the last valid position before `.noSolution` is still the original intersection.
        state.dispatch(.updateObjectPosition(id: pointDID, position: WorldPoint(x: 2, y: 4)))

        guard let afterNoSolution = state.document.objects.first(where: { $0.id == intersectionPoint.id }) else {
            Issue.record("Missing intersection point after no-solution transition")
            return
        }
        #expect(afterNoSolution.geometryDependency != nil)
        #expect(afterNoSolution.position == original)
        #expect(afterNoSolution.geometryDefinitionStatus == .noSolution)
    }

    @MainActor
    @Test func draggingDynamicIntersectionPointIsNoOp() throws {
        let state = makeDynamicIntersectionWorkspaceState()
        guard let intersectionPoint = state.document.objects.first(where: { $0.name == "P" && $0.type == .point }) else {
            Issue.record("Missing dynamic intersection point")
            return
        }
        let original = intersectionPoint.position
        state.dispatch(.updateObjectPosition(id: intersectionPoint.id, position: WorldPoint(x: 99, y: 99)))
        guard let after = state.document.objects.first(where: { $0.id == intersectionPoint.id }) else {
            Issue.record("Missing intersection point after attempted drag")
            return
        }
        #expect(after.geometryDependency != nil)
        #expect(after.position == original)
    }

    @MainActor
    @Test func convertToStaticStopsDynamicIntersectionRecompute() throws {
        let state = makeDynamicIntersectionWorkspaceState()
        guard let intersectionPoint = state.document.objects.first(where: { $0.name == "P" && $0.type == .point }),
              let sourcePointID = state.document.objects.first(where: { $0.name == "B" })?.id else {
            Issue.record("Missing dynamic intersection setup")
            return
        }
        let frozenPosition = intersectionPoint.position

        state.dispatch(.convertObjectToStatic(id: intersectionPoint.id))
        state.dispatch(.updateObjectPosition(id: sourcePointID, position: WorldPoint(x: 2, y: 3)))

        guard let after = state.document.objects.first(where: { $0.id == intersectionPoint.id }) else {
            Issue.record("Missing intersection point after convert-to-static")
            return
        }
        #expect(after.geometryDependency == nil)
        #expect(after.geometryDefinitionStatus == nil)
        #expect(after.position == frozenPosition)
    }

    @MainActor
    @Test func convertToStaticStopsDynamicPerpendicularLineRecompute() throws {
        let state = makeDerivedLineWorkspaceState(mode: .perpendicular)
        guard let line = state.document.objects.first(where: { $0.type == .line && $0.geometryDependency != nil }),
              let throughPointID = state.document.objects.first(where: { $0.name == "P" })?.id else {
            Issue.record("Missing dynamic perpendicular setup")
            return
        }
        let frozen = line.points
        state.dispatch(.convertObjectToStatic(id: line.id))
        state.dispatch(.updateObjectPosition(id: throughPointID, position: WorldPoint(x: 7, y: 7)))
        guard let after = state.document.objects.first(where: { $0.id == line.id }) else {
            Issue.record("Missing perpendicular line after convert-to-static")
            return
        }
        #expect(after.geometryDependency == nil)
        #expect(after.geometryDefinitionStatus == nil)
        #expect(after.points == frozen)
    }

    @MainActor
    @Test func deletingIntersectionSourceConvertsDerivedIntersectionToStatic() throws {
        let state = makeDynamicIntersectionWorkspaceState()
        guard let sourceLine = state.document.objects.first(where: { $0.name == "l2" && $0.type == .line }),
              let intersectionPoint = state.document.objects.first(where: { $0.name == "P" && $0.type == .point }) else {
            Issue.record("Missing dynamic intersection setup")
            return
        }
        let original = intersectionPoint.position

        state.dispatch(.deleteObject(id: sourceLine.id))
        guard let afterDelete = state.document.objects.first(where: { $0.id == intersectionPoint.id }) else {
            Issue.record("Missing intersection point after source deletion")
            return
        }
        #expect(afterDelete.geometryDependency == nil)
        #expect(afterDelete.geometryDefinitionStatus == nil)
        #expect(afterDelete.position == original)
    }

    @MainActor
    @Test func movingCircleSourcesRecomputesDynamicCirclePoints() throws {
        let state = makeDynamicCircleWorkspaceState()
        guard let centerPointID = state.document.objects.first(where: { $0.name == "C" })?.id,
              let circleID = state.document.objects.first(where: { $0.type == .circle })?.id else {
            Issue.record("Missing dynamic circle setup")
            return
        }
        state.dispatch(.updateObjectPosition(id: centerPointID, position: WorldPoint(x: 2, y: 2)))
        guard let circle = state.document.objects.first(where: { $0.id == circleID }),
              let points = circle.points, points.count >= 2 else {
            Issue.record("Missing updated circle")
            return
        }
        #expect(circle.geometryDependency != nil)
        #expect(circle.geometryDefinitionStatus == .defined)
        #expect(points[0] == WorldPoint(x: 2, y: 2))
    }

    @MainActor
    @Test func deletingCircleSourceConvertsCircleToStatic() throws {
        let state = makeDynamicCircleWorkspaceState()
        guard let throughPointID = state.document.objects.first(where: { $0.name == "T" })?.id,
              let circleID = state.document.objects.first(where: { $0.type == .circle })?.id else {
            Issue.record("Missing dynamic circle setup")
            return
        }
        let originalPoints = state.document.objects.first(where: { $0.id == circleID })?.points
        state.dispatch(.deleteObject(id: throughPointID))
        guard let circle = state.document.objects.first(where: { $0.id == circleID }) else {
            Issue.record("Missing circle after deletion")
            return
        }
        #expect(circle.geometryDependency == nil)
        #expect(circle.geometryDefinitionStatus == nil)
        #expect(circle.points == originalPoints)
    }

    @MainActor
    @Test func movingCenterRecomputesCenterRadiusDynamicCircleAndPreservesRadius() throws {
        let state = makeDynamicCircleByRadiusWorkspaceState()
        guard let centerID = state.document.objects.first(where: { $0.name == "C" })?.id,
              let circleID = state.document.objects.first(where: { $0.type == .circle })?.id,
              let beforeCircle = state.document.objects.first(where: { $0.id == circleID }),
              let beforePoints = beforeCircle.points, beforePoints.count >= 2 else {
            Issue.record("Missing center-radius setup")
            return
        }

        let beforeRadius = hypot(beforePoints[1].x - beforePoints[0].x, beforePoints[1].y - beforePoints[0].y)
        state.dispatch(.updateObjectPosition(id: centerID, position: WorldPoint(x: 5, y: -2)))

        guard let afterCircle = state.document.objects.first(where: { $0.id == circleID }),
              let afterPoints = afterCircle.points, afterPoints.count >= 2 else {
            Issue.record("Missing updated center-radius circle")
            return
        }
        let afterRadius = hypot(afterPoints[1].x - afterPoints[0].x, afterPoints[1].y - afterPoints[0].y)
        #expect(afterPoints[0] == WorldPoint(x: 5, y: -2))
        #expect(abs(afterRadius - beforeRadius) < 1e-9)
        #expect(afterCircle.geometryDefinitionStatus == .defined)
    }

    @MainActor
    @Test func deletingCenterConvertsCenterRadiusDynamicCircleToStatic() throws {
        let state = makeDynamicCircleByRadiusWorkspaceState()
        guard let centerID = state.document.objects.first(where: { $0.name == "C" })?.id,
              let circleID = state.document.objects.first(where: { $0.type == .circle })?.id else {
            Issue.record("Missing center-radius setup")
            return
        }
        let originalPoints = state.document.objects.first(where: { $0.id == circleID })?.points
        state.dispatch(.deleteObject(id: centerID))
        guard let circle = state.document.objects.first(where: { $0.id == circleID }) else {
            Issue.record("Missing circle after center deletion")
            return
        }
        #expect(circle.geometryDependency == nil)
        #expect(circle.geometryDefinitionStatus == nil)
        #expect(circle.points == originalPoints)
    }

    @MainActor
    @Test func convertToStaticStopsCenterRadiusCircleRecompute() throws {
        let state = makeDynamicCircleByRadiusWorkspaceState()
        guard let centerID = state.document.objects.first(where: { $0.name == "C" })?.id,
              let circle = state.document.objects.first(where: { $0.type == .circle }) else {
            Issue.record("Missing center-radius setup")
            return
        }
        let frozenPoints = circle.points
        state.dispatch(.convertObjectToStatic(id: circle.id))
        state.dispatch(.updateObjectPosition(id: centerID, position: WorldPoint(x: 9, y: 9)))
        guard let after = state.document.objects.first(where: { $0.id == circle.id }) else {
            Issue.record("Missing circle after convert-to-static")
            return
        }
        #expect(after.geometryDependency == nil)
        #expect(after.geometryDefinitionStatus == nil)
        #expect(after.points == frozenPoints)
    }

    @MainActor
    @Test func movingCenterRecomputesLineCircleIntersectionsForCenterRadiusCircle() throws {
        let state = makeDynamicLineCircleIntersectionByRadiusWorkspaceState()
        guard let centerID = state.document.objects.first(where: { $0.name == "C" })?.id else {
            Issue.record("Missing center for center-radius line-circle setup")
            return
        }
        let before = state.document.objects.filter { $0.name.hasPrefix("I") }.compactMap(\.position)
        state.dispatch(.updateObjectPosition(id: centerID, position: WorldPoint(x: 1, y: 0)))
        let after = state.document.objects.filter { $0.name.hasPrefix("I") }.compactMap(\.position)
        #expect(before != after)
    }

    @Test func dependencyPresentationProvidesSourceTexts() {
        let a = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let b = MathObject(
            id: UUID(),
            name: "B",
            type: .point,
            expression: MathExpression(displayText: "B"),
            position: WorldPoint(x: 1, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let m = MathObject(
            id: UUID(),
            name: "M",
            type: .point,
            expression: MathExpression(displayText: "M"),
            position: WorldPoint(x: 0.5, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .midpointOfPoints(pointAID: a.id, pointBID: b.id)),
            style: MathStyle(colorToken: "green")
        )
        let text = GeometryDependencyPresentation.sourceText(for: m, objects: [a, b, m])
        #expect(text == "中点：A，B")
    }

    @Test func dependencyPresentationCoversAllKinds() {
        let a = MathObject(id: UUID(), name: "A", type: .point, expression: MathExpression(displayText: "A"), position: .zero, geometryDefinition: GeometryDefinition(kind: .point, anchors: []), style: MathStyle(colorToken: "yellowOrange"))
        let b = MathObject(id: UUID(), name: "B", type: .point, expression: MathExpression(displayText: "B"), position: WorldPoint(x: 1, y: 0), geometryDefinition: GeometryDefinition(kind: .point, anchors: []), style: MathStyle(colorToken: "purple"))
        let l = MathObject(id: UUID(), name: "l1", type: .line, expression: MathExpression(displayText: "l1"), points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 1, y: 0)], geometryDefinition: GeometryDefinition(kind: .line, anchors: [.object(a.id), .object(b.id)]), style: MathStyle(colorToken: "indigo"))
        let c = MathObject(id: UUID(), name: "c1", type: .circle, expression: MathExpression(displayText: "c1"), points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 1, y: 0)], geometryDefinition: GeometryDefinition(kind: .circle, anchors: [.object(a.id), .object(b.id)]), style: MathStyle(colorToken: "green"))
        let midpoint = MathObject(name: "M", type: .point, expression: MathExpression(displayText: "M"), position: .zero, geometryDefinition: GeometryDefinition(kind: .point, anchors: []), geometryDependency: GeometryDependency(kind: .midpointOfPoints(pointAID: a.id, pointBID: b.id)), style: MathStyle(colorToken: "green"))
        let parallel = MathObject(name: "p", type: .line, expression: MathExpression(displayText: "p"), points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 1, y: 0)], geometryDefinition: GeometryDefinition(kind: .line, anchors: [.object(a.id), .object(b.id)]), geometryDependency: GeometryDependency(kind: .parallelLine(referenceObjectID: l.id, throughPointID: a.id)), style: MathStyle(colorToken: "indigo"))
        let perpendicular = MathObject(name: "q", type: .line, expression: MathExpression(displayText: "q"), points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 0, y: 1)], geometryDefinition: GeometryDefinition(kind: .line, anchors: [.object(a.id), .object(b.id)]), geometryDependency: GeometryDependency(kind: .perpendicularLine(referenceObjectID: l.id, throughPointID: a.id)), style: MathStyle(colorToken: "indigo"))
        let circle = MathObject(name: "cc", type: .circle, expression: MathExpression(displayText: "cc"), points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 1, y: 0)], geometryDefinition: GeometryDefinition(kind: .circle, anchors: [.object(a.id), .object(b.id)]), geometryDependency: GeometryDependency(kind: .circleByCenterPoint(centerPointID: a.id, throughPointID: b.id)), style: MathStyle(colorToken: "green"))
        let circleByRadius = MathObject(name: "cr", type: .circle, expression: MathExpression(displayText: "cr"), points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 2, y: 0)], geometryDefinition: GeometryDefinition(kind: .circle, anchors: [.object(a.id), .fixedPoint(WorldPoint(x: 2, y: 0))]), geometryDependency: GeometryDependency(kind: .circleByCenterRadius(centerPointID: a.id, radius: 2)), style: MathStyle(colorToken: "green"))
        let intersection = MathObject(name: "I", type: .point, expression: MathExpression(displayText: "I"), position: .zero, geometryDefinition: GeometryDefinition(kind: .point, anchors: []), geometryDependency: GeometryDependency(kind: .intersectionOf(objectAID: l.id, objectBID: c.id, index: 0)), style: MathStyle(colorToken: "yellowOrange"))
        let objects = [a, b, l, c, midpoint, parallel, perpendicular, circle, circleByRadius, intersection]
        #expect(GeometryDependencyPresentation.sourceText(for: midpoint, objects: objects) != nil)
        #expect(GeometryDependencyPresentation.sourceText(for: parallel, objects: objects) != nil)
        #expect(GeometryDependencyPresentation.sourceText(for: perpendicular, objects: objects) != nil)
        #expect(GeometryDependencyPresentation.sourceText(for: circle, objects: objects) != nil)
        #expect(GeometryDependencyPresentation.sourceText(for: circleByRadius, objects: objects) != nil)
        #expect(GeometryDependencyPresentation.sourceText(for: intersection, objects: objects) != nil)
    }

    @Test func dependencyPresentationProvidesStatusText() {
        let point = MathObject(
            id: UUID(),
            name: "I",
            type: .point,
            expression: MathExpression(displayText: "I"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .intersectionOf(objectAID: UUID(), objectBID: UUID(), index: 0)),
            geometryDefinitionStatus: .noSolution,
            style: MathStyle(colorToken: "yellowOrange")
        )
        #expect(GeometryDependencyPresentation.statusText(for: point) == "状态：当前无交点")
    }

    @Test func dependencySecondaryLinesForMidpointKeepSource() {
        let a = MathObject(id: UUID(), name: "A", type: .point, expression: MathExpression(displayText: "A"), position: .zero, geometryDefinition: GeometryDefinition(kind: .point, anchors: []), style: MathStyle(colorToken: "yellowOrange"))
        let b = MathObject(id: UUID(), name: "B", type: .point, expression: MathExpression(displayText: "B"), position: WorldPoint(x: 2, y: 0), geometryDefinition: GeometryDefinition(kind: .point, anchors: []), style: MathStyle(colorToken: "purple"))
        let midpoint = MathObject(
            id: UUID(),
            name: "M",
            type: .point,
            expression: MathExpression(displayText: "M"),
            position: WorldPoint(x: 1, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .midpointOfPoints(pointAID: a.id, pointBID: b.id)),
            style: MathStyle(colorToken: "green")
        )
        let lines = secondaryLines(
            for: midpoint,
            objects: [a, b, midpoint],
            simplifiedText: nil,
            metadataText: "point",
            typeFallback: midpoint.type.rawValue
        )
        #expect(lines.first == "中点：A，B")
    }

    @Test func dependencySecondaryLinesForCircleByRadiusKeepSource() {
        let center = MathObject(id: UUID(), name: "C", type: .point, expression: MathExpression(displayText: "C"), position: .zero, geometryDefinition: GeometryDefinition(kind: .point, anchors: []), style: MathStyle(colorToken: "green"))
        let circle = MathObject(
            id: UUID(),
            name: "c",
            type: .circle,
            expression: MathExpression(displayText: "c"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 2, y: 0)],
            geometryDefinition: GeometryDefinition(kind: .circle, anchors: [.object(center.id), .fixedPoint(WorldPoint(x: 2, y: 0))]),
            geometryDependency: GeometryDependency(kind: .circleByCenterRadius(centerPointID: center.id, radius: 2)),
            style: MathStyle(colorToken: "green")
        )
        let lines = secondaryLines(
            for: circle,
            objects: [center, circle],
            simplifiedText: nil,
            metadataText: nil,
            typeFallback: circle.type.rawValue
        )
        #expect(lines.first == "圆：圆心 C，半径 2.00")
    }

    @Test func dependencySecondaryLinesForNoSolutionKeepSourceAndStatus() {
        let l = MathObject(id: UUID(), name: "l", type: .line, expression: MathExpression(displayText: "l"), points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 1, y: 0)], geometryDefinition: GeometryDefinition(kind: .line, anchors: [.fixedPoint(WorldPoint(x: 0, y: 0)), .fixedPoint(WorldPoint(x: 1, y: 0))]), style: MathStyle(colorToken: "indigo"))
        let c = MathObject(id: UUID(), name: "c", type: .circle, expression: MathExpression(displayText: "c"), points: [WorldPoint(x: 0, y: 2), WorldPoint(x: 1, y: 2)], geometryDefinition: GeometryDefinition(kind: .circle, anchors: [.fixedPoint(WorldPoint(x: 0, y: 2)), .fixedPoint(WorldPoint(x: 1, y: 2))]), style: MathStyle(colorToken: "green"))
        let i = MathObject(
            id: UUID(),
            name: "I",
            type: .point,
            expression: MathExpression(displayText: "I"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .intersectionOf(objectAID: l.id, objectBID: c.id, index: 0)),
            geometryDefinitionStatus: .noSolution,
            style: MathStyle(colorToken: "yellowOrange")
        )
        let lines = secondaryLines(
            for: i,
            objects: [l, c, i],
            simplifiedText: "x=1",
            metadataText: "metadata",
            typeFallback: i.type.rawValue
        )
        #expect(lines.count >= 2)
        #expect(lines[0] == "交点：l × c")
        #expect(lines[1] == "状态：当前无交点")
    }

    @Test func dependencySecondaryLinesWithStatusSuppressMetadataFallback() {
        let sourceA = MathObject(id: UUID(), name: "A", type: .point, expression: MathExpression(displayText: "A"), position: .zero, geometryDefinition: GeometryDefinition(kind: .point, anchors: []), style: MathStyle(colorToken: "yellowOrange"))
        let sourceB = MathObject(id: UUID(), name: "B", type: .point, expression: MathExpression(displayText: "B"), position: WorldPoint(x: 1, y: 0), geometryDefinition: GeometryDefinition(kind: .point, anchors: []), style: MathStyle(colorToken: "purple"))
        let derived = MathObject(
            id: UUID(),
            name: "M",
            type: .point,
            expression: MathExpression(displayText: "M"),
            position: WorldPoint(x: 0.5, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .midpointOfPoints(pointAID: sourceA.id, pointBID: sourceB.id)),
            geometryDefinitionStatus: .missingSource,
            style: MathStyle(colorToken: "green")
        )
        let lines = secondaryLines(
            for: derived,
            objects: [sourceA, sourceB, derived],
            simplifiedText: nil,
            metadataText: "point",
            typeFallback: derived.type.rawValue
        )
        #expect(lines.contains("状态：源对象缺失"))
        #expect(lines.contains("point") == false)
        #expect(lines.contains(derived.type.rawValue) == false)
    }

    @Test func nonDerivedSecondaryLinesKeepExistingSimplifiedPriority() {
        let function = MathObject(
            id: UUID(),
            name: "f",
            type: .function,
            expression: MathExpression(displayText: "y=x", simplifiedDisplayText: "x"),
            style: MathStyle(colorToken: "blue")
        )
        let lines = secondaryLines(
            for: function,
            objects: [function],
            simplifiedText: "x",
            metadataText: "显函数",
            typeFallback: function.type.rawValue
        )
        #expect(lines == ["化简：x"])
    }

    @Test func staticSegmentSecondaryTextIncludesLengthProperty() {
        let a = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let b = MathObject(
            id: UUID(),
            name: "B",
            type: .point,
            expression: MathExpression(displayText: "B"),
            position: WorldPoint(x: 3, y: 4),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let segment = MathObject(
            id: UUID(),
            name: "s",
            type: .segment,
            expression: MathExpression(displayText: "s"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 3, y: 4)],
            geometryDefinition: GeometryDefinition(kind: .segment, anchors: [.object(a.id), .object(b.id)]),
            style: MathStyle(colorToken: "indigo")
        )

        let lines = secondaryLines(
            for: segment,
            objects: [a, b, segment],
            simplifiedText: nil,
            metadataText: nil,
            typeFallback: segment.type.rawValue
        )
        #expect(lines == ["长度 5.00"])
    }

    @Test func staticCircleSecondaryTextIncludesRadiusProperty() {
        let center = MathObject(
            id: UUID(),
            name: "C",
            type: .point,
            expression: MathExpression(displayText: "C"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "green")
        )
        let through = MathObject(
            id: UUID(),
            name: "T",
            type: .point,
            expression: MathExpression(displayText: "T"),
            position: WorldPoint(x: 0, y: 2),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "green")
        )
        let circle = MathObject(
            id: UUID(),
            name: "c",
            type: .circle,
            expression: MathExpression(displayText: "c"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 0, y: 2)],
            geometryDefinition: GeometryDefinition(kind: .circle, anchors: [.object(center.id), .object(through.id)]),
            style: MathStyle(colorToken: "green")
        )
        let lines = secondaryLines(
            for: circle,
            objects: [center, through, circle],
            simplifiedText: nil,
            metadataText: nil,
            typeFallback: circle.type.rawValue
        )
        #expect(lines == ["半径 2.00"])
    }

    @Test func nonDefinedCircleSkipsRadiusProperty() {
        let center = MathObject(
            id: UUID(),
            name: "C",
            type: .point,
            expression: MathExpression(displayText: "C"),
            position: .zero,
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "green")
        )
        let circle = MathObject(
            id: UUID(),
            name: "c",
            type: .circle,
            expression: MathExpression(displayText: "c"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 2, y: 0)],
            geometryDefinition: GeometryDefinition(kind: .circle, anchors: [.object(center.id), .fixedPoint(WorldPoint(x: 2, y: 0))]),
            geometryDependency: GeometryDependency(kind: .circleByCenterRadius(centerPointID: center.id, radius: 2)),
            geometryDefinitionStatus: .missingSource,
            style: MathStyle(colorToken: "green")
        )
        let lines = secondaryLines(
            for: circle,
            objects: [center, circle],
            simplifiedText: nil,
            metadataText: "circle",
            typeFallback: circle.type.rawValue
        )
        #expect(lines.contains { $0.hasPrefix("半径 ") } == false)
        #expect(lines.contains("状态：源对象缺失"))
    }

    @Test func noSolutionIntersectionSecondaryTextDoesNotShowProperty() {
        let lineA = MathObject(
            id: UUID(),
            name: "l1",
            type: .line,
            expression: MathExpression(displayText: "l1"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 1, y: 0)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.fixedPoint(WorldPoint(x: 0, y: 0)), .fixedPoint(WorldPoint(x: 1, y: 0))]),
            style: MathStyle(colorToken: "indigo")
        )
        let lineB = MathObject(
            id: UUID(),
            name: "l2",
            type: .line,
            expression: MathExpression(displayText: "l2"),
            points: [WorldPoint(x: 0, y: 1), WorldPoint(x: 1, y: 1)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.fixedPoint(WorldPoint(x: 0, y: 1)), .fixedPoint(WorldPoint(x: 1, y: 1))]),
            style: MathStyle(colorToken: "purple")
        )
        let intersection = MathObject(
            id: UUID(),
            name: "I",
            type: .point,
            expression: MathExpression(displayText: "I"),
            position: .zero,
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .intersectionOf(objectAID: lineA.id, objectBID: lineB.id, index: 0)),
            geometryDefinitionStatus: .noSolution,
            style: MathStyle(colorToken: "yellowOrange")
        )
        let lines = secondaryLines(
            for: intersection,
            objects: [lineA, lineB, intersection],
            simplifiedText: nil,
            metadataText: nil,
            typeFallback: intersection.type.rawValue
        )
        #expect(lines == ["交点：l1 × l2", "状态：当前无交点"])
    }

    @Test func inspectorPointPropertiesIncludeCoordinate() {
        let point = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A"),
            position: WorldPoint(x: 1.25, y: -2.5),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let rows = inspectorRows(for: point, objects: [point])
        #expect(rows.contains { $0.label == "坐标" && $0.value == "(1.25, -2.50)" })
    }

    @Test func inspectorSegmentPropertiesIncludeEndpointsLengthAndAngle() {
        let a = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let b = MathObject(
            id: UUID(),
            name: "B",
            type: .point,
            expression: MathExpression(displayText: "B"),
            position: WorldPoint(x: 3, y: 4),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let segment = MathObject(
            id: UUID(),
            name: "s",
            type: .segment,
            expression: MathExpression(displayText: "s"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 3, y: 4)],
            geometryDefinition: GeometryDefinition(kind: .segment, anchors: [.object(a.id), .object(b.id)]),
            style: MathStyle(colorToken: "indigo")
        )
        let rows = inspectorRows(for: segment, objects: [a, b, segment])
        #expect(rows.contains { $0.label == "端点 A" && $0.value.contains("A") })
        #expect(rows.contains { $0.label == "端点 B" && $0.value.contains("B") })
        #expect(rows.contains { $0.label == "长度" && $0.value == "5.00" })
        #expect(rows.contains { $0.label == "方向角" && $0.value.hasSuffix("°") })
    }

    @Test func inspectorCirclePropertiesIncludeCenterRadiusAndDiameter() {
        let center = MathObject(
            id: UUID(),
            name: "C",
            type: .point,
            expression: MathExpression(displayText: "C"),
            position: WorldPoint(x: 1, y: 1),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "green")
        )
        let circle = MathObject(
            id: UUID(),
            name: "c",
            type: .circle,
            expression: MathExpression(displayText: "c"),
            points: [WorldPoint(x: 1, y: 1), WorldPoint(x: 3, y: 1)],
            geometryDefinition: GeometryDefinition(kind: .circle, anchors: [.object(center.id), .fixedPoint(WorldPoint(x: 3, y: 1))]),
            geometryDependency: GeometryDependency(kind: .circleByCenterRadius(centerPointID: center.id, radius: 2)),
            style: MathStyle(colorToken: "green")
        )
        let rows = inspectorRows(for: circle, objects: [center, circle])
        #expect(rows.contains { $0.label == "来源对象" && $0.value.contains("圆心 C") })
        #expect(rows.contains { $0.label == "圆心" && $0.value.contains("C") })
        #expect(rows.contains { $0.label == "半径" && $0.value == "2.00" })
        #expect(rows.contains { $0.label == "直径" && $0.value == "4.00" })
    }

    @Test func inspectorCircleByCenterPointSourceTextIsCorrect() {
        let center = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "green")
        )
        let through = MathObject(
            id: UUID(),
            name: "B",
            type: .point,
            expression: MathExpression(displayText: "B"),
            position: WorldPoint(x: 0, y: 2),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "green")
        )
        let circle = MathObject(
            id: UUID(),
            name: "c",
            type: .circle,
            expression: MathExpression(displayText: "c"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 0, y: 2)],
            geometryDefinition: GeometryDefinition(kind: .circle, anchors: [.object(center.id), .object(through.id)]),
            geometryDependency: GeometryDependency(kind: .circleByCenterPoint(centerPointID: center.id, throughPointID: through.id)),
            style: MathStyle(colorToken: "green")
        )
        let rows = inspectorRows(for: circle, objects: [center, through, circle])
        #expect(rows.contains { $0.label == "来源对象" && $0.value == "圆：圆心 A，过 B" })
    }

    @Test func inspectorNonDefinedDerivedObjectShowsStatusWithoutGeometryValues() {
        let center = MathObject(
            id: UUID(),
            name: "C",
            type: .point,
            expression: MathExpression(displayText: "C"),
            position: .zero,
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "green")
        )
        let circle = MathObject(
            id: UUID(),
            name: "c",
            type: .circle,
            expression: MathExpression(displayText: "c"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 2, y: 0)],
            geometryDefinition: GeometryDefinition(kind: .circle, anchors: [.object(center.id), .fixedPoint(WorldPoint(x: 2, y: 0))]),
            geometryDependency: GeometryDependency(kind: .circleByCenterRadius(centerPointID: center.id, radius: 2)),
            geometryDefinitionStatus: .noSolution,
            style: MathStyle(colorToken: "green")
        )
        let rows = inspectorRows(for: circle, objects: [center, circle])
        #expect(rows.contains { $0.label == "定义状态" && $0.value == "当前无交点" })
        #expect(rows.contains { $0.label == "半径" } == false)
        #expect(rows.contains { $0.label == "直径" } == false)
        #expect(rows.contains { $0.label == "圆心" } == false)
    }

    @Test func inspectorLinePropertiesIncludeDirectionVectorSlopeAndAngle() {
        let a = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A"),
            position: WorldPoint(x: 1, y: 2),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let b = MathObject(
            id: UUID(),
            name: "B",
            type: .point,
            expression: MathExpression(displayText: "B"),
            position: WorldPoint(x: 4, y: 8),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let line = MathObject(
            id: UUID(),
            name: "l",
            type: .line,
            expression: MathExpression(displayText: "l"),
            points: [a.position!, b.position!],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.object(a.id), .object(b.id)]),
            style: MathStyle(colorToken: "indigo")
        )
        let rows = inspectorRows(for: line, objects: [a, b, line])
        #expect(rows.contains { $0.label == "过点" && $0.value.contains("A") })
        #expect(rows.contains { $0.label == "方向向量" && $0.value == "(3.00, 6.00)" })
        #expect(rows.contains { $0.label == "斜率" && $0.value == "2.00" })
        #expect(rows.contains { $0.label == "方向角" && $0.value.hasSuffix("°") })
    }

    @Test func inspectorVerticalLineSlopeDisplaysVerticalMarker() {
        let line = MathObject(
            id: UUID(),
            name: "v",
            type: .line,
            expression: MathExpression(displayText: "v"),
            points: [WorldPoint(x: 2, y: 1), WorldPoint(x: 2, y: 5)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.fixedPoint(WorldPoint(x: 2, y: 1)), .fixedPoint(WorldPoint(x: 2, y: 5))]),
            style: MathStyle(colorToken: "indigo")
        )
        let rows = inspectorRows(for: line, objects: [line])
        #expect(rows.contains { $0.label == "斜率" && $0.value == "垂直" })
    }

    @Test func inspectorRayPropertiesIncludeStartDirectionAndAngle() {
        let start = MathObject(
            id: UUID(),
            name: "P",
            type: .point,
            expression: MathExpression(displayText: "P"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let through = MathObject(
            id: UUID(),
            name: "Q",
            type: .point,
            expression: MathExpression(displayText: "Q"),
            position: WorldPoint(x: 2, y: 2),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let ray = MathObject(
            id: UUID(),
            name: "r",
            type: .ray,
            expression: MathExpression(displayText: "r"),
            points: [start.position!, through.position!],
            geometryDefinition: GeometryDefinition(kind: .ray, anchors: [.object(start.id), .object(through.id)]),
            style: MathStyle(colorToken: "indigo")
        )
        let rows = inspectorRows(for: ray, objects: [start, through, ray])
        #expect(rows.contains { $0.label == "起点" && $0.value.contains("P") })
        #expect(rows.contains { $0.label == "方向向量" && $0.value == "(2.00, 2.00)" })
        #expect(rows.contains { $0.label == "方向角" && $0.value.hasSuffix("°") })
    }

    @Test func inspectorIntersectionPropertiesIncludeSourceIndexAndCoordinateWhenDefined() {
        let line = MathObject(
            id: UUID(),
            name: "l",
            type: .line,
            expression: MathExpression(displayText: "l"),
            points: [WorldPoint(x: -1, y: 0), WorldPoint(x: 1, y: 0)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.fixedPoint(WorldPoint(x: -1, y: 0)), .fixedPoint(WorldPoint(x: 1, y: 0))]),
            style: MathStyle(colorToken: "indigo")
        )
        let circle = MathObject(
            id: UUID(),
            name: "c",
            type: .circle,
            expression: MathExpression(displayText: "c"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 1, y: 0)],
            geometryDefinition: GeometryDefinition(kind: .circle, anchors: [.fixedPoint(WorldPoint(x: 0, y: 0)), .fixedPoint(WorldPoint(x: 1, y: 0))]),
            style: MathStyle(colorToken: "green")
        )
        let intersection = MathObject(
            id: UUID(),
            name: "I1",
            type: .point,
            expression: MathExpression(displayText: "I1"),
            position: WorldPoint(x: 1, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .intersectionOf(objectAID: line.id, objectBID: circle.id, index: 1)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "yellowOrange")
        )
        let rows = inspectorRows(for: intersection, objects: [line, circle, intersection])
        #expect(rows.contains { $0.label == "构造关系" && $0.value == "交点" })
        #expect(rows.contains { $0.label == "来源对象" && $0.value == "交点：l × c" })
        #expect(rows.contains { $0.label == "交点序号" && $0.value == "2" })
        #expect(rows.contains { $0.label == "坐标" && $0.value == "(1.00, 0.00)" })
    }

    @Test func inspectorNoSolutionIntersectionShowsStatusWithoutStaleCoordinate() {
        let lineA = MathObject(
            id: UUID(),
            name: "l1",
            type: .line,
            expression: MathExpression(displayText: "l1"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 1, y: 0)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.fixedPoint(WorldPoint(x: 0, y: 0)), .fixedPoint(WorldPoint(x: 1, y: 0))]),
            style: MathStyle(colorToken: "indigo")
        )
        let lineB = MathObject(
            id: UUID(),
            name: "l2",
            type: .line,
            expression: MathExpression(displayText: "l2"),
            points: [WorldPoint(x: 0, y: 1), WorldPoint(x: 1, y: 1)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.fixedPoint(WorldPoint(x: 0, y: 1)), .fixedPoint(WorldPoint(x: 1, y: 1))]),
            style: MathStyle(colorToken: "purple")
        )
        let intersection = MathObject(
            id: UUID(),
            name: "I",
            type: .point,
            expression: MathExpression(displayText: "I"),
            position: WorldPoint(x: 999, y: 999),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .intersectionOf(objectAID: lineA.id, objectBID: lineB.id, index: 0)),
            geometryDefinitionStatus: .noSolution,
            style: MathStyle(colorToken: "yellowOrange")
        )
        let rows = inspectorRows(for: intersection, objects: [lineA, lineB, intersection])
        #expect(rows.contains { $0.label == "定义状态" && $0.value == "当前无交点" })
        #expect(rows.contains { $0.label == "坐标" } == false)
    }

    @Test func inspectorDerivedLineShowsDependencyKindAndSource() {
        let reference = MathObject(
            id: UUID(),
            name: "l0",
            type: .line,
            expression: MathExpression(displayText: "l0"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 2, y: 0)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.fixedPoint(WorldPoint(x: 0, y: 0)), .fixedPoint(WorldPoint(x: 2, y: 0))]),
            style: MathStyle(colorToken: "indigo")
        )
        let through = MathObject(
            id: UUID(),
            name: "P",
            type: .point,
            expression: MathExpression(displayText: "P"),
            position: WorldPoint(x: 0, y: 1),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let derived = MathObject(
            id: UUID(),
            name: "p",
            type: .line,
            expression: MathExpression(displayText: "p"),
            points: [WorldPoint(x: 0, y: 1), WorldPoint(x: 1, y: 1)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.object(through.id), .fixedPoint(WorldPoint(x: 1, y: 1))]),
            geometryDependency: GeometryDependency(kind: .parallelLine(referenceObjectID: reference.id, throughPointID: through.id)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "indigo")
        )
        let rows = inspectorRows(for: derived, objects: [reference, through, derived])
        #expect(rows.contains { $0.label == "构造关系" && $0.value == "平行线" })
        #expect(rows.contains { $0.label == "来源对象" && $0.value == "平行：过 P，参考 l0" })
    }

    @Test func geometryFormatterCoordinateUsesTwoDecimals() {
        let value = GeometryPropertyFormatter.coordinate(WorldPoint(x: 1.234, y: -4.567))
        #expect(value == "(1.23, -4.57)")
    }

    @Test func geometryFormatterVectorUsesTwoDecimals() {
        let value = GeometryPropertyFormatter.vector(dx: 1, dy: -0.3333)
        #expect(value == "(1.00, -0.33)")
    }

    @Test func geometryFormatterMeasurementUsesTwoDecimals() {
        #expect(GeometryPropertyFormatter.measurement(3.14159) == "3.14")
    }

    @Test func geometryFormatterAngleUsesOneDecimalDegree() {
        let value = GeometryPropertyFormatter.angleRadians(.pi / 4)
        #expect(value == "45.0°")
    }

    @Test func geometryFormatterSlopeUsesTwoDecimals() {
        let value = GeometryPropertyFormatter.slope(dx: 2, dy: 1)
        #expect(value == "0.50")
    }

    @Test func geometryFormatterVerticalSlopeReturnsVerticalLabel() {
        let value = GeometryPropertyFormatter.slope(dx: 0, dy: 5)
        #expect(value == "垂直")
    }

    @Test func geometryFormatterInvalidSlopeReturnsUndefined() {
        let value = GeometryPropertyFormatter.slope(dx: .infinity, dy: 1)
        #expect(value == "未定义")
    }

    @Test func geometryFormatterFiniteValidationRejectsNaNAndInfinite() {
        #expect(GeometryPropertyFormatter.isFiniteValid(.nan) == false)
        #expect(GeometryPropertyFormatter.isFiniteValid(.infinity) == false)
        #expect(GeometryPropertyFormatter.isFiniteValid(-.infinity) == false)
        #expect(GeometryPropertyFormatter.isFiniteValid(1.0) == true)
    }

    @MainActor
    @Test func movingLineCircleSourcesRecomputesDynamicIntersectionPoints() throws {
        let state = makeDynamicLineCircleIntersectionWorkspaceState()
        guard let sourcePointID = state.document.objects.first(where: { $0.name == "B" })?.id else {
            Issue.record("Missing source point")
            return
        }
        let tolerance = 1e-6
        let before = state.document.objects
            .filter { $0.name.hasPrefix("I") }
            .compactMap(\.position)
            .sorted { $0.x < $1.x }

        state.dispatch(.updateObjectPosition(id: sourcePointID, position: WorldPoint(x: 2, y: 1)))

        let after = state.document.objects
            .filter { $0.name.hasPrefix("I") }
            .compactMap(\.position)
            .sorted { $0.x < $1.x }

        #expect(before.count == 2)
        #expect(after.count == 2)
        #expect(zip(before, after).allSatisfy { pair in
            hypot(pair.0.x - pair.1.x, pair.0.y - pair.1.y) > tolerance
        })
        #expect(state.document.objects.filter { $0.name.hasPrefix("I") }.allSatisfy { $0.geometryDependency != nil })
    }

    @MainActor
    @Test func deletingCircleSourceConvertsDynamicIntersectionToStatic() throws {
        let state = makeDynamicLineCircleIntersectionWorkspaceState()
        guard let circleID = state.document.objects.first(where: { $0.type == .circle })?.id,
              let intersectionID = state.document.objects.first(where: { $0.name == "I0" })?.id else {
            Issue.record("Missing setup for source-removal test")
            return
        }
        state.dispatch(.deleteObject(id: circleID))
        guard let intersection = state.document.objects.first(where: { $0.id == intersectionID }) else {
            Issue.record("Missing intersection point after delete")
            return
        }
        #expect(intersection.geometryDependency == nil)
    }
}

private extension PlaneGeometryDependencyTests {
    enum DerivedLineMode {
        case parallel
        case perpendicular
    }

    var geometryPresentationResolver: any GeometryPresentationResolverProtocol {
        PlaneWorkspaceModuleProvider().geometryPresentationResolver ?? DefaultGeometryPresentationResolver()
    }

    func secondaryLines(
        for object: MathObject,
        objects: [MathObject],
        simplifiedText: String?,
        metadataText: String?,
        typeFallback: String
    ) -> [String] {
        GeometryDependencyPresentation.secondaryLines(
            for: object,
            objects: objects,
            simplifiedText: simplifiedText,
            metadataText: metadataText,
            typeFallback: typeFallback,
            geometryResolver: geometryPresentationResolver
        )
    }

    func inspectorRows(for object: MathObject, objects: [MathObject]) -> [GeometryInspectorPropertyRow] {
        GeometryInspectorPropertyPresenter.rows(
            for: object,
            objects: objects,
            geometryResolver: geometryPresentationResolver
        )
    }

    @MainActor
    func makeDerivedLineWorkspaceState(mode: DerivedLineMode) -> WorkspaceState {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "derived-line",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )

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
            expression: MathExpression(displayText: "B=(3,1)"),
            position: WorldPoint(x: 3, y: 1),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let reference = MathObject(
            id: UUID(),
            name: "s1",
            type: .segment,
            expression: MathExpression(displayText: "s1: 线段"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 3, y: 1)],
            geometryDefinition: GeometryDefinition(
                kind: .segment,
                anchors: [.object(pointA.id), .object(pointB.id)]
            ),
            style: MathStyle(colorToken: "blue")
        )
        let throughPoint = MathObject(
            id: UUID(),
            name: "P",
            type: .point,
            expression: MathExpression(displayText: "P=(2,2)"),
            position: WorldPoint(x: 2, y: 2),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )

        let modeID = mode == .parallel ? "plane.createParallelLine" : "plane.createPerpendicularLine"
        let payload = #"{"referenceObjectID":"\#(reference.id.uuidString)","pointID":"\#(throughPoint.id.uuidString)"}"#
        let handler = PlaneCommandHandler()
        let seedDocument = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: [pointA, pointB, reference, throughPoint]
        )
        let output = handler.handle(
            .moduleSpecific(id: modeID, payload: payload),
            context: ModuleCommandContext(document: seedDocument, selectedObjectIDs: [], inputText: "")
        )
        var finalDocument = seedDocument
        finalDocument.apply(output.documentCommands)
        return WorkspaceState(
            module: .plane,
            document: finalDocument,
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
    }

    @MainActor
    func makeMidpointWorkspaceState() -> WorkspaceState {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "midpoint-state",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
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
            style: MathStyle(colorToken: "green")
        )
        let document = EMathicaDocument(metadata: metadata, moduleID: "plane", objects: [pointA, pointB, midpoint])
        return WorkspaceState(
            module: .plane,
            document: document,
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
    }

    @MainActor
    func makeDynamicIntersectionWorkspaceState() -> WorkspaceState {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "dynamic-intersection",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )

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
            expression: MathExpression(displayText: "B=(2,2)"),
            position: WorldPoint(x: 2, y: 2),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let line1 = MathObject(
            id: UUID(),
            name: "l1",
            type: .line,
            expression: MathExpression(displayText: "l1: 直线"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 2, y: 2)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.object(pointA.id), .object(pointB.id)]),
            style: MathStyle(colorToken: "indigo")
        )

        let pointC = MathObject(
            id: UUID(),
            name: "C",
            type: .point,
            expression: MathExpression(displayText: "C=(0,2)"),
            position: WorldPoint(x: 0, y: 2),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "green")
        )
        let pointD = MathObject(
            id: UUID(),
            name: "D",
            type: .point,
            expression: MathExpression(displayText: "D=(2,0)"),
            position: WorldPoint(x: 2, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "pink")
        )
        let line2 = MathObject(
            id: UUID(),
            name: "l2",
            type: .line,
            expression: MathExpression(displayText: "l2: 直线"),
            points: [WorldPoint(x: 0, y: 2), WorldPoint(x: 2, y: 0)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.object(pointC.id), .object(pointD.id)]),
            style: MathStyle(colorToken: "blue")
        )

        let intersectionPoint = MathObject(
            id: UUID(),
            name: "P",
            type: .point,
            expression: MathExpression(displayText: "P = (1, 1)"),
            position: WorldPoint(x: 1, y: 1),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .intersectionOf(objectAID: line1.id, objectBID: line2.id, index: 0)),
            style: MathStyle(colorToken: "yellowOrange")
        )

        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: [pointA, pointB, pointC, pointD, line1, line2, intersectionPoint]
        )

        return WorkspaceState(
            module: .plane,
            document: document,
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
    }

    @MainActor
    func makeDynamicCircleWorkspaceState() -> WorkspaceState {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "dynamic-circle",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        let center = MathObject(
            id: UUID(),
            name: "C",
            type: .point,
            expression: MathExpression(displayText: "C=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let through = MathObject(
            id: UUID(),
            name: "T",
            type: .point,
            expression: MathExpression(displayText: "T=(2,0)"),
            position: WorldPoint(x: 2, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let circle = MathObject(
            id: UUID(),
            name: "c1",
            type: .circle,
            expression: MathExpression(displayText: "c1: 圆"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 2, y: 0)],
            geometryDefinition: GeometryDefinition(kind: .circle, anchors: [.object(center.id), .object(through.id)]),
            geometryDependency: GeometryDependency(kind: .circleByCenterPoint(centerPointID: center.id, throughPointID: through.id)),
            style: MathStyle(colorToken: "green")
        )
        let document = EMathicaDocument(metadata: metadata, moduleID: "plane", objects: [center, through, circle])
        return WorkspaceState(
            module: .plane,
            document: document,
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
    }

    @MainActor
    func makeDynamicCircleByRadiusWorkspaceState() -> WorkspaceState {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "dynamic-circle-by-radius",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        let center = MathObject(
            id: UUID(),
            name: "C",
            type: .point,
            expression: MathExpression(displayText: "C=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let radius = 2.0
        let through = WorldPoint(x: radius, y: 0)
        let circle = MathObject(
            id: UUID(),
            name: "c1",
            type: .circle,
            expression: MathExpression(displayText: "c1: 圆"),
            points: [WorldPoint(x: 0, y: 0), through],
            geometryDefinition: GeometryDefinition(kind: .circle, anchors: [.object(center.id), .fixedPoint(through)]),
            geometryDependency: GeometryDependency(kind: .circleByCenterRadius(centerPointID: center.id, radius: radius)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "green")
        )
        let document = EMathicaDocument(metadata: metadata, moduleID: "plane", objects: [center, circle])
        return WorkspaceState(
            module: .plane,
            document: document,
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
    }

    @MainActor
    func makeDynamicLineCircleIntersectionWorkspaceState() -> WorkspaceState {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "dynamic-line-circle-intersection",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )

        let a = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(-2,0)"),
            position: WorldPoint(x: -2, y: 0),
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
        let line = MathObject(
            id: UUID(),
            name: "l1",
            type: .line,
            expression: MathExpression(displayText: "l1: 直线"),
            points: [WorldPoint(x: -2, y: 0), WorldPoint(x: 2, y: 0)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.object(a.id), .object(b.id)]),
            style: MathStyle(colorToken: "indigo")
        )

        let c = MathObject(
            id: UUID(),
            name: "C",
            type: .point,
            expression: MathExpression(displayText: "C=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "green")
        )
        let t = MathObject(
            id: UUID(),
            name: "T",
            type: .point,
            expression: MathExpression(displayText: "T=(1,0)"),
            position: WorldPoint(x: 1, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "pink")
        )
        let circle = MathObject(
            id: UUID(),
            name: "c1",
            type: .circle,
            expression: MathExpression(displayText: "c1: 圆"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 1, y: 0)],
            geometryDefinition: GeometryDefinition(kind: .circle, anchors: [.object(c.id), .object(t.id)]),
            geometryDependency: GeometryDependency(kind: .circleByCenterPoint(centerPointID: c.id, throughPointID: t.id)),
            style: MathStyle(colorToken: "green")
        )

        let i0 = MathObject(
            id: UUID(),
            name: "I0",
            type: .point,
            expression: MathExpression(displayText: "I0=(-1,0)"),
            position: WorldPoint(x: -1, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .intersectionOf(objectAID: line.id, objectBID: circle.id, index: 0)),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let i1 = MathObject(
            id: UUID(),
            name: "I1",
            type: .point,
            expression: MathExpression(displayText: "I1=(1,0)"),
            position: WorldPoint(x: 1, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .intersectionOf(objectAID: line.id, objectBID: circle.id, index: 1)),
            style: MathStyle(colorToken: "yellowOrange")
        )

        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: [a, b, c, t, line, circle, i0, i1]
        )

        return WorkspaceState(
            module: .plane,
            document: document,
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
    }

    @MainActor
    func makeDynamicLineCircleIntersectionByRadiusWorkspaceState() -> WorkspaceState {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "dynamic-line-circle-intersection-by-radius",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )

        let a = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(-3,0)"),
            position: WorldPoint(x: -3, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let b = MathObject(
            id: UUID(),
            name: "B",
            type: .point,
            expression: MathExpression(displayText: "B=(3,0)"),
            position: WorldPoint(x: 3, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let line = MathObject(
            id: UUID(),
            name: "l1",
            type: .line,
            expression: MathExpression(displayText: "l1: 直线"),
            points: [WorldPoint(x: -3, y: 0), WorldPoint(x: 3, y: 0)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.object(a.id), .object(b.id)]),
            style: MathStyle(colorToken: "indigo")
        )

        let c = MathObject(
            id: UUID(),
            name: "C",
            type: .point,
            expression: MathExpression(displayText: "C=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "green")
        )
        let radius = 1.5
        let through = WorldPoint(x: c.position!.x + radius, y: c.position!.y)
        let circle = MathObject(
            id: UUID(),
            name: "c1",
            type: .circle,
            expression: MathExpression(displayText: "c1: 圆"),
            points: [c.position!, through],
            geometryDefinition: GeometryDefinition(kind: .circle, anchors: [.object(c.id), .fixedPoint(through)]),
            geometryDependency: GeometryDependency(kind: .circleByCenterRadius(centerPointID: c.id, radius: radius)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "green")
        )

        let i0 = MathObject(
            id: UUID(),
            name: "I0",
            type: .point,
            expression: MathExpression(displayText: "I0=(-1.5,0)"),
            position: WorldPoint(x: -1.5, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .intersectionOf(objectAID: line.id, objectBID: circle.id, index: 0)),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let i1 = MathObject(
            id: UUID(),
            name: "I1",
            type: .point,
            expression: MathExpression(displayText: "I1=(1.5,0)"),
            position: WorldPoint(x: 1.5, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .intersectionOf(objectAID: line.id, objectBID: circle.id, index: 1)),
            style: MathStyle(colorToken: "yellowOrange")
        )

        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: [a, b, c, line, circle, i0, i1]
        )

        return WorkspaceState(
            module: .plane,
            document: document,
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
    }

    func cross(_ lhs: WorldPoint, _ rhs: WorldPoint) -> Double {
        lhs.x * rhs.y - lhs.y * rhs.x
    }

    func dot(_ lhs: WorldPoint, _ rhs: WorldPoint) -> Double {
        lhs.x * rhs.x + lhs.y * rhs.y
    }
}
