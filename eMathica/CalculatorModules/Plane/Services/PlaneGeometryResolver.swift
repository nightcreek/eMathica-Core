import Foundation
import EMathicaMathCore

enum PlaneGeometryResolver {
    static func pointPosition(for object: MathObject) -> WorldPoint? {
        if let position = object.position {
            return position
        }
        if let definition = object.geometryDefinition,
           definition.kind == .point,
           let first = definition.anchors.first,
           first.kind == .fixedPoint,
           let point = first.point {
            return point
        }
        return object.points?.first
    }

    static func segmentEndpoints(
        for segment: MathObject,
        in objects: [MathObject]
    ) -> (WorldPoint, WorldPoint)? {
        if let definition = segment.geometryDefinition,
           definition.kind == .segment,
           definition.anchors.count >= 2,
           let start = resolve(anchor: definition.anchors[0], in: objects),
           let end = resolve(anchor: definition.anchors[1], in: objects) {
            return (start, end)
        }

        if let ids = linkedSegmentEndpointIDs(from: segment),
           let start = objects.first(where: { $0.id == ids.startID && $0.type == .point }).flatMap(pointPosition(for:)),
           let end = objects.first(where: { $0.id == ids.endID && $0.type == .point }).flatMap(pointPosition(for:)) {
            return (start, end)
        }

        if let points = segment.points, points.count >= 2 {
            return (points[0], points[1])
        }
        return nil
    }

    static func linePoints(
        for line: MathObject,
        in objects: [MathObject]
    ) -> (WorldPoint, WorldPoint)? {
        endpoints(for: line, expectedKind: .line, in: objects)
    }

    static func rayPoints(
        for ray: MathObject,
        in objects: [MathObject]
    ) -> (WorldPoint, WorldPoint)? {
        endpoints(for: ray, expectedKind: .ray, in: objects)
    }

    static func lineLikePoints(
        for object: MathObject,
        in objects: [MathObject]
    ) -> (WorldPoint, WorldPoint)? {
        switch object.type {
        case .segment:
            return segmentEndpoints(for: object, in: objects)
        case .line:
            return linePoints(for: object, in: objects)
        case .ray:
            return rayPoints(for: object, in: objects)
        case .circle, .function, .point, .parameter, .parameterGroup, .arc:
            return nil
        }
    }

    static func circleGeometry(
        for circle: MathObject,
        in objects: [MathObject]
    ) -> (center: WorldPoint, radius: Double)? {
        guard circle.type == .circle else {
            return nil
        }

        if let dependency = circle.geometryDependency {
            switch dependency.kind {
            case .circleByCenterRadius(let centerPointID, let radius):
                guard radius.isFinite, radius > 0,
                      let centerObject = objects.first(where: { $0.id == centerPointID && $0.type == .point }),
                      let center = pointPosition(for: centerObject) else {
                    return nil
                }
                return (center, radius)
            default:
                break
            }
        }

        if let definition = circle.geometryDefinition,
           definition.kind == .circle,
           definition.anchors.count >= 2,
           let center = resolve(anchor: definition.anchors[0], in: objects),
           let through = resolve(anchor: definition.anchors[1], in: objects) {
            let dx = through.x - center.x
            let dy = through.y - center.y
            let radius = (dx * dx + dy * dy).squareRoot()
            if radius.isFinite, radius > 0 {
                return (center, radius)
            }
        }

        if let points = circle.points, points.count >= 2 {
            let center = points[0]
            let through = points[1]
            let dx = through.x - center.x
            let dy = through.y - center.y
            let radius = (dx * dx + dy * dy).squareRoot()
            if radius.isFinite, radius > 0 {
                return (center, radius)
            }
        }

        guard let analysis = circle.expression.algebraAnalysis else {
            return nil
        }
        let classification = analysis.classification
        guard classification.kind == .circle,
              let centerX = classification.centerX,
              let centerY = classification.centerY else {
            return nil
        }
        let radius = classification.radius ?? classification.radiusX ?? classification.radiusY
        guard let radius, radius.isFinite, radius > 0 else { return nil }
        return (WorldPoint(x: centerX, y: centerY), radius)
    }

    static func intersectionPrimitive(
        for object: MathObject,
        in objects: [MathObject]
    ) -> PlaneIntersectionPrimitive? {
        switch object.type {
        case .line:
            guard let endpoints = linePoints(for: object, in: objects) else { return nil }
            return .line(pointA: endpoints.0, pointB: endpoints.1)
        case .ray:
            guard let endpoints = rayPoints(for: object, in: objects) else { return nil }
            return .ray(start: endpoints.0, through: endpoints.1)
        case .segment:
            guard let endpoints = segmentEndpoints(for: object, in: objects) else { return nil }
            return .segment(start: endpoints.0, end: endpoints.1)
        case .circle:
            guard let circle = circleGeometry(for: object, in: objects) else { return nil }
            return .circle(center: circle.center, radius: circle.radius)
        case .function, .point, .parameter, .parameterGroup, .arc:
            return nil
        }
    }

    private static func resolve(anchor: GeometryAnchor, in objects: [MathObject]) -> WorldPoint? {
        switch anchor.kind {
        case .object:
            guard let id = anchor.objectID,
                  let object = objects.first(where: { $0.id == id }) else { return nil }
            return pointPosition(for: object)
        case .fixedPoint:
            return anchor.point
        }
    }

