import EMathicaDocumentKit
import EMathicaMathCore
import EMathicaMathInputCore
import EMathicaWorkspaceKit
import Foundation

struct FormulaRenderingBaselineFixtureCase: Equatable {
    enum StorageKind: String, Equatable {
        case structured
    }

    let name: String
    let group: String
    let formula: String
    let storageKind: StorageKind
    let object: MathObject
}

struct FormulaRenderingBaselineFixtureBuilt: Equatable {
    let document: EMathicaDocument
    let cases: [FormulaRenderingBaselineFixtureCase]
}

enum FormulaRenderingBaselineFixture {
    static let projectID = UUID(uuidString: "6C6E5C13-6BA5-4F8A-B59F-D70F83FA9B84")!
    static let projectTitle = "Formula Rendering Baseline"
    static let fixtureDirectoryName = "FormulaRenderingBaseline.emathica"
    static let stableTimestamp = Date(timeIntervalSince1970: 1_783_459_200)

    static func build() -> FormulaRenderingBaselineFixtureBuilt {
        let cases = makeCases()
        let metadata = ProjectMetadata(
            id: projectID,
            title: projectTitle,
            moduleID: CalculatorModuleType.plane.rawValue,
            createdAt: stableTimestamp,
            updatedAt: stableTimestamp,
            calculatorType: CalculatorModuleType.plane.rawValue
        )
        let document = EMathicaDocument(
            id: projectID,
            metadata: metadata,
            moduleID: CalculatorModuleType.plane.rawValue,
            objects: cases.map(\.object)
        )
        return .init(document: document, cases: cases)
    }

    private static func makeCases() -> [FormulaRenderingBaselineFixtureCase] {
        [
            structured(name: "A01", group: "A", formula: "abcde"),
            structured(name: "A02", group: "A", formula: "abcdefghij"),
            structured(name: "B01", group: "B", formula: "x^2"),
            structured(name: "B02", group: "B", formula: "e^{xy}"),
            structured(name: "C01", group: "C", formula: "\\sqrt{x}"),
            structured(name: "C02", group: "C", formula: "\\sqrt{x^2+y^2}"),
            structured(name: "D01", group: "D", formula: "\\frac{x}{y}"),
            structured(name: "D02", group: "D", formula: "\\frac{\\sqrt{x^2+1}}{a+b}"),
            structured(name: "E01", group: "E", formula: "x_i^2"),
            structured(name: "F01", group: "F", formula: "\\left(\\frac{x+1}{x-1}\\right)^2")
        ]
    }

    private static func structured(
        name: String,
        group: String,
        formula: String
    ) -> FormulaRenderingBaselineFixtureCase {
        let parser = SimpleMathParser()
        let root = parser.parseLatex(formula) ?? parser.parseSource(formula) ?? textNode(formula)
        let input = inputState(root: root)
        let expression = MathExpression(
            displayText: input.displayLatex,
            rawInput: input.source,
            originalLatex: formula,
            editorASTData: editorASTData(for: input.editorState),
            sourceExpression: input.source,
            computeExpression: input.computeExpression
        )
        let object = MathObject(
            name: name,
            type: .function,
            expression: expression,
            style: MathStyle(colorToken: "blue")
        )
        return .init(
            name: name,
            group: group,
            formula: formula,
            storageKind: .structured,
            object: object
        )
    }

    private static func inputState(root: MathNode) -> FormulaInputState {
        var input = FormulaInputState(editorState: EditorState(root: root))
        input.syncDerivedStrings()
        return input
    }

    private static func editorASTData(for state: EditorState) -> String {
        let data = try! JSONEncoder().encode(state)
        return String(decoding: data, as: UTF8.self)
    }

    private static func textNode(_ text: String) -> MathNode {
        .sequence(text.map { .character(String($0)) })
    }
}
