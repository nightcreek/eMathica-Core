import Foundation
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct PlaneIntersectionSolverTests {
    @Test func lineLineCrossingReturnsSinglePoint() {
        let points = PlaneIntersectionSolver.intersections(
            .line(pointA: WorldPoint(x: -1, y: -1), pointB: WorldPoint(x: 1, y: 1)),
            .line(pointA: WorldPoint(x: -1, y: 1), pointB: WorldPoint(x: 1, y: -1))
        )
        #expect(points.count == 1)
        if let point = points.first {
            #expect(abs(point.x) < 1e-9)
            #expect(abs(point.y) < 1e-9)
        }
    }

    @Test func segmentSegmentNoOverlapReturnsEmpty() {
        let points = PlaneIntersectionSolver.intersections(
            .segment(start: WorldPoint(x: -3, y: 0), end: WorldPoint(x: -2, y: 0)),
            .segment(start: WorldPoint(x: 1, y: 0), end: WorldPoint(x: 2, y: 0))
        )
        #expect(points.isEmpty)
    }

    @Test func rayBackwardExtensionDoesNotIntersect() {
        let points = PlaneIntersectionSolver.intersections(
            .ray(start: WorldPoint(x: 0, y: 0), through: WorldPoint(x: 1, y: 0)),
            .line(pointA: WorldPoint(x: -1, y: 1), pointB: WorldPoint(x: -1, y: -1))
        )
        #expect(points.isEmpty)
    }

    @Test func lineCircleReturnsTwoPoints() {
        let points = PlaneIntersectionSolver.intersections(
            .line(pointA: WorldPoint(x: -2, y: 0), pointB: WorldPoint(x: 2, y: 0)),
            .circle(center: WorldPoint(x: 0, y: 0), radius: 1)
        )
        #expect(points.count == 2)
    }

    @Test func circleCircleTangentReturnsOnePoint() {
        let points = PlaneIntersectionSolver.intersections(
            .circle(center: WorldPoint(x: 0, y: 0), radius: 1),
            .circle(center: WorldPoint(x: 2, y: 0), radius: 1)
        )
        #expect(points.count == 1)
        if let point = points.first {
            #expect(abs(point.x - 1) < 1e-8)
            #expect(abs(point.y) < 1e-8)
        }
    }

    @Test func segmentCircleTwoIntersectionsWithinSegment() {
        let points = PlaneIntersectionSolver.intersections(
            .segment(start: WorldPoint(x: -2, y: 0), end: WorldPoint(x: 2, y: 0)),
            .circle(center: WorldPoint(x: 0, y: 0), radius: 1)
        )
        #expect(points.count == 2)
    }

    @Test func segmentCircleFiltersOutsideSegment() {
        let points = PlaneIntersectionSolver.intersections(
            .segment(start: WorldPoint(x: 2, y: 0), end: WorldPoint(x: 3, y: 0)),
            .circle(center: WorldPoint(x: 0, y: 0), radius: 1)
        )
        #expect(points.isEmpty)
    }

    @Test func rayCircleFiltersNegativeT() {
        let points = PlaneIntersectionSolver.intersections(
            .ray(start: WorldPoint(x: 2, y: 0), through: WorldPoint(x: 3, y: 0)),
            .circle(center: WorldPoint(x: 0, y: 0), radius: 1)
        )
        #expect(points.isEmpty)
    }

    @Test func raySegmentCrossingReturnsPoint() {
        let points = PlaneIntersectionSolver.intersections(
            .ray(start: WorldPoint(x: 0, y: 0), through: WorldPoint(x: 1, y: 0)),
            .segment(start: WorldPoint(x: 1, y: -1), end: WorldPoint(x: 1, y: 1))
        )
        #expect(points.count == 1)
        if let point = points.first {
            #expect(abs(point.x - 1) < 1e-9)
            #expect(abs(point.y) < 1e-9)
        }
    }

    @Test func raySegmentBehindRayReturnsEmpty() {
        let points = PlaneIntersectionSolver.intersections(
            .ray(start: WorldPoint(x: 0, y: 0), through: WorldPoint(x: 1, y: 0)),
            .segment(start: WorldPoint(x: -1, y: -1), end: WorldPoint(x: -1, y: 1))
        )
        #expect(points.isEmpty)
    }

    @Test func segmentSegmentEndpointTouchReturnsOnePoint() {
        let points = PlaneIntersectionSolver.intersections(
            .segment(start: WorldPoint(x: 0, y: 0), end: WorldPoint(x: 1, y: 0)),
            .segment(start: WorldPoint(x: 1, y: 0), end: WorldPoint(x: 2, y: 0))
        )
        #expect(points.count == 1)
        if let point = points.first {
            #expect(abs(point.x - 1) < 1e-9)
            #expect(abs(point.y) < 1e-9)
        }
    }

    @Test func coincidentSegmentsReturnEmptyFirstVersion() {
        let points = PlaneIntersectionSolver.intersections(
            .segment(start: WorldPoint(x: 0, y: 0), end: WorldPoint(x: 2, y: 0)),
            .segment(start: WorldPoint(x: 1, y: 0), end: WorldPoint(x: 3, y: 0))
        )
        #expect(points.isEmpty)
    }

    @Test func parallelOverlappingRaysReturnEmptyFirstVersion() {
        let points = PlaneIntersectionSolver.intersections(
            .ray(start: WorldPoint(x: 0, y: 0), through: WorldPoint(x: 1, y: 0)),
            .ray(start: WorldPoint(x: 0.5, y: 0), through: WorldPoint(x: 1.5, y: 0))
        )
        #expect(points.isEmpty)
    }
}
