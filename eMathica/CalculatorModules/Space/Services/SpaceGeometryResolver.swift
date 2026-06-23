import EMathicaMathCore
import CoreGraphics
import Foundation

enum SpaceGeometryResolver {
    static func planeNormalFromThreePoints(
        _ a: WorldPoint3D,
        _ b: WorldPoint3D,
        _ c: WorldPoint3D,
        epsilon: Double = 1e-8
    ) -> Vector3D? {
        let ab = b - a
        let ac = c - a
        guard ab.length > epsilon, ac.length > epsilon else { return nil }
        let normal = ab.cross(ac)
        guard normal.length > epsilon else { return nil }
        return normal.normalized()
    }

    static func snappedOrWorkPlanePoint(
        screenPoint: CGPoint,
        objects: [MathObject],
        scene: SpaceWireframeScene,
        viewportSize: SpaceViewportSize,
        camera: SpaceCameraState,
        workPlane: SpaceWorkPlane,
        pointSnapThreshold: Double = 12
    ) -> WorldPoint3D? {
        if let hit = SpaceHitTestService.hitTestPointOnly(
            tapPoint: screenPoint,
            scene: scene,
            threshold: pointSnapThreshold
        ),
           let object = objects.first(where: { $0.id == hit.objectID }),
           object.geometryDefinition?.kind == .point3D,
           let snappedPoint = object.geometryDefinition?.point3D {
            return snappedPoint
        }

        return screenPointToWorkPlane(
            screenPoint,
            workPlane: workPlane,
            viewportSize: viewportSize,
            camera: camera
        )
    }

    static func screenPointToWorkPlane(
        _ screenPoint: CGPoint,
        workPlane: SpaceWorkPlane,
        viewportSize: SpaceViewportSize,
        camera: SpaceCameraState,
        orthographicPointsPerUnit: Double = 60
    ) -> WorldPoint3D? {
        let ray = cameraRay(
            through: screenPoint,
            viewportSize: viewportSize,
            camera: camera,
            orthographicPointsPerUnit: orthographicPointsPerUnit
        )
        return intersectRayWithWorkPlane(
            origin: ray.origin,
            direction: ray.direction,
            workPlane: workPlane
        )
    }

    static func screenPointToWorkPlaneZ0(
        _ screenPoint: CGPoint,
        viewportSize: SpaceViewportSize,
        camera: SpaceCameraState,
        orthographicPointsPerUnit: Double = 60
    ) -> WorldPoint3D? {
        screenPointToWorkPlane(
            screenPoint,
            workPlane: .xy,
            viewportSize: viewportSize,
            camera: camera,
            orthographicPointsPerUnit: orthographicPointsPerUnit
        )
    }

    static func intersectRayWithWorkPlane(
        origin: WorldPoint3D,
        direction: Vector3D,
        workPlane: SpaceWorkPlane,
        epsilon: Double = 1e-9
    ) -> WorldPoint3D? {
        guard direction.length > epsilon else { return nil }

        let numerator: Double
        let denominator: Double
        switch workPlane {
        case .xy:
            numerator = -origin.z
            denominator = direction.z
        case .yz:
            numerator = -origin.x
            denominator = direction.x
        case .zx:
            numerator = -origin.y
            denominator = direction.y
        }

        guard abs(denominator) > epsilon else { return nil }
        let t = numerator / denominator
        guard t.isFinite else { return nil }
        return origin + direction * t
    }

    static func cameraRay(
        through screenPoint: CGPoint,
        viewportSize: SpaceViewportSize,
        camera: SpaceCameraState,
        orthographicPointsPerUnit: Double = 60
    ) -> (origin: WorldPoint3D, direction: Vector3D) {
        let centerX = viewportSize.width * 0.5
        let centerY = viewportSize.height * 0.5
        let dx = Double(screenPoint.x) - centerX
        let dy = centerY - Double(screenPoint.y)

        switch camera.projection {
        case .orthographic:
            let unit = orthographicPointsPerUnit > 0 ? orthographicPointsPerUnit : 60
            let worldOffset = camera.right * (dx / unit) + camera.up * (dy / unit)
            let origin = camera.position + worldOffset
            return (origin, camera.forward)

        case .perspective:
            let width = max(1e-6, viewportSize.width)
            let height = max(1e-6, viewportSize.height)
            let ndcX = (Double(screenPoint.x) / width) * 2 - 1
            let ndcY = 1 - (Double(screenPoint.y) / height) * 2
            let fov = camera.clampedFovDegrees * .pi / 180
            let tanHalfFov = tan(fov * 0.5)
            let aspect = width / height

            let dirCamera = Vector3D(
                x: ndcX * aspect * tanHalfFov,
                y: ndcY * tanHalfFov,
                z: 1
            ).normalized()

            let worldDirection = (
                camera.right * dirCamera.x +
                camera.up * dirCamera.y +
                camera.forward * dirCamera.z
            ).normalized()
            return (camera.position, worldDirection)
        }
    }
}
