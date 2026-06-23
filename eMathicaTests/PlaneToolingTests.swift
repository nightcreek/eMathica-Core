import Foundation
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct PlaneToolingTests {
    @Test func planeToolProviderIncludesCoreToolsAndRemovesLegacyLongItems() {
        let groups = PlaneToolProvider.defaultToolGroups()
        let ids = Set(groups.flatMap(\.tools).map(\.id))

        #expect(ids.contains(PlaneToolIDs.select))
        #expect(ids.contains(PlaneToolIDs.pan))
        #expect(ids.contains(PlaneToolIDs.delete))
        #expect(ids.contains(PlaneToolIDs.point))
        #expect(ids.contains(PlaneToolIDs.segment))
        #expect(ids.contains(PlaneToolIDs.midpoint))
        #expect(ids.contains(PlaneToolIDs.line))
        #expect(ids.contains(PlaneToolIDs.ray))
        #expect(ids.contains(PlaneToolIDs.parallel))
        #expect(ids.contains(PlaneToolIDs.perpendicular))
        #expect(ids.contains(PlaneToolIDs.circle))
        #expect(ids.contains(PlaneToolIDs.intersection))

        #expect(ids.contains(PlaneToolIDs.function))
        #expect(ids.contains(PlaneToolIDs.slider))

        #expect(!ids.contains(PlaneToolIDs.boxSelect))
        #expect(!ids.contains(PlaneToolIDs.curve))
    }

    @Test func geometryToolsUseDedicatedGeometryIconsAndSetActiveToolActions() {
        let groups = PlaneToolProvider.defaultToolGroups()
        guard let geometryGroup = groups.first(where: { $0.id == "plane.geometry" }) else {
            Issue.record("Missing plane.geometry group")
            return
        }
        let expected: [(String, GeometryToolGlyph)] = [
            (PlaneToolIDs.point, .point),
            (PlaneToolIDs.segment, .segment),
            (PlaneToolIDs.midpoint, .midpoint),
            (PlaneToolIDs.line, .line),
            (PlaneToolIDs.ray, .ray),
            (PlaneToolIDs.parallel, .parallel),
            (PlaneToolIDs.perpendicular, .perpendicular),
            (PlaneToolIDs.circle, .circle),
            (PlaneToolIDs.intersection, .intersection)
        ]

        for (toolID, glyph) in expected {
            guard let tool = geometryGroup.tools.first(where: { $0.id == toolID }) else {
                Issue.record("Missing tool \(toolID)")
                continue
            }
            switch tool.icon {
            case .geometry(let actualGlyph):
                #expect(actualGlyph == glyph)
            default:
                Issue.record("Tool \(toolID) does not use geometry icon")
            }

            if case .setActiveTool(let actionID) = tool.action {
                #expect(actionID == toolID)
            } else {
                Issue.record("Tool \(toolID) action changed unexpectedly")
            }
        }
    }

    @Test func circleModuleSpecificCommandWithBlankCenterAndBlankThroughCreatesCenterRadiusDynamicCircle() throws {
        let handler = PlaneCommandHandler()
        let now = Date()
        let metadata = ProjectMetadata(
            title: "test",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: []
        )
        let center = WorldPoint(x: 1, y: 2)
        let radiusPoint = WorldPoint(x: 4, y: 2)
        let payload = CircleCreatePayload(
            centerPointID: nil,
            throughPointID: nil,
            centerWorldPoint: center,
            radiusWorldPoint: radiusPoint
        )
        let data = try JSONEncoder().encode(payload)
        let json = String(decoding: data, as: UTF8.self)

        let output = handler.handle(
            .moduleSpecific(id: "plane.createCircleWithOptionalCenter", payload: json),
            context: ModuleCommandContext(document: document, selectedObjectIDs: [], inputText: "")
        )

        let circles = output.documentCommands.compactMap { command -> MathObject? in
            if case .addObject(let object) = command, object.type == .circle {
                return object
            }
            return nil
        }

        #expect(circles.count == 1)
        guard let circle = circles.first else { return }
        #expect(output.effects.contains(WorkspaceEffect.selectObject(id: circle.id)))
        #expect(circle.geometryDefinition?.kind == .circle)
        if let dependency = circle.geometryDependency {
            switch dependency.kind {
            case .circleByCenterRadius(_, let radius):
                #expect(abs(radius - 3) < 1e-9)
            default:
                Issue.record("Expected circleByCenterRadius dependency")
            }
        } else {
            Issue.record("Expected dynamic center-radius dependency")
        }

        let addedPoints = output.documentCommands.compactMap { command -> MathObject? in
            if case .addObject(let object) = command, object.type == .point { return object }
            return nil
        }
        #expect(addedPoints.count == 1)
        #expect(output.documentCommands.count == 2)
    }

    @Test func circleModuleSpecificCommandWithExistingCenterAndBlankThroughCreatesCenterRadiusDynamicCircleWithoutHelperPoint() throws {
        let handler = PlaneCommandHandler()
        let now = Date()
        let metadata = ProjectMetadata(
            title: "test",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        let centerPoint = MathObject(
            name: "C",
            type: .point,
            expression: MathExpression(displayText: "C=(1,2)"),
            position: WorldPoint(x: 1, y: 2),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: [centerPoint]
        )
        let payload = CircleCreatePayload(
            centerPointID: centerPoint.id,
            throughPointID: nil,
            centerWorldPoint: WorldPoint(x: 1, y: 2),
            radiusWorldPoint: WorldPoint(x: 4, y: 2)
        )
        let data = try JSONEncoder().encode(payload)
        let json = String(decoding: data, as: UTF8.self)

        let output = handler.handle(
            .moduleSpecific(id: "plane.createCircleWithOptionalCenter", payload: json),
            context: ModuleCommandContext(document: document, selectedObjectIDs: [], inputText: "")
        )

        let circles = output.documentCommands.compactMap { command -> MathObject? in
            if case .addObject(let object) = command, object.type == .circle { return object }
            return nil
        }
        #expect(circles.count == 1)
        guard let circle = circles.first else { return }
        if let dependency = circle.geometryDependency {
            switch dependency.kind {
            case .circleByCenterRadius(let centerPointID, let radius):
                #expect(centerPointID == centerPoint.id)
                #expect(abs(radius - 3) < 1e-9)
            default:
                Issue.record("Expected circleByCenterRadius dependency")
            }
        } else {
            Issue.record("Expected center-radius dependency")
        }

        let addedPoints = output.documentCommands.compactMap { command -> MathObject? in
            if case .addObject(let object) = command, object.type == .point { return object }
            return nil
        }
        #expect(addedPoints.isEmpty)
        #expect(output.documentCommands.count == 1)
    }

    @Test func circleModuleSpecificCommandWithCenterAndThroughPointsCreatesDynamicCircle() throws {
        let handler = PlaneCommandHandler()
        let now = Date()
        let metadata = ProjectMetadata(
            title: "test",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        let centerPoint = MathObject(
            name: "C",
            type: .point,
            expression: MathExpression(displayText: "C=(1,2)"),
            position: WorldPoint(x: 1, y: 2),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let throughPoint = MathObject(
            name: "T",
            type: .point,
            expression: MathExpression(displayText: "T=(4,2)"),
            position: WorldPoint(x: 4, y: 2),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )
        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: [centerPoint, throughPoint]
        )
        let payload = CircleCreatePayload(
            centerPointID: centerPoint.id,
            throughPointID: throughPoint.id,
            centerWorldPoint: WorldPoint(x: 1, y: 2),
            radiusWorldPoint: WorldPoint(x: 4, y: 2)
        )
        let data = try JSONEncoder().encode(payload)
        let json = String(decoding: data, as: UTF8.self)
        let output = handler.handle(
            .moduleSpecific(id: "plane.createCircleWithOptionalCenter", payload: json),
            context: ModuleCommandContext(document: document, selectedObjectIDs: [], inputText: "")
        )
        let circles = output.documentCommands.compactMap { command -> MathObject? in
            if case .addObject(let object) = command, object.type == .circle { return object }
            return nil
        }
        #expect(circles.count == 1)
        guard let circle = circles.first else { return }
        #expect(circle.geometryDefinition?.kind == .circle)
        if let dep = circle.geometryDependency {
            switch dep.kind {
            case .circleByCenterPoint(let centerPointID, let throughPointID):
                #expect(centerPointID == centerPoint.id)
                #expect(throughPointID == throughPoint.id)
            default:
                Issue.record("Expected circleByCenterPoint dependency")
            }
        } else {
            Issue.record("Expected dynamic circle dependency")
        }
    }

    @Test func lineModuleSpecificCommandCreatesLineAndSelectsIt() throws {
        let handler = PlaneCommandHandler()
        let now = Date()
        let metadata = ProjectMetadata(
            title: "test",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: []
        )
        let payload = #"{"pointAID":null,"pointAWorldPoint":{"x":0,"y":0},"pointBID":null,"pointBWorldPoint":{"x":2,"y":1}}"#
        let output = handler.handle(
            .moduleSpecific(id: "plane.createLineWithOptionalPoints", payload: payload),
            context: ModuleCommandContext(document: document, selectedObjectIDs: [], inputText: "")
        )

        let lines = output.documentCommands.compactMap { command -> MathObject? in
            if case .addObject(let object) = command, object.type == .line {
                return object
            }
            return nil
        }
        #expect(lines.count == 1)
        if let line = lines.first {
            #expect(output.effects.contains(WorkspaceEffect.selectObject(id: line.id)))
        }
    }

    @Test func rayModuleSpecificCommandCreatesRayAndSelectsIt() throws {
        let handler = PlaneCommandHandler()
        let now = Date()
        let metadata = ProjectMetadata(
            title: "test",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: []
        )
        let payload = #"{"startPointID":null,"startWorldPoint":{"x":1,"y":1},"throughPointID":null,"throughWorldPoint":{"x":3,"y":2}}"#
        let output = handler.handle(
            .moduleSpecific(id: "plane.createRayWithOptionalPoints", payload: payload),
            context: ModuleCommandContext(document: document, selectedObjectIDs: [], inputText: "")
        )

        let rays = output.documentCommands.compactMap { command -> MathObject? in
            if case .addObject(let object) = command, object.type == .ray {
                return object
            }
            return nil
        }
        #expect(rays.count == 1)
        if let ray = rays.first {
            #expect(output.effects.contains(WorkspaceEffect.selectObject(id: ray.id)))
        }
    }

    @Test func zeroLengthLineAndRayAreRejected() throws {
        let handler = PlaneCommandHandler()
        let now = Date()
        let metadata = ProjectMetadata(
            title: "test",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: []
        )
        let lineOutput = handler.handle(
            .createLine(pointA: WorldPoint(x: 1, y: 1), pointB: WorldPoint(x: 1, y: 1)),
            context: ModuleCommandContext(document: document, selectedObjectIDs: [], inputText: "")
        )
        #expect(lineOutput.documentCommands.isEmpty)

        let rayOutput = handler.handle(
            .createRay(start: WorldPoint(x: 1, y: 1), through: WorldPoint(x: 1, y: 1)),
            context: ModuleCommandContext(document: document, selectedObjectIDs: [], inputText: "")
        )
        #expect(rayOutput.documentCommands.isEmpty)
    }

    @Test func intersectionModuleSpecificCommandCreatesPointObjectsFromLineCircle() throws {
        let handler = PlaneCommandHandler()
        let now = Date()
        let metadata = ProjectMetadata(
            title: "test",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )

        let line = MathObject(
            name: "l1",
            type: .line,
            expression: MathExpression(displayText: "l1: 直线"),
            points: [WorldPoint(x: -2, y: 0), WorldPoint(x: 2, y: 0)],
            geometryDefinition: GeometryDefinition(
                kind: .line,
                anchors: [.fixedPoint(WorldPoint(x: -2, y: 0)), .fixedPoint(WorldPoint(x: 2, y: 0))]
            ),
            style: MathStyle(colorToken: "indigo")
        )

        let builtCircle = PlaneExpressionService.buildExpression(from: "x^2+y^2=1", fallbackToExplicitY: false)
        let circleExpression: MathExpression
        switch builtCircle {
        case .success(let value):
            circleExpression = value
        case .failure(let error):
            Issue.record("failed to build circle expression: \(error.message)")
            return
        }
        let circle = MathObject(
            name: "c1",
            type: .circle,
            expression: circleExpression,
            style: MathStyle(colorToken: "green")
        )

        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: [line, circle]
        )

        let payload = #"{"firstObjectID":"\#(line.id.uuidString)","secondObjectID":"\#(circle.id.uuidString)"}"#
        let output = handler.handle(
            .moduleSpecific(id: "plane.createIntersectionPoints", payload: payload),
            context: ModuleCommandContext(document: document, selectedObjectIDs: [], inputText: "")
        )
        let createdPoints = output.documentCommands.compactMap { command -> MathObject? in
            if case .addObject(let object) = command, object.type == .point {
                return object
            }
            return nil
        }
        #expect(createdPoints.count == 2)
    }

    @Test func createIntersectionPointsForSegmentCircleCreatesExpectedPoints() throws {
        let handler = PlaneCommandHandler()
        let now = Date()
        let metadata = ProjectMetadata(
            title: "test",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        let segment = MathObject(
            name: "s1",
            type: .segment,
            expression: MathExpression(displayText: "s1: 线段"),
            points: [WorldPoint(x: -2, y: 0), WorldPoint(x: 2, y: 0)],
            geometryDefinition: GeometryDefinition(
                kind: .segment,
                anchors: [.fixedPoint(WorldPoint(x: -2, y: 0)), .fixedPoint(WorldPoint(x: 2, y: 0))]
            ),
            style: MathStyle(colorToken: "indigo")
        )

        let builtCircle = PlaneExpressionService.buildExpression(from: "x^2+y^2=1", fallbackToExplicitY: false)
        let circleExpression = try builtCircle.get()
        let circle = MathObject(
            name: "c1",
            type: .circle,
            expression: circleExpression,
            style: MathStyle(colorToken: "green")
        )

        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: [segment, circle]
        )

        let payload = #"{"firstObjectID":"\#(segment.id.uuidString)","secondObjectID":"\#(circle.id.uuidString)"}"#
        let output = handler.handle(
            .moduleSpecific(id: "plane.createIntersectionPoints", payload: payload),
            context: ModuleCommandContext(document: document, selectedObjectIDs: [], inputText: "")
        )

        let createdPoints = output.documentCommands.compactMap { command -> MathObject? in
            if case .addObject(let object) = command, object.type == .point {
                return object
            }
            return nil
        }
        #expect(createdPoints.count == 2)
    }

    @Test func createIntersectionPointsForRayCircleFiltersBackwardPoints() throws {
        let handler = PlaneCommandHandler()
        let now = Date()
        let metadata = ProjectMetadata(
            title: "test",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        let ray = MathObject(
            name: "r1",
            type: .ray,
            expression: MathExpression(displayText: "r1: 射线"),
            points: [WorldPoint(x: 2, y: 0), WorldPoint(x: 3, y: 0)],
            geometryDefinition: GeometryDefinition(
                kind: .ray,
                anchors: [.fixedPoint(WorldPoint(x: 2, y: 0)), .fixedPoint(WorldPoint(x: 3, y: 0))]
            ),
            style: MathStyle(colorToken: "pink")
        )

        let circleExpression = try PlaneExpressionService.buildExpression(from: "x^2+y^2=1", fallbackToExplicitY: false).get()
        let circle = MathObject(
            name: "c1",
            type: .circle,
            expression: circleExpression,
            style: MathStyle(colorToken: "green")
        )

        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: [ray, circle]
        )
        let payload = #"{"firstObjectID":"\#(ray.id.uuidString)","secondObjectID":"\#(circle.id.uuidString)"}"#
        let output = handler.handle(
            .moduleSpecific(id: "plane.createIntersectionPoints", payload: payload),
            context: ModuleCommandContext(document: document, selectedObjectIDs: [], inputText: "")
        )
        let createdPoints = output.documentCommands.compactMap { command -> MathObject? in
            if case .addObject(let object) = command, object.type == .point {
                return object
            }
            return nil
        }
        #expect(createdPoints.isEmpty)
    }

    @Test func createIntersectionPointsForSegmentSegmentCreatesOnePoint() throws {
        let handler = PlaneCommandHandler()
        let now = Date()
        let metadata = ProjectMetadata(
            title: "test",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        let s1 = MathObject(
            name: "s1",
            type: .segment,
            expression: MathExpression(displayText: "s1: 线段"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 2, y: 0)],
            geometryDefinition: GeometryDefinition(
                kind: .segment,
                anchors: [.fixedPoint(WorldPoint(x: 0, y: 0)), .fixedPoint(WorldPoint(x: 2, y: 0))]
            ),
            style: MathStyle(colorToken: "indigo")
        )
        let s2 = MathObject(
            name: "s2",
            type: .segment,
            expression: MathExpression(displayText: "s2: 线段"),
            points: [WorldPoint(x: 1, y: -1), WorldPoint(x: 1, y: 1)],
            geometryDefinition: GeometryDefinition(
                kind: .segment,
                anchors: [.fixedPoint(WorldPoint(x: 1, y: -1)), .fixedPoint(WorldPoint(x: 1, y: 1))]
            ),
            style: MathStyle(colorToken: "green")
        )
        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: [s1, s2]
        )
        let payload = #"{"firstObjectID":"\#(s1.id.uuidString)","secondObjectID":"\#(s2.id.uuidString)"}"#
        let output = handler.handle(
            .moduleSpecific(id: "plane.createIntersectionPoints", payload: payload),
            context: ModuleCommandContext(document: document, selectedObjectIDs: [], inputText: "")
        )
        let createdPoints = output.documentCommands.compactMap { command -> MathObject? in
            if case .addObject(let object) = command, object.type == .point {
                return object
            }
            return nil
        }
        #expect(createdPoints.count == 1)
        if let created = createdPoints.first,
           let dependency = created.geometryDependency {
            switch dependency.kind {
            case .intersectionOf(let objectAID, let objectBID, let index):
                #expect(objectAID == s1.id)
                #expect(objectBID == s2.id)
                #expect(index == 0)
            default:
                Issue.record("Expected line-like intersection dependency")
            }
        } else {
            Issue.record("Expected dynamic dependency for line-like intersection")
        }
    }

    @Test func lineCircleIntersectionCreatesDynamicPointsInCirclePhase() throws {
        let handler = PlaneCommandHandler()
        let now = Date()
        let metadata = ProjectMetadata(
            title: "test",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        let line = MathObject(
            name: "l1",
            type: .line,
            expression: MathExpression(displayText: "l1: 直线"),
            points: [WorldPoint(x: -2, y: 0), WorldPoint(x: 2, y: 0)],
            geometryDefinition: GeometryDefinition(
                kind: .line,
                anchors: [.fixedPoint(WorldPoint(x: -2, y: 0)), .fixedPoint(WorldPoint(x: 2, y: 0))]
            ),
            style: MathStyle(colorToken: "indigo")
        )
        let circleExpression = try PlaneExpressionService.buildExpression(from: "x^2+y^2=1", fallbackToExplicitY: false).get()
        let circle = MathObject(
            name: "c1",
            type: .circle,
            expression: circleExpression,
            style: MathStyle(colorToken: "green")
        )
        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: [line, circle]
        )
        let payload = #"{"firstObjectID":"\#(line.id.uuidString)","secondObjectID":"\#(circle.id.uuidString)"}"#
        let output = handler.handle(
            .moduleSpecific(id: "plane.createIntersectionPoints", payload: payload),
            context: ModuleCommandContext(document: document, selectedObjectIDs: [], inputText: "")
        )
        let createdPoints = output.documentCommands.compactMap { command -> MathObject? in
            if case .addObject(let object) = command, object.type == .point {
                return object
            }
            return nil
        }
        #expect(createdPoints.count == 2)
        for (idx, point) in createdPoints.enumerated() {
            guard let dep = point.geometryDependency else {
                Issue.record("Expected dynamic intersection dependency")
                return
            }
            switch dep.kind {
            case .intersectionOf(let objectAID, let objectBID, let index):
                #expect(objectAID == line.id)
                #expect(objectBID == circle.id)
                #expect(index == idx)
            default:
                Issue.record("Expected intersectionOf dependency")
            }
        }
    }

    @Test func createIntersectionPointsNoIntersectionCreatesNoObject() throws {
        let handler = PlaneCommandHandler()
        let now = Date()
        let metadata = ProjectMetadata(
            title: "test",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        let s1 = MathObject(
            name: "s1",
            type: .segment,
            expression: MathExpression(displayText: "s1: 线段"),
            points: [WorldPoint(x: -3, y: 0), WorldPoint(x: -2, y: 0)],
            geometryDefinition: GeometryDefinition(
                kind: .segment,
                anchors: [.fixedPoint(WorldPoint(x: -3, y: 0)), .fixedPoint(WorldPoint(x: -2, y: 0))]
            ),
            style: MathStyle(colorToken: "indigo")
        )
        let s2 = MathObject(
            name: "s2",
            type: .segment,
            expression: MathExpression(displayText: "s2: 线段"),
            points: [WorldPoint(x: 1, y: 0), WorldPoint(x: 2, y: 0)],
            geometryDefinition: GeometryDefinition(
                kind: .segment,
                anchors: [.fixedPoint(WorldPoint(x: 1, y: 0)), .fixedPoint(WorldPoint(x: 2, y: 0))]
            ),
            style: MathStyle(colorToken: "green")
        )
        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: [s1, s2]
        )
        let payload = #"{"firstObjectID":"\#(s1.id.uuidString)","secondObjectID":"\#(s2.id.uuidString)"}"#
        let output = handler.handle(
            .moduleSpecific(id: "plane.createIntersectionPoints", payload: payload),
            context: ModuleCommandContext(document: document, selectedObjectIDs: [], inputText: "")
        )
        let createdPoints = output.documentCommands.compactMap { command -> MathObject? in
            if case .addObject(let object) = command, object.type == .point {
                return object
            }
            return nil
        }
        #expect(createdPoints.isEmpty)
    }

    @Test func createIntersectionPointsDoesNotModifySourceObjects() throws {
        let handler = PlaneCommandHandler()
        let now = Date()
        let metadata = ProjectMetadata(
            title: "test",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        let line = MathObject(
            name: "l1",
            type: .line,
            expression: MathExpression(displayText: "l1: 直线"),
            points: [WorldPoint(x: -2, y: 0), WorldPoint(x: 2, y: 0)],
            geometryDefinition: GeometryDefinition(
                kind: .line,
                anchors: [.fixedPoint(WorldPoint(x: -2, y: 0)), .fixedPoint(WorldPoint(x: 2, y: 0))]
            ),
            style: MathStyle(colorToken: "indigo", opacity: 0.5, lineWidth: 5, lineStyle: .dashed)
        )
        let circleExpression = try PlaneExpressionService.buildExpression(from: "x^2+y^2=1", fallbackToExplicitY: false).get()
        let circle = MathObject(
            name: "c1",
            type: .circle,
            expression: circleExpression,
            style: MathStyle(colorToken: "green", opacity: 0.75, lineWidth: 3)
        )
        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: [line, circle]
        )
        let payload = #"{"firstObjectID":"\#(line.id.uuidString)","secondObjectID":"\#(circle.id.uuidString)"}"#
        let output = handler.handle(
            .moduleSpecific(id: "plane.createIntersectionPoints", payload: payload),
            context: ModuleCommandContext(document: document, selectedObjectIDs: [], inputText: "")
        )

        let hasUpdateCommand = output.documentCommands.contains { command in
            if case .updateObject = command { return true }
            return false
        }
        #expect(hasUpdateCommand == false)
    }

    @Test func midpointModuleSpecificCommandFromTwoPointsCreatesDynamicMidpointPoint() throws {
        let handler = PlaneCommandHandler()
        let now = Date()
        let metadata = ProjectMetadata(
            title: "test",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )

        let pointA = MathObject(
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let pointB = MathObject(
            name: "B",
            type: .point,
            expression: MathExpression(displayText: "B=(2,2)"),
            position: WorldPoint(x: 2, y: 2),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "purple")
        )

        let document = EMathicaDocument(metadata: metadata, moduleID: "plane", objects: [pointA, pointB])
        let payload = #"{"segmentID":null,"pointAID":"\#(pointA.id.uuidString)","pointBID":"\#(pointB.id.uuidString)"}"#
        let output = handler.handle(
            .moduleSpecific(id: "plane.createMidpoint", payload: payload),
            context: ModuleCommandContext(document: document, selectedObjectIDs: [], inputText: "")
        )

        let createdPoint = output.documentCommands.compactMap { command -> MathObject? in
            if case .addObject(let object) = command, object.type == .point { return object }
            return nil
        }.first
        #expect(createdPoint != nil)
        #expect(createdPoint?.position == WorldPoint(x: 1, y: 1))
        if let dependency = createdPoint?.geometryDependency {
            switch dependency.kind {
            case .midpointOfPoints(let pointAID, let pointBID):
                #expect(pointAID == pointA.id)
                #expect(pointBID == pointB.id)
            case .parallelLine, .perpendicularLine, .intersectionOf, .circleByCenterPoint, .circleByCenterRadius, .arcByThreePoints:
                Issue.record("Unexpected dependency kind for midpoint creation")
            }
        } else {
            Issue.record("Expected midpoint dependency for point-point midpoint creation")
        }
        if let createdPoint {
            #expect(output.effects.contains(.selectObject(id: createdPoint.id)))
        }
    }

    @Test func midpointModuleSpecificCommandFromSegmentCreatesStaticPoint() throws {
        let handler = PlaneCommandHandler()
        let now = Date()
        let metadata = ProjectMetadata(
            title: "test",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )

        let segment = MathObject(
            name: "s1",
            type: .segment,
            expression: MathExpression(displayText: "s1: 线段"),
            points: [WorldPoint(x: -2, y: 0), WorldPoint(x: 2, y: 0)],
            geometryDefinition: GeometryDefinition(
                kind: .segment,
                anchors: [.fixedPoint(WorldPoint(x: -2, y: 0)), .fixedPoint(WorldPoint(x: 2, y: 0))]
            ),
            style: MathStyle(colorToken: "indigo")
        )
        let document = EMathicaDocument(metadata: metadata, moduleID: "plane", objects: [segment])
        let payload = #"{"segmentID":"\#(segment.id.uuidString)","pointAID":null,"pointBID":null}"#
        let output = handler.handle(
            .moduleSpecific(id: "plane.createMidpoint", payload: payload),
            context: ModuleCommandContext(document: document, selectedObjectIDs: [], inputText: "")
        )

        let createdPoint = output.documentCommands.compactMap { command -> MathObject? in
            if case .addObject(let object) = command, object.type == .point { return object }
            return nil
        }.first
        #expect(createdPoint != nil)
        #expect(createdPoint?.position == WorldPoint(x: 0, y: 0))
        #expect(createdPoint?.geometryDependency == nil)
    }

    @Test func midpointModuleSpecificCommandWithSamePointIDsCreatesNoObject() throws {
        let handler = PlaneCommandHandler()
        let now = Date()
        let metadata = ProjectMetadata(
            title: "test",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )

        let pointA = MathObject(
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            position: WorldPoint(x: 0, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )

        let document = EMathicaDocument(metadata: metadata, moduleID: "plane", objects: [pointA])
        let payload = #"{"segmentID":null,"pointAID":"\#(pointA.id.uuidString)","pointBID":"\#(pointA.id.uuidString)"}"#
        let output = handler.handle(
            .moduleSpecific(id: "plane.createMidpoint", payload: payload),
            context: ModuleCommandContext(document: document, selectedObjectIDs: [], inputText: "")
        )
        let hasAddedPoint = output.documentCommands.contains { command in
            if case .addObject(let object) = command, object.type == .point { return true }
            return false
        }
        #expect(hasAddedPoint == false)
    }

    @Test func parallelModuleSpecificCommandCreatesLineThroughPointWithReferenceDirection() throws {
        let handler = PlaneCommandHandler()
        let now = Date()
        let metadata = ProjectMetadata(
            title: "test",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        let reference = MathObject(
            name: "s1",
            type: .segment,
            expression: MathExpression(displayText: "s1: 线段"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 3, y: 1)],
            geometryDefinition: GeometryDefinition(
                kind: .segment,
                anchors: [.fixedPoint(WorldPoint(x: 0, y: 0)), .fixedPoint(WorldPoint(x: 3, y: 1))]
            ),
            style: MathStyle(colorToken: "blue")
        )
        let throughPoint = MathObject(
            name: "P",
            type: .point,
            expression: MathExpression(displayText: "P=(2,2)"),
            position: WorldPoint(x: 2, y: 2),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let document = EMathicaDocument(metadata: metadata, moduleID: "plane", objects: [reference, throughPoint])
        let payload = #"{"referenceObjectID":"\#(reference.id.uuidString)","pointID":"\#(throughPoint.id.uuidString)"}"#
        let output = handler.handle(
            .moduleSpecific(id: "plane.createParallelLine", payload: payload),
            context: ModuleCommandContext(document: document, selectedObjectIDs: [], inputText: "")
        )
        let createdLine = output.documentCommands.compactMap { command -> MathObject? in
            if case .addObject(let object) = command, object.type == .line { return object }
            return nil
        }.first
        #expect(createdLine != nil)
        guard let createdLine, let linePoints = createdLine.points, linePoints.count >= 2 else {
            Issue.record("Missing created parallel line points")
            return
        }
        if let dependency = createdLine.geometryDependency {
            switch dependency.kind {
            case .parallelLine(let referenceObjectID, let throughPointID):
                #expect(referenceObjectID == reference.id)
                #expect(throughPointID == throughPoint.id)
            default:
                Issue.record("Expected parallel line dependency")
            }
        } else {
            Issue.record("Missing parallel line dependency")
        }
        #expect(linePoints[0] == throughPoint.position)
        let referenceDirection = WorldPoint(x: 3, y: 1)
        let createdDirection = WorldPoint(
            x: linePoints[1].x - linePoints[0].x,
            y: linePoints[1].y - linePoints[0].y
        )
        #expect(abs(cross(referenceDirection, createdDirection)) < 1e-9)
        let addedPoints = output.documentCommands.compactMap { command -> MathObject? in
            if case .addObject(let object) = command, object.type == .point { return object }
            return nil
        }
        #expect(addedPoints.isEmpty)
        #expect(output.documentCommands.count == 1)
        if let definition = createdLine.geometryDefinition {
            #expect(definition.kind == .line)
            #expect(definition.anchors.count == 2)
            #expect(definition.anchors[0].kind == .object)
            #expect(definition.anchors[0].objectID == throughPoint.id)
            #expect(definition.anchors[1].kind == .fixedPoint)
            #expect(definition.anchors[1].point == linePoints[1])
        } else {
            Issue.record("Missing geometryDefinition for derived parallel line")
        }
    }

    @Test func perpendicularModuleSpecificCommandCreatesLineThroughPointWithPerpendicularDirection() throws {
        let handler = PlaneCommandHandler()
        let now = Date()
        let metadata = ProjectMetadata(
            title: "test",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        let reference = MathObject(
            name: "r1",
            type: .ray,
            expression: MathExpression(displayText: "r1: 射线"),
            points: [WorldPoint(x: 1, y: 1), WorldPoint(x: 4, y: 2)],
            geometryDefinition: GeometryDefinition(
                kind: .ray,
                anchors: [.fixedPoint(WorldPoint(x: 1, y: 1)), .fixedPoint(WorldPoint(x: 4, y: 2))]
            ),
            style: MathStyle(colorToken: "pink")
        )
        let throughPoint = MathObject(
            name: "Q",
            type: .point,
            expression: MathExpression(displayText: "Q=(0,3)"),
            position: WorldPoint(x: 0, y: 3),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let document = EMathicaDocument(metadata: metadata, moduleID: "plane", objects: [reference, throughPoint])
        let payload = #"{"referenceObjectID":"\#(reference.id.uuidString)","pointID":"\#(throughPoint.id.uuidString)"}"#
        let output = handler.handle(
            .moduleSpecific(id: "plane.createPerpendicularLine", payload: payload),
            context: ModuleCommandContext(document: document, selectedObjectIDs: [], inputText: "")
        )
        let createdLine = output.documentCommands.compactMap { command -> MathObject? in
            if case .addObject(let object) = command, object.type == .line { return object }
            return nil
        }.first
        #expect(createdLine != nil)
        guard let createdLine, let linePoints = createdLine.points, linePoints.count >= 2 else {
            Issue.record("Missing created perpendicular line points")
            return
        }
        if let dependency = createdLine.geometryDependency {
            switch dependency.kind {
            case .perpendicularLine(let referenceObjectID, let throughPointID):
                #expect(referenceObjectID == reference.id)
                #expect(throughPointID == throughPoint.id)
            default:
                Issue.record("Expected perpendicular line dependency")
            }
        } else {
            Issue.record("Missing perpendicular line dependency")
        }
        #expect(linePoints[0] == throughPoint.position)
        let referenceDirection = WorldPoint(x: 3, y: 1)
        let createdDirection = WorldPoint(
            x: linePoints[1].x - linePoints[0].x,
            y: linePoints[1].y - linePoints[0].y
        )
        #expect(abs(dot(referenceDirection, createdDirection)) < 1e-9)
        let addedPoints = output.documentCommands.compactMap { command -> MathObject? in
            if case .addObject(let object) = command, object.type == .point { return object }
            return nil
        }
        #expect(addedPoints.isEmpty)
        #expect(output.documentCommands.count == 1)
        if let definition = createdLine.geometryDefinition {
            #expect(definition.kind == .line)
            #expect(definition.anchors.count == 2)
            #expect(definition.anchors[0].kind == .object)
            #expect(definition.anchors[0].objectID == throughPoint.id)
            #expect(definition.anchors[1].kind == .fixedPoint)
            #expect(definition.anchors[1].point == linePoints[1])
        } else {
            Issue.record("Missing geometryDefinition for derived perpendicular line")
        }
    }

    @Test func toolGroupDisplaysSelectedToolAndFallsBackToFirst() {
        let group = WorkspaceToolGroup(
            id: "test.group",
            title: "测试",
            tools: [
                WorkspaceTool(
                    id: "test.first",
                    title: "第一",
                    icon: .system("1.circle"),
                    action: .setActiveTool("test.first")
                ),
                WorkspaceTool(
                    id: "test.second",
                    title: "第二",
                    icon: .system("2.circle"),
                    action: .setActiveTool("test.second")
                )
            ]
        )

        #expect(group.displayedTool(for: nil)?.id == "test.first")
        #expect(group.displayedTool(for: "test.second")?.id == "test.second")
        #expect(group.displayedTool(for: "unknown")?.id == "test.first")
    }

    @Test func planeFunctionToolBelongsToSetActiveToolActionForGroupIconTracking() {
        let groups = PlaneToolProvider.defaultToolGroups()
        let functionTool = groups
            .flatMap(\.tools)
            .first(where: { $0.id == PlaneToolIDs.function })

        if case .setActiveTool(let id)? = functionTool?.action {
            #expect(id == PlaneToolIDs.function)
        } else {
            Issue.record("Plane function tool should use setActiveTool action.")
        }
    }
}

private func dot(_ a: WorldPoint, _ b: WorldPoint) -> Double {
    (a.x * b.x) + (a.y * b.y)
}

private func cross(_ a: WorldPoint, _ b: WorldPoint) -> Double {
    (a.x * b.y) - (a.y * b.x)
}
