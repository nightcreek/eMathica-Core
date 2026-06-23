import EMathicaDocumentKit
import EMathicaMathCore
import Foundation

enum SpaceWireframeHitKind: Hashable {
    case point
    case segment
    case line
    case planeEdge
}

struct SpaceWireframePoint: Hashable {
    var sourceObjectID: UUID?
    var projected: ProjectedPoint2D
    var style: SpaceWireframeStyle
    var hitKind: SpaceWireframeHitKind?
}

struct SpaceWireframeSegment: Hashable {
    var sourceObjectID: UUID?
    var start: ProjectedPoint2D
    var end: ProjectedPoint2D
    var averageDepth: Double
    var style: SpaceWireframeStyle
    var hitKind: SpaceWireframeHitKind?
}

struct SpaceWireframePolygon: Hashable {
    var sourceObjectID: UUID?
    var corners: [ProjectedPoint2D]
    var style: SpaceWireframeStyle
}

struct SpaceWireframeLabel: Hashable {
    var text: String
    var projected: ProjectedPoint2D
    var style: SpaceWireframeStyle
}

enum SpaceWireframeStyle: Hashable {
    case axisX
    case axisY
    case axisZ
    case object
    case plane
    case point
}

struct SpaceWireframeScene: Hashable {
    var points: [SpaceWireframePoint]
    var segments: [SpaceWireframeSegment]
    var polygons: [SpaceWireframePolygon]
    var labels: [SpaceWireframeLabel]
}

enum SpaceWireframeRenderer {
    static func buildScene(
        objects: [MathObject],
        camera: SpaceCameraState,
        viewport: SpaceViewportSize
    ) -> SpaceWireframeScene {
        var points: [SpaceWireframePoint] = []
        var segments: [SpaceWireframeSegment] = []
        var polygons: [SpaceWireframePolygon] = []
        var labels: [SpaceWireframeLabel] = []

        appendAxes(into: &segments, labels: &labels, camera: camera, viewport: viewport)

        for object in objects {
            guard object.isVisible else { continue }
            guard let definition = object.geometryDefinition else { continue }
            switch definition.kind {
            case .point3D:
                guard let p = definition.point3D else { continue }
                guard let projected = projectVisible(point: p, camera: camera, viewport: viewport) else { continue }
                points.append(
                    SpaceWireframePoint(
                        sourceObjectID: object.id,
                        projected: projected,
                        style: .point,
                        hitKind: .point
                    )
                )
            case .segment3D:
                guard let a = definition.point3D, let b = definition.pointB3D else { continue }
                appendSegment3D(
                    sourceObjectID: object.id,
                    start: a,
                    end: b,
                    style: .object,
                    hitKind: .segment,
                    camera: camera,
                    viewport: viewport,
                    into: &segments
                )
            case .line3D:
                guard let anchor = definition.point3D,
                      let direction = definition.vector3D?.normalized(),
                      direction.length > 0 else { continue }
                let lineHalfLength = max(10, camera.clampedDistance * 3)
                let start = anchor + direction * (-lineHalfLength)
                let end = anchor + direction * lineHalfLength
                appendSegment3D(
                    sourceObjectID: object.id,
                    start: start,
                    end: end,
                    style: .object,
                    hitKind: .line,
                    camera: camera,
                    viewport: viewport,
                    into: &segments
                )
            case .plane3D:
                appendPlaneWireframe(
                    sourceObjectID: object.id,
                    definition: definition,
                    camera: camera,
                    viewport: viewport,
                    intoPolygons: &polygons,
                    into: &segments
                )
            case .point, .segment, .line, .ray, .circle, .arc:
                continue
            }
        }

        return SpaceWireframeScene(points: points, segments: segments, polygons: polygons, labels: labels)
    }

