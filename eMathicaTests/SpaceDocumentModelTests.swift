import Foundation
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct SpaceDocumentModelTests {
    @Test func point3DGeometryDefinitionRoundTrip() throws {
        let definition = GeometryDefinition(
            kind: .point3D,
            point3D: WorldPoint3D(x: 1, y: 2, z: 3)
        )
        let data = try EMathicaPackageCodec.makeEncoder().encode(definition)
        let decoded = try EMathicaPackageCodec.makeDecoder().decode(GeometryDefinition.self, from: data)
        #expect(decoded == definition)
    }

    @Test func segment3DGeometryDefinitionRoundTrip() throws {
        let definition = GeometryDefinition(
            kind: .segment3D,
            point3D: WorldPoint3D(x: 1, y: 2, z: 3),
            pointB3D: WorldPoint3D(x: 4, y: 5, z: 6)
        )
        let data = try EMathicaPackageCodec.makeEncoder().encode(definition)
        let decoded = try EMathicaPackageCodec.makeDecoder().decode(GeometryDefinition.self, from: data)
        #expect(decoded == definition)
    }

    @Test func line3DGeometryDefinitionRoundTrip() throws {
        let definition = GeometryDefinition(
            kind: .line3D,
            point3D: WorldPoint3D(x: -1, y: 2, z: 3),
            vector3D: Vector3D(x: 0.5, y: 1.0, z: -2.0)
        )
        let data = try EMathicaPackageCodec.makeEncoder().encode(definition)
        let decoded = try EMathicaPackageCodec.makeDecoder().decode(GeometryDefinition.self, from: data)
        #expect(decoded == definition)
    }

    @Test func plane3DGeometryDefinitionRoundTrip() throws {
        let definition = GeometryDefinition(
            kind: .plane3D,
            point3D: WorldPoint3D(x: 0, y: 1, z: 2),
            vector3D: Vector3D(x: 0, y: 1, z: 0)
        )
        let data = try EMathicaPackageCodec.makeEncoder().encode(definition)
        let decoded = try EMathicaPackageCodec.makeDecoder().decode(GeometryDefinition.self, from: data)
        #expect(decoded == definition)
    }

    @Test func documentRoundTripPreservesSpaceCameraStateAnd3DObjects() throws {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "Space 3D",
            moduleID: "space",
            createdAt: now,
            updatedAt: now,
            calculatorType: "space"
        )
        let camera = SpaceCameraState(
            target: WorldPoint3D(x: 1, y: 2, z: 3),
            distance: 20,
            yaw: 0.3,
            pitch: 0.2,
            projection: .orthographic,
            fovDegrees: 45
        )
        let object = MathObject(
            name: "A3D",
            type: .point,
            expression: MathExpression(displayText: "A3D"),
            geometryDefinition: GeometryDefinition(
                kind: .point3D,
                point3D: WorldPoint3D(x: 2, y: 3, z: 4)
            ),
            style: MathStyle(colorToken: "blue")
        )
        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "space",
            objects: [object],
            spaceCameraState: camera
        )

        let data = try EMathicaPackageCodec.makeEncoder().encode(document)
        let decoded = try EMathicaPackageCodec.makeDecoder().decode(EMathicaDocument.self, from: data)
        #expect(decoded.spaceCameraState == camera)
        #expect(decoded.objects.first?.geometryDefinition?.kind == .point3D)
        #expect(decoded.objects.first?.geometryDefinition?.point3D == WorldPoint3D(x: 2, y: 3, z: 4))
    }

    @Test func oldStyleDocumentDecodeWithoutSpaceCameraStateIsSafe() throws {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "compat",
            moduleID: "space",
            createdAt: now,
            updatedAt: now,
            calculatorType: "space"
        )
        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "space",
            objects: []
        )
        let encoded = try EMathicaPackageCodec.makeEncoder().encode(document)
        let raw = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        var withoutCamera = raw
        withoutCamera.removeValue(forKey: "spaceCameraState")
        let compatData = try JSONSerialization.data(withJSONObject: withoutCamera, options: [])
        let decoded = try EMathicaPackageCodec.makeDecoder().decode(EMathicaDocument.self, from: compatData)
        #expect(decoded.spaceCameraState == nil)
    }

    @Test func updateSpaceCameraStateCommandUpdatesDocument() {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "command",
            moduleID: "space",
            createdAt: now,
            updatedAt: now,
            calculatorType: "space"
        )
        var document = EMathicaDocument(
            metadata: metadata,
            moduleID: "space",
            objects: []
        )
        let camera = SpaceCameraState.default.orbit(deltaYaw: 0.2, deltaPitch: 0.1)
        document.apply(.updateSpaceCameraState(camera))
        #expect(document.spaceCameraState == camera)
    }

    @Test func objectHistoryCanRoundTrip3DObjectRecord() throws {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "history-3d",
            moduleID: "space",
            createdAt: now,
            updatedAt: now,
            calculatorType: "space"
        )
        let removedObject = MathObject(
            name: "L3D",
            type: .line,
            expression: MathExpression(displayText: "L3D"),
            geometryDefinition: GeometryDefinition(
                kind: .line3D,
                point3D: WorldPoint3D(x: 0, y: 0, z: 0),
                vector3D: Vector3D(x: 1, y: 1, z: 1)
            ),
            style: MathStyle(colorToken: "purple")
        )
        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "space",
            objects: [],
            deletedObjectHistory: [DeletedObjectRecord(object: removedObject, context: .userDelete)]
        )
        let data = try EMathicaPackageCodec.makeEncoder().encode(document)
        let decoded = try EMathicaPackageCodec.makeDecoder().decode(EMathicaDocument.self, from: data)
        #expect(decoded.deletedObjectHistory?.first?.object.geometryDefinition?.kind == .line3D)
    }
}
