import Foundation
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct ProjectPreviewRendererTests {
    @Test func thumbnailBoundsForEmptyDocumentFallsBackToDefault() throws {
        let bounds = ProjectPreviewRenderer.thumbnailBounds(for: makeDocument(objects: []))
        #expect(bounds.minX == -10)
        #expect(bounds.maxX == 10)
        #expect(bounds.minY == -10)
        #expect(bounds.maxY == 10)
    }

    @Test func thumbnailBoundsForSinglePointExpandsToMinimumSpan() throws {
        let point = MathObject(
            name: "P",
            type: .point,
            expression: MathExpression(displayText: "P=(12,8)"),
            position: WorldPoint(x: 12, y: 8),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "red")
        )
        let bounds = ProjectPreviewRenderer.thumbnailBounds(for: makeDocument(objects: [point]))
        #expect(bounds.minX < 12)
        #expect(bounds.maxX > 12)
        #expect(bounds.minY < 8)
        #expect(bounds.maxY > 8)
        #expect(bounds.width >= 4)
        #expect(bounds.height >= 4)
    }

    @Test func thumbnailBoundsFollowFarAwayFiniteContent() throws {
        let a = MathObject(
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(100,100)"),
            position: WorldPoint(x: 100, y: 100),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "green")
        )
        let b = MathObject(
            name: "B",
            type: .point,
            expression: MathExpression(displayText: "B=(110,104)"),
            position: WorldPoint(x: 110, y: 104),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "blue")
        )
        let bounds = ProjectPreviewRenderer.thumbnailBounds(for: makeDocument(objects: [a, b]))
        let centerX = (bounds.minX + bounds.maxX) * 0.5
        let centerY = (bounds.minY + bounds.maxY) * 0.5
        #expect(bounds.minX < 100)
        #expect(bounds.maxX > 110)
        #expect(bounds.minY < 100)
        #expect(bounds.maxY > 104)
        #expect(abs(centerX - 105) < 0.01)
        #expect(abs(centerY - 102) < 0.01)
    }

    @Test func thumbnailBoundsIncludeCircleExtents() throws {
        let circle = MathObject(
            name: "c",
            type: .circle,
            expression: MathExpression(displayText: "c"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 5, y: 0)],
            geometryDefinition: GeometryDefinition(
                kind: .circle,
                anchors: [
                    .fixedPoint(WorldPoint(x: 0, y: 0)),
                    .fixedPoint(WorldPoint(x: 5, y: 0))
                ]
            ),
            style: MathStyle(colorToken: "purple")
        )
        let bounds = ProjectPreviewRenderer.thumbnailBounds(for: makeDocument(objects: [circle]))
        #expect(bounds.minX <= -5)
        #expect(bounds.maxX >= 5)
        #expect(bounds.minY <= -5)
        #expect(bounds.maxY >= 5)
    }

    @Test func thumbnailBoundsIgnoreLineAndRayOnlyDocuments() throws {
        let line = MathObject(
            name: "l",
            type: .line,
            expression: MathExpression(displayText: "line"),
            points: [WorldPoint(x: 100, y: 100), WorldPoint(x: 200, y: 220)],
            geometryDefinition: GeometryDefinition(
                kind: .line,
                anchors: [
                    .fixedPoint(WorldPoint(x: 100, y: 100)),
                    .fixedPoint(WorldPoint(x: 200, y: 220))
                ]
            ),
            style: MathStyle(colorToken: "blue")
        )
        let ray = MathObject(
            name: "r",
            type: .ray,
            expression: MathExpression(displayText: "ray"),
            points: [WorldPoint(x: -50, y: -40), WorldPoint(x: 80, y: 90)],
            geometryDefinition: GeometryDefinition(
                kind: .ray,
                anchors: [
                    .fixedPoint(WorldPoint(x: -50, y: -40)),
                    .fixedPoint(WorldPoint(x: 80, y: 90))
                ]
            ),
            style: MathStyle(colorToken: "red")
        )
        let bounds = ProjectPreviewRenderer.thumbnailBounds(for: makeDocument(objects: [line, ray]))
        #expect(bounds.minX == -10)
        #expect(bounds.maxX == 10)
        #expect(bounds.minY == -10)
        #expect(bounds.maxY == 10)
    }

    @Test func thumbnailBoundsIgnoreInvalidCoordinates() throws {
        let invalid = MathObject(
            name: "I",
            type: .point,
            expression: MathExpression(displayText: "I"),
            position: WorldPoint(x: .nan, y: .infinity),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "orange")
        )
        let bounds = ProjectPreviewRenderer.thumbnailBounds(for: makeDocument(objects: [invalid]))
        #expect(bounds.minX == -10)
        #expect(bounds.maxX == 10)
        #expect(bounds.minY == -10)
        #expect(bounds.maxY == 10)
    }

    @Test func previewWithLineObjectIsNonEmpty() throws {
        let line = MathObject(
            name: "l",
            type: .line,
            expression: MathExpression(displayText: "line((0,0),(1,1))"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 1, y: 1)],
            geometryDefinition: GeometryDefinition(
                kind: .line,
                anchors: [
                    .fixedPoint(WorldPoint(x: 0, y: 0)),
                    .fixedPoint(WorldPoint(x: 1, y: 1))
                ]
            ),
            style: MathStyle(colorToken: "red", lineWidth: 3)
        )
        let data = ProjectPreviewRenderer.renderPNGData(for: makeDocument(objects: [line]))
        #expect(data != nil)
        #expect(data?.isEmpty == false)
    }

    @Test func previewWithRayObjectIsNonEmpty() throws {
        let ray = MathObject(
            name: "r",
            type: .ray,
            expression: MathExpression(displayText: "ray((0,0),(2,1))"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 2, y: 1)],
            geometryDefinition: GeometryDefinition(
                kind: .ray,
                anchors: [
                    .fixedPoint(WorldPoint(x: 0, y: 0)),
                    .fixedPoint(WorldPoint(x: 2, y: 1))
                ]
            ),
            style: MathStyle(colorToken: "blue", lineWidth: 2.5, lineStyle: .dashed)
        )
        let data = ProjectPreviewRenderer.renderPNGData(for: makeDocument(objects: [ray]))
        #expect(data != nil)
        #expect(data?.isEmpty == false)
    }

    @Test func previewWithCircleObjectIsNonEmpty() throws {
        let analysis = AlgebraCore.analyzePlaneLatex("x^2+y^2=4")
        let circle = MathObject(
            name: "c",
            type: .circle,
            expression: .algebra(analysis),
            style: MathStyle(colorToken: "green", lineWidth: 2)
        )
        let data = ProjectPreviewRenderer.renderPNGData(for: makeDocument(objects: [circle]))
        #expect(data != nil)
        #expect(data?.isEmpty == false)
    }

    @Test func previewWithImplicitEquationIsNonEmpty() throws {
        let analysis = AlgebraCore.analyzePlaneLatex("x^2+y^2=1")
        let function = MathObject(
            name: "f",
            type: .function,
            expression: .algebra(analysis),
            style: MathStyle(colorToken: "purple", lineWidth: 2)
        )
        let data = ProjectPreviewRenderer.renderPNGData(for: makeDocument(objects: [function]))
        #expect(data != nil)
        #expect(data?.isEmpty == false)
    }

    @Test func hiddenObjectIsIgnored() throws {
        let baseline = try #require(ProjectPreviewRenderer.renderPNGData(for: makeDocument(objects: [])))
        let hidden = MathObject(
            name: "h",
            type: .segment,
            expression: MathExpression(displayText: "segment"),
            points: [WorldPoint(x: -1, y: -1), WorldPoint(x: 1, y: 1)],
            style: MathStyle(colorToken: "red"),
            isVisible: false
        )
        let rendered = try #require(ProjectPreviewRenderer.renderPNGData(for: makeDocument(objects: [hidden])))
        #expect(rendered == baseline)
    }

    @Test func parameterObjectDoesNotDrawStandaloneContent() throws {
        let baseline = try #require(ProjectPreviewRenderer.renderPNGData(for: makeDocument(objects: [])))
        let parameter = MathObject(
            name: "a",
            type: .parameter,
            expression: MathExpression(displayText: "a=2"),
            parameterValue: 2,
            style: MathStyle(colorToken: "orange")
        )
        let rendered = try #require(ProjectPreviewRenderer.renderPNGData(for: makeDocument(objects: [parameter])))
        #expect(rendered == baseline)
    }

    @Test func styleAffectsRenderedPreview() throws {
        let segment = MathObject(
            name: "s",
            type: .segment,
            expression: MathExpression(displayText: "segment"),
            points: [WorldPoint(x: -2, y: -2), WorldPoint(x: 2, y: 2)],
            style: MathStyle(colorToken: "blue", lineWidth: 2, lineStyle: .solid)
        )
        let dashed = MathObject(
            id: segment.id,
            name: segment.name,
            type: segment.type,
            expression: segment.expression,
            position: segment.position,
            points: segment.points,
            parameterValue: segment.parameterValue,
            parameterMin: segment.parameterMin,
            parameterMax: segment.parameterMax,
            sliderSettings: segment.sliderSettings,
            geometryDefinition: segment.geometryDefinition,
            style: MathStyle(colorToken: "red", lineWidth: 5, lineStyle: .dashed),
            isVisible: true
        )
        let first = try #require(ProjectPreviewRenderer.renderPNGData(for: makeDocument(objects: [segment])))
        let second = try #require(ProjectPreviewRenderer.renderPNGData(for: makeDocument(objects: [dashed])))
        #expect(first != second)
    }

    @Test func previewSkipsNoSolutionDerivedPoint() throws {
        let baseline = try #require(ProjectPreviewRenderer.renderPNGData(for: makeDocument(objects: [])))
        let derivedNoSolution = MathObject(
            name: "I",
            type: .point,
            expression: MathExpression(displayText: "I=(1,1)"),
            position: WorldPoint(x: 1, y: 1),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .intersectionOf(objectAID: UUID(), objectBID: UUID(), index: 0)),
            geometryDefinitionStatus: .noSolution,
            style: MathStyle(colorToken: "yellowOrange")
        )
        let rendered = try #require(ProjectPreviewRenderer.renderPNGData(for: makeDocument(objects: [derivedNoSolution])))
        #expect(rendered == baseline)
    }

    @Test func previewRendersDefinedDynamicCircleAndIntersections() throws {
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
            expression: MathExpression(displayText: "T=(2,0)"),
            position: WorldPoint(x: 2, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "pink")
        )
        let circle = MathObject(
            id: UUID(),
            name: "c1",
            type: .circle,
            expression: MathExpression(displayText: "c1: 圆"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 2, y: 0)],
            geometryDefinition: GeometryDefinition(kind: .circle, anchors: [.object(c.id), .object(t.id)]),
            geometryDependency: GeometryDependency(kind: .circleByCenterPoint(centerPointID: c.id, throughPointID: t.id)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "green")
        )
        let i0 = MathObject(
            name: "I0",
            type: .point,
            expression: MathExpression(displayText: "I0=(2,0)"),
            position: WorldPoint(x: 2, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .intersectionOf(objectAID: UUID(), objectBID: circle.id, index: 0)),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "yellowOrange")
        )
        let data = ProjectPreviewRenderer.renderPNGData(for: makeDocument(objects: [c, t, circle, i0]))
        #expect(data != nil)
        #expect(data?.isEmpty == false)
    }

    @Test func previewIgnoresDeletedObjectHistory() throws {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "Preview History",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        let historyObject = MathObject(
            name: "H",
            type: .line,
            expression: MathExpression(displayText: "h"),
            points: [WorldPoint(x: -10, y: -10), WorldPoint(x: 10, y: 10)],
            geometryDefinition: GeometryDefinition(kind: .line, anchors: [.fixedPoint(WorldPoint(x: -10, y: -10)), .fixedPoint(WorldPoint(x: 10, y: 10))]),
            style: MathStyle(colorToken: "red", lineWidth: 6)
        )
        let withHistory = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: [],
            deletedObjectHistory: [DeletedObjectRecord(object: historyObject, context: .userDelete)]
        )
        let withoutHistory = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: []
        )
        let first = try #require(ProjectPreviewRenderer.renderPNGData(for: withHistory))
        let second = try #require(ProjectPreviewRenderer.renderPNGData(for: withoutHistory))
        #expect(first == second)
    }

    @Test func previewRenders3DGeometryObjectsWhenPresent() throws {
        let baseline = try #require(ProjectPreviewRenderer.renderPNGData(for: makeDocument(objects: [])))
        let object3D = MathObject(
            name: "P3D",
            type: .point,
            expression: MathExpression(displayText: "P3D"),
            geometryDefinition: GeometryDefinition(
                kind: .point3D,
                point3D: WorldPoint3D(x: 1, y: 2, z: 3)
            ),
            style: MathStyle(colorToken: "red")
        )
        let rendered = try #require(ProjectPreviewRenderer.renderPNGData(for: makeDocument(objects: [object3D])))
        #expect(rendered != baseline)
    }

    @Test func spacePreviewRendersPoint3D() throws {
        let object3D = MathObject(
            name: "P3D",
            type: .point,
            expression: MathExpression(displayText: "P3D"),
            geometryDefinition: GeometryDefinition(
                kind: .point3D,
                point3D: WorldPoint3D(x: 1, y: 2, z: 3)
            ),
            style: MathStyle(colorToken: "red")
        )
        let rendered = ProjectPreviewRenderer.renderPNGData(for: makeSpaceDocument(objects: [object3D]))
        #expect(rendered != nil)
        #expect(rendered?.isEmpty == false)
    }

    @Test func spacePreviewUsesStoredCameraState() throws {
        let segment3D = MathObject(
            name: "S3D",
            type: .segment,
            expression: MathExpression(displayText: "S3D"),
            geometryDefinition: GeometryDefinition(
                kind: .segment3D,
                point3D: WorldPoint3D(x: -1, y: 0, z: 0),
                pointB3D: WorldPoint3D(x: 1, y: 0, z: 0)
            ),
            style: MathStyle(colorToken: "blue")
        )
        let defaultCameraDoc = makeSpaceDocument(objects: [segment3D], camera: nil)
        let customCameraDoc = makeSpaceDocument(
            objects: [segment3D],
            camera: SpaceCameraState.default.orbit(deltaYaw: 0.9, deltaPitch: -0.4).zoom(delta: 2.4)
        )
        let first = try #require(ProjectPreviewRenderer.renderPNGData(for: defaultCameraDoc))
        let second = try #require(ProjectPreviewRenderer.renderPNGData(for: customCameraDoc))
        #expect(first != second)
    }

    @Test func spacePreviewRendersPlane3D() throws {
        let plane3D = MathObject(
            name: "Pi",
            type: .function,
            expression: MathExpression(displayText: "plane"),
            geometryDefinition: GeometryDefinition(
                kind: .plane3D,
                point3D: WorldPoint3D(x: 0, y: 0, z: 0),
                vector3D: Vector3D(x: 0, y: 1, z: 0)
            ),
            style: MathStyle(colorToken: "indigo")
        )
        let rendered = ProjectPreviewRenderer.renderPNGData(for: makeSpaceDocument(objects: [plane3D]))
        #expect(rendered != nil)
        #expect(rendered?.isEmpty == false)
    }

    @Test func spacePreviewSkipsInvalid3DGeometryWithoutCrash() throws {
        let invalidPlane3D = MathObject(
            name: "BadPlane",
            type: .function,
            expression: MathExpression(displayText: "bad plane"),
            geometryDefinition: GeometryDefinition(
                kind: .plane3D,
                point3D: .zero,
                vector3D: .zero
            ),
            style: MathStyle(colorToken: "green")
        )
        let baseline = try #require(ProjectPreviewRenderer.renderPNGData(for: makeSpaceDocument(objects: [])))
        let rendered = try #require(ProjectPreviewRenderer.renderPNGData(for: makeSpaceDocument(objects: [invalidPlane3D])))
        #expect(rendered == baseline)
    }

    private func makeDocument(objects: [MathObject]) -> EMathicaDocument {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "Preview Test",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        return EMathicaDocument(metadata: metadata, moduleID: "plane", objects: objects)
    }

    private func makeSpaceDocument(objects: [MathObject], camera: SpaceCameraState? = nil) -> EMathicaDocument {
        let now = Date()
        let metadata = ProjectMetadata(
            title: "Space Preview Test",
            moduleID: "space",
            createdAt: now,
            updatedAt: now,
            calculatorType: "space"
        )
        return EMathicaDocument(
            metadata: metadata,
            moduleID: "space",
            objects: objects,
            spaceCameraState: camera
        )
    }
}
