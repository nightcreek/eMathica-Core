import CoreGraphics
import Foundation
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct SpaceToolingTests {
    @Test func spaceToolProviderIncludesV1ASet() {
        let groups = SpaceToolProvider.defaultToolGroups()
        let ids = Set(groups.flatMap(\.tools).map(\.id))
        #expect(ids.contains(SpaceToolIDs.select))
        #expect(ids.contains(SpaceToolIDs.orbit))
        #expect(ids.contains(SpaceToolIDs.pan))
        #expect(ids.contains(SpaceToolIDs.point3D))
        #expect(ids.contains(SpaceToolIDs.segment3D))
        #expect(ids.contains(SpaceToolIDs.line3D))
        #expect(ids.contains(SpaceToolIDs.plane3D))
    }

    @Test func line3DToolActionSetsActiveTool() {
        let groups = SpaceToolProvider.defaultToolGroups()
        let tool = groups
            .flatMap(\.tools)
            .first(where: { $0.id == SpaceToolIDs.line3D })
        #expect(tool != nil)
        if case .setActiveTool(let id)? = tool?.action {
            #expect(id == SpaceToolIDs.line3D)
        } else {
            Issue.record("line3D tool action should be setActiveTool")
        }
    }

    @Test func plane3DToolActionSetsActiveTool() {
        let groups = SpaceToolProvider.defaultToolGroups()
        let tool = groups
            .flatMap(\.tools)
            .first(where: { $0.id == SpaceToolIDs.plane3D })
        #expect(tool != nil)
        if case .setActiveTool(let id)? = tool?.action {
            #expect(id == SpaceToolIDs.plane3D)
        } else {
            Issue.record("plane3D tool action should be setActiveTool")
        }
    }

    @Test func tapProjectionMapsToZ0Plane() {
        let viewport = SpaceViewportSize(width: 800, height: 600)
        let point = SpaceGeometryResolver.screenPointToWorkPlane(
            CGPoint(x: 400, y: 300),
            workPlane: .xy,
            viewportSize: viewport,
            camera: .default
        )
        #expect(point != nil)
        #expect(abs((point?.z ?? 1)) < 1e-6)
    }

    @Test func orthographicTapProjectionMapsToZ0Plane() {
        let viewport = SpaceViewportSize(width: 800, height: 600)
        let camera = SpaceCameraState(
            target: .zero,
            distance: 12,
            yaw: -.pi / 5,
            pitch: .pi / 7,
            projection: .orthographic,
            fovDegrees: 60
        )
        let point = SpaceGeometryResolver.screenPointToWorkPlane(
            CGPoint(x: 500, y: 220),
            workPlane: .xy,
            viewportSize: viewport,
            camera: camera
        )
        #expect(point != nil)
        #expect(abs((point?.z ?? 1)) < 1e-6)
    }

    @Test func tapProjectionMapsToYZAndZXPlanes() {
        let viewport = SpaceViewportSize(width: 800, height: 600)
        let pointYZ = SpaceGeometryResolver.screenPointToWorkPlane(
            CGPoint(x: 380, y: 310),
            workPlane: .yz,
            viewportSize: viewport,
            camera: .default
        )
        #expect(pointYZ != nil)
        #expect(abs((pointYZ?.x ?? 1)) < 1e-6)

        let pointZX = SpaceGeometryResolver.screenPointToWorkPlane(
            CGPoint(x: 380, y: 310),
            workPlane: .zx,
            viewportSize: viewport,
            camera: .default
        )
        #expect(pointZX != nil)
        #expect(abs((pointZX?.y ?? 1)) < 1e-6)
    }

    @Test func rayParallelToPlaneReturnsNilWhenNoIntersection() {
        let camera = SpaceCameraState(
            target: .zero,
            distance: 10,
            yaw: 0,
            pitch: 0,
            projection: .orthographic,
            fovDegrees: 60
        )
        let viewport = SpaceViewportSize(width: 800, height: 600)
        let point = SpaceGeometryResolver.screenPointToWorkPlane(
            CGPoint(x: 400, y: 300),
            workPlane: .yz,
            viewportSize: viewport,
            camera: camera
        )
        #expect(point == nil)
    }

    @Test func planeNormalFromThreePointsForNonCollinearPointsIsValid() {
        let a = WorldPoint3D(x: 0, y: 0, z: 0)
        let b = WorldPoint3D(x: 1, y: 0, z: 0)
        let c = WorldPoint3D(x: 0, y: 1, z: 0)
        let normal = SpaceGeometryResolver.planeNormalFromThreePoints(a, b, c)
        #expect(normal != nil)
        #expect(abs((normal?.length ?? 0) - 1) < 1e-6)
        #expect(abs(normal?.z ?? 0) > 0.99)
    }

    @Test func planeNormalFromThreePointsRejectsCollinearOrTooClosePoints() {
        let a = WorldPoint3D(x: 0, y: 0, z: 0)
        let b = WorldPoint3D(x: 1, y: 1, z: 1)
        let c = WorldPoint3D(x: 2, y: 2, z: 2)
        #expect(SpaceGeometryResolver.planeNormalFromThreePoints(a, b, c) == nil)
        #expect(SpaceGeometryResolver.planeNormalFromThreePoints(a, a, c) == nil)
    }

    @MainActor
    @Test func createPoint3DCommandAddsObject() {
        let state = makeSpaceState()
        let payload = PointPayload(point: WorldPoint3D(x: 1, y: 2, z: 0))
        let json = encode(payload)
        state.dispatch(.moduleSpecific(id: "space.createPoint3D", payload: json))

        #expect(state.document.objects.count == 1)
        let object = state.document.objects[0]
        #expect(object.geometryDefinition?.kind == .point3D)
        #expect(object.geometryDefinition?.point3D == payload.point)
        #expect(state.selectedObjectIDs.contains(object.id))
    }

    @MainActor
    @Test func createSegment3DCommandAddsObject() {
        let state = makeSpaceState()
        let payload = SegmentPayload(
            pointA: WorldPoint3D(x: 0, y: 0, z: 0),
            pointB: WorldPoint3D(x: 2, y: 1, z: 0)
        )
        let json = encode(payload)
        state.dispatch(.moduleSpecific(id: "space.createSegment3D", payload: json))

        #expect(state.document.objects.count == 1)
        let object = state.document.objects[0]
        #expect(object.geometryDefinition?.kind == .segment3D)
        #expect(object.geometryDefinition?.point3D == payload.pointA)
        #expect(object.geometryDefinition?.pointB3D == payload.pointB)
        #expect(object.geometryDependency == nil)
        #expect(state.selectedObjectIDs.contains(object.id))
    }

    @MainActor
    @Test func createPoint3DUndoRedoWorks() {
        let state = makeSpaceState()
        let payload = PointPayload(point: WorldPoint3D(x: -2, y: 3, z: 0))
        state.dispatch(.moduleSpecific(id: "space.createPoint3D", payload: encode(payload)))
        #expect(state.document.objects.count == 1)
        #expect(state.undoDepth == 1)

        state.dispatch(.undo)
        #expect(state.document.objects.isEmpty)
        state.dispatch(.redo)
        #expect(state.document.objects.count == 1)
        #expect(state.document.objects[0].geometryDefinition?.kind == .point3D)
    }

    @MainActor
    @Test func createSegment3DUndoRedoWorks() {
        let state = makeSpaceState()
        let payload = SegmentPayload(
            pointA: WorldPoint3D(x: -1, y: -1, z: 0),
            pointB: WorldPoint3D(x: 1, y: 1, z: 0)
        )
        state.dispatch(.moduleSpecific(id: "space.createSegment3D", payload: encode(payload)))
        #expect(state.document.objects.count == 1)
        #expect(state.undoDepth == 1)

        state.dispatch(.undo)
        #expect(state.document.objects.isEmpty)
        state.dispatch(.redo)
        #expect(state.document.objects.count == 1)
        #expect(state.document.objects[0].geometryDefinition?.kind == .segment3D)
    }

    @MainActor
    @Test func createLine3DCommandAddsObject() {
        let state = makeSpaceState()
        let payload = LinePayload(
            point: WorldPoint3D(x: 0, y: 0, z: 0),
            direction: Vector3D(x: 1, y: 2, z: 0)
        )
        let json = encode(payload)
        state.dispatch(.moduleSpecific(id: "space.createLine3D", payload: json))

        #expect(state.document.objects.count == 1)
        let object = state.document.objects[0]
        #expect(object.type == .line)
        #expect(object.geometryDefinition?.kind == .line3D)
        #expect(object.geometryDefinition?.point3D == payload.point)
        #expect(object.geometryDefinition?.vector3D == payload.direction)
        #expect(object.geometryDependency == nil)
        #expect(state.selectedObjectIDs.contains(object.id))
    }

    @MainActor
    @Test func createLine3DRejectsTooShortDirection() {
        let state = makeSpaceState()
        let payload = LinePayload(
            point: WorldPoint3D(x: 0, y: 0, z: 0),
            direction: Vector3D.zero
        )
        state.dispatch(.moduleSpecific(id: "space.createLine3D", payload: encode(payload)))
        #expect(state.document.objects.isEmpty)
    }

    @MainActor
    @Test func createLine3DUndoRedoWorks() {
        let state = makeSpaceState()
        let payload = LinePayload(
            point: WorldPoint3D(x: -1, y: 1, z: 0),
            direction: Vector3D(x: 3, y: -2, z: 0)
        )
        state.dispatch(.moduleSpecific(id: "space.createLine3D", payload: encode(payload)))
        #expect(state.document.objects.count == 1)
        #expect(state.undoDepth == 1)

        state.dispatch(.undo)
        #expect(state.document.objects.isEmpty)
        state.dispatch(.redo)
        #expect(state.document.objects.count == 1)
        #expect(state.document.objects[0].geometryDefinition?.kind == .line3D)
    }

    @MainActor
    @Test func createPlane3DCommandAddsObjectWithNormalizedNormal() {
        let state = makeSpaceState()
        let payload = PlanePayload(
            point: WorldPoint3D(x: 1, y: 2, z: 3),
            normal: Vector3D(x: 0, y: 3, z: 4)
        )
        state.dispatch(.moduleSpecific(id: "space.createPlane3D", payload: encode(payload)))

        #expect(state.document.objects.count == 1)
        let object = state.document.objects[0]
        #expect(object.geometryDefinition?.kind == .plane3D)
        #expect(object.geometryDefinition?.point3D == payload.point)
        #expect(object.geometryDefinition?.vector3D == payload.normal.normalized())
        #expect(object.geometryDependency == nil)
        #expect(state.selectedObjectIDs.contains(object.id))
    }

    @MainActor
    @Test func createPlane3DRejectsInvalidNormal() {
        let state = makeSpaceState()
        let payload = PlanePayload(
            point: WorldPoint3D(x: 0, y: 0, z: 0),
            normal: .zero
        )
        state.dispatch(.moduleSpecific(id: "space.createPlane3D", payload: encode(payload)))
        #expect(state.document.objects.isEmpty)
    }

    @MainActor
    @Test func createPlane3DUndoRedoWorks() {
        let state = makeSpaceState()
        let payload = PlanePayload(
            point: WorldPoint3D(x: -1, y: 0.5, z: 2),
            normal: Vector3D(x: 1, y: -2, z: 1)
        )
        state.dispatch(.moduleSpecific(id: "space.createPlane3D", payload: encode(payload)))
        #expect(state.document.objects.count == 1)
        #expect(state.undoDepth == 1)

        state.dispatch(.undo)
        #expect(state.document.objects.isEmpty)
        state.dispatch(.redo)
        #expect(state.document.objects.count == 1)
        #expect(state.document.objects[0].geometryDefinition?.kind == .plane3D)
    }

    @MainActor
    @Test func saveLoadRoundTripAfterToolCreationWorks() throws {
        let state = makeSpaceState()
        state.dispatch(.moduleSpecific(
            id: "space.createPoint3D",
            payload: encode(PointPayload(point: WorldPoint3D(x: 3, y: 4, z: 0)))
        ))
        state.dispatch(.moduleSpecific(
            id: "space.createSegment3D",
            payload: encode(SegmentPayload(
                pointA: WorldPoint3D(x: 0, y: 0, z: 0),
                pointB: WorldPoint3D(x: 1, y: 1, z: 0)
            ))
        ))
        let data = try EMathicaPackageCodec.makeEncoder().encode(state.document)
        let decoded = try EMathicaPackageCodec.makeDecoder().decode(EMathicaDocument.self, from: data)
        #expect(decoded.objects.count == 2)
        #expect(decoded.objects.contains(where: { $0.geometryDefinition?.kind == .point3D }))
        #expect(decoded.objects.contains(where: { $0.geometryDefinition?.kind == .segment3D }))

        state.dispatch(.moduleSpecific(
            id: "space.createLine3D",
            payload: encode(LinePayload(
                point: WorldPoint3D(x: 2, y: 2, z: 0),
                direction: Vector3D(x: 0, y: 1, z: 0)
            ))
        ))
        state.dispatch(.moduleSpecific(
            id: "space.createPlane3D",
            payload: encode(PlanePayload(
                point: WorldPoint3D(x: 0, y: 0, z: 0),
                normal: Vector3D(x: 0, y: 0, z: 1)
            ))
        ))
        let dataWithLine = try EMathicaPackageCodec.makeEncoder().encode(state.document)
        let decodedWithLine = try EMathicaPackageCodec.makeDecoder().decode(EMathicaDocument.self, from: dataWithLine)
        #expect(decodedWithLine.objects.contains(where: { $0.geometryDefinition?.kind == .line3D }))
        #expect(decodedWithLine.objects.contains(where: { $0.geometryDefinition?.kind == .plane3D }))
    }

    @MainActor
    private func makeSpaceState() -> WorkspaceState {
        let now = Date()
        let document = EMathicaDocument(
            metadata: ProjectMetadata(
                title: "space-tools",
                moduleID: "space",
                createdAt: now,
                updatedAt: now,
                calculatorType: "space"
            ),
            moduleID: "space",
            objects: [],
            spaceCameraState: .default
        )
        let provider = SpaceWorkspaceModuleProvider()
        return WorkspaceState(
            module: .space,
            document: document,
            toolGroups: provider.toolGroups,
            moduleProvider: provider
        )
    }

    private func encode<T: Encodable>(_ value: T) -> String {
        let encoder = JSONEncoder()
        let data = (try? encoder.encode(value)) ?? Data()
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

private struct PointPayload: Codable {
    var point: WorldPoint3D
}

private struct SegmentPayload: Codable {
    var pointA: WorldPoint3D
    var pointB: WorldPoint3D
}

private struct LinePayload: Codable {
    var point: WorldPoint3D
    var direction: Vector3D
}

private struct PlanePayload: Codable {
    var point: WorldPoint3D
    var normal: Vector3D
}