    private static func linkedSegmentEndpointIDs(from segment: MathObject) -> (startID: UUID, endID: UUID)? {
        guard let compute = segment.expression.computeExpression,
              compute.hasPrefix("segment:") else { return nil }
        let payload = String(compute.dropFirst("segment:".count))
        let parts = payload.split(separator: ",", maxSplits: 1).map(String.init)
        guard parts.count == 2,
              let startID = UUID(uuidString: parts[0]),
              let endID = UUID(uuidString: parts[1]) else {
            return nil
        }
        return (startID, endID)
    }

    private static func endpoints(
        for object: MathObject,
        expectedKind: GeometryKind,
        in objects: [MathObject]
    ) -> (WorldPoint, WorldPoint)? {
        if let definition = object.geometryDefinition,
           definition.kind == expectedKind,
           definition.anchors.count >= 2,
           let start = resolve(anchor: definition.anchors[0], in: objects),
           let end = resolve(anchor: definition.anchors[1], in: objects) {
            return (start, end)
        }
        if let points = object.points, points.count >= 2 {
            return (points[0], points[1])
        }
        return nil
    }

    // MARK: - Arc

    /// Compute arc (center, radius, startAngle, endAngle) from three non-collinear points.
    /// Returns nil if points are collinear or any two points coincide.
    static func arcFromThreePoints(
        _ a: WorldPoint, _ b: WorldPoint, _ c: WorldPoint
    ) -> (center: WorldPoint, radius: Double, startAngle: Double, endAngle: Double)? {
        // Perpendicular bisector of AB
        let midAB = WorldPoint(x: (a.x + b.x) * 0.5, y: (a.y + b.y) * 0.5)
        let dxAB = b.x - a.x
        let dyAB = b.y - a.y
        // Perpendicular bisector of BC
        let midBC = WorldPoint(x: (b.x + c.x) * 0.5, y: (b.y + c.y) * 0.5)
        let dxBC = c.x - b.x
        let dyBC = c.y - b.y

        // Solve: center = midAB + t * (-dyAB, dxAB) = midBC + s * (-dyBC, dxBC)
        // midAB.x - t*dyAB = midBC.x - s*dyBC
        // midAB.y + t*dxAB = midBC.y + s*dxBC
        //
        // -t*dyAB + s*dyBC = midBC.x - midAB.x
        //  t*dxAB - s*dxBC = midBC.y - midAB.y
        let a1 = -dyAB; let b1 = dyBC; let c1 = midBC.x - midAB.x
        let a2 = dxAB;  let b2 = -dxBC; let c2 = midBC.y - midAB.y

        let det = a1 * b2 - a2 * b1
        guard abs(det) > 1e-12 else { return nil } // collinear

        let t = (c1 * b2 - b1 * c2) / det
        let center = WorldPoint(x: midAB.x + t * (-dyAB), y: midAB.y + t * dxAB)

        let radius = sqrt(
            (a.x - center.x) * (a.x - center.x) +
            (a.y - center.y) * (a.y - center.y)
        )
        guard radius.isFinite, radius > 1e-9 else { return nil }

        let startAngle = atan2(a.y - center.y, a.x - center.x)
        let midAngle  = atan2(b.y - center.y, b.x - center.x)
        var endAngle  = atan2(c.y - center.y, c.x - center.x)

        // Determine sweep direction from B
        let ccw = isCounterClockwise(start: startAngle, mid: midAngle, end: endAngle)
        if !ccw {
            // Reverse: walk from start through mid to end in clockwise direction
            if endAngle > startAngle { endAngle -= 2 * .pi }
        } else {
            if endAngle < startAngle { endAngle += 2 * .pi }
        }

        return (center, radius, startAngle, endAngle)
    }

    /// Whether going from start→mid→end is counter-clockwise.
    private static func isCounterClockwise(start: Double, mid: Double, end: Double) -> Bool {
        var m = mid
        var e = end
        if m < start { m += 2 * .pi }
        if e < start { e += 2 * .pi }
        return m < e
    }

    /// Resolve arc geometry from an arc MathObject.
    static func arcGeometry(
        for arc: MathObject,
        in objects: [MathObject]
    ) -> (center: WorldPoint, radius: Double, startAngle: Double, endAngle: Double)? {
        guard arc.type == .arc else { return nil }

        if let dependency = arc.geometryDependency {
            if case .arcByThreePoints(let pointAID, let pointBID, let pointCID) = dependency.kind {
                guard let pointA = objects.first(where: { $0.id == pointAID && $0.type == .point }),
                      let pointB = objects.first(where: { $0.id == pointBID && $0.type == .point }),
                      let pointC = objects.first(where: { $0.id == pointCID && $0.type == .point }),
                      let posA = pointPosition(for: pointA),
                      let posB = pointPosition(for: pointB),
                      let posC = pointPosition(for: pointC) else {
                    return nil
                }
                return arcFromThreePoints(posA, posB, posC)
            }
        }

        // Free arc stored with points
        if let points = arc.points, points.count >= 3 {
            return arcFromThreePoints(points[0], points[1], points[2])
        }

        return nil
    }
}
