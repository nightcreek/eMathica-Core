import EMathicaMathCore
import Foundation

enum PlaneIntersectionPrimitive: Equatable {
    case line(pointA: WorldPoint, pointB: WorldPoint)
    case ray(start: WorldPoint, through: WorldPoint)
    case segment(start: WorldPoint, end: WorldPoint)
    case circle(center: WorldPoint, radius: Double)
}

enum PlaneIntersectionSolver {
    private static let epsilon = 1e-9

    static func intersections(
        _ first: PlaneIntersectionPrimitive,
        _ second: PlaneIntersectionPrimitive
    ) -> [WorldPoint] {
        switch (first, second) {
        case let (.line(a1, a2), .line(b1, b2)):
            return intersectLineLike(
                .line(origin: a1, direction: vector(from: a1, to: a2)),
                .line(origin: b1, direction: vector(from: b1, to: b2))
            )
        case let (.line(a1, a2), .ray(bStart, bThrough)):
            return intersectLineLike(
                .line(origin: a1, direction: vector(from: a1, to: a2)),
                .ray(origin: bStart, direction: vector(from: bStart, to: bThrough))
            )
        case let (.ray(aStart, aThrough), .line(b1, b2)):
            return intersections(.line(pointA: b1, pointB: b2), .ray(start: aStart, through: aThrough))
        case let (.line(a1, a2), .segment(bStart, bEnd)):
            return intersectLineLike(
                .line(origin: a1, direction: vector(from: a1, to: a2)),
                .segment(origin: bStart, direction: vector(from: bStart, to: bEnd))
            )
        case let (.segment(aStart, aEnd), .line(b1, b2)):
            return intersections(.line(pointA: b1, pointB: b2), .segment(start: aStart, end: aEnd))
        case let (.ray(aStart, aThrough), .ray(bStart, bThrough)):
            return intersectLineLike(
                .ray(origin: aStart, direction: vector(from: aStart, to: aThrough)),
                .ray(origin: bStart, direction: vector(from: bStart, to: bThrough))
            )
        case let (.ray(aStart, aThrough), .segment(bStart, bEnd)):
            return intersectLineLike(
                .ray(origin: aStart, direction: vector(from: aStart, to: aThrough)),
                .segment(origin: bStart, direction: vector(from: bStart, to: bEnd))
            )
        case let (.segment(aStart, aEnd), .ray(bStart, bThrough)):
            return intersections(.ray(start: bStart, through: bThrough), .segment(start: aStart, end: aEnd))
        case let (.segment(aStart, aEnd), .segment(bStart, bEnd)):
            return intersectLineLike(
                .segment(origin: aStart, direction: vector(from: aStart, to: aEnd)),
                .segment(origin: bStart, direction: vector(from: bStart, to: bEnd))
            )
        case let (.line(a1, a2), .circle(center, radius)):
            return intersectLineLikeCircle(
                .line(origin: a1, direction: vector(from: a1, to: a2)),
                center: center,
                radius: radius
            )
        case let (.circle(center, radius), .line(a1, a2)):
            return intersections(.line(pointA: a1, pointB: a2), .circle(center: center, radius: radius))
        case let (.ray(start, through), .circle(center, radius)):
            return intersectLineLikeCircle(
                .ray(origin: start, direction: vector(from: start, to: through)),
                center: center,
                radius: radius
            )
        case let (.circle(center, radius), .ray(start, through)):
            return intersections(.ray(start: start, through: through), .circle(center: center, radius: radius))
        case let (.segment(start, end), .circle(center, radius)):
            return intersectLineLikeCircle(
                .segment(origin: start, direction: vector(from: start, to: end)),
                center: center,
                radius: radius
            )
        case let (.circle(center, radius), .segment(start, end)):
            return intersections(.segment(start: start, end: end), .circle(center: center, radius: radius))
        case let (.circle(c0, r0), .circle(c1, r1)):
            return intersectCircleCircle(c0: c0, r0: r0, c1: c1, r1: r1)
        }
    }

    private enum LineLike {
        case line(origin: WorldPoint, direction: WorldPoint)
        case ray(origin: WorldPoint, direction: WorldPoint)
        case segment(origin: WorldPoint, direction: WorldPoint)

        func allows(parameter t: Double) -> Bool {
            switch self {
            case .line:
                return t.isFinite
            case .ray:
                return t >= -PlaneIntersectionSolver.epsilon
            case .segment:
                return t >= -PlaneIntersectionSolver.epsilon && t <= 1 + PlaneIntersectionSolver.epsilon
            }
        }

        var origin: WorldPoint {
            switch self {
            case .line(let origin, _), .ray(let origin, _), .segment(let origin, _):
                return origin
            }
        }

