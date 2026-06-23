import EMathicaMathCore
import Foundation

enum PlaneConstructionMode: Hashable {
    case none

    case segmentSecondPoint(startWorldPoint: WorldPoint, startPointID: UUID?)
    case midpointSecondPoint(firstPointID: UUID, firstWorldPoint: WorldPoint)
    case lineSecondPoint(startWorldPoint: WorldPoint, startPointID: UUID?)
    case raySecondPoint(startWorldPoint: WorldPoint, startPointID: UUID?)
    case parallelSecondPoint(referenceObjectID: UUID)
    case parallelSecondReference(pointID: UUID, pointWorldPoint: WorldPoint)
    case perpendicularSecondPoint(referenceObjectID: UUID)
    case perpendicularSecondReference(pointID: UUID, pointWorldPoint: WorldPoint)
    case intersectionSecondObject(firstObjectID: UUID)

    case circleCenter
    case circleRadius(centerPointID: UUID?)

    case arcFirstPoint
    case arcSecondPoint(firstWorldPoint: WorldPoint, firstPointID: UUID?)
    case arcThirdPoint(firstWorldPoint: WorldPoint, firstPointID: UUID?,
                       secondWorldPoint: WorldPoint, secondPointID: UUID?)

    case functionInput
    case curveInput
}
