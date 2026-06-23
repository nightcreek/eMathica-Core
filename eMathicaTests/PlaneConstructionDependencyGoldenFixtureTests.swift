import Foundation
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct PlaneConstructionDependencyGoldenFixtureTests {
    @Test func constructionDependencyFixtureCanBeBuilt() throws {
        let fixture = PlaneConstructionDependencyFixture()
        let document = fixture.document()
        let resolver = fixture.geometryPresentationResolver

        #expect(document.objects.count == 11)
        #expect(Set(document.objects.map(\.id)).count == 11)

        let midpoint = try #require(document.object(id: fixture.midpointID))
        let intersection = try #require(document.object(id: fixture.intersectionID))
        let parallel = try #require(document.object(id: fixture.parallelID))
        let perpendicular = try #require(document.object(id: fixture.perpendicularID))
        let downstreamIntersection = try #require(document.object(id: fixture.downstreamIntersectionID))

        #expect(GeometryDependencyPresentation.sourceText(for: midpoint, objects: document.objects) != nil)
        #expect(GeometryDependencyPresentation.sourceText(for: intersection, objects: document.objects) != nil)
        #expect(GeometryDependencyPresentation.sourceText(for: parallel, objects: document.objects) != nil)
        #expect(GeometryDependencyPresentation.sourceText(for: perpendicular, objects: document.objects) != nil)

        let midpointRows = GeometryInspectorPropertyPresenter.rows(
            for: midpoint,
            objects: document.objects,
            geometryResolver: resolver
        )
        let intersectionRows = GeometryInspectorPropertyPresenter.rows(
            for: intersection,
            objects: document.objects,
            geometryResolver: resolver
        )
        let parallelRows = GeometryInspectorPropertyPresenter.rows(
            for: parallel,
            objects: document.objects,
            geometryResolver: resolver
        )
        let perpendicularRows = GeometryInspectorPropertyPresenter.rows(
            for: perpendicular,
            objects: document.objects,
            geometryResolver: resolver
        )
        let downstreamRows = GeometryInspectorPropertyPresenter.rows(
            for: downstreamIntersection,
            objects: document.objects,
            geometryResolver: resolver
        )

        #expect(midpointRows.contains(where: { $0.label == "坐标" }))
        #expect(intersectionRows.contains(where: { $0.label == "坐标" }))
        #expect(intersectionRows.contains(where: { $0.label == "交点序号" }))
        #expect(parallelRows.contains(where: { $0.label == "方向向量" }))
        #expect(perpendicularRows.contains(where: { $0.label == "方向向量" }))
        #expect(downstreamRows.contains(where: { $0.label == "坐标" }))
    }

    @MainActor
    @Test func constructionDependencyFixtureRecomputesAfterSourceMove() throws {
        let fixture = PlaneConstructionDependencyFixture()
        let state = try fixture.workspaceState(reopen: false)

        let originalMidpoint = try #require(state.document.object(id: fixture.midpointID))
        let originalIntersection = try #require(state.document.object(id: fixture.intersectionID))
        let originalParallel = try #require(state.document.object(id: fixture.parallelID))
        let originalPerpendicular = try #require(state.document.object(id: fixture.perpendicularID))

        state.dispatch(.updateObjectPosition(id: fixture.pointBID, position: WorldPoint(x: 4, y: 3)))

        let recomputedMidpoint = try #require(state.document.object(id: fixture.midpointID))
        let recomputedIntersection = try #require(state.document.object(id: fixture.intersectionID))
        let recomputedParallel = try #require(state.document.object(id: fixture.parallelID))
        let recomputedPerpendicular = try #require(state.document.object(id: fixture.perpendicularID))

        #expect(recomputedMidpoint.position == WorldPoint(x: 2, y: 1.5))
        #expect(recomputedIntersection.position == WorldPoint(x: 2, y: 1.5))
        #expect(recomputedParallel.geometryDefinitionStatus == .defined)
        #expect(recomputedPerpendicular.geometryDefinitionStatus == .defined)
        #expect(recomputedParallel.points?.first == WorldPoint(x: 2, y: -2))
        #expect(recomputedPerpendicular.points?.first == WorldPoint(x: 2, y: 2))
        #expect(recomputedParallel.points != originalParallel.points)
        #expect(recomputedPerpendicular.points != originalPerpendicular.points)
        #expect(originalMidpoint.position != recomputedMidpoint.position)
        #expect(originalIntersection.position != recomputedIntersection.position)
    }

    @MainActor
    @Test func constructionDependencyFixtureSurvivesSaveReopen() throws {
        let fixture = PlaneConstructionDependencyFixture()
        let reopened = try fixture.reopen(fixture.document())

        #expect(reopened.objects.count == 11)
        #expect(Set(reopened.objects.map(\.id)) == fixture.allObjectIDs)

        let midpoint = try #require(reopened.object(id: fixture.midpointID))
        let intersection = try #require(reopened.object(id: fixture.intersectionID))
        let parallel = try #require(reopened.object(id: fixture.parallelID))
        let perpendicular = try #require(reopened.object(id: fixture.perpendicularID))

        #expect(midpoint.geometryDependency?.kind == fixture.midpointDependency.kind)
        #expect(intersection.geometryDependency?.kind == fixture.intersectionDependency.kind)
        #expect(parallel.geometryDependency?.kind == fixture.parallelDependency.kind)
        #expect(perpendicular.geometryDependency?.kind == fixture.perpendicularDependency.kind)

        let state = fixture.workspaceState(document: reopened)
        state.dispatch(.updateObjectPosition(id: fixture.pointBID, position: WorldPoint(x: 4, y: 3)))

        let recomputedMidpoint = try #require(state.document.object(id: fixture.midpointID))
        let recomputedIntersection = try #require(state.document.object(id: fixture.intersectionID))
        let recomputedDownstream = try #require(state.document.object(id: fixture.downstreamIntersectionID))

        #expect(recomputedMidpoint.position == WorldPoint(x: 2, y: 1.5))
        #expect(recomputedIntersection.position == WorldPoint(x: 2, y: 1.5))
        #expect(recomputedDownstream.geometryDependency == fixture.downstreamIntersectionDependency)
        #expect(recomputedDownstream.geometryDefinitionStatus == .defined)
    }

    @MainActor
    @Test func constructionDependencyFixtureUnlinkSavesAsStatic() throws {
        let fixture = PlaneConstructionDependencyFixture()
        let state = try fixture.workspaceState(reopen: false)
        let originalPerpendicular = try #require(state.document.object(id: fixture.perpendicularID))
        let originalDownstream = try #require(state.document.object(id: fixture.downstreamIntersectionID))

        state.dispatch(.deleteObject(id: fixture.pointDID))
        let reopened = try fixture.reopen(state.document)

        #expect(reopened.objects.contains(where: { $0.id == fixture.pointDID }) == false)

        let reopenedPerpendicular = try #require(reopened.object(id: fixture.perpendicularID))
        let reopenedDownstream = try #require(reopened.object(id: fixture.downstreamIntersectionID))

        #expect(reopenedPerpendicular.geometryDependency == nil)
        #expect(reopenedPerpendicular.geometryDefinitionStatus == nil)
        #expect(reopenedPerpendicular.points == originalPerpendicular.points)
        #expect(reopenedDownstream.geometryDependency == fixture.downstreamIntersectionDependency)
        #expect(reopenedDownstream.geometryDefinitionStatus == .defined)
        #expect(hasDanglingGeometryDependency(in: reopened) == false)

        let reopenedState = fixture.workspaceState(document: reopened)
        reopenedState.dispatch(.updateObjectPosition(id: fixture.pointBID, position: WorldPoint(x: 4, y: 3)))

        let movedDownstream = try #require(reopenedState.document.object(id: fixture.downstreamIntersectionID))
        #expect(movedDownstream.position == originalDownstream.position)
    }

    @MainActor
    @Test func constructionDependencyFixtureDeleteAffectedSavesExpectedObjects() throws {
        let fixture = PlaneConstructionDependencyFixture()
        let state = try fixture.workspaceState(reopen: false)
        let originalDownstream = try #require(state.document.object(id: fixture.downstreamIntersectionID))

        state.requestDeleteObjectsWithConfirmation(Set([fixture.pointDID]))
        #expect(state.pendingDependencyDeletion?.selectedIDs == Set([fixture.pointDID]))
        #expect(state.pendingDependencyDeletion?.affectedIDs == Set([fixture.perpendicularID]))

        state.confirmPendingDependencyDeletion(strategy: .deleteAffected)
        let reopened = try fixture.reopen(state.document)

        #expect(reopened.objects.contains(where: { $0.id == fixture.pointDID }) == false)
        #expect(reopened.objects.contains(where: { $0.id == fixture.perpendicularID }) == false)

        let reopenedDownstream = try #require(reopened.object(id: fixture.downstreamIntersectionID))
        #expect(reopenedDownstream.geometryDependency == nil)
        #expect(reopenedDownstream.geometryDefinitionStatus == nil)
        #expect(reopenedDownstream.position == originalDownstream.position)
        #expect(hasDanglingGeometryDependency(in: reopened) == false)

        let reopenedState = fixture.workspaceState(document: reopened)
        reopenedState.dispatch(.updateObjectPosition(id: fixture.pointBID, position: WorldPoint(x: 4, y: 3)))
        let movedDownstream = try #require(reopenedState.document.object(id: fixture.downstreamIntersectionID))
        #expect(movedDownstream.position == originalDownstream.position)
    }

    @MainActor
    @Test func constructionDependencyFixturePreviewRenders() throws {
        let fixture = PlaneConstructionDependencyFixture()
        let baseDocument = fixture.document()

        let basePreview = try #require(ProjectPreviewRenderer.renderPNGData(for: baseDocument))
        #expect(basePreview.isEmpty == false)

        let unlinkDocument = try fixture.unlinkDocument()
        let unlinkPreview = try #require(ProjectPreviewRenderer.renderPNGData(for: unlinkDocument))
        #expect(unlinkPreview.isEmpty == false)

        let deleteAffectedDocument = try fixture.deleteAffectedDocument()
        let deleteAffectedPreview = try #require(ProjectPreviewRenderer.renderPNGData(for: deleteAffectedDocument))
        #expect(deleteAffectedPreview.isEmpty == false)
    }
}

