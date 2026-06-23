import EMathicaMathCore
import Foundation

enum PlaneIntersectionPreviewResolver {
    private static let allowedTypes: Set<MathObjectType> = [.segment, .line, .ray, .circle]

    static func previewPoints(
        firstObjectID: UUID,
        secondObjectID: UUID,
        objects: [MathObject]
    ) -> [WorldPoint] {
        guard firstObjectID != secondObjectID else { return [] }
        guard let firstObject = objects.first(where: { $0.id == firstObjectID }),
              let secondObject = objects.first(where: { $0.id == secondObjectID }) else {
            return []
        }
        guard firstObject.isVisible, secondObject.isVisible else { return [] }
        guard allowedTypes.contains(firstObject.type), allowedTypes.contains(secondObject.type) else {
            return []
        }
        guard let firstPrimitive = PlaneGeometryResolver.intersectionPrimitive(for: firstObject, in: objects),
              let secondPrimitive = PlaneGeometryResolver.intersectionPrimitive(for: secondObject, in: objects) else {
            return []
        }
        return PlaneIntersectionSolver.intersections(firstPrimitive, secondPrimitive)
            .filter { $0.x.isFinite && $0.y.isFinite }
    }
}
