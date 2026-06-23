import CoreGraphics
import Foundation
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct PlaneHitTestServiceTests {
    private let canvasSize = CGSize(width: 600, height: 600)
    private let canvasState = CanvasState.default

    @Test func parametricSemanticCurveCanBeHitTested() throws {
        let objectID = UUID()
        let object = MathObject(
            id: objectID,
            name: "p",
            type: .function,
            expression: MathExpression(
                displayText: "{x=t,y=1}",
                editorASTData: editorASTData(for: parametricTemplateState())
            ),
            style: MathStyle(colorToken: "blue")
        )

        let hit = PlaneHitTestService.hitTestObject(
            at: toScreen(WorldPoint(x: 0.5, y: 1.0)),
            objects: [object],
            canvasState: canvasState,
            canvasSize: canvasSize
        )
        #expect(hit == objectID)
    }

    @Test func piecewiseSemanticCurveCanBeHitTestedAcrossBranches() throws {
        let objectID = UUID()
        let object = MathObject(
            id: objectID,
            name: "pw",
            type: .function,
            expression: MathExpression(
                displayText: "piecewise",
                editorASTData: editorASTData(for: piecewiseTemplateState())
            ),
            style: MathStyle(colorToken: "green")
        )

        let leftBranchHit = PlaneHitTestService.hitTestObject(
            at: toScreen(WorldPoint(x: -0.5, y: 0.25)),
            objects: [object],
            canvasState: canvasState,
            canvasSize: canvasSize
        )
        #expect(leftBranchHit == objectID)

        let rightBranchHit = PlaneHitTestService.hitTestObject(
            at: toScreen(WorldPoint(x: 0.6, y: 0.6)),
            objects: [object],
            canvasState: canvasState,
            canvasSize: canvasSize
        )
        #expect(rightBranchHit == objectID)
    }

    @Test func semanticCurveHitTestReturnsNilWhenFarAway() throws {
        let object = MathObject(
            name: "p",
            type: .function,
            expression: MathExpression(
                displayText: "{x=t,y=1}",
                editorASTData: editorASTData(for: parametricTemplateState())
            ),
            style: MathStyle(colorToken: "blue")
        )

        let hit = PlaneHitTestService.hitTestObject(
            at: CGPoint(x: 20, y: 20),
            objects: [object],
            canvasState: canvasState,
            canvasSize: canvasSize
        )
        #expect(hit == nil)
    }

    @Test func hiddenObjectIsIgnoredByHitTest() throws {
        let objectID = UUID()
        let hidden = MathObject(
            id: objectID,
            name: "hidden",
            type: .function,
            expression: MathExpression(
                displayText: "{x=t,y=1}",
                editorASTData: editorASTData(for: parametricTemplateState())
            ),
            style: MathStyle(colorToken: "blue"),
            isVisible: false
        )
        let hit = PlaneHitTestService.hitTestObject(
            at: toScreen(WorldPoint(x: 0.5, y: 1.0)),
            objects: [hidden],
            canvasState: canvasState,
            canvasSize: canvasSize
        )
        #expect(hit == nil)
    }

    @Test func parameterObjectIsIgnoredByHitTest() throws {
        let parameter = MathObject(
            name: "a",
            type: .parameter,
            expression: MathExpression(displayText: "a=1"),
            parameterValue: 1,
            style: MathStyle(colorToken: "green")
        )
        let hit = PlaneHitTestService.hitTestObject(
            at: toScreen(WorldPoint(x: 0, y: 0)),
            objects: [parameter],
            canvasState: canvasState,
            canvasSize: canvasSize
        )
        #expect(hit == nil)
    }

    @Test func lineObjectHitWorksAcrossVisibleExtent() throws {
        let line = MathObject(
            name: "l1",
            type: .line,
            expression: MathExpression(displayText: "l1: 直线"),
            points: [WorldPoint(x: -1, y: -1), WorldPoint(x: 1, y: 1)],
            geometryDefinition: GeometryDefinition(
                kind: .line,
                anchors: [
                    .fixedPoint(WorldPoint(x: -1, y: -1)),
                    .fixedPoint(WorldPoint(x: 1, y: 1))
                ]
            ),
            style: MathStyle(colorToken: "indigo")
        )
        let hit = PlaneHitTestService.hitTestObject(
            at: toScreen(WorldPoint(x: 3, y: 3)),
            objects: [line],
            canvasState: canvasState,
            canvasSize: canvasSize
        )
        #expect(hit == line.id)
    }

    @Test func rayDoesNotHitBackwardExtension() throws {
        let ray = MathObject(
            name: "r1",
            type: .ray,
            expression: MathExpression(displayText: "r1: 射线"),
            points: [WorldPoint(x: 0, y: 0), WorldPoint(x: 1, y: 0)],
            geometryDefinition: GeometryDefinition(
                kind: .ray,
                anchors: [
                    .fixedPoint(WorldPoint(x: 0, y: 0)),
                    .fixedPoint(WorldPoint(x: 1, y: 0))
                ]
            ),
            style: MathStyle(colorToken: "pink")
        )

        let forwardHit = PlaneHitTestService.hitTestObject(
            at: toScreen(WorldPoint(x: 4, y: 0)),
            objects: [ray],
            canvasState: canvasState,
            canvasSize: canvasSize
        )
        #expect(forwardHit == ray.id)

        let backwardHit = PlaneHitTestService.hitTestObject(
            at: toScreen(WorldPoint(x: -3, y: 0)),
            objects: [ray],
            canvasState: canvasState,
            canvasSize: canvasSize
        )
        #expect(backwardHit == nil)
    }

    @Test func hitTestAllowedTypesCanFilterOutPoints() {
        let point = MathObject(
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            position: .zero,
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let hit = PlaneHitTestService.hitTestObject(
            at: toScreen(.zero),
            objects: [point],
            canvasState: canvasState,
            canvasSize: canvasSize,
            allowedTypes: [.line, .segment, .ray, .circle]
        )
        #expect(hit == nil)
    }

    @Test func noSolutionDerivedPointIsIgnoredByHitTest() {
        let point = MathObject(
            name: "I",
            type: .point,
            expression: MathExpression(displayText: "I=(1,0)"),
            position: WorldPoint(x: 1, y: 0),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            geometryDependency: GeometryDependency(kind: .intersectionOf(objectAID: UUID(), objectBID: UUID(), index: 0)),
            geometryDefinitionStatus: .noSolution,
            style: MathStyle(colorToken: "yellowOrange")
        )
        let hit = PlaneHitTestService.hitTestObject(
            at: toScreen(WorldPoint(x: 1, y: 0)),
            objects: [point],
            canvasState: canvasState,
            canvasSize: canvasSize
        )
        #expect(hit == nil)
    }

    @Test func nonDefinedDerivedPointStatusesAreIgnoredByHitTest() {
        let statuses: [GeometryDefinitionStatus] = [.missingSource, .unsupported, .invalid]
        for status in statuses {
            let point = MathObject(
                name: "I",
                type: .point,
                expression: MathExpression(displayText: "I=(1,0)"),
                position: WorldPoint(x: 1, y: 0),
                geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
                geometryDependency: GeometryDependency(kind: .intersectionOf(objectAID: UUID(), objectBID: UUID(), index: 0)),
                geometryDefinitionStatus: status,
                style: MathStyle(colorToken: "yellowOrange")
            )
            let hit = PlaneHitTestService.hitTestObject(
                at: toScreen(WorldPoint(x: 1, y: 0)),
                objects: [point],
                canvasState: canvasState,
                canvasSize: canvasSize
            )
            #expect(hit == nil)
        }
    }

    private func toScreen(_ world: WorldPoint) -> CGPoint {
        let origin = CGPoint(
            x: canvasSize.width * 0.5 + canvasState.origin.x,
            y: canvasSize.height * 0.5 + canvasState.origin.y
        )
        return CGPoint(
            x: origin.x + CGFloat(world.x) * CGFloat(canvasState.scale),
            y: origin.y - CGFloat(world.y) * CGFloat(canvasState.scale)
        )
    }

    private func editorASTData(for state: EditorState) -> String {
        let data = try! JSONEncoder().encode(state)
        return String(decoding: data, as: UTF8.self)
    }

    private func parametricTemplateState() -> EditorState {
        let template = TemplateNode(
            kind: .parametricEquation2D,
            fields: [
                .init(id: .parametricExpression(0), node: .sequence([.character("t")])),
                .init(id: .parametricExpression(1), node: .sequence([.character("1")]))
            ]
        )
        return EditorState(root: .sequence([.template(template)]))
    }

    private func piecewiseTemplateState() -> EditorState {
        let template = TemplateNode(
            kind: .piecewise(rows: 2),
            fields: [
                .init(id: .rowExpression(0), node: .sequence([.character("x"), .operatorSymbol("^"), .character("2")])),
                .init(id: .rowCondition(0), node: .sequence([.character("x"), .operatorSymbol("<"), .character("0")])),
                .init(id: .rowExpression(1), node: .sequence([.character("x")])),
                .init(id: .rowCondition(1), node: .sequence([.character("x"), .operatorSymbol(">"), .character("0")]))
            ]
        )
        return EditorState(root: .sequence([.template(template)]))
    }
}
