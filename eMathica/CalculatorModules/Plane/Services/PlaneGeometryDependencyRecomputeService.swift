import EMathicaDocumentKit
import EMathicaMathCore
import Foundation

enum PlaneGeometryDependencyRecomputeService {
    static func directlyAffectedDerivedObjectIDs(
        objects: [MathObject],
        candidateSourceIDs: Set<UUID>
    ) -> Set<UUID> {
        guard !candidateSourceIDs.isEmpty else { return [] }
        var affected: Set<UUID> = []
        for object in objects {
            guard let dependency = object.geometryDependency else { continue }
            if dependency.referencesAny(in: candidateSourceIDs) {
                affected.insert(object.id)
            }
        }
        affected.subtract(candidateSourceIDs)
        return affected
    }

    static func downstreamAffectedDerivedObjectIDs(
        objects: [MathObject],
        candidateSourceIDs: Set<UUID>
    ) -> Set<UUID> {
        guard !candidateSourceIDs.isEmpty else { return [] }
        var visitedSources = candidateSourceIDs
        var frontier = candidateSourceIDs
        var affected: Set<UUID> = []

        while !frontier.isEmpty {
            var nextFrontier: Set<UUID> = []
            for object in objects {
                guard let dependency = object.geometryDependency else { continue }
                guard dependency.referencesAny(in: frontier) else { continue }
                guard !candidateSourceIDs.contains(object.id) else { continue }
                if affected.insert(object.id).inserted,
                   !visitedSources.contains(object.id) {
                    nextFrontier.insert(object.id)
                }
            }
            visitedSources.formUnion(nextFrontier)
            frontier = nextFrontier
        }

        return affected
    }

    static func midpointPatches(
        objects: [MathObject],
        changedSourceIDs: Set<UUID>
    ) -> [(UUID, DocumentObjectPatch)] {
        dependencyPatches(objects: objects, changedSourceIDs: changedSourceIDs).filter { _, patch in
            patch.position != nil
        }
    }

    static func dependencyPatches(
        objects: [MathObject],
        changedSourceIDs: Set<UUID>
    ) -> [(UUID, DocumentObjectPatch)] {
        guard !changedSourceIDs.isEmpty else { return [] }
        let objectsByID = Dictionary(uniqueKeysWithValues: objects.map { ($0.id, $0) })
        var patches: [(UUID, DocumentObjectPatch)] = []

        for object in objects {
            guard let dependency = object.geometryDependency else {
                continue
            }
            switch dependency.kind {
            case .midpointOfPoints(let pointAID, let pointBID):
                guard object.type == .point else { continue }
                guard changedSourceIDs.contains(pointAID) || changedSourceIDs.contains(pointBID) else {
                    continue
                }
                guard let pointAObject = objectsByID[pointAID],
                      let pointBObject = objectsByID[pointBID],
                      pointAObject.type == .point,
                      pointBObject.type == .point,
                      let pointA = PlaneGeometryResolver.pointPosition(for: pointAObject),
                      let pointB = PlaneGeometryResolver.pointPosition(for: pointBObject) else {
                    continue
                }
                let midpoint = WorldPoint(
                    x: (pointA.x + pointB.x) * 0.5,
                    y: (pointA.y + pointB.y) * 0.5
                )
                let display = "\(object.name) = (\(format(midpoint.x)), \(format(midpoint.y)))"
                patches.append((
                    object.id,
                    DocumentObjectPatch(
                        expressionDisplayText: display,
                        position: midpoint,
                        geometryDefinitionStatus: .defined
                    )
                ))

            case .parallelLine(let referenceObjectID, let throughPointID):
                guard object.type == .line else { continue }
                appendDerivedLinePatches(
                    mode: .parallel,
                    derivedLine: object,
                    referenceObjectID: referenceObjectID,
                    throughPointID: throughPointID,
                    objects: objects,
                    objectsByID: objectsByID,
                    changedSourceIDs: changedSourceIDs,
                    into: &patches
                )

            case .perpendicularLine(let referenceObjectID, let throughPointID):
                guard object.type == .line else { continue }
                appendDerivedLinePatches(
                    mode: .perpendicular,
                    derivedLine: object,
                    referenceObjectID: referenceObjectID,
                    throughPointID: throughPointID,
                    objects: objects,
                    objectsByID: objectsByID,
                    changedSourceIDs: changedSourceIDs,
                    into: &patches
                )

            case .intersectionOf(let objectAID, let objectBID, let index):
                guard object.type == .point else { continue }
                appendIntersectionPatches(
                    derivedPoint: object,
                    objectAID: objectAID,
                    objectBID: objectBID,
                    index: index,
                    objects: objects,
                    objectsByID: objectsByID,
                    changedSourceIDs: changedSourceIDs,
                    into: &patches
                )

            case .circleByCenterPoint(let centerPointID, let throughPointID):
                guard object.type == .circle else { continue }
                appendCirclePatches(
                    derivedCircle: object,
                    centerPointID: centerPointID,
                    throughPointID: throughPointID,
                    objectsByID: objectsByID,
                    changedSourceIDs: changedSourceIDs,
                    into: &patches
                )
            case .circleByCenterRadius(let centerPointID, let radius):
                guard object.type == .circle else { continue }
                appendCircleByCenterRadiusPatches(
                    derivedCircle: object,
                    centerPointID: centerPointID,
                    radius: radius,
                    objectsByID: objectsByID,
                    changedSourceIDs: changedSourceIDs,
                    into: &patches
                )
            case .arcByThreePoints(let pointAID, let pointBID, let pointCID):
                guard object.type == .arc else { continue }
                appendArcByThreePointsPatches(
                    derivedArc: object,
                    pointAID: pointAID, pointBID: pointBID, pointCID: pointCID,
                    objectsByID: objectsByID,
                    changedSourceIDs: changedSourceIDs,
                    into: &patches
                )
            }
        }

        return patches
    }

