import Foundation
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct PlaneBasicGeometryGoldenFixtureTests {
    @Test func basicGeometryFixtureCanBeBuilt() throws {
        let fixture = PlaneBasicGeometryFixture()
        let document = fixture.document()
        let resolver = fixture.geometryPresentationResolver

        #expect(document.objects.count == 10)
        #expect(Set(document.objects.map(\.id)).count == 10)
        #expect(Dictionary(uniqueKeysWithValues: document.objects.map { ($0.id, $0.name) }) == fixture.expectedNamesByID)

        let pointA = try #require(document.object(id: fixture.pointAID))
        let lineAB = try #require(document.object(id: fixture.lineABID))
        let segmentAC = try #require(document.object(id: fixture.segmentACID))
        let rayED = try #require(document.object(id: fixture.rayEDID))
        let circleAB = try #require(document.object(id: fixture.circleABID))
        let arcACD = try #require(document.object(id: fixture.arcACDID))

        let pointRows = GeometryInspectorPropertyPresenter.rows(
            for: pointA,
            objects: document.objects,
            geometryResolver: resolver
        )
        let lineRows = GeometryInspectorPropertyPresenter.rows(
            for: lineAB,
            objects: document.objects,
            geometryResolver: resolver
        )
        let segmentRows = GeometryInspectorPropertyPresenter.rows(
            for: segmentAC,
            objects: document.objects,
            geometryResolver: resolver
        )
        let rayRows = GeometryInspectorPropertyPresenter.rows(
            for: rayED,
            objects: document.objects,
            geometryResolver: resolver
        )
        let circleRows = GeometryInspectorPropertyPresenter.rows(
            for: circleAB,
            objects: document.objects,
            geometryResolver: resolver
        )

        #expect(pointRows.contains(where: { $0.label == "坐标" }))
        #expect(lineRows.contains(where: { $0.label == "方向向量" }))
        #expect(lineRows.contains(where: { $0.label == "斜率" }))
        #expect(segmentRows.contains(where: { $0.label == "长度" }))
        #expect(rayRows.contains(where: { $0.label == "起点" }))
        #expect(circleRows.contains(where: { $0.label == "半径" }))
        #expect(circleRows.contains(where: { $0.label == "直径" }))

        let segmentSecondary = GeometryDependencyPresentation.secondaryText(
            for: segmentAC,
            objects: document.objects,
            simplifiedText: nil,
            metadataText: nil,
            typeFallback: "segment",
            geometryResolver: resolver
        )
        let circleSecondary = GeometryDependencyPresentation.secondaryText(
            for: circleAB,
            objects: document.objects,
            simplifiedText: nil,
            metadataText: nil,
            typeFallback: "circle",
            geometryResolver: resolver
        )
        #expect(segmentSecondary.contains("长度"))
        #expect(circleSecondary.contains("半径"))

        let arcSource = GeometryDependencyPresentation.sourceText(for: arcACD, objects: document.objects)
        let arcGeometry = PlaneGeometryResolver.arcGeometry(for: arcACD, in: document.objects)
        #expect(arcSource?.contains("圆弧") == true)
        #expect(arcGeometry != nil)
    }

    @MainActor
    @Test func basicGeometryFixtureResolvesObjectProperties() throws {
        let fixture = PlaneBasicGeometryFixture()
        let document = fixture.document()

        let lineAB = try #require(document.object(id: fixture.lineABID))
        let segmentAC = try #require(document.object(id: fixture.segmentACID))
        let rayED = try #require(document.object(id: fixture.rayEDID))
        let circleAB = try #require(document.object(id: fixture.circleABID))
        let arcACD = try #require(document.object(id: fixture.arcACDID))

        let linePoints = try #require(PlaneGeometryResolver.linePoints(for: lineAB, in: document.objects))
        let segmentEndpoints = try #require(PlaneGeometryResolver.segmentEndpoints(for: segmentAC, in: document.objects))
        let rayPoints = try #require(PlaneGeometryResolver.rayPoints(for: rayED, in: document.objects))
        let circleGeometry = try #require(PlaneGeometryResolver.circleGeometry(for: circleAB, in: document.objects))
        let arcGeometry = try #require(PlaneGeometryResolver.arcGeometry(for: arcACD, in: document.objects))

        #expect(linePoints.0 == WorldPoint(x: 0, y: 0))
        #expect(linePoints.1 == WorldPoint(x: 4, y: 0))
        #expect(segmentEndpoints.0 == WorldPoint(x: 0, y: 0))
        #expect(segmentEndpoints.1 == WorldPoint(x: 1, y: 3))
        #expect(rayPoints.0 == WorldPoint(x: -2, y: 1))
        #expect(rayPoints.1 == WorldPoint(x: 3, y: 2))
        #expect(circleGeometry.center == WorldPoint(x: 0, y: 0))
        #expect(abs(circleGeometry.radius - 4) < 1e-9)
        #expect(arcGeometry.radius.isFinite)
        #expect(arcGeometry.radius > 0)
    }

    @MainActor
    @Test func basicGeometryFixtureUpdatesAfterSourcePointMove() throws {
        let fixture = PlaneBasicGeometryFixture()
        let state = fixture.workspaceState(document: fixture.document())

        let originalArc = try #require(state.document.object(id: fixture.arcACDID))
        let originalArcGeometry = try #require(PlaneGeometryResolver.arcGeometry(for: originalArc, in: state.document.objects))

        state.dispatch(.updateObjectPosition(id: fixture.pointBID, position: WorldPoint(x: 4, y: 2)))
        state.dispatch(.updateObjectPosition(id: fixture.pointCID, position: WorldPoint(x: 2, y: 4)))
        state.dispatch(.updateObjectPosition(id: fixture.pointDID, position: WorldPoint(x: 5, y: 3)))

        let lineAB = try #require(state.document.object(id: fixture.lineABID))
        let segmentAC = try #require(state.document.object(id: fixture.segmentACID))
        let rayED = try #require(state.document.object(id: fixture.rayEDID))
        let circleAB = try #require(state.document.object(id: fixture.circleABID))
        let arcACD = try #require(state.document.object(id: fixture.arcACDID))

        let linePoints = try #require(PlaneGeometryResolver.linePoints(for: lineAB, in: state.document.objects))
        let segmentEndpoints = try #require(PlaneGeometryResolver.segmentEndpoints(for: segmentAC, in: state.document.objects))
        let rayPoints = try #require(PlaneGeometryResolver.rayPoints(for: rayED, in: state.document.objects))
        let circleGeometry = try #require(PlaneGeometryResolver.circleGeometry(for: circleAB, in: state.document.objects))
        let arcGeometry = try #require(PlaneGeometryResolver.arcGeometry(for: arcACD, in: state.document.objects))

        #expect(linePoints.0 == WorldPoint(x: 0, y: 0))
        #expect(linePoints.1 == WorldPoint(x: 4, y: 2))
        #expect(segmentEndpoints.0 == WorldPoint(x: 0, y: 0))
        #expect(segmentEndpoints.1 == WorldPoint(x: 2, y: 4))
        #expect(rayPoints.0 == WorldPoint(x: -2, y: 1))
        #expect(rayPoints.1 == WorldPoint(x: 5, y: 3))
        #expect(circleGeometry.center == WorldPoint(x: 0, y: 0))
        #expect(abs(circleGeometry.radius - sqrt(20)) < 1e-9)
        #expect(arcACD.points == [WorldPoint(x: 0, y: 0), WorldPoint(x: 2, y: 4), WorldPoint(x: 5, y: 3)])
        #expect(arcGeometry.radius != originalArcGeometry.radius)
    }

    @MainActor
    @Test func basicGeometryFixtureSurvivesSaveReopen() throws {
        let fixture = PlaneBasicGeometryFixture()
        let reopened = try fixture.reopen(fixture.document())

        #expect(reopened.objects.count == 10)
        #expect(Set(reopened.objects.map(\.id)) == fixture.allObjectIDs)
        #expect(Dictionary(uniqueKeysWithValues: reopened.objects.map { ($0.id, $0.name) }) == fixture.expectedNamesByID)

        let lineAB = try #require(reopened.object(id: fixture.lineABID))
        let segmentAC = try #require(reopened.object(id: fixture.segmentACID))
        let rayED = try #require(reopened.object(id: fixture.rayEDID))
        let circleAB = try #require(reopened.object(id: fixture.circleABID))
        let arcACD = try #require(reopened.object(id: fixture.arcACDID))

        let lineAnchors = try #require(lineAB.geometryDefinition?.anchors)
        let segmentAnchors = try #require(segmentAC.geometryDefinition?.anchors)
        let rayAnchors = try #require(rayED.geometryDefinition?.anchors)
        let circleAnchors = try #require(circleAB.geometryDefinition?.anchors)

        #expect(lineAnchors.compactMap(\.objectID) == [fixture.pointAID, fixture.pointBID])
        #expect(segmentAnchors.compactMap(\.objectID) == [fixture.pointAID, fixture.pointCID])
        #expect(rayAnchors.compactMap(\.objectID) == [fixture.pointEID, fixture.pointDID])
        #expect(circleAnchors.compactMap(\.objectID) == [fixture.pointAID, fixture.pointBID])
        #expect(arcACD.geometryDependency?.kind == fixture.arcDependency.kind)

        let state = fixture.workspaceState(document: reopened)
        state.dispatch(.updateObjectPosition(id: fixture.pointBID, position: WorldPoint(x: 5, y: 1)))
        state.dispatch(.updateObjectPosition(id: fixture.pointCID, position: WorldPoint(x: 2, y: 5)))

        let updatedLine = try #require(state.document.object(id: fixture.lineABID))
        let updatedSegment = try #require(state.document.object(id: fixture.segmentACID))
        let updatedCircle = try #require(state.document.object(id: fixture.circleABID))
        let updatedArc = try #require(state.document.object(id: fixture.arcACDID))

        let updatedLinePoints = try #require(PlaneGeometryResolver.linePoints(for: updatedLine, in: state.document.objects))
        let updatedSegmentEndpoints = try #require(PlaneGeometryResolver.segmentEndpoints(for: updatedSegment, in: state.document.objects))
        let updatedCircleGeometry = try #require(PlaneGeometryResolver.circleGeometry(for: updatedCircle, in: state.document.objects))
        let updatedArcGeometry = try #require(PlaneGeometryResolver.arcGeometry(for: updatedArc, in: state.document.objects))

        #expect(updatedLinePoints.1 == WorldPoint(x: 5, y: 1))
        #expect(updatedSegmentEndpoints.1 == WorldPoint(x: 2, y: 5))
        #expect(abs(updatedCircleGeometry.radius - sqrt(26)) < 1e-9)
        #expect(updatedArcGeometry.radius.isFinite)
        #expect(updatedArcGeometry.radius > 0)
    }

    @MainActor
    @Test func basicGeometryFixtureDeleteIndependentObjectKeepsDocumentValid() throws {
        let fixture = PlaneBasicGeometryFixture()
        let state = fixture.workspaceState(document: fixture.document())

        state.dispatch(.deleteObject(id: fixture.lineABID))
        let reopened = try fixture.reopen(state.document)

        #expect(reopened.objects.count == 9)
        #expect(reopened.objects.contains(where: { $0.id == fixture.lineABID }) == false)
        #expect(reopened.objects.contains(where: { $0.id == fixture.circleABID }))
        #expect(reopened.objects.contains(where: { $0.id == fixture.arcACDID }))
        #expect(hasDanglingGeometryDependency(in: reopened) == false)

        let reopenedCircle = try #require(reopened.object(id: fixture.circleABID))
        let circleGeometry = try #require(PlaneGeometryResolver.circleGeometry(for: reopenedCircle, in: reopened.objects))
        #expect(circleGeometry.center == WorldPoint(x: 0, y: 0))
        #expect(abs(circleGeometry.radius - 4) < 1e-9)
    }

    @MainActor
    @Test func basicGeometryFixturePreviewRenders() throws {
        let fixture = PlaneBasicGeometryFixture()
        let baseDocument = fixture.document()
        let reopenedBase = try fixture.reopen(baseDocument)
        let deletedDocument = try fixture.deletedDocument()

        let basePreview = try #require(ProjectPreviewRenderer.renderPNGData(for: baseDocument))
        let reopenedPreview = try #require(ProjectPreviewRenderer.renderPNGData(for: reopenedBase))
        let deletedPreview = try #require(ProjectPreviewRenderer.renderPNGData(for: deletedDocument))

        #expect(basePreview.isEmpty == false)
        #expect(reopenedPreview.isEmpty == false)
        #expect(deletedPreview.isEmpty == false)
    }
}

