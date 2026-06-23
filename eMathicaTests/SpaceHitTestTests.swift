import CoreGraphics
import Foundation
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct SpaceHitTestTests {
    @Test func pointHitWithinThresholdReturnsPointObject() {
        let id = UUID()
        let scene = SpaceWireframeScene(
            points: [
                SpaceWireframePoint(
                    sourceObjectID: id,
                    projected: ProjectedPoint2D(x: 100, y: 100, depth: 2, isVisible: true),
                    style: .point,
                    hitKind: .point
                )
            ],
            segments: [],
            polygons: [],
            labels: []
        )

        let hit = SpaceHitTestService.hitTest(tapPoint: CGPoint(x: 105, y: 104), scene: scene)
        #expect(hit?.objectID == id)
    }

    @Test func pointOutsideThresholdReturnsNil() {
        let scene = SpaceWireframeScene(
            points: [
                SpaceWireframePoint(
                    sourceObjectID: UUID(),
                    projected: ProjectedPoint2D(x: 100, y: 100, depth: 2, isVisible: true),
                    style: .point,
                    hitKind: .point
                )
            ],
            segments: [],
            polygons: [],
            labels: []
        )
        let hit = SpaceHitTestService.hitTest(tapPoint: CGPoint(x: 200, y: 200), scene: scene)
        #expect(hit == nil)
    }

    @Test func segmentHitReturnsSegmentObject() {
        let id = UUID()
        let scene = SpaceWireframeScene(
            points: [],
            segments: [
                SpaceWireframeSegment(
                    sourceObjectID: id,
                    start: ProjectedPoint2D(x: 10, y: 10, depth: 2, isVisible: true),
                    end: ProjectedPoint2D(x: 110, y: 10, depth: 2, isVisible: true),
                    averageDepth: 2,
                    style: .object,
                    hitKind: .segment
                )
            ],
            polygons: [],
            labels: []
        )
        let hit = SpaceHitTestService.hitTest(tapPoint: CGPoint(x: 60, y: 14), scene: scene)
        #expect(hit?.objectID == id)
    }

    @Test func pointBeatsSegmentWhenBothHit() {
        let pointID = UUID()
        let segmentID = UUID()
        let scene = SpaceWireframeScene(
            points: [
                SpaceWireframePoint(
                    sourceObjectID: pointID,
                    projected: ProjectedPoint2D(x: 50, y: 50, depth: 3, isVisible: true),
                    style: .point,
                    hitKind: .point
                )
            ],
            segments: [
                SpaceWireframeSegment(
                    sourceObjectID: segmentID,
                    start: ProjectedPoint2D(x: 20, y: 50, depth: 1, isVisible: true),
                    end: ProjectedPoint2D(x: 80, y: 50, depth: 1, isVisible: true),
                    averageDepth: 1,
                    style: .object,
                    hitKind: .segment
                )
            ],
            polygons: [],
            labels: []
        )
        let hit = SpaceHitTestService.hitTest(tapPoint: CGPoint(x: 52, y: 50), scene: scene)
        #expect(hit?.objectID == pointID)
    }

    @Test func nearerDepthWinsForSamePriority() {
        let nearID = UUID()
        let farID = UUID()
        let scene = SpaceWireframeScene(
            points: [],
            segments: [
                SpaceWireframeSegment(
                    sourceObjectID: farID,
                    start: ProjectedPoint2D(x: 0, y: 0, depth: 10, isVisible: true),
                    end: ProjectedPoint2D(x: 100, y: 0, depth: 10, isVisible: true),
                    averageDepth: 10,
                    style: .object,
                    hitKind: .segment
                ),
                SpaceWireframeSegment(
                    sourceObjectID: nearID,
                    start: ProjectedPoint2D(x: 0, y: 0, depth: 2, isVisible: true),
                    end: ProjectedPoint2D(x: 100, y: 0, depth: 2, isVisible: true),
                    averageDepth: 2,
                    style: .object,
                    hitKind: .segment
                )
            ],
            polygons: [],
            labels: []
        )
        let hit = SpaceHitTestService.hitTest(tapPoint: CGPoint(x: 50, y: 3), scene: scene)
        #expect(hit?.objectID == nearID)
    }

    @Test func planeFillDoesNotCauseHitWithoutEdgeSegments() {
        let planeID = UUID()
        let scene = SpaceWireframeScene(
            points: [],
            segments: [],
            polygons: [
                SpaceWireframePolygon(
                    sourceObjectID: planeID,
                    corners: [
                        ProjectedPoint2D(x: 0, y: 0, depth: 3, isVisible: true),
                        ProjectedPoint2D(x: 100, y: 0, depth: 3, isVisible: true),
                        ProjectedPoint2D(x: 100, y: 100, depth: 3, isVisible: true),
                        ProjectedPoint2D(x: 0, y: 100, depth: 3, isVisible: true)
                    ],
                    style: .plane
                )
            ],
            labels: []
        )
        let hit = SpaceHitTestService.hitTest(tapPoint: CGPoint(x: 50, y: 50), scene: scene)
        #expect(hit == nil)
    }

    @Test func pointOnlyHitReturnsPointAndIgnoresSegment() {
        let pointID = UUID()
        let segmentID = UUID()
        let scene = SpaceWireframeScene(
            points: [
                SpaceWireframePoint(
                    sourceObjectID: pointID,
                    projected: ProjectedPoint2D(x: 40, y: 40, depth: 2, isVisible: true),
                    style: .point,
                    hitKind: .point
                )
            ],
            segments: [
                SpaceWireframeSegment(
                    sourceObjectID: segmentID,
                    start: ProjectedPoint2D(x: 20, y: 40, depth: 1, isVisible: true),
                    end: ProjectedPoint2D(x: 80, y: 40, depth: 1, isVisible: true),
                    averageDepth: 1,
                    style: .object,
                    hitKind: .segment
                )
            ],
            polygons: [],
            labels: []
        )
        let hit = SpaceHitTestService.hitTestPointOnly(
            tapPoint: CGPoint(x: 42, y: 41),
            scene: scene
        )
        #expect(hit?.objectID == pointID)
    }

    @Test func snappedOrWorkPlaneUsesExistingPoint3DWhenNear() {
        let pointID = UUID()
        let snapped = WorldPoint3D(x: 3, y: 4, z: 5)
        let objects = [
            MathObject(
                id: pointID,
                name: "P",
                type: .point,
                expression: MathExpression(displayText: "P"),
                geometryDefinition: GeometryDefinition(
                    kind: .point3D,
                    point3D: snapped
                ),
                style: MathStyle(colorToken: "white")
            )
        ]

        let scene = SpaceWireframeScene(
            points: [
                SpaceWireframePoint(
                    sourceObjectID: pointID,
                    projected: ProjectedPoint2D(x: 100, y: 100, depth: 2, isVisible: true),
                    style: .point,
                    hitKind: .point
                )
            ],
            segments: [],
            polygons: [],
            labels: []
        )

        let result = SpaceGeometryResolver.snappedOrWorkPlanePoint(
            screenPoint: CGPoint(x: 102, y: 98),
            objects: objects,
            scene: scene,
            viewportSize: SpaceViewportSize(width: 800, height: 600),
            camera: .default,
            workPlane: .xy
        )
        #expect(result == snapped)
    }

    @Test func snappedOrWorkPlaneFallsBackToZ0WhenNoPointHit() {
        let scene = SpaceWireframeScene(points: [], segments: [], polygons: [], labels: [])
        let screen = CGPoint(x: 400, y: 300)
        let viewport = SpaceViewportSize(width: 800, height: 600)
        let result = SpaceGeometryResolver.snappedOrWorkPlanePoint(
            screenPoint: screen,
            objects: [],
            scene: scene,
            viewportSize: viewport,
            camera: .default,
            workPlane: .xy
        )
        #expect(result != nil)
        #expect(abs((result?.z ?? 1)) < 1e-6)
    }

    @Test func snappedOrWorkPlaneFallsBackToActiveWorkPlaneWhenNoPointHit() {
        let scene = SpaceWireframeScene(points: [], segments: [], polygons: [], labels: [])
        let screen = CGPoint(x: 400, y: 300)
        let viewport = SpaceViewportSize(width: 800, height: 600)
        let resultYZ = SpaceGeometryResolver.snappedOrWorkPlanePoint(
            screenPoint: screen,
            objects: [],
            scene: scene,
            viewportSize: viewport,
            camera: .default,
            workPlane: .yz
        )
        #expect(resultYZ != nil)
        #expect(abs((resultYZ?.x ?? 1)) < 1e-6)
    }
}