    static func dependencyCleanupPatchesForRemovedSources(
        objects: [MathObject],
        removedSourceIDs: Set<UUID>
    ) -> [(UUID, DocumentObjectPatch)] {
        guard !removedSourceIDs.isEmpty else { return [] }
        var patches: [(UUID, DocumentObjectPatch)] = []
        for object in objects {
            guard let dependency = object.geometryDependency else { continue }
            let shouldClear: Bool
            switch dependency.kind {
            case .midpointOfPoints(let pointAID, let pointBID):
                shouldClear = removedSourceIDs.contains(pointAID) || removedSourceIDs.contains(pointBID)
            case .parallelLine(let referenceObjectID, let throughPointID):
                shouldClear = removedSourceIDs.contains(referenceObjectID) || removedSourceIDs.contains(throughPointID)
            case .perpendicularLine(let referenceObjectID, let throughPointID):
                shouldClear = removedSourceIDs.contains(referenceObjectID) || removedSourceIDs.contains(throughPointID)
            case .intersectionOf(let objectAID, let objectBID, _):
                shouldClear = removedSourceIDs.contains(objectAID) || removedSourceIDs.contains(objectBID)
            case .circleByCenterPoint(let centerPointID, let throughPointID):
                shouldClear = removedSourceIDs.contains(centerPointID) || removedSourceIDs.contains(throughPointID)
            case .circleByCenterRadius(let centerPointID, _):
                shouldClear = removedSourceIDs.contains(centerPointID)
            case .arcByThreePoints(let pointAID, let pointBID, let pointCID):
                shouldClear = removedSourceIDs.contains(pointAID)
                    || removedSourceIDs.contains(pointBID)
                    || removedSourceIDs.contains(pointCID)
            }
            if shouldClear {
                patches.append((
                    object.id,
                    DocumentObjectPatch(
                        clearGeometryDependency: true,
                        clearGeometryDefinitionStatus: true
                    )
                ))
            }
        }
        return patches
    }

    private enum DerivedLineMode {
        case parallel
        case perpendicular
    }

    private static func appendDerivedLinePatches(
        mode: DerivedLineMode,
        derivedLine: MathObject,
        referenceObjectID: UUID,
        throughPointID: UUID,
        objects: [MathObject],
        objectsByID: [UUID: MathObject],
        changedSourceIDs: Set<UUID>,
        into patches: inout [(UUID, DocumentObjectPatch)]
    ) {
        guard let referenceObject = objectsByID[referenceObjectID],
              referenceObject.isVisible,
              let throughPointObject = objectsByID[throughPointID],
              throughPointObject.type == .point,
              let throughPoint = PlaneGeometryResolver.pointPosition(for: throughPointObject),
              let referencePoints = PlaneGeometryResolver.lineLikePoints(for: referenceObject, in: objects) else {
            patches.append((
                derivedLine.id,
                DocumentObjectPatch(geometryDefinitionStatus: .missingSource)
            ))
            return
        }

        let referenceAnchorIDs = Set(referenceObject.geometryDefinition?.anchors.compactMap(\.objectID) ?? [])
        let affectedByReferenceAnchorChange = !referenceAnchorIDs.isDisjoint(with: changedSourceIDs)
        guard changedSourceIDs.contains(throughPointID) ||
                changedSourceIDs.contains(referenceObjectID) ||
                affectedByReferenceAnchorChange else {
            return
        }

        let dx = referencePoints.1.x - referencePoints.0.x
        let dy = referencePoints.1.y - referencePoints.0.y
        guard dx.isFinite, dy.isFinite else {
            patches.append((
                derivedLine.id,
                DocumentObjectPatch(geometryDefinitionStatus: .invalid)
            ))
            return
        }
        let magnitudeSquared = dx * dx + dy * dy
        guard magnitudeSquared > 1e-18 else {
            patches.append((
                derivedLine.id,
                DocumentObjectPatch(geometryDefinitionStatus: .invalid)
            ))
            return
        }

        let direction: WorldPoint
        switch mode {
        case .parallel:
            direction = WorldPoint(x: dx, y: dy)
        case .perpendicular:
            direction = WorldPoint(x: -dy, y: dx)
        }
        guard direction.x.isFinite, direction.y.isFinite,
              direction.x * direction.x + direction.y * direction.y > 1e-18 else {
            patches.append((
                derivedLine.id,
                DocumentObjectPatch(geometryDefinitionStatus: .invalid)
            ))
            return
        }

        let targetPoint = WorldPoint(
            x: throughPoint.x + direction.x,
            y: throughPoint.y + direction.y
        )

        let geometryDefinition = GeometryDefinition(
            kind: .line,
            anchors: [
                .object(throughPointID),
                .fixedPoint(targetPoint)
            ]
        )

        patches.append((
            derivedLine.id,
            DocumentObjectPatch(
                points: [throughPoint, targetPoint],
                geometryDefinition: geometryDefinition,
                geometryDefinitionStatus: .defined
            )
        ))
    }