private struct PlaneConstructionDependencyFixture {
    let pointAID = UUID()
    let pointBID = UUID()
    let pointCID = UUID()
    let pointDID = UUID()
    let lineABID = UUID()
    let lineCDID = UUID()
    let midpointID = UUID()
    let intersectionID = UUID()
    let parallelID = UUID()
    let perpendicularID = UUID()
    let downstreamIntersectionID = UUID()

    var allObjectIDs: Set<UUID> {
        [
            pointAID,
            pointBID,
            pointCID,
            pointDID,
            lineABID,
            lineCDID,
            midpointID,
            intersectionID,
            parallelID,
            perpendicularID,
            downstreamIntersectionID
        ]
    }

    var midpointDependency: GeometryDependency {
        GeometryDependency(kind: .midpointOfPoints(pointAID: pointAID, pointBID: pointBID))
    }

    var intersectionDependency: GeometryDependency {
        GeometryDependency(kind: .intersectionOf(objectAID: lineABID, objectBID: lineCDID, index: 0))
    }

    var parallelDependency: GeometryDependency {
        GeometryDependency(kind: .parallelLine(referenceObjectID: lineABID, throughPointID: pointCID))
    }

    var perpendicularDependency: GeometryDependency {
        GeometryDependency(kind: .perpendicularLine(referenceObjectID: lineABID, throughPointID: pointDID))
    }