        var direction: WorldPoint {
            switch self {
            case .line(_, let direction), .ray(_, let direction), .segment(_, let direction):
                return direction
            }
        }
    }

    private static func intersectLineLike(_ first: LineLike, _ second: LineLike) -> [WorldPoint] {
        let r = first.direction
        let s = second.direction
        let rNorm2 = dot(r, r)
        let sNorm2 = dot(s, s)
        guard rNorm2 > epsilon * epsilon, sNorm2 > epsilon * epsilon else { return [] }

        let denominator = cross(r, s)
        if abs(denominator) <= epsilon {
            return []
        }

        let qp = vector(from: first.origin, to: second.origin)
        let t = cross(qp, s) / denominator
        let u = cross(qp, r) / denominator
        guard first.allows(parameter: t), second.allows(parameter: u) else { return [] }

        let point = WorldPoint(
            x: first.origin.x + r.x * t,
            y: first.origin.y + r.y * t
        )
        guard point.x.isFinite, point.y.isFinite else { return [] }
        return [point]
    }

    private static func intersectLineLikeCircle(
        _ lineLike: LineLike,
        center: WorldPoint,
        radius: Double
    ) -> [WorldPoint] {
        guard radius.isFinite, radius > epsilon else { return [] }
        let d = lineLike.direction
        let dNorm2 = dot(d, d)
        guard dNorm2 > epsilon * epsilon else { return [] }

        let f = vector(from: center, to: lineLike.origin)
        let a = dNorm2
        let b = 2 * dot(f, d)
        let c = dot(f, f) - radius * radius
        let discriminant = b * b - 4 * a * c

        if discriminant < -epsilon {
            return []
        }
        if abs(discriminant) <= epsilon {
            let t = -b / (2 * a)
            guard lineLike.allows(parameter: t) else { return [] }
            let point = WorldPoint(x: lineLike.origin.x + d.x * t, y: lineLike.origin.y + d.y * t)
            guard point.x.isFinite, point.y.isFinite else { return [] }
            return [point]
        }

        let sqrtDisc = sqrt(max(0, discriminant))
        let t0 = (-b - sqrtDisc) / (2 * a)
        let t1 = (-b + sqrtDisc) / (2 * a)
        var points: [WorldPoint] = []
        for t in [t0, t1] where lineLike.allows(parameter: t) {
            let point = WorldPoint(x: lineLike.origin.x + d.x * t, y: lineLike.origin.y + d.y * t)
            guard point.x.isFinite, point.y.isFinite else { continue }
            points.append(point)
        }
        return dedupe(points)
    }

    private static func intersectCircleCircle(
        c0: WorldPoint,
        r0: Double,
        c1: WorldPoint,
        r1: Double
    ) -> [WorldPoint] {
        guard r0.isFinite, r1.isFinite, r0 > epsilon, r1 > epsilon else { return [] }
        let dx = c1.x - c0.x
        let dy = c1.y - c0.y
        let d = hypot(dx, dy)

        if d <= epsilon, abs(r0 - r1) <= epsilon {
            return []
        }
        if d > r0 + r1 + epsilon {
            return []
        }
        if d < abs(r0 - r1) - epsilon {
            return []
        }
        if d <= epsilon {
            return []
        }

        let a = (r0 * r0 - r1 * r1 + d * d) / (2 * d)
        let h2 = r0 * r0 - a * a
        if h2 < -epsilon {
            return []
        }

        let xm = c0.x + a * dx / d
        let ym = c0.y + a * dy / d

        if abs(h2) <= epsilon {
            return [WorldPoint(x: xm, y: ym)]
        }

        let h = sqrt(max(0, h2))
        let rx = -dy * (h / d)
        let ry = dx * (h / d)
        let p1 = WorldPoint(x: xm + rx, y: ym + ry)
        let p2 = WorldPoint(x: xm - rx, y: ym - ry)
        return dedupe([p1, p2])
    }

    private static func dedupe(_ points: [WorldPoint]) -> [WorldPoint] {
        var deduped: [WorldPoint] = []
        for point in points {
            if deduped.contains(where: { hypot($0.x - point.x, $0.y - point.y) <= epsilon }) {
                continue
            }
            deduped.append(point)
        }
        return deduped
    }

    private static func vector(from a: WorldPoint, to b: WorldPoint) -> WorldPoint {
        WorldPoint(x: b.x - a.x, y: b.y - a.y)
    }

    private static func dot(_ lhs: WorldPoint, _ rhs: WorldPoint) -> Double {
        lhs.x * rhs.x + lhs.y * rhs.y
    }

    private static func cross(_ lhs: WorldPoint, _ rhs: WorldPoint) -> Double {
        lhs.x * rhs.y - lhs.y * rhs.x
    }
}
