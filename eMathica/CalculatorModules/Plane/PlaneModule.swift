import EMathicaWorkspaceKit
import EMathicaDocumentKit
import EMathicaMathCore
import Foundation

enum PlaneModule {
    static let id: CalculatorModuleType = .plane

    static func demoObjects() -> [MathObject] {
        [
            MathObject(name: "f", type: .function, expression: MathExpression(displayText: "f(x) = x² − 2x + 1"), style: MathStyle(colorToken: "blue")),
            MathObject(name: "g", type: .function, expression: MathExpression(displayText: "g(x) = sin(x)"), style: MathStyle(colorToken: "pink")),
            MathObject(name: "A", type: .point, expression: MathExpression(displayText: "A = (1, 2)"), style: MathStyle(colorToken: "yellowOrange")),
            MathObject(name: "B", type: .point, expression: MathExpression(displayText: "B = (4, 3)"), style: MathStyle(colorToken: "purple")),
            MathObject(name: "c", type: .circle, expression: MathExpression(displayText: "c: 圆(A, 2)"), style: MathStyle(colorToken: "green")),
            MathObject(name: "参数", type: .parameterGroup, expression: MathExpression(displayText: "参数 >"), style: MathStyle(colorToken: "indigo"))
        ]
    }

    static func emptyObjects() -> [MathObject] {
        []
    }

    static func newDocument(title: String) -> EMathicaDocument {
        let now = Date()
        let metadata = ProjectMetadata(title: title, moduleID: id.rawValue, createdAt: now, updatedAt: now, calculatorType: id.rawValue)
        return EMathicaDocument(metadata: metadata, moduleID: id.rawValue, objects: emptyObjects())
    }

    static func demoDocument(title: String) -> EMathicaDocument {
        let now = Date()
        let metadata = ProjectMetadata(title: title, moduleID: id.rawValue, createdAt: now, updatedAt: now, calculatorType: id.rawValue)
        return EMathicaDocument(metadata: metadata, moduleID: id.rawValue, objects: demoObjects())
    }
}
