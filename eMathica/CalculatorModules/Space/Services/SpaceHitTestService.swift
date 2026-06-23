import EMathicaMathCore
import CoreGraphics
import Foundation

struct SpaceHitTestResult: Hashable {
    let objectID: UUID
    let priority: Int
    let depth: Double
    let distance: Double
}

enum SpaceHitTestService {
    static func hitTestPointOnly(
        tapPoint: CGPoint,
        scene: SpaceWireframeScene,
        threshold: Double = 12
    ) -> SpaceHitTestResult? {
        var candidates: [SpaceHitTestResult] = []
        for point in scene.points {
            guard let id = point.sourceObjectID else { continue }
            guard point.hitKind == .point else { continue }
            let distance = distance(
                CGPoint(x: point.projected.x, y: point.projected.y),
                tapPoint
            )
            guard distance <= threshold else { continue }
            candidates.append(
                SpaceHitTestResult(
                    objectID: id,
                    priority: 0,
                    depth: point.projected.depth,
                    distance: distance
                )
            )
        }
        return candidates.sorted(by: compareHitResult).first
    }

    static func hitTest(
        tapPoint: CGPoint,
        scene: SpaceWireframeScene,
        pointThreshold: Double = 12,
        segmentThreshold: Double = 10
    ) -> SpaceHitTestResult? {
        var candidates: [SpaceHitTestResult] = []

        if let pointHit = hitTestPointOnly(
            tapPoint: tapPoint,
            scene: scene,
            threshold: pointThreshold
        ) {
            candidates.append(pointHit)
        }

        for segment in scene.segments {
            guard let id = segment.sourceObjectID else { continue }
            guard let hitKind = segment.hitKind else { continue }

            let priority: Int
            switch hitKind {
            case .segment:
                priority = 1
            case .line:
                priority = 2
            case .planeEdge:
                // v0.1 keeps plane edge selectable at lowest priority only.
                priority = 3
            case .point:
                continue
            }

            let a = CGPoint(x: segment.start.x, y: segment.start.y)
            let b = CGPoint(x: segment.end.x, y: segment.end.y)
            let distance = pointToSegmentDistance(point: tapPoint, a: a, b: b)
            guard distance <= segmentThreshold else { continue }

            candidates.append(
                SpaceHitTestResult(
                    objectID: id,
                    priority: priority,
                    depth: segment.averageDepth,
                    distance: distance
                )
            )
        }

        return candidates.sorted(by: compareHitResult).first
    }

    private static func compareHitResult(_ lhs: SpaceHitTestResult, _ rhs: SpaceHitTestResult) -> Bool {
        if lhs.priority != rhs.priority {
            return lhs.priority < rhs.priority
        }
        if abs(lhs.depth - rhs.depth) > 1e-9 {
            return lhs.depth < rhs.depth
        }
        return lhs.distance < rhs.distance
    }

    private static func pointToSegmentDistance(
        point p: CGPoint,
        a: CGPoint,
        b: CGPoint
    ) -> Double {
        let abx = b.x - a.x
        let aby = b.y - a.y
        let apx = p.x - a.x
        let apy = p.y - a.y
        let abLen2 = abx * abx + aby * aby
        if abLen2 <= .ulpOfOne {
            return distance(p, a)
        }
        let t = max(0, min(1, (apx * abx + apy * aby) / abLen2))
        let q = CGPoint(x: a.x + abx * t, y: a.y + aby * t)
        return distance(p, q)
    }

    private static func distance(_ a: CGPoint, _ b: CGPoint) -> Double {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return Double((dx * dx + dy * dy).squareRoot())
    }
}
