import EMathicaMathCore
import Foundation

struct PlaneInteractionState: Hashable {
    var activeConstruction: PlaneConstructionMode?
    var pendingPointID: UUID?
    var pendingWorldPoint: WorldPoint?
    var constructionPreview: PlaneConstructionPreview?

    var isDraggingObject: Bool
    var draggingObjectID: UUID?

    init(
        activeConstruction: PlaneConstructionMode? = nil,
        pendingPointID: UUID? = nil,
        pendingWorldPoint: WorldPoint? = nil,
        constructionPreview: PlaneConstructionPreview? = nil,
        isDraggingObject: Bool = false,
        draggingObjectID: UUID? = nil
    ) {
        self.activeConstruction = activeConstruction
        self.pendingPointID = pendingPointID
        self.pendingWorldPoint = pendingWorldPoint
        self.constructionPreview = constructionPreview
        self.isDraggingObject = isDraggingObject
        self.draggingObjectID = draggingObjectID
    }
}

extension PlaneInteractionState {
    var constructionHintText: String? {
        guard let activeConstruction else { return nil }

        switch activeConstruction {
        case .segmentSecondPoint:
            return "线段：选择第二个点"
        case .lineSecondPoint:
            return "直线：选择第二个点"
        case .raySecondPoint:
            return "射线：选择方向点"
        case .midpointSecondPoint:
            return "中点：选择第二个点"
        case .circleRadius:
            return "圆：选择圆上一点"
        case .arcSecondPoint:
            return "圆弧：选择第二个点"
        case .arcThirdPoint:
            return "圆弧：选择第三个点"
        case .intersectionSecondObject:
            return "交点：选择第二个对象"
        case .parallelSecondPoint:
            return "平行线：选择第二个对象"
        case .parallelSecondReference:
            return "平行线：选择目标点"
        case .perpendicularSecondPoint:
            return "垂线：选择第二个对象"
        case .perpendicularSecondReference:
            return "垂线：选择目标点"
        case .circleCenter, .arcFirstPoint, .functionInput, .curveInput, .none:
            return nil
        }
    }

    var hasConstructionHint: Bool {
        constructionHintText != nil
    }

    mutating func clearConstructionProgress() {
        activeConstruction = nil
        pendingPointID = nil
        pendingWorldPoint = nil
        constructionPreview = nil
    }
}
