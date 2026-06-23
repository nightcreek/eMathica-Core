import EMathicaMathCore
import EMathicaWorkspaceKit

struct PlaneGeometryPresentationResolver: GeometryPresentationResolverProtocol {
    func pointPosition(for object: MathObject) -> WorldPoint? {
        PlaneGeometryResolver.pointPosition(for: object)
    }

    func segmentEndpoints(for object: MathObject, in objects: [MathObject]) -> (WorldPoint, WorldPoint)? {
        PlaneGeometryResolver.segmentEndpoints(for: object, in: objects)
    }

    func linePoints(for object: MathObject, in objects: [MathObject]) -> (WorldPoint, WorldPoint)? {
        PlaneGeometryResolver.linePoints(for: object, in: objects)
    }

    func rayPoints(for object: MathObject, in objects: [MathObject]) -> (WorldPoint, WorldPoint)? {
        PlaneGeometryResolver.rayPoints(for: object, in: objects)
    }

    func circleGeometry(for object: MathObject, in objects: [MathObject]) -> (center: WorldPoint, radius: Double)? {
        PlaneGeometryResolver.circleGeometry(for: object, in: objects)
    }
}