    var downstreamIntersectionDependency: GeometryDependency {
        GeometryDependency(kind: .intersectionOf(objectAID: parallelID, objectBID: perpendicularID, index: 0))
    }

    var geometryPresentationResolver: any GeometryPresentationResolverProtocol {
        PlaneWorkspaceModuleProvider().geometryPresentationResolver ?? DefaultGeometryPresentationResolver()
    }

    func document(title: String = "Plane-2D-ConstructionDependency") -> EMathicaDocument {
        let now = Date()
        return EMathicaDocument(
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
    }

    @MainActor
    func workspaceState(reopen: Bool) throws -> WorkspaceState {
        let baseDocument = document()
        let targetDocument = try reopen ? self.reopen(baseDocument) : baseDocument
        return workspaceState(document: targetDocument)
    }

    @MainActor
    func workspaceState(document: EMathicaDocument) -> WorkspaceState {
        WorkspaceState(
            module: .plane,
            document: document,
            toolGroups: PlaneToolProvider.defaultToolGroups(),
            moduleProvider: PlaneWorkspaceModuleProvider()
        )
    }

    func reopen(_ document: EMathicaDocument) throws -> EMathicaDocument {
        let data = try EMathicaPackageCodec.makeEncoder().encode(document)
        return try EMathicaPackageCodec.makeDecoder().decode(EMathicaDocument.self, from: data)
    }

    @MainActor
    func unlinkDocument() throws -> EMathicaDocument {
        let state = try workspaceState(reopen: false)
        state.dispatch(.deleteObject(id: pointDID))
        return try reopen(state.document)
    }

    @MainActor
    func deleteAffectedDocument() throws -> EMathicaDocument {
        let state = try workspaceState(reopen: false)
        state.requestDeleteObjectsWithConfirmation(Set([pointDID]))
        state.confirmPendingDependencyDeletion(strategy: .deleteAffected)
        return try reopen(state.document)
    }

    private var objects: [MathObject] {
        let pointA = MathObject(
            id: pointAID,
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let pointB = MathObject(
            id: pointBID,
            name: "B",
            type: .point,
            expression: MathExpression(displayText: "B=(4,1)"),
            position: WorldPoint(x: 4, y: 1),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let pointC = MathObject(
            id: pointCID,
            name: "C",
            type: .point,
            expression: MathExpression(displayText: "C=(2,-2)"),
            position: WorldPoint(x: 2, y: -2),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "green")
        )
        let pointD = MathObject(
            id: pointDID,
            name: "D",
            type: .point,
            expression: MathExpression(displayText: "D=(2,2)"),
            position: WorldPoint(x: 2, y: 2),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "pink")
        )
        let lineAB = MathObject(
            id: lineABID,
            name: "ℓ1",
            type: .line,
            expression: MathExpression(displayText: "ℓ1"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 4, y: 1)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.object(pointAID), .object(pointBID)]),
            style: MathStyle(colorToken: "blue")
        )
        let lineCD = MathObject(
            id: lineCDID,
            name: "ℓ2",
            type: .line,
            expression: MathExpression(displayText: "ℓ2"),
            points: [WorldPoint(x: 2, y: -2), WorldPoint(x: 2, y: 2)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.object(pointCID), .object(pointDID)]),
            style: MathStyle(colorToken: "indigo")
        )
        let midpoint = MathObject(
            id: midpointID,
            name: "M",
            type: .point,
            expression: MathExpression(displayText: "M=(2,0.5)"),
            position: WorldPoint(x: 2, y: 0.5),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: midpointDependency,
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "green")
        )
        let intersection = MathObject(
            id: intersectionID,
            name: "X",
            type: .point,
            expression: MathExpression(displayText: "X=(2,0.5)"),
            position: WorldPoint(x: 2, y: 0.5),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: intersectionDependency,
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "yellowOrange")
        )
        let parallel = MathObject(
            id: parallelID,
            name: "p",
            type: .line,
            expression: MathExpression(displayText: "p"),
            points: [WorldPoint(x: 2, y: -2), WorldPoint(x: 6, y: -1)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.object(pointCID), .fixedPoint(WorldPoint(x: 6, y: -1))]),
            geometryDependency: parallelDependency,
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "blue")
        )
        let perpendicular = MathObject(
            id: perpendicularID,
            name: "q",
            type: .line,
            expression: MathExpression(displayText: "q"),
            points: [WorldPoint(x: 2, y: 2), WorldPoint(x: 1, y: 6)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.object(pointDID), .fixedPoint(WorldPoint(x: 1, y: 6))]),
            geometryDependency: perpendicularDependency,
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "cyan")
        )
        let downstreamIntersection = MathObject(
            id: downstreamIntersectionID,
            name: "Y",
            type: .point,
            expression: MathExpression(displayText: "Y"),
            position: WorldPoint(x: 2.9411764705882355, y: -1.7647058823529411),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: downstreamIntersectionDependency,
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "yellowOrange")
        )
        return [
            pointA,
            pointB,
            pointC,
            pointD,
            lineAB,
            lineCD,
            midpoint,
            intersection,
            parallel,
            perpendicular,
            downstreamIntersection
        ]
    }
}

private extension EMathicaDocument {
    func object(id: UUID) -> MathObject? {
        objects.first(where: { $0.id == id })
    }
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
