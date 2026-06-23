import EMathicaMathCore
import Foundation

enum PlaneConstructionPreview: Hashable {
    case temporarySegment(start: WorldPoint, current: WorldPoint)
    case temporaryLine(pointA: WorldPoint, pointB: WorldPoint)
    case temporaryRay(start: WorldPoint, through: WorldPoint)
    case temporaryCircle(center: WorldPoint, currentRadiusPoint: WorldPoint)
    case temporaryArc(pointA: WorldPoint, pointB: WorldPoint, pointC: WorldPoint)
    case temporaryIntersections(points: [WorldPoint])
}