private struct PlaneBasicGeometryFixture {
    let pointAID = UUID()
    let pointBID = UUID()
    let pointCID = UUID()
    let pointDID = UUID()
    let pointEID = UUID()
    let lineABID = UUID()
    let segmentACID = UUID()
    let rayEDID = UUID()
    let circleABID = UUID()
    let arcACDID = UUID()

    var allObjectIDs: Set<UUID> {
        [
            pointAID,
            pointBID,
            pointCID,
            pointDID,
            pointEID,
            lineABID,
            segmentACID,
            rayEDID,
            circleABID,
            arcACDID
        ]
    }

    var expectedNamesByID: [UUID: String] {
        [
            pointAID: "A",
            pointBID: "B",
            pointCID: "C",
            pointDID: "D",
            pointEID: "E",
            lineABID: "l_AB",
            segmentACID: "s_AC",
            rayEDID: "r_ED",
            circleABID: "c_AB",
            arcACDID: "arc_ACD"
        ]
    }

    var arcDependency: GeometryDependency {
        GeometryDependency(kind: .arcByThreePoints(pointAID: pointAID, pointBID: pointCID, pointCID: pointDID))
    }

    var geometryPresentationResolver: any GeometryPresentationResolverProtocol {
        PlaneWorkspaceModuleProvider().geometryPresentationResolver ?? DefaultGeometryPresentationResolver()
    }