    private static func appendIntersectionPatches(
        derivedPoint: MathObject,
        objectAID: UUID,
        objectBID: UUID,
        index: Int,
        objects: [MathObject],
        objectsByID: [UUID: MathObject],
        changedSourceIDs: Set<UUID>,
        into patches: inout [(UUID, DocumentObjectPatch)]
    ) {
        guard index >= 0 else { return }
        guard let objectA = objectsByID[objectAID],
              let objectB = objectsByID[objectBID] else {
            patches.append((
                derivedPoint.id,
                DocumentObjectPatch(geometryDefinitionStatus: .missingSource)
            ))
            return
        }

        let objectAAnchorIDs = Set(objectA.geometryDefinition?.anchors.compactMap(\.objectID) ?? [])
        let objectBAnchorIDs = Set(objectB.geometryDefinition?.anchors.compactMap(\.objectID) ?? [])
        let affectedByAnchors = !objectAAnchorIDs.isDisjoint(with: changedSourceIDs)
            || !objectBAnchorIDs.isDisjoint(with: changedSourceIDs)
        guard changedSourceIDs.contains(objectAID)
                || changedSourceIDs.contains(objectBID)
                || affectedByAnchors else {
            return
        }

        guard let primitiveA = intersectionPrimitive(for: objectA, in: objects),
              let primitiveB = intersectionPrimitive(for: objectB, in: objects) else {
            patches.append((
                derivedPoint.id,
                DocumentObjectPatch(geometryDefinitionStatus: .unsupported)
            ))
            return
        }

        let points = PlaneIntersectionSolver.intersections(primitiveA, primitiveB)
        guard points.indices.contains(index) else {
            patches.append((
                derivedPoint.id,
                DocumentObjectPatch(geometryDefinitionStatus: .noSolution)
            ))
            return
        }

        let point = points[index]
        let display = "\(derivedPoint.name) = (\(format(point.x)), \(format(point.y)))"
        patches.append((
            derivedPoint.id,
            DocumentObjectPatch(
                expressionDisplayText: display,
                position: point,
                geometryDefinitionStatus: .defined
            )
        ))
    }

    private static func intersectionPrimitive(
        for object: MathObject,
        in objects: [MathObject]
    ) -> PlaneIntersectionPrimitive? {
        guard let primitive = PlaneGeometryResolver.intersectionPrimitive(for: object, in: objects) else {
            return nil
        }
        switch primitive {
        case .line, .ray, .segment, .circle:
            return primitive
        }
    }

    private static func appendCirclePatches(
        derivedCircle: MathObject,
        centerPointID: UUID,
        throughPointID: UUID,
        objectsByID: [UUID: MathObject],
        changedSourceIDs: Set<UUID>,
        into patches: inout [(UUID, DocumentObjectPatch)]
    ) {
        guard changedSourceIDs.contains(centerPointID) || changedSourceIDs.contains(throughPointID) else {
            return
        }
        guard let centerObject = objectsByID[centerPointID],
              let throughObject = objectsByID[throughPointID],
              centerObject.type == .point,
              throughObject.type == .point,
              let center = PlaneGeometryResolver.pointPosition(for: centerObject),
              let through = PlaneGeometryResolver.pointPosition(for: throughObject) else {
            patches.append((
                derivedCircle.id,
                DocumentObjectPatch(geometryDefinitionStatus: .missingSource)
            ))
            return
        }
        let dx = through.x - center.x
        let dy = through.y - center.y
        let radius = (dx * dx + dy * dy).squareRoot()
        guard radius.isFinite, radius > 1e-12 else {
            patches.append((
                derivedCircle.id,
                DocumentObjectPatch(geometryDefinitionStatus: .invalid)
            ))
            return
        }

        let display = "\(derivedCircle.name): 圆"
        patches.append((
            derivedCircle.id,
            DocumentObjectPatch(
                expressionDisplayText: display,
                points: [center, through],
                geometryDefinitionStatus: .defined
            )
        ))
    }

