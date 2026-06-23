import Foundation
import SwiftUI
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct SpaceCanvasTests {
    @Test func wireframeRendererBuildsPrimitivesForPointSegmentLinePlane() {
        let point3D = MathObject(
            name: "P",
            type: .point,
            expression: MathExpression(displayText: "P"),
            geometryDefinition: GeometryDefinition(
                kind: .point3D,
                point3D: WorldPoint3D(x: 0, y: 0, z: 0)
            ),
            style: MathStyle(colorToken: "white")
        )
        let segment3D = MathObject(
            name: "S",
            type: .segment,
            expression: MathExpression(displayText: "S"),
            geometryDefinition: GeometryDefinition(
                kind: .segment3D,
                point3D: WorldPoint3D(x: -1, y: 0, z: 0),
                pointB3D: WorldPoint3D(x: 1, y: 0, z: 0)
            ),
            style: MathStyle(colorToken: "white")
        )
        let line3D = MathObject(
            name: "L",
            type: .line,
            expression: MathExpression(displayText: "L"),
            geometryDefinition: GeometryDefinition(
                kind: .line3D,
                point3D: WorldPoint3D(x: 0, y: 0, z: 0),
                vector3D: Vector3D(x: 1, y: 1, z: 0)
            ),
            style: MathStyle(colorToken: "white")
        )
        let plane3D = MathObject(
            name: "A",
            type: .function,
            expression: MathExpression(displayText: "A"),
            geometryDefinition: GeometryDefinition(
                kind: .plane3D,
                point3D: WorldPoint3D(x: 0, y: 0, z: 0),
                vector3D: Vector3D(x: 0, y: 1, z: 0)
            ),
            style: MathStyle(colorToken: "white")
        )

        let scene = SpaceWireframeRenderer.buildScene(
            objects: [point3D, segment3D, line3D, plane3D],
            camera: .default,
            viewport: SpaceViewportSize(width: 600, height: 400)
        )

        #expect(scene.points.count >= 1)
        #expect(scene.segments.count >= 10) // axes + segment + line + plane edges + grid
        #expect(scene.polygons.contains { $0.style == .plane })
        #expect(scene.points.contains { $0.sourceObjectID == point3D.id })
        #expect(scene.segments.contains { $0.sourceObjectID == segment3D.id && $0.hitKind == .segment })
        #expect(scene.segments.contains { $0.sourceObjectID == line3D.id && $0.hitKind == .line })
        #expect(scene.labels.contains { $0.text == "X" })
        #expect(scene.labels.contains { $0.text == "Y" })
        #expect(scene.labels.contains { $0.text == "Z" })
        #expect(scene.segments.contains { $0.style == .axisX })
        #expect(scene.segments.contains { $0.style == .axisY })
        #expect(scene.segments.contains { $0.style == .axisZ })
        #expect(scene.segments.contains { $0.style == .plane })
    }

    @Test func wireframeRendererSkipsInvalid3DPayloadWithoutCrash() {
        let invalidLine = MathObject(
            name: "L0",
            type: .line,
            expression: MathExpression(displayText: "L0"),
            geometryDefinition: GeometryDefinition(
                kind: .line3D,
                point3D: WorldPoint3D(x: 0, y: 0, z: 0),
                vector3D: .zero
            ),
            style: MathStyle(colorToken: "white")
        )
        let invalidPlane = MathObject(
            name: "A0",
            type: .function,
            expression: MathExpression(displayText: "A0"),
            geometryDefinition: GeometryDefinition(
                kind: .plane3D,
                point3D: WorldPoint3D(x: 0, y: 0, z: 0),
                vector3D: .zero
            ),
            style: MathStyle(colorToken: "white")
        )
        let scene = SpaceWireframeRenderer.buildScene(
            objects: [invalidLine, invalidPlane],
            camera: .default,
            viewport: SpaceViewportSize(width: 600, height: 400)
        )
        #expect(scene.points.isEmpty)
        #expect(scene.segments.count >= 3) // axes remain
    }

    @Test func spaceCanvasStyleUsesLightAndDarkBackground() {
        #expect(SpaceCanvasStyle.usesDarkBackground(for: .dark))
        #expect(!SpaceCanvasStyle.usesDarkBackground(for: .light))
    }

    @Test func space3DObjectTypeFallbackLabelsAreReadable() {
        let plane = MathObject(
            name: "Π",
            type: .function,
            expression: MathExpression(displayText: "plane"),
            geometryDefinition: GeometryDefinition(
                kind: .plane3D,
                point3D: .zero,
                vector3D: Vector3D(x: 0, y: 1, z: 0)
            ),
            style: MathStyle(colorToken: "white")
        )
        let line = MathObject(
            name: "l",
            type: .line,
            expression: MathExpression(displayText: "line"),
            geometryDefinition: GeometryDefinition(
                kind: .line3D,
                point3D: .zero,
                vector3D: Vector3D(x: 1, y: 0, z: 0)
            ),
            style: MathStyle(colorToken: "white")
        )
        #expect(GeometryDependencyPresentation.objectTypeFallbackLabel(for: plane) == "空间平面")
        #expect(GeometryDependencyPresentation.objectTypeFallbackLabel(for: line) == "空间直线")
    }

    @Test func expressionLikeZEqYIsNotPretendedAsPlane3D() {
        let expressionObject = MathObject(
            name: "f",
            type: .function,
            expression: MathExpression(displayText: "z=y"),
            geometryDefinition: nil,
            style: MathStyle(colorToken: "white")
        )
        #expect(GeometryDependencyPresentation.objectTypeFallbackLabel(for: expressionObject) == MathObjectType.function.rawValue)
    }

    @MainActor
    @Test func spaceCameraInteractionCoalescesUndoIntoSingleStep() {
        let now = Date()
        let document = EMathicaDocument(
            metadata: ProjectMetadata(
                title: "space-undo",
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
        let state = WorkspaceState(
            module: .space,
            document: document,
            toolGroups: provider.toolGroups,
            moduleProvider: provider
        )

        state.dispatch(.setCanvasInteracting(true))
        let c1 = SpaceCameraState.default.orbit(deltaYaw: 0.2, deltaPitch: 0.1)
        let c2 = c1.zoom(delta: -2)
        state.dispatch(.setSpaceCameraState(c1))
        state.dispatch(.setSpaceCameraState(c2))
        #expect(state.undoDepth == 0)
        state.dispatch(.setCanvasInteracting(false))
        #expect(state.undoDepth == 1)
        #expect(state.document.spaceCameraState == c2)

        state.dispatch(.undo)
        #expect(state.document.spaceCameraState == .default)
        state.dispatch(.redo)
        #expect(state.document.spaceCameraState == c2)
    }
}