    private static func appendAxes(
        into segments: inout [SpaceWireframeSegment],
        labels: inout [SpaceWireframeLabel],
        camera: SpaceCameraState,
        viewport: SpaceViewportSize
    ) {
        let axisLength = max(8, camera.clampedDistance * 1.1)
        let labelOffset = max(0.6, axisLength * 0.06)
        let xEnd = WorldPoint3D(x: axisLength, y: 0, z: 0)
        let yEnd = WorldPoint3D(x: 0, y: axisLength, z: 0)
        let zEnd = WorldPoint3D(x: 0, y: 0, z: axisLength)

        appendSegment3D(
            sourceObjectID: nil,
            start: WorldPoint3D(x: -axisLength, y: 0, z: 0),
            end: xEnd,
            style: .axisX,
            hitKind: nil,
            camera: camera,
            viewport: viewport,
            into: &segments,
            preferVisibleByClipping: true
        )
        appendSegment3D(
            sourceObjectID: nil,
            start: WorldPoint3D(x: 0, y: -axisLength, z: 0),
            end: yEnd,
            style: .axisY,
            hitKind: nil,
            camera: camera,
            viewport: viewport,
            into: &segments,
            preferVisibleByClipping: true
        )
        appendSegment3D(
            sourceObjectID: nil,
            start: WorldPoint3D(x: 0, y: 0, z: -axisLength),
            end: zEnd,
            style: .axisZ,
            hitKind: nil,
            camera: camera,
            viewport: viewport,
            into: &segments,
            preferVisibleByClipping: true
        )

        appendLabel(text: "X", at: xEnd + Vector3D(x: labelOffset, y: 0, z: 0), style: .axisX, camera: camera, viewport: viewport, into: &labels)
        appendLabel(text: "Y", at: yEnd + Vector3D(x: 0, y: labelOffset, z: 0), style: .axisY, camera: camera, viewport: viewport, into: &labels)
        appendLabel(text: "Z", at: zEnd + Vector3D(x: 0, y: 0, z: labelOffset), style: .axisZ, camera: camera, viewport: viewport, into: &labels)
    }

    private static func appendPlaneWireframe(
        sourceObjectID: UUID,
        definition: GeometryDefinition,
        camera: SpaceCameraState,
        viewport: SpaceViewportSize,
        intoPolygons polygons: inout [SpaceWireframePolygon],
        into segments: inout [SpaceWireframeSegment]
    ) {
        guard let center = definition.point3D,
              let normal = definition.vector3D?.normalized(),
              normal.length > 0 else { return }

        let reference: Vector3D = abs(normal.dot(.worldUp)) > 0.95
            ? Vector3D(x: 1, y: 0, z: 0)
            : .worldUp
        let u = normal.cross(reference).normalized()
        guard u.length > 0 else { return }
        let v = normal.cross(u).normalized()
        guard v.length > 0 else { return }

        let half = max(6, camera.clampedDistance * 0.85)
        let c0 = center + u * half + v * half
        let c1 = center + u * half + v * (-half)
        let c2 = center + u * (-half) + v * (-half)
        let c3 = center + u * (-half) + v * half

        if let p0 = projectVisible(point: c0, camera: camera, viewport: viewport),
           let p1 = projectVisible(point: c1, camera: camera, viewport: viewport),
           let p2 = projectVisible(point: c2, camera: camera, viewport: viewport),
           let p3 = projectVisible(point: c3, camera: camera, viewport: viewport) {
            polygons.append(
                SpaceWireframePolygon(
                    sourceObjectID: sourceObjectID,
                    corners: [p0, p1, p2, p3],
                    style: .plane
                )
            )
        }

        appendSegment3D(sourceObjectID: sourceObjectID, start: c0, end: c1, style: .plane, hitKind: .planeEdge, camera: camera, viewport: viewport, into: &segments, preferVisibleByClipping: true)
        appendSegment3D(sourceObjectID: sourceObjectID, start: c1, end: c2, style: .plane, hitKind: .planeEdge, camera: camera, viewport: viewport, into: &segments, preferVisibleByClipping: true)
        appendSegment3D(sourceObjectID: sourceObjectID, start: c2, end: c3, style: .plane, hitKind: .planeEdge, camera: camera, viewport: viewport, into: &segments, preferVisibleByClipping: true)
        appendSegment3D(sourceObjectID: sourceObjectID, start: c3, end: c0, style: .plane, hitKind: .planeEdge, camera: camera, viewport: viewport, into: &segments, preferVisibleByClipping: true)

        let gridCount = 3
        for i in 1...gridCount {
            let t = (Double(i) / Double(gridCount + 1)) * 2 - 1
            let alongUStart = center + (u * (t * half)) + (v * (-half))
            let alongUEnd = center + (u * (t * half)) + (v * half)
            appendSegment3D(sourceObjectID: sourceObjectID, start: alongUStart, end: alongUEnd, style: .plane, hitKind: .planeEdge, camera: camera, viewport: viewport, into: &segments, preferVisibleByClipping: true)

            let alongVStart = center + (v * (t * half)) + (u * (-half))
            let alongVEnd = center + (v * (t * half)) + (u * half)
            appendSegment3D(sourceObjectID: sourceObjectID, start: alongVStart, end: alongVEnd, style: .plane, hitKind: .planeEdge, camera: camera, viewport: viewport, into: &segments, preferVisibleByClipping: true)
        }
    }

