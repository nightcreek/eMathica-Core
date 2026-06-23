import EMathicaMathCore
import Foundation

enum PlaneLineClipping {
    static func clipInfiniteLine(
        pointA: WorldPoint,
        pointB: WorldPoint,
        visibleWorldRect rect: WorldRect
    ) -> (WorldPoint, WorldPoint)? {
        clipParametric(
            origin: pointA,
            direction: WorldPoint(x: pointB.x - pointA.x, y: pointB.y - pointA.y),
            tLower: -.infinity,
            tUpper: .infinity,
            rect: rect
        )
    }

    static func clipRay(
        start: WorldPoint,
        through: WorldPoint,
        visibleWorldRect rect: WorldRect
    ) -> (WorldPoint, WorldPoint)? {
        clipParametric(
            origin: start,
            direction: WorldPoint(x: through.x - start.x, y: through.y - start.y),
            tLower: 0,
            tUpper: .infinity,
            rect: rect
        )
    }

    private static func clipParametric(
        origin: WorldPoint,
        direction: WorldPoint,
        tLower: Double,
        tUpper: Double,
        rect: WorldRect
    ) -> (WorldPoint, WorldPoint)? {
        let dx = direction.x
        let dy = direction.y
        let magnitudeSquared = dx * dx + dy * dy
        guard magnitudeSquared > 1e-18 else { return nil }

        var tMin = tLower
        var tMax = tUpper

        if !updateInterval(
            coord: origin.x,
            delta: dx,
            minBound: rect.minX,
            maxBound: rect.maxX,
            tMin: &tMin,
            tMax: &tMax
        ) {
            return nil
        }

        if !updateInterval(
            coord: origin.y,
            delta: dy,
            minBound: rect.minY,
            maxBound: rect.maxY,
            tMin: &tMin,
            tMax: &tMax
        ) {
            return nil
        }

        guard tMin.isFinite, tMax.isFinite, tMin <= tMax else { return nil }
        let a = WorldPoint(x: origin.x + dx * tMin, y: origin.y + dy * tMin)
        let b = WorldPoint(x: origin.x + dx * tMax, y: origin.y + dy * tMax)
        return (a, b)
    }

    private static func updateInterval(
        coord: Double,
        delta: Double,
        minBound: Double,
        maxBound: Double,
        tMin: inout Double,
        tMax: inout Double
    ) -> Bool {
        if abs(delta) < 1e-12 {
            return coord >= minBound && coord <= maxBound
        }

        var t0 = (minBound - coord) / delta
        var t1 = (maxBound - coord) / delta
        if t0 > t1 { swap(&t0, &t1) }
        tMin = max(tMin, t0)
        tMax = min(tMax, t1)
        return tMin <= tMax
    }
}