    func document(title: String = "Plane-2D-BasicGeometry") -> EMathicaDocument {
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
    func deletedDocument() throws -> EMathicaDocument {
        let state = workspaceState(document: document())
        state.dispatch(.deleteObject(id: lineABID))
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
            expression: MathExpression(displayText: "B=(4,0)"),
            position: WorldPoint(x: 4, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let pointC = MathObject(
            id: pointCID,
            name: "C",
            type: .point,
            expression: MathExpression(displayText: "C=(1,3)"),
            position: WorldPoint(x: 1, y: 3),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "green")
        )
        let pointD = MathObject(
            id: pointDID,
            name: "D",
            type: .point,
            expression: MathExpression(displayText: "D=(3,2)"),
            position: WorldPoint(x: 3, y: 2),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "indigo")
        )
        let pointE = MathObject(
            id: pointEID,
            name: "E",
            type: .point,
            expression: MathExpression(displayText: "E=(-2,1)"),
            position: WorldPoint(x: -2, y: 1),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let lineAB = MathObject(
            id: lineABID,
            name: "l_AB",
            type: .line,
            expression: MathExpression(displayText: "l_AB"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 4, y: 0)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.object(pointAID), .object(pointBID)]),
            style: MathStyle(colorToken: "indigo")
        )
        let segmentAC = MathObject(
            id: segmentACID,
            name: "s_AC",
            type: .segment,
            expression: MathExpression(displayText: "s_AC"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 1, y: 3)],
            geometryDefinition: GeometryDefinition(kind: .segment, anchors: [.object(pointAID), .object(pointCID)]),
            style: MathStyle(colorToken: "blue")
        )
        let rayED = MathObject(
            id: rayEDID,
            name: "r_ED",
            type: .ray,
            expression: MathExpression(displayText: "r_ED"),
            points: [WorldPoint(x: -2, y: 1), WorldPoint(x: 3, y: 2)],
            geometryDefinition: GeometryDefinition(kind: .ray, anchors: [.object(pointEID), .object(pointDID)]),
            style: MathStyle(colorToken: "purple")
        )
        let circleAB = MathObject(
            id: circleABID,
            name: "c_AB",
            type: .circle,
            expression: MathExpression(displayText: "c_AB"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 4, y: 0)],
            geometryDefinition: GeometryDefinition(kind: .circle, anchors: [.object(pointAID), .object(pointBID)]),
            style: MathStyle(colorToken: "green")
        )
        let arcACD = MathObject(
            id: arcACDID,
            name: "arc_ACD",
            type: .arc,
            expression: MathExpression(displayText: "arc_ACD"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 1, y: 3), WorldPoint(x: 3, y: 2)],
            geometryDefinition: GeometryDefinition(kind: .arc, anchors: [.object(pointAID), .object(pointCID), .object(pointDID)]),
            geometryDependency: arcDependency,
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "yellowOrange")
        )
        return [pointA, pointB, pointC, pointD, pointE, lineAB, segmentAC, rayED, circleAB, arcACD]
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