    private static func appendCircleByCenterRadiusPatches(
        derivedCircle: MathObject,
        centerPointID: UUID,
        radius: Double,
        objectsByID: [UUID: MathObject],
        changedSourceIDs: Set<UUID>,
        into patches: inout [(UUID, DocumentObjectPatch)]
    ) {
        guard changedSourceIDs.contains(centerPointID) else {
            return
        }
        guard radius.isFinite, radius > 1e-12 else {
            patches.append((
                derivedCircle.id,
                DocumentObjectPatch(geometryDefinitionStatus: .invalid)
            ))
            return
        }
        guard let centerObject = objectsByID[centerPointID],
              centerObject.type == .point,
              let center = PlaneGeometryResolver.pointPosition(for: centerObject) else {
            patches.append((
                derivedCircle.id,
                DocumentObjectPatch(geometryDefinitionStatus: .missingSource)
            ))
            return
        }

        let through = WorldPoint(x: center.x + radius, y: center.y)
        let geometryDefinition = GeometryDefinition(
            kind: .circle,
            anchors: [
                .object(centerPointID),
                .fixedPoint(through)
            ]
        )
        let display = "\(derivedCircle.name): 圆"
        patches.append((
            derivedCircle.id,
            DocumentObjectPatch(
                expressionDisplayText: display,
                points: [center, through],
                geometryDefinition: geometryDefinition,
                geometryDefinitionStatus: .defined
            )
        ))
    }

    private static func format(_ value: Double) -> String {
        let rounded = (value * 100).rounded() / 100
        if rounded == Double(Int(rounded)) {
            return String(Int(rounded))
        }
        return String(rounded)
    }
}

private extension GeometryDependency {
    func referencesAny(in sourceIDs: Set<UUID>) -> Bool {
        switch kind {
        case .midpointOfPoints(let pointAID, let pointBID):
            return sourceIDs.contains(pointAID) || sourceIDs.contains(pointBID)
        case .parallelLine(let referenceObjectID, let throughPointID):
            return sourceIDs.contains(referenceObjectID) || sourceIDs.contains(throughPointID)
        case .perpendicularLine(let referenceObjectID, let throughPointID):
            return sourceIDs.contains(referenceObjectID) || sourceIDs.contains(throughPointID)
        case .intersectionOf(let objectAID, let objectBID, _):
            return sourceIDs.contains(objectAID) || sourceIDs.contains(objectBID)
        case .circleByCenterPoint(let centerPointID, let throughPointID):
            return sourceIDs.contains(centerPointID) || sourceIDs.contains(throughPointID)
        case .circleByCenterRadius(let centerPointID, _):
            return sourceIDs.contains(centerPointID)
        case .arcByThreePoints(let pointAID, let pointBID, let pointCID):
            return sourceIDs.contains(pointAID)
                || sourceIDs.contains(pointBID)
                || sourceIDs.contains(pointCID)
        }
    }
}

private func appendArcByThreePointsPatches(
    derivedArc: MathObject,
    pointAID: UUID,
    pointBID: UUID,
    pointCID: UUID,
    objectsByID: [UUID: MathObject],
    changedSourceIDs: Set<UUID>,
    into patches: inout [(UUID, DocumentObjectPatch)]
) {
    guard changedSourceIDs.contains(pointAID)
            || changedSourceIDs.contains(pointBID)
            || changedSourceIDs.contains(pointCID) else { return }
    guard let pointA = objectsByID[pointAID], pointA.type == .point,
          let pointB = objectsByID[pointBID], pointB.type == .point,
          let pointC = objectsByID[pointCID], pointC.type == .point,
          let posA = PlaneGeometryResolver.pointPosition(for: pointA),
          let posB = PlaneGeometryResolver.pointPosition(for: pointB),
          let posC = PlaneGeometryResolver.pointPosition(for: pointC),
          let arc = PlaneGeometryResolver.arcFromThreePoints(posA, posB, posC) else {
        patches.append((derivedArc.id, DocumentObjectPatch(geometryDefinitionStatus: .missingSource)))
        return
    }
    patches.append((derivedArc.id, DocumentObjectPatch(
        expressionDisplayText: "圆弧",
        points: [posA, posB, posC],
        geometryDefinitionStatus: .defined
    )))
}