    private static func appendSegment3D(
        sourceObjectID: UUID?,
        start: WorldPoint3D,
        end: WorldPoint3D,
        style: SpaceWireframeStyle,
        hitKind: SpaceWireframeHitKind?,
        camera: SpaceCameraState,
        viewport: SpaceViewportSize,
        into segments: inout [SpaceWireframeSegment],
        preferVisibleByClipping: Bool = false
    ) {
        if preferVisibleByClipping, camera.projection == .perspective,
           let clipped = clipSegmentToNearPlane(start: start, end: end, camera: camera) {
            guard let a = projectVisible(point: clipped.0, camera: camera, viewport: viewport),
                  let b = projectVisible(point: clipped.1, camera: camera, viewport: viewport) else { return }
            segments.append(
                SpaceWireframeSegment(
                    sourceObjectID: sourceObjectID,
                    start: a,
                    end: b,
                    averageDepth: (a.depth + b.depth) * 0.5,
                    style: style,
                    hitKind: hitKind
                )
            )
            return
        }

        guard let a = projectVisible(point: start, camera: camera, viewport: viewport),
              let b = projectVisible(point: end, camera: camera, viewport: viewport) else {
            return
        }
        segments.append(
            SpaceWireframeSegment(
                sourceObjectID: sourceObjectID,
                start: a,
                end: b,
                averageDepth: (a.depth + b.depth) * 0.5,
                style: style,
                hitKind: hitKind
            )
        )
    }

    private static func projectVisible(
        point: WorldPoint3D,
        camera: SpaceCameraState,
        viewport: SpaceViewportSize
    ) -> ProjectedPoint2D? {
        let projected = camera.project(point, viewportSize: viewport)
        return projected.isVisible ? projected : nil
    }

    private static func appendLabel(
        text: String,
        at point: WorldPoint3D,
        style: SpaceWireframeStyle,
        camera: SpaceCameraState,
        viewport: SpaceViewportSize,
        into labels: inout [SpaceWireframeLabel]
    ) {
        guard let projected = projectVisible(point: point, camera: camera, viewport: viewport) else { return }
        labels.append(SpaceWireframeLabel(text: text, projected: projected, style: style))
    }

    private static func clipSegmentToNearPlane(
        start: WorldPoint3D,
        end: WorldPoint3D,
        camera: SpaceCameraState
    ) -> (WorldPoint3D, WorldPoint3D)? {
        let near: Double = 1e-4
        let a = cameraCoordinates(for: start, camera: camera)
        let b = cameraCoordinates(for: end, camera: camera)

        if a.z <= near && b.z <= near {
            return nil
        }

        var ca = a
        var cb = b
        if ca.z <= near || cb.z <= near {
            let t = (near - ca.z) / (cb.z - ca.z)
            let ix = ca.x + (cb.x - ca.x) * t
            let iy = ca.y + (cb.y - ca.y) * t
            let iz = near
            if ca.z <= near {
                ca = (ix, iy, iz)
            } else {
                cb = (ix, iy, iz)
            }
        }

        return (
            worldPoint(fromCamera: ca, camera: camera),
            worldPoint(fromCamera: cb, camera: camera)
        )
    }

    private static func cameraCoordinates(
        for point: WorldPoint3D,
        camera: SpaceCameraState
    ) -> (x: Double, y: Double, z: Double) {
        let rel = point - camera.position
        return (
            rel.dot(camera.right),
            rel.dot(camera.up),
            rel.dot(camera.forward)
        )
    }

    private static func worldPoint(
        fromCamera c: (x: Double, y: Double, z: Double),
        camera: SpaceCameraState
    ) -> WorldPoint3D {
        camera.position + (camera.right * c.x) + (camera.up * c.y) + (camera.forward * c.z)
    }
}
