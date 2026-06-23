import Foundation
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct SpaceInspectorTests {
    @Test func point3DInspectorShowsCoordinate() {
        let object = MathObject(
            name: "P",
            type: .point,
            expression: MathExpression(displayText: "P"),
            geometryDefinition: GeometryDefinition(
                kind: .point3D,
                point3D: WorldPoint3D(x: 1.234, y: -2.345, z: 3.456)
            ),
            style: MathStyle(colorToken: "white")
        )
        let rows = SpaceGeometryInspectorPropertyPresenter.rows(for: object)
        #expect(rows.contains(where: { $0.label == "对象类型" && $0.value == "空间点" }))
        #expect(rows.contains(where: { $0.label == "坐标" && $0.value == "(1.23, -2.35, 3.46)" }))
    }

    @Test func segment3DInspectorShowsEndpointsAndLength() {
        let object = MathObject(
            name: "S",
            type: .segment,
            expression: MathExpression(displayText: "S"),
            geometryDefinition: GeometryDefinition(
                kind: .segment3D,
                point3D: WorldPoint3D(x: 0, y: 0, z: 0),
                pointB3D: WorldPoint3D(x: 0, y: 3, z: 4)
            ),
            style: MathStyle(colorToken: "white")
        )
        let rows = SpaceGeometryInspectorPropertyPresenter.rows(for: object)
        #expect(rows.contains(where: { $0.label == "端点 A" && $0.value == "(0.00, 0.00, 0.00)" }))
        #expect(rows.contains(where: { $0.label == "端点 B" && $0.value == "(0.00, 3.00, 4.00)" }))
        #expect(rows.contains(where: { $0.label == "长度" && $0.value == "5.00" }))
    }

    @Test func line3DInspectorShowsPointAndDirection() {
        let object = MathObject(
            name: "L",
            type: .line,
            expression: MathExpression(displayText: "L"),
            geometryDefinition: GeometryDefinition(
                kind: .line3D,
                point3D: WorldPoint3D(x: 1, y: 2, z: 3),
                vector3D: Vector3D(x: 2, y: -2, z: 1)
            ),
            style: MathStyle(colorToken: "white")
        )
        let rows = SpaceGeometryInspectorPropertyPresenter.rows(for: object)
        #expect(rows.contains(where: { $0.label == "过点" && $0.value == "(1.00, 2.00, 3.00)" }))
        #expect(rows.contains(where: { $0.label == "方向向量" && $0.value == "<2.00, -2.00, 1.00>" }))
        #expect(rows.contains(where: { $0.label == "方向向量长度" && $0.value == "3.00" }))
    }

    @Test func plane3DInspectorShowsPointNormalAndEquation() {
        let object = MathObject(
            name: "Π",
            type: .function,
            expression: MathExpression(displayText: "Π"),
            geometryDefinition: GeometryDefinition(
                kind: .plane3D,
                point3D: WorldPoint3D(x: 1, y: 2, z: 3),
                vector3D: Vector3D(x: 0, y: 0, z: 1)
            ),
            style: MathStyle(colorToken: "white")
        )
        let rows = SpaceGeometryInspectorPropertyPresenter.rows(for: object)
        #expect(rows.contains(where: { $0.label == "对象类型" && $0.value == "空间平面" }))
        #expect(rows.contains(where: { $0.label == "法向量" && $0.value == "<0.00, 0.00, 1.00>" }))
        #expect(rows.contains(where: { $0.label == "平面方程" && $0.value == "0.00x + 0.00y + 1.00z = 3.00" }))
    }

    @Test func invalidPlaneNormalDoesNotCrashAndEquationIsUndefined() {
        let object = MathObject(
            name: "Π0",
            type: .function,
            expression: MathExpression(displayText: "Π0"),
            geometryDefinition: GeometryDefinition(
                kind: .plane3D,
                point3D: .zero,
                vector3D: .zero
            ),
            style: MathStyle(colorToken: "white")
        )
        let rows = SpaceGeometryInspectorPropertyPresenter.rows(for: object)
        #expect(rows.contains(where: { $0.label == "平面方程" && $0.value == "未定义" }))
    }

    @Test func spaceFormatterUsesTwoDecimals() {
        let pointText = SpaceGeometryPropertyFormatter.coordinate(WorldPoint3D(x: 1.236, y: 2, z: -3.994))
        #expect(pointText == "(1.24, 2.00, -3.99)")

        let vectorText = SpaceGeometryPropertyFormatter.vector(Vector3D(x: 0.3333, y: -0.004, z: 12))
        #expect(vectorText == "<0.33, -0.00, 12.00>")

        let eq = SpaceGeometryPropertyFormatter.planeEquation(
            point: WorldPoint3D(x: 1, y: 2, z: 3),
            normal: Vector3D(x: 1, y: 2, z: 2)
        )
        #expect(eq == "1.00x + 2.00y + 2.00z = 11.00")
    }
}
